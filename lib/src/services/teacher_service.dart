import 'dart:convert';
import 'package:http/http.dart' as http;
import '../config/api_config.dart';

class TeacherService {
  static Future<Map<String, dynamic>> getTeacherDetails(String udiseCode) async {
    try {
      final response = await http.get(
        Uri.parse('${ApiConfig.baseUrl}/teachers/$udiseCode'),
        headers: {'Content-Type': 'application/json'},
      );

      final dynamic decoded = json.decode(response.body);
      return Map<String, dynamic>.from(decoded as Map);
    } catch (e) {
      return {
        'success': false,
        'message': e.toString(),
      };
    }
  }
}
