const express = require('express');
const router = express.Router();
const symptomController = require('../controllers/symptomController');

// @route POST /api/symptoms/analyze
router.post('/analyze', symptomController.analyzeSymptoms);

module.exports = router;
