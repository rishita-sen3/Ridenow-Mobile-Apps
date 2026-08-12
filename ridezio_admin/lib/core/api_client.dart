import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

class ApiClient {
  Future<Map<String, String>> _getHeaders() async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('auth_token');
    return {
      'Content-Type': 'application/json',
      'Accept': 'application/json',
      if (token != null) 'Authorization': 'Bearer $token',
    };
  }

  Future<http.Response> get(String url) async {
    return await http.get(
      Uri.parse(url),
      headers: await _getHeaders(),
    ).timeout(const Duration(seconds: 60));
  }

  Future<http.Response> post(String url, {Map<String, dynamic>? body}) async {
    return await http.post(
      Uri.parse(url),
      headers: await _getHeaders(),
      body: body != null ? jsonEncode(body) : null,
    ).timeout(const Duration(seconds: 60));
  }

  Future<http.Response> put(String url, {Map<String, dynamic>? body}) async {
    return await http.put(
      Uri.parse(url),
      headers: await _getHeaders(),
      body: body != null ? jsonEncode(body) : null,
    ).timeout(const Duration(seconds: 60));
  }

  Future<http.Response> patch(String url, {Map<String, dynamic>? body}) async {
    return await http.patch(
      Uri.parse(url),
      headers: await _getHeaders(),
      body: body != null ? jsonEncode(body) : null,
    ).timeout(const Duration(seconds: 60));
  }

  Future<http.Response> delete(String url) async {
    return await http.delete(
      Uri.parse(url),
      headers: await _getHeaders(),
    ).timeout(const Duration(seconds: 60));
  }

  Future<http.Response> multipartRequest(
    String url, {
    required String method,
    Map<String, String>? fields,
    String? fileField,
    String? filePath,
  }) async {
    final request = http.MultipartRequest(method, Uri.parse(url));
    
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('auth_token');
    if (token != null) {
      request.headers['Authorization'] = 'Bearer $token';
    }
    request.headers['Accept'] = 'application/json';

    if (fields != null) {
      request.fields.addAll(fields);
    }

    if (fileField != null && filePath != null && filePath.isNotEmpty) {
      request.files.add(await http.MultipartFile.fromPath(fileField, filePath));
    }

    final streamedResponse = await request.send().timeout(const Duration(seconds: 30));
    return await http.Response.fromStream(streamedResponse);
  }
}
