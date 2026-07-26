const express = require('express');
const db = require('../database');
const { authMiddleware } = require('../middleware/auth');
const { socialLimiter } = require('../middleware/rateLimit');
const { validate } = require('../middleware/validate');
const { canLike, canFollow, canUnfollow, canDeleteComment, spotExists, userExists, deny } = require('../middleware/accessControl');

const router = express.Router();

router.post('/spots/:id/like', authMiddleware, socialLimiter, (req, res) => {
  const spotId = parseInt(req.params.id);
  const spot = spotExists(spotId);
  if (!spot) return res.status(404).json({ error: 'Spot no encontrado' });

  const likeError = canLike(req.userId, spotId);
  if (likeError) return deny(res, likeError);

  const existing = db.prepare('SELECT id FROM likes WHERE user_id = ? AND spot_id = ?').get(req.userId, spotId);
  if (existing) {
    db.prepare('DELETE FROM likes WHERE id = ?').run(existing.id);
    return res.json({ liked: false });
  }

  db.prepare('INSERT INTO likes (user_id, spot_id) VALUES (?, ?)').run(req.userId, spotId);
  res.json({ liked: true });
});

router.get('/spots/:id/comentarios', (req, res) => {
  const spotId = parseInt(req.params.id);
  const comentarios = db.prepare(
    'SELECT c.*, u.username, u.avatar_url FROM comentarios c JOIN usuarios u ON c.user_id = u.id WHERE c.spot_id = ? ORDER BY c.created_at ASC'
  ).all(spotId);

  res.json(comentarios);
});

router.post('/spots/:id/comentarios', authMiddleware, socialLimiter, validate('comment'), (req, res) => {
  const spotId = parseInt(req.params.id);
  const { contenido } = req.body;

  const spot = spotExists(spotId);
  if (!spot) return res.status(404).json({ error: 'Spot no encontrado' });

  const result = db.prepare('INSERT INTO comentarios (user_id, spot_id, contenido) VALUES (?, ?, ?)').run(req.userId, spotId, contenido);

  const comentario = db.prepare(
    'SELECT c.*, u.username, u.avatar_url FROM comentarios c JOIN usuarios u ON c.user_id = u.id WHERE c.id = ?'
  ).get(result.lastInsertRowid);

  res.status(201).json(comentario);
});

router.delete('/comentarios/:id', authMiddleware, socialLimiter, (req, res) => {
  const commentId = parseInt(req.params.id);

  const deleteError = canDeleteComment(req.userId, commentId);
  if (deleteError) return deny(res, deleteError);

  db.prepare('DELETE FROM comentarios WHERE id = ?').run(commentId);
  res.json({ mensaje: 'Comentario eliminado' });
});

router.post('/usuarios/:id/seguir', authMiddleware, socialLimiter, (req, res) => {
  const targetId = parseInt(req.params.id);
  const userId = req.userId;

  const followError = canFollow(userId, targetId);
  if (followError) return deny(res, followError);

  const target = userExists(targetId);
  if (!target) return res.status(404).json({ error: 'Usuario no encontrado' });

  const existing = db.prepare('SELECT id FROM seguidores WHERE seguidor_id = ? AND seguido_id = ?').get(userId, targetId);
  if (existing) {
    db.prepare('DELETE FROM seguidores WHERE id = ?').run(existing.id);
    return res.json({ siguiendo: false });
  }

  db.prepare('INSERT INTO seguidores (seguidor_id, seguido_id) VALUES (?, ?)').run(userId, targetId);
  res.json({ siguiendo: true });
});

router.get('/usuarios/:id/seguidores', (req, res) => {
  const userId = parseInt(req.params.id);
  const seguidores = db.prepare(
    'SELECT u.id, u.username, u.avatar_url FROM seguidores s JOIN usuarios u ON u.id = s.seguidor_id WHERE s.seguido_id = ?'
  ).all(userId);

  res.json(seguidores);
});

router.get('/usuarios/:id/siguiendo', (req, res) => {
  const userId = parseInt(req.params.id);
  const siguiendo = db.prepare(
    'SELECT u.id, u.username, u.avatar_url FROM seguidores s JOIN usuarios u ON u.id = s.seguido_id WHERE s.seguidor_id = ?'
  ).all(userId);

  res.json(siguiendo);
});

router.get('/usuarios/:id', (req, res) => {
  const userId = parseInt(req.params.id);
  const usuario = db.prepare(
    'SELECT id, email, username, avatar_url, bio, created_at FROM usuarios WHERE id = ?'
  ).get(userId);

  if (!usuario) return res.status(404).json({ error: 'Usuario no encontrado' });

  const stats = db.prepare('SELECT * FROM estadisticas_usuario WHERE user_id = ?').get(usuario.id);
  const spots = db.prepare('SELECT id, nombre, imagen_url, categoria, dificultad, created_at FROM spots WHERE user_id = ? ORDER BY created_at DESC').all(usuario.id);

  res.json({ ...usuario, estadisticas: stats, spots });
});

module.exports = router;
