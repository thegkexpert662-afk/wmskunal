import 'package:flutter/material.dart';
import '../common_widgets.dart';
import '../../services/order_service.dart';
import '../../services/warehouse_service.dart';
import '../../services/product_service.dart';

class AdminOrdersScreen extends StatefulWidget {
  const AdminOrdersScreen({super.key});
  @override State<AdminOrdersScreen> createState() => _AdminOrdersScreenState();
}

class _AdminOrdersScreenState extends State<AdminOrdersScreen> {
  final api=OrderService.instance;
  final warehouseApi=WarehouseService.instance;
  final productApi=ProductService.instance;
  final search=TextEditingController();
  List<Map<String,dynamic>> orders=[],clients=[],warehouses=[],products=[];
  String status='All',client='All',error='';
  bool loading=true;

  @override void initState(){super.initState();search.addListener(_loadSearch);_load();}
  void _loadSearch(){if(mounted)setState((){});}
  Future<void> _load() async{
    if(mounted)setState(()=>loading=true);
    try{
      final r=await Future.wait([api.list(status:status,search:search.text),warehouseApi.getWarehouses(),productApi.getProducts(),api.clients()]);
      if(!mounted)return;
      setState((){orders=r[0];warehouses=r[1].where((x)=>x['is_active']==true).toList();products=r[2].where((x)=>x['is_active']==true).toList();clients=r[3].where((x)=>x['is_active']==true).toList();error='';});
    }catch(e){
      try{final o=await api.list(status:status,search:search.text);if(mounted)setState((){orders=o;error='';});}
      catch(e2){if(mounted)setState(()=>error=e2.toString().replaceFirst('Exception: ',''));}
    }finally{if(mounted)setState(()=>loading=false);}
  }
  @override void dispose(){search.dispose();super.dispose();}

  @override Widget build(BuildContext context){
    final canCreate=clients.isNotEmpty&&warehouses.isNotEmpty&&products.isNotEmpty;
    return ScreenFrame(title:'Orders',subtitle:'Manage client orders from acceptance through dispatch.',actions:[
      OutlinedButton.icon(onPressed:loading?null:_load,icon:const Icon(Icons.refresh),label:const Text('Refresh')),
      const SizedBox(width:8),FilledButton.icon(onPressed:canCreate?_newOrder:null,icon:const Icon(Icons.add),label:const Text('New Order')),
    ],child:loading?const Center(child:CircularProgressIndicator()):error.isNotEmpty?_error():Column(children:[_cards(),const SizedBox(height:16),_table()]));
  }

  Widget _cards()=>Wrap(spacing:12,runSpacing:12,children:[
    _card('Total',orders.length),_card('Draft',_count('draft')),_card('Confirmed',_count('confirmed')),
    _card('Picking',_count('picking')),_card('Dispatched',_count('dispatched')),
  ]);
  int _count(String s)=>orders.where((x)=>x['status']==s).length;
  Widget _card(String t,num n)=>Container(width:175,padding:const EdgeInsets.all(15),decoration:_box(),child:Column(crossAxisAlignment:CrossAxisAlignment.start,children:[Text(t,style:const TextStyle(fontSize:11,fontWeight:FontWeight.w700)),const SizedBox(height:5),Text(n.toString(),style:const TextStyle(fontSize:23,fontWeight:FontWeight.w900))]));

  Widget _table()=>_panel('Client Orders',Column(children:[
    Padding(padding:const EdgeInsets.all(10),child:Wrap(spacing:8,runSpacing:8,children:[
      SizedBox(width:300,height:40,child:TextField(controller:search,decoration:const InputDecoration(hintText:'Search order ID, client...',prefixIcon:Icon(Icons.search),border:OutlineInputBorder()))),
      _drop(client,['All',...clients.map((x)=>x['name'].toString())],(v)=>setState(()=>client=v!),'Client'),
      _drop(status,const ['All','draft','confirmed','allocated','picking','packed','dispatched','delivered','cancelled'],(v)async{setState(()=>status=v!);await _load();},'Status'),
    ])),
    const Divider(height:1),
    if(_filtered.isEmpty)const Padding(padding:EdgeInsets.all(30),child:Text('No orders found.')) else HorizontalTableScroller(child:DataTable(
      headingRowColor:const WidgetStatePropertyAll(Color(0xFFF4F8FC)),
      columns:const[DataColumn(label:Text('#')),DataColumn(label:Text('Order ID')),DataColumn(label:Text('Client')),DataColumn(label:Text('Warehouse')),DataColumn(label:Text('Items')),DataColumn(label:Text('Qty')),DataColumn(label:Text('Required')),DataColumn(label:Text('Status')),DataColumn(label:Text('Action'))],
      rows:List.generate(_filtered.length,(i){final x=_filtered[i];return DataRow(cells:[
        DataCell(Text('${i+1}')),DataCell(Text(x['order_no'].toString())),DataCell(Text(x['client_name'].toString())),
        DataCell(Text(x['warehouse_code'].toString())),DataCell(Text(x['item_count'].toString())),DataCell(Text(x['total_qty'].toString())),
        DataCell(Text(_date(x['required_date']))),DataCell(_chip(x['status'].toString())),
        DataCell(IconButton(onPressed:()=>_detail(x['id'].toString()),icon:const Icon(Icons.visibility_outlined,color:Color(0xFF1769E8)))),
      ]);}),
    )),
    const Divider(height:1),Padding(padding:const EdgeInsets.all(10),child:Text('Showing ${_filtered.length} order(s)',style:const TextStyle(fontSize:10,color:Color(0xFF718096)))),
  ]));

