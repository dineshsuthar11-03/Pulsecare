const { analyzeSymptoms } = require('../services/aiService');

// POST /api/ai/analyze
async function getAnalysis(req, res) {
  try {
    const { symptoms } = req.body;

    if (!symptoms || (typeof symptoms !== 'string' && !Array.isArray(symptoms))) {
      return res.status(400).json({
        success: false,
        message: 'symptoms must be a string or an array of strings',
      });
    }

    const symptomsText = Array.isArray(symptoms) ? symptoms.join(', ') : symptoms;

    const result = await analyzeSymptoms(symptomsText);

    return res.status(200).json({
      success: true,
      analysis: result,
    });
  } catch (error) {
    console.error('[AI Controller] Error:', error.message || error);
    return res.status(500).json({
      success: false,
      message: 'AI analysis failed',
    });
  }
}

module.exports = {
  getAnalysis,
};
