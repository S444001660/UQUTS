import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/foundation.dart' show debugPrint;
import 'dart:io';
import 'package:path/path.dart' as path;
import 'package:uuid/uuid.dart';

import '../models/lab_model.dart';
import '../models/device_model.dart';

//------------------------------------------------------------------------------

/// كلاس خدمي (Service Class) للتعامل مع عمليات قاعدة بيانات Firebase Firestore و Storage.
/// يوفر دوال ثابتة (static) لتنفيذ عمليات CRUD (إنشاء، قراءة، تحديث، حذف) للمعامل والأجهزة.
class FirebaseDatabaseService {
  // --- تهيئة خدمات Firebase ---
  static final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  static final FirebaseStorage _storage = FirebaseStorage.instance;

  // ---------------------------------------------------------------------------
  // عمليات المعامل (Labs)
  // ---------------------------------------------------------------------------

  /// إضافة معمل جديد أو تحديث بيانات معمل موجود.
  static Future<void> addOrUpdateLab(LabModel lab) async {
    try {
      // التحقق من صحة البيانات الأساسية قبل إرسالها.
      if (lab.id.isEmpty ||
          lab.labNumber.isEmpty ||
          lab.college.isEmpty ||
          lab.department.isEmpty) {
        throw Exception('بيانات المعمل الأساسية غير صالحة أو مفقودة.');
      }

      // تحويل LabModel إلى Map جاهزة لـ Firestore.
      final Map<String, dynamic> labData = lab.toMap();

      // إذا كان هناك imagePath محلي (وليس URL)، يتم رفعه إلى Storage.
      if (lab.imagePath != null &&
          lab.imagePath!.isNotEmpty &&
          !lab.imagePath!.startsWith('http')) {
        final imageUrl = await uploadImageToFirebaseStorage(
            File(lab.imagePath!), 'lab_images/${lab.id}');
        labData['imagePath'] = imageUrl;
      }

      // إضافة أو تحديث المستند في مجموعة 'labs' باستخدام الـ ID الخاص بالمعمل.
      // SetOptions(merge: true) تضمن عدم حذف الحقول الموجودة عند التحديث.
      await _firestore
          .collection('labs')
          .doc(lab.id)
          .set(labData, SetOptions(merge: true));
      debugPrint('تم إضافة/تحديث المعمل بنجاح: ${lab.labNumber}');
    } catch (e) {
      debugPrint('خطأ في إضافة/تحديث المعمل: $e');
      rethrow; // إعادة رمي الخطأ للتعامل معه في واجهة المستخدم.
    }
  }

  //------------------------------------------------------------------------------

  /// حذف معمل وجميع البيانات المرتبطة به.
  static Future<void> deleteLab(String labId) async {
    try {
      // حذف مستند المعمل من Firestore.
      await _firestore.collection('labs').doc(labId).delete();

      // تحديث الأجهزة المرتبطة: إزالة مرجع labId.
      // استخدام Batch Write لتحسين الأداء عند تحديث عدة مستندات دفعة واحدة.
      final devicesSnapshot = await _firestore
          .collection('devices')
          .where('labId', isEqualTo: labId)
          .get();
      final batch = _firestore.batch();
      for (var doc in devicesSnapshot.docs) {
        batch.update(doc.reference, {'labId': null}); // تعيين labId إلى null.
      }
      await batch.commit();

      // حذف الصورة المرتبطة بالمعمل من Storage (اختياري).
      await _deleteImageFromFirebaseStorage('lab_images/$labId');

      debugPrint('تم حذف المعمل بنجاح: $labId');
    } catch (e) {
      debugPrint('خطأ في حذف المعمل: $e');
      rethrow;
    }
  }

  //------------------------------------------------------------------------------

