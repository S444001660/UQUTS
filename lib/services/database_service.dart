import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import '../models/lab_model.dart';
import '../models/device_model.dart';
import 'dart:io';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as path;
import 'package:uuid/uuid.dart';
import 'package:flutter/foundation.dart' show debugPrint;

class DatabaseService {
  static Database? _database;
  static const String dbName = 'labs_manager.db';

  static Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDB();
    return _database!;
  }

  static Future<Database> _initDB() async {
    final dbPath = await getDatabasesPath();
    final path = join(dbPath, dbName);

    return openDatabase(
      path,
      version: 9,
      onCreate: (db, version) async {
        // Create labs table with all columns
        await db.execute('''
          CREATE TABLE labs(
            id TEXT PRIMARY KEY,
            labNumber TEXT NOT NULL,
            college TEXT NOT NULL,
            department TEXT NOT NULL,
            floorNumber TEXT NOT NULL,
            status TEXT NOT NULL,
            notes TEXT,
            imagePath TEXT,
            locationUrl TEXT,
            latitude REAL,
            longitude REAL,
            createdAt INTEGER NOT NULL,
            updatedAt INTEGER NOT NULL
          )
        ''');

        // Create devices table
        await db.execute('''
          CREATE TABLE devices(
            id TEXT PRIMARY KEY,
            name TEXT NOT NULL,
            college TEXT NOT NULL,
            department TEXT,
            model TEXT NOT NULL,
            serialNumber TEXT NOT NULL UNIQUE,
            processor TEXT NOT NULL,
            storageType TEXT NOT NULL,
            storageSize TEXT NOT NULL,
            hasExtraStorage INTEGER NOT NULL DEFAULT 0,
            extraStorageType TEXT,
            extraStorageSize TEXT,
            osVersion TEXT NOT NULL,
            notes TEXT,
            labId TEXT,
            universityBarcode TEXT UNIQUE,
            assetSource TEXT,
            assetCategory TEXT,
            assetCode TEXT,
            needsMaintenance INTEGER NOT NULL DEFAULT 0,
            createdAt INTEGER NOT NULL,
            updatedAt INTEGER NOT NULL,
            FOREIGN KEY (labId) REFERENCES labs (id)
              ON DELETE SET NULL
              ON UPDATE CASCADE
          )
        ''');
      },
      onUpgrade: (db, oldVersion, newVersion) async {
        // Comprehensive migration steps
        try {
          // Ensure imagePath column exists
          await db.execute('''
            ALTER TABLE labs
            ADD COLUMN imagePath TEXT
          ''');
        } catch (e) {
          debugPrint('Error adding imagePath column (might already exist): $e');
        }

        try {
          // Add locationUrl column
          await db.execute('''
            ALTER TABLE labs
            ADD COLUMN locationUrl TEXT
          ''');
        } catch (e) {
          debugPrint(
              'Error adding locationUrl column (might already exist): $e');
        }

        try {
          // Add latitude column
          await db.execute('''
            ALTER TABLE labs
            ADD COLUMN latitude REAL
          ''');
        } catch (e) {
          debugPrint('Error adding latitude column (might already exist): $e');
        }

        try {
          // Add longitude column
          await db.execute('''
            ALTER TABLE labs
            ADD COLUMN longitude REAL
          ''');
        } catch (e) {
          debugPrint('Error adding longitude column (might already exist): $e');
        }

        // New columns for devices
        try {
          // إضافة assetSource
          await db.execute('''
            ALTER TABLE devices
            ADD COLUMN IF NOT EXISTS assetSource TEXT
          ''');
        } catch (e) {
          debugPrint('Error adding assetSource column: $e');
        }

        try {
          // إضافة assetCategory
          await db.execute('''
            ALTER TABLE devices
            ADD COLUMN IF NOT EXISTS assetCategory TEXT
          ''');
        } catch (e) {
          debugPrint('Error adding assetCategory column: $e');
        }

        // Previous migration steps
        if (oldVersion < 2) {
          // Add needsMaintenance column to devices table
          await db.execute('''
            ALTER TABLE devices
            ADD COLUMN IF NOT EXISTS needsMaintenance INTEGER NOT NULL DEFAULT 0
          ''');
        }

        if (oldVersion < 4) {
          // Add department column to devices table
          try {
            await db.execute('''
              ALTER TABLE devices
              ADD COLUMN IF NOT EXISTS department TEXT
            ''');
          } catch (e) {
            debugPrint('Error adding department column: $e');
          }
        }

        if (oldVersion < 5) {
          // Add extraStorageType and extraStorageSize columns to devices table
          try {
            await db.execute('''
              ALTER TABLE devices
              ADD COLUMN IF NOT EXISTS extraStorageType TEXT
            ''');
            await db.execute('''
              ALTER TABLE devices
              ADD COLUMN IF NOT EXISTS extraStorageSize TEXT
            ''');
          } catch (e) {
            debugPrint('Error adding extra storage columns: $e');
          }
        }
      },
    );
  }

  // Modify addLab method to handle null values more carefully
  static Future<void> addLab(LabModel lab) async {
    try {
      // التحقق من صحة البيانات قبل الإدخال
      if (lab.id.isEmpty) {
        throw Exception('معرف المعمل غير صالح');
      }
      if (lab.labNumber.isEmpty) {
        throw Exception('رقم المعمل مطلوب');
      }
      if (lab.college.isEmpty || lab.department.isEmpty) {
        throw Exception('الكلية والقسم مطلوبان');
      }

      final db = await database;

      // إنشاء خريطة البيانات مع القيم الأساسية
      final Map<String, dynamic> labData = {
        'id': lab.id,
        'labNumber': lab.labNumber,
        'college': lab.college,
        'department': lab.department,
        'floorNumber': lab.floorNumber,
        'status': lab.status.toString(),
        'notes': lab.notes,
        'createdAt': lab.createdAt.millisecondsSinceEpoch,
        'updatedAt': lab.updatedAt.millisecondsSinceEpoch,
      };

      // إضافة imagePath فقط إذا كانت غير null وغير فارغة
      if (lab.imagePath != null && lab.imagePath!.isNotEmpty) {
        labData['imagePath'] = lab.imagePath;
      }

      // إضافة معلومات الموقع إذا كانت متوفرة
      if (lab.locationUrl != null) {
        final locationUrl = lab.locationUrl!.trim();
        if (locationUrl.isNotEmpty) {
          labData['locationUrl'] = locationUrl;
        }
      }

      // إضافة معلومات الموقع الجغرافي
      if (lab.latitude != null) {
        labData['latitude'] = lab.latitude;
      }
      if (lab.longitude != null) {
        labData['longitude'] = lab.longitude;
      }

      await db.insert(
        'labs',
        labData,
        conflictAlgorithm: ConflictAlgorithm.replace,
      );

      debugPrint('تم إضافة المعمل بنجاح: ${lab.labNumber}');
    } catch (e) {
      debugPrint('خطأ في إضافة المعمل: $e');
      rethrow;
    }
  }

  // Modify updateLab method to handle null values more carefully
  static Future<void> updateLab(LabModel lab) async {
    try {
      final db = await database;

      // Create a map of values to update
      final Map<String, dynamic> updateValues = {
        'labNumber': lab.labNumber,
        'college': lab.college,
        'department': lab.department,
        'floorNumber': lab.floorNumber,
        'status': lab.status.toString(),
        'notes': lab.notes,
        'updatedAt': lab.updatedAt.millisecondsSinceEpoch,
      };

      // Only add imagePath if it's not null and not empty
      if (lab.imagePath != null && lab.imagePath!.isNotEmpty) {
        updateValues['imagePath'] = lab.imagePath;
      }

      // Add optional location-related fields only if they have values
      if (lab.locationUrl != null) {
        final locationUrl = lab.locationUrl!.trim();
        if (locationUrl.isNotEmpty) {
          updateValues['locationUrl'] = locationUrl;
        }
      }

      // Add latitude and longitude if they are not null
      if (lab.latitude != null) {
        updateValues['latitude'] = lab.latitude;
      }
      if (lab.longitude != null) {
        updateValues['longitude'] = lab.longitude;
      }

      // Perform the update
      await db.update(
        'labs',
        updateValues,
        where: 'id = ?',
        whereArgs: [lab.id],
      );
    } catch (e) {
      debugPrint('Error updating lab: $e');

      // Log more detailed error information
      if (e is DatabaseException) {
        debugPrint('Detailed DatabaseException: ${e.toString()}');
      }

      rethrow;
    }
  }

  static Future<void> deleteLab(String labId) async {
    final db = await database;
    await db.transaction((txn) async {
      // Update devices to remove lab reference
      await txn.update(
        'devices',
        {'labId': null},
        where: 'labId = ?',
        whereArgs: [labId],
      );
      // Delete the lab
      await txn.delete(
        'labs',
        where: 'id = ?',
        whereArgs: [labId],
      );
    });
  }

  static Future<void> updateLabStatus(String labId) async {
    final db = await database;

    // Get devices count for this lab
    final List<Map<String, dynamic>> deviceMaps = await db.query(
      'devices',
      where: 'labId = ?',
      whereArgs: [labId],
    );

    final deviceCount = deviceMaps.length;

    // Get current lab
    final List<Map<String, dynamic>> labMaps = await db.query(
      'labs',
      where: 'id = ?',
      whereArgs: [labId],
      limit: 1,
    );

    if (labMaps.isEmpty) return;

    // Determine new status based on device count
    final newStatus = deviceCount > 0
        ? LabStatus.openWithDevices.toString()
        : LabStatus.openNoDevices.toString();

    await db.update(
      'labs',
      {
        'status': newStatus,
        'updatedAt': DateTime.now().millisecondsSinceEpoch,
      },
      where: 'id = ?',
      whereArgs: [labId],
    );
  }

  static Future<List<LabModel>> getLabs() async {
    try {
      final db = await database;
      final List<Map<String, dynamic>> maps = await db.query('labs');

      // تصفية المعامل للتأكد من صحة البيانات
      return maps
          .where((map) {
            return map['id'] != null &&
                (map['id'] as String).isNotEmpty &&
                map['labNumber'] != null &&
                (map['labNumber'] as String).isNotEmpty &&
                map['college'] != null &&
                (map['college'] as String).isNotEmpty;
          })
          .map((map) => LabModel.fromMap(map))
          .toList();
    } catch (e) {
      debugPrint('خطأ في جلب المعامل: $e');
      return []; // إرجاع قائمة فارغة في حالة الخطأ
    }
  }

  static Future<List<LabModel>> getLabsByCollege(String college) async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query(
      'labs',
      where: 'college = ?',
      whereArgs: [college],
    );

    return List.generate(maps.length, (i) {
      return LabModel(
        id: maps[i]['id'],
        labNumber: maps[i]['labNumber'],
        college: maps[i]['college'],
        department: maps[i]['department'],
        floorNumber: maps[i]['floorNumber'],
        status: LabStatus.values.firstWhere(
          (e) => e.toString() == maps[i]['status'],
          orElse: () => LabStatus.closed,
        ),
        notes: maps[i]['notes'] ?? '',
        deviceIds: [], // Will be populated separately
        createdAt: DateTime.fromMillisecondsSinceEpoch(maps[i]['createdAt']),
        updatedAt: DateTime.fromMillisecondsSinceEpoch(maps[i]['updatedAt']),
      );
    });
  }

  static Future<LabModel?> getLabById(String labId) async {
    try {
      final db = await database;
      final List<Map<String, dynamic>> maps = await db.query(
        'labs',
        where: 'id = ?',
        whereArgs: [labId],
      );

      // التأكد من وجود نتائج وصحة البيانات
      if (maps.isNotEmpty) {
        final labMap = maps.first;

        // التحقق من صحة البيانات الأساسية
        if (labMap['id'] != null &&
            (labMap['id'] as String).isNotEmpty &&
            labMap['labNumber'] != null &&
            (labMap['labNumber'] as String).isNotEmpty &&
            labMap['college'] != null &&
            (labMap['college'] as String).isNotEmpty) {
          return LabModel.fromMap(labMap);
        }
      }

      return null; // إرجاع null إذا لم تكن البيانات صالحة
    } catch (e) {
      debugPrint('خطأ في جلب المعمل: $e');
      return null;
    }
  }

  // Consolidated Device Operations
  static Future<void> addDevice(DeviceModel device) async {
    try {
      final db = await database;
      await db.insert(
        'devices',
        device.toMap(),
        conflictAlgorithm: ConflictAlgorithm.replace,
      );

      // Update lab status when device is added
      await updateLabStatus(device.labId);
    } catch (e) {
      debugPrint('Error adding device: $e');
      rethrow;
    }
  }

  // Simplified method to update a device
  static Future<void> updateDeviceRecord(DeviceModel device) async {
    try {
      final db = await database;

      // Get old device to check if labId changed
      final oldDevice = await getDeviceById(device.id);
      final oldLabId = oldDevice?.labId;

      await db.update(
        'devices',
        device.toMap(),
        where: 'id = ?',
        whereArgs: [device.id],
      );

      // Update status for both old and new lab if changed
      if (oldLabId != null) {
        await updateLabStatus(oldLabId);
      }
      if (device.labId != oldLabId) {
        await updateLabStatus(device.labId);
      }
    } catch (e) {
      debugPrint('Error updating device: $e');
      rethrow;
    }
  }

  // Simplified method to delete a device
  static Future<void> removeDevice(String deviceId) async {
    try {
      final db = await database;

      // Get device's lab before deleting
      final device = await getDeviceById(deviceId);
      final labId = device?.labId;

      await db.delete(
        'devices',
        where: 'id = ?',
        whereArgs: [deviceId],
      );

      // Update lab status if device was in a lab
      if (labId != null) {
        await updateLabStatus(labId);
      }
    } catch (e) {
      debugPrint('Error deleting device: $e');
      rethrow;
    }
  }

  static Future<List<DeviceModel>> getDevices() async {
    try {
      final db = await database;
      final List<Map<String, dynamic>> maps = await db.query('devices');

      // تصفية الأجهزة للتأكد من صحة البيانات
      return maps
          .where((map) {
            return map['id'] != null &&
                (map['id'] as String).isNotEmpty &&
                map['name'] != null &&
                (map['name'] as String).isNotEmpty &&
                map['college'] != null &&
                (map['college'] as String).isNotEmpty;
          })
          .map((map) => DeviceModel.fromMap(map))
          .toList();
    } catch (e) {
      debugPrint('خطأ في جلب الأجهزة: $e');
      return []; // إرجاع قائمة فارغة في حالة الخطأ
    }
  }

  static Future<List<DeviceModel>> getDevicesForLab(String? labId) async {
    if (labId == null) return [];

    final db = await database;
    final maps = await db.query(
      'devices',
      where: 'labId = ?',
      whereArgs: [labId],
    );

    return maps.map((map) => DeviceModel.fromMap(map)).toList();
  }

  static Future<bool> serialNumberExists(
    String serialNumber, {
    String? excludeId,
  }) async {
    try {
      final db = await database;
      final query = excludeId != null
          ? 'serialNumber = ? AND id != ?'
          : 'serialNumber = ?';
      final args =
          excludeId != null ? [serialNumber, excludeId] : [serialNumber];

      final result = await db.query(
        'devices',
        where: query,
        whereArgs: args,
      );

      return result.isNotEmpty;
    } catch (e) {
      debugPrint('Error checking serial number: $e');
      return false;
    }
  }

  static Future<DeviceModel?> getDeviceById(String id) async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query(
      'devices',
      where: 'id = ?',
      whereArgs: [id],
      limit: 1,
    );

    if (maps.isEmpty) return null;

    return DeviceModel(
      id: maps[0]['id'],
      name: maps[0]['name'],
      college: maps[0]['college'],
      model: maps[0]['model'],
      serialNumber: maps[0]['serialNumber'],
      processor: maps[0]['processor'],
      storageType: maps[0]['storageType'],
      storageSize: maps[0]['storageSize'],
      hasExtraStorage: maps[0]['hasExtraStorage'] == 1,
      osVersion: maps[0]['osVersion'],
      notes: maps[0]['notes'] ?? '',
      labId: maps[0]['labId'],
      universityBarcode: maps[0]['universityBarcode'],
      assetCode: maps[0]['assetCode'],
      needsMaintenance: maps[0]['needsMaintenance'] == 1,
      createdAt: DateTime.fromMillisecondsSinceEpoch(maps[0]['createdAt']),
      updatedAt: DateTime.fromMillisecondsSinceEpoch(maps[0]['updatedAt']),
    );
  }

  static Future<DeviceModel?> getDeviceByBarcode(String? barcode) async {
    if (barcode == null || barcode.isEmpty) return null;

    try {
      final db = await database;
      final maps = await db.query(
        'devices',
        where: 'universityBarcode = ?',
        whereArgs: [barcode],
        limit: 1,
      );

      return maps.isNotEmpty ? DeviceModel.fromMap(maps.first) : null;
    } catch (e) {
      debugPrint('Error retrieving device by barcode: $e');
      return null;
    }
  }

  static Future<List<DeviceModel>> searchDevices(String query) async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query(
      'devices',
      where:
          'name LIKE ? OR serialNumber LIKE ? OR universityBarcode LIKE ? OR assetCode LIKE ?',
      whereArgs: ['%$query%', '%$query%', '%$query%', '%$query%'],
    );

    return List.generate(maps.length, (i) {
      return DeviceModel(
        id: maps[i]['id'],
        name: maps[i]['name'],
        college: maps[i]['college'],
        model: maps[i]['model'],
        serialNumber: maps[i]['serialNumber'],
        processor: maps[i]['processor'],
        storageType: maps[i]['storageType'],
        storageSize: maps[i]['storageSize'],
        hasExtraStorage: maps[i]['hasExtraStorage'] == 1,
        osVersion: maps[i]['osVersion'],
        notes: maps[i]['notes'] ?? '',
        labId: maps[i]['labId'],
        universityBarcode: maps[i]['universityBarcode'],
        assetCode: maps[i]['assetCode'],
        needsMaintenance: maps[i]['needsMaintenance'] == 1,
        createdAt: DateTime.fromMillisecondsSinceEpoch(maps[i]['createdAt']),
        updatedAt: DateTime.fromMillisecondsSinceEpoch(maps[i]['updatedAt']),
      );
    });
  }

  // Remove labs older than 3 months
  static Future<void> removeOldLabs() async {
    final db = await database;
    final threeMonthsAgo = DateTime.now().subtract(const Duration(days: 90));

    await db.delete(
      'labs',
      where: 'createdAt < ?',
      whereArgs: [threeMonthsAgo.millisecondsSinceEpoch],
    );

    // Also remove associated devices
    await db.delete(
      'devices',
      where: 'labId NOT IN (SELECT id FROM labs)',
    );
  }

  // New method to save image for a lab
  static Future<String?> saveLabImage(File imageFile, String labNumber) async {
    try {
      // Get the application documents directory
      final appDir = await getApplicationDocumentsDirectory();

      // Create a directory for lab images if it doesn't exist
      final labImagesDir = Directory('${appDir.path}/lab_images');
      if (!await labImagesDir.exists()) {
        await labImagesDir.create(recursive: true);
      }

      // Generate a unique filename based on lab number and timestamp
      final fileName =
          'lab_${labNumber}_${DateTime.now().millisecondsSinceEpoch}${path.extension(imageFile.path)}';

      // Save the image to the new path
      final savedFile = await imageFile.copy('${labImagesDir.path}/$fileName');

      return savedFile.path;
    } catch (e) {
      debugPrint('Error saving lab image: $e');
      return null;
    }
  }

  // Method to get the last inserted lab
  static Future<LabModel?> getLastInsertedLab() async {
    final db = await database;
    final maps = await db.query(
      'labs',
      orderBy: 'createdAt DESC',
      limit: 1,
    );

    if (maps.isNotEmpty) {
      return LabModel.fromMap(maps.first);
    }
    return null;
  }

  // Update other methods that might use lab ID
  static Future<int> insertLab(LabModel lab) async {
    final db = await database;
    return await db.insert('labs', lab.toMap());
  }

  // Method to insert a new device
  static Future<int> insertDevice(DeviceModel device) async {
    final db = await database;
    return await db.insert('devices', device.toMap());
  }

  // Method to update an existing device
  static Future<int> updateDevice(DeviceModel device) async {
    final db = await database;
    return await db.update(
      'devices',
      device.toMap(),
      where: 'id = ?',
      whereArgs: [device.id],
    );
  }

  // Method to delete a device
  static Future<int> deleteDevice(String deviceId) async {
    final db = await database;
    return await db.delete(
      'devices',
      where: 'id = ?',
      whereArgs: [deviceId],
    );
  }

  // Ensure robust ID generation and handling
  static String generateUniqueId() {
    return const Uuid().v4().toString();
  }

  // إعادة إنشاء قاعدة البيانات بالكامل
  static Future<void> recreateDatabase() async {
    try {
      // إغلاق قاعدة البيانات الحالية إن وجدت
      if (_database != null) {
        await _database!.close();
        _database = null;
      }

      // مسار قاعدة البيانات
      final dbPath = await getDatabasesPath();
      final path = join(dbPath, dbName);

      // حذف قاعدة البيانات الموجودة
      await deleteDatabase(path);

      // إعادة إنشاء قاعدة البيانات
      await _initDB();

      debugPrint('تمت إعادة إنشاء قاعدة البيانات بنجاح');
    } catch (e) {
      debugPrint('خطأ في إعادة إنشاء قاعدة البيانات: $e');
      rethrow;
    }
  }

  // دالة استعادة النسخة الاحتياطية
  static Future<void> restoreDatabaseFromBackup() async {
    try {
      // مسار قاعدة البيانات
      final dbPath = await getDatabasesPath();
      final path = join(dbPath, dbName);
      final backupPath = '$path.backup';

      // التأكد من وجود النسخة الاحتياطية
      if (await File(backupPath).exists()) {
        // إغلاق قاعدة البيانات الحالية
        if (_database != null) {
          await _database!.close();
          _database = null;
        }

        // استعادة النسخة الاحتياطية
        await File(backupPath).copy(path);

        // إعادة فتح قاعدة البيانات
        _database = await _initDB();

        debugPrint('تمت استعادة قاعدة البيانات من النسخة الاحتياطية بنجاح');
      } else {
        debugPrint('لا توجد نسخة احتياطية للاستعادة');
      }
    } catch (e) {
      debugPrint('خطأ في استعادة قاعدة البيانات: $e');
      rethrow;
    }
  }
}
