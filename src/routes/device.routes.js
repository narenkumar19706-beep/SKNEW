const express = require('express');
const {
  registerDevice,
  getProfile,
  updateProfile,
} = require('../controllers/device.controller');
const { authenticateDevice } = require('../middlewares/auth.middleware');

const router = express.Router();

router.post('/register', registerDevice);
router.get('/profile', authenticateDevice, getProfile);
router.put('/profile', authenticateDevice, updateProfile);

module.exports = router;
