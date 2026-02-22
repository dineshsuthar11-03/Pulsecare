const express = require('express');
const router = express.Router();
const { getAnalysis } = require('../controllers/aiController');

// @route POST /api/ai/analyze
router.post('/analyze', getAnalysis);

module.exports = router;
