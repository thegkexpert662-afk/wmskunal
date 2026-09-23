import 'dart:convert';
import 'package:http/http.dart' as http;
import 'auth_service.dart';

class WarehouseService {
  WarehouseService._();
  static final WarehouseService instance = WarehouseService._();

  static const String _baseUrl = String.fromEnvironment(
    'WMS_API_BASE_URL',
    defaultValue: 'http://localhost:4000/api',
  );

  Future<List<Map<String, dynamic>>> getWarehouses() async {
    final token = AuthService.instance.session?.accessToken;
    if (token == null || token.isEmpty) throw Exception('Please login again.');
    final r = await http.get(
      Uri.parse('$_baseUrl/warehouses'),
      headers: {'Authorization': 'Bearer $token'},
    );
    final body = jsonDecode(r.body);
    if (r.statusCode != 200) {
      final message = body is Map && body['error'] is Map
          ? body['error']['message']
          : 'Unable to load warehouses.';
      throw Exception(message);
    }
    return List<Map<String, dynamic>>.from(
      (body['warehouses'] as List? ?? []).map((e) => Map<String, dynamic>.from(e)),
    );
  }

  Future<List<Map<String, dynamic>>> getLocations(String warehouseId) async {
    final token = AuthService.instance.session?.accessToken;
    if (token == null || token.isEmpty) throw Exception('Please login again.');
    final r = await http.get(
      Uri.parse('$_baseUrl/warehouses/${Uri.encodeComponent(warehouseId)}/locations'),
      headers: {'Authorization': 'Bearer $token'},
    );
    final body = jsonDecode(r.body);
    if (r.statusCode != 200) {
      final message = body is Map && body['error'] is Map
          ? body['error']['message']
          : 'Unable to load locations.';
      throw Exception(message);
    }
    return List<Map<String, dynamic>>.from(
      (body['locations'] as List? ?? []).map((e) => Map<String, dynamic>.from(e)),
    );
  }
}
