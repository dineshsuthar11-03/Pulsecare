import 'package:flutter/material.dart';
import 'package:pulsecare/core/constants/app_colors.dart';
import 'package:pulsecare/core/constants/app_strings.dart';
import 'package:pulsecare/core/services/medicine_backend_service.dart';
import 'package:pulsecare/data/models/medicine_model.dart';
import 'package:pulsecare/services/gemini_service.dart';

class MedicineDetailScreen extends StatefulWidget {
  final MedicineModel medicine;

  const MedicineDetailScreen({super.key, required this.medicine});

  @override
  State<MedicineDetailScreen> createState() => _MedicineDetailScreenState();
}

class _MedicineDetailScreenState extends State<MedicineDetailScreen> {
  final MedicineBackendService _medicineService = MedicineBackendService();
  final GeminiService _geminiService = GeminiService();
  List<MedicineModel> _alternatives = [];
  bool _loadingAlternatives = false;
  bool _loadingAi = false;
  String? _aiSummary;
  String? _aiError;

  @override
  void initState() {
    super.initState();
    _loadAlternatives();
  }

  Future<void> _loadAlternatives() async {
    if (widget.medicine.activeIngredients.isEmpty) return;

    setState(() {
      _loadingAlternatives = true;
    });

    try {
      final alternatives = await _medicineService.getAlternativeMedicines(
        widget.medicine.activeIngredients.first,
        excludeId: widget.medicine.id,
      );

      // Filter out the current medicine
      final filtered = alternatives
          .where((m) => m.id != widget.medicine.id)
          .take(5)
          .toList();

      setState(() {
        _alternatives = filtered;
        _loadingAlternatives = false;
      });
    } catch (e) {
      setState(() {
        _loadingAlternatives = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Medicine Details')),
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Header
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(gradient: AppColors.primaryGradient),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.2),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: const Icon(
                          Icons.medication,
                          color: Colors.white,
                          size: 32,
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              widget.medicine.displayName,
                              style: Theme.of(context).textTheme.headlineMedium
                                  ?.copyWith(
                                    color: Colors.white,
                                    fontWeight: FontWeight.bold,
                                  ),
                            ),
                            if (widget.medicine.genericName !=
                                widget.medicine.brandName)
                              Padding(
                                padding: const EdgeInsets.only(top: 4),
                                child: Text(
                                  'Generic: ${widget.medicine.genericName}',
                                  style: Theme.of(context).textTheme.bodyMedium
                                      ?.copyWith(
                                        color: Colors.white.withOpacity(0.9),
                                      ),
                                ),
                              ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),

            const SizedBox(height: 16),

            // Groq AI Medicine Insights
            _buildAiInsightsSection(context),

            const SizedBox(height: 8),

            // Active Ingredients
            if (widget.medicine.activeIngredients.isNotEmpty)
              _buildSection(
                context,
                'Active Ingredients',
                Icons.science,
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: widget.medicine.activeIngredients
                      .map(
                        (ingredient) => Padding(
                          padding: const EdgeInsets.only(bottom: 4),
                          child: Text('• $ingredient'),
                        ),
                      )
                      .toList(),
                ),
              ),

            // Dosage Form & Route
            if (widget.medicine.dosageForm != null ||
                widget.medicine.route != null)
              _buildSection(
                context,
                'Dosage Information',
                Icons.local_pharmacy,
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (widget.medicine.dosageForm != null)
                      Text('Form: ${widget.medicine.dosageForm}'),
                    if (widget.medicine.route != null)
                      Text('Route: ${widget.medicine.route}'),
                  ],
                ),
              ),

            // Purpose
            if (widget.medicine.purpose != null)
              _buildSection(
                context,
                'Purpose',
                Icons.assignment,
                Text(widget.medicine.purpose!),
              ),

