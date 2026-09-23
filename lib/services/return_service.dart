import 'dart:convert';
import 'package:http/http.dart' as http;
import 'auth_service.dart';

class ReturnService {
  ReturnService._();
  static final instance = ReturnService._();

  static const base = String.fromEnvironment(
    'WMS_API_BASE_URL',
    defaultValue: 'http://localhost:4000/api',
  );

  Map<String, String> _headers() {
    final token = AuthService.instance.session?.accessToken;
    if (token == null || token.isEmpty) throw Exception('Please login again.');
    return {'Content-Type': 'application/json', 'Authorization': 'Bearer $token'};
  }

  dynamic _body(http.Response r) {
    final b = jsonDecode(r.body);
    if (r.statusCode < 200 || r.statusCode >= 300) {
      final message = b is Map && b['error'] is Map
          ? (b['error']['message'] ?? 'Request failed.').toString()
          : 'Request failed.';
      throw Exception(message);
    }
    return b;
  }

  Future<List<Map<String, dynamic>>> list({String? status}) async {
    final uri = Uri.parse('$base/returns').replace(
      queryParameters: status == null || status == 'All' ? null : {'status': status},
    );
    final b = _body(await http.get(uri, headers: _headers()));
    return (b['returns'] as List? ?? [])
        .map((e) => Map<String, dynamic>.from(e as Map))
        .toList();
  }

  Future<List<Map<String, dynamic>>> pending() async {
    final b = _body(await http.get(Uri.parse('$base/returns/pending'), headers: _headers()));
    return (b['returns'] as List? ?? [])
        .map((e) => Map<String, dynamic>.from(e as Map))
        .toList();
  }

  Future<List<Map<String, dynamic>>> sourceOrders() async {
    final b = _body(await http.get(Uri.parse('$base/returns/source/orders'), headers: _headers()));
    return (b['orders'] as List? ?? [])
        .map((e) => Map<String, dynamic>.from(e as Map))
        .toList();
  }

  Future<List<Map<String, dynamic>>> sourceInvoices() async {
    final b = _body(await http.get(
      Uri.parse('$base/returns/source/invoices'),
      headers: _headers(),
    ));
    return (b['invoices'] as List? ?? [])
        .map((e) => Map<String, dynamic>.from(e as Map))
        .toList();
  }

  Future<Map<String, dynamic>> detail(String id) async {
    final b = _body(await http.get(Uri.parse('$base/returns/$id'), headers: _headers()));
    return Map<String, dynamic>.from(b['return'] as Map);
  }

  Future<Map<String, dynamic>> create({
    String? orderId,
    String? invoiceId,
    required String warehouseId,
    required String reason,
    required List<Map<String, dynamic>> items,
  }) async {
    final b = _body(await http.post(
      Uri.parse('$base/returns'),
      headers: _headers(),
      body: jsonEncode({
        'orderId': orderId,
        'invoiceId': invoiceId,
        'warehouseId': warehouseId,
        'reason': reason,
        'items': items,
      }),
    ));
    return Map<String, dynamic>.from(b['return'] as Map);
  }

  Future<Map<String, dynamic>> gateIn(String id) async {
    final b = _body(await http.post(
      Uri.parse('$base/returns/$id/gate-in'),
      headers: _headers(),
      body: jsonEncode({}),
    ));
    return Map<String, dynamic>.from(b['return'] as Map);
  }

  Future<Map<String, dynamic>> qc(
    String id,
    List<Map<String, dynamic>> items,
  ) async {
    final b = _body(await http.post(
      Uri.parse('$base/returns/$id/qc'),
      headers: _headers(),
      body: jsonEncode({'items': items}),
    ));
    return Map<String, dynamic>.from(b['return'] as Map);
  }

  Future<Map<String, dynamic>> cancel(String id) async {
    final b = _body(await http.patch(
      Uri.parse('$base/returns/$id/status'),
      headers: _headers(),
      body: jsonEncode({'status': 'cancelled'}),
    ));
    return Map<String, dynamic>.from(b['return'] as Map);
  }
}
