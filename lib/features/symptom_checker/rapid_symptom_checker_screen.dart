import 'package:flutter/material.dart';
import 'package:pulsecare/services/symptom_checker_service.dart';
import 'package:pulsecare/services/gemini_service.dart';
import 'package:pulsecare/services/local_analysis_service.dart';
import 'package:flutter_markdown/flutter_markdown.dart';
import 'dart:ui';
import 'dart:async';

class RapidSymptomCheckerScreen extends StatefulWidget {
  const RapidSymptomCheckerScreen({super.key});

  @override
  State<RapidSymptomCheckerScreen> createState() =>
      _RapidSymptomCheckerScreenState();
}

class _RapidSymptomCheckerScreenState extends State<RapidSymptomCheckerScreen> {
  final SymptomCheckerService _nihService = SymptomCheckerService();
  final GeminiService _geminiService = GeminiService();
  final LocalAnalysisService _localAnalysisService = LocalAnalysisService();

  final TextEditingController _searchController = TextEditingController();
  final PageController _pageController = PageController();
  Timer? _debounce;

  int _currentStep = 0;
  List<Map<String, dynamic>> _searchResults = []; // Now holds rich objects
  final List<Map<String, dynamic>> _selectedSymptoms =
      []; // Holds {name, risk_level}

  bool _isSearching = false;
  bool _isAnalyzing = false;

  // Patient Info
  String _gender = 'Male';
  double _age = 25;
  double _temp = 37.0;
  String _selectedLanguage = 'English';
  late final TextEditingController _tempController;
  bool _isCelsius = true;

  @override
  void initState() {
    super.initState();
    _tempController =
        TextEditingController(text: _temp.toStringAsFixed(1));
  }

  @override
  void dispose() {
    _searchController.dispose();
    _pageController.dispose();
    _tempController.dispose();
    _debounce?.cancel();
    super.dispose();
  }

