const dgram = require('dgram');
const os = require('os');

const DISCOVERY_PORT = 42069;
const DISCOVERY_MSG = 'OUTDOOR_DISCOVER';

function getLocalIP() {
  const interfaces = os.networkInterfaces();
  for (const name of Object.keys(interfaces)) {
    for (const iface of interfaces[name]) {
      if (iface.family === 'IPv4' && !iface.internal) return iface.address;
    }
  }
  return '127.0.0.1';
}

function startDiscovery(apiPort) {
  const forcedIP = process.env.REPORT_IP;
  const localIP = forcedIP || getLocalIP();
  if (forcedIP) console.log(`Discovery usando IP forzada: ${forcedIP}`);
  const server = dgram.createSocket({ type: 'udp4', reuseAddr: true });

  server.on('error', (err) => {
    console.error('Discovery error:', err.message);
  });

  server.on('message', (msg, rinfo) => {
    const received = msg.toString().trim();
    if (received === DISCOVERY_MSG) {
      const response = JSON.stringify({ ip: localIP, port: apiPort });
      server.send(response, rinfo.port, rinfo.address, (err) => {
        if (err) console.error('Discovery send error:', err.message);
      });
    }
  });

  server.on('listening', () => {
    const addr = server.address();
    console.log(`Discovery UDP escuchando en ${addr.address}:${addr.port}`);
  });

  server.bind(DISCOVERY_PORT, () => {
    server.setBroadcast(true);
  });

  return server;
}

module.exports = { startDiscovery, getLocalIP, DISCOVERY_PORT, DISCOVERY_MSG };
