import 'dart:convert';
import 'package:http/http.dart' as http;
import 'auth_service.dart';

class InboundService {
  InboundService._();
  static final InboundService instance = InboundService._();

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
      final message = body is Map && body['error'] is Map
          ? body['error']['message']
          : 'Request failed.';
      throw Exception(message?.toString() ?? 'Request failed.');
    }
    return body;
  }

  Future<List<Map<String, dynamic>>> getGrns() async {
    final r = await http.get(Uri.parse('$_baseUrl/grns'), headers: _headers());
    final body = _body(r);
    return List<Map<String, dynamic>>.from(
      (body['data'] as List? ?? []).map((e) => Map<String, dynamic>.from(e)),
    );
  }

  Future<List<Map<String, dynamic>>> getProductionReceipts() async {
    final r = await http.get(
      Uri.parse('$_baseUrl/production-receipts'),
      headers: _headers(),
    );
    final body = _body(r);
    return List<Map<String, dynamic>>.from(
      (body['data'] as List? ?? []).map((e) => Map<String, dynamic>.from(e)),
    );
  }

  Future<Map<String, dynamic>> createGrn({
    required String supplierName,
    String? invoiceNo,
    required String warehouseId,
    required List<Map<String, dynamic>> items,
  }) async {
    final r = await http.post(
      Uri.parse('$_baseUrl/grns'),
      headers: _headers(),
      body: jsonEncode({
        'supplierName': supplierName,
        'invoiceNo': invoiceNo,
        'warehouseId': warehouseId,
        'items': items,
      }),
    );
    final body = _body(r);
    return Map<String, dynamic>.from(body['data'] as Map);
  }

  Future<void> createProductionReceipt({
    required String receiptNo,
    String? productionReference,
    required String warehouseId,
    required List<Map<String, dynamic>> items,
  }) async {
    final r = await http.post(
      Uri.parse('$_baseUrl/production-receipts'),
      headers: _headers(),
      body: jsonEncode({
        'receiptNo': receiptNo,
        'productionReference': productionReference,
        'warehouseId': warehouseId,
        'items': items,
      }),
    );
    _body(r);
  }
}
