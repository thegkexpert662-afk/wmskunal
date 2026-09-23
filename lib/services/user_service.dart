import 'dart:convert';
import 'package:http/http.dart' as http;
import 'auth_service.dart';

class UserService {
  UserService._();
  static final instance = UserService._();
  static const apiBase = String.fromEnvironment('WMS_API_BASE_URL', defaultValue: 'http://localhost:4000/api');

  Map<String,String> get _headers {
    final token = AuthService.instance.session?.accessToken;
    if (token == null || token.isEmpty) throw Exception('Please login again.');
    return {'Content-Type':'application/json','Authorization':'Bearer $token'};
  }

  Future<List<Map<String,dynamic>>> list() async {
    final r=await http.get(Uri.parse('$apiBase/users'),headers:_headers);
    if(r.statusCode!=200) throw Exception(_error(r));
    final body=jsonDecode(r.body) as Map;
    return (body['users'] as List? ?? []).map((e)=>Map<String,dynamic>.from(e as Map)).toList();
  }

  Future<List<Map<String,dynamic>>> roles() async {
    final r=await http.get(Uri.parse('$apiBase/users/roles'),headers:_headers);
    if(r.statusCode!=200) throw Exception(_error(r));
    final body=jsonDecode(r.body) as Map;
    return (body['roles'] as List? ?? []).map((e)=>Map<String,dynamic>.from(e as Map)).toList();
  }

  Future<List<Map<String,dynamic>>> warehouses({String? companyId}) async {
    final suffix=companyId==null?'':'?companyId=${Uri.encodeComponent(companyId)}';
    final r=await http.get(Uri.parse('$apiBase/users/warehouses$suffix'),headers:_headers);
    if(r.statusCode!=200) throw Exception(_error(r));
    final body=jsonDecode(r.body) as Map;
    return (body['warehouses'] as List? ?? []).map((e)=>Map<String,dynamic>.from(e as Map)).toList();
  }

  Future<Map<String,dynamic>> create(Map<String,dynamic> data) async {
    final r=await http.post(Uri.parse('$apiBase/users'),headers:_headers,body:jsonEncode(data));
    if(r.statusCode!=201) throw Exception(_error(r));
    return Map<String,dynamic>.from((jsonDecode(r.body) as Map)['user'] as Map);
  }

  Future<Map<String,dynamic>> update(String id,Map<String,dynamic> data) async {
    final r=await http.patch(Uri.parse('$apiBase/users/$id'),headers:_headers,body:jsonEncode(data));
    if(r.statusCode!=200) throw Exception(_error(r));
    return Map<String,dynamic>.from((jsonDecode(r.body) as Map)['user'] as Map);
  }

  Future<void> setStatus(String id,bool active) async {
    final r=await http.patch(Uri.parse('$apiBase/users/$id/status'),headers:_headers,body:jsonEncode({'isActive':active}));
    if(r.statusCode!=200) throw Exception(_error(r));
  }

  String _error(http.Response r){
    try { final b=jsonDecode(r.body); return b['error']?['message']?.toString() ?? 'Request failed.'; }
    catch(_){ return 'Unable to connect to WMS server.'; }
  }
}