  /// تحديث حالة المعمل تلقائيًا بناءً على عدد الأجهزة فيه.
  static Future<void> updateLabStatus(String labId) async {
    try {
      final devicesSnapshot = await _firestore
          .collection('devices')
          .where('labId', isEqualTo: labId)
          .get();
      final deviceCount = devicesSnapshot.docs.length;

      // تحديد الحالة الجديدة بناءً على وجود أجهزة.
      final newStatus = deviceCount > 0
          ? LabStatus.openWithDevices.name
          : LabStatus.openNoDevices.name;

      // تحديث حقل الحالة وتاريخ التحديث في مستند المعمل.
      await _firestore.collection('labs').doc(labId).update({
        'status': newStatus,
        'updatedAt': Timestamp.fromDate(DateTime.now()),
      });
      debugPrint('تم تحديث حالة المعمل $labId إلى $newStatus');
    } catch (e) {
      debugPrint('خطأ في تحديث حالة المعمل: $e');
      rethrow;
    }
  }

  //------------------------------------------------------------------------------

  /// جلب قائمة بجميع المعامل من قاعدة البيانات.
  static Future<List<LabModel>> getLabs() async {
    try {
      final QuerySnapshot snapshot = await _firestore.collection('labs').get();
      return snapshot.docs
          .map((doc) => LabModel.fromMap(doc.data() as Map<String, dynamic>))
          .toList();
    } catch (e) {
      debugPrint('خطأ في جلب المعامل: $e');
      return [];
    }
  }

  //------------------------------------------------------------------------------

  /// جلب قائمة المعامل التي تنتمي إلى كلية معينة.
  static Future<List<LabModel>> getLabsByCollege(String college) async {
    try {
      final QuerySnapshot snapshot = await _firestore
          .collection('labs')
          .where('college', isEqualTo: college)
          .get();
      return snapshot.docs
          .map((doc) => LabModel.fromMap(doc.data() as Map<String, dynamic>))
          .toList();
    } catch (e) {
      debugPrint('خطأ في جلب المعامل حسب الكلية: $e');
      return [];
    }
  }

  //------------------------------------------------------------------------------

  /// جلب بيانات معمل واحد باستخدام معرفه (ID).
  static Future<LabModel?> getLabById(String labId) async {
    try {
      final DocumentSnapshot doc =
          await _firestore.collection('labs').doc(labId).get();
      if (doc.exists && doc.data() != null) {
        return LabModel.fromMap(doc.data() as Map<String, dynamic>);
      }
      return null;
    } catch (e) {
      debugPrint('خطأ في جلب المعمل بواسطة ID: $e');
      return null;
    }
  }

  // ---------------------------------------------------------------------------
  // عمليات الأجهزة (Devices)
  // ---------------------------------------------------------------------------

  /// إضافة جهاز جديد أو تحديث بيانات جهاز موجود.
  static Future<void> addOrUpdateDevice(DeviceModel device) async {
    try {
      final Map<String, dynamic> deviceData = device.toMap();

      if (device.imagePath != null &&
          device.imagePath!.isNotEmpty &&
          !device.imagePath!.startsWith('http')) {
        final imageUrl = await uploadImageToFirebaseStorage(
            File(device.imagePath!), 'device_images/${device.id}');
        deviceData['imagePath'] = imageUrl;
      }

      await _firestore
          .collection('devices')
          .doc(device.id)
          .set(deviceData, SetOptions(merge: true));

      // تحديث حالة المعمل المرتبط بالجهاز بعد الإضافة أو التحديث.
      await updateLabStatus(device.labId);
      debugPrint('تم إضافة/تحديث الجهاز بنجاح: ${device.name}');
    } catch (e) {
      debugPrint('خطأ في إضافة/تحديث الجهاز: $e');
      rethrow;
    }
  }

  //------------------------------------------------------------------------------

