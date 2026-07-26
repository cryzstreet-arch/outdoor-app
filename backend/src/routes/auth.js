const express = require('express');
const bcrypt = require('bcryptjs');
const jwt = require('jsonwebtoken');
const db = require('../database');

const router = express.Router();

router.post('/register', (req, res) => {
  const { email, username, password } = req.body;

  if (!email || !username || !password) {
    return res.status(400).json({ error: 'Email, usuario y contraseña requeridos' });
  }

  const emailRegex = /^[^\s@]+@[^\s@]+\.[^\s@]+$/;
  if (!emailRegex.test(email)) return res.status(400).json({ error: 'Email inválido' });
  if (!/^[a-zA-Z0-9_]{3,20}$/.test(username)) return res.status(400).json({ error: 'Usuario: 3-20 caracteres, solo letras, números y _' });

  if (password.length < 6) {
    return res.status(400).json({ error: 'La contraseña debe tener al menos 6 caracteres' });
  }

  const exists = db.prepare('SELECT id FROM usuarios WHERE email = ? OR username = ?').get(email, username);
  if (exists) {
    return res.status(409).json({ error: 'El email o usuario ya está registrado' });
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

router.post('/login', (req, res) => {
  const { email, password } = req.body;

  if (!email || !password) {
    return res.status(400).json({ error: 'Email y contraseña requeridos' });
  }

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
