const Joi = require('joi');

function sanitizeString(str) {
  if (typeof str !== 'string') return str;
  return str
    .replace(/<script\b[^<]*(?:(?!<\/script>)<[^<]*)*<\/script>/gi, '')
    .replace(/<iframe\b[^<]*(?:(?!<\/iframe>)<[^<]*)*<\/iframe>/gi, '')
    .replace(/on\w+\s*=/gi, 'data-blocked=')
    .replace(/javascript:/gi, 'blocked:')
    .trim();
}

function sanitizeObject(obj) {
  if (!obj || typeof obj !== 'object') return obj;
  const clean = {};
  for (const [key, val] of Object.entries(obj)) {
    if (typeof val === 'string') {
      clean[key] = sanitizeString(val);
    } else {
      clean[key] = val;
    }
  }
  return clean;
}

const schemas = {
  register: Joi.object({
    email: Joi.string().email().required().max(255),
    username: Joi.string().alphanum().min(3).max(20).required(),
    password: Joi.string().min(6).max(128).required(),
  }),

  login: Joi.object({
    email: Joi.string().email().required(),
    password: Joi.string().required(),
  }),

  createSpot: Joi.object({
    nombre: Joi.string().min(3).max(100).required(),
    descripcion: Joi.string().max(2000).allow('', null),
    lat: Joi.number().min(-90).max(90).required(),
    lng: Joi.number().min(-180).max(180).required(),
    categoria: Joi.string().valid('senderismo','pesca','camping','escalada','kayak','observacion','mirador','natural','running','otro').default('otro'),
    dificultad: Joi.string().valid('facil','medio','dificil').default('facil'),
    hide_radius: Joi.number().min(10).max(50000).default(3000),
    reveal_radius: Joi.number().min(10).max(20000).default(1000),
    detail_radius: Joi.number().min(10).max(5000).default(300),
    gps_radius: Joi.number().min(5).max(1000).default(50),
    start_lat: Joi.number().min(-90).max(90).allow(null),
    start_lng: Joi.number().min(-180).max(180).allow(null),
  }),

  updateSpot: Joi.object({
    nombre: Joi.string().min(3).max(100),
    descripcion: Joi.string().max(2000).allow('', null),
    categoria: Joi.string().valid('senderismo','pesca','camping','escalada','kayak','observacion','mirador','natural','running','otro'),
    dificultad: Joi.string().valid('facil','medio','dificil'),
    hide_radius: Joi.number().min(10).max(50000),
    reveal_radius: Joi.number().min(10).max(20000),
    detail_radius: Joi.number().min(10).max(5000),
    gps_radius: Joi.number().min(5).max(1000),
    start_lat: Joi.number().min(-90).max(90).allow(null),
    start_lng: Joi.number().min(-180).max(180).allow(null),
  }).min(1),

  comment: Joi.object({
    contenido: Joi.string().min(1).max(500).required(),
  }),

  pagination: Joi.object({
    page: Joi.number().integer().min(1).default(1),
    limit: Joi.number().integer().min(1).max(100).default(20),
    categoria: Joi.string().valid('senderismo','pesca','camping','escalada','kayak','observacion','mirador','natural','running','otro'),
    dificultad: Joi.string().valid('facil','medio','dificil'),
  }),

  nearby: Joi.object({
    lat: Joi.number().min(-90).max(90).required(),
    lng: Joi.number().min(-180).max(180).required(),
    radio: Joi.number().min(10).max(50000).default(5000),
  }),
};

function validate(schemaName) {
  return (req, res, next) => {
    const schema = schemas[schemaName];
    if (!schema) return next();

    if (req.body && typeof req.body === 'object') {
      req.body = sanitizeObject(req.body);
    }

    const dataToValidate = schemaName === 'pagination' || schemaName === 'nearby'
      ? req.query
      : req.body;

    const { error, value } = schema.validate(dataToValidate, { abortEarly: false, stripUnknown: true });
    if (error) {
      const msgs = error.details.map(d => d.message);
      return res.status(400).json({ error: msgs.join(', ') });
    }

    if (schemaName === 'pagination' || schemaName === 'nearby') {
      Object.assign(req.query, value);
    } else {
      req.body = value;
    }
    next();
  };
}

module.exports = { validate, schemas, sanitizeString };
