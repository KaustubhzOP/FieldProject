import 'driver.dart';

class WaypointModel {
  final double latitude;
  final double longitude;
  final String address;
  final bool completed;

  WaypointModel({
    required this.latitude,
    required this.longitude,
    required this.address,
    this.completed = false,
  });

  factory WaypointModel.fromJson(Map<String, dynamic> json) {
    return WaypointModel(
      latitude: json['latitude']?.toDouble() ?? 0.0,
      longitude: json['longitude']?.toDouble() ?? 0.0,
      address: json['address'] ?? '',
      completed: json['completed'] ?? false,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'latitude': latitude,
      'longitude': longitude,
      'address': address,
      'completed': completed,
    };
  }

  WaypointModel copyWith({
    double? latitude,
    double? longitude,
    String? address,
    bool? completed,
  }) {
    return WaypointModel(
      latitude: latitude ?? this.latitude,
      longitude: longitude ?? this.longitude,
      address: address ?? this.address,
      completed: completed ?? this.completed,
    );
  }
}

class RouteModel {
  final String id;
  final String name;
  final String ward;
  final List<WaypointModel> waypoints;
  final String assignedDriver;
  final DateTime? scheduledTime;
  final String status;
  final DateTime createdAt;

  RouteModel({
    required this.id,
    required this.name,
    required this.ward,
    required this.waypoints,
    this.assignedDriver = '',
    this.scheduledTime,
    this.status = 'assigned',
    required this.createdAt,
  });

  factory RouteModel.fromJson(Map<String, dynamic> json) {
    return RouteModel(
      id: json['id'] ?? '',
      name: json['name'] ?? '',
      ward: json['ward'] ?? '',
      waypoints: json['waypoints'] != null
          ? (json['waypoints'] as List)
              .map((w) => WaypointModel.fromJson(w))
              .toList()
          : [],
      assignedDriver: json['assignedDriver'] ?? '',
      scheduledTime: json['scheduledTime'] != null 
          ? DateTime.parse(json['scheduledTime']) 
          : null,
      status: json['status'] ?? 'assigned',
      createdAt: json['createdAt'] != null 
          ? DateTime.parse(json['createdAt']) 
          : DateTime.now(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'ward': ward,
      'waypoints': waypoints.map((w) => w.toJson()).toList(),
      'assignedDriver': assignedDriver,
      'scheduledTime': scheduledTime?.toIso8601String(),
      'status': status,
      'createdAt': createdAt.toIso8601String(),
    };
  }

  RouteModel copyWith({
    String? id,
    String? name,
    String? ward,
    List<WaypointModel>? waypoints,
    String? assignedDriver,
    DateTime? scheduledTime,
    String? status,
    DateTime? createdAt,
  }) {
    return RouteModel(
      id: id ?? this.id,
      name: name ?? this.name,
      ward: ward ?? this.ward,
      waypoints: waypoints ?? this.waypoints,
      assignedDriver: assignedDriver ?? this.assignedDriver,
      scheduledTime: scheduledTime ?? this.scheduledTime,
      status: status ?? this.status,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  int get completedWaypoints => waypoints.where((w) => w.completed).length;
  int get totalWaypoints => waypoints.length;
  double get progress => totalWaypoints > 0 ? completedWaypoints / totalWaypoints : 0.0;
}
