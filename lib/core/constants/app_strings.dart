class AppStrings {
  // App Info
  static const String appName = 'PulseCare';
  static const String appTagline = 'Your Preliminary Health Assistant';

  // Medical Disclaimer
  static const String medicalDisclaimer =
      'This app provides educational health information only. '
      'It is NOT a replacement for professional medical advice, diagnosis, or treatment. '
      'Always consult qualified healthcare professionals for medical concerns.';

  static const String shortDisclaimer =
      'Not medical advice. Consult a healthcare professional.';

  static const String emergencyWarning =
      'EMERGENCY: If experiencing severe symptoms, chest pain, difficulty breathing, '
      'or life-threatening conditions, call emergency services immediately.';

  // Home Screen
  static const String homeWelcome = 'Welcome to PulseCare';
  static const String homeSubtitle = 'How can we assist you today?';

  // Feature Cards
  static const String symptomCheckerTitle = 'Symptom Checker';
  static const String symptomCheckerDesc =
      'Describe your symptoms and get AI-powered guidance';

  static const String medicineGuideTitle = 'Medicine Guide';
  static const String medicineGuideDesc =
      'Search medicines and learn about safe usage';

  // Symptom Checker
  static const String symptomInputHint = 'Describe your symptoms...';
  static const String symptomInputPrompt =
      'Tell me about your symptoms. Be specific about duration, severity, and any other details.';

  // Medicine Guide
  static const String medicineSearchHint = 'Search for a medicine...';
  static const String medicineSearchEmpty =
      'No medicines found. Try a different search.';
  static const String recentSearches = 'Recent Searches';

  // Dosage Safety
  static const String dosageSafetyTitle = 'Dosage & Safety';
  static const String neverExceed = 'NEVER EXCEED';
  static const String recommendedDose = 'Recommended Dose';
  static const String maximumDose = 'Maximum Daily Dose';
  static const String overdoseWarning =
      'Taking more than the recommended dose can cause serious health issues. '
      'Contact poison control or seek emergency care if overdose is suspected.';

  // Alternatives
  static const String alternativesTitle = 'Alternative Medicines';
  static const String noAlternatives = 'No alternatives found.';

  // Actions
  static const String consultDoctor = 'Consult a Doctor';
  static const String viewDetails = 'View Details';
  static const String startNewCheck = 'Start New Check';
  static const String searchNow = 'Search';
  static const String send = 'Send';

  // Error Messages
  static const String errorNoInternet =
      'No internet connection. Some features require internet access.';
  static const String errorApiLimit =
      'API rate limit reached. Please try again later.';
  static const String errorGeneric = 'Something went wrong. Please try again.';
  static const String errorLoadingMedicine =
      'Failed to load medicine information.';

  // Loading Messages
  static const String loadingAnalyzing = 'Analyzing symptoms...';
  static const String loadingSearching = 'Searching medicines...';
  static const String loadingMedicine = 'Loading medicine details...';

  // Severity Levels
  static const String severityLow = 'Low Urgency';
  static const String severityMedium = 'Moderate - See Doctor Soon';
  static const String severityHigh = 'High - Seek Medical Attention';
  static const String severityEmergency = 'EMERGENCY - Call 911';
}
