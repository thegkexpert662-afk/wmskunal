import 'package:flutter/material.dart';
import '../../services/packing_service.dart';

class AdminPackingScreen extends StatefulWidget {
  const AdminPackingScreen({super.key});
  @override State<AdminPackingScreen> createState() => _AdminPackingScreenState();
}

class _AdminPackingScreenState extends State<AdminPackingScreen> {
  final api = PackingService.instance;
  bool loading = true;
  String? error;
  List<Map<String,dynamic>> pending = [];
  List<Map<String,dynamic>> tasks = [];

  @override void initState() { super.initState(); load(); }

  Future<void> load() async {
    setState(() { loading = true; error = null; });
    try {
      final r = await Future.wait([api.pending(), api.tasks()]);
      if (!mounted) return;
      setState(() { pending = r[0]; tasks = r[1]; loading = false; });
    } catch (e) {
      if (!mounted) return;
      setState(() { error = e.toString().replaceFirst('Exception: ', ''); loading = false; });
    }
  }

  void snack(String s, [bool bad=false]) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(s), backgroundColor: bad ? Colors.red.shade700 : null));
  }

  Future<void> start(Map<String,dynamic> o) async {
    try { await api.createTask(o['id'].toString()); snack('Packing task created.'); await load(); }
    catch(e) { snack(e.toString().replaceFirst('Exception: ', ''), true); }
  }

  Future<void> openTask(Map<String,dynamic> t) async {
    try {
      final d = await api.detail(t['id'].toString());
      if (!mounted) return;
      await showDialog(context: context, barrierDismissible: false, builder: (_) => PackingTaskDialog(api: api, initial: d));
      await load();
    } catch(e) { snack(e.toString().replaceFirst('Exception: ', ''), true); }
  }

  @override Widget build(BuildContext context) {
    final active = tasks.where((x) => x['status'] == 'in_progress').length;
    final ready = tasks.where((x) => x['status'] == 'ready').length;
    return Container(
      color: const Color(0xFFF5F7FB), padding: const EdgeInsets.all(22),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [
          const Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text('Packing', style: TextStyle(fontSize: 22, fontWeight: FontWeight.w900, color: Color(0xFF10243E))),
            SizedBox(height: 4),
            Text('Verify picked quantities, create packages and release orders to dispatch.', style: TextStyle(fontSize: 11, color: Color(0xFF718096))),
          ])),
          OutlinedButton.icon(onPressed: loading ? null : load, icon: const Icon(Icons.refresh, size: 17), label: const Text('Refresh')),
        ]),
        const SizedBox(height: 16),
        Row(children: [
          stat('Ready to Pack', pending.length, Icons.inventory_2_outlined),
          const SizedBox(width: 9), stat('Active', active, Icons.playlist_add_check_outlined),
          const SizedBox(width: 9), stat('Ready Dispatch', ready, Icons.local_shipping_outlined),
          const SizedBox(width: 9), stat('Packages', tasks.fold<int>(0, (a,x) => a + ((x['total_packages'] as num?)?.toInt() ?? 0)), Icons.all_inbox_outlined),
        ]),
        const SizedBox(height: 14),
        if (error != null) errorBox(),
        Expanded(child: loading ? const Center(child: CircularProgressIndicator()) : DefaultTabController(
          length: 2, child: Column(children: [
            const TabBar(tabs: [Tab(text: 'Ready to Pack'), Tab(text: 'Packing Tasks')]),
            const SizedBox(height: 8),
            Expanded(child: TabBarView(children: [pendingTable(), tasksTable()])),
          ]),
        )),
      ]),
    );
  }

  Widget stat(String title, int n, IconData icon) => Expanded(child: Container(
    padding: const EdgeInsets.all(12),
    decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(11), border: Border.all(color: const Color(0xFFE1E7EF))),
    child: Row(children: [
      Container(width: 38, height: 38, decoration: BoxDecoration(color: const Color(0xFFEAF2FF), borderRadius: BorderRadius.circular(9)), child: Icon(icon, color: const Color(0xFF1769E8))),
      const SizedBox(width: 9), Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text(title, style: const TextStyle(fontSize: 9, color: Color(0xFF718096))), Text(n.toString(), style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w900)),
      ]),
    ]),
  ));

  Widget errorBox() => Container(width: double.infinity, padding: const EdgeInsets.all(10), margin: const EdgeInsets.only(bottom: 8),
    color: const Color(0xFFFFF2F2), child: Row(children: [const Icon(Icons.error_outline, color: Colors.red), const SizedBox(width: 8), Expanded(child: Text(error!)), TextButton(onPressed: load, child: const Text('Retry'))]));

  Widget pendingTable() {
    if (pending.isEmpty) return const Center(child: Text('No orders are ready for packing.'));
    return table(['Order','Client','Warehouse','Items','Picked','Required','Action'],
      pending.map((o) => [o['order_no'],o['client_name'],o['warehouse_name'],o['item_count'],o['picked_qty'],o['required_date'] ?? '-',ElevatedButton(onPressed: () => start(o), child: const Text('Start Packing'))]).toList());
  }

  Widget tasksTable() {
    if (tasks.isEmpty) return const Center(child: Text('No packing tasks found.'));
    return table(['Packing No','Order','Client','Warehouse','Status','Packages','Packed','Action'],
      tasks.map((t) => [t['packing_no'],t['order_no'],t['client_name'],t['warehouse_name'],status(t['status'].toString()),t['total_packages'],t['packed_qty'],OutlinedButton(onPressed: () => openTask(t), child: const Text('Open'))]).toList());
  }

  Widget table(List<String> heads, List<List<dynamic>> rows) => Container(
    decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(9), border: Border.all(color: const Color(0xFFE1E7EF))),
    child: SingleChildScrollView(scrollDirection: Axis.horizontal, child: DataTable(
      columns: heads.map((x) => DataColumn(label: Text(x, style: const TextStyle(fontSize: 10, fontWeight: FontWeight.w800)))).toList(),
      rows: rows.map((r) => DataRow(cells: r.map((v) => DataCell(v is Widget ? v : Text(v.toString(), style: const TextStyle(fontSize: 10)))).toList())).toList(),
    )),
  );

  Widget status(String s) => Container(padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
    decoration: BoxDecoration(color: s == 'ready' ? const Color(0xFFE9F8EF) : const Color(0xFFEAF2FF), borderRadius: BorderRadius.circular(15)),
    child: Text(s.replaceAll('_',' ').toUpperCase(), style: const TextStyle(fontSize: 8, fontWeight: FontWeight.w800)));

}

