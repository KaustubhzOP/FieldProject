import 'package:cloud_firestore/cloud_firestore.dart';

class UserModel {
  final String id;
  final String email;
  final String name;
  final String phone;
  final String role;
  final String address;
  final String ward;
  final DateTime createdAt;
  
  // Home Verification Fields
  final double? homeLat;
  final double? homeLng;
  final double? pendingLat;
  final double? pendingLng;
  final String homeStatus; // 'none', 'pending_approval', 'approved', 'pending_removal'

  UserModel({
    required this.id,
    required this.email,
    required this.name,
    required this.phone,
    required this.role,
    this.address = '',
    this.ward = '',
    required this.createdAt,
    this.homeLat,
    this.homeLng,
    this.pendingLat,
    this.pendingLng,
    this.homeStatus = 'none',
  });

  factory UserModel.fromJson(Map<String, dynamic> json) {
    return UserModel(
      id: json['id'] ?? '',
      email: json['email'] ?? '',
      name: json['name'] ?? '',
      phone: json['phone'] ?? '',
      role: json['role'] ?? 'resident',
      address: json['address'] ?? '',
      ward: json['ward'] ?? '',
      createdAt: _parseDate(json['createdAt']),
      homeLat: (json['homeLat'] as num?)?.toDouble(),
      homeLng: (json['homeLng'] as num?)?.toDouble(),
      pendingLat: (json['pendingLat'] as num?)?.toDouble(),
      pendingLng: (json['pendingLng'] as num?)?.toDouble(),
      homeStatus: json['homeStatus'] ?? 'none',
    );
  }

  static DateTime _parseDate(dynamic value) {
    if (value == null) return DateTime.now();
    if (value is Timestamp) return value.toDate();
    if (value is String) {
      try { return DateTime.parse(value); } catch (_) { return DateTime.now(); }
    }
    return DateTime.now();
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'email': email,
      'name': name,
      'phone': phone,
      'role': role,
      'address': address,
      'ward': ward,
      'createdAt': createdAt.toIso8601String(),
      'homeLat': homeLat,
      'homeLng': homeLng,
      'pendingLat': pendingLat,
      'pendingLng': pendingLng,
      'homeStatus': homeStatus,
    };
  }

  UserModel copyWith({
    String? id,
    String? email,
    String? name,
    String? phone,
    String? role,
    String? address,
    String? ward,
    DateTime? createdAt,
    double? homeLat,
    double? homeLng,
    double? pendingLat,
    double? pendingLng,
    String? homeStatus,
  }) {
    return UserModel(
      id: id ?? this.id,
      email: email ?? this.email,
      name: name ?? this.name,
      phone: phone ?? this.phone,
      role: role ?? this.role,
      address: address ?? this.address,
      ward: ward ?? this.ward,
      createdAt: createdAt ?? this.createdAt,
      homeLat: homeLat ?? this.homeLat,
      homeLng: homeLng ?? this.homeLng,
      pendingLat: pendingLat ?? this.pendingLat,
      pendingLng: pendingLng ?? this.pendingLng,
      homeStatus: homeStatus ?? this.homeStatus,
    );
  }
}
