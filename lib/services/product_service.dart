import 'dart:convert';
import 'package:http/http.dart' as http;
import 'auth_service.dart';

class ProductService {
  ProductService._();
  static final ProductService instance = ProductService._();

  static const String _baseUrl = String.fromEnvironment(
    'WMS_API_BASE_URL',
    defaultValue: 'http://localhost:4000/api',
  );

  Map<String, String> _headers() {
    final token = AuthService.instance.session?.accessToken;
    if (token == null || token.isEmpty) {
      throw Exception('Please login again.');
    }
    return {
      'Content-Type': 'application/json',
      'Authorization': 'Bearer $token',
    };
  }

  List<Map<String, dynamic>> _list(http.Response response) {
    final body = jsonDecode(response.body);
    if (response.statusCode != 200) throw Exception(_message(body));
    final data = body['products'];
    if (data is! List) return [];
    return data.map((e) => Map<String, dynamic>.from(e as Map)).toList();
  }

  Map<String, dynamic> _one(http.Response response) {
    final body = jsonDecode(response.body);
    if (response.statusCode != 200 && response.statusCode != 201) {
      throw Exception(_message(body));
    }
    return Map<String, dynamic>.from(body['product'] as Map);
  }

  String _message(dynamic body) {
    if (body is Map && body['error'] is Map) {
      return (body['error']['message'] ?? 'Request failed.').toString();
    }
    return 'Request failed.';
  }

  Future<List<Map<String, dynamic>>> getProducts() async {
    final response = await http.get(
      Uri.parse('$_baseUrl/products'),
      headers: _headers(),
    );
    return _list(response);
  }

  Future<Map<String, dynamic>> createProduct({
    required String sku,
    required String name,
    String? description,
    String? hsnCode,
    required String uom,
    required double rate,
  }) async {
    final response = await http.post(
      Uri.parse('$_baseUrl/products'),
      headers: _headers(),
      body: jsonEncode({
        'sku': sku,
        'name': name,
        'description': description,
        'hsnCode': hsnCode,
        'uom': uom,
        'rate': rate,
      }),
    );
    return _one(response);
  }

  Future<Map<String, dynamic>> updateProduct({
    required String id,
    required Map<String, dynamic> data,
  }) async {
    final response = await http.patch(
      Uri.parse('$_baseUrl/products/$id'),
      headers: _headers(),
      body: jsonEncode(data),
    );
    return _one(response);
  }

  Future<Map<String, dynamic>> updateStatus({
    required String id,
    required bool isActive,
  }) async {
    final response = await http.patch(
      Uri.parse('$_baseUrl/products/$id/status'),
      headers: _headers(),
      body: jsonEncode({'isActive': isActive}),
    );
    return _one(response);
  }
}
