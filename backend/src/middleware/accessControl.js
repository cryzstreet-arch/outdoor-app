const db = require('../database');

function canReadSpot(userId, spotId) {
  return !!db.prepare('SELECT id FROM spots WHERE id = ?').get(spotId);
}

function canEditSpot(userId, spotId) {
  const spot = db.prepare('SELECT user_id FROM spots WHERE id = ?').get(spotId);
  if (!spot) return false;
  if (spot.user_id === userId) return true;
  const admin = db.prepare('SELECT es_admin FROM usuarios WHERE id = ?').get(userId);
  return admin && admin.es_admin === 1;
}

function canDeleteSpot(userId, spotId) {
  return canEditSpot(userId, spotId);
}

function canLike(userId, spotId) {
  const existing = db.prepare('SELECT id FROM likes WHERE user_id = ? AND spot_id = ?').get(userId, spotId);
  return !existing;
}

function canComment(userId, spotId) {
  return !!db.prepare('SELECT id FROM spots WHERE id = ?').get(spotId);
}

function canDeleteComment(userId, commentId) {
  const comment = db.prepare('SELECT user_id FROM comentarios WHERE id = ?').get(commentId);
  if (!comment) return false;
  if (comment.user_id === userId) return true;
  const admin = db.prepare('SELECT es_admin FROM usuarios WHERE id = ?').get(userId);
  return admin && admin.es_admin === 1;
}

function canFollow(userId, targetId) {
  if (userId === targetId) return false;
  const existing = db.prepare('SELECT id FROM seguidores WHERE seguidor_id = ? AND seguido_id = ?').get(userId, targetId);
  return !existing;
}

function canUnfollow(userId, targetId) {
  const existing = db.prepare('SELECT id FROM seguidores WHERE seguidor_id = ? AND seguido_id = ?').get(userId, targetId);
  return !!existing;
}

function canCheckin(userId, spotId) {
  const recent = db.prepare(
    "SELECT id FROM checkins WHERE user_id = ? AND spot_id = ? AND created_at > datetime('now', '-24 hours')"
  ).get(userId, spotId);
  return !recent;
}

function spotExists(spotId) {
  return !!db.prepare('SELECT id FROM spots WHERE id = ?').get(spotId);
}

function userExists(userId) {
  return !!db.prepare('SELECT id FROM usuarios WHERE id = ?').get(userId);
}

function deny(res, msg) {
  return res.status(403).json({ error: msg || 'No tienes permiso para esta acción' });
}

module.exports = {
  canReadSpot, canEditSpot, canDeleteSpot,
  canLike, canComment, canDeleteComment,
  canFollow, canUnfollow, canCheckin,
  spotExists, userExists, deny,
};