  List<Map<String,dynamic>> get _filtered=>client=='All'?orders:orders.where((x)=>x['client_name']==client).toList();

  Widget _drop(String value,List<String> values,ValueChanged<String?> cb,String label)=>Container(height:40,width:165,padding:const EdgeInsets.symmetric(horizontal:9),decoration:BoxDecoration(border:Border.all(color:const Color(0xFFDCE4EE)),borderRadius:BorderRadius.circular(8)),child:DropdownButtonHideUnderline(child:DropdownButton<String>(
    value:values.contains(value)?value:values.first,isExpanded:true,items:values.map((v)=>DropdownMenuItem(value:v,child:Text(v=='All'?'${label}: All':v))).toList(),onChanged:cb,
  )));

  Future<void> _newOrder() async {
    String? cid = clients.first['id'].toString();
    String? wid = warehouses.first['id'].toString();
    String? pid = products.first['id'].toString();

    final no = TextEditingController(text: 'ORD-${DateTime.now().millisecondsSinceEpoch}');
    final qty = TextEditingController(text: '1');
    final date = TextEditingController();
    final truck = TextEditingController();
    final transporter = TextEditingController();
    final vehicle = TextEditingController();
    final driver = TextEditingController();
    final driverMobile = TextEditingController();
    final shipment = TextEditingController();
    final shipmentDate = TextEditingController();
    final delivery = TextEditingController();
    final deliveryDate = TextEditingController();
    final soldBy = TextEditingController();
    final soldByAddress = TextEditingController();
    final soldByGstin = TextEditingController();
    final soldTo = TextEditingController();
    final soldToAddress = TextEditingController();
    final soldToGstin = TextEditingController();
    final shipTo = TextEditingController();
    final shipToAddress = TextEditingController();
    final shipToGstin = TextEditingController();

    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setLocal) => AlertDialog(
          title: const Text('Create Client Order'),
          content: SizedBox(
            width: 820,
            height: 650,
            child: SingleChildScrollView(
              child: Column(
                children: [
                  _field(no, 'Order Number *'),
                  const SizedBox(height: 10),
                  _select('Client *', cid, clients, (x) => x['name'].toString(), (v) => setLocal(() => cid = v)),
                  const SizedBox(height: 10),
                  _select('Warehouse *', wid, warehouses, (x) => '${x['code']} - ${x['name']}', (v) => setLocal(() => wid = v)),
                  const SizedBox(height: 10),
                  _select('Product *', pid, products, (x) => '${x['sku']} - ${x['name']}', (v) => setLocal(() => pid = v)),
                  const SizedBox(height: 10),
                  _field(qty, 'Ordered Quantity *', decimal: true),
                  const SizedBox(height: 10),
                  _field(date, 'Required Date (YYYY-MM-DD)'),

                  const SizedBox(height: 18),
                  const Align(
                    alignment: Alignment.centerLeft,
                    child: Text('Shipment / Vehicle Information', style: TextStyle(fontWeight: FontWeight.w900)),
                  ),
                  const SizedBox(height: 8),
                  Row(children: [
                    Expanded(child: _field(truck, 'Truck Type')),
                    const SizedBox(width: 8),
                    Expanded(child: _field(transporter, 'Transporter')),
                  ]),
                  const SizedBox(height: 8),
                  Row(children: [
                    Expanded(child: _field(vehicle, 'Vehicle No.')),
                    const SizedBox(width: 8),
                    Expanded(child: _field(driver, 'Driver Name')),
                    const SizedBox(width: 8),
                    Expanded(child: _field(driverMobile, 'Driver Mobile')),
                  ]),
                  const SizedBox(height: 8),
                  Row(children: [
                    Expanded(child: _field(shipment, 'Shipment No.')),
                    const SizedBox(width: 8),
                    Expanded(child: _field(shipmentDate, 'Shipment Date (YYYY-MM-DD)')),
                    const SizedBox(width: 8),
                    Expanded(child: _field(delivery, 'Delivery No.')),
                    const SizedBox(width: 8),
                    Expanded(child: _field(deliveryDate, 'Delivery Date (YYYY-MM-DD)')),
                  ]),

                  const SizedBox(height: 18),
                  const Align(
                    alignment: Alignment.centerLeft,
                    child: Text('Sold By / Sold To / Ship To', style: TextStyle(fontWeight: FontWeight.w900)),
                  ),
                  const SizedBox(height: 8),
                  Row(children: [
                    Expanded(child: _field(soldBy, 'Sold By Name')),
                    const SizedBox(width: 8),
                    Expanded(child: _field(soldByGstin, 'Sold By GSTIN')),
                  ]),
                  const SizedBox(height: 8),
                  _field(soldByAddress, 'Sold By Address'),
                  const SizedBox(height: 8),
                  Row(children: [
                    Expanded(child: _field(soldTo, 'Sold To Name')),
                    const SizedBox(width: 8),
                    Expanded(child: _field(soldToGstin, 'Sold To GSTIN')),
                  ]),
                  const SizedBox(height: 8),
                  _field(soldToAddress, 'Sold To Address'),
                  const SizedBox(height: 8),
                  Row(children: [
                    Expanded(child: _field(shipTo, 'Ship To Name')),
                    const SizedBox(width: 8),
                    Expanded(child: _field(shipToGstin, 'Ship To GSTIN')),
                  ]),
                  const SizedBox(height: 8),
                  _field(shipToAddress, 'Ship To Address'),
                ],
              ),
            ),
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
            FilledButton(
              onPressed: () async {
                final q = double.tryParse(qty.text);
                if (q == null || q <= 0) return;
                try {
                  await api.create(
                    orderNo: no.text.trim(),
                    clientId: cid!,
                    warehouseId: wid!,
                    requiredDate: date.text.trim().isEmpty ? null : date.text.trim(),
                    items: [{'productId': pid!, 'orderedQty': q}],
                    truckType: truck.text.trim().isEmpty ? null : truck.text.trim(),
                    transporterName: transporter.text.trim().isEmpty ? null : transporter.text.trim(),
                    vehicleNo: vehicle.text.trim().isEmpty ? null : vehicle.text.trim(),
                    driverName: driver.text.trim().isEmpty ? null : driver.text.trim(),
                    driverMobile: driverMobile.text.trim().isEmpty ? null : driverMobile.text.trim(),
                    shipmentNo: shipment.text.trim().isEmpty ? null : shipment.text.trim(),
                    shipmentDate: shipmentDate.text.trim().isEmpty ? null : shipmentDate.text.trim(),
                    deliveryNo: delivery.text.trim().isEmpty ? null : delivery.text.trim(),
                    deliveryDate: deliveryDate.text.trim().isEmpty ? null : deliveryDate.text.trim(),
                    soldByName: soldBy.text.trim().isEmpty ? null : soldBy.text.trim(),
                    soldByAddress: soldByAddress.text.trim().isEmpty ? null : soldByAddress.text.trim(),
                    soldByGstin: soldByGstin.text.trim().isEmpty ? null : soldByGstin.text.trim(),
                    soldToName: soldTo.text.trim().isEmpty ? null : soldTo.text.trim(),
                    soldToAddress: soldToAddress.text.trim().isEmpty ? null : soldToAddress.text.trim(),
                    soldToGstin: soldToGstin.text.trim().isEmpty ? null : soldToGstin.text.trim(),
                    shipToName: shipTo.text.trim().isEmpty ? null : shipTo.text.trim(),
                    shipToAddress: shipToAddress.text.trim().isEmpty ? null : shipToAddress.text.trim(),
                    shipToGstin: shipToGstin.text.trim().isEmpty ? null : shipToGstin.text.trim(),
                  );
                  if (ctx.mounted) Navigator.pop(ctx, true);
                } catch (e) {
                  if (ctx.mounted) {
                    ScaffoldMessenger.of(ctx).showSnackBar(
                      SnackBar(content: Text(e.toString().replaceFirst('Exception: ', ''))),
                    );
                  }
                }
              },
              child: const Text('Create Order'),
            ),
          ],
        ),
      ),
    );

    for (final controller in [
      no, qty, date, truck, transporter, vehicle, driver, driverMobile,
      shipment, shipmentDate, delivery, deliveryDate, soldBy, soldByAddress,
      soldByGstin, soldTo, soldToAddress, soldToGstin, shipTo, shipToAddress, shipToGstin,
    ]) {
      controller.dispose();
    }

    if (ok == true) {
      await _load();
      _msg('Order created successfully.');
    }
  }

  Widget _select(String label,String? value,List<Map<String,dynamic>> data,String Function(Map<String,dynamic>) text,ValueChanged<String?> cb)=>DropdownButtonFormField<String>(
    value:data.any((x)=>x['id'].toString()==value)?value:null,decoration:InputDecoration(labelText:label,border:const OutlineInputBorder()),
    items:data.map((x)=>DropdownMenuItem(value:x['id'].toString(),child:Text(text(x),overflow:TextOverflow.ellipsis))).toList(),onChanged:cb);
  Widget _field(TextEditingController c,String label,{bool decimal=false})=>TextField(controller:c,keyboardType:decimal?const TextInputType.numberWithOptions(decimal:true):null,decoration:InputDecoration(labelText:label,border:const OutlineInputBorder()));

  Future<void> _detail(String id)async{try{final d=await api.detail(id);if(!mounted)return;await showDialog(context:context,builder:(_)=>_OrderDialog(detail:d,api:api,onChanged:_load));}catch(e){_msg(e.toString().replaceFirst('Exception: ',''));}}
  Widget _error()=>Center(child:Column(mainAxisSize:MainAxisSize.min,children:[Text(error,textAlign:TextAlign.center),const SizedBox(height:10),FilledButton(onPressed:_load,child:const Text('Retry'))]));
  String _date(dynamic v){final d=DateTime.tryParse(v?.toString()??'');return d==null?'—':'${d.day.toString().padLeft(2,'0')}-${d.month.toString().padLeft(2,'0')}-${d.year}';}
  Widget _chip(String s)=>Chip(label:Text(s.replaceAll('_',' ').toUpperCase()),visualDensity:VisualDensity.compact);
  BoxDecoration _box()=>BoxDecoration(color:Colors.white,borderRadius:BorderRadius.circular(12),border:Border.all(color:const Color(0xFFE1E8F1)));
  Widget _panel(String t,Widget c)=>Container(padding:const EdgeInsets.all(15),decoration:_box(),child:Column(crossAxisAlignment:CrossAxisAlignment.start,children:[Text(t,style:const TextStyle(fontSize:14,fontWeight:FontWeight.w800)),const SizedBox(height:8),c]));
  void _msg(String s)=>ScaffoldMessenger.of(context).showSnackBar(SnackBar(content:Text(s)));
}

