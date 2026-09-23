import 'dart:convert';
import 'package:http/http.dart' as http;
import 'auth_service.dart';

class DispatchService {
  DispatchService._();
  static final instance = DispatchService._();

  static const base = String.fromEnvironment(
    'WMS_API_BASE_URL',
    defaultValue: 'http://localhost:4000/api',
  );

  Map<String, String> _headers() {
    final token = AuthService.instance.session?.accessToken;
    if (token == null || token.isEmpty) throw Exception('Please login again.');
    return {'Content-Type': 'application/json', 'Authorization': 'Bearer $token'};
  }

  String _message(dynamic body) => body is Map && body['error'] is Map
      ? (body['error']['message'] ?? 'Request failed.').toString()
      : 'Request failed.';

  Future<List<Map<String, dynamic>>> pending() async {
    final r = await http.get(Uri.parse('$base/dispatch/pending'), headers: _headers());
    final b = jsonDecode(r.body);
    if (r.statusCode != 200) throw Exception(_message(b));
    return (b['orders'] as List? ?? [])
        .map((e) => Map<String, dynamic>.from(e as Map))
        .toList();
  }

  Future<List<Map<String, dynamic>>> list({String? status}) async {
    final uri = Uri.parse('$base/dispatch').replace(
      queryParameters: status == null ? null : {'status': status},
    );
    final r = await http.get(uri, headers: _headers());
    final b = jsonDecode(r.body);
    if (r.statusCode != 200) throw Exception(_message(b));
    return (b['dispatches'] as List? ?? [])
        .map((e) => Map<String, dynamic>.from(e as Map))
        .toList();
  }

  Future<Map<String, dynamic>> detail(String id) async {
    final r = await http.get(Uri.parse('$base/dispatch/$id'), headers: _headers());
    final b = jsonDecode(r.body);
    if (r.statusCode != 200) throw Exception(_message(b));
    final result = Map<String, dynamic>.from(b['dispatch'] as Map);
    if (b['invoice'] is Map) result['_invoice'] = Map<String, dynamic>.from(b['invoice'] as Map);
    return result;
  }

  Future<Map<String, dynamic>> create({
    required String orderId,
    String? vehicleNo,
    String? transporterName,
    String? driverName,
    String? driverMobile,
    String? lrNo,
  }) {
    return _post('/dispatch', {
      'orderId': orderId,
      'vehicleNo': vehicleNo,
      'transporterName': transporterName,
      'driverName': driverName,
      'driverMobile': driverMobile,
      'lrNo': lrNo,
    });
  }

  Future<Map<String, dynamic>> gateOut(String id) => _post('/dispatch/$id/gate-out', {});

  Future<Map<String, dynamic>> updateStatus(String id, String status) =>
      _patch('/dispatch/$id/status', {'status': status});

  Future<Map<String, dynamic>> _post(String path, Map<String, dynamic> body) async {
    final r = await http.post(
      Uri.parse('$base$path'),
      headers: _headers(),
      body: jsonEncode(body),
    );
    final b = jsonDecode(r.body);
    if (r.statusCode < 200 || r.statusCode >= 300) throw Exception(_message(b));
    return Map<String, dynamic>.from(b['dispatch'] as Map);
  }

  Future<Map<String, dynamic>> _patch(String path, Map<String, dynamic> body) async {
    final r = await http.patch(
      Uri.parse('$base$path'),
      headers: _headers(),
      body: jsonEncode(body),
    );
    final b = jsonDecode(r.body);
    if (r.statusCode < 200 || r.statusCode >= 300) throw Exception(_message(b));
    return Map<String, dynamic>.from(b['dispatch'] as Map);
  }
}
