const { analyzeSymptoms } = require('../services/aiService');

// Legacy endpoint now powered by Groq instead of RapidAPI.
exports.analyzeSymptoms = async (req, res) => {
    try {
        const { symptoms, gender, age, language } = req.body;

        if (!symptoms || (!Array.isArray(symptoms) && typeof symptoms !== 'string')) {
            return res.status(400).json({ error: 'symptoms must be a string or an array of strings' });
        }

        const symptomsText = Array.isArray(symptoms) ? symptoms.join(', ') : symptoms;

        const analysis = await analyzeSymptoms(symptomsText, language);

        return res.json({
            success: true,
            analysis,
            meta: {
                engine: 'groq',
                gender,
                age,
                language: language || 'English',
            },
        });
    } catch (err) {
        console.error('[SymptomController] Groq AI error:', err.message || err);
        return res.status(500).json({
            success: false,
            error: 'Failed to analyze symptoms with AI',
        });
    }
};
