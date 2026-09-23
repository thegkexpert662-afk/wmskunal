import 'dart:convert';
import 'package:http/http.dart' as http;
import 'auth_service.dart';

class InventoryService {
  InventoryService._();
  static final InventoryService instance=InventoryService._();
  static const String _baseUrl=String.fromEnvironment('WMS_API_BASE_URL',defaultValue:'http://localhost:4000/api');
  Map<String,String> _headers(){final t=AuthService.instance.session?.accessToken;if(t==null||t.isEmpty)throw Exception('Please login again.');return {'Content-Type':'application/json','Authorization':'Bearer '+t};}
  String _message(dynamic body)=>body is Map&&body['error'] is Map?(body['error']['message']??'Request failed.').toString():'Request failed.';
  Future<List<Map<String,dynamic>>> getInventory({String? warehouseId,String? productId})async{final q=<String>[];if(warehouseId!=null)q.add('warehouseId='+Uri.encodeQueryComponent(warehouseId));if(productId!=null)q.add('productId='+Uri.encodeQueryComponent(productId));final r=await http.get(Uri.parse(_baseUrl+'/inventory'+(q.isEmpty?'':'?'+q.join('&'))),headers:_headers());final b=jsonDecode(r.body);if(r.statusCode!=200)throw Exception(_message(b));return (b['data'] as List? ?? []).map((e)=>Map<String,dynamic>.from(e)).toList();}
  Future<List<Map<String,dynamic>>> transactions({String? warehouseId})async{final url=warehouseId==null?_baseUrl+'/inventory/transactions':_baseUrl+'/inventory/transactions?warehouseId='+Uri.encodeQueryComponent(warehouseId);final r=await http.get(Uri.parse(url),headers:_headers());final b=jsonDecode(r.body);if(r.statusCode!=200)throw Exception(_message(b));return (b['data'] as List? ?? []).map((e)=>Map<String,dynamic>.from(e)).toList();}
  Future<void> adjust({required String productId,required String warehouseId,String? locationId,required double quantity,String? remarks})async{final r=await http.post(Uri.parse(_baseUrl+'/inventory/adjust'),headers:_headers(),body:jsonEncode({'productId':productId,'warehouseId':warehouseId,'locationId':locationId,'quantity':quantity,'remarks':remarks}));final b=jsonDecode(r.body);if(r.statusCode!=201)throw Exception(_message(b));}
}