require('dotenv').config({ path: require('path').join(__dirname, '..', '.env') });
const express = require('express');
const cors = require('cors');
const helmet = require('helmet');
const path = require('path');
const http = require('http');
const { Server } = require('socket.io');
const routes = require('./routes');
const analyticsRoutes = require('./routes/analytics');
const analyticsMiddleware = require('./middleware/analyticsMiddleware');
const { generalLimiter } = require('./middleware/rateLimit');
const { startDiscovery, getLocalIP } = require('./discovery');

const app = express();
const server = http.createServer(app);

const allowedOrigins = process.env.ALLOWED_ORIGINS?.split(',').filter(Boolean) || [];
if (allowedOrigins.length === 0) {
  console.error('WARNING: ALLOWED_ORIGINS no configurado. Usando localhost por defecto.');
  allowedOrigins.push('http://localhost:5173', 'http://localhost:3000');
}

const io = new Server(server, { cors: { origin: allowedOrigins } });

app.use(helmet({ contentSecurityPolicy: false }));
app.use(cors({ origin: allowedOrigins }));
app.use(express.json({ limit: '1mb' }));
app.use(express.urlencoded({ limit: '1mb', extended: true }));
app.use(generalLimiter);
app.use(analyticsMiddleware);

const jwt = require('jsonwebtoken');
io.use((socket, next) => {
  const token = socket.handshake.auth?.token;
  if (!token) return next(new Error('Auth required'));
  try {
    socket.userId = jwt.verify(token, process.env.JWT_SECRET).id;
    next();
  } catch { next(new Error('Invalid token')); }
});

app.use('/uploads', express.static(path.join(__dirname, '..', 'uploads')));
app.use('/api', routes);
app.use('/api/analytics', analyticsRoutes);

app.use((err, req, res, next) => {
  console.error(err.stack);
  res.status(500).json({ error: 'Error interno del servidor' });
});

io.on('connection', (socket) => {
  socket.on('unirse-spot', (spotId) => {
    socket.join(`spot-${spotId}`);
  });

  socket.on('nuevo-comentario', (data) => {
    io.to(`spot-${data.spotId}`).emit('comentario-recibido', data);
  });
});

const PORT = process.env.PORT || 3000;
server.listen(PORT, () => {
  const localIP = process.env.REPORT_IP || getLocalIP();
  console.log(`Servidor outdoor corriendo en http://localhost:${PORT}`);
  console.log(`En tu red local: http://${localIP}:${PORT}`);
  startDiscovery(PORT);
});

module.exports = { app, server, io };