class _OrderDialog extends StatefulWidget{
  final Map<String,dynamic> detail;final OrderService api;final Future<void> Function() onChanged;
  const _OrderDialog({required this.detail,required this.api,required this.onChanged});
  @override State<_OrderDialog> createState()=>_OrderDialogState();
}
class _OrderDialogState extends State<_OrderDialog>{
  bool busy=false;
  final Map<String,List<String>> transitions={'draft':['confirmed','cancelled'],'confirmed':['allocated','cancelled'],'allocated':['picking','cancelled'],'picking':['packed'],'packed':['dispatched'],'dispatched':['delivered']};
  Future<void> _set(String s)async{setState(()=>busy=true);try{await widget.api.updateStatus(widget.detail['id'].toString(),s);await widget.onChanged();if(mounted)Navigator.pop(context);}catch(e){if(mounted)ScaffoldMessenger.of(context).showSnackBar(SnackBar(content:Text(e.toString().replaceFirst('Exception: ',''))));}finally{if(mounted)setState(()=>busy=false);}}
  @override Widget build(BuildContext context){
    final status=widget.detail['status'].toString();final items=(widget.detail['items'] as List? ?? []).map((e)=>Map<String,dynamic>.from(e as Map)).toList();
    return AlertDialog(title:Text('Order ${widget.detail['order_no']}'),content:SizedBox(width:700,child:SingleChildScrollView(child:Column(crossAxisAlignment:CrossAxisAlignment.stretch,children:[
      Text('Client: ${widget.detail['client_name']}  •  Warehouse: ${widget.detail['warehouse_code']}'),const SizedBox(height:8),_chip(status),const Divider(),
      ...items.map((x)=>ListTile(title:Text('${x['sku']} - ${x['product_name']}'),subtitle:Text('Ordered: ${x['ordered_qty']} | Picked: ${x['picked_qty']} | Dispatched: ${x['dispatched_qty']}'))),
      const SizedBox(height:8),if((transitions[status]??[]).isNotEmpty)Wrap(spacing:8,children:transitions[status]!.map((s)=>FilledButton.tonal(onPressed:busy?null:()=>_set(s),child:Text('Set ${s.toUpperCase()}'))).toList()),
    ]))),actions:[TextButton(onPressed:busy?null:()=>Navigator.pop(context),child:const Text('Close'))]);
  }
}
