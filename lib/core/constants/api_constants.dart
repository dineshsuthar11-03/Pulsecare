class ApiConstants {
  // OpenFDA API Configuration
  static const String openFdaBaseUrl = 'https://api.fda.gov';
  static const String drugLabelEndpoint = '/drug/label.json';
  static const String drugEventEndpoint = '/drug/event.json';

  // API Rate Limits
  static const int openFdaRateLimit =
      240; // requests per minute without API key
  static const int openFdaRateLimitWithKey =
      1000; // requests per minute with API key

  // Gemini API Configuration
  static const String geminiModel = 'gemini-1.5-flash';
  static const int geminiMaxTokens = 8192;
  static const double geminiTemperature = 0.7;

  // Cache Configuration
  static const Duration cacheExpiry = Duration(days: 30);
  static const int maxCachedMedicines = 100;

  // Search Configuration
  static const int searchResultsLimit = 20;
  static const int searchDebounceMs = 500;

  // NIH Clinical Tables Search API
  static const String nihConditionsBaseUrl =
      'https://clinicaltables.nlm.nih.gov/api/conditions/v3/search';

  // AI Diagnostic Configuration
  static const String diagnosticModel = 'gemini-1.5-flash';
  static const String fallbackModel = 'gemini-pro';
}
