import 'dart:convert';
import 'package:http/http.dart' as http;
import 'auth_service.dart';

class OrderService {
  OrderService._();
  static final OrderService instance = OrderService._();

  static const String _baseUrl = String.fromEnvironment(
    'WMS_API_BASE_URL',
    defaultValue: 'http://localhost:4000/api',
  );

  Map<String, String> _headers() {
    final token = AuthService.instance.session?.accessToken;
    if (token == null || token.isEmpty) throw Exception('Please login again.');
    return {
      'Content-Type': 'application/json',
      'Authorization': 'Bearer $token',
    };
  }

  dynamic _body(http.Response response) {
    final body = jsonDecode(response.body);
    if (response.statusCode < 200 || response.statusCode >= 300) {
      final message = body is Map && body['error'] is Map
          ? (body['error']['message'] ?? 'Request failed.').toString()
          : 'Request failed.';
      throw Exception(message);
    }
    return body;
  }

  List<Map<String, dynamic>> _list(http.Response response) {
    final body = _body(response);
    return (body['orders'] as List? ?? [])
        .map((e) => Map<String, dynamic>.from(e as Map))
        .toList();
  }

  Future<List<Map<String, dynamic>>> list({String? status, String? search}) async {
    final query = <String, String>{};
    if (status != null && status != 'All') query['status'] = status;
    if (search != null && search.trim().isNotEmpty) query['search'] = search.trim();
    final uri = Uri.parse('$_baseUrl/orders').replace(queryParameters: query.isEmpty ? null : query);
    return _list(await http.get(uri, headers: _headers()));
  }

  Future<Map<String, dynamic>> detail(String id) async {
    final body = _body(await http.get(
      Uri.parse('$_baseUrl/orders/${Uri.encodeComponent(id)}'),
      headers: _headers(),
    ));
    return Map<String, dynamic>.from(body['order'] as Map);
  }

  Future<Map<String, dynamic>> create({
    required String orderNo,
    required String clientId,
    required String warehouseId,
    String? requiredDate,
    required List<Map<String, dynamic>> items,
    String? remarks,
    String? truckType,
    String? transporterName,
    String? vehicleNo,
    String? driverName,
    String? driverMobile,
    String? shipmentNo,
    String? shipmentDate,
    String? deliveryNo,
    String? deliveryDate,
    String? soldByName,
    String? soldByAddress,
    String? soldByGstin,
    String? soldToName,
    String? soldToAddress,
    String? soldToGstin,
    String? shipToName,
    String? shipToAddress,
    String? shipToGstin,
  }) async {
    final body = _body(await http.post(
      Uri.parse('$_baseUrl/orders'),
      headers: _headers(),
      body: jsonEncode({
        'orderNo': orderNo,
        'clientId': clientId,
        'warehouseId': warehouseId,
        'requiredDate': requiredDate,
        'items': items,
        'remarks': remarks,
        'truckType': truckType,
        'transporterName': transporterName,
        'vehicleNo': vehicleNo,
        'driverName': driverName,
        'driverMobile': driverMobile,
        'shipmentNo': shipmentNo,
        'shipmentDate': shipmentDate,
        'deliveryNo': deliveryNo,
        'deliveryDate': deliveryDate,
        'soldByName': soldByName,
        'soldByAddress': soldByAddress,
        'soldByGstin': soldByGstin,
        'soldToName': soldToName,
        'soldToAddress': soldToAddress,
        'soldToGstin': soldToGstin,
        'shipToName': shipToName,
        'shipToAddress': shipToAddress,
        'shipToGstin': shipToGstin,
      }),
    ));
    return Map<String, dynamic>.from(body['order'] as Map);
  }

  Future<Map<String, dynamic>> updateStatus(String id, String status) async {
    final body = _body(await http.patch(
      Uri.parse('$_baseUrl/orders/${Uri.encodeComponent(id)}/status'),
      headers: _headers(),
      body: jsonEncode({'status': status}),
    ));
    return Map<String, dynamic>.from(body['order'] as Map);
  }

  Future<List<Map<String, dynamic>>> clients() async {
    final body = _body(await http.get(
      Uri.parse('$_baseUrl/clients'),
      headers: _headers(),
    ));
    return (body['clients'] as List? ?? [])
        .map((e) => Map<String, dynamic>.from(e as Map))
        .toList();
  }
}
