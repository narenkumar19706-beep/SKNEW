const express = require('express');
const { triggerSos, addUpdate, resolveActiveSos } = require('../controllers/sos.controller');
const { authenticateDevice } = require('../middlewares/auth.middleware');

const router = express.Router();

router.post('/trigger', authenticateDevice, triggerSos);
router.post('/update', authenticateDevice, addUpdate);
router.post('/resolve', authenticateDevice, resolveActiveSos);

module.exports = router;
