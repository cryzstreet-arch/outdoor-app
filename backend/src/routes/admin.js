const express = require('express');
const db = require('../database');
const { adminMiddleware } = require('../middleware/auth');

const router = express.Router();

router.get('/usuarios', adminMiddleware, (req, res) => {
  const usuarios = db.prepare(
    'SELECT id, email, username, es_admin, created_at FROM usuarios ORDER BY id'
  ).all();
  res.json(usuarios);
});

router.get('/spots', adminMiddleware, (req, res) => {
  const spots = db.prepare(
    'SELECT s.*, u.username FROM spots s JOIN usuarios u ON s.user_id = u.id ORDER BY s.id'
  ).all();
  res.json(spots);
});

router.get('/estadisticas', adminMiddleware, (req, res) => {
  const totalUsuarios = db.prepare('SELECT COUNT(*) as total FROM usuarios').get();
  const totalSpots = db.prepare('SELECT COUNT(*) as total FROM spots').get();
  const totalCheckins = db.prepare('SELECT COUNT(*) as total FROM checkins').get();
  const totalComentarios = db.prepare('SELECT COUNT(*) as total FROM comentarios').get();
  res.json({
    usuarios: totalUsuarios.total,
    spots: totalSpots.total,
    checkins: totalCheckins.total,
    comentarios: totalComentarios.total,
  });
});

router.post('/seed', adminMiddleware, (req, res) => {
  const spotsSeed = [
    { nombre: 'Mirador del Valle', descripcion: 'Vista panorámica espectacular', lat: -33.456, lng: -70.648, categoria: 'mirador', dificultad: 'facil' },
    { nombre: 'Sendero del Bosque', descripcion: 'Camino rodeado de naturaleza', lat: -33.460, lng: -70.655, categoria: 'sendero', dificultad: 'medio' },
    { nombre: 'Cascada Escondida', descripcion: 'Hermosa caída de agua', lat: -33.470, lng: -70.640, categoria: 'natural', dificultad: 'dificil' },
  ];
  const insert = db.prepare(
    'INSERT OR IGNORE INTO spots (user_id, nombre, descripcion, lat, lng, categoria, dificultad) VALUES (?, ?, ?, ?, ?, ?, ?)'
  );
  let count = 0;
  for (const spot of spotsSeed) {
    const existing = db.prepare('SELECT id FROM spots WHERE nombre = ?').get(spot.nombre);
    if (!existing) {
      insert.run(req.userId, spot.nombre, spot.descripcion, spot.lat, spot.lng, spot.categoria, spot.dificultad);
      count++;
    }
  }
  res.json({ creados: count, mensaje: `${count} spots de ejemplo creados` });
});

module.exports = router;
