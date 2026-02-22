const medicineService = require('../services/medicineService');

exports.searchMedicines = (req, res) => {
  try {
    const { q, limit } = req.query;

    if (!q || !q.trim()) {
      return res.status(400).json({ error: 'Query parameter "q" is required.' });
    }

    const numericLimit = Number.parseInt(limit, 10);
    const safeLimit = Number.isFinite(numericLimit) && numericLimit > 0
      ? Math.min(numericLimit, 50)
      : 20;

    const results = medicineService.searchMedicines(q, safeLimit);
    return res.json(results);
  } catch (err) {
    console.error('[MedicineController] searchMedicines error:', err.message || err);
    return res.status(500).json({ error: 'Failed to search medicines.' });
  }
};

exports.getAlternatives = (req, res) => {
  try {
    const { activeIngredient, excludeId, limit } = req.query;

    if (!activeIngredient || !activeIngredient.trim()) {
      return res
        .status(400)
        .json({ error: 'Query parameter "activeIngredient" is required.' });
    }

    const numericLimit = Number.parseInt(limit, 10);
    const safeLimit = Number.isFinite(numericLimit) && numericLimit > 0
      ? Math.min(numericLimit, 20)
      : 5;

    const results = medicineService.getAlternatives(
      activeIngredient,
      excludeId,
      safeLimit,
    );

    return res.json(results);
  } catch (err) {
    console.error('[MedicineController] getAlternatives error:', err.message || err);
    return res.status(500).json({ error: 'Failed to load alternative medicines.' });
  }
};
