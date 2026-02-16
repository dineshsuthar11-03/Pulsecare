class MedicineModel {
  final String id;
  final String brandName;
  final String genericName;
  final List<String> activeIngredients;
  final String? dosageForm;
  final String? route;
  final String? purpose;
  final List<String> warnings;
  final List<String> adverseReactions;
  final String? dosageAndAdministration;
  final String? maximumDailyDose;
  final String? manufacturer;
  final DateTime? cacheDate;

  MedicineModel({
    required this.id,
    required this.brandName,
    required this.genericName,
    this.activeIngredients = const [],
    this.dosageForm,
    this.route,
    this.purpose,
    this.warnings = const [],
    this.adverseReactions = const [],
    this.dosageAndAdministration,
    this.maximumDailyDose,
    this.manufacturer,
    this.cacheDate,
  });

  Map<String, dynamic> toJson() => {
    'id': id,
    'brandName': brandName,
    'genericName': genericName,
    'activeIngredients': activeIngredients,
    'dosageForm': dosageForm,
    'route': route,
    'purpose': purpose,
    'warnings': warnings,
    'adverseReactions': adverseReactions,
    'dosageAndAdministration': dosageAndAdministration,
    'maximumDailyDose': maximumDailyDose,
    'manufacturer': manufacturer,
    'cacheDate': cacheDate?.toIso8601String(),
  };

  factory MedicineModel.fromJson(Map<String, dynamic> json) => MedicineModel(
    id: json['id'] as String,
    brandName: json['brandName'] as String,
    genericName: json['genericName'] as String,
    activeIngredients:
        (json['activeIngredients'] as List<dynamic>?)
            ?.map((e) => e as String)
            .toList() ??
        [],
    dosageForm: json['dosageForm'] as String?,
    route: json['route'] as String?,
    purpose: json['purpose'] as String?,
    warnings:
        (json['warnings'] as List<dynamic>?)
            ?.map((e) => e as String)
            .toList() ??
        [],
    adverseReactions:
        (json['adverseReactions'] as List<dynamic>?)
            ?.map((e) => e as String)
            .toList() ??
        [],
    dosageAndAdministration: json['dosageAndAdministration'] as String?,
    maximumDailyDose: json['maximumDailyDose'] as String?,
    manufacturer: json['manufacturer'] as String?,
    cacheDate: json['cacheDate'] != null
        ? DateTime.parse(json['cacheDate'] as String)
        : null,
  );

  factory MedicineModel.fromOpenFDA(Map<String, dynamic> fdaData) {
    // Extract data from OpenFDA response structure
    final openfda = fdaData['openfda'] as Map<String, dynamic>?;
    final brandName =
        (openfda?['brand_name'] as List<dynamic>?)?.first as String? ??
        'Unknown';
    final genericName =
        (openfda?['generic_name'] as List<dynamic>?)?.first as String? ??
        brandName;
    final activeIngredients =
        (openfda?['substance_name'] as List<dynamic>?)
            ?.map((e) => e as String)
            .toList() ??
        [];

    return MedicineModel(
      id:
          fdaData['id'] as String? ??
          DateTime.now().millisecondsSinceEpoch.toString(),
      brandName: brandName,
      genericName: genericName,
      activeIngredients: activeIngredients,
      dosageForm: (openfda?['dosage_form'] as List<dynamic>?)?.first as String?,
      route: (openfda?['route'] as List<dynamic>?)?.first as String?,
      purpose: (fdaData['purpose'] as List<dynamic>?)?.first as String?,
      warnings:
          (fdaData['warnings'] as List<dynamic>?)
              ?.map((e) => e as String)
              .toList() ??
          [],
      adverseReactions:
          (fdaData['adverse_reactions'] as List<dynamic>?)
              ?.map((e) => e as String)
              .toList() ??
          [],
      dosageAndAdministration:
          (fdaData['dosage_and_administration'] as List<dynamic>?)?.first
              as String?,
      maximumDailyDose: null, // Will need to parse from dosage text
      manufacturer:
          (openfda?['manufacturer_name'] as List<dynamic>?)?.first as String?,
      cacheDate: DateTime.now(),
    );
  }

  String get displayName => brandName != 'Unknown' ? brandName : genericName;
}
