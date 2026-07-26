#!/bin/bash
cd "$(dirname "$0")/backend"
echo "=== Iniciando servidor Outdoor Social ==="
echo "Puerto: ${PORT:-3000}"
echo ""
npm install --production 2>&1 | tail -3
node src/index.js
