import 'dart:convert';
import 'package:http/http.dart' as http;
import 'auth_service.dart';

class InvoiceService {
  InvoiceService._();
  static final instance = InvoiceService._();

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

  Future<List<Map<String, dynamic>>> list({
    String? search,
    String? status,
    String? from,
    String? to,
  }) async {
    final params = <String, String>{};
    if (search != null && search.trim().isNotEmpty) params['search'] = search.trim();
    if (status != null && status.isNotEmpty && status != 'All') params['status'] = status;
    if (from != null && from.isNotEmpty) params['from'] = from;
    if (to != null && to.isNotEmpty) params['to'] = to;
    final uri = Uri.parse('$base/invoices').replace(queryParameters: params.isEmpty ? null : params);
    final r = await http.get(uri, headers: _headers());
    final b = jsonDecode(r.body);
    if (r.statusCode != 200) throw Exception(_message(b));
    return (b['invoices'] as List? ?? [])
        .map((e) => Map<String, dynamic>.from(e as Map))
        .toList();
  }

  Future<Map<String, dynamic>> detail(String id) async {
    final r = await http.get(Uri.parse('$base/invoices/$id'), headers: _headers());
    final b = jsonDecode(r.body);
    if (r.statusCode != 200) throw Exception(_message(b));
    return {
      'invoice': Map<String, dynamic>.from(b['invoice'] as Map),
      'items': (b['items'] as List? ?? []).map((e) => Map<String, dynamic>.from(e as Map)).toList(),
    };
  }

  Future<Map<String, dynamic>> create({
    required String orderId,
    String? dispatchId,
    String? invoiceDate,
    double discountAmount = 0,
    double cgstRate = 0,
    double sgstRate = 0,
    double igstRate = 0,
    String? paymentTerms,
    String? dueDate,
  }) async {
    final r = await http.post(
      Uri.parse('$base/invoices'),
      headers: _headers(),
      body: jsonEncode({
        'orderId': orderId,
        'dispatchId': dispatchId,
        'invoiceDate': invoiceDate,
        'discountAmount': discountAmount,
        'cgstRate': cgstRate,
        'sgstRate': sgstRate,
        'igstRate': igstRate,
        'paymentTerms': paymentTerms,
        'dueDate': dueDate,
      }),
    );
    final b = jsonDecode(r.body);
    if (r.statusCode < 200 || r.statusCode >= 300) throw Exception(_message(b));
    return Map<String, dynamic>.from(b['invoice'] as Map);
  }

  Future<Map<String, dynamic>> updateStatus(String id, String status) async {
    final r = await http.patch(
      Uri.parse('$base/invoices/$id/status'),
      headers: _headers(),
      body: jsonEncode({'status': status}),
    );
    final b = jsonDecode(r.body);
    if (r.statusCode < 200 || r.statusCode >= 300) throw Exception(_message(b));
    return Map<String, dynamic>.from(b['invoice'] as Map);
  }

  Future<Uri> pdfDataUri(String id) async {
    final r = await http.get(Uri.parse('$base/invoices/$id/pdf'), headers: _headers());
    if (r.statusCode != 200) {
      final b = jsonDecode(r.body);
      throw Exception(_message(b));
    }
    return Uri.parse('data:application/pdf;base64,${base64Encode(r.bodyBytes)}');
  }
}
