const jwt = require('jsonwebtoken');
const db = require('../database');

function authMiddleware(req, res, next) {
  const header = req.headers.authorization;
  if (!header || !header.startsWith('Bearer ')) {
    return res.status(401).json({ error: 'Token requerido' });
  }

  const token = header.split(' ')[1];
  try {
    const decoded = jwt.verify(token, process.env.JWT_SECRET);
    req.userId = decoded.id;
    next();
  } catch {
    return res.status(401).json({ error: 'Token inválido' });
  }
}

function adminMiddleware(req, res, next) {
  const header = req.headers.authorization;
  if (!header || !header.startsWith('Bearer ')) {
    return res.status(401).json({ error: 'Token requerido' });
  }

  const token = header.split(' ')[1];
  try {
    const decoded = jwt.verify(token, process.env.JWT_SECRET);
    const user = db.prepare('SELECT es_admin FROM usuarios WHERE id = ?').get(decoded.id);
    if (!user || !user.es_admin) {
      return res.status(403).json({ error: 'Acceso solo para administradores' });
    }
    req.userId = decoded.id;
    next();
  } catch {
    return res.status(401).json({ error: 'Token inválido' });
  }
}

module.exports = { authMiddleware, adminMiddleware };