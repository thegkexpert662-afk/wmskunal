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

  Future<Map<String, dynamic>> createWarehouse({required String code, required String name, String? address}) async {
    final token = AuthService.instance.session?.accessToken;
    if (token == null || token.isEmpty) throw Exception('Please login again.');
    final r = await http.post(Uri.parse(_baseUrl + '/warehouses'), headers: {'Authorization': 'Bearer ' + token, 'Content-Type': 'application/json'}, body: jsonEncode({'code': code, 'name': name, 'address': address}));
    final body = jsonDecode(r.body);
    if (r.statusCode != 201) throw Exception(body is Map && body['error'] is Map ? body['error']['message'] : 'Unable to create warehouse.');
    return Map<String, dynamic>.from(body['warehouse'] as Map);
  }

  Future<Map<String, dynamic>> updateWarehouse(String id, {String? code, String? name, String? address}) async {
    final token = AuthService.instance.session?.accessToken;
    if (token == null || token.isEmpty) throw Exception('Please login again.');
    final r = await http.patch(Uri.parse(_baseUrl + '/warehouses/' + Uri.encodeComponent(id)), headers: {'Authorization': 'Bearer ' + token, 'Content-Type': 'application/json'}, body: jsonEncode({'code': code, 'name': name, 'address': address}));
    final body = jsonDecode(r.body);
    if (r.statusCode != 200) throw Exception(body is Map && body['error'] is Map ? body['error']['message'] : 'Unable to update warehouse.');
    return Map<String, dynamic>.from(body['warehouse'] as Map);
  }

  Future<Map<String, dynamic>> setWarehouseStatus(String id, bool isActive) async {
    final token = AuthService.instance.session?.accessToken;
    if (token == null || token.isEmpty) throw Exception('Please login again.');
    final r = await http.patch(Uri.parse(_baseUrl + '/warehouses/' + Uri.encodeComponent(id) + '/status'), headers: {'Authorization': 'Bearer ' + token, 'Content-Type': 'application/json'}, body: jsonEncode({'isActive': isActive}));
    final body = jsonDecode(r.body);
    if (r.statusCode != 200) throw Exception(body is Map && body['error'] is Map ? body['error']['message'] : 'Unable to change warehouse status.');
    return Map<String, dynamic>.from(body['warehouse'] as Map);
  }

  Future<Map<String, dynamic>> createLocation(String warehouseId, {required String code, String? zone, String? bin}) async {
    final token = AuthService.instance.session?.accessToken;
    if (token == null || token.isEmpty) throw Exception('Please login again.');
    final r = await http.post(Uri.parse(_baseUrl + '/warehouses/' + Uri.encodeComponent(warehouseId) + '/locations'), headers: {'Authorization': 'Bearer ' + token, 'Content-Type': 'application/json'}, body: jsonEncode({'code': code, 'zone': zone, 'bin': bin}));
    final body = jsonDecode(r.body);
    if (r.statusCode != 201) throw Exception(body is Map && body['error'] is Map ? body['error']['message'] : 'Unable to create location.');
    return Map<String, dynamic>.from(body['location'] as Map);
  }

  Future<Map<String, dynamic>> updateLocation(String warehouseId, String locationId, {String? code, String? zone, String? bin}) async {
    final token = AuthService.instance.session?.accessToken;
    if (token == null || token.isEmpty) throw Exception('Please login again.');
    final r = await http.patch(Uri.parse(_baseUrl + '/warehouses/' + Uri.encodeComponent(warehouseId) + '/locations/' + Uri.encodeComponent(locationId)), headers: {'Authorization': 'Bearer ' + token, 'Content-Type': 'application/json'}, body: jsonEncode({'code': code, 'zone': zone, 'bin': bin}));
    final body = jsonDecode(r.body);
    if (r.statusCode != 200) throw Exception(body is Map && body['error'] is Map ? body['error']['message'] : 'Unable to update location.');
    return Map<String, dynamic>.from(body['location'] as Map);
  }

  Future<Map<String, dynamic>> setLocationStatus(String warehouseId, String locationId, bool isActive) async {
    final token = AuthService.instance.session?.accessToken;
    if (token == null || token.isEmpty) throw Exception('Please login again.');
    final r = await http.patch(Uri.parse(_baseUrl + '/warehouses/' + Uri.encodeComponent(warehouseId) + '/locations/' + Uri.encodeComponent(locationId) + '/status'), headers: {'Authorization': 'Bearer ' + token, 'Content-Type': 'application/json'}, body: jsonEncode({'isActive': isActive}));
    final body = jsonDecode(r.body);
    if (r.statusCode != 200) throw Exception(body is Map && body['error'] is Map ? body['error']['message'] : 'Unable to change location status.');
    return Map<String, dynamic>.from(body['location'] as Map);
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