  void _onSearchChanged(String query) {
    if (_debounce?.isActive ?? false) _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 500), () {
      if (query.length >= 2) {
        _performSearch(query);
      } else {
        setState(() => _searchResults = []);
      }
    });
  }

  Future<void> _performSearch(String query) async {
    setState(() => _isSearching = true);
    try {
      // 1. Search Local JSON first (includes risk_level)
      final localResults = await _nihService.searchLocalSymptoms(query);

      // 2. Search NIH API
      final nihResults = await _nihService.searchConditions(query);

      // 3. Merge: localResults already have risk_level; NIH ones default to 'Unknown'
      final localNames = localResults.map((s) => s['name'].toString()).toSet();
      final nihMapped = nihResults
          .where((n) => !localNames.contains(n))
          .map((n) => {'name': n, 'risk_level': 'Unknown', 'description': ''})
          .toList();

      setState(() {
        _searchResults = [...localResults, ...nihMapped];
        _isSearching = false;
      });
    } catch (e) {
      setState(() => _isSearching = false);
    }
  }

  void _toggleSymptom(Map<String, dynamic> symptom) {
    final name = symptom['name'].toString();
    setState(() {
      final already = _selectedSymptoms.any((s) => s['name'] == name);
      if (already) {
        _selectedSymptoms.removeWhere((s) => s['name'] == name);
      } else {
        if (_selectedSymptoms.length < 10) {
          _selectedSymptoms.add(symptom);
          _searchController.clear();
          _searchResults = [];
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Maximum 10 symptoms at a time')),
          );
        }
      }
    });
  }

  /// Compute the highest risk level among selected local symptoms
  String _computeOverallRisk() {
    final riskOrder = {'High': 3, 'Medium': 2, 'Low': 1, 'Unknown': 0};
    int maxRisk = 0;
    String maxLabel = 'Unknown';
    for (final s in _selectedSymptoms) {
      final level = s['risk_level']?.toString() ?? 'Unknown';
      final score = riskOrder[level] ?? 0;
      if (score > maxRisk) {
        maxRisk = score;
        maxLabel = level;
      }
    }
    return maxLabel;
  }

  Future<void> _runAnalysis() async {
    if (_selectedSymptoms.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select at least one symptom')),
      );
      return;
    }

    setState(() => _isAnalyzing = true);

    final symptomNames = _selectedSymptoms
        .map((s) => s['name'].toString())
        .toList();
    final overallRisk = _computeOverallRisk();

    try {
      String analysisContent = '';

      // --- Severity Section from Local JSON ---
      analysisContent += _buildSeveritySection(overallRisk);

      // --- Offline Local Clinical Engine (Symptoms.json) ---
      final localReport = await _localAnalysisService.generateReport(
        symptoms: symptomNames,
        gender: _gender,
        age: _age.toInt(),
        temperature: _temp,
      );
      analysisContent += '\n\n' + localReport + '\n\n---\n\n';

      // --- Groq AI Analysis (via GeminiService) ---
      final groqAnalysis = await _geminiService.analyzeSymptoms(
        symptoms: symptomNames,
        gender: _gender,
        age: _age.toInt(),
        temperature: _temp,
        language: _selectedLanguage,
      );

      analysisContent +=
          '\n\n---\n\n### 🤖 AI Analysis (Groq)\n\n' + groqAnalysis;

      if (mounted) {
        _showAnalysisSheet(analysisContent, overallRisk);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Analysis Error: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isAnalyzing = false);
    }
  }

  String _buildSeveritySection(String risk) {
    String emoji, description;
    switch (risk) {
      case 'High':
        emoji = '🔴';
        description =
            'Your selected symptoms indicate **HIGH risk**. Please seek medical attention **immediately** or visit the nearest emergency room.';
        break;
      case 'Medium':
        emoji = '🟡';
        description =
            'Your selected symptoms suggest a **MEDIUM risk** level. Consider consulting a doctor **within 24 hours**.';
        break;
      case 'Low':
        emoji = '🟢';
        description =
            'Your symptoms appear to be **LOW risk**. Monitor your condition. If symptoms worsen, consult a healthcare provider.';
        break;
      default:
        emoji = '⚪';
        description =
            'Risk level could not be determined from local database. AI analysis below is your best reference.';
    }
    return '## $emoji Severity Assessment: **$risk**\n\n$description\n\n---';
  }

  void _showAnalysisSheet(String content, String overallRisk) {
    final Color riskColor = _riskColor(overallRisk);

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
        child: Container(
          height: MediaQuery.of(context).size.height * 0.92,
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(32)),
          ),
          child: Column(
            children: [
              const SizedBox(height: 12),
              Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.grey[300],
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              // Header with severity badge
              Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 24,
                  vertical: 16,
                ),
                child: Row(
                  children: [
                    const Icon(
                      Icons.analytics_outlined,
                      color: Colors.indigo,
                      size: 28,
                    ),
                    const SizedBox(width: 12),
                    const Expanded(
                      child: Text(
                        'AI Clinical Report',
                        style: TextStyle(
                          fontSize: 22,
                          fontWeight: FontWeight.bold,
                          color: Colors.indigo,
                        ),
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 6,
                      ),
                      decoration: BoxDecoration(
                        color: riskColor.withOpacity(0.15),
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(color: riskColor, width: 1.5),
                      ),
                      child: Text(
                        '$overallRisk Risk',
                        style: TextStyle(
                          color: riskColor,
                          fontWeight: FontWeight.bold,
                          fontSize: 13,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const Divider(height: 1),
              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(24),
                  child: MarkdownBody(
                    data: content,
                    selectable: true,
                    styleSheet: MarkdownStyleSheet(
                      h2: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Colors.indigo,
                        height: 2,
                      ),
                      h3: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: Colors.blueGrey,
                        height: 1.8,
                      ),
                      p: const TextStyle(fontSize: 15, height: 1.6),
                      listBullet: const TextStyle(color: Colors.indigo),
                      strong: const TextStyle(fontWeight: FontWeight.bold),
                      blockquotePadding: const EdgeInsets.all(12),
                    ),
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.all(24),
                child: SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    onPressed: () => Navigator.pop(context),
                    icon: const Icon(Icons.close, color: Colors.white),
                    label: const Text('Close Report'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.indigo,
                      padding: const EdgeInsets.symmetric(vertical: 18),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
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

  Color _riskColor(String risk) {
    switch (risk) {
      case 'High':
        return Colors.red;
      case 'Medium':
        return Colors.orange;
      case 'Low':
        return Colors.green;
      default:
        return Colors.grey;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        title: const Text(
          'Clinical Nexus',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        backgroundColor: Colors.transparent,
        elevation: 0,
        flexibleSpace: ClipRect(
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
            child: Container(color: Colors.indigo.withOpacity(0.7)),
          ),
        ),
        actions: [
          DropdownButtonHideUnderline(
            child: DropdownButton<String>(
              value: _selectedLanguage,
              icon: const Icon(Icons.language, color: Colors.white),
              dropdownColor: Colors.indigo,
              items: const [
                'English',
                'Hindi',
                'Spanish',
                'French',
                'German',
                'Tamil',
              ].map((lang) {
                return DropdownMenuItem<String>(
                  value: lang,
                  child: Text(
                    lang,
                    style: const TextStyle(color: Colors.white),
                  ),
                );
              }).toList(),
              onChanged: (value) {
                if (value == null) return;
                setState(() => _selectedLanguage = value);
                _geminiService.setPreferredLanguage(value);
              },
            ),
          ),
        ],
      ),
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [Colors.indigo.shade50, Colors.white, Colors.blue.shade50],
          ),
        ),
        child: SafeArea(
          child: Column(
            children: [
              _buildStepperHeader(),
              Expanded(
                child: PageView(
                  controller: _pageController,
                  physics: const NeverScrollableScrollPhysics(),
                  children: [
                    _buildPatientProfileStep(),
                    _buildSymptomSelectionStep(),
                  ],
                ),
              ),
              _buildNavigationFooter(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStepperHeader() {
    return Padding(
      padding: const EdgeInsets.all(24),
      child: Row(
        children: [
          _stepIcon(0, Icons.person, 'Profile'),
          _stepConnector(0),
          _stepIcon(1, Icons.playlist_add_check, 'Symptoms'),
        ],
      ),
    );
  }

  Widget _stepIcon(int step, IconData icon, String label) {
    bool isActive = _currentStep >= step;
    return Column(
      children: [
        AnimatedContainer(
          duration: const Duration(milliseconds: 300),
          width: 50,
          height: 50,
          decoration: BoxDecoration(
            color: isActive ? Colors.indigo : Colors.white,
            shape: BoxShape.circle,
            boxShadow: [
              BoxShadow(
                color: Colors.indigo.withOpacity(0.1),
                blurRadius: 10,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Icon(
            icon,
            color: isActive ? Colors.white : Colors.indigo,
            size: 24,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          label,
          style: TextStyle(
            fontSize: 12,
            fontWeight: isActive ? FontWeight.bold : FontWeight.normal,
            color: isActive ? Colors.indigo : Colors.grey,
          ),
        ),
      ],
    );
  }

  Widget _stepConnector(int afterStep) {
    bool isPassed = _currentStep > afterStep;
    return Expanded(
      child: Container(
        height: 2,
        margin: const EdgeInsets.only(left: 16, right: 16, bottom: 20),
        color: isPassed ? Colors.indigo : Colors.grey[300],
      ),
    );
  }

  Widget _buildPatientProfileStep() {
    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Medical Background',
            style: TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.bold,
              color: Colors.indigo,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Personal details help the AI calibrate its diagnosis.',
            style: TextStyle(color: Colors.grey[600]),
          ),
          const SizedBox(height: 32),
          _inputCard(
            'Biological Gender',
            Row(
              children: [
                _genderOption('Male'),
                const SizedBox(width: 16),
                _genderOption('Female'),
              ],
            ),
          ),
          _inputCard(
            'Current Age (Years)',
            Column(
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      '${_age.toInt()} yrs',
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    ),
                    const Text('0-120'),
                  ],
                ),
                Slider(
                  value: _age,
                  min: 0,
                  max: 120,
                  activeColor: Colors.indigo,
                  onChanged: (v) => setState(() => _age = v),
                ),
              ],
            ),
          ),
          _inputCard(
            'Body Temperature',
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: _tempController,
                        keyboardType:
                            const TextInputType.numberWithOptions(decimal: true),
                        decoration: InputDecoration(
                          labelText:
                              _isCelsius ? 'Temperature (°C)' : 'Temperature (°F)',
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        onChanged: _onTemperatureChanged,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Container(
                      padding: const EdgeInsets.all(4),
                      decoration: BoxDecoration(
                        color: Colors.grey[100],
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          _tempUnitChip(true, '°C'),
                          _tempUnitChip(false, '°F'),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Text(
                  _isCelsius
                      ? 'Typical range: 35–42 °C'
                      : 'Typical range: 95–107 °F',
                  style: const TextStyle(
                    fontSize: 12,
                    color: Colors.grey,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _genderOption(String g) {
    bool isSel = _gender == g;
    return Expanded(
      child: GestureDetector(
        onTap: () => setState(() => _gender = g),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 16),
          decoration: BoxDecoration(
            color: isSel ? Colors.indigo : Colors.white,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: isSel ? Colors.indigo : Colors.grey[300]!,
            ),
          ),
          child: Center(
            child: Text(
              g,
              style: TextStyle(
                color: isSel ? Colors.white : Colors.indigo,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _inputCard(String label, Widget child) {
    return Container(
      margin: const EdgeInsets.only(bottom: 24),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.02),
            blurRadius: 15,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: const TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: Colors.grey,
            ),
          ),
          const SizedBox(height: 16),
          child,
        ],
      ),
    );
  }

  void _onTemperatureChanged(String value) {
    final parsed = double.tryParse(value);
    if (parsed == null) {
      return;
    }

    setState(() {
      if (_isCelsius) {
        _temp = parsed;
      } else {
        _temp = (parsed - 32) * 5 / 9;
      }
    });
  }

  Widget _tempUnitChip(bool forCelsius, String label) {
    final isSelected = _isCelsius == forCelsius;
    return InkWell(
      onTap: () {
        if (isSelected) return;
        setState(() {
          _isCelsius = forCelsius;
          final displayTemp = _isCelsius
              ? _temp
              : (_temp * 9 / 5) + 32;
          _tempController.text = displayTemp.toStringAsFixed(1);
        });
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected ? Colors.indigo : Colors.transparent,
          borderRadius: BorderRadius.circular(10),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: isSelected ? Colors.white : Colors.indigo,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
    );
  }

  Widget _buildSymptomSelectionStep() {
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: TextField(
            controller: _searchController,
            onChanged: _onSearchChanged,
            decoration: InputDecoration(
              hintText: 'Search symptoms (e.g. Fever, Headache)...',
              prefixIcon: const Icon(Icons.search, color: Colors.indigo),
              suffixIcon: _isSearching
                  ? const Padding(
                      padding: EdgeInsets.all(12),
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : null,
              filled: true,
              fillColor: Colors.white,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(20),
                borderSide: BorderSide.none,
              ),
              contentPadding: const EdgeInsets.symmetric(vertical: 20),
            ),
          ),
        ),
        // Selected symptoms with risk chips
        if (_selectedSymptoms.isNotEmpty)
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    const Icon(
                      Icons.check_circle,
                      color: Colors.indigo,
                      size: 16,
                    ),
                    const SizedBox(width: 6),
                    Text(
                      'Selected (${_selectedSymptoms.length}/10)',
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        color: Colors.indigo,
                        fontSize: 13,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: _selectedSymptoms.map((s) {
                    final risk = s['risk_level']?.toString() ?? 'Unknown';
                    final color = _riskColor(risk);
                    return Chip(
                      label: Text(
                        s['name'].toString(),
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 12,
                        ),
                      ),
                      backgroundColor: Colors.indigo,
                      deleteIcon: const Icon(
                        Icons.close,
                        size: 16,
                        color: Colors.white,
                      ),
                      onDeleted: () => _toggleSymptom(s),
                      side: BorderSide(color: color, width: 2),
                    );
                  }).toList(),
                ),
                const SizedBox(height: 8),
                // Overall risk computed from selection
                if (_selectedSymptoms.isNotEmpty)
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 8,
                    ),
                    decoration: BoxDecoration(
                      color: _riskColor(_computeOverallRisk()).withOpacity(0.1),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: _riskColor(
                          _computeOverallRisk(),
                        ).withOpacity(0.4),
                      ),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          Icons.warning_amber_rounded,
                          color: _riskColor(_computeOverallRisk()),
                          size: 16,
                        ),
                        const SizedBox(width: 6),
                        Text(
                          'Estimated Severity: ${_computeOverallRisk()}',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            color: _riskColor(_computeOverallRisk()),
                            fontSize: 13,
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
          child: _searchResults.isEmpty
              ? _buildEmptyState()
              : ListView.separated(
                  padding: const EdgeInsets.all(16),
                  itemCount: _searchResults.length,
                  separatorBuilder: (_, __) => const Divider(height: 1),
                  itemBuilder: (context, index) {
                    final symptom = _searchResults[index];
                    final name = symptom['name'].toString();
                    final risk = symptom['risk_level']?.toString() ?? 'Unknown';
                    final desc = symptom['description']?.toString() ?? '';
                    final isSelected = _selectedSymptoms.any(
                      (s) => s['name'] == name,
                    );
                    final riskColor = _riskColor(risk);

                    return ListTile(
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 4,
                      ),
                      title: Text(
                        name,
                        style: const TextStyle(fontWeight: FontWeight.w600),
                      ),
                      subtitle: desc.isNotEmpty
                          ? Text(
                              desc,
                              style: TextStyle(
                                fontSize: 12,
                                color: Colors.grey[600],
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            )
                          : null,
                      leading: risk != 'Unknown'
                          ? Container(
                              width: 10,
                              height: 10,
                              margin: const EdgeInsets.only(top: 4),
                              decoration: BoxDecoration(
                                color: riskColor,
                                shape: BoxShape.circle,
                              ),
                            )
                          : null,
                      trailing: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          if (risk != 'Unknown')
                            Container(
                              margin: const EdgeInsets.only(right: 8),
                              padding: const EdgeInsets.symmetric(
                                horizontal: 8,
                                vertical: 4,
                              ),
                              decoration: BoxDecoration(
                                color: riskColor.withOpacity(0.1),
                                borderRadius: BorderRadius.circular(8),
                                border: Border.all(color: riskColor, width: 1),
                              ),
                              child: Text(
                                risk,
                                style: TextStyle(
                                  color: riskColor,
                                  fontSize: 11,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                          Icon(
                            isSelected
                                ? Icons.check_circle
                                : Icons.add_circle_outline,
                            color: isSelected ? Colors.green : Colors.indigo,
                          ),
                        ],
                      ),
                      onTap: () => _toggleSymptom(symptom),
                    );
                  },
                ),
        ),
      ],
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.medical_information_outlined,
            size: 64,
            color: Colors.grey[300],
          ),
          const SizedBox(height: 16),
          Text(
            _searchController.text.isEmpty
                ? 'Search for symptoms to get started'
                : 'No symptoms found for this search',
            style: TextStyle(color: Colors.grey[400]),
          ),
          const SizedBox(height: 8),
          Text(
            'e.g. Fever, Headache, Chest Pain',
            style: TextStyle(color: Colors.grey[300], fontSize: 12),
          ),
        ],
      ),
    );
  }

  Widget _buildNavigationFooter() {
    bool isStepOne = _currentStep == 0;
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border(top: BorderSide(color: Colors.grey[200]!)),
      ),
      child: Row(
        children: [
          if (!isStepOne)
            Expanded(
              child: OutlinedButton(
                onPressed: () {
                  setState(() => _currentStep = 0);
                  _pageController.previousPage(
                    duration: const Duration(milliseconds: 300),
                    curve: Curves.easeInOut,
                  );
                },
                style: OutlinedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 20),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                ),
                child: const Text('Back'),
              ),
            ),
          if (!isStepOne) const SizedBox(width: 16),
          Expanded(
            flex: 2,
            child: ElevatedButton(
              onPressed: _isAnalyzing
                  ? null
                  : (isStepOne ? _nextStep : _runAnalysis),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.indigo,
                padding: const EdgeInsets.symmetric(vertical: 20),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
              ),
              child: _isAnalyzing
                  ? const SizedBox(
                      height: 20,
                      width: 20,
                      child: CircularProgressIndicator(
                        color: Colors.white,
                        strokeWidth: 2,
                      ),
                    )
                  : Text(
                      isStepOne ? 'Next: Add Symptoms' : 'Run Full AI Analysis',
                    ),
            ),
          ),
        ],
      ),
    );
  }

  void _nextStep() {
    setState(() => _currentStep = 1);
    _pageController.nextPage(
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeInOut,
    );
  }
}
