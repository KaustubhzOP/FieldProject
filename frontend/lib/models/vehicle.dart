import 'driver.dart';

class VehicleModel {
  final String id;
  final String type;
  final String registrationNo;
  final LocationModel? currentLocation;
  final double capacity;
  final String status;
  final String driverId;

  VehicleModel({
    required this.id,
    required this.type,
    required this.registrationNo,
    this.currentLocation,
    this.capacity = 1000,
    this.status = 'active',
    this.driverId = '',
  });

  factory VehicleModel.fromJson(Map<String, dynamic> json) {
    return VehicleModel(
      id: json['id'] ?? '',
      type: json['type'] ?? 'truck',
      registrationNo: json['registrationNo'] ?? '',
      currentLocation: json['currentLocation'] != null 
          ? LocationModel.fromJson(json['currentLocation']) 
          : null,
      capacity: json['capacity']?.toDouble() ?? 1000,
      status: json['status'] ?? 'active',
      driverId: json['driverId'] ?? '',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'type': type,
      'registrationNo': registrationNo,
      'currentLocation': currentLocation?.toJson(),
      'capacity': capacity,
      'status': status,
      'driverId': driverId,
    };
  }

  VehicleModel copyWith({
    String? id,
    String? type,
    String? registrationNo,
    LocationModel? currentLocation,
    double? capacity,
    String? status,
    String? driverId,
  }) {
    return VehicleModel(
      id: id ?? this.id,
      type: type ?? this.type,
      registrationNo: registrationNo ?? this.registrationNo,
      currentLocation: currentLocation ?? this.currentLocation,
      capacity: capacity ?? this.capacity,
      status: status ?? this.status,
      driverId: driverId ?? this.driverId,
    );
  }
}
