import 'package:flutter/material.dart';
import '../../services/stock_transfer_service.dart';
import '../../services/warehouse_service.dart';
import '../../services/product_service.dart';
import '../common_widgets.dart';

class AdminStockTransferScreen extends StatefulWidget {
  const AdminStockTransferScreen({super.key});
  @override State<AdminStockTransferScreen> createState() => _AdminStockTransferScreenState();
}

class _AdminStockTransferScreenState extends State<AdminStockTransferScreen> {
  final api = StockTransferService.instance;
  final warehouseApi = WarehouseService.instance;
  final productApi = ProductService.instance;
  List<Map<String,dynamic>> rows = [], warehouses = [], products = [];
  bool loading = true;
  String? error;

  @override void initState() { super.initState(); _load(); }
  Future<void> _load() async {
    setState(() => loading = true);
    try {
      final d = await Future.wait([api.list(), warehouseApi.getWarehouses(), productApi.getProducts()]);
      if (!mounted) return;
      setState(() { rows=d[0]; warehouses=d[1].where((x)=>x['is_active']==true).toList(); products=d[2].where((x)=>x['is_active']==true).toList(); error=null; });
    } catch(e) { if(mounted) setState(()=>error=e.toString().replaceFirst('Exception: ','')); }
    finally { if(mounted) setState(()=>loading=false); }
  }

  @override Widget build(BuildContext context) => ScreenFrame(
    title:'Stock Transfer / STO',
    subtitle:'Controlled movement of stock between warehouses with approval, picking and receiving.',
    actions:[
      OutlinedButton.icon(onPressed:loading?null:_load,icon:const Icon(Icons.refresh),label:const Text('Refresh')),
      const SizedBox(width:8),
      FilledButton.icon(onPressed:warehouses.length>=2 && products.isNotEmpty ? _newSto : null,icon:const Icon(Icons.add),label:const Text('New STO')),
    ],
    child: loading ? const Center(child:CircularProgressIndicator()) : error!=null ? _error() : Column(crossAxisAlignment:CrossAxisAlignment.stretch,children:[_cards(),const SizedBox(height:16),_table()]),
  );

  Widget _cards()=>Wrap(spacing:12,runSpacing:12,children:[
    _card('Total',rows.length), _card('Pending Approval',rows.where((x)=>x['status']=='pending_approval').length),
    _card('Picking',rows.where((x)=>x['status']=='picking').length), _card('In Transit',rows.where((x)=>x['status']=='in_transit').length),
    _card('Received',rows.where((x)=>x['status']=='received').length),
  ]);
  Widget _card(String t,num n)=>Container(width:175,padding:const EdgeInsets.all(15),decoration:_box(),child:Column(crossAxisAlignment:CrossAxisAlignment.start,children:[Text(t,style:const TextStyle(fontSize:11,fontWeight:FontWeight.w700)),const SizedBox(height:5),Text(n.toString(),style:const TextStyle(fontSize:23,fontWeight:FontWeight.w900))]));
  Widget _table()=>Container(padding:const EdgeInsets.all(14),decoration:_box(),child:HorizontalTableScroller(child:DataTable(
    columns:const[DataColumn(label:Text('STO No.')),DataColumn(label:Text('Source')),DataColumn(label:Text('Destination')),DataColumn(label:Text('Status')),DataColumn(label:Text('Created')),DataColumn(label:Text('Action'))],
    rows:rows.map((x)=>DataRow(cells:[
      DataCell(Text(x['sto_no']?.toString()??'-')),DataCell(Text(x['source_warehouse_code']?.toString()??'-')),DataCell(Text(x['destination_warehouse_code']?.toString()??'-')),
      DataCell(Chip(label:Text((x['status']?.toString()??'-').replaceAll('_',' ').toUpperCase()),visualDensity:VisualDensity.compact)),
      DataCell(Text(_date(x['created_at']))),DataCell(FilledButton.tonal(onPressed:()=>_detail(x['id'].toString()),child:const Text('Open'))),
    ])).toList(),
  )));