class PackingTaskDialog extends StatefulWidget {
  final PackingService api; final Map<String,dynamic> initial;
  const PackingTaskDialog({super.key, required this.api, required this.initial});
  @override State<PackingTaskDialog> createState() => _PackingTaskDialogState();
}

class _PackingTaskDialogState extends State<PackingTaskDialog> {
  late Map<String,dynamic> d; bool busy=false;
  @override void initState(){super.initState();d=widget.initial;}
  List<Map<String,dynamic>> get items => (d['items'] as List? ?? []).map((x)=>Map<String,dynamic>.from(x)).toList();
  List<Map<String,dynamic>> get packages => (d['packages'] as List? ?? []).map((x)=>Map<String,dynamic>.from(x)).toList();

  Future<void> reload() async {
    final x=await widget.api.detail(d['task']['id'].toString());
    if(mounted)setState(()=>d=x);
  }

  Future<void> createPackage() async {
    final x=await showDialog<Map<String,dynamic>>(context:context,builder:(_)=>const PackageForm());
    if(x==null)return; setState(()=>busy=true);
    try { await widget.api.createPackage(d['task']['id'].toString(),packageNo:x['no'],packageType:x['type'],weight:x['weight'],length:x['length'],width:x['width'],height:x['height']); await reload(); }
    catch(e){snack(e.toString().replaceFirst('Exception: ',''),true);} finally{if(mounted)setState(()=>busy=false);}
  }

  Future<void> packItem() async {
    final good=items.where((x)=>((x['remaining_qty'] as num?)?.toDouble() ?? 0) > 0).toList();
    if(packages.isEmpty){snack('Create a package first.',true);return;}
    if(good.isEmpty){snack('All picked quantities are packed.',true);return;}
    final x=await showDialog<Map<String,dynamic>>(context:context,builder:(_)=>PackForm(items:good,packages:packages));
    if(x==null)return; setState(()=>busy=true);
    try { await widget.api.pack(d['task']['id'].toString(),orderItemId:x['item'],packageId:x['package'],quantity:x['qty']); await reload(); }
    catch(e){snack(e.toString().replaceFirst('Exception: ',''),true);} finally{if(mounted)setState(()=>busy=false);}
  }

