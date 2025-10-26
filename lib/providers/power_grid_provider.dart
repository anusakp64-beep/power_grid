import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart'; // สำหรับ ChangeNotifier
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:path/path.dart';
import '../model/power_grid.dart';


class PowerGridProvider with ChangeNotifier {
  List<PowerGrid> _grids = [];
  List<PowerGrid> get grids => [..._grids];

  Database? _db;

Future<void> initDatabase() async {
  if (!kIsWeb) {
    sqfliteFfiInit();
    databaseFactory = databaseFactoryFfi;
  }

  final dbPath = join(await databaseFactory.getDatabasesPath(), 'powergrid.db');
  _db = await databaseFactory.openDatabase(dbPath, options: OpenDatabaseOptions(
    version: 1,
    onCreate: (db, version) async {
      await db.execute('''
        CREATE TABLE grids(
          id INTEGER PRIMARY KEY AUTOINCREMENT,
          name TEXT,
          location TEXT,
          capacity REAL,
          status TEXT,
          description TEXT
        )
      ''');
    },
  ));

  await fetchGrids();
}


  Future<void> fetchGrids() async {
    final maps = await _db!.query('grids');
    _grids = maps.map((map) => PowerGrid.fromMap(map)).toList();
    notifyListeners();
  }

  Future<void> addPowerGrid(PowerGrid grid) async {
    grid.id = await _db!.insert('grids', grid.toMap());
    _grids.add(grid);
    notifyListeners();
  }

  Future<void> updatePowerGrid(PowerGrid grid) async {
    await _db!.update('grids', grid.toMap(), where: 'id = ?', whereArgs: [grid.id]);
    final index = _grids.indexWhere((g) => g.id == grid.id);
    if (index != -1) _grids[index] = grid;
    notifyListeners();
  }

  Future<void> deletePowerGrid(int id) async {
    await _db!.delete('grids', where: 'id = ?', whereArgs: [id]);
    _grids.removeWhere((g) => g.id == id);
    notifyListeners();
  }
}
