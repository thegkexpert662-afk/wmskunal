import 'dart:convert';
import 'package:http/http.dart' as http;
import 'auth_service.dart';

class CompanyService {
  CompanyService._();
  static final instance = CompanyService._();
  static const apiBase = String.fromEnvironment(
    'WMS_API_BASE_URL',
    defaultValue: 'http://localhost:4000/api',
  );

  Map<String, String> get _headers {
    final token = AuthService.instance.session?.accessToken;
    if (token == null || token.isEmpty) throw Exception('Please login again.');
    return {'Content-Type': 'application/json', 'Authorization': 'Bearer $token'};
  }

  Future<List<Map<String, dynamic>>> list() async {
    final response = await http.get(Uri.parse('$apiBase/company'), headers: _headers);
    if (response.statusCode != 200) throw Exception(_error(response));
    final body = jsonDecode(response.body) as Map;
    return (body['companies'] as List? ?? []).map((e) => Map<String, dynamic>.from(e as Map)).toList();
  }

  Future<Map<String, dynamic>> create(Map<String, dynamic> data) async {
    final response = await http.post(Uri.parse('$apiBase/company'), headers: _headers, body: jsonEncode(data));
    if (response.statusCode != 201) throw Exception(_error(response));
    return Map<String, dynamic>.from((jsonDecode(response.body) as Map)['company'] as Map);
  }

  Future<Map<String, dynamic>> update(String id, Map<String, dynamic> data) async {
    final response = await http.patch(Uri.parse('$apiBase/company/$id'), headers: _headers, body: jsonEncode(data));
    if (response.statusCode != 200) throw Exception(_error(response));
    return Map<String, dynamic>.from((jsonDecode(response.body) as Map)['company'] as Map);
  }

  Future<Map<String, dynamic>> setStatus(String id, bool isActive) async {
    final response = await http.patch(
      Uri.parse('$apiBase/company/$id/status'),
      headers: _headers,
      body: jsonEncode({'isActive': isActive}),
    );
    if (response.statusCode != 200) throw Exception(_error(response));
    return Map<String, dynamic>.from((jsonDecode(response.body) as Map)['company'] as Map);
  }

  Future<List<Map<String, dynamic>>> modules(String id) async {
    final response = await http.get(Uri.parse('$apiBase/company/$id/modules'), headers: _headers);
    if (response.statusCode != 200) throw Exception(_error(response));
    final body = jsonDecode(response.body) as Map;
    return (body['modules'] as List? ?? []).map((e) => Map<String, dynamic>.from(e as Map)).toList();
  }

  Future<List<Map<String, dynamic>>> updateModules(String id, List<Map<String, dynamic>> modules) async {
    final response = await http.put(
      Uri.parse('$apiBase/company/$id/modules'),
      headers: _headers,
      body: jsonEncode({'modules': modules}),
    );
    if (response.statusCode != 200) throw Exception(_error(response));
    final body = jsonDecode(response.body) as Map;
    return (body['modules'] as List? ?? []).map((e) => Map<String, dynamic>.from(e as Map)).toList();
  }

  String _error(http.Response response) {
    try {
      final body = jsonDecode(response.body) as Map;
      final error = body['error'];
      if (error is Map && error['message'] != null) return error['message'].toString();
      return 'Request failed (${response.statusCode}).';
    } catch (_) {
      return 'Unable to connect to WMS server.';
    }
  }
}
