import 'package:flutter/material.dart';
import '../../services/auth_service.dart';
import '../../services/user_service.dart';
import '../common_widgets.dart';

class MasterUsersRolesScreen extends StatefulWidget {
  const MasterUsersRolesScreen({super.key});
  @override State<MasterUsersRolesScreen> createState()=>_MasterUsersRolesScreenState();
}

class _MasterUsersRolesScreenState extends State<MasterUsersRolesScreen> {
  final search=TextEditingController();
  final service=UserService.instance;
  List<Map<String,dynamic>> users=[],roles=[],warehouses=[],companies=[];
  String role='All',status='All';
  bool loading=true;

  @override void initState(){super.initState();search.addListener(_refresh);_load();}
  @override void dispose(){search.dispose();super.dispose();}
  void _refresh(){if(mounted)setState((){});}
  void _msg(String m)=>ScaffoldMessenger.of(context).showSnackBar(SnackBar(content:Text(m)));

  Future<void> _load() async {
    setState(()=>loading=true);
    try{
      users=await service.list();
      roles=await service.roles();
      if(AuthService.instance.session?.role=='master_admin'){
        companies=await service.companies();
        if(companies.isNotEmpty) warehouses=await service.warehouses(companyId:companies.first['id'].toString());
      }
      if(mounted)setState(()=>loading=false);
    }catch(e){if(mounted){setState(()=>loading=false);_msg(e.toString().replaceFirst('Exception: ',''));}}
  }

  List<Map<String,dynamic>> get filtered=>users.where((u){
    final q=search.text.toLowerCase().trim();
    final r=role=='All'||u['role']==role;
    final s=status=='All'||(u['is_active']==true?'Active':'Inactive')==status;
    final t=[u['user_code'],u['full_name'],u['email'],u['role'],u['employee_code']].join(' ').toLowerCase();
    return r&&s&&(q.isEmpty||t.contains(q));
  }).toList();

  String label(String r){
    const m={'admin':'Company Admin','client':'Client User','warehouse_manager':'Warehouse Manager','warehouse_supervisor':'Warehouse Supervisor','warehouse_operator':'Warehouse Operator','warehouse_qc':'Warehouse QC User','gate_operator':'Gate Operator','inventory_user':'Inventory User','dispatch_user':'Dispatch User'};
    return m[r]??r;
  }

