import 'dart:convert';
import 'package:http/http.dart' as http;

class AprsApiService {
  // ⚠️ CHANGE THIS depending on where you're running:
  //   - Chrome on the same PC as the backend:   http://127.0.0.1:8000
  //   - Android emulator:                        http://10.0.2.2:8000
  //   - Physical phone (same WiFi as PC):        http://<YOUR-PC-LAN-IP>:8000
  static const String baseUrl = 'http://192.168.100.115:8000';

  /// Sends an image file to the Python backend and returns the JSON response.
  /// Works for both mobile (XFile from camera) and web (Uint8List).
  static Future<Map<String, dynamic>?> scanPlate({
    required List<int> imageBytes,
    required String filename,
    String gateId = 'GATE_01',
  }) async {
    try {
      final uri = Uri.parse('$baseUrl/scan');
      final request = http.MultipartRequest('POST', uri);

      request.fields['gate_id'] = gateId;

      // Attach the image
      request.files.add(
        http.MultipartFile.fromBytes(
          'file',
          imageBytes,
          filename: filename,
        ),
      );

      final streamed = await request.send().timeout(
            const Duration(seconds: 45),
          );
      final response = await http.Response.fromStream(streamed);

      if (response.statusCode != 200) {
        return {
          'status': 'error',
          'message': 'Server returned ${response.statusCode}',
        };
      }

      return jsonDecode(response.body) as Map<String, dynamic>;
    } catch (e) {
      return {
        'status': 'error',
        'message': 'Connection failed: $e',
      };
    }
  }
}
