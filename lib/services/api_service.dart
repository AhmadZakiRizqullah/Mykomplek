// lib/services/api_service.dart
import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:http/http.dart' as http;
import '../config/constants.dart';
import '../utils/session.dart';
import 'package:image_picker/image_picker.dart';

class ApiService {
  static Future<Map<String, String>> _getHeaders(
    {bool needsAuth = false}) async {
      final headers = {
        'Content-Type': 'application/json',
        'Accept': 'application/json',
      };

      if (needsAuth) {
        final token = await Session.getToken();
        print('🔐 TOKEN DIAMBIL: $token');

        if (token != null && token.isNotEmpty) {
          headers['Authorization'] = 'Bearer $token';
        }
      }

      print('📤 HEADERS TERKIRIM: $headers');
      return headers;
    }

  static Future<Map<String, dynamic>> post(
    String url,
    Map<String, dynamic> body, {
    bool needsAuth = false,
  }) async {
    try {
      print('🌐 POST Request to: $url');
      print('📦 Body: ${jsonEncode(body)}');

      final headers = await _getHeaders(needsAuth: needsAuth);

      final response = await http
          .post(
        Uri.parse(url),
        headers: headers,
        body: jsonEncode(body),
      )
          .timeout(
        const Duration(seconds: 10),
        onTimeout: () {
          throw Exception(
              'Request timeout - Cek koneksi internet atau IP address');
        },
      );

      print('📥 Response Status: ${response.statusCode}');
      print('📥 Response Body: ${response.body}');

      if (response.statusCode == 200 || response.statusCode == 201) {
        return jsonDecode(response.body);
      } else {
        // Try to parse error response
        try {
          return jsonDecode(response.body);
        } catch (e) {
          return {
            'status': response.statusCode,
            'message': 'HTTP Error ${response.statusCode}: ${response.body}',
          };
        }
      }
    } on SocketException catch (e) {
      print('❌ SocketException: $e');
      return {
        'status': 500,
        'message': 'Tidak dapat terhubung ke server. Pastikan:\n'
            '1. XAMPP Apache & MySQL sudah running\n'
            '2. IP address di constants.dart sudah benar\n'
            '3. Laptop dan browser di jaringan yang sama',
      };
    } catch (e) {
      print('❌ Error: $e');
      return {
        'status': 500,
        'message': 'Koneksi gagal: $e',
      };
    }
  }

  static Future<Map<String, dynamic>> get(
    String url, {
    bool needsAuth = false,
    Map<String, String>? queryParams,
  }) async {
    try {
      print('🌐 GET Request to: $url');

      final headers = await _getHeaders(needsAuth: needsAuth);

      Uri uri = Uri.parse(url);
      if (queryParams != null) {
        uri = uri.replace(queryParameters: queryParams);
      }

      print('🔗 Full URL: $uri');

      final response = await http.get(uri, headers: headers).timeout(
        const Duration(seconds: 10),
        onTimeout: () {
          throw Exception('Request timeout');
        },
      );

      print('📥 Response Status: ${response.statusCode}');
      print('📥 Response Body: ${response.body}');

      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      } else {
        try {
          return jsonDecode(response.body);
        } catch (e) {
          return {
            'status': response.statusCode,
            'message': 'HTTP Error ${response.statusCode}',
          };
        }
      }
    } on SocketException catch (e) {
      print('❌ SocketException: $e');
      return {
        'status': 500,
        'message': 'Tidak dapat terhubung ke server. Cek XAMPP dan IP address.',
      };
    } catch (e) {
      print('❌ Error: $e');
      return {
        'status': 500,
        'message': 'Koneksi gagal: $e',
      };
    }
  }

  static Future<Map<String, dynamic>> delete(
    String url,
    Map<String, dynamic> body, {
    bool needsAuth = false,
  }) async {
    try {
      final headers = await _getHeaders(needsAuth: needsAuth);
      final response = await http.delete(
        Uri.parse(url),
        headers: headers,
        body: jsonEncode(body),
      );

      return jsonDecode(response.body);
    } catch (e) {
      return {
        'status': 500,
        'message': 'Koneksi gagal: $e',
      };
    }
  }

  static Future<Map<String, dynamic>> uploadMultipart(
    String url,
    Map<String, String> fields,
    Map<String, dynamic> files, // Changed from Map<String, File>
  ) async {
    try {
      print('🌐 Upload to: $url');

      final token = await Session.getToken();
      final request = http.MultipartRequest('POST', Uri.parse(url));

      if (token != null) {
        request.headers['Authorization'] = 'Bearer $token';
      }

      request.fields.addAll(fields);

      // Handle files for both web and mobile
      for (var entry in files.entries) {
        if (kIsWeb) {
          // For web: files[key] should be Uint8List
          if (entry.value is Uint8List) {
            request.files.add(
              http.MultipartFile.fromBytes(
                entry.key,
                entry.value as Uint8List,
                filename:
                    '${entry.key}_${DateTime.now().millisecondsSinceEpoch}.jpg',
              ),
            );
          }
        } else {
          // For mobile: files[key] should be File
          if (entry.value is File) {
            request.files.add(
              await http.MultipartFile.fromPath(
                  entry.key, (entry.value as File).path),
            );
          }
        }
      }

      final streamedResponse = await request.send().timeout(
        const Duration(seconds: 30),
        onTimeout: () {
          throw Exception('Upload timeout');
        },
      );

      final response = await http.Response.fromStream(streamedResponse);

      print('📥 Upload Response: ${response.body}');

      return jsonDecode(response.body);
    } on SocketException catch (e) {
      print('❌ SocketException: $e');
      return {
        'status': 500,
        'message': 'Tidak dapat terhubung ke server',
      };
    } catch (e) {
      print('❌ Upload Error: $e');
      return {
        'status': 500,
        'message': 'Upload gagal: $e',
      };
    }
  }
}
