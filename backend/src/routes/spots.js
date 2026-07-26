const express = require('express');
const path = require('path');
const fs = require('fs');
const multer = require('multer');
const db = require('../database');
const { authMiddleware } = require('../middleware/auth');
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
const upload = multer({ storage, limits: { fileSize: 10 * 1024 * 1024 } });

router.get('/', (req, res) => {
  const { categoria, dificultad, page = 1, limit = 20 } = req.query;
  const offset = ((parseInt(page) || 1) - 1) * (parseInt(limit) || 20);

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

  if (categoria) {
    sql += ' AND s.categoria = ?';
    params.push(categoria);
  }
  if (dificultad) {
    sql += ' AND s.dificultad = ?';
    params.push(dificultad);
  }

  sql += ' ORDER BY s.created_at DESC LIMIT ? OFFSET ?';
  params.push(parseInt(limit), offset);

  const spots = db.prepare(sql).all(...params);

  let countSql = 'SELECT COUNT(*) as count FROM spots WHERE 1=1';
  const countParams = [];
  if (categoria) { countSql += ' AND categoria = ?'; countParams.push(categoria); }
  if (dificultad) { countSql += ' AND dificultad = ?'; countParams.push(dificultad); }
  const total = db.prepare(countSql).get(...countParams);

  res.json({ spots, total: total.count, page: parseInt(page) || 1, limit: parseInt(limit) || 20 });
});

router.get('/cerca', (req, res) => {
  const { lat, lng, radio = 5000 } = req.query;

  if (!lat || !lng) {
    return res.status(400).json({ error: 'Latitud y longitud requeridas' });
  }

  const spots = db.prepare('SELECT * FROM spots').all();
  const cerca = spots.map(s => {
    const d = haversine(parseFloat(lat), parseFloat(lng), s.lat, s.lng);
    return { ...s, distancia: d };
  }).filter(s => s.distancia <= parseFloat(radio))
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

router.post('/', authMiddleware, upload.single('imagen'), (req, res) => {
  const { nombre, descripcion, lat, lng, categoria, dificultad, hide_radius, reveal_radius, detail_radius, gps_radius, start_lat, start_lng } = req.body;

  if (!nombre || lat === undefined || lng === undefined) {
    return res.status(400).json({ error: 'Nombre, latitud y longitud requeridos' });
  }

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

router.put('/:id', authMiddleware, (req, res) => {
  const spot = db.prepare('SELECT * FROM spots WHERE id = ? AND (user_id = ? OR (SELECT es_admin FROM usuarios WHERE id = ?) = 1)').get(req.params.id, req.userId, req.userId);
  if (!spot) return res.status(404).json({ error: 'Spot no encontrado o no autorizado' });

  const { nombre, descripcion, categoria, dificultad, hide_radius, reveal_radius, detail_radius, gps_radius } = req.body;

  db.prepare(`
    UPDATE spots SET nombre = COALESCE(?, nombre), descripcion = COALESCE(?, descripcion),
    categoria = COALESCE(?, categoria), dificultad = COALESCE(?, dificultad),
    hide_radius = COALESCE(?, hide_radius), reveal_radius = COALESCE(?, reveal_radius),
    detail_radius = COALESCE(?, detail_radius), gps_radius = COALESCE(?, gps_radius)
    WHERE id = ?
  `).run(nombre, descripcion, categoria, dificultad, hide_radius, reveal_radius, detail_radius, gps_radius, req.params.id);

  const updated = db.prepare('SELECT * FROM spots WHERE id = ?').get(req.params.id);
  res.json(updated);
});

router.delete('/:id', authMiddleware, (req, res) => {
  const spot = db.prepare('SELECT * FROM spots WHERE id = ? AND (user_id = ? OR (SELECT es_admin FROM usuarios WHERE id = ?) = 1)').get(req.params.id, req.userId, req.userId);
  if (!spot) return res.status(404).json({ error: 'Spot no encontrado o no autorizado' });

  db.prepare('DELETE FROM likes WHERE spot_id = ?').run(req.params.id);
  db.prepare('DELETE FROM comentarios WHERE spot_id = ?').run(req.params.id);
  db.prepare('DELETE FROM checkins WHERE spot_id = ?').run(req.params.id);
  db.prepare('DELETE FROM publicaciones WHERE spot_id = ?').run(req.params.id);
  db.prepare('DELETE FROM spots WHERE id = ?').run(req.params.id);
  res.json({ mensaje: 'Spot eliminado' });
});

module.exports = router;
