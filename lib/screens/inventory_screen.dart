import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'common_widgets.dart';

class InventoryScreen extends StatefulWidget {
  const InventoryScreen({super.key});
  @override
  State<InventoryScreen> createState() => _InventoryScreenState();
}

class _InventoryScreenState extends State<InventoryScreen> {
  final search = TextEditingController();
  String category = 'All', warehouse = 'All', status = 'All';

  final items = const [
    ['ITM-1001','Cotton Fabric Roll','Raw Material','Main Warehouse','Roll','150','In Stock','₹ 3,75,000'],
    ['ITM-1002','Polyester Fabric Roll','Raw Material','Main Warehouse','Roll','80','Low Stock','₹ 1,60,000'],
    ['ITM-1003','Thread 40s','Raw Material','Ankleshwar WH','Cone','0','Out of Stock','₹ 0'],
    ['ITM-1004','Packaging Box Large','Packaging','Vilayat Warehouse','Pcs','200','In Stock','₹ 40,000'],
    ['ITM-1005','Packing Tape 2 Inch','Packaging','Main Warehouse','Roll','25','Low Stock','₹ 3,750'],
    ['ITM-1006','Label 100x150','Stationery','Delhi Warehouse','Pcs','0','Out of Stock','₹ 0'],
    ['ITM-1007','Pallet Wooden','Material Handling','Main Warehouse','Pcs','35','Low Stock','₹ 14,000'],
    ['ITM-1008','Stretch Film','Packaging','Mumbai Warehouse','Roll','120','In Stock','₹ 12,900'],
  ];

  List<List<String>> get filtered => items.where((r) {
    final q = search.text.toLowerCase().trim();
    return (q.isEmpty || r.any((v) => v.toLowerCase().contains(q))) &&
      (category == 'All' || r[2] == category) &&
      (warehouse == 'All' || r[3] == warehouse) &&
      (status == 'All' || r[6] == status);
  }).toList();

  @override
  void initState() { super.initState(); search.addListener(() => setState(() {})); }
  @override
  void dispose() { search.dispose(); super.dispose(); }

