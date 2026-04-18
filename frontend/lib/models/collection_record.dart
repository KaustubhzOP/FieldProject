class CollectionRecordModel {
  final String id;
  final String routeId;
  final String driverId;
  final DateTime startTime;
  final DateTime? endTime;
  final String status;
  final int pointsCollected;
  final int totalPoints;
  final Map<String, dynamic>? feedback;

  CollectionRecordModel({
    required this.id,
    required this.routeId,
    required this.driverId,
    required this.startTime,
    this.endTime,
    this.status = 'in_progress',
    this.pointsCollected = 0,
    this.totalPoints = 0,
    this.feedback,
  });

  factory CollectionRecordModel.fromJson(Map<String, dynamic> json) {
    return CollectionRecordModel(
      id: json['id'] ?? '',
      routeId: json['routeId'] ?? '',
      driverId: json['driverId'] ?? '',
      startTime: json['startTime'] != null 
          ? DateTime.parse(json['startTime']) 
          : DateTime.now(),
      endTime: json['endTime'] != null 
          ? DateTime.parse(json['endTime']) 
          : null,
      status: json['status'] ?? 'in_progress',
      pointsCollected: json['pointsCollected'] ?? 0,
      totalPoints: json['totalPoints'] ?? 0,
      feedback: json['feedback'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'routeId': routeId,
      'driverId': driverId,
      'startTime': startTime.toIso8601String(),
      'endTime': endTime?.toIso8601String(),
      'status': status,
      'pointsCollected': pointsCollected,
      'totalPoints': totalPoints,
      'feedback': feedback,
    };
  }

  CollectionRecordModel copyWith({
    String? id,
    String? routeId,
    String? driverId,
    DateTime? startTime,
    DateTime? endTime,
    String? status,
    int? pointsCollected,
    int? totalPoints,
    Map<String, dynamic>? feedback,
  }) {
    return CollectionRecordModel(
      id: id ?? this.id,
      routeId: routeId ?? this.routeId,
      driverId: driverId ?? this.driverId,
      startTime: startTime ?? this.startTime,
      endTime: endTime ?? this.endTime,
      status: status ?? this.status,
      pointsCollected: pointsCollected ?? this.pointsCollected,
      totalPoints: totalPoints ?? this.totalPoints,
      feedback: feedback ?? this.feedback,
    );
  }

  double get progress => totalPoints > 0 ? pointsCollected / totalPoints : 0.0;
  Duration? get duration => endTime != null ? endTime!.difference(startTime) : null;
}
