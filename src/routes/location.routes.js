const express = require('express');

const router = express.Router();

router.post('/update', (req, res) => {
  res.status(501).json({ error: 'Not implemented' });
});

router.get('/live/:sosId', (req, res) => {
  res.status(501).json({ error: 'Not implemented' });
});

module.exports = router;
