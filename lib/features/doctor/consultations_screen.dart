import 'package:flutter/material.dart';
import 'package:carelink/core/constants/app_colors.dart';
import 'package:carelink/core/services/consultation_service.dart';
import 'package:carelink/features/doctor/patient_detail_screen.dart';
import 'package:intl/intl.dart';

class ConsultationsScreen extends StatefulWidget {
  const ConsultationsScreen({super.key});

  @override
  State<ConsultationsScreen> createState() => _ConsultationsScreenState();
}

class _ConsultationsScreenState extends State<ConsultationsScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final ConsultationService _service = ConsultationService();
  bool _isLoading = true;
  List<Map<String, dynamic>> _allConsultations = [];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _fetchConsultations();
  }

  Future<void> _fetchConsultations() async {
    setState(() => _isLoading = true);
    final results = await _service.getConsultations();
    setState(() {
      _allConsultations = results;
      _isLoading = false;
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Consultations'),
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(text: 'Upcoming'),
            Tab(text: 'Past'),
          ],
        ),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : TabBarView(
              controller: _tabController,
              children: [
                _buildConsultationList(isUpcoming: true),
                _buildConsultationList(isUpcoming: false),
              ],
            ),
    );
  }

  Widget _buildConsultationList({required bool isUpcoming}) {
    final now = DateTime.now();
    final consultations = _allConsultations.where((c) {
      final scheduledAt = DateTime.parse(c['scheduled_at']);
      return isUpcoming
          ? scheduledAt.isAfter(now) && c['status'] == 'scheduled'
          : scheduledAt.isBefore(now) || c['status'] != 'scheduled';
    }).toList();

    if (consultations.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.event_busy, size: 64, color: Colors.grey.shade400),
            const SizedBox(height: 16),
            Text(
              'No consultations found',
              style: TextStyle(color: Colors.grey.shade600, fontSize: 16),
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: consultations.length,
      itemBuilder: (context, index) {
        final item = consultations[index];
        return Card(
          margin: const EdgeInsets.only(bottom: 16),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    GestureDetector(
                      onTap: () {
                        if (item['patient'] != null) {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => PatientDetailScreen(
                                patient: {
                                  'id': item['patient_id'],
                                  'full_name': item['patient']['full_name'],
                                },
                              ),
                            ),
                          );
                        }
                      },
                      child: Row(
                        children: [
                          CircleAvatar(
                            backgroundColor: AppColors.primary.withOpacity(0.1),
                            child: Text(
                              (item['patient']?['full_name'] ?? 'P')[0],
                              style: const TextStyle(
                                color: AppColors.primary,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                item['patient']?['full_name'] ??
                                    'Unknown Patient',
                                style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 16,
                                ),
                              ),
                              Text(
                                DateFormat(
                                  'MMM d, h:mm a',
                                ).format(DateTime.parse(item['scheduled_at'])),
                                style: TextStyle(
                                  color: Colors.grey.shade600,
                                  fontSize: 13,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                    if (isUpcoming)
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: AppColors.primary.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Text(
                          item['status']?.toString().toUpperCase() ??
                              'SCHEDULED',
                          style: const TextStyle(
                            color: AppColors.primary,
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                  ],
                ),
                const Divider(height: 24),
                Row(
                  children: [
                    Icon(
                      Icons.description_outlined,
                      size: 16,
                      color: Colors.grey.shade600,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      'Symptoms: ${item['symptoms']}',
                      style: TextStyle(color: Colors.grey.shade800),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    if (isUpcoming) ...[
                      Expanded(
                        child: OutlinedButton(
                          onPressed: () {},
                          child: const Text('Cancel'),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: ElevatedButton.icon(
                          onPressed: () {
                            // TODO: Start Video Call
                          },
                          icon: const Icon(Icons.video_call),
                          label: const Text('Start'),
                        ),
                      ),
                    ] else ...[
                      Expanded(
                        child: OutlinedButton.icon(
                          onPressed: () {},
                          icon: const Icon(Icons.history),
                          label: const Text('View History'),
                        ),
                      ),
                    ],
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
