// استيراد المكتبات والملفات الضرورية
import 'package:cloud_firestore/cloud_firestore.dart'; // مكتبة Firebase Firestore للتعامل مع قاعدة البيانات

//------------------------------------------------------------------------------

/// نموذج بيانات (Data Model) يمثل "الجهاز" داخل النظام.
/// هذا الكلاس هو المخطط الهندسي (Blueprint) الذي يحدد خصائص ووظائف أي جهاز.
class DeviceModel {
  // --- الخصائص الأساسية للجهاز ---
  final String id; // معرف فريد للجهاز
  final String name; // اسم الجهاز
  final String college; // اسم الكلية التابعة للجهاز
  final String department; // القسم (اختياري)
  final String model; // موديل الجهاز
  final String serialNumber; // الرقم التسلسلي
  final String processor; // نوع المعالج
  final String storageType; // نوع التخزين الأساسي (HDD أو SSD)
  final String storageSize; // حجم التخزين الأساسي

  // --- معلومات التخزين الإضافي إن وُجد ---
  final bool hasExtraStorage; // هل يوجد تخزين إضافي؟
  final String? extraStorageType; // نوع التخزين الإضافي
  final String? extraStorageSize; // حجم التخزين الإضافي

  // --- خصائص أخرى ---
  final String osVersion; // إصدار نظام التشغيل
  final String notes; // ملاحظات (افتراضيًا فارغة)
  final String labId; // معرف المعمل المرتبط بالجهاز
  final String? universityBarcode; // باركود الجامعة
  final String? assetSource; // مصدر الأصل (مثلاً: جامعة أم القرى)
  final String? assetCategory; // فئة الأصل (مثلاً: آلات ومعدات)
  final String? assetCode; // رمز الأصل
  final bool needsMaintenance; // هل الجهاز يحتاج صيانة؟
  final DateTime createdAt; // وقت إنشاء السجل
  final DateTime updatedAt; // آخر تحديث للسجل
  final String? imagePath; // مسار الصورة المرتبطة بالجهاز

  //------------------------------------------------------------------------------

  /// البناء (Constructor) لإنشاء كائن جديد من نوع DeviceModel.
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
    this.imagePath,
  });

  //------------------------------------------------------------------------------

  /// دالة لتحويل كائن DeviceModel إلى خريطة (Map) من نوع <String, dynamic>.
  /// هذه الصيغة مناسبة لتخزين البيانات في قاعدة بيانات Firestore.
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
      'hasExtraStorage': hasExtraStorage,
      'extraStorageType': extraStorageType,
      'extraStorageSize': extraStorageSize,
      'osVersion': osVersion,
      'notes': notes,
      'labId': labId,
      'universityBarcode': universityBarcode,
      'assetSource': assetSource,
      'assetCategory': assetCategory,
      'assetCode': assetCode,
      'needsMaintenance': needsMaintenance,
      'createdAt': Timestamp.fromDate(createdAt), // تحويل DateTime إلى Timestamp
      'updatedAt': Timestamp.fromDate(updatedAt), // تحويل DateTime إلى Timestamp
      'imagePath': imagePath,
    };
  }

  //------------------------------------------------------------------------------

  /// دالة مصنع (Factory Constructor) لبناء كائن DeviceModel من خريطة (Map).
  /// تُستخدم عند قراءة البيانات من Firestore وتحويلها إلى كائن Dart.
  factory DeviceModel.fromMap(Map<String, dynamic> map) {
    // التحقق من وجود الحقول الأساسية لضمان سلامة البيانات.
    if (map['id'] == null ||
        (map['id'] as String).isEmpty ||
        map['name'] == null ||
        (map['name'] as String).isEmpty ||
        map['college'] == null ||
        (map['college'] as String).isEmpty) {
      throw ArgumentError('بيانات الجهاز غير صالحة');
    }

    // دالة مساعدة داخلية لتحويل أنواع مختلفة من بيانات التاريخ إلى DateTime.
    DateTime _parseDateTime(dynamic value) {
      if (value is Timestamp) {
        return value.toDate();
      } else if (value is int) {
        return DateTime.fromMillisecondsSinceEpoch(value);
      }
      return DateTime.now(); // قيمة احتياطية إذا كان النوع غير معروف.
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
      // التعامل مع القيم المنطقية (bool) التي قد تأتي بصيغ مختلفة.
      hasExtraStorage: (map['hasExtraStorage'] is bool)
          ? map['hasExtraStorage'] as bool
          : (map['hasExtraStorage'] == 1),
      extraStorageType: map['extraStorageType'] as String?,
      extraStorageSize: map['extraStorageSize'] as String?,
      osVersion: (map['osVersion'] as String?) ?? '',
      notes: (map['notes'] as String?) ?? '',
      labId: (map['labId'] as String?) ?? '',
      universityBarcode: map['universityBarcode'] as String?,
      assetSource: map['assetSource'] as String?,
      assetCategory: map['assetCategory'] as String?,
      assetCode: map['assetCode'] as String?,
      needsMaintenance: (map['needsMaintenance'] is bool)
          ? map['needsMaintenance'] as bool
          : (map['needsMaintenance'] == 1),
      createdAt: _parseDateTime(map['createdAt']), // استخدام الدالة المساعدة.
      updatedAt: _parseDateTime(map['updatedAt']), // استخدام الدالة المساعدة.
      imagePath: map['imagePath'] as String?,
    );
  }

  //------------------------------------------------------------------------------

  /// دالة لإنشاء نسخة جديدة من الجهاز مع تعديل بعض القيم فقط.
  /// مفيدة للحفاظ على البيانات غير القابلة للتغيير (immutability).
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
    String? imagePath,
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
      imagePath: imagePath ?? this.imagePath,
    );
  }
}
