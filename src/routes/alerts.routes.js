const express = require('express');
const { getDistrictAlerts } = require('../controllers/alerts.controller');
const { authenticateDevice } = require('../middlewares/auth.middleware');

const router = express.Router();

router.get('/district', authenticateDevice, getDistrictAlerts);

module.exports = router;
