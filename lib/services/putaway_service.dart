import 'dart:convert';
import 'package:http/http.dart' as http;
import 'auth_service.dart';

class PutawayService {
  PutawayService._();
  static final instance=PutawayService._();
  static const base=String.fromEnvironment('WMS_API_BASE_URL',defaultValue:'http://localhost:4000/api');
  Map<String,String> get headers{
    final t=AuthService.instance.session?.accessToken;
    if(t==null||t.isEmpty)throw Exception('Please login again.');
    return {'Content-Type':'application/json','Authorization':'Bearer $t'};
  }
  Future<List<Map<String,dynamic>>> pending()async{
    final r=await http.get(Uri.parse('$base/putaway/pending'),headers:headers);
    if(r.statusCode!=200)throw Exception(_err(r));
    return ((jsonDecode(r.body) as Map)['items'] as List? ?? []).map((e)=>Map<String,dynamic>.from(e as Map)).toList();
  }
  Future<List<Map<String,dynamic>>> tasks()async{
    final r=await http.get(Uri.parse('$base/putaway'),headers:headers);
    if(r.statusCode!=200)throw Exception(_err(r));
    return ((jsonDecode(r.body) as Map)['tasks'] as List???[]).map((e)=>Map<String,dynamic>.from(e as Map)).toList();
  }
  Future<Map<String,dynamic>> create({required String sourceType,required String sourceItemId,required String locationId})async{
    final r=await http.post(Uri.parse('$base/putaway'),headers:headers,body:jsonEncode({'sourceType':sourceType,'sourceItemId':sourceItemId,'locationId':locationId,'quantity':quantity}));
    if(r.statusCode!=201)throw Exception(_err(r));
    return Map<String,dynamic>.from((jsonDecode(r.body) as Map)['task'] as Map);
  }
  Future<void> process(String id,String locationId)async{
    final r=await http.post(Uri.parse('$base/putaway/$id/process'),headers:headers,body:jsonEncode({'locationId':locationId}));
    if(r.statusCode!=200)throw Exception(_err(r));
  }
  String _err(http.Response r){try{final b=jsonDecode(r.body) as Map;return b['error']?['message']?.toString()??'Request failed.';}catch(_){return 'Unable to connect to WMS server.';}}
}
