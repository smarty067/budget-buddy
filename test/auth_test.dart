import 'dart:convert';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;

void main() {
  test('Supabase Auth Raw HTTP Audit', () async {
    print('--- RAW HTTP AUDIT START ---');
    final url = 'https://zvrgpxcguadpurovvwcy.supabase.co/auth/v1/signup';
    final anonKey = 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6Inp2cmdweGNndWFkcHVyb3Z2d2N5Iiwicm9sZSI6ImFub24iLCJpYXQiOjE3ODUyMjcwMzgsImV4cCI6MjEwMDgwMzAzOH0.hRh4-sQUT7HBJaVsZZdE-96XYCre31b3LTpQKT_PJ-g';

    try {
      final response = await http.post(
        Uri.parse(url),
        headers: {
          'apikey': anonKey,
          'Content-Type': 'application/json',
        },
        body: jsonEncode({
          'email': 'budgetbuddy_test_user_123@gmail.com',
          'password': 'password123',
        }),
      );

      print('Status Code: ${response.statusCode}');
      print('Headers: ${response.headers}');
      print('Body: ${response.body}');
    } catch (e) {
      print('HTTP request failed: $e');
    }
    print('--- RAW HTTP AUDIT END ---');
  });
}