  Future<void> _openForm([Map<String,dynamic>? old]) async {
    if (AuthService.instance.session?.role == 'master_admin') {
      try {
        companies = await service.companies();
        if (companies.isEmpty) {
          _msg('No companies found. Create a company first.');
          return;
        }
      } catch (e) {
        _msg(e.toString().replaceFirst('Exception: ', ''));
        return;
      }
    }
    final name=TextEditingController(text:old?['full_name']?.toString()??'');
    final username=TextEditingController(text:old?['username']?.toString()??'');
    final email=TextEditingController(text:old?['email']?.toString()??'');
    final phone=TextEditingController(text:old?['phone']?.toString()??'');
    final emp=TextEditingController(text:old?['employee_code']?.toString()??'');
    final dept=TextEditingController(text:old?['department']?.toString()??'');
    final designation=TextEditingController(text:old?['designation']?.toString()??'');
    final password=TextEditingController();
    String selected=old?['role']?.toString()??'warehouse_operator';
    String? companyId=old?['company_id']?.toString()??(companies.isNotEmpty?companies.first['id'].toString():null);
    List<String> selectedWh=((old?['warehouses'] as List?)??[]).map((e)=>(e as Map)['warehouseId'].toString()).toList();

    await showDialog(context:context,builder:(ctx)=>StatefulBuilder(builder:(ctx,setD){
      return AlertDialog(
        title:Text(old==null?'Add User':'Edit User'),
        content:SizedBox(width:560,child:SingleChildScrollView(child:Column(children:[
          if(AuthService.instance.session?.role=='master_admin')
            InkWell(
              onTap: companies.isEmpty
                  ? null
                  : () async {
                      final selectedCompany = await showDialog<String>(
                        context: ctx,
                        builder: (dialogContext) => AlertDialog(
                          title: const Text('Select Company'),
                          content: SizedBox(
                            width: 450,
                            child: ListView(
                              shrinkWrap: true,
                              children: companies.map((c) {
                                final id = c['id'].toString();
                                return ListTile(
                                  title: Text(c['name']?.toString() ?? '-'),
                                  subtitle: Text(c['company_code']?.toString() ?? ''),
                                  trailing: id == companyId
                                      ? const Icon(Icons.check_circle)
                                      : null,
                                  onTap: () => Navigator.pop(dialogContext, id),
                                );
                              }).toList(),
                            ),
                          ),
                        ),
                      );
                      if (selectedCompany != null) {
                        companyId = selectedCompany;
                        selectedWh = [];
                        try {
                          final x = await service.warehouses(companyId: selectedCompany);
                          setD(() => warehouses = x);
                        } catch (e) {
                          _msg(e.toString().replaceFirst('Exception: ', ''));
                        }
                      }
                    },
              child: InputDecorator(
                decoration: const InputDecoration(
                  labelText: 'Company',
                  border: OutlineInputBorder(),
                  suffixIcon: Icon(Icons.arrow_drop_down),
                ),
                child: Text(
                  companyId == null
                      ? 'Select Company'
                      : (companies.firstWhere(
                          (c) => c['id'].toString() == companyId,
                          orElse: () => <String, dynamic>{'name': 'Select Company'},
                        )['name']?.toString() ?? 'Select Company'),
                ),
              ),
            ),
          _field(name,'Full Name'),_field(username,'Username',enabled:old==null),_field(email,'Email'),_field(phone,'Phone'),
          _field(emp,'Employee Code'),_field(dept,'Department'),_field(designation,'Designation'),
          InkWell(
            onTap: roles.isEmpty
                ? null
                : () async {
                    final selectedRole = await showDialog<String>(
                      context: ctx,
                      builder: (dialogContext) => AlertDialog(
                        title: const Text('Select Role'),
                        content: SizedBox(
                          width: 450,
                          child: ListView(
                            shrinkWrap: true,
                            children: roles.map((r) {
                              final key = r['key'].toString();
                              return ListTile(
                                title: Text(r['label']?.toString() ?? key),
                                subtitle: Text(key),
                                trailing: key == selected
                                    ? const Icon(Icons.check_circle)
                                    : null,
                                onTap: () => Navigator.pop(dialogContext, key),
                              );
                            }).toList(),
                          ),
                        ),
                      ),
                    );
                    if (selectedRole != null) {
                      setD(() => selected = selectedRole);
                    }
                  },
            child: InputDecorator(
              decoration: const InputDecoration(
                labelText: 'Role',
                border: OutlineInputBorder(),
                suffixIcon: Icon(Icons.arrow_drop_down),
              ),
              child: Text(
                roles
                    .firstWhere(
                      (r) => r['key'].toString() == selected,
                      orElse: () => <String, dynamic>{'label': selected},
                    )['label']
                    ?.toString() ?? selected,
              ),
            ),
          ),
          if(old==null)_field(password,'Password (min 12 characters)',obscure:true),
          if(['warehouse_manager','warehouse_supervisor','warehouse_operator','warehouse_qc','gate_operator','inventory_user','dispatch_user'].contains(selected))...[
            const SizedBox(height:8),const Align(alignment:Alignment.centerLeft,child:Text('Warehouse Assignment',style:TextStyle(fontWeight:FontWeight.w700))),
            ...warehouses.map((w)=>CheckboxListTile(dense:true,value:selectedWh.contains(w['id'].toString()),title:Text((w['code']??'').toString()+' - '+(w['name']??'').toString()),onChanged:(v)=>setD(()=>v==true?selectedWh.add(w['id'].toString()):selectedWh.remove(w['id'].toString())))),
          ],
        ]))),
        actions:[TextButton(onPressed:()=>Navigator.pop(ctx),child:const Text('Cancel')),FilledButton(onPressed:()async{
          try{
            final data=<String,dynamic>{'fullName':name.text,'username':username.text,'email':email.text,'phone':phone.text,'employeeCode':emp.text,'department':dept.text,'designation':designation.text,'role':selected,'warehouseIds':selectedWh};
            if(companyId!=null)data['companyId']=companyId;
            if(password.text.isNotEmpty)data['password']=password.text;
            if(old==null)await service.create(data);else await service.update(old['id'].toString(),data);
            if(ctx.mounted)Navigator.pop(ctx);await _load();_msg('User saved successfully.');
          }catch(e){_msg(e.toString().replaceFirst('Exception: ',''));}
        },child:Text(old==null?'Create User':'Save Changes'))],
      );
    }));
  }

  Widget _field(TextEditingController c,String label,{bool enabled=true,bool obscure=false})=>Padding(padding:const EdgeInsets.only(bottom:8),child:TextField(controller:c,enabled:enabled,obscureText:obscure,decoration:InputDecoration(labelText:label)));

