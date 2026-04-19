import 'driver.dart';

class ComplaintModel {
  final String id;
  final String type;
  final String description;
  final LocationModel location;
  final String status;
  final String raisedBy;
  final String? assignedTo;
  final DateTime createdAt;
  final DateTime? resolvedAt;
  final int? rating;
  final String? feedback;
  final String? imageUrl;

  ComplaintModel({
    required this.id,
    required this.type,
    required this.description,
    required this.location,
    this.status = 'pending',
    required this.raisedBy,
    this.assignedTo,
    required this.createdAt,
    this.resolvedAt,
    this.rating,
    this.feedback,
    this.imageUrl,
  });

  factory ComplaintModel.fromJson(Map<String, dynamic> json) {
    return ComplaintModel(
      id: json['id'] ?? '',
      type: json['type'] ?? '',
      description: json['description'] ?? '',
      location: json['location'] != null 
          ? LocationModel.fromJson(json['location']) 
          : LocationModel(latitude: 0, longitude: 0),
      status: json['status'] ?? 'pending',
      raisedBy: json['raisedBy'] ?? '',
      assignedTo: json['assignedTo'],
      createdAt: json['createdAt'] != null 
          ? DateTime.parse(json['createdAt']) 
          : DateTime.now(),
      resolvedAt: json['resolvedAt'] != null 
          ? DateTime.parse(json['resolvedAt']) 
          : null,
      rating: json['rating'],
      feedback: json['feedback'],
      imageUrl: json['imageUrl'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'type': type,
      'description': description,
      'location': location.toJson(),
      'status': status,
      'raisedBy': raisedBy,
      'assignedTo': assignedTo,
      'createdAt': createdAt.toIso8601String(),
      'resolvedAt': resolvedAt?.toIso8601String(),
      'rating': rating,
      'feedback': feedback,
      'imageUrl': imageUrl,
    };
  }

  ComplaintModel copyWith({
    String? id,
    String? type,
    String? description,
    LocationModel? location,
    String? status,
    String? raisedBy,
    String? assignedTo,
    DateTime? createdAt,
    DateTime? resolvedAt,
    int? rating,
    String? feedback,
    String? imageUrl,
  }) {
    return ComplaintModel(
      id: id ?? this.id,
      type: type ?? this.type,
      description: description ?? this.description,
      location: location ?? this.location,
      status: status ?? this.status,
      raisedBy: raisedBy ?? this.raisedBy,
      assignedTo: assignedTo ?? this.assignedTo,
      createdAt: createdAt ?? this.createdAt,
      resolvedAt: resolvedAt ?? this.resolvedAt,
      rating: rating ?? this.rating,
      feedback: feedback ?? this.feedback,
      imageUrl: imageUrl ?? this.imageUrl,
    );
  }
}
