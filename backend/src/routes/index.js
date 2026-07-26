const express = require('express');
const router = express.Router();

router.use('/auth', require('./auth'));
router.use('/spots', require('./spots'));
router.use('/social', require('./social'));
router.use('/', require('./checkin'));
router.use('/logros', require('./logros'));
router.use('/admin', require('./admin'));

router.get('/health', (req, res) => {
  res.json({ status: 'ok', message: 'Outdoor Social API funcionando' });
});

module.exports = router;
