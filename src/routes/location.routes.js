const express = require('express');
const { updateLocation, getLiveLocation } = require('../controllers/location.controller');
const { authenticateDevice } = require('../middlewares/auth.middleware');

const router = express.Router();

router.post('/update', authenticateDevice, updateLocation);
router.get('/live/:sosId', getLiveLocation);

module.exports = router;