  Future<void> _newSto() async {
    String? src=warehouses.first['id']?.toString(), dst=warehouses[1]['id']?.toString(), product=products.first['id']?.toString();
    final no=TextEditingController(text:'STO-'+DateTime.now().millisecondsSinceEpoch.toString());
    final qty=TextEditingController(text:'1'); final remarks=TextEditingController();
    final ok=await showDialog<bool>(context:context,builder:(ctx)=>StatefulBuilder(builder:(ctx,setLocal)=>AlertDialog(
      title:const Text('Create Stock Transfer'),
      content:SizedBox(width:560,child:SingleChildScrollView(child:Column(mainAxisSize:MainAxisSize.min,children:[
        _field(no,'STO Number *'),const SizedBox(height:10),_warehouse('Source Warehouse *',src,(v)=>setLocal(()=>src=v)),const SizedBox(height:10),_warehouse('Destination Warehouse *',dst,(v)=>setLocal(()=>dst=v)),
        const SizedBox(height:10),DropdownButtonFormField<String>(value:product,decoration:const InputDecoration(labelText:'Product *',border:OutlineInputBorder()),items:products.map((p)=>DropdownMenuItem(value:p['id'].toString(),child:Text(p['sku'].toString()+' - '+p['name'].toString()))).toList(),onChanged:(v)=>setLocal(()=>product=v)),
        const SizedBox(height:10),_field(qty,'Requested Quantity *',decimal:true),const SizedBox(height:10),_field(remarks,'Remarks'),
      ]))),
      actions:[TextButton(onPressed:()=>Navigator.pop(ctx),child:const Text('Cancel')),FilledButton(onPressed:()async{
        final q=double.tryParse(qty.text.trim());
        if(src==null||dst==null||product==null||src==dst||q==null||q<=0||no.text.trim().isEmpty){ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content:Text('Select different warehouses and enter a valid quantity.')));return;}
        try{await api.create(stoNo:no.text.trim(),sourceWarehouseId:src!,destinationWarehouseId:dst!,items:[{'productId':product!,'requestedQty':q}],remarks:remarks.text.trim().isEmpty?null:remarks.text.trim());if(ctx.mounted)Navigator.pop(ctx,true);}
        catch(e){if(ctx.mounted)ScaffoldMessenger.of(ctx).showSnackBar(SnackBar(content:Text(e.toString().replaceFirst('Exception: ',''))));}
      },child:const Text('Create'))],
    )));
    no.dispose();qty.dispose();remarks.dispose();if(ok==true){await _load();_msg('STO created.');}
  }

  Widget _warehouse(String label,String? value,ValueChanged<String?> onChanged)=>DropdownButtonFormField<String>(
    value:warehouses.any((w)=>w['id'].toString()==value)?value:null,decoration:InputDecoration(labelText:label,border:const OutlineInputBorder()),
    items:warehouses.map((w)=>DropdownMenuItem(value:w['id'].toString(),child:Text(w['code'].toString()+' - '+w['name'].toString()))).toList(),onChanged:onChanged);
  Widget _field(TextEditingController c,String label,{bool decimal=false})=>TextField(controller:c,keyboardType:decimal?const TextInputType.numberWithOptions(decimal:true):null,decoration:InputDecoration(labelText:label,border:const OutlineInputBorder()));

  Future<void> _detail(String id) async {
    try{final d=await api.detail(id);if(!mounted)return;await showDialog(context:context,builder:(_)=>_Detail(detail:d,api:api,warehouseApi:warehouseApi,onChanged:_load));}
    catch(e){_msg(e.toString().replaceFirst('Exception: ',''));}
  }
  Widget _error()=>Center(child:Column(mainAxisSize:MainAxisSize.min,children:[Text(error!,textAlign:TextAlign.center),const SizedBox(height:10),FilledButton(onPressed:_load,child:const Text('Retry'))]));
  String _date(dynamic v){final d=DateTime.tryParse(v?.toString()??'');return d==null?'—':d.day.toString().padLeft(2,'0')+'-'+d.month.toString().padLeft(2,'0')+'-'+d.year.toString();}
  BoxDecoration _box()=>BoxDecoration(color:Colors.white,borderRadius:BorderRadius.circular(12),border:Border.all(color:const Color(0xFFE1E8F1)));
  void _msg(String s)=>ScaffoldMessenger.of(context).showSnackBar(SnackBar(content:Text(s)));
}

