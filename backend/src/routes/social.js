const express = require('express');
const db = require('../database');
const { authMiddleware } = require('../middleware/auth');

const router = express.Router();

router.post('/spots/:id/like', authMiddleware, (req, res) => {
  const spot = db.prepare('SELECT id FROM spots WHERE id = ?').get(req.params.id);
  if (!spot) return res.status(404).json({ error: 'Spot no encontrado' });

  const existing = db.prepare('SELECT id FROM likes WHERE user_id = ? AND spot_id = ?').get(req.userId, req.params.id);
  if (existing) {
    db.prepare('DELETE FROM likes WHERE id = ?').run(existing.id);
    return res.json({ liked: false });
  }

  db.prepare('INSERT INTO likes (user_id, spot_id) VALUES (?, ?)').run(req.userId, req.params.id);
  res.json({ liked: true });
});

router.get('/spots/:id/comentarios', (req, res) => {
  const comentarios = db.prepare(
    'SELECT c.*, u.username, u.avatar_url FROM comentarios c JOIN usuarios u ON c.user_id = u.id WHERE c.spot_id = ? ORDER BY c.created_at ASC'
  ).all(req.params.id);

  res.json(comentarios);
});

router.post('/spots/:id/comentarios', authMiddleware, (req, res) => {
  const { contenido } = req.body;
  if (!contenido || contenido.trim() === '') {
    return res.status(400).json({ error: 'El comentario no puede estar vacío' });
  }

  const spot = db.prepare('SELECT id FROM spots WHERE id = ?').get(req.params.id);
  if (!spot) return res.status(404).json({ error: 'Spot no encontrado' });

  const result = db.prepare('INSERT INTO comentarios (user_id, spot_id, contenido) VALUES (?, ?, ?)').run(req.userId, req.params.id, contenido);

  const comentario = db.prepare(
    'SELECT c.*, u.username, u.avatar_url FROM comentarios c JOIN usuarios u ON c.user_id = u.id WHERE c.id = ?'
  ).get(result.lastInsertRowid);

  res.status(201).json(comentario);
});

router.delete('/comentarios/:id', authMiddleware, (req, res) => {
  const comentario = db.prepare('SELECT * FROM comentarios WHERE id = ? AND (user_id = ? OR (SELECT es_admin FROM usuarios WHERE id = ?) = 1)').get(req.params.id, req.userId, req.userId);
  if (!comentario) return res.status(404).json({ error: 'Comentario no encontrado o no autorizado' });

  db.prepare('DELETE FROM comentarios WHERE id = ?').run(req.params.id);
  res.json({ mensaje: 'Comentario eliminado' });
});

router.post('/usuarios/:id/seguir', authMiddleware, (req, res) => {
  if (parseInt(req.params.id) === req.userId) {
    return res.status(400).json({ error: 'No puedes seguirte a ti mismo' });
  }

  const usuario = db.prepare('SELECT id FROM usuarios WHERE id = ?').get(req.params.id);
  if (!usuario) return res.status(404).json({ error: 'Usuario no encontrado' });

  const existing = db.prepare('SELECT id FROM seguidores WHERE seguidor_id = ? AND seguido_id = ?').get(req.userId, req.params.id);
  if (existing) {
    db.prepare('DELETE FROM seguidores WHERE id = ?').run(existing.id);
    return res.json({ siguiendo: false });
  }

  db.prepare('INSERT INTO seguidores (seguidor_id, seguido_id) VALUES (?, ?)').run(req.userId, req.params.id);
  res.json({ siguiendo: true });
});

router.get('/usuarios/:id/seguidores', (req, res) => {
  const seguidores = db.prepare(
    'SELECT u.id, u.username, u.avatar_url FROM seguidores s JOIN usuarios u ON u.id = s.seguidor_id WHERE s.seguido_id = ?'
  ).all(req.params.id);

  res.json(seguidores);
});

router.get('/usuarios/:id/siguiendo', (req, res) => {
  const siguiendo = db.prepare(
    'SELECT u.id, u.username, u.avatar_url FROM seguidores s JOIN usuarios u ON u.id = s.seguido_id WHERE s.seguidor_id = ?'
  ).all(req.params.id);

  res.json(siguiendo);
});

router.get('/usuarios/:id', (req, res) => {
  const usuario = db.prepare(
    'SELECT id, email, username, avatar_url, bio, created_at FROM usuarios WHERE id = ?'
  ).get(req.params.id);

  if (!usuario) return res.status(404).json({ error: 'Usuario no encontrado' });

  const stats = db.prepare('SELECT * FROM estadisticas_usuario WHERE user_id = ?').get(usuario.id);
  const spots = db.prepare('SELECT id, nombre, imagen_url, categoria, dificultad, created_at FROM spots WHERE user_id = ? ORDER BY created_at DESC').all(usuario.id);

  res.json({ ...usuario, estadisticas: stats, spots });
});

module.exports = router;