            // Dosage & Administration
            if (widget.medicine.dosageAndAdministration != null)
              _buildSection(
                context,
                AppStrings.dosageSafetyTitle,
                Icons.health_and_safety,
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: AppColors.warning.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: AppColors.warning, width: 2),
                      ),
                      child: Row(
                        children: [
                          Icon(Icons.warning_amber, color: AppColors.warning),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Text(
                              AppStrings.overdoseWarning,
                              style: Theme.of(context).textTheme.bodySmall
                                  ?.copyWith(
                                    color: AppColors.textPrimary,
                                    fontWeight: FontWeight.w600,
                                  ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 12),
                    Text(
                      widget.medicine.dosageAndAdministration!,
                      style: Theme.of(context).textTheme.bodyMedium,
                    ),
                  ],
                ),
              ),

            // Warnings
            if (widget.medicine.warnings.isNotEmpty)
              _buildSection(
                context,
                'Warnings & Precautions',
                Icons.error_outline,
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: widget.medicine.warnings
                      .take(3)
                      .map(
                        (warning) => Padding(
                          padding: const EdgeInsets.only(bottom: 8),
                          child: Container(
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: AppColors.error.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Icon(
                                  Icons.warning,
                                  color: AppColors.error,
                                  size: 20,
                                ),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: Text(
                                    warning,
                                    style: Theme.of(
                                      context,
                                    ).textTheme.bodySmall,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      )
                      .toList(),
                ),
              ),

            // Adverse Reactions
            if (widget.medicine.adverseReactions.isNotEmpty)
              _buildSection(
                context,
                'Possible Side Effects',
                Icons.healing,
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: widget.medicine.adverseReactions
                      .take(3)
                      .map(
                        (reaction) => Padding(
                          padding: const EdgeInsets.only(bottom: 4),
                          child: Text('• $reaction'),
                        ),
                      )
                      .toList(),
                ),
              ),

            // Manufacturer
            if (widget.medicine.manufacturer != null)
              _buildSection(
                context,
                'Manufacturer',
                Icons.business,
                Text(widget.medicine.manufacturer!),
              ),

            // Alternative Medicines
            _buildAlternativesSection(),

            const SizedBox(height: 16),

            // Disclaimer
            Container(
              margin: const EdgeInsets.all(16),
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppColors.warning.withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: AppColors.warning.withOpacity(0.3)),
              ),
              child: Row(
                children: [
                  Icon(Icons.info_outline, color: AppColors.warning),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      AppStrings.medicalDisclaimer,
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSection(
    BuildContext context,
    String title,
    IconData icon,
    Widget content,
  ) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: AppColors.shadow,
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, color: AppColors.primary, size: 20),
              const SizedBox(width: 8),
              Text(
                title,
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: AppColors.primary,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          content,
        ],
      ),
    );
  }

  Widget _buildAiInsightsSection(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: AppColors.accentGradient,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: AppColors.shadow,
            blurRadius: 8,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(
                  Icons.smart_toy_outlined,
                  color: Colors.white,
                  size: 22,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Groq AI Medicine Insights',
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                          ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Get a simple explanation of how this medicine is used and safety points to remember.',
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: Colors.white.withOpacity(0.9),
                          ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          if (_aiError != null)
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.12),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                _aiError!,
                style: Theme.of(context)
                    .textTheme
                    .bodySmall
                    ?.copyWith(color: Colors.white),
              ),
            ),
          if (_aiSummary != null)
            Container(
              margin: const EdgeInsets.only(top: 12),
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                _aiSummary!,
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: AppColors.textPrimary,
                    ),
              ),
            ),
          const SizedBox(height: 12),
          Align(
            alignment: Alignment.centerRight,
            child: ElevatedButton.icon(
              onPressed: _loadingAi ? null : _onAskAiPressed,
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.white,
                foregroundColor: AppColors.accentDark,
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(999),
                ),
              ),
              icon: _loadingAi
                  ? const SizedBox(
                      height: 18,
                      width: 18,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Icon(Icons.bolt_outlined, size: 18),
              label: Text(
                _loadingAi ? 'Analyzing…' : 'Ask Groq AI',
                style: const TextStyle(fontWeight: FontWeight.w600),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _onAskAiPressed() async {
    setState(() {
      _loadingAi = true;
      _aiError = null;
    });

    try {
      final summary = await _geminiService.analyzeMedicine(
        name: widget.medicine.displayName,
        activeIngredients: widget.medicine.activeIngredients,
        purpose: widget.medicine.purpose,
        warnings: widget.medicine.warnings.isNotEmpty
            ? widget.medicine.warnings.take(3).join('\n')
            : null,
        dosageAndAdministration: widget.medicine.dosageAndAdministration,
      );

      if (mounted) {
        setState(() {
          _aiSummary = summary;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _aiError = 'Unable to load AI insights: $e';
        });
      }
    } finally {
      if (mounted) {
        setState(() {
          _loadingAi = false;
        });
      }
    }
  }

  Widget _buildAlternativesSection() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.compare_arrows, color: AppColors.accent, size: 20),
              const SizedBox(width: 8),
              Text(
                AppStrings.alternativesTitle,
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: AppColors.accent,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          if (_loadingAlternatives)
            const Center(child: CircularProgressIndicator())
          else if (_alternatives.isEmpty)
            Text(
              AppStrings.noAlternatives,
              style: Theme.of(
                context,
              ).textTheme.bodyMedium?.copyWith(color: AppColors.textSecondary),
            )
          else
            SizedBox(
              height: 120,
              child: ListView.builder(
                scrollDirection: Axis.horizontal,
                itemCount: _alternatives.length,
                itemBuilder: (context, index) {
                  final alt = _alternatives[index];
                  return Card(
                    margin: const EdgeInsets.only(right: 12),
                    child: InkWell(
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) =>
                                MedicineDetailScreen(medicine: alt),
                          ),
                        );
                      },
                      child: Container(
                        width: 200,
                        padding: const EdgeInsets.all(12),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text(
                              alt.displayName,
                              style: Theme.of(context).textTheme.titleSmall
                                  ?.copyWith(fontWeight: FontWeight.w600),
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                            ),
                            if (alt.dosageForm != null)
                              Padding(
                                padding: const EdgeInsets.only(top: 4),
                                child: Text(
                                  alt.dosageForm!,
                                  style: Theme.of(context).textTheme.bodySmall,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                            const SizedBox(height: 4),
                            Text(
                              'Same active ingredient',
                              style: Theme.of(context).textTheme.bodySmall
                                  ?.copyWith(
                                    color: AppColors.accent,
                                    fontWeight: FontWeight.w500,
                                  ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),
        ],
      ),
    );
  }
}