  Future<void> complete() async {
    setState(()=>busy=true);
    try { await widget.api.complete(d['task']['id'].toString()); await reload(); snack('Packing completed. Order is ready for dispatch.'); }
    catch(e){snack(e.toString().replaceFirst('Exception: ',''),true);} finally{if(mounted)setState(()=>busy=false);}
  }

  void snack(String s,[bool bad=false])=>ScaffoldMessenger.of(context).showSnackBar(SnackBar(content:Text(s),backgroundColor:bad?Colors.red.shade700:null));

  @override Widget build(BuildContext context){
    final t=Map<String,dynamic>.from(d['task']); final st=t['status'].toString();
    final picked=items.fold<double>(0,(a,x)=>a+((x['picked_qty'] as num?)?.toDouble()??0));
    final packed=items.fold<double>(0,(a,x)=>a+((x['packed_qty'] as num?)?.toDouble()??0));
    return AlertDialog(
      title: Row(children:[Expanded(child:Text((t['packing_no']??'Packing').toString()+' • '+(t['order_no']??'').toString())),pill(st)]),
      content:SizedBox(width:900,height:540,child:busy?const Center(child:CircularProgressIndicator()):Column(children:[
        Align(alignment:Alignment.centerLeft,child:Text((t['client_name']??'-').toString()+' • '+(t['warehouse_name']??'-').toString())),
        const SizedBox(height:10),
        Row(children:[mini('Picked',picked),mini('Packed',packed),mini('Balance',picked-packed),mini('Packages',packages.length.toDouble())]),
        const SizedBox(height:10),
        Expanded(child:Row(children:[Expanded(child:itemsTable()),const SizedBox(width:10),SizedBox(width:270,child:packagePanel())])),
      ])),
      actions:[TextButton(onPressed:()=>Navigator.pop(context),child:const Text('Close')),if(st=='in_progress')...[
        OutlinedButton.icon(onPressed:createPackage,icon:const Icon(Icons.add_box_outlined),label:const Text('New Package')),
        ElevatedButton.icon(onPressed:packItem,icon:const Icon(Icons.inventory_2_outlined),label:const Text('Pack Item')),
        ElevatedButton.icon(onPressed:complete,icon:const Icon(Icons.check_circle_outline),label:const Text('Mark Ready')),
      ]],
    );
  }

  Widget mini(String title,double v)=>Expanded(child:Container(margin:const EdgeInsets.only(right:6),padding:const EdgeInsets.all(8),color:const Color(0xFFF5F8FC),child:Column(crossAxisAlignment:CrossAxisAlignment.start,children:[Text(title,style:const TextStyle(fontSize:8)),Text(v.toStringAsFixed(2),style:const TextStyle(fontWeight:FontWeight.w800))])));
  Widget pill(String s)=>Container(padding:const EdgeInsets.symmetric(horizontal:8,vertical:4),color:const Color(0xFFEAF2FF),child:Text(s.replaceAll('_',' ').toUpperCase(),style:const TextStyle(fontSize:8,fontWeight:FontWeight.w800)));
  Widget itemsTable()=>SingleChildScrollView(child:DataTable(columns:const[DataColumn(label:Text('SKU')),DataColumn(label:Text('Product')),DataColumn(label:Text('Picked')),DataColumn(label:Text('Packed')),DataColumn(label:Text('Balance'))],rows:items.map((i)=>DataRow(cells:[DataCell(Text(i['sku'].toString())),DataCell(Text(i['product_name'].toString())),DataCell(Text(i['picked_qty'].toString())),DataCell(Text(i['packed_qty'].toString())),DataCell(Text(i['remaining_qty'].toString()))])).toList()));
  Widget packagePanel()=>Container(padding:const EdgeInsets.all(8),color:const Color(0xFFF8FAFD),child:Column(crossAxisAlignment:CrossAxisAlignment.start,children:[const Text('Packages',style:TextStyle(fontWeight:FontWeight.w800)),const SizedBox(height:5),Expanded(child:ListView.builder(itemCount:packages.length,itemBuilder:(_,i){final p=packages[i];return ListTile(dense:true,contentPadding:EdgeInsets.zero,title:Text(p['package_no'].toString()),subtitle:Text(p['package_type'].toString()+' • '+p['weight'].toString()+' kg'));}))]));
}

