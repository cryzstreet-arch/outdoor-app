const express = require('express');
const db = require('../database');
const { adminMiddleware } = require('../middleware/auth');

const router = express.Router();

router.post('/', (req, res) => {
  try {
    const { event_type, event_name, metadata } = req.body;
    if (!event_type || !event_name) return res.status(400).json({ error: 'event_type y event_name requeridos' });

    db.prepare(
      `INSERT INTO analytics (event_type, event_name, user_id, metadata, ip_address, user_agent)
       VALUES (?, ?, ?, ?, ?, ?)`
    ).run(
      event_type,
      event_name,
      req.userId || null,
      JSON.stringify(metadata || {}),
      req.ip || req.connection?.remoteAddress || null,
      req.headers['user-agent']?.substring(0, 200) || null
    );

    res.json({ ok: true });
  } catch (e) {
    res.status(500).json({ error: 'Error guardando analytics' });
  }
});

router.get('/resumen', adminMiddleware, (req, res) => {
  try {
    const totalEvents = db.prepare('SELECT COUNT(*) as total FROM analytics').get().total;

    const topEvents = db.prepare(
      `SELECT event_name, COUNT(*) as count FROM analytics
       GROUP BY event_name ORDER BY count DESC LIMIT 10`
    ).all();

    const topScreens = db.prepare(
      `SELECT event_name, COUNT(*) as count FROM analytics
       WHERE event_type = 'screen_view'
       GROUP BY event_name ORDER BY count DESC LIMIT 10`
    ).all();

    const errors = db.prepare(
      `SELECT event_name, COUNT(*) as count FROM analytics
       WHERE event_type = 'error'
       GROUP BY event_name ORDER BY count DESC LIMIT 10`
    ).all();

    const activeUsers = db.prepare(
      `SELECT COUNT(DISTINCT user_id) as total FROM analytics WHERE user_id IS NOT NULL`
    ).get().total;

    const eventsByDay = db.prepare(
      `SELECT date(created_at) as day, COUNT(*) as count
       FROM analytics GROUP BY day ORDER BY day DESC LIMIT 7`
    ).all();

    res.json({
      totalEvents,
      activeUsers,
      topEvents,
      topScreens,
      errors,
      eventsByDay,
    });
  } catch (e) {
    res.status(500).json({ error: 'Error obteniendo resumen' });
  }
});

router.get('/eventos', adminMiddleware, (req, res) => {
  try {
    const limit = Math.min(parseInt(req.query.limit) || 50, 200);
    const offset = parseInt(req.query.offset) || 0;
    const type = req.query.type;

    let query = 'SELECT a.*, u.username FROM analytics a LEFT JOIN usuarios u ON a.user_id = u.id';
    const params = [];

    if (type) {
      query += ' WHERE a.event_type = ?';
      params.push(type);
    }

    query += ' ORDER BY a.created_at DESC LIMIT ? OFFSET ?';
    params.push(limit, offset);

    const eventos = db.prepare(query).all(...params);
    res.json(eventos);
  } catch (e) {
    res.status(500).json({ error: 'Error obteniendo eventos' });
  }
});

module.exports = router;
