const express = require('express');
const db = require('../database');
const { authMiddleware } = require('../middleware/auth');

const router = express.Router();

router.get('/', authMiddleware, (req, res) => {
  const logros = db.prepare(
    `SELECT l.*, lu.desbloqueado_en,
      CASE WHEN lu.id IS NOT NULL THEN 1 ELSE 0 END as desbloqueado
    FROM logros l
    LEFT JOIN logros_usuario lu ON l.id = lu.logro_id AND lu.user_id = ?
    ORDER BY l.tipo, l.umbral ASC`
  ).all(req.userId);

  res.json(logros);
});

router.get('/usuario/:id', (req, res) => {
  const logros = db.prepare(
    `SELECT l.*, lu.desbloqueado_en, lu.spot_id
    FROM logros_usuario lu
    JOIN logros l ON l.id = lu.logro_id
    WHERE lu.user_id = ?
    ORDER BY lu.desbloqueado_en DESC`
  ).all(req.params.id);

  res.json(logros);
});

module.exports = router;
