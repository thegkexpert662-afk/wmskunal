import 'dart:convert';
import 'package:http/http.dart' as http;
import 'auth_service.dart';

class PickingService {
  PickingService._();
  static final instance = PickingService._();
  static const base = String.fromEnvironment('WMS_API_BASE_URL', defaultValue: 'http://localhost:4000/api');

  Map<String,String> _headers() {
    final token = AuthService.instance.session?.accessToken;
    if (token == null || token.isEmpty) throw Exception('Please login again.');
    return {'Content-Type':'application/json','Authorization':'Bearer $token'};
  }

  String _message(dynamic body) => body is Map && body['error'] is Map
      ? (body['error']['message'] ?? 'Request failed.').toString()
      : 'Request failed.';

  Future<List<Map<String,dynamic>>> pending() async {
    final r=await http.get(Uri.parse('$base/picking/pending'),headers:_headers());
    final b=jsonDecode(r.body);
    if(r.statusCode!=200) throw Exception(_message(b));
    return (b['orders'] as List? ?? []).map((e)=>Map<String,dynamic>.from(e)).toList();
  }

  Future<List<Map<String,dynamic>>> tasks({String? status}) async {
    final uri=Uri.parse('$base/picking/tasks').replace(queryParameters: status==null?null:{'status':status});
    final r=await http.get(uri,headers:_headers());
    final b=jsonDecode(r.body);
    if(r.statusCode!=200) throw Exception(_message(b));
    return (b['tasks'] as List? ?? []).map((e)=>Map<String,dynamic>.from(e)).toList();
  }

  Future<Map<String,dynamic>> detail(String id) async {
    final r=await http.get(Uri.parse('$base/picking/tasks/$id'),headers:_headers());
    final b=jsonDecode(r.body);
    if(r.statusCode!=200) throw Exception(_message(b));
    return Map<String,dynamic>.from(b);
  }

  Future<Map<String,dynamic>> createTask(String orderId) => _post('/picking/tasks', {'orderId':orderId});
  Future<Map<String,dynamic>> pick(String taskId,{required String orderItemId,required String locationId,required double quantity}) =>
      _post('/picking/tasks/$taskId/pick', {'orderItemId':orderItemId,'locationId':locationId,'quantity':quantity});
  Future<Map<String,dynamic>> complete(String taskId) => _post('/picking/tasks/$taskId/complete', {});

  Future<Map<String,dynamic>> _post(String path, Map<String,dynamic> body) async {
    final r=await http.post(Uri.parse('$base$path'),headers:_headers(),body:jsonEncode(body));
    final b=jsonDecode(r.body);
    if(r.statusCode<200||r.statusCode>=300) throw Exception(_message(b));
    return Map<String,dynamic>.from(b);
  }
}
