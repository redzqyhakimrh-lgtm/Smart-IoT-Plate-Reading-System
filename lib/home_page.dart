import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:google_fonts/google_fonts.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:webview_flutter/webview_flutter.dart';
import 'package:image_picker/image_picker.dart';
import '../services/database_service.dart';
import '../services/aprs_api_service.dart';
import 'setting_page.dart';

class HomePage extends StatefulWidget {
  final String studentId;

  const HomePage({super.key, required this.studentId});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  static const Color primaryBlue = Color(0xFF2563EB);
  static const Color bgLight     = Color(0xFFF1F5F9);
  static const Color cardBg      = Color(0xFFFFFFFF);
  static const Color textDark    = Color(0xFF0F172A);

  final DatabaseService _dbService = DatabaseService();
  final ImagePicker _imagePicker = ImagePicker();
  WebViewController? _mapController;

  bool _isScanning = false;

  @override
  void initState() {
    super.initState();

    if (!kIsWeb) {
      const String mapHtml = '''
        <!DOCTYPE html>
        <html>
        <head>
          <meta name="viewport" content="width=device-width, initial-scale=1.0, maximum-scale=1.0, user-scalable=no" />
          <link rel="stylesheet" type="text/css" href="https://api.tomtom.com/maps-sdk-for-web/cdn/6.x/6.25.0/maps/maps.css"/>
          <script src="https://api.tomtom.com/maps-sdk-for-web/cdn/6.x/6.25.0/maps/maps-web.min.js"></script>
          <style>
            body, html { margin: 0; padding: 0; height: 100%; width: 100%; }
            #map { width: 100%; height: 100%; }
          </style>
        </head>
        <body>
          <div id="map"></div>
          <script>
            var apiKey = 'QdndWLaV34C0c5Cqop1bSVASMaSsEE2f';
            var map = tt.map({
              key: apiKey,
              container: 'map',
              center: [101.71, 2.99],
              zoom: 14,
              stylesVisibility: { trafficFlow: true, trafficIncidents: true }
            });
            map.on('load', function() {
              map.addTier(new tt.TrafficFlowTilesTier({
                key: apiKey,
                style: 'tomtom://vector/1/relative'
              }));
            });
            map.addControl(new tt.NavigationControl());
          </script>
        </body>
        </html>
      ''';

      _mapController = WebViewController()
        ..setJavaScriptMode(JavaScriptMode.unrestricted)
        ..loadHtmlString(mapHtml);
    }
  }

  // ============================================================
  // SCAN LOGIC
  // ============================================================

  Future<void> _pickAndScan(ImageSource source) async {
    try {
      final XFile? picked = await _imagePicker.pickImage(
        source: source,
        imageQuality: 85,
        maxWidth: 1600,
      );

      if (picked == null) return;

      setState(() => _isScanning = true);

      final bytes = await picked.readAsBytes();

      final result = await AprsApiService.scanPlate(
        imageBytes: bytes,
        filename: picked.name,
      );

      if (!mounted) return;

      if (result == null || result['status'] == 'error') {
        _showResultDialog(
          title: 'Connection Error',
          message: result?['message'] ?? 'Could not reach the server.',
          isSuccess: false,
        );
        return;
      }

      if (result['status'] == 'no_plate') {
        _showResultDialog(
          title: 'No Plate Detected',
          message: 'The image did not contain a readable plate. Try again.',
          isSuccess: false,
        );
        return;
      }

      // Success!
      final plate = result['plate'] ?? '?';
      final registered = result['registered'] == true;
      final direction = (result['direction'] ?? 'entry').toString().toUpperCase();

      _showResultDialog(
        title: registered
    		? '${direction == 'EXIT' ? 'Exit' : 'Entry'} Recorded ✅'
    		: 'Unregistered Vehicle 🚨',
        message: registered
            ? 'Plate: $plate\nDirection: $direction\nConfidence: ${result['confidence']}'
            : 'Plate: $plate\nThis vehicle is not registered.\nSecurity has been alerted.',
        isSuccess: registered,
      );
    } catch (e) {
      if (!mounted) return;
      _showResultDialog(
        title: 'Scan Failed',
        message: '$e',
        isSuccess: false,
      );
    } finally {
      if (mounted) setState(() => _isScanning = false);
    }
  }

