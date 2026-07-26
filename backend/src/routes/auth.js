const express = require('express');
const bcrypt = require('bcryptjs');
const jwt = require('jsonwebtoken');
const db = require('../database');
const { authLimiter } = require('../middleware/rateLimit');
const { validate } = require('../middleware/validate');

const router = express.Router();

router.post('/register', authLimiter, validate('register'), (req, res) => {
  const { email, username, password } = req.body;

  const exists = db.prepare('SELECT id FROM usuarios WHERE email = ? OR username = ?').get(email, username);
  if (exists) {
    return res.status(409).json({ error: 'Datos ya registrados' });
  }

  const password_hash = bcrypt.hashSync(password, 10);
  const result = db.prepare(
    'INSERT INTO usuarios (email, username, password_hash) VALUES (?, ?, ?)'
  ).run(email, username, password_hash);

  db.prepare('INSERT INTO estadisticas_usuario (user_id) VALUES (?)').run(result.lastInsertRowid);

  const token = jwt.sign({ id: result.lastInsertRowid }, process.env.JWT_SECRET, { expiresIn: '30d' });

  res.status(201).json({
    token,
    usuario: { id: result.lastInsertRowid, email, username, es_admin: 0 }
  });
});

router.post('/login', authLimiter, validate('login'), (req, res) => {
  const { email, password } = req.body;

  const usuario = db.prepare('SELECT * FROM usuarios WHERE email = ?').get(email);
  if (!usuario || !bcrypt.compareSync(password, usuario.password_hash)) {
    return res.status(401).json({ error: 'Credenciales inválidas' });
  }

  const token = jwt.sign({ id: usuario.id }, process.env.JWT_SECRET, { expiresIn: '30d' });

  res.json({
    token,
    usuario: { id: usuario.id, email: usuario.email, username: usuario.username, es_admin: usuario.es_admin || 0 }
  });
});

router.get('/perfil', (req, res) => {
  const authHeader = req.headers.authorization;
  if (!authHeader || !authHeader.startsWith('Bearer ')) {
    return res.status(401).json({ error: 'Token requerido' });
  }

  try {
    const decoded = jwt.verify(authHeader.split(' ')[1], process.env.JWT_SECRET);
    const usuario = db.prepare(
      'SELECT id, email, username, avatar_url, bio, es_admin, created_at FROM usuarios WHERE id = ?'
    ).get(decoded.id);

    if (!usuario) return res.status(404).json({ error: 'Usuario no encontrado' });

    const stats = db.prepare('SELECT * FROM estadisticas_usuario WHERE user_id = ?').get(usuario.id);

    res.json({ ...usuario, estadisticas: stats });
  } catch {
    return res.status(401).json({ error: 'Token inválido' });
  }
});

module.exports = router;
