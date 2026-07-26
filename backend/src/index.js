require('dotenv').config({ path: require('path').join(__dirname, '..', '.env') });
const express = require('express');
const cors = require('cors');
const path = require('path');
const http = require('http');
const { Server } = require('socket.io');
const routes = require('./routes');
const { startDiscovery, getLocalIP } = require('./discovery');

const app = express();
const server = http.createServer(app);
const io = new Server(server, { cors: { origin: '*' } });

app.use(cors());
app.use(express.json());
app.use('/uploads', express.static(path.join(__dirname, '..', 'uploads')));

app.use('/api', routes);

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
