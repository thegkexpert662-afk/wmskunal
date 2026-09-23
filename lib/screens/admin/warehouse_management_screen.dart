import 'package:flutter/material.dart';
import '../../services/warehouse_service.dart';

class AdminWarehouseManagementScreen extends StatefulWidget {
  const AdminWarehouseManagementScreen({super.key});
  @override State<AdminWarehouseManagementScreen> createState() => _AdminWarehouseManagementScreenState();
}
class _AdminWarehouseManagementScreenState extends State<AdminWarehouseManagementScreen> {
  final api = WarehouseService.instance;
  List<Map<String,dynamic>> warehouses=[]; List<Map<String,dynamic>> locations=[];
  String? selectedWarehouseId; bool loading=true; String? error;
  @override void initState(){super.initState(); load();}
  Future<void> load() async {
    setState(()=>loading=true);
    try { final data=await api.getWarehouses(); if(!mounted)return; setState(()=>{warehouses=data, selectedWarehouseId=data.any((w)=>w['id'].toString()==selectedWarehouseId)?selectedWarehouseId:(data.isNotEmpty?data.first['id'].toString():null)}); await loadLocations(); }
    catch(e){if(mounted)setState(()=>error=e.toString().replaceFirst('Exception: ',''));} finally{if(mounted)setState(()=>loading=false);}
  }
  Future<void> loadLocations() async { if(selectedWarehouseId==null){setState(()=>locations=[]);return;} try{final d=await api.getLocations(selectedWarehouseId!);if(mounted)setState(()=>locations=d);}catch(e){if(mounted)setState(()=>error=e.toString().replaceFirst('Exception: ',''));}}
  void msg(String s)=>ScaffoldMessenger.of(context).showSnackBar(SnackBar(content:Text(s)));
  Future<void> warehouseDialog({Map<String,dynamic>? item}) async {
    final code=TextEditingController(text:item?['code']?.toString()??''); final name=TextEditingController(text:item?['name']?.toString()??''); final address=TextEditingController(text:item?['address']?.toString()??''); final key=GlobalKey<FormState>();
    final ok=await showDialog<bool>(context:context,builder:(ctx)=>AlertDialog(title:Text(item==null?'Add Warehouse':'Edit Warehouse'),content:SizedBox(width:520,child:Form(key:key,child:Column(mainAxisSize:MainAxisSize.min,children:[
      TextFormField(controller:code,decoration:const InputDecoration(labelText:'Warehouse Code',border:OutlineInputBorder()),validator:(v)=>v==null||v.trim().length<2?'Enter a valid warehouse code':null),
      const SizedBox(height:12),TextFormField(controller:name,decoration:const InputDecoration(labelText:'Warehouse Name',border:OutlineInputBorder()),validator:(v)=>v==null||v.trim().length<2?'Enter warehouse name':null),
      const SizedBox(height:12),TextFormField(controller:address,maxLines:3,decoration:const InputDecoration(labelText:'Address',border:OutlineInputBorder())),
    ]))),actions:[TextButton(onPressed:()=>Navigator.pop(ctx,false),child:const Text('Cancel')),FilledButton(onPressed:()async{if(!key.currentState!.validate())return;try{if(item==null){await api.createWarehouse(code:code.text.trim(),name:name.text.trim(),address:address.text.trim().isEmpty?null:address.text.trim());}else{await api.updateWarehouse(item['id'].toString(),code:code.text.trim(),name:name.text.trim(),address:address.text.trim());}if(ctx.mounted)Navigator.pop(ctx,true);}catch(e){if(ctx.mounted)ScaffoldMessenger.of(ctx).showSnackBar(SnackBar(content:Text(e.toString().replaceFirst('Exception: ',''))));}},child:Text(item==null?'Create Warehouse':'Save Changes'))]));
    code.dispose();name.dispose();address.dispose();if(ok==true){await load();msg(item==null?'Warehouse created.':'Warehouse updated.');}
  }
  Future<void> locationDialog({Map<String,dynamic>? item}) async {
    if(selectedWarehouseId==null){msg('Select a warehouse first.');return;}
    final code=TextEditingController(text:item?['code']?.toString()??'');final zone=TextEditingController(text:item?['zone']?.toString()??'');final bin=TextEditingController(text:item?['bin']?.toString()??'');final key=GlobalKey<FormState>();
    final ok=await showDialog<bool>(context:context,builder:(ctx)=>AlertDialog(title:Text(item==null?'Add Location':'Edit Location'),content:SizedBox(width:520,child:Form(key:key,child:Column(mainAxisSize:MainAxisSize.min,children:[
      TextFormField(controller:code,decoration:const InputDecoration(labelText:'Location Code',border:OutlineInputBorder()),validator:(v)=>v==null||v.trim().isEmpty?'Enter location code':null),const SizedBox(height:12),
      TextFormField(controller:zone,decoration:const InputDecoration(labelText:'Zone',border:OutlineInputBorder())),const SizedBox(height:12),TextFormField(controller:bin,decoration:const InputDecoration(labelText:'Bin',border:OutlineInputBorder())),
    ]))),actions:[TextButton(onPressed:()=>Navigator.pop(ctx,false),child:const Text('Cancel')),FilledButton(onPressed:()async{if(!key.currentState!.validate())return;try{if(item==null){await api.createLocation(selectedWarehouseId!,code:code.text.trim(),zone:zone.text.trim().isEmpty?null:zone.text.trim(),bin:bin.text.trim().isEmpty?null:bin.text.trim());}else{await api.updateLocation(selectedWarehouseId!,item['id'].toString(),code:code.text.trim(),zone:zone.text.trim(),bin:bin.text.trim());}if(ctx.mounted)Navigator.pop(ctx,true);}catch(e){if(ctx.mounted)ScaffoldMessenger.of(ctx).showSnackBar(SnackBar(content:Text(e.toString().replaceFirst('Exception: ',''))));}},child:Text(item==null?'Create Location':'Save Changes'))]));
    code.dispose();zone.dispose();bin.dispose();if(ok==true){await loadLocations();await load();msg(item==null?'Location created.':'Location updated.');}
  }
  Future<void> toggleWarehouse(Map<String,dynamic>w)async{try{await api.setWarehouseStatus(w['id'].toString(),w['is_active']!=true);await load();}catch(e){msg(e.toString().replaceFirst('Exception: ',''));}}
  Future<void> toggleLocation(Map<String,dynamic>l)async{try{await api.setLocationStatus(selectedWarehouseId!,l['id'].toString(),l['is_active']!=true);await loadLocations();await load();}catch(e){msg(e.toString().replaceFirst('Exception: ',''));}}
  @override Widget build(BuildContext context){
    final selected=warehouses.where((w)=>w['id'].toString()==selectedWarehouseId).isEmpty?null:warehouses.firstWhere((w)=>w['id'].toString()==selectedWarehouseId);
    return Scaffold(backgroundColor:const Color(0xFFF5F8FC),body:Padding(padding:const EdgeInsets.all(24),child:Column(crossAxisAlignment:CrossAxisAlignment.start,children:[
      Row(children:[const Expanded(child:Column(crossAxisAlignment:CrossAxisAlignment.start,children:[Text('Warehouse Management',style:TextStyle(fontSize:28,fontWeight:FontWeight.w800)),SizedBox(height:5),Text('Manage warehouses, locations and operational status.')])) ,OutlinedButton.icon(onPressed:load,icon:const Icon(Icons.refresh),label:const Text('Refresh')),const SizedBox(width:10),FilledButton.icon(onPressed:()=>warehouseDialog(),icon:const Icon(Icons.add_business),label:const Text('Add Warehouse'))]),
      const SizedBox(height:18),if(error!=null)Container(width:double.infinity,padding:const EdgeInsets.all(12),color:Colors.red.shade50,child:Row(children:[const Icon(Icons.error_outline,color:Colors.red),const SizedBox(width:8),Expanded(child:Text(error!)),TextButton(onPressed:load,child:const Text('Retry'))])),const SizedBox(height:12),
      Expanded(child:loading?const Center(child:CircularProgressIndicator()):Row(crossAxisAlignment:CrossAxisAlignment.start,children:[
        Expanded(child:Card(child:Padding(padding:const EdgeInsets.all(16),child:Column(children:[Row(children:[const Text('Warehouses',style:TextStyle(fontSize:18,fontWeight:FontWeight.w700)),const Spacer(),Text(warehouses.length.toString())]),const Divider(),Expanded(child:warehouses.isEmpty?const Center(child:Text('No warehouses found.')):ListView.separated(itemCount:warehouses.length,separatorBuilder:(_,__)=>const Divider(height:1),itemBuilder:(_,i){final w=warehouses[i];final active=w['is_active']==true;final sel=w['id'].toString()==selectedWarehouseId;return ListTile(selected:sel,selectedTileColor:const Color(0xFFEAF3FF),onTap:()async{setState(()=>selectedWarehouseId=w['id'].toString());await loadLocations();},title:Text(w['name']?.toString()??'-'),subtitle:Text((w['code']?.toString()??'-')+' • '+(w['location_count']?.toString()??'0')+' locations'),trailing:Wrap(spacing:2,children:[IconButton(tooltip:'Edit',onPressed:()=>warehouseDialog(item:w),icon:const Icon(Icons.edit_outlined)),IconButton(tooltip:active?'Deactivate':'Activate',onPressed:()=>toggleWarehouse(w),icon:Icon(active?Icons.toggle_on:Icons.toggle_off,color:active?Colors.green:Colors.grey))]));}))])))),
        const SizedBox(width:16),Expanded(flex:2,child:Card(child:Padding(padding:const EdgeInsets.all(16),child:Column(children:[Row(children:[Expanded(child:Text(selected==null?'Locations':'Locations — '+selected['name'].toString(),style:const TextStyle(fontSize:18,fontWeight:FontWeight.w700))),FilledButton.icon(onPressed:selected==null||selected['is_active']!=true?null:()=>locationDialog(),icon:const Icon(Icons.add_location_alt_outlined),label:const Text('Add Location'))]),const Divider(),Expanded(child:selected==null?const Center(child:Text('Select a warehouse.')):locations.isEmpty?const Center(child:Text('No locations found.')):ListView.separated(itemCount:locations.length,separatorBuilder:(_,__)=>const Divider(height:1),itemBuilder:(_,i){final l=locations[i];final active=l['is_active']==true;return ListTile(leading:const Icon(Icons.location_on_outlined),title:Text(l['code']?.toString()??'-'),subtitle:Text('Zone: '+(l['zone']?.toString()??'-')+' • Bin: '+(l['bin']?.toString()??'-')),trailing:Wrap(spacing:2,children:[IconButton(tooltip:'Edit',onPressed:()=>locationDialog(item:l),icon:const Icon(Icons.edit_outlined)),IconButton(tooltip:active?'Deactivate':'Activate',onPressed:()=>toggleLocation(l),icon:Icon(active?Icons.toggle_on:Icons.toggle_off,color:active?Colors.green:Colors.grey))]));}))])))),
      ])),
    ])));
  }
}