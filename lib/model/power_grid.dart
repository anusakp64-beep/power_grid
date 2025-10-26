// lib/model/power_grid.dart
class PowerGrid {
  int? id;
  String name;
  String location;
  double capacity;
  String status;
  String description;

  PowerGrid({
    this.id,
    required this.name,
    required this.location,
    required this.capacity,
    required this.status,
    required this.description,
  });

  Map<String, dynamic> toMap() {
    final map = <String, dynamic>{
      'name': name,
      'location': location,
      'capacity': capacity,
      'status': status,
      'description': description,
    };
    if (id != null) map['id'] = id;
    return map;
  }

  factory PowerGrid.fromMap(Map<String, dynamic> map) {
    return PowerGrid(
      id: map['id'],
      name: map['name'],
      location: map['location'],
      capacity: map['capacity'],
      status: map['status'],
      description: map['description'],
    );
  }
}
