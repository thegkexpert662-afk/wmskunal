import 'dart:convert';
import 'package:http/http.dart' as http;
import 'auth_service.dart';

class PackingService {
  PackingService._();
  static final instance = PackingService._();
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
    final r = await http.get(Uri.parse('$base/packing/pending'), headers: _headers());
    final b = jsonDecode(r.body);
    if (r.statusCode != 200) throw Exception(_message(b));
    return (b['orders'] as List? ?? [])
        .map((e) => Map<String, dynamic>.from(e))
        .toList();
  }

  Future<List<Map<String, dynamic>>> tasks({String? status}) async {
    final uri = Uri.parse('$base/packing/tasks').replace(
      queryParameters: status == null ? null : {'status': status},
    );
    final r = await http.get(uri, headers: _headers());
    final b = jsonDecode(r.body);
    if (r.statusCode != 200) throw Exception(_message(b));
    return (b['tasks'] as List? ?? [])
        .map((e) => Map<String, dynamic>.from(e))
        .toList();
  }

  Future<Map<String, dynamic>> detail(String id) async {
    final r = await http.get(Uri.parse('$base/packing/tasks/$id'), headers: _headers());
    final b = jsonDecode(r.body);
    if (r.statusCode != 200) throw Exception(_message(b));
    return Map<String, dynamic>.from(b);
  }

  Future<Map<String, dynamic>> createTask(String orderId) =>
      _post('/packing/tasks', {'orderId': orderId});

  Future<Map<String, dynamic>> createPackage(
    String taskId, {
    required String packageNo,
    String packageType = 'Box',
    double weight = 0,
    double length = 0,
    double width = 0,
    double height = 0,
  }) =>
      _post('/packing/tasks/$taskId/packages', {
        'packageNo': packageNo,
        'packageType': packageType,
        'weight': weight,
        'length': length,
        'width': width,
        'height': height,
      });

  Future<Map<String, dynamic>> pack(
    String taskId, {
    required String orderItemId,
    required String packageId,
    required double quantity,
  }) =>
      _post('/packing/tasks/$taskId/pack', {
        'orderItemId': orderItemId,
        'packageId': packageId,
        'quantity': quantity,
      });

  Future<Map<String, dynamic>> complete(String taskId) =>
      _post('/packing/tasks/$taskId/complete', {});

  Future<Map<String, dynamic>> _post(
    String path,
    Map<String, dynamic> body,
  ) async {
    final r = await http.post(
      Uri.parse('$base$path'),
      headers: _headers(),
      body: jsonEncode(body),
    );
    final b = jsonDecode(r.body);
    if (r.statusCode < 200 || r.statusCode >= 300) {
      throw Exception(_message(b));
    }
    return Map<String, dynamic>.from(b);
  }
}
