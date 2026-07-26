const db = require('../database');

function analyticsMiddleware(req, res, next) {
  const start = Date.now();

  res.on('finish', () => {
    try {
      const duration = Date.now() - start;
      const userId = req.userId || null;

      db.prepare(
        `INSERT INTO analytics (event_type, event_name, user_id, metadata, ip_address, user_agent)
         VALUES (?, ?, ?, ?, ?, ?)`
      ).run(
        'request',
        `${req.method} ${req.path}`,
        userId,
        JSON.stringify({ status: res.statusCode, duration }),
        req.ip || req.connection?.remoteAddress || null,
        req.headers['user-agent']?.substring(0, 200) || null
      );
    } catch (_) {}
  });

  next();
}

module.exports = analyticsMiddleware;
