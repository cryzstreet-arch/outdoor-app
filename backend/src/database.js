const Database = require('better-sqlite3');
const bcrypt = require('bcryptjs');
const path = require('path');

const db = new Database(path.join(__dirname, '..', 'outdoor.db'));

db.pragma('journal_mode = WAL');
db.pragma('foreign_keys = ON');

db.exec(`
  CREATE TABLE IF NOT EXISTS usuarios (
    id INTEGER PRIMARY KEY AUTOINCREMENT,
    email TEXT UNIQUE NOT NULL,
    username TEXT UNIQUE NOT NULL,
    password_hash TEXT NOT NULL,
    avatar_url TEXT DEFAULT NULL,
    bio TEXT DEFAULT '',
    es_admin INTEGER DEFAULT 0,
    created_at DATETIME DEFAULT CURRENT_TIMESTAMP
  );

  CREATE TABLE IF NOT EXISTS spots (
    id INTEGER PRIMARY KEY AUTOINCREMENT,
    user_id INTEGER NOT NULL,
    nombre TEXT NOT NULL,
    descripcion TEXT DEFAULT '',
    lat REAL NOT NULL,
    lng REAL NOT NULL,
    categoria TEXT DEFAULT 'otro',
    dificultad TEXT DEFAULT 'facil',
    imagen_url TEXT DEFAULT NULL,
    hide_radius REAL DEFAULT 3000,
    reveal_radius REAL DEFAULT 1000,
    detail_radius REAL DEFAULT 300,
    gps_radius REAL DEFAULT 50,
    start_lat REAL DEFAULT NULL,
    start_lng REAL DEFAULT NULL,
    created_at DATETIME DEFAULT CURRENT_TIMESTAMP,
    FOREIGN KEY (user_id) REFERENCES usuarios(id)
  );

  CREATE TABLE IF NOT EXISTS likes (
    id INTEGER PRIMARY KEY AUTOINCREMENT,
    user_id INTEGER NOT NULL,
    spot_id INTEGER NOT NULL,
    created_at DATETIME DEFAULT CURRENT_TIMESTAMP,
    UNIQUE(user_id, spot_id),
    FOREIGN KEY (user_id) REFERENCES usuarios(id),
    FOREIGN KEY (spot_id) REFERENCES spots(id)
  );

  CREATE TABLE IF NOT EXISTS comentarios (
    id INTEGER PRIMARY KEY AUTOINCREMENT,
    user_id INTEGER NOT NULL,
    spot_id INTEGER NOT NULL,
    contenido TEXT NOT NULL,
    created_at DATETIME DEFAULT CURRENT_TIMESTAMP,
    FOREIGN KEY (user_id) REFERENCES usuarios(id),
    FOREIGN KEY (spot_id) REFERENCES spots(id)
  );

  CREATE TABLE IF NOT EXISTS seguidores (
    id INTEGER PRIMARY KEY AUTOINCREMENT,
    seguidor_id INTEGER NOT NULL,
    seguido_id INTEGER NOT NULL,
    created_at DATETIME DEFAULT CURRENT_TIMESTAMP,
    UNIQUE(seguidor_id, seguido_id),
    FOREIGN KEY (seguidor_id) REFERENCES usuarios(id),
    FOREIGN KEY (seguido_id) REFERENCES usuarios(id)
  );

  CREATE TABLE IF NOT EXISTS logros (
    id INTEGER PRIMARY KEY AUTOINCREMENT,
    nombre TEXT NOT NULL,
    descripcion TEXT DEFAULT '',
    icono TEXT DEFAULT 'medalla_default',
    tipo TEXT NOT NULL,
    criterio TEXT DEFAULT NULL,
    umbral INTEGER DEFAULT NULL,
    created_at DATETIME DEFAULT CURRENT_TIMESTAMP
  );

  CREATE TABLE IF NOT EXISTS logros_usuario (
    id INTEGER PRIMARY KEY AUTOINCREMENT,
    user_id INTEGER NOT NULL,
    logro_id INTEGER NOT NULL,
    spot_id INTEGER DEFAULT NULL,
    desbloqueado_en DATETIME DEFAULT CURRENT_TIMESTAMP,
    UNIQUE(user_id, logro_id, spot_id),
    FOREIGN KEY (user_id) REFERENCES usuarios(id),
    FOREIGN KEY (logro_id) REFERENCES logros(id)
  );

  CREATE TABLE IF NOT EXISTS checkins (
    id INTEGER PRIMARY KEY AUTOINCREMENT,
    user_id INTEGER NOT NULL,
    spot_id INTEGER NOT NULL,
    created_at DATETIME DEFAULT CURRENT_TIMESTAMP,
    UNIQUE(user_id, spot_id),
    FOREIGN KEY (user_id) REFERENCES usuarios(id),
    FOREIGN KEY (spot_id) REFERENCES spots(id)
  );

  CREATE TABLE IF NOT EXISTS publicaciones (
    id INTEGER PRIMARY KEY AUTOINCREMENT,
    user_id INTEGER NOT NULL,
    spot_id INTEGER NOT NULL,
    imagen_url TEXT NOT NULL,
    descripcion TEXT DEFAULT '',
    created_at DATETIME DEFAULT CURRENT_TIMESTAMP,
    FOREIGN KEY (user_id) REFERENCES usuarios(id),
    FOREIGN KEY (spot_id) REFERENCES spots(id)
  );

  CREATE TABLE IF NOT EXISTS estadisticas_usuario (
    id INTEGER PRIMARY KEY AUTOINCREMENT,
    user_id INTEGER UNIQUE NOT NULL,
    total_km REAL DEFAULT 0,
    total_checkins INTEGER DEFAULT 0,
    total_facil INTEGER DEFAULT 0,
    total_medio INTEGER DEFAULT 0,
    total_dificil INTEGER DEFAULT 0,
    ultima_publicacion DATETIME DEFAULT NULL,
    prime_activo INTEGER DEFAULT 0,
    updated_at DATETIME DEFAULT CURRENT_TIMESTAMP,
    FOREIGN KEY (user_id) REFERENCES usuarios(id)
  );
`);

const rootExists = db.prepare('SELECT id FROM usuarios WHERE username = ?').get('root');
if (!rootExists) {
  const hash = bcrypt.hashSync('1q2w3e4r5t', 10);
  db.prepare(
    'INSERT INTO usuarios (email, username, password_hash, es_admin) VALUES (?, ?, ?, ?)'
  ).run('root@admin', 'root', hash, 1);
  const rootId = db.prepare('SELECT id FROM usuarios WHERE username = ?').get('root');
  if (rootId) {
    db.prepare('INSERT OR IGNORE INTO estadisticas_usuario (user_id) VALUES (?)').run(rootId.id);
  }
  console.log('Usuario root creado (admin)');
} else {
  db.prepare('UPDATE usuarios SET es_admin = 1 WHERE username = ?').run('root');
}

module.exports = db;