class PackageForm extends StatefulWidget {
  const PackageForm({super.key});

  @override
  State<PackageForm> createState() => _PackageFormState();
}

class _PackageFormState extends State<PackageForm> {
  final no = TextEditingController();
  final type = TextEditingController(text: 'Box');
  final weight = TextEditingController(text: '0');
  final length = TextEditingController(text: '0');
  final width = TextEditingController(text: '0');
  final height = TextEditingController(text: '0');

  @override
  void dispose() {
    no.dispose();
    type.dispose();
    weight.dispose();
    length.dispose();
    width.dispose();
    height.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Create Package'),
      content: SizedBox(
        width: 420,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: no,
              decoration: const InputDecoration(labelText: 'Package No'),
            ),
            TextField(
              controller: type,
              decoration: const InputDecoration(labelText: 'Package Type'),
            ),
            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: weight,
                    keyboardType: TextInputType.number,
                    decoration: const InputDecoration(labelText: 'Weight kg'),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: TextField(
                    controller: length,
                    keyboardType: TextInputType.number,
                    decoration: const InputDecoration(labelText: 'Length'),
                  ),
                ),
              ],
            ),
            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: width,
                    keyboardType: TextInputType.number,
                    decoration: const InputDecoration(labelText: 'Width'),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: TextField(
                    controller: height,
                    keyboardType: TextInputType.number,
                    decoration: const InputDecoration(labelText: 'Height'),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancel'),
        ),
        ElevatedButton(
          onPressed: () {
            if (no.text.trim().isEmpty) return;
            Navigator.pop(context, {
              'no': no.text.trim(),
              'type': type.text.trim().isEmpty ? 'Box' : type.text.trim(),
              'weight': double.tryParse(weight.text) ?? 0,
              'length': double.tryParse(length.text) ?? 0,
              'width': double.tryParse(width.text) ?? 0,
              'height': double.tryParse(height.text) ?? 0,
            });
          },
          child: const Text('Create'),
        ),
      ],
    );
  }
}

class PackForm extends StatefulWidget {
  final List<Map<String, dynamic>> items;
  final List<Map<String, dynamic>> packages;

  const PackForm({
    super.key,
    required this.items,
    required this.packages,
  });

  @override
  State<PackForm> createState() => _PackFormState();
}

class _PackFormState extends State<PackForm> {
  String? item;
  String? package;
  final qty = TextEditingController();

  @override
  void dispose() {
    qty.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final itemOptions = widget.items
        .map(
          (i) => DropdownMenuItem<String>(
            value: i['order_item_id'].toString(),
            child: Text(
              '${i['sku'] ?? '-'} • ${i['product_name'] ?? '-'}',
            ),
          ),
        )
        .toList();

    final packageOptions = widget.packages
        .map(
          (p) => DropdownMenuItem<String>(
            value: p['id'].toString(),
            child: Text(p['package_no']?.toString() ?? '-'),
          ),
        )
        .toList();

    return AlertDialog(
      title: const Text('Pack Item'),
      content: SizedBox(
        width: 450,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            DropdownButtonFormField<String>(
              value: item,
              decoration: const InputDecoration(
                labelText: 'Product / Order Item',
              ),
              items: itemOptions,
              onChanged: (value) => setState(() => item = value),
            ),
            const SizedBox(height: 8),
            DropdownButtonFormField<String>(
              value: package,
              decoration: const InputDecoration(labelText: 'Package'),
              items: packageOptions,
              onChanged: (value) => setState(() => package = value),
            ),
            TextField(
              controller: qty,
              keyboardType: const TextInputType.numberWithOptions(
                decimal: true,
              ),
              decoration: const InputDecoration(labelText: 'Quantity'),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancel'),
        ),
        ElevatedButton(
          onPressed: () {
            final quantity = double.tryParse(qty.text);
            if (item == null ||
                package == null ||
                quantity == null ||
                quantity <= 0) {
              return;
            }

            Navigator.pop(context, {
              'item': item,
              'package': package,
              'qty': quantity,
            });
          },
          child: const Text('Pack'),
        ),
      ],
    );
  }
}
