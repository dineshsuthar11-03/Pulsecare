import 'package:flutter/material.dart';
import 'package:pulsecare/core/constants/app_colors.dart';
import 'package:url_launcher/url_launcher.dart';

class EmergencyHelpScreen extends StatelessWidget {
  const EmergencyHelpScreen({super.key});

  Future<void> _callNumber(String number) async {
    final uri = Uri(scheme: 'tel', path: number);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              Color(0xFF1F2937),
              Color(0xFF111827),
            ],
          ),
        ),
        child: SafeArea(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Padding(
                padding:
                    const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                child: Row(
                  children: [
                    IconButton(
                      icon: const Icon(Icons.arrow_back, color: Colors.white),
                      onPressed: () => Navigator.of(context).pop(),
                    ),
                    const SizedBox(width: 8),
                    const Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Emergency help (India)',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          SizedBox(height: 4),
                          Text(
                            'Important national helplines and what they are for.',
                            style: TextStyle(
                              color: Colors.white70,
                              fontSize: 12,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 8),
              Expanded(
                child: Container(
                  decoration: const BoxDecoration(
                    color: AppColors.background,
                    borderRadius: BorderRadius.vertical(
                      top: Radius.circular(32),
                    ),
                  ),
                  child: SingleChildScrollView(
                    padding:
                        const EdgeInsets.fromLTRB(20, 24, 20, 32),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Container(
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(20),
                            color: const Color(0xFFB91C1C),
                          ),
                          child: const Row(
                            children: [
                              Icon(Icons.emergency, color: Colors.white,
                                  size: 32),
                              SizedBox(width: 12),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment:
                                      CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      'In a life‑threatening emergency',
                                      style: TextStyle(
                                        color: Colors.white,
                                        fontSize: 16,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                    SizedBox(height: 4),
                                    Text(
                                      'If you or someone around you has severe chest pain, difficulty breathing, heavy bleeding, loss of consciousness, or is in immediate danger, call 112 or your closest emergency number right away.',
                                      style: TextStyle(
                                        color: Colors.white70,
                                        fontSize: 12,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 24),
                        const Text(
                          'Key emergency numbers in India',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: AppColors.textPrimary,
                          ),
                        ),
                        const SizedBox(height: 12),
                        _EmergencyNumberTile(
                          label: '112 – Single emergency helpline',
                          description:
                              'National helpline that connects you to police, fire, or ambulance services based on your situation and location.',
                          number: '112',
                          onCall: _callNumber,
                        ),
                        _EmergencyNumberTile(
                          label: '100 – Police',
                          description:
                              'Call if you feel unsafe, witness violence, theft, or any situation needing police support.',
                          number: '100',
                          onCall: _callNumber,
                        ),
                        _EmergencyNumberTile(
                          label: '101 – Fire service',
                          description:
                              'For fire accidents, gas leaks, or smoke where fire brigade assistance is required.',
                          number: '101',
                          onCall: _callNumber,
                        ),
                        _EmergencyNumberTile(
                          label: '102 – Ambulance (basic medical help)',
                          description:
                              'For medical emergencies needing an ambulance to reach a nearby hospital.',
                          number: '102',
                          onCall: _callNumber,
                        ),
                        _EmergencyNumberTile(
                          label: '108 – Emergency ambulance & disaster response',
                          description:
                              'Widely used in many states for advanced life support ambulances and disaster/accident response.',
                          number: '108',
                          onCall: _callNumber,
                        ),
                        const SizedBox(height: 24),
                        const Text(
                          'Support and specialised helplines',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: AppColors.textPrimary,
                          ),
                        ),
                        const SizedBox(height: 12),
                        _EmergencyNumberTile(
                          label: '1091 – Women helpline',
                          description:
                              'For women facing harassment, violence, or feeling unsafe and needing urgent police support.',
                          number: '1091',
                          onCall: _callNumber,
                        ),
                        _EmergencyNumberTile(
                          label: '181 – Women helpline (many states)',
                          description:
                              'State‑level women support helpline available in many regions for counselling and assistance.',
                          number: '181',
                          onCall: _callNumber,
                        ),
                        _EmergencyNumberTile(
                          label: '1098 – Child helpline',
                          description:
                              'For children in distress, abuse, neglect, or any situation where a child needs protection.',
                          number: '1098',
                          onCall: _callNumber,
                        ),
                        const SizedBox(height: 24),
                        const Text(
                          'Important notes',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                            color: AppColors.textPrimary,
                          ),
                        ),
                        const SizedBox(height: 8),
                        const Text(
                          '''• Availability of some numbers (like 108, 181) can vary by state.
• Try to stay calm, speak clearly, and share your exact location (landmarks, street name, city).
• Keep your phone charged and accessible, especially if you have a history of serious medical conditions.''',
                          style: TextStyle(
                            fontSize: 13,
                            height: 1.4,
                            color: AppColors.textSecondary,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _EmergencyNumberTile extends StatelessWidget {
  final String label;
  final String description;
  final String number;
  final Future<void> Function(String) onCall;

  const _EmergencyNumberTile({
    required this.label,
    required this.description,
    required this.number,
    required this.onCall,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(18),
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.03),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: Colors.red.withOpacity(0.08),
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.call,
              color: Colors.red,
              size: 22,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                    color: AppColors.textPrimary,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  description,
                  style: const TextStyle(
                    fontSize: 13,
                    color: AppColors.textSecondary,
                  ),
                ),
                const SizedBox(height: 6),
                GestureDetector(
                  onTap: () => onCall(number),
                  child: Container(
                    margin: const EdgeInsets.only(top: 6),
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 6,
                    ),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(16),
                      color: const Color(0xFFEF4444).withOpacity(0.08),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(
                          Icons.phone_in_talk,
                          size: 16,
                          color: Color(0xFFB91C1C),
                        ),
                        const SizedBox(width: 6),
                        Text(
                          number,
                          style: const TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFFB91C1C),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