  @override
  Widget build(BuildContext context) {
    final compact = MediaQuery.sizeOf(context).width < 1050;
    return ScreenFrame(
      title: 'Inventory',
      subtitle: 'Stock by client, warehouse, SKU and batch.',
      actions: [OutlinedButton.icon(onPressed: () => _msg('Inventory exported successfully.'), icon: const Icon(Icons.download_outlined), label: const Text('Export'))],
      child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
        _stats(compact), const SizedBox(height: 16),
        if (compact) ...[_overview(), const SizedBox(height: 14), _valueChart(), const SizedBox(height: 14), _categoryChart()]
        else Row(crossAxisAlignment: CrossAxisAlignment.start, children: [Expanded(flex: 4, child: _overview()), const SizedBox(width: 14), Expanded(flex: 5, child: _valueChart()), const SizedBox(width: 14), Expanded(flex: 3, child: _categoryChart())]),
        const SizedBox(height: 16),
        if (compact) ...[_table(), const SizedBox(height: 14), _alerts()]
        else Row(crossAxisAlignment: CrossAxisAlignment.start, children: [Expanded(flex: 8, child: _table()), const SizedBox(width: 14), Expanded(flex: 3, child: _alerts())]),
      ]),
    );
  }

  Widget _stats(bool compact) {
    final data = [
      ['Total Items','1,250','All Items',Icons.inventory_2_outlined,Color(0xFF1769E8),Color(0xFFEAF2FF)],
      ['In Stock','875','70.00% of Total',Icons.inventory_outlined,Color(0xFF16A05D),Color(0xFFE7F9EF)],
      ['Low Stock','120','9.60% of Total',Icons.inventory_2_outlined,Color(0xFFE6A014),Color(0xFFFFF5E1)],
      ['Out of Stock','45','3.60% of Total',Icons.inventory_2_outlined,Color(0xFFE83C55),Color(0xFFFFE9ED)],
      ['Total Stock Value','₹ 48,75,650','In Current Value',Icons.currency_rupee_rounded,Color(0xFF7447D8),Color(0xFFF0EAFF)],
    ];
    final cards = data.map((d) => _stat(d[0] as String,d[1] as String,d[2] as String,d[3] as IconData,d[4] as Color,d[5] as Color)).toList();
    if (compact) return GridView.count(crossAxisCount: 2,crossAxisSpacing: 12,mainAxisSpacing: 12,childAspectRatio: 2.2,shrinkWrap: true,physics: const NeverScrollableScrollPhysics(),children: cards);
    return Row(children: [for (var i=0;i<cards.length;i++) ...[Expanded(child: cards[i]),if(i<cards.length-1) const SizedBox(width:12)]]);
  }

  Widget _stat(String title,String value,String sub,IconData icon,Color color,Color bg) => Container(
    padding: const EdgeInsets.all(14),
    decoration: _box(),
    child: Row(children: [Container(width:56,height:56,decoration:BoxDecoration(color:bg,borderRadius:BorderRadius.circular(11)),child:Icon(icon,color:color,size:28)),const SizedBox(width:12),Expanded(child:Column(crossAxisAlignment:CrossAxisAlignment.start,children:[Text(title,maxLines:1,overflow:TextOverflow.ellipsis,style:_bold(12)),const SizedBox(height:3),FittedBox(alignment:Alignment.centerLeft,child:Text(value,style:_bold(23))),Text(sub,maxLines:1,overflow:TextOverflow.ellipsis,style:const TextStyle(color:Color(0xFF738298),fontSize:10))]))]),
  );

  BoxDecoration _box() => BoxDecoration(color:Colors.white,borderRadius:BorderRadius.circular(12),border:Border.all(color:const Color(0xFFE1E8F1)),boxShadow:const [BoxShadow(color:Color(0x0A18304F),blurRadius:12,offset:Offset(0,4))]);
  TextStyle _bold(double size) => TextStyle(color:const Color(0xFF162B46),fontSize:size,fontWeight:FontWeight.w800);

  Widget _panel(String title,Widget body,{String? action}) => Container(padding:const EdgeInsets.all(15),decoration:_box(),child:Column(crossAxisAlignment:CrossAxisAlignment.start,children:[Row(children:[Text(title,style:_bold(14)),const Spacer(),if(action!=null)Text(action,style:const TextStyle(color:Color(0xFF1769E8),fontSize:11,fontWeight:FontWeight.w700))]),const SizedBox(height:8),body]));

  Widget _overview() => _panel('Stock Overview',SizedBox(height:190,child:Row(children:[SizedBox(width:180,child:CustomPaint(painter:_DonutPainter(),child:const Center(child:Column(mainAxisSize:MainAxisSize.min,children:[Text('1,250',style:TextStyle(fontSize:23,fontWeight:FontWeight.w900,color:Color(0xFF162B46))),Text('Total Items',style:TextStyle(fontSize:10,color:Color(0xFF77859A)))])))),const SizedBox(width:12),Expanded(child:Column(mainAxisAlignment:MainAxisAlignment.center,children:[_legend('In Stock','875 (70.00%)',Color(0xFF1769E8)),_legend('Low Stock','120 (9.60%)',Color(0xFFFFB20E)),_legend('Out of Stock','45 (3.60%)',Color(0xFFE83C55)),_legend('Total Items','1,250 (100%)',Color(0xFF22B86B))]))]));
  Widget _legend(String a,String b,Color c) => Padding(padding:const EdgeInsets.symmetric(vertical:6),child:Row(children:[Container(width:8,height:8,decoration:BoxDecoration(color:c,shape:BoxShape.circle)),const SizedBox(width:8),Expanded(child:Text(a,style:const TextStyle(fontSize:10,color:Color(0xFF35465D)))),Text(b,style:const TextStyle(fontSize:9,fontWeight:FontWeight.w700,color:Color(0xFF24364D)))]));

  Widget _valueChart() => _panel('Stock Value (Last 7 Days)',SizedBox(height:190,child:CustomPaint(painter:_LinePainter(),child:const SizedBox.expand())));

  Widget _categoryChart() => _panel('Stock by Category',SizedBox(height:190,child:Row(children:[SizedBox(width:118,child:CustomPaint(painter:_CategoryPainter(),child:const SizedBox.expand())),const SizedBox(width:7),Expanded(child:Column(mainAxisAlignment:MainAxisAlignment.center,children:[_legend('Raw Material','52% (650)',Color(0xFF1769E8)),_legend('Packaging','20% (250)',Color(0xFF22B86B)),_legend('Material Handling','15% (188)',Color(0xFFFFB20E)),_legend('Stationery','8% (100)',Color(0xFF7046D8)),_legend('Others','5% (62)',Color(0xFF9AA6B6))]))])));

  Widget _table() => _panel('Inventory',Column(children:[_filters(),const Divider(height:1),SingleChildScrollView(scrollDirection:Axis.horizontal,child:DataTable(headingRowHeight:44,dataRowMinHeight:49,dataRowMaxHeight:54,columnSpacing:22,headingRowColor:const WidgetStatePropertyAll(Color(0xFFFAFBFD)),columns:const [DataColumn(label:Text('#')),DataColumn(label:Text('Item Code')),DataColumn(label:Text('Item Name')),DataColumn(label:Text('Category')),DataColumn(label:Text('Warehouse')),DataColumn(label:Text('UOM')),DataColumn(label:Text('Stock Qty')),DataColumn(label:Text('Status')),DataColumn(label:Text('Stock Value')),DataColumn(label:Text('Actions'))],rows:List.generate(filtered.length,(i){final r=filtered[i];return DataRow(cells:[DataCell(Text('${i+1}')),DataCell(Text(r[0])),DataCell(Text(r[1],style:const TextStyle(fontWeight:FontWeight.w600))),DataCell(Text(r[2])),DataCell(Text(r[3])),DataCell(Text(r[4])),DataCell(Text(r[5])),DataCell(_chip(r[6])),DataCell(Text(r[7])),DataCell(_view(r[1]))]);})),const Divider(height:1),Padding(padding:const EdgeInsets.symmetric(vertical:10),child:Row(children:[Text('Showing 1 to ${filtered.length} of 1,250 entries',style:const TextStyle(color:Color(0xFF718096),fontSize:10)),const Spacer(),_page('Prev'),_page('1',true),_page('2'),_page('3'),_page('4'),_page('5'),_page('…'),_page('157'),_page('Next')]))]));

  Widget _filters() => Padding(padding:const EdgeInsets.all(10),child:Wrap(spacing:7,runSpacing:7,children:[SizedBox(width:310,height:40,child:TextField(controller:search,decoration:InputDecoration(hintText:'Search by item name, SKU or barcode...',hintStyle:const TextStyle(fontSize:10,color:Color(0xFF8290A2)),prefixIcon:const Icon(Icons.search_rounded,size:18),contentPadding:const EdgeInsets.symmetric(vertical:9),border:OutlineInputBorder(borderRadius:BorderRadius.all(Radius.circular(8)),borderSide:BorderSide(color:Color(0xFFDCE4EE))))),_drop(category,['All','Raw Material','Packaging','Material Handling','Stationery'],(v)=>setState(()=>category=v!),'Category'),_drop(warehouse,['All','Main Warehouse','Ankleshwar WH','Vilayat Warehouse','Delhi Warehouse','Mumbai Warehouse'],(v)=>setState(()=>warehouse=v!),'Warehouse'),_drop(status,['All','In Stock','Low Stock','Out of Stock'],(v)=>setState(()=>status=v!),'Status'),OutlinedButton.icon(onPressed:()=>setState((){}),icon:const Icon(Icons.filter_alt_outlined,size:16),label:const Text('Filter'),style:OutlinedButton.styleFrom(padding:const EdgeInsets.symmetric(horizontal:12,vertical:11))),OutlinedButton.icon(onPressed:()=>_msg('Inventory exported successfully.'),icon:const Icon(Icons.download_outlined,size:16),label:const Text('Export'),style:OutlinedButton.styleFrom(padding:const EdgeInsets.symmetric(horizontal:12,vertical:11))) ]));

  Widget _drop(String value,List<String> list,ValueChanged<String?> onChange,String label)=>Container(height:40,width:145,padding:const EdgeInsets.symmetric(horizontal:9),decoration:BoxDecoration(border:Border.all(color:const Color(0xFFDCE4EE)),borderRadius:BorderRadius.circular(8)),child:DropdownButtonHideUnderline(child:DropdownButton<String>(value:value,isExpanded:true,icon:const Icon(Icons.keyboard_arrow_down_rounded,size:16),style:const TextStyle(fontSize:10,color:Color(0xFF42546A),fontWeight:FontWeight.w600),items:list.map((x)=>DropdownMenuItem(value:x,child:Text(x=='All'?'$label: All':x,maxLines:1,overflow:TextOverflow.ellipsis))).toList(),onChanged:onChange)));
  Widget _chip(String s){final low=s=='Low Stock',out=s=='Out of Stock';final c=out?Color(0xFFD92F4B):low?Color(0xFFE28C00):Color(0xFF14894E);final bg=out?Color(0xFFFFE5EA):low?Color(0xFFFFF0D8):Color(0xFFE4F7EC);return Container(padding:const EdgeInsets.symmetric(horizontal:8,vertical:5),decoration:BoxDecoration(color:bg,borderRadius:BorderRadius.circular(6)),child:Text(s,style:TextStyle(color:c,fontSize:8,fontWeight:FontWeight.w800)));}
  Widget _view(String name)=>IconButton(onPressed:()=>_msg('Viewing $name'),icon:const Icon(Icons.visibility_outlined,color:Color(0xFF1769E8),size:17),tooltip:'View');
  Widget _page(String s,[bool active=false])=>Container(margin:const EdgeInsets.only(left:4),height:30,minWidth:30,alignment:Alignment.center,padding:const EdgeInsets.symmetric(horizontal:7),decoration:BoxDecoration(color:active?const Color(0xFF1769E8):Colors.white,borderRadius:BorderRadius.circular(6),border:Border.all(color:active?const Color(0xFF1769E8):const Color(0xFFDDE5EF))),child:Text(s,style:TextStyle(color:active?Colors.white:const Color(0xFF63738A),fontSize:9,fontWeight:FontWeight.w700)));

  Widget _alerts()=>Column(children:[_alert('Low Stock Alerts',Color(0xFFEBA311),Icons.warning_amber_rounded,[['Polyester Fabric Roll','Qty: 80','Ankleshwar WH'],['Packing Tape 2 Inch','Qty: 25','Main Warehouse'],['Pallet Wooden','Qty: 35','Main Warehouse']]),const SizedBox(height:12),_alert('Out of Stock Alerts',Color(0xFFE83C55),Icons.inventory_2_outlined,[['Thread 40s','Last In: 10 May 2025','Ankleshwar WH'],['Label 100x150','Last In: 12 May 2025','Delhi Warehouse']])]);
  Widget _alert(String title,Color color,IconData icon,List<List<String>> data)=>_panel(title,Column(children:[for(var i=0;i<data.length;i++) ...[Padding(padding:const EdgeInsets.symmetric(vertical:8),child:Row(children:[Container(width:28,height:28,decoration:BoxDecoration(color:color.withValues(alpha:.11),borderRadius:BorderRadius.circular(7)),child:Icon(icon,color:color,size:16)),const SizedBox(width:8),Expanded(child:Column(crossAxisAlignment:CrossAxisAlignment.start,children:[Text(data[i][0],maxLines:1,overflow:TextOverflow.ellipsis,style:const TextStyle(fontSize:9,fontWeight:FontWeight.w700)),Text(data[i][2],style:const TextStyle(fontSize:8,color:Color(0xFF8793A4)))])),Text(data[i][1],style:const TextStyle(fontSize:8,fontWeight:FontWeight.w700))])),if(i<data.length-1)const Divider(height:1)]));
  void _msg(String s)=>ScaffoldMessenger.of(context).showSnackBar(SnackBar(content:Text(s)));
}

class _DonutPainter extends CustomPainter { @override void paint(Canvas c,Size s){final center=Offset(s.width/2,s.height/2),r=math.min(s.width,s.height)/2-12,p=Paint()..style=PaintingStyle.stroke..strokeWidth=r*.3;const v=[70.0,9.6,3.6,16.8],col=[Color(0xFF1769E8),Color(0xFFFFB20E),Color(0xFFE83C55),Color(0xFF22B86B)];var a=-math.pi/2;for(var i=0;i<v.length;i++){final sw=2*math.pi*v[i]/100;p.color=col[i];c.drawArc(Rect.fromCircle(center:center,radius:r),a,sw,false,p);a+=sw+.025;}}@override bool shouldRepaint(covariant CustomPainter oldDelegate)=>false;}
class _CategoryPainter extends CustomPainter { @override void paint(Canvas c,Size s){final center=Offset(s.width/2,s.height/2),r=math.min(s.width,s.height)/2-7,p=Paint()..style=PaintingStyle.stroke..strokeWidth=r*.32;const v=[52.0,20.0,15.0,8.0,5.0],col=[Color(0xFF1769E8),Color(0xFF22B86B),Color(0xFFFFB20E),Color(0xFF7046D8),Color(0xFF9AA6B6)];var a=-math.pi/2;for(var i=0;i<v.length;i++){final sw=2*math.pi*v[i]/100;p.color=col[i];c.drawArc(Rect.fromCircle(center:center,radius:r),a,sw,false,p);a+=sw+.018;}}@override bool shouldRepaint(covariant CustomPainter oldDelegate)=>false;}
class _LinePainter extends CustomPainter { @override void paint(Canvas c,Size s){const l=34.0,r=7.0,t=14.0,b=30.0;final w=s.width-l-r,h=s.height-t-b,g=Paint()..color=const Color(0xFFE8EDF4);for(var i=0;i<4;i++){final y=t+h*i/3;c.drawLine(Offset(l,y),Offset(s.width-r,y),g);}const v=[28.0,35.0,40.0,36.0,42.0,38.0,51.0];final p=Paint()..color=const Color(0xFF1769E8)..style=PaintingStyle.stroke..strokeWidth=2.5..strokeCap=StrokeCap.round;final path=Path();for(var i=0;i<v.length;i++){final x=l+w*i/(v.length-1),y=t+h*(60-v[i])/60;i==0?path.moveTo(x,y):path.lineTo(x,y);c.drawCircle(Offset(x,y),3.5,Paint()..color=const Color(0xFF1769E8));}c.drawPath(path,p);const labels=['19 May','20 May','21 May','22 May','23 May','24 May','25 May'];for(var i=0;i<labels.length;i++){final tp=TextPainter(text:TextSpan(text:labels[i],style:const TextStyle(fontSize:7,color:Color(0xFF7B8798))),textDirection:TextDirection.ltr)..layout();tp.paint(c,Offset(l+w*i/(labels.length-1)-tp.width/2,s.height-16));}}@override bool shouldRepaint(covariant CustomPainter oldDelegate)=>false;}
