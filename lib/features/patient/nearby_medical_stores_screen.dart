import 'package:pulsecare/core/constants/app_colors.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:webview_flutter/webview_flutter.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:flutter/services.dart' show rootBundle;

class NearbyMedicalStoresScreen extends StatefulWidget {
  const NearbyMedicalStoresScreen({super.key});

  @override
  State<NearbyMedicalStoresScreen> createState() =>
      _NearbyMedicalStoresScreenState();
}

class _NearbyMedicalStoresScreenState
    extends State<NearbyMedicalStoresScreen> {
  bool _locationPermissionGranted = false;
  bool _isRequestingPermission = false;
  bool _isLoadingStores = false;
  String? _errorMessage;

  // Placeholder list until the real API is integrated.
  List<Map<String, dynamic>> _stores = [];
  WebViewController? _webViewController;

  @override
  void initState() {
    super.initState();
    _checkExistingPermission();
  }

  Future<void> _checkExistingPermission() async {
    // On web, permission_handler does not support locationWhenInUse.
    if (kIsWeb) {
      if (!mounted) return;
      setState(() {
        _locationPermissionGranted = true;
      });
      await _loadStores();
      return;
    }

    final status = await Permission.locationWhenInUse.status;
    if (!mounted) return;
    setState(() {
      _locationPermissionGranted = status.isGranted;
    });
    if (status.isGranted) {
      await _loadStores();
    }
  }

  Future<void> _requestLocationPermission() async {
    // On web, we cannot request this permission via permission_handler;
    // the browser handles it. Treat it as granted and load stores.
    if (kIsWeb) {
      if (!mounted) return;
      setState(() {
        _locationPermissionGranted = true;
        _errorMessage = null;
      });
      await _loadStores();
      return;
    }

    setState(() {
      _isRequestingPermission = true;
      _errorMessage = null;
    });

    final status = await Permission.locationWhenInUse.request();

    if (!mounted) return;

    setState(() {
      _isRequestingPermission = false;
      _locationPermissionGranted = status.isGranted;
    });

    if (status.isGranted) {
      await _loadStores();
    } else if (status.isPermanentlyDenied) {
      setState(() {
        _errorMessage =
            'Location access is permanently denied. Please enable it in system settings to see nearby medical stores.';
      });
    }
  }

  Future<void> _openOsmMapInBrowser() async {
    final uri = Uri.parse('assets/mappls_nearby.html');
    final ok = await launchUrl(
      uri,
      mode: LaunchMode.platformDefault,
      webOnlyWindowName: '_blank',
    );

    if (!ok && mounted) {
      setState(() {
        _errorMessage = 'Could not open map in browser.';
      });
    }
  }

  Future<void> _loadStores() async {
    setState(() {
      _isLoadingStores = true;
      _errorMessage = null;
    });

    try {
      // For the OpenStreetMap + Overpass integration, we don't fetch stores
      // from Flutter; the embedded HTML (loaded in the WebView) handles
      // searching and rendering pharmacies near the user.

      // Simulate a short delay so we can show a loader before the map.
      await Future.delayed(const Duration(milliseconds: 300));

      if (!mounted) return;
      setState(() {
        _stores = [];
        _isLoadingStores = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _isLoadingStores = false;
        _errorMessage = 'Failed to load nearby stores. Please try again.';
      });
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
                    const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                child: Row(
                  children: [
                    IconButton(
                      icon:
                          const Icon(Icons.arrow_back, color: Colors.white),
                      onPressed: () => Navigator.of(context).pop(),
                    ),
                    const SizedBox(width: 8),
                    const Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Nearby medical stores',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          SizedBox(height: 4),
                          Text(
                            'Enable your location to find medical stores around you.',
                            style: TextStyle(
                              color: Colors.white70,
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
                child: Container(
                  decoration: const BoxDecoration(
                    color: AppColors.background,
                    borderRadius: BorderRadius.vertical(
                      top: Radius.circular(32),
                    ),
                  ),
                  child: _buildBody(),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildBody() {
    if (!_locationPermissionGranted) {
      return SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(20, 24, 20, 32),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(24),
                color: Colors.white,
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.04),
                    blurRadius: 12,
                    offset: const Offset(0, 6),
                  ),
                ],
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: AppColors.primary.withOpacity(0.1),
                      shape: BoxShape.circle,
                    ),
                    child:
                        const Icon(Icons.location_on, color: AppColors.primary),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Turn on location',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: AppColors.textPrimary,
                          ),
                        ),
                        const SizedBox(height: 6),
                        const Text(
                          'We use your current location only to find nearby pharmacies and medical stores. This helps us show distance and guide you better.',
                          style: TextStyle(
                            fontSize: 13,
                            height: 1.4,
                            color: AppColors.textSecondary,
                          ),
                        ),
                        const SizedBox(height: 16),
                        SizedBox(
                          width: double.infinity,
                          child: ElevatedButton.icon(
                            onPressed: _isRequestingPermission
                                ? null
                                : _requestLocationPermission,
                            icon: _isRequestingPermission
                                ? const SizedBox(
                                    width: 16,
                                    height: 16,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                      valueColor:
                                          AlwaysStoppedAnimation(Colors.white),
                                    ),
                                  )
                                : const Icon(Icons.location_searching),
                            label: Text(
                              _isRequestingPermission
                                  ? 'Requesting permission...'
                                  : 'Enable location',
                            ),
                            style: ElevatedButton.styleFrom(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 16,
                                vertical: 12,
                              ),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(height: 8),
                        const Text(
                          'You can change this later from your phone settings. We do not store your exact location on the device.',
                          style: TextStyle(
                            fontSize: 11,
                            color: AppColors.textTertiary,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            if (_errorMessage != null) ...[
              const SizedBox(height: 16),
              _buildErrorBanner(_errorMessage!),
            ],
          ],
        ),
      );
    }

    if (_isLoadingStores) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_errorMessage != null) {
      return Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _buildErrorBanner(_errorMessage!),
            const SizedBox(height: 12),
            OutlinedButton.icon(
              onPressed: _loadStores,
              icon: const Icon(Icons.refresh),
              label: const Text('Try again'),
            ),
          ],
        ),
      );
    }

    // When location is enabled and there are no errors, show the map view
    // using an embedded HTML page (OpenStreetMap tiles + Overpass API).

    if (kIsWeb) {
      return Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            const Icon(
              Icons.map_outlined,
              size: 48,
              color: AppColors.textSecondary,
            ),
            const SizedBox(height: 16),
            const Text(
              'Open the map to see nearby medical stores in your browser.',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 14,
                color: AppColors.textSecondary,
              ),
            ),
            const SizedBox(height: 16),
            ElevatedButton.icon(
              onPressed: _openOsmMapInBrowser,
              icon: const Icon(Icons.open_in_new),
              label: const Text('Open map'),
            ),
          ],
        ),
      );
    }

    return FutureBuilder<String>(
      future: rootBundle.loadString('assets/mappls_nearby.html'),
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return const Center(child: CircularProgressIndicator());
        }

        final htmlContent = snapshot.data!;

        _webViewController ??= WebViewController()
          ..setJavaScriptMode(JavaScriptMode.unrestricted)
          ..loadHtmlString(htmlContent);

        return WebViewWidget(controller: _webViewController!);
      },
    );
  }

  Widget _buildErrorBanner(String message) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFFFEE2E2),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFEF4444).withOpacity(0.6)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(Icons.error_outline,
              color: Color(0xFFB91C1C), size: 20),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              message,
              style: const TextStyle(
                fontSize: 13,
                color: Color(0xFF7F1D1D),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStoreCard(Map<String, dynamic> store) {
    final bool isOpen = store['isOpen'] == true;
    return Card(
      margin: const EdgeInsets.only(bottom: 14),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppColors.primary.withOpacity(0.08),
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Icon(Icons.local_pharmacy,
                  size: 32, color: AppColors.primary),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    store['name'] ?? 'Medical Store',
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    store['address'] ?? '',
                    style: const TextStyle(
                      fontSize: 13,
                      color: AppColors.textSecondary,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Row(
                        children: [
                          const Icon(Icons.place,
                              size: 16, color: AppColors.textTertiary),
                          const SizedBox(width: 4),
                          Text(
                            store['distance'] ?? '-',
                            style: const TextStyle(
                              fontSize: 13,
                              color: AppColors.textTertiary,
                            ),
                          ),
                        ],
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: isOpen
                              ? const Color(0xFFD1FAE5)
                              : const Color(0xFFFEE2E2),
                          borderRadius: BorderRadius.circular(999),
                        ),
                        child: Text(
                          isOpen ? 'Open now' : 'Closed',
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                            color: isOpen
                                ? const Color(0xFF065F46)
                                : const Color(0xFF991B1B),
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Align(
                    alignment: Alignment.centerRight,
                    child: TextButton.icon(
                      onPressed: () {
                        // TODO: Optionally integrate with map navigation
                        // using url_launcher or a dedicated maps package.
                      },
                      icon: const Icon(Icons.directions, size: 18),
                      label: const Text('Get directions'),
                      style: TextButton.styleFrom(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 4,
                        ),
                        minimumSize: const Size(0, 32),
                      ),
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
}