class _Detail extends StatefulWidget {
  final Map<String,dynamic> detail; final StockTransferService api; final WarehouseService warehouseApi; final Future<void> Function() onChanged;
  const _Detail({required this.detail,required this.api,required this.warehouseApi,required this.onChanged});
  @override State<_Detail> createState()=>_DetailState();
}
class _DetailState extends State<_Detail> {
  bool busy=false;
  List<Map<String,dynamic>> get items=>(widget.detail['items'] as List? ?? []).map((e)=>Map<String,dynamic>.from(e as Map)).toList();
  Future<void> _approve()async=>_run(()=>widget.api.approve(widget.detail['id'].toString()),'STO approved.');
  Future<void> _move(Map<String,dynamic> item,bool pick)async{
    final wid=(pick?widget.detail['source_warehouse_id']:widget.detail['destination_warehouse_id'])?.toString();if(wid==null)return;
    try{final locs=(await widget.warehouseApi.getLocations(wid)).where((x)=>x['is_active']==true).toList();if(locs.isEmpty){_msg('No active locations found.');return;}
      final picked=double.tryParse(item['picked_qty'].toString())??0,received=double.tryParse(item['received_qty'].toString())??0,requested=double.tryParse(item['requested_qty'].toString())??0;
      final max=pick?requested-picked:picked-received;if(max<=0){_msg(pick?'Item is fully picked.':'Nothing is pending for receipt.');return;}
      String? location=locs.first['id']?.toString();final qty=TextEditingController(text:max.toString());final remarks=TextEditingController();
      final ok=await showDialog<bool>(context:context,builder:(ctx)=>StatefulBuilder(builder:(ctx,setLocal)=>AlertDialog(
        title:Text(pick?'Pick Stock':'Receive Stock'),content:SizedBox(width:500,child:Column(mainAxisSize:MainAxisSize.min,children:[
          Text(item['sku'].toString()+' - '+item['product_name'].toString()),const SizedBox(height:10),
          DropdownButtonFormField<String>(value:location,decoration:InputDecoration(labelText:pick?'Source Location *':'Destination Location *',border:const OutlineInputBorder()),items:locs.map((l)=>DropdownMenuItem(value:l['id'].toString(),child:Text(l['code'].toString()))).toList(),onChanged:(v)=>setLocal(()=>location=v)),
          const SizedBox(height:10),TextField(controller:qty,keyboardType:const TextInputType.numberWithOptions(decimal:true),decoration:InputDecoration(labelText:'Quantity (max '+max.toString()+')',border:const OutlineInputBorder())),
          if(!pick) ...[const SizedBox(height:10),TextField(controller:remarks,decoration:const InputDecoration(labelText:'Remarks',border:OutlineInputBorder()))],
        ])),
        actions:[TextButton(onPressed:()=>Navigator.pop(ctx),child:const Text('Cancel')),FilledButton(onPressed:()async{final q=double.tryParse(qty.text.trim());if(location==null||q==null||q<=0||q>max){ScaffoldMessenger.of(ctx).showSnackBar(const SnackBar(content:Text('Enter a valid quantity.')));return;}
          try{if(pick){await widget.api.pick(widget.detail['id'].toString(),stoItemId:item['id'].toString(),sourceLocationId:location!,pickedQty:q);}else{await widget.api.receive(widget.detail['id'].toString(),stoItemId:item['id'].toString(),destinationLocationId:location!,receivedQty:q,remarks:remarks.text.trim().isEmpty?null:remarks.text.trim());}if(ctx.mounted)Navigator.pop(ctx,true);}
          catch(e){if(ctx.mounted)ScaffoldMessenger.of(ctx).showSnackBar(SnackBar(content:Text(e.toString().replaceFirst('Exception: ',''))));}
        },child:Text(pick?'Pick':'Receive'))],
      )));qty.dispose();remarks.dispose();if(ok==true){await widget.onChanged();if(mounted)Navigator.pop(context);}
    }catch(e){_msg(e.toString().replaceFirst('Exception: ',''));}
  }
  Future<void> _run(Future<dynamic> Function() fn,String success)async{setState(()=>busy=true);try{await fn();await widget.onChanged();if(mounted)Navigator.pop(context);}catch(e){_msg(e.toString().replaceFirst('Exception: ',''));}finally{if(mounted)setState(()=>busy=false);}}
  @override Widget build(BuildContext context){final status=widget.detail['status']?.toString()??'-';return AlertDialog(
    title:Text('STO '+(widget.detail['sto_no']?.toString()??'')),
    content:SizedBox(width:760,child:SingleChildScrollView(child:Column(crossAxisAlignment:CrossAxisAlignment.stretch,children:[
      Text((widget.detail['source_warehouse_code']?.toString()??'-')+' → '+(widget.detail['destination_warehouse_code']?.toString()??'-')),const SizedBox(height:10),Chip(label:Text(status.replaceAll('_',' ').toUpperCase())),
      ...items.map((item){final picked=double.tryParse(item['picked_qty'].toString())??0,received=double.tryParse(item['received_qty'].toString())??0,requested=double.tryParse(item['requested_qty'].toString())??0;return Card(child:ListTile(
        title:Text(item['sku'].toString()+' - '+item['product_name'].toString()),subtitle:Text('Requested: '+requested.toString()+' | Picked: '+picked.toString()+' | Received: '+received.toString()),
        trailing:Wrap(spacing:6,children:[if(status=='pending_approval'&&!busy)FilledButton.tonal(onPressed:_approve,child:const Text('Approve')),if((status=='approved'||status=='picking')&&!busy&&picked<requested)FilledButton.tonal(onPressed:()=>_move(item,true),child:const Text('Pick')),if((status=='in_transit'||status=='partially_received')&&!busy&&received<picked)FilledButton.tonal(onPressed:()=>_move(item,false),child:const Text('Receive'))]),
      ));}),
    ]))),actions:[TextButton(onPressed:busy?null:()=>Navigator.pop(context),child:const Text('Close'))],);}
  void _msg(String s)=>ScaffoldMessenger.of(context).showSnackBar(SnackBar(content:Text(s)));
}