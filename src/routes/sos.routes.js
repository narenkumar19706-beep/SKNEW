const express = require('express');

const router = express.Router();

router.post('/trigger', (req, res) => {
  res.status(501).json({ error: 'Not implemented' });
});

router.post('/update', (req, res) => {
  res.status(501).json({ error: 'Not implemented' });
});

router.post('/resolve', (req, res) => {
  res.status(501).json({ error: 'Not implemented' });
});

module.exports = router;
