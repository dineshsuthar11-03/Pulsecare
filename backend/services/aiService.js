const axios = require('axios');

/**
 * Analyze symptoms with Groq's chat completions API via HTTP.
 * @param {string} symptomsText - Free-text description of symptoms.
 * @param {string} [language] - Optional target language for the response.
 * @returns {Promise<string>} - AI-generated analysis text.
 */
async function analyzeSymptoms(symptomsText, language) {
  const apiKey = process.env.GROQ_API_KEY;
  if (!apiKey) {
    throw new Error('GROQ_API_KEY is missing in environment variables');
  }

  try {
    const response = await axios.post(
      'https://api.groq.com/openai/v1/chat/completions',
      {
        model: 'llama-3.1-8b-instant',
        temperature: 0.3,
        messages: [
          {
            role: 'system',
            content:
              `You are a cautious medical assistant AI. Analyze symptoms carefully, never give a final diagnosis, and always recommend consulting a real doctor. Always respond in ${language || 'English'}.`,
          },
          {
            role: 'user',
            content: `Patient symptoms: ${symptomsText}\n\nProvide:\n1. Possible conditions (bullet list)\n2. Risk level (Low/Medium/High)\n3. Recommended action (e.g., home care / see GP / ER)\n4. Clear disclaimer that this is not a diagnosis.`,
          },
        ],
        stream: false,
      },
      {
        headers: {
          'Content-Type': 'application/json',
          Authorization: `Bearer ${apiKey}`,
        },
      }
    );

    const data = response.data;
    const content =
      data?.choices?.[0]?.message?.content || 'No analysis returned by AI.';
    return content;
  } catch (error) {
    console.error('[Groq AI] Error during symptom analysis:',
      error.response?.data || error.message || error);
    throw new Error('AI Analysis Failed');
  }
}

module.exports = {
  analyzeSymptoms,
};