  /// حذف جهاز وتحديث حالة المعمل المرتبط به.
  static Future<void> deleteDevice(String deviceId) async {
    try {
      // الحصول على بيانات الجهاز قبل الحذف لمعرفة المعمل المرتبط به.
      final deviceDoc =
          await _firestore.collection('devices').doc(deviceId).get();
      String? labId;
      String? imagePath;
      if (deviceDoc.exists && deviceDoc.data() != null) {
        final data = deviceDoc.data() as Map<String, dynamic>;
        labId = data['labId'];
        imagePath = data['imagePath'];
      }

      await _firestore.collection('devices').doc(deviceId).delete();

      // حذف الصورة المرتبطة بالجهاز من Storage.
      if (imagePath != null && imagePath.isNotEmpty) {
        try {
          final storageRef = _storage.refFromURL(imagePath);
          await storageRef.delete();
        } catch (e) {
          debugPrint(
              'خطأ في حذف صورة الجهاز من Storage (قد لا تكون موجودة): $e');
        }
      }

      // تحديث حالة المعمل إذا كان الجهاز مرتبطًا بمعمل.
      if (labId != null) {
        await updateLabStatus(labId);
      }
      debugPrint('تم حذف الجهاز بنجاح: $deviceId');
    } catch (e) {
      debugPrint('خطأ في حذف الجهاز: $e');
      rethrow;
    }
  }

  //------------------------------------------------------------------------------

  /// جلب بيانات جهاز واحد باستخدام معرفه (ID).
  static Future<DeviceModel?> getDeviceById(String deviceId) async {
    try {
      final DocumentSnapshot doc =
          await _firestore.collection('devices').doc(deviceId).get();
      if (doc.exists && doc.data() != null) {
        return DeviceModel.fromMap(doc.data() as Map<String, dynamic>);
      }
      return null;
    } catch (e) {
      debugPrint('خطأ في جلب الجهاز بواسطة ID: $e');
      return null;
    }
  }

  //------------------------------------------------------------------------------

  /// جلب قائمة بجميع الأجهزة من قاعدة البيانات.
  static Future<List<DeviceModel>> getDevices() async {
    try {
      final QuerySnapshot snapshot =
          await _firestore.collection('devices').get();
      return snapshot.docs
          .map((doc) => DeviceModel.fromMap(doc.data() as Map<String, dynamic>))
          .toList();
    } catch (e) {
      debugPrint('خطأ في جلب الأجهزة: $e');
      return [];
    }
  }

  //------------------------------------------------------------------------------

  /// جلب قائمة الأجهزة الموجودة في معمل معين.
  static Future<List<DeviceModel>> getDevicesForLab(String labId) async {
    try {
      final QuerySnapshot snapshot = await _firestore
          .collection('devices')
          .where('labId', isEqualTo: labId)
          .get();
      return snapshot.docs
          .map((doc) => DeviceModel.fromMap(doc.data() as Map<String, dynamic>))
          .toList();
    } catch (e) {
      debugPrint('خطأ في جلب الأجهزة للمعمل: $e');
      return [];
    }
  }

  //------------------------------------------------------------------------------

  /// دالة بحث مبسطة عن الأجهزة (تحتاج لتحسين للبحث الكامل).
  static Future<List<DeviceModel>> searchDevices(String query) async {
    try {
      // البحث في Firestore يتطلب استعلامات دقيقة أو استخدام خدمات بحث خارجية.
      // هذا مثال للبحث في حقلين ودمج النتائج.
      final QuerySnapshot nameSnapshot = await _firestore
          .collection('devices')
          .where('name', isGreaterThanOrEqualTo: query)
          .where('name', isLessThanOrEqualTo: query + '\uf8ff')
          .get();

      final QuerySnapshot serialSnapshot = await _firestore
          .collection('devices')
          .where('serialNumber', isGreaterThanOrEqualTo: query)
          .where('serialNumber', isLessThanOrEqualTo: query + '\uf8ff')
          .get();

      // دمج النتائج وإزالة التكرارات باستخدام Set.
      final Set<DeviceModel> uniqueDevices = {};
      nameSnapshot.docs.forEach((doc) => uniqueDevices
          .add(DeviceModel.fromMap(doc.data() as Map<String, dynamic>)));
      serialSnapshot.docs.forEach((doc) => uniqueDevices
          .add(DeviceModel.fromMap(doc.data() as Map<String, dynamic>)));

      return uniqueDevices.toList();
    } catch (e) {
      debugPrint('خطأ في البحث عن الأجهزة: $e');
      return [];
    }
  }