  Future<void> _status(Map<String,dynamic> u)async{
    try{await service.setStatus(u['id'].toString(),u['is_active']!=true);await _load();}
    catch(e){_msg(e.toString().replaceFirst('Exception: ',''));}
  }

  @override Widget build(BuildContext context)=>ScreenFrame(
    title:'Users & Roles',
    subtitle:'Manage users, warehouse roles, permissions and access scope.',
    actions:[FilledButton.icon(onPressed:()=>_openForm(),icon:const Icon(Icons.person_add_alt_1_outlined),label:const Text('Add User')),IconButton(onPressed:_load,icon:const Icon(Icons.refresh))],
    child:loading?const Center(child:CircularProgressIndicator()):Column(crossAxisAlignment:CrossAxisAlignment.stretch,children:[_stats(),const SizedBox(height:16),_table()])
  );

  Widget _stats()=>Wrap(spacing:12,runSpacing:12,children:[
    _stat('Total Users',users.length,Icons.groups_2_outlined),
    _stat('Active',users.where((u)=>u['is_active']==true).length,Icons.verified_user_outlined),
    _stat('Warehouse Staff',users.where((u)=>['warehouse_manager','warehouse_supervisor','warehouse_operator','warehouse_qc'].contains(u['role'])).length,Icons.warehouse_outlined),
    _stat('QC Users',users.where((u)=>u['role']=='warehouse_qc').length,Icons.fact_check_outlined),
  ]);

  Widget _stat(String t,int v,IconData i)=>Container(width:210,padding:const EdgeInsets.all(14),decoration:_box(),child:Row(children:[Icon(i,size:28,color:const Color(0xFF1769E8)),const SizedBox(width:12),Column(crossAxisAlignment:CrossAxisAlignment.start,children:[Text(t,style:const TextStyle(fontSize:11,fontWeight:FontWeight.w700)),Text(v.toString(),style:const TextStyle(fontSize:22,fontWeight:FontWeight.w800))])]));

  Widget _table()=>Container(decoration:_box(),padding:const EdgeInsets.all(12),child:Column(children:[
    Wrap(spacing:8,runSpacing:8,children:[
      SizedBox(width:300,height:42,child:TextField(controller:search,decoration:const InputDecoration(prefixIcon:Icon(Icons.search),hintText:'Search user, employee code or role'))),
      _drop(role,['All',...roles.map((r)=>r['key'].toString())],(v)=>setState(()=>role=v??'All'),(v)=>v=='All'?'Role: All':label(v)),
      _drop(status,const ['All','Active','Inactive'],(v)=>setState(()=>status=v??'All'),(v)=>v),
    ]),
    const Divider(height:20),
    SingleChildScrollView(scrollDirection:Axis.horizontal,child:DataTable(
      columns:const[DataColumn(label:Text('User ID')),DataColumn(label:Text('Employee Code')),DataColumn(label:Text('Name')),DataColumn(label:Text('Role')),DataColumn(label:Text('Warehouse')),DataColumn(label:Text('Status')),DataColumn(label:Text('Actions'))],
      rows:filtered.map((u){
        final wh=(u['warehouses'] as List? ?? []).map((e)=>(e as Map)['code'].toString()).join(', ');
        final active=u['is_active']==true;
        return DataRow(cells:[
          DataCell(Text(u['user_code']?.toString()??'-')),
          DataCell(Text(u['employee_code']?.toString()??'-')),
          DataCell(Text(u['full_name']?.toString()??'-')),
          DataCell(Text(label(u['role'].toString()))),
          DataCell(Text(wh.isEmpty?'-':wh)),
          DataCell(Text(active?'Active':'Inactive')),
          DataCell(Row(children:[IconButton(onPressed:()=>_openForm(u),icon:const Icon(Icons.edit_outlined)),IconButton(onPressed:()=>_status(u),icon:Icon(active?Icons.person_off_outlined:Icons.person_add_alt_1_outlined))]))
        ]);
      }).toList(),
    ))
  ]));

  Widget _drop(String value,List<String> vals,ValueChanged<String?> onChanged,String Function(String) text)=>Container(width:190,height:42,padding:const EdgeInsets.symmetric(horizontal:8),decoration:_box(),child:DropdownButtonHideUnderline(child:DropdownButton<String>(value:value,isExpanded:true,items:vals.map((v)=>DropdownMenuItem(value:v,child:Text(text(v),overflow:TextOverflow.ellipsis))).toList(),onChanged:onChanged)));

  BoxDecoration _box()=>BoxDecoration(color:Colors.white,borderRadius:BorderRadius.circular(12),border:Border.all(color:const Color(0xFFE1E8F1)));
}
