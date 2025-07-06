// lib/models/device_model.dart

class DeviceModel {
  final String id;
  final String name;
  final String college;
  final String department;
  final String model;
  final String serialNumber;
  final String processor;
  final String storageType;
  final String storageSize;
  final bool hasExtraStorage;
  final String? extraStorageType;
  final String? extraStorageSize;
  final String osVersion;
  final String notes;
  final String labId;
  final String? universityBarcode;
  final String? assetSource; // مصدر الأصل (جامعة أم القرى)
  final String? assetCategory; // فئة الأصل (الآلات والمعدات)
  final String? assetCode; // رمز الأصل
  final bool needsMaintenance;
  final DateTime createdAt;
  final DateTime updatedAt;

  const DeviceModel({
    required this.id,
    required this.name,
    required this.college,
    this.department = '',
    required this.model,
    required this.serialNumber,
    required this.processor,
    required this.storageType,
    required this.storageSize,
    this.hasExtraStorage = false,
    this.extraStorageType,
    this.extraStorageSize,
    required this.osVersion,
    this.notes = '',
    this.labId = '',
    this.universityBarcode,
    this.assetSource,
    this.assetCategory,
    this.assetCode,
    this.needsMaintenance = false,
    required this.createdAt,
    required this.updatedAt,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'college': college,
      'department': department,
      'model': model,
      'serialNumber': serialNumber,
      'processor': processor,
      'storageType': storageType,
      'storageSize': storageSize,
      'hasExtraStorage': hasExtraStorage ? 1 : 0,
      'extraStorageType': extraStorageType,
      'extraStorageSize': extraStorageSize,
      'osVersion': osVersion,
      'notes': notes,
      'labId': labId,
      'universityBarcode': universityBarcode,
      'assetSource': assetSource ?? universityBarcode,
      'assetCategory': assetCategory,
      'assetCode': assetCode ?? universityBarcode,
      'needsMaintenance': needsMaintenance ? 1 : 0,
      'createdAt': createdAt.millisecondsSinceEpoch,
      'updatedAt': updatedAt.millisecondsSinceEpoch,
    };
  }

  factory DeviceModel.fromMap(Map<String, dynamic> map) {
    if (map['id'] == null ||
        (map['id'] as String).isEmpty ||
        map['name'] == null ||
        (map['name'] as String).isEmpty ||
        map['college'] == null ||
        (map['college'] as String).isEmpty) {
      throw ArgumentError('بيانات الجهاز غير صالحة');
    }

    return DeviceModel(
      id: map['id'] as String,
      name: map['name'] as String,
      college: map['college'] as String,
      department: (map['department'] as String?) ?? '',
      model: (map['model'] as String?) ?? '',
      serialNumber: (map['serialNumber'] as String?) ?? '',
      processor: (map['processor'] as String?) ?? '',
      storageType: (map['storageType'] as String?) ?? '',
      storageSize: (map['storageSize'] as String?) ?? '',
      hasExtraStorage:
          (map['hasExtraStorage'] == 1) || (map['hasExtraStorage'] == true),
      extraStorageType: map['extraStorageType'] as String?,
      extraStorageSize: map['extraStorageSize'] as String?,
      osVersion: (map['osVersion'] as String?) ?? '',
      notes: (map['notes'] as String?) ?? '',
      labId: (map['labId'] as String?) ?? '',
      universityBarcode: map['universityBarcode'] as String?,
      assetSource:
          map['assetSource'] as String? ?? map['universityBarcode'] as String?,
      assetCategory: map['assetCategory'] as String?,
      assetCode:
          map['assetCode'] as String? ?? map['universityBarcode'] as String?,
      needsMaintenance:
          (map['needsMaintenance'] == 1) || (map['needsMaintenance'] == true),
      createdAt: map['createdAt'] is int
          ? DateTime.fromMillisecondsSinceEpoch(map['createdAt'] as int)
          : DateTime.now(),
      updatedAt: map['updatedAt'] is int
          ? DateTime.fromMillisecondsSinceEpoch(map['updatedAt'] as int)
          : DateTime.now(),
    );
  }

  DeviceModel copyWith({
    String? id,
    String? name,
    String? college,
    String? department,
    String? model,
    String? serialNumber,
    String? processor,
    String? storageType,
    String? storageSize,
    bool? hasExtraStorage,
    String? extraStorageType,
    String? extraStorageSize,
    String? osVersion,
    String? notes,
    String? labId,
    String? universityBarcode,
    String? assetSource,
    String? assetCategory,
    String? assetCode,
    bool? needsMaintenance,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return DeviceModel(
      id: id ?? this.id,
      name: name ?? this.name,
      college: college ?? this.college,
      department: department ?? this.department,
      model: model ?? this.model,
      serialNumber: serialNumber ?? this.serialNumber,
      processor: processor ?? this.processor,
      storageType: storageType ?? this.storageType,
      storageSize: storageSize ?? this.storageSize,
      hasExtraStorage: hasExtraStorage ?? this.hasExtraStorage,
      extraStorageType: extraStorageType ?? this.extraStorageType,
      extraStorageSize: extraStorageSize ?? this.extraStorageSize,
      osVersion: osVersion ?? this.osVersion,
      notes: notes ?? this.notes,
      labId: labId ?? this.labId,
      universityBarcode: universityBarcode ?? this.universityBarcode,
      assetSource: assetSource ?? this.assetSource,
      assetCategory: assetCategory ?? this.assetCategory,
      assetCode: assetCode ?? this.assetCode,
      needsMaintenance: needsMaintenance ?? this.needsMaintenance,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}
