const express = require('express');
const path = require('path');
const fs = require('fs');
const multer = require('multer');
const db = require('../database');
const { authMiddleware } = require('../middleware/auth');
const haversine = require('../utils/haversine');
const { uploadLimiter } = require('../middleware/rateLimit');
const { canCheckin, spotExists, deny } = require('../middleware/accessControl');

const router = express.Router();
fs.mkdirSync(path.join(__dirname, '..', '..', 'uploads'), { recursive: true });

const ALLOWED_MIME = ['image/jpeg', 'image/png', 'image/webp', 'image/gif', 'application/octet-stream'];
const ALLOWED_EXTS = ['.jpg', '.jpeg', '.png', '.webp', '.gif'];

const storage = multer.diskStorage({
  destination: path.join(__dirname, '..', '..', 'uploads'),
  filename: (req, file, cb) => {
    const unique = Date.now() + '-' + Math.round(Math.random() * 1E9);
    cb(null, unique + path.extname(file.originalname));
  }
});

const upload = multer({
  storage,
  limits: { fileSize: 10 * 1024 * 1024 },
  fileFilter: (req, file, cb) => {
    if (ALLOWED_MIME.includes(file.mimetype)) {
      cb(null, true);
    } else {
      const ext = require('path').extname(file.originalname).toLowerCase();
      if (ALLOWED_EXTS.includes(ext)) return cb(null, true);
      cb(new Error('Tipo de archivo no permitido. Solo se aceptan imágenes JPEG, PNG, WebP y GIF.'));
    }
  }
});

router.post('/spots/:id/checkin', authMiddleware, (req, res) => {
  const spotId = parseInt(req.params.id, 10);
  if (isNaN(spotId)) {
    return res.status(400).json({ error: 'spot_id debe ser un número entero' });
  }

  const check = canCheckin(req.userId, spotId);
  if (!check.allowed) {
    return deny(res, 429, 'Checkin en las últimas 24h');
  }

  const spot = db.prepare('SELECT * FROM spots WHERE id = ?').get(spotId);
  if (!spot) return res.status(404).json({ error: 'Spot no encontrado' });

  const existing = db.prepare('SELECT id FROM checkins WHERE user_id = ? AND spot_id = ?').get(req.userId, spotId);
  if (existing) {
    return res.status(409).json({ error: 'Ya has hecho check-in en este spot' });
  }

  db.prepare('INSERT INTO checkins (user_id, spot_id) VALUES (?, ?)').run(req.userId, spotId);

  let distancia = 0;
  if (spot.start_lat && spot.start_lng) {
    distancia = haversine(
      spot.start_lat, spot.start_lng,
      spot.lat, spot.lng
    ) / 1000;
  }

  const updateFields = [];
  const updateValues = [];

  updateFields.push('total_checkins = total_checkins + 1');
  updateFields.push('total_km = total_km + ?');
  updateValues.push(distancia);

  if (spot.dificultad === 'facil') {
    updateFields.push('total_facil = total_facil + 1');
  } else if (spot.dificultad === 'medio') {
    updateFields.push('total_medio = total_medio + 1');
  } else if (spot.dificultad === 'dificil') {
    updateFields.push('total_dificil = total_dificil + 1');
  }

  updateFields.push('updated_at = CURRENT_TIMESTAMP');
  updateValues.push(req.userId);

  db.prepare(`UPDATE estadisticas_usuario SET ${updateFields.join(', ')} WHERE user_id = ?`).run(...updateValues);

  const logrosDesbloqueados = verificarLogros(req.userId, spot);

  const updatedStats = db.prepare('SELECT * FROM estadisticas_usuario WHERE user_id = ?').get(req.userId);
  res.json({ estadisticas: updatedStats, logros_nuevos: logrosDesbloqueados });
});

router.post('/publicar', authMiddleware, uploadLimiter, upload.single('imagen'), (req, res) => {
  const { spot_id, descripcion } = req.body;

  const spotId = parseInt(spot_id, 10);
  if (!spot_id || isNaN(spotId)) {
    return res.status(400).json({ error: 'spot_id requerido y debe ser un número entero' });
  }

  if (!spotExists(spotId)) {
    return res.status(404).json({ error: 'Spot no encontrado' });
  }

  const spot = db.prepare('SELECT * FROM spots WHERE id = ?').get(spotId);

  if (!req.file) {
    return res.status(400).json({ error: 'Se requiere una foto para publicar' });
  }

  const imagen_url = `/uploads/${req.file.filename}`;

  const result = db.prepare(
    'INSERT INTO publicaciones (user_id, spot_id, imagen_url, descripcion) VALUES (?, ?, ?, ?)'
  ).run(req.userId, spotId, imagen_url, descripcion || '');

  const esPrimerDescubridor = db.prepare(
    'SELECT id FROM publicaciones WHERE spot_id = ? ORDER BY created_at ASC LIMIT 1'
  ).get(spotId);

  const logros = [];
  if (esPrimerDescubridor && esPrimerDescubridor.id === result.lastInsertRowid) {
    darLogroPrime(req.userId, spot);
    logros.push({ tipo: 'prime', nombre: `Primer descubridor de ${spot.nombre}` });
  }

  db.prepare('UPDATE estadisticas_usuario SET ultima_publicacion = CURRENT_TIMESTAMP WHERE user_id = ?').run(req.userId);

  verificarPrimeActivo(req.userId);

  const publicacion = db.prepare(
    'SELECT p.*, u.username, u.avatar_url FROM publicaciones p JOIN usuarios u ON p.user_id = u.id WHERE p.id = ?'
  ).get(result.lastInsertRowid);

  res.status(201).json({ publicacion, logros });
});

function darLogroPrime(userId, spot) {
  const logro = db.prepare("SELECT id FROM logros WHERE tipo = 'prime' AND criterio = 'descubridor'").get();
  if (logro) {
    const tiene = db.prepare('SELECT id FROM logros_usuario WHERE user_id = ? AND logro_id = ?').get(userId, logro.id);
    if (!tiene) {
      db.prepare('INSERT INTO logros_usuario (user_id, logro_id) VALUES (?, ?)').run(userId, logro.id);
    }
  }
}

function verificarPrimeActivo(userId) {
  const stats = db.prepare('SELECT ultima_publicacion FROM estadisticas_usuario WHERE user_id = ?').get(userId);
  if (!stats || !stats.ultima_publicacion) return;

  const ultima = new Date(stats.ultima_publicacion).getTime();
  const ahora = Date.now();
  const diff = ahora - ultima;

  const activo = diff <= 7 * 24 * 60 * 60 * 1000;
  db.prepare('UPDATE estadisticas_usuario SET prime_activo = ? WHERE user_id = ?').run(activo ? 1 : 0, userId);
}

function verificarLogros(userId, spot) {
  const nuevos = [];
  const stats = db.prepare('SELECT * FROM estadisticas_usuario WHERE user_id = ?').get(userId);

  if (stats.total_checkins % 5 === 0) {
    const logro = db.prepare("SELECT id, nombre FROM logros WHERE tipo = 'insignia' AND umbral = ?").get(stats.total_checkins);
    if (logro) {
      db.prepare('INSERT OR IGNORE INTO logros_usuario (user_id, logro_id) VALUES (?, ?)').run(userId, logro.id);
      nuevos.push({ tipo: 'insignia', nombre: logro.nombre });
    }
  }

  return nuevos;
}

module.exports = router;
