// lib/main.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'model/power_grid.dart';
import 'providers/power_grid_provider.dart';

void main() {
  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => PowerGridProvider()),
      ],
      child: MyApp(),
    ),
  );
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Power Grid App',
      theme: ThemeData(primarySwatch: Colors.blue),
      home: PowerGridScreen(),
    );
  }
}

class PowerGridScreen extends StatefulWidget {
  @override
  _PowerGridScreenState createState() => _PowerGridScreenState();
}

class _PowerGridScreenState extends State<PowerGridScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      Provider.of<PowerGridProvider>(context, listen: false).initDatabase();
    });
  }

  void _showAddDialog({PowerGrid? grid}) {
    final _formKey = GlobalKey<FormState>();
    final nameController = TextEditingController(text: grid?.name ?? '');
    final locationController = TextEditingController(text: grid?.location ?? '');
    final capacityController = TextEditingController(text: grid?.capacity.toString() ?? '');
    final statusController = TextEditingController(text: grid?.status ?? '');
    final descController = TextEditingController(text: grid?.description ?? '');

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text(grid == null ? 'เพิ่มข้อมูล Power Grid' : 'แก้ไขข้อมูล'),
          content: Form(
            key: _formKey,
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextFormField(
                    controller: nameController,
                    decoration: InputDecoration(labelText: 'Name (ชื่อโรงไฟฟ้า)'),
                    validator: (v) => v!.isEmpty ? 'กรอกชื่อ' : null,
                  ),
                  TextFormField(
                    controller: locationController,
                    decoration: InputDecoration(labelText: 'Location (ที่ตั้ง)'),
                    validator: (v) => v!.isEmpty ? 'กรอกสถานที่' : null,
                  ),
                  TextFormField(
                    controller: capacityController,
                    decoration: InputDecoration(labelText: 'Capacity (กำลังผลิต, MW)'),
                    keyboardType: TextInputType.number,
                    validator: (v) {
                      if (v!.isEmpty) return 'กรอกความจุ';
                      if (double.tryParse(v) == null) return 'กรุณากรอกเป็นตัวเลข';
                      return null;
                    },
                  ),
                  TextFormField(
                    controller: statusController,
                    decoration: InputDecoration(labelText: 'Status (สถานะ)'),
                    validator: (v) => v!.isEmpty ? 'กรอกสถานะ' : null,
                  ),
                  TextFormField(
                    controller: descController,
                    decoration: InputDecoration(labelText: 'Description (รายละเอียด)'),
                  ),
                ],
              ),
            ),
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(context), child: Text('ยกเลิก')),
            ElevatedButton(
              onPressed: () async {
                if (_formKey.currentState!.validate()) {
                  final provider = Provider.of<PowerGridProvider>(context, listen: false);
                  final capacity = double.parse(capacityController.text);

                  try {
                    if (grid == null) {
                      await provider.addPowerGrid(
                        PowerGrid(
                          name: nameController.text,
                          location: locationController.text,
                          capacity: capacity,
                          status: statusController.text,
                          description: descController.text,
                        ),
                      );
                    } else {
                      await provider.updatePowerGrid(
                        PowerGrid(
                          id: grid.id,
                          name: nameController.text,
                          location: locationController.text,
                          capacity: capacity,
                          status: statusController.text,
                          description: descController.text,
                        ),
                      );
                    }

                    Navigator.pop(context);
                    await provider.fetchGrids(); // รีเฟรชหน้า
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text('บันทึกสำเร็จ')),
                    );
                  } catch (e) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text('เกิดข้อผิดพลาด: $e')),
                    );
                  }
                }
              },
              child: Text(grid == null ? 'บันทึก' : 'อัปเดต'),
            ),
          ],
        );
      },
    );
  }

  void _confirmDelete(PowerGrid grid) async {
    final provider = Provider.of<PowerGridProvider>(context, listen: false);
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('ลบข้อมูล'),
        content: Text('ต้องการลบ "${grid.name}" หรือไม่?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: Text('ยกเลิก')),
          TextButton(onPressed: () => Navigator.pop(context, true), child: Text('ลบ')),
        ],
      ),
    );
    if (confirm == true) {
      await provider.deletePowerGrid(grid.id!);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('ลบข้อมูลเรียบร้อยแล้ว')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final provider = Provider.of<PowerGridProvider>(context);
    final grids = provider.grids;

    return Scaffold(
      appBar: AppBar(
        title: Text('Power Grid Manager'),
        actions: [
          IconButton(
            icon: Icon(Icons.refresh),
            onPressed: () async {
              await provider.fetchGrids(); // รีเฟรชหน้า
            },
          ),
        ],
      ),
      body: Padding(
        padding: EdgeInsets.all(16),
        child: grids.isEmpty
            ? Center(
                child: ElevatedButton(
                  onPressed: () => _showAddDialog(),
                  child: Text('เพิ่มข้อมูล'),
                ),
              )
            : ListView.builder(
                itemCount: grids.length,
                itemBuilder: (context, index) {
                  final grid = grids[index];
                  return Card(
                    child: ListTile(
                      title: Text(grid.name),
                      subtitle: Text(
                          'Location: ${grid.location}, Capacity: ${grid.capacity} MW, Status: ${grid.status}'),
                      trailing: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          IconButton(
                              icon: Icon(Icons.edit),
                              onPressed: () => _showAddDialog(grid: grid)),
                          IconButton(
                              icon: Icon(Icons.delete),
                              onPressed: () => _confirmDelete(grid)),
                        ],
                      ),
                    ),
                  );
                },
              ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _showAddDialog(),
        child: Icon(Icons.add),
      ),
    );
  }
}
