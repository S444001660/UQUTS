import 'package:flutter/material.dart';

enum LabStatus {
  openWithDevices, // Green - Open with devices registered
  openNoDevices, // Orange - Open but no devices registered
  closed, // Red - Closed with no devices
}

class LabModel {
  final String id;
  final String labNumber;
  final String college;
  final String department;
  final String floorNumber;
  final LabStatus status;
  final String notes;
  final List<String> deviceIds;
  final DateTime createdAt;
  final DateTime updatedAt;
  final String? imagePath;
  final String? locationUrl;
  final double? latitude;
  final double? longitude;

  const LabModel({
    required this.id,
    required this.labNumber,
    required this.college,
    required this.department,
    required this.floorNumber,
    required this.status,
    required this.notes,
    required this.deviceIds,
    required this.createdAt,
    required this.updatedAt,
    this.imagePath,
    this.locationUrl,
    this.latitude,
    this.longitude,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'labNumber': labNumber,
      'college': college,
      'department': department,
      'floorNumber': floorNumber,
      'status': status.toString(),
      'notes': notes,
      'deviceIds': deviceIds,
      'createdAt': createdAt.millisecondsSinceEpoch,
      'updatedAt': updatedAt.millisecondsSinceEpoch,
      'imagePath': imagePath,
      'locationUrl': locationUrl,
      'latitude': latitude,
      'longitude': longitude,
    };
  }

  factory LabModel.fromMap(Map<String, dynamic> map) {
    return LabModel(
      id: map['id'] as String,
      labNumber: map['labNumber'] as String,
      college: map['college'] as String,
      department: map['department'] as String,
      floorNumber: map['floorNumber'] as String,
      status: LabStatus.values.firstWhere(
        (e) => e.toString() == map['status'],
        orElse: () => LabStatus.closed,
      ),
      notes: map['notes'] ?? '',
      deviceIds: List<String>.from(map['deviceIds'] ?? []),
      createdAt: DateTime.fromMillisecondsSinceEpoch(map['createdAt'] as int),
      updatedAt: DateTime.fromMillisecondsSinceEpoch(map['updatedAt'] as int),
      imagePath: map['imagePath'] as String?,
      locationUrl: map['locationUrl'] as String?,
      latitude: map['latitude'] as double?,
      longitude: map['longitude'] as double?,
    );
  }

  LabModel copyWith({
    String? id,
    String? labNumber,
    String? college,
    String? department,
    String? floorNumber,
    LabStatus? status,
    String? notes,
    List<String>? deviceIds,
    DateTime? createdAt,
    DateTime? updatedAt,
    String? imagePath,
    String? locationUrl,
    double? latitude,
    double? longitude,
  }) {
    return LabModel(
      id: id ?? this.id,
      labNumber: labNumber ?? this.labNumber,
      college: college ?? this.college,
      department: department ?? this.department,
      floorNumber: floorNumber ?? this.floorNumber,
      status: status ?? this.status,
      notes: notes ?? this.notes,
      deviceIds: deviceIds ?? this.deviceIds,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      imagePath: imagePath ?? this.imagePath,
      locationUrl: locationUrl ?? this.locationUrl,
      latitude: latitude ?? this.latitude,
      longitude: longitude ?? this.longitude,
    );
  }

  // Helper method to get status color
  Color getStatusColor(BuildContext context) {
    switch (status) {
      case LabStatus.openWithDevices:
        return Colors.green;
      case LabStatus.openNoDevices:
        return Colors.orange;
      case LabStatus.closed:
        return Colors.red;
    }
  }

  // Helper method to get status text
  String getStatusText() {
    switch (status) {
      case LabStatus.openWithDevices:
        return 'مفتوح - يحتوي على أجهزة';
      case LabStatus.openNoDevices:
        return 'مفتوح - لا توجد أجهزة';
      case LabStatus.closed:
        return 'مغلق';
    }
  }
}
