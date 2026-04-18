class LocationModel {
  final double latitude;
  final double longitude;
  final String? address;

  LocationModel({
    required this.latitude,
    required this.longitude,
    this.address,
  });

  factory LocationModel.fromJson(Map<String, dynamic> json) {
    return LocationModel(
      latitude: json['latitude']?.toDouble() ?? 0.0,
      longitude: json['longitude']?.toDouble() ?? 0.0,
      address: json['address'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'latitude': latitude,
      'longitude': longitude,
      'address': address,
    };
  }

  @override
  String toString() {
    return 'LocationModel(lat: $latitude, lng: $longitude)';
  }
}

class DriverModel {
  final String id;
  final String userId;
  final String vehicleNo;
  final String routeId;
  final String status;
  final LocationModel? lastLocation;
  final DateTime? dutyStartTime;
  final bool isOnDuty;

  DriverModel({
    required this.id,
    required this.userId,
    required this.vehicleNo,
    this.routeId = '',
    this.status = 'off_duty',
    this.lastLocation,
    this.dutyStartTime,
    this.isOnDuty = false,
  });

  factory DriverModel.fromJson(Map<String, dynamic> json) {
    return DriverModel(
      id: json['id'] ?? '',
      userId: json['userId'] ?? '',
      vehicleNo: json['vehicleNo'] ?? '',
      routeId: json['routeId'] ?? '',
      status: json['status'] ?? 'off_duty',
      lastLocation: json['lastLocation'] != null 
          ? LocationModel.fromJson(json['lastLocation']) 
          : null,
      dutyStartTime: json['dutyStartTime'] != null 
          ? DateTime.parse(json['dutyStartTime']) 
          : null,
      isOnDuty: json['isOnDuty'] ?? false,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'userId': userId,
      'vehicleNo': vehicleNo,
      'routeId': routeId,
      'status': status,
      'lastLocation': lastLocation?.toJson(),
      'dutyStartTime': dutyStartTime?.toIso8601String(),
      'isOnDuty': isOnDuty,
    };
  }

  DriverModel copyWith({
    String? id,
    String? userId,
    String? vehicleNo,
    String? routeId,
    String? status,
    LocationModel? lastLocation,
    DateTime? dutyStartTime,
    bool? isOnDuty,
  }) {
    return DriverModel(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      vehicleNo: vehicleNo ?? this.vehicleNo,
      routeId: routeId ?? this.routeId,
      status: status ?? this.status,
      lastLocation: lastLocation ?? this.lastLocation,
      dutyStartTime: dutyStartTime ?? this.dutyStartTime,
      isOnDuty: isOnDuty ?? this.isOnDuty,
    );
  }
}