  void _showScanOptions() {
    showModalBottomSheet(
      context: context,
      backgroundColor: cardBg,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (context) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 12),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 40,
                height: 4,
                margin: const EdgeInsets.only(bottom: 12),
                decoration: BoxDecoration(
                  color: Colors.grey.shade300,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                child: Text(
                  'Scan a vehicle plate',
                  style: GoogleFonts.poppins(
                    fontSize: 16,
                    fontWeight: FontWeight.w800,
                    color: textDark,
                  ),
                ),
              ),
              ListTile(
                leading: const CircleAvatar(
                  backgroundColor: Color(0xFFDBEAFE),
                  child: Icon(Icons.camera_alt_rounded, color: primaryBlue),
                ),
                title: Text(
                  'Take a photo',
                  style: GoogleFonts.poppins(fontWeight: FontWeight.w600),
                ),
                onTap: () {
                  Navigator.pop(context);
                  _pickAndScan(ImageSource.camera);
                },
              ),
              ListTile(
                leading: const CircleAvatar(
                  backgroundColor: Color(0xFFDBEAFE),
                  child: Icon(Icons.photo_library_rounded, color: primaryBlue),
                ),
                title: Text(
                  'Choose from gallery',
                  style: GoogleFonts.poppins(fontWeight: FontWeight.w600),
                ),
                onTap: () {
                  Navigator.pop(context);
                  _pickAndScan(ImageSource.gallery);
                },
              ),
              const SizedBox(height: 8),
            ],
          ),
        ),
      ),
    );
  }

  void _showResultDialog({
    required String title,
    required String message,
    required bool isSuccess,
  }) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text(
          title,
          style: GoogleFonts.poppins(
            fontWeight: FontWeight.bold,
            color: isSuccess ? Colors.green.shade800 : Colors.red.shade800,
          ),
        ),
        content: Text(message, style: GoogleFonts.poppins(fontSize: 13)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(
              'OK',
              style: GoogleFonts.poppins(
                fontWeight: FontWeight.bold,
                color: primaryBlue,
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ============================================================
  // BUILD
  // ============================================================

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: bgLight,
      appBar: AppBar(
        title: Text(
          'Hostel Parking Hub',
          style: GoogleFonts.poppins(
            color: textDark,
            fontWeight: FontWeight.w800,
            fontSize: 22,
          ),
        ),
        backgroundColor: bgLight,
        elevation: 0,
        automaticallyImplyLeading: false,
        actions: [
          IconButton(
  		icon: const Icon(Icons.settings_outlined, color: primaryBlue),
  		onPressed: () {
   		 Navigator.push(
     		 context,
     		 MaterialPageRoute(builder: (context) => const SettingsPage()),
   		 );
  		},
	      ),
          IconButton(
            icon: const Icon(Icons.person_outline, color: primaryBlue),
            onPressed: () {},
          ),
          const SizedBox(width: 8),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _isScanning ? null : _showScanOptions,
        backgroundColor: primaryBlue,
        icon: _isScanning
            ? const SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(
                  color: Colors.white,
                  strokeWidth: 2.5,
                ),
              )
            : const Icon(Icons.qr_code_scanner_rounded, color: Colors.white),
        label: Text(
          _isScanning ? 'Scanning...' : 'Scan Plate',
          style: GoogleFonts.poppins(
            color: Colors.white,
            fontWeight: FontWeight.w700,
          ),
        ),
      ),
      body: StreamBuilder<DocumentSnapshot>(
        stream: _dbService.getStudentProfile(widget.studentId),
        builder: (context, snapshot) {
          String fullName = 'Student';
          String permitStatus = 'Inactive';
          int parkingQuota = 0;

          if (snapshot.hasData && snapshot.data!.exists) {
            final data = snapshot.data!.data() as Map<String, dynamic>;
            fullName = data['fullName'] ?? 'Student';
            permitStatus = data['permitStatus'] ?? 'Inactive';
            parkingQuota = data['parkingQuota'] ?? 0;
          }

          return SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 10.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // 1. Dynamic User Banner
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: primaryBlue,
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Welcome, $fullName',
                        style: GoogleFonts.poppins(
                          color: Colors.white,
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 12),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            'Permit Status: $permitStatus',
                            style: GoogleFonts.poppins(
                              color: Colors.white70,
                              fontSize: 13,
                            ),
                          ),
                          Text(
                            'Available Quota: $parkingQuota',
                            style: GoogleFonts.poppins(
                              color: Colors.white,
                              fontSize: 13,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 24),

                // 2. Live Hostel Traffic Map Section
                Text(
                  'Live Hostel Traffic Map',
                  style: GoogleFonts.poppins(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: textDark,
                  ),
                ),
                const SizedBox(height: 12),
                Container(
                  height: 220,
                  width: double.infinity,
                  clipBehavior: Clip.antiAlias,
                  decoration: BoxDecoration(
                    color: cardBg,
                    borderRadius: BorderRadius.circular(16),
                    boxShadow: const [
                      BoxShadow(color: Color(0x0A000000), blurRadius: 10),
                    ],
                  ),
                  child: kIsWeb
                      ? _buildWebMapPlaceholder()
                      : Stack(
                          children: [
                            if (_mapController != null)
                              WebViewWidget(controller: _mapController!),
                            Positioned(
                              bottom: 12,
                              left: 12,
                              right: 12,
                              child: Container(
                                padding: const EdgeInsets.symmetric(
                                  vertical: 8,
                                  horizontal: 12,
                                ),
                                decoration: BoxDecoration(
                                  color: Colors.white.withValues(alpha: 0.9),
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    const Icon(
                                      Icons.traffic_rounded,
                                      color: primaryBlue,
                                      size: 18,
                                    ),
                                    const SizedBox(width: 8),
                                    Text(
                                      'TomTom Traffic Layer Active',
                                      style: GoogleFonts.poppins(
                                        fontSize: 12,
                                        fontWeight: FontWeight.w600,
                                        color: textDark,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ],
                        ),
                ),
                const SizedBox(height: 24),

                // 3. Entry / Exit Logs
                Text(
                  'Entry / Exit Logs',
                  style: GoogleFonts.poppins(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: textDark,
                  ),
                ),
                const SizedBox(height: 12),
                _buildEntryLogsSection(),
                const SizedBox(height: 80), // room for FAB
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildWebMapPlaceholder() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.map_rounded, size: 48, color: primaryBlue),
          const SizedBox(height: 12),
          Text(
            'Live traffic map available on mobile app',
            style: GoogleFonts.poppins(
              color: textDark,
              fontWeight: FontWeight.w600,
              fontSize: 13,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            '(TomTom WebView not supported on Chrome)',
            style: GoogleFonts.poppins(color: Colors.grey, fontSize: 11),
          ),
        ],
      ),
    );
  }

  Widget _buildEntryLogsSection() {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('entry_logs')
          .where('studentUid', isEqualTo: widget.studentId)
          .orderBy('timestamp', descending: true)
          .limit(10)
          .snapshots(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return Container(
            width: double.infinity,
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: cardBg,
              borderRadius: BorderRadius.circular(16),
            ),
            child: const Center(
              child: CircularProgressIndicator(color: primaryBlue),
            ),
          );
        }

        if (snapshot.hasError) {
          return Container(
            width: double.infinity,
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: cardBg,
              borderRadius: BorderRadius.circular(16),
            ),
            child: Center(
              child: Text(
                'Error loading logs: ${snapshot.error}',
                style: GoogleFonts.poppins(color: Colors.red, fontSize: 12),
                textAlign: TextAlign.center,
              ),
            ),
          );
        }

        if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
          return Container(
            width: double.infinity,
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: cardBg,
              borderRadius: BorderRadius.circular(16),
              boxShadow: const [
                BoxShadow(color: Color(0x0A000000), blurRadius: 10),
              ],
            ),
            child: Center(
              child: Text(
                'No entry or exit history available.',
                style: GoogleFonts.poppins(color: Colors.grey, fontSize: 13),
              ),
            ),
          );
        }

        return Column(
          children: snapshot.data!.docs.map((doc) {
            final data = doc.data() as Map<String, dynamic>;
            final direction = data['direction'] ?? 'entry';
            final plate = data['plate'] ?? '-';
            final ts = (data['timestamp'] as Timestamp?)?.toDate();

            final timeStr = ts != null
                ? '${ts.day}/${ts.month} '
                    '${ts.hour.toString().padLeft(2, '0')}:'
                    '${ts.minute.toString().padLeft(2, '0')}'
                : '--';

            final isEntry = direction == 'entry';

            return Container(
              margin: const EdgeInsets.only(bottom: 8),
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: cardBg,
                borderRadius: BorderRadius.circular(12),
                boxShadow: const [
                  BoxShadow(color: Color(0x0A000000), blurRadius: 6),
                ],
              ),
              child: Row(
                children: [
                  Icon(
                    isEntry ? Icons.login_rounded : Icons.logout_rounded,
                    color: isEntry ? Colors.green : Colors.red,
                    size: 26,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          plate,
                          style: GoogleFonts.poppins(
                            fontWeight: FontWeight.w700,
                            fontSize: 14,
                            color: textDark,
                          ),
                        ),
                        Text(
                          direction.toUpperCase(),
                          style: GoogleFonts.poppins(
                            fontSize: 11,
                            color: Colors.grey,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Text(
                    timeStr,
                    style: GoogleFonts.poppins(
                      fontSize: 11,
                      color: Colors.grey,
                    ),
                  ),
                ],
              ),
            );
          }).toList(),
        );
      },
    );
  }
}
