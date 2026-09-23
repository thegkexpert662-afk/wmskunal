import 'dart:convert';
import 'package:http/http.dart' as http;
import 'auth_service.dart';

class QcService {
  QcService._();
  static final QcService instance = QcService._();

  static const String _baseUrl = String.fromEnvironment(
    'WMS_API_BASE_URL',
    defaultValue: 'http://localhost:4000/api',
  );

  Map<String, String> _headers() {
    final token = AuthService.instance.session?.accessToken;
    if (token == null || token.isEmpty) throw Exception('Please login again.');
    return {'Content-Type': 'application/json', 'Authorization': 'Bearer $token'};
  }

  dynamic _body(http.Response r) {
    final body = jsonDecode(r.body);
    if (r.statusCode < 200 || r.statusCode >= 300) {
      final msg = body is Map && body['error'] is Map ? body['error']['message'] : 'Request failed.';
      throw Exception(msg?.toString() ?? 'Request failed.');
    }
    return body;
  }

  Future<List<Map<String, dynamic>>> getPending() async {
    final r = await http.get(Uri.parse('$_baseUrl/qc/pending'), headers: _headers());
    final b = _body(r);
    return List<Map<String, dynamic>>.from(
      (b['data'] as List? ?? []).map((e) => Map<String, dynamic>.from(e)),
    );
  }

  Future<void> process({
    required String sourceType,
    required String sourceItemId,
    required double inspectedQty,
    required double acceptedQty,
    required double rejectedQty,
    required String result,
    String? remarks,
  }) async {
    final r = await http.post(
      Uri.parse('$_baseUrl/qc'),
      headers: _headers(),
      body: jsonEncode({
        'sourceType': sourceType,
        'sourceItemId': sourceItemId,
        'inspectedQty': inspectedQty,
        'acceptedQty': acceptedQty,
        'rejectedQty': rejectedQty,
        'result': result,
        'remarks': remarks,
      }),
    );
    _body(r);
  }
}
