const express = require('express');
const router = express.Router();
const medicineController = require('../controllers/medicineController');

// @route GET /api/medicines/search?q=...
router.get('/search', medicineController.searchMedicines);

// @route GET /api/medicines/alternatives?activeIngredient=...&excludeId=...
router.get('/alternatives', medicineController.getAlternatives);

module.exports = router;
