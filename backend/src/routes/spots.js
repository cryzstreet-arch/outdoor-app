const express = require('express');
const path = require('path');
const fs = require('fs');
const multer = require('multer');
const db = require('../database');
const { authMiddleware } = require('../middleware/auth');
const { validate } = require('../middleware/validate');
const { uploadLimiter } = require('../middleware/rateLimit');
const { canEditSpot, canDeleteSpot, spotExists, deny } = require('../middleware/accessControl');
const haversine = require('../utils/haversine');

const router = express.Router();
fs.mkdirSync(path.join(__dirname, '..', '..', 'uploads'), { recursive: true });

const storage = multer.diskStorage({
  destination: path.join(__dirname, '..', '..', 'uploads'),
  filename: (req, file, cb) => {
    const unique = Date.now() + '-' + Math.round(Math.random() * 1E9);
    cb(null, unique + path.extname(file.originalname));
  }
});

const ALLOWED_MIMES = ['image/jpeg', 'image/png', 'image/webp', 'image/gif'];
const upload = multer({
  storage,
  limits: { fileSize: 10 * 1024 * 1024 },
  fileFilter: (req, file, cb) => {
    if (ALLOWED_MIMES.includes(file.mimetype)) return cb(null, true);
    cb(new Error('Solo se permiten imágenes (JPEG, PNG, WebP, GIF)'));
  }
});

router.get('/', validate('pagination'), (req, res) => {
  const { categoria, dificultad, page = 1, limit = 20 } = req.query;
  const offset = (page - 1) * limit;

  let sql = `
    SELECT s.*, u.username, u.avatar_url,
      (SELECT COUNT(*) FROM likes WHERE spot_id = s.id) as total_likes,
      (SELECT COUNT(*) FROM comentarios WHERE spot_id = s.id) as total_comentarios,
      (SELECT COUNT(*) FROM checkins WHERE spot_id = s.id) as total_checkins
    FROM spots s
    JOIN usuarios u ON s.user_id = u.id
    WHERE 1=1
  `;
  const params = [];

  if (categoria) { sql += ' AND s.categoria = ?'; params.push(categoria); }
  if (dificultad) { sql += ' AND s.dificultad = ?'; params.push(dificultad); }

  sql += ' ORDER BY s.created_at DESC LIMIT ? OFFSET ?';
  params.push(limit, offset);

  const spots = db.prepare(sql).all(...params);

  let countSql = 'SELECT COUNT(*) as count FROM spots WHERE 1=1';
  const countParams = [];
  if (categoria) { countSql += ' AND categoria = ?'; countParams.push(categoria); }
  if (dificultad) { countSql += ' AND dificultad = ?'; countParams.push(dificultad); }
  const total = db.prepare(countSql).get(...countParams);

  res.json({ spots, total: total.count, page, limit });
});

router.get('/cerca', validate('nearby'), (req, res) => {
  const { lat, lng, radio } = req.query;

  const spots = db.prepare('SELECT * FROM spots').all();
  const cerca = spots.map(s => {
    const d = haversine(lat, lng, s.lat, s.lng);
    return { ...s, distancia: d };
  }).filter(s => s.distancia <= radio)
    .sort((a, b) => a.distancia - b.distancia);

  res.json({ spots: cerca });
});

router.get('/:id', (req, res) => {
  const spot = db.prepare(`
    SELECT s.*, u.username, u.avatar_url,
      (SELECT COUNT(*) FROM likes WHERE spot_id = s.id) as total_likes,
      (SELECT COUNT(*) FROM comentarios WHERE spot_id = s.id) as total_comentarios,
      (SELECT COUNT(*) FROM checkins WHERE spot_id = s.id) as total_checkins
    FROM spots s
    JOIN usuarios u ON s.user_id = u.id
    WHERE s.id = ?
  `).get(req.params.id);

  if (!spot) return res.status(404).json({ error: 'Spot no encontrado' });

  const publicaciones = db.prepare(
    'SELECT p.*, u.username, u.avatar_url FROM publicaciones p JOIN usuarios u ON p.user_id = u.id WHERE p.spot_id = ? ORDER BY p.created_at DESC'
  ).all(req.params.id);

  res.json({ ...spot, publicaciones });
});

router.post('/', authMiddleware, uploadLimiter, upload.single('imagen'), validate('createSpot'), (req, res) => {
  const { nombre, descripcion, lat, lng, categoria, dificultad, hide_radius, reveal_radius, detail_radius, gps_radius, start_lat, start_lng } = req.body;

  const imagen_url = req.file ? `/uploads/${req.file.filename}` : null;

  const result = db.prepare(`
    INSERT INTO spots (user_id, nombre, descripcion, lat, lng, categoria, dificultad, imagen_url, hide_radius, reveal_radius, detail_radius, gps_radius, start_lat, start_lng)
    VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?)
  `).run(
    req.userId, nombre, descripcion || '', lat, lng,
    categoria || 'otro', dificultad || 'facil', imagen_url,
    hide_radius || 3000, reveal_radius || 1000, detail_radius || 300, gps_radius || 50,
    start_lat || null, start_lng || null
  );

  const spot = db.prepare('SELECT * FROM spots WHERE id = ?').get(result.lastInsertRowid);
  res.status(201).json(spot);
});

router.put('/:id', authMiddleware, validate('updateSpot'), (req, res) => {
  const spotId = parseInt(req.params.id);
  if (!spotExists(spotId)) return res.status(404).json({ error: 'Spot no encontrado' });
  if (!canEditSpot(req.userId, spotId)) return deny(res, 'No tienes permiso para editar este spot');

  const { nombre, descripcion, categoria, dificultad, hide_radius, reveal_radius, detail_radius, gps_radius } = req.body;

  db.prepare(`
    UPDATE spots SET nombre = COALESCE(?, nombre), descripcion = COALESCE(?, descripcion),
    categoria = COALESCE(?, categoria), dificultad = COALESCE(?, dificultad),
    hide_radius = COALESCE(?, hide_radius), reveal_radius = COALESCE(?, reveal_radius),
    detail_radius = COALESCE(?, detail_radius), gps_radius = COALESCE(?, gps_radius)
    WHERE id = ?
  `).run(nombre, descripcion, categoria, dificultad, hide_radius, reveal_radius, detail_radius, gps_radius, spotId);

  const updated = db.prepare('SELECT * FROM spots WHERE id = ?').get(spotId);
  res.json(updated);
});

router.delete('/:id', authMiddleware, (req, res) => {
  const spotId = parseInt(req.params.id);
  if (!spotExists(spotId)) return res.status(404).json({ error: 'Spot no encontrado' });
  if (!canDeleteSpot(req.userId, spotId)) return deny(res, 'No tienes permiso para eliminar este spot');

  db.prepare('DELETE FROM likes WHERE spot_id = ?').run(spotId);
  db.prepare('DELETE FROM comentarios WHERE spot_id = ?').run(spotId);
  db.prepare('DELETE FROM checkins WHERE spot_id = ?').run(spotId);
  db.prepare('DELETE FROM publicaciones WHERE spot_id = ?').run(spotId);
  db.prepare('DELETE FROM spots WHERE id = ?').run(spotId);
  res.json({ mensaje: 'Spot eliminado' });
});

module.exports = router;