  //------------------------------------------------------------------------------

  /// التحقق من وجود الرقم التسلسلي مسبقًا في قاعدة البيانات.
  static Future<bool> serialNumberExists(String serialNumber,
      {String? excludeId}) async {
    try {
      Query query = _firestore
          .collection('devices')
          .where('serialNumber', isEqualTo: serialNumber);
      if (excludeId != null) {
        // إذا كنا نتحقق من التكرار أثناء التحديث، نستبعد الجهاز الحالي من البحث.
        query = query.where('id', isNotEqualTo: excludeId);
      }
      final QuerySnapshot snapshot = await query.get();
      return snapshot.docs.isNotEmpty;
    } catch (e) {
      debugPrint('خطأ في التحقق من وجود الرقم التسلسلي: $e');
      return false;
    }
  }

  //------------------------------------------------------------------------------

  /// جلب جهاز باستخدام الباركود الجامعي أو رمز الأصل.
  static Future<DeviceModel?> getDeviceByBarcode(
      String barcode, String assetCode) async {
    try {
      // Firestore لا يدعم OR مباشرة بين حقول مختلفة، لذا نقوم باستعلامين.
      final QuerySnapshot barcodeSnapshot = await _firestore
          .collection('devices')
          .where('universityBarcode', isEqualTo: barcode)
          .limit(1)
          .get();
      if (barcodeSnapshot.docs.isNotEmpty) {
        return DeviceModel.fromMap(
            barcodeSnapshot.docs.first.data() as Map<String, dynamic>);
      }

      final QuerySnapshot assetCodeSnapshot = await _firestore
          .collection('devices')
          .where('assetCode', isEqualTo: assetCode)
          .limit(1)
          .get();
      if (assetCodeSnapshot.docs.isNotEmpty) {
        return DeviceModel.fromMap(
            assetCodeSnapshot.docs.first.data() as Map<String, dynamic>);
      }
      return null;
    } catch (e) {
      debugPrint('خطأ في جلب الجهاز بواسطة الباركود/Asset Code: $e');
      return null;
    }
  }

  // ---------------------------------------------------------------------------
  // دوال مساعدة لـ Firebase Storage (لتخزين الصور)
  // ---------------------------------------------------------------------------

  /// دالة عامة لرفع ملف صورة إلى Firebase Storage.
  static Future<String?> uploadImageToFirebaseStorage(
      File imageFile, String storagePath) async {
    try {
      final ref = _storage.ref().child(storagePath);
      // إضافة metadata فارغة لتجنب NullPointerException.
      final uploadTask = ref.putFile(imageFile, SettableMetadata());
      final snapshot = await uploadTask.whenComplete(() {});
      final downloadUrl = await snapshot.ref.getDownloadURL();
      debugPrint('تم رفع الصورة بنجاح: $downloadUrl');
      return downloadUrl;
    } catch (e) {
      debugPrint('خطأ في رفع الصورة إلى Storage: $e');
      return null;
    }
  }

  //------------------------------------------------------------------------------

  /// دالة مساعدة خاصة لحذف صورة من Firebase Storage.
  static Future<void> _deleteImageFromFirebaseStorage(
      String storagePath) async {
    try {
      final ref = _storage.ref().child(storagePath);
      await ref.delete();
      debugPrint('تم حذف الصورة من Storage: $storagePath');
    } catch (e) {
      // نتجاهل الخطأ إذا كانت الصورة غير موجودة أصلاً.
      debugPrint('خطأ في حذف الصورة من Storage (قد لا تكون موجودة): $e');
    }
  }

  // ---------------------------------------------------------------------------
  // دوال مساعدة أخرى (توليد ID)
  // ---------------------------------------------------------------------------

  /// دالة مساعدة لتوليد معرف فريد عالميًا (UUID).
  static String generateUniqueId() {
    return const Uuid().v4();
  }
}
