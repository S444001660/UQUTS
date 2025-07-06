import 'package:flutter/material.dart';
import '../models/device_model.dart';
import '../models/lab_model.dart';
import '../services/barcode_service.dart';
import '../services/database_service.dart';
import 'add_device_screen.dart';
import 'package:uuid/uuid.dart';
import 'device_details_screen.dart';

class BarcodeScannerScreen extends StatefulWidget {
  final bool isDeviceMode;

  const BarcodeScannerScreen({
    super.key,
    this.isDeviceMode = false,
  });

  @override
  State<BarcodeScannerScreen> createState() => _BarcodeScannerScreenState();
}

class _BarcodeScannerScreenState extends State<BarcodeScannerScreen> {
  // Use final for fields that don't change after initialization
  final List<LabModel> _labs = [];
  DeviceModel? _existingDevice;

  @override
  void initState() {
    super.initState();
    _loadLabs();
  }

  Future<void> _loadLabs() async {
    try {
      final labs = await DatabaseService.getLabs();
      if (mounted) {
        setState(() {
          _labs.clear();
          _labs.addAll(labs);
        });
      }
    } catch (e) {
      // Simple error logging and user feedback
      debugPrint('Error loading labs: $e');

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('خطأ في تحميل المعامل: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  // دالة لعرض حوار تسجيل جهاز جديد بتصميم أكثر جاذبية
  void _showNewDeviceDialog(Map<String, String?> barcodeData) {
    final theme = Theme.of(context);

    showDialog(
      context: context,
      builder: (context) => Dialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        child: Container(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // رأس الحوار
              Row(
                children: [
                  Icon(
                    Icons.add_circle_outline,
                    color: theme.colorScheme.primary,
                    size: 32,
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Text(
                      'تسجيل جهاز جديد',
                      style: theme.textTheme.titleLarge?.copyWith(
                        color: theme.colorScheme.primary,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),

              // محتوى الحوار
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: theme.colorScheme.surfaceContainerHighest.withAlpha(50),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'تم اكتشاف جهاز غير مسجل في النظام',
                      style: theme.textTheme.titleMedium?.copyWith(
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                    ),
                    const SizedBox(height: 8),
                    _buildDetailRow(theme, Icons.business_outlined,
                        'مصدر الأصل', barcodeData['assetSource'] ?? 'غير محدد'),
                    _buildDetailRow(theme, Icons.category_outlined, 'فئة الأصل',
                        barcodeData['assetCategory'] ?? 'غير محدد'),
                    _buildDetailRow(theme, Icons.qr_code_outlined, 'رمز الأصل',
                        barcodeData['assetCode'] ?? 'غير محدد'),
                  ],
                ),
              ),
              const SizedBox(height: 16),

              // أزرار الإجراءات
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () => Navigator.pop(context),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: theme.colorScheme.error,
                        side: BorderSide(color: theme.colorScheme.error),
                      ),
                      child: const Text('إلغاء'),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: FilledButton(
                      onPressed: () {
                        Navigator.pop(context);
                        _showLabSelectionDialog(barcodeData);
                      },
                      child: const Text('تسجيل الجهاز'),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  // دالة مساعدة لبناء صف تفاصيل
  Widget _buildDetailRow(
      ThemeData theme, IconData icon, String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Icon(
            icon,
            color: theme.colorScheme.primary.withAlpha(180),
            size: 20,
          ),
          const SizedBox(width: 8),
          Text(
            '$label: ',
            style: theme.textTheme.bodyMedium?.copyWith(
              fontWeight: FontWeight.bold,
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
          Text(
            value,
            style: theme.textTheme.bodyMedium?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
        ],
      ),
    );
  }

  // تعديل دالة _scanBarcode للاستخدام الجديد
  Future<void> _scanBarcode() async {
    try {
      final barcode = await BarcodeService.scanBarcode(context);
      if (barcode == null || !mounted) return;

      // تحليل الباركود مع طباعة معلومات التصحيح
      final barcodeData = BarcodeService.parseUniversityBarcode(barcode);
      final assetCode = barcodeData['assetCode'];

      // طباعة معلومات التصحيح
      debugPrint('Scanned Barcode: $barcode');
      debugPrint('Parsed Asset Code: $assetCode');
      debugPrint('Parsed Asset Source: ${barcodeData['assetSource']}');
      debugPrint('Parsed Asset Category: ${barcodeData['assetCategory']}');

      // Check if this device is already registered
      final devices = await DatabaseService.getDevices();

      // Find the device with matching barcode (مع التعامل مع الحالات المختلفة)
      final existingDevice = devices.where((d) {
        // التحقق من رمز الأصل مع طباعة معلومات التصحيح
        bool matchAssetCode = d.assetCode != null &&
            (d.assetCode == assetCode ||
                d.assetCode == barcode ||
                (assetCode != null && barcode.contains(d.assetCode!)) ||
                (d.assetCode != null && barcode.contains(d.assetCode!)));

        // التحقق من الباركود الجامعي مع طباعة معلومات التصحيح
        bool matchUniversityBarcode = d.universityBarcode != null &&
            (d.universityBarcode == barcode ||
                barcode.contains(d.universityBarcode!) ||
                d.universityBarcode!.contains(barcode));

        // طباعة معلومات التصحيح للجهاز الحالي
        if (matchAssetCode || matchUniversityBarcode) {
          debugPrint('Matched Device:');
          debugPrint('Device ID: ${d.id}');
          debugPrint('Device Asset Code: ${d.assetCode}');
          debugPrint('Device University Barcode: ${d.universityBarcode}');
        }

        return matchAssetCode || matchUniversityBarcode;
      }).toList();

      // التحقق من وجود أجهزة مطابقة
      if (existingDevice.isNotEmpty) {
        debugPrint('Found ${existingDevice.length} matching devices');

        if (mounted) {
          setState(() => _existingDevice = existingDevice.first);
          _showExistingDeviceDialog(_existingDevice!);
        }
      } else {
        // Device not found, show new device registration dialog
        debugPrint('No matching device found');

        if (!mounted) return;

        // استخدام الحوار الجديد
        _showNewDeviceDialog(barcodeData);
      }
    } catch (e) {
      // Simple error logging and user feedback
      debugPrint('Error scanning barcode: $e');

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'حدث خطأ في قراءة الباركود: $e',
            style: const TextStyle(color: Colors.white),
          ),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  void _showExistingDeviceDialog(DeviceModel device) {
    // التأكد من وجود السياق والشاشة
    if (!mounted) return;

    // طباعة معلومات الجهاز للتأكد
    debugPrint('Opening Device Details:');
    debugPrint('Device ID: ${device.id}');
    debugPrint('Device Name: ${device.name}');
    debugPrint('Device Asset Code: ${device.assetCode}');
    debugPrint('Device University Barcode: ${device.universityBarcode}');

    // محاولة فتح صفحة تفاصيل الجهاز مع معالجة الأخطاء
    try {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => DeviceDetailsScreen(device: device),
        ),
      );
    } catch (e) {
      // طباعة أي خطأ محتمل
      debugPrint('Error opening device details: $e');

      // عرض رسالة خطأ للمستخدم
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('حدث خطأ في فتح تفاصيل الجهاز: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  // دالة اختيار المعمل وإضافة الجهاز الجديد
  void _showLabSelectionDialog(Map<String, String?> barcodeData) {
    // التحقق من وجود معامل
    if (_labs.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('لا توجد معامل مسجلة. يرجى إضافة معمل أولاً'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    final theme = Theme.of(context);

    showDialog(
      context: context,
      builder: (context) => Dialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        child: Container(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // رأس الحوار
              Row(
                children: [
                  Icon(
                    Icons.science_outlined,
                    color: theme.colorScheme.primary,
                    size: 32,
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Text(
                      'اختيار المعمل',
                      style: theme.textTheme.titleLarge?.copyWith(
                        color: theme.colorScheme.primary,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),

              // قائمة المعامل
              Expanded(
                child: ListView.builder(
                  shrinkWrap: true,
                  itemCount: _labs.length,
                  itemBuilder: (context, index) {
                    final lab = _labs[index];
                    return Card(
                      margin: const EdgeInsets.only(bottom: 8),
                      child: ListTile(
                        title: Text('معمل ${lab.labNumber}'),
                        subtitle: Text('${lab.college} - ${lab.department}'),
                        trailing: Text(lab.floorNumber),
                        onTap: () async {
                          // إنشاء جهاز جديد
                          final newDevice = DeviceModel(
                            id: const Uuid().v4(),
                            name: '', // سيتم ملؤه لاحقاً في شاشة الإضافة
                            college: lab.college, // من المعمل المختار
                            department: lab.department, // من المعمل المختار
                            model: '', // سيتم ملؤه لاحقاً
                            serialNumber: '', // سيتم ملؤه لاحقاً
                            processor: '', // سيتم ملؤه لاحقاً
                            storageType: '', // سيتم ملؤه لاحقاً
                            storageSize: '', // سيتم ملؤه لاحقاً
                            hasExtraStorage: false, // قيمة افتراضية
                            osVersion: '', // سيتم ملؤه لاحقاً
                            notes: '', // سيتم ملؤه لاحقاً
                            labId: lab.id,
                            universityBarcode: barcodeData['assetCode'],
                            assetSource: barcodeData['assetSource'],
                            assetCategory: barcodeData['assetCategory'],
                            assetCode: barcodeData['assetCode'],
                            needsMaintenance: false, // قيمة افتراضية
                            createdAt: DateTime.now(),
                            updatedAt: DateTime.now(),
                          );

                          try {
                            // حفظ الجهاز في قاعدة البيانات
                            await DatabaseService.addDevice(newDevice);

                            // إغلاق الحوار
                            if (mounted) Navigator.pop(context);

                            // عرض رسالة نجاح
                            if (mounted) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: Text(
                                      'تم إضافة الجهاز بنجاح في معمل ${lab.labNumber}'),
                                  backgroundColor: Colors.green,
                                ),
                              );
                            }

                            // الانتقال إلى تفاصيل الجهاز
                            if (mounted) {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) =>
                                      DeviceDetailsScreen(device: newDevice),
                                ),
                              );
                            }
                          } catch (e) {
                            // عرض رسالة خطأ
                            if (mounted) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: Text('خطأ في إضافة الجهاز: $e'),
                                  backgroundColor: Colors.red,
                                ),
                              );
                            }
                          }
                        },
                      ),
                    );
                  },
                ),
              ),

              // زر الإلغاء
              const SizedBox(height: 16),
              OutlinedButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('إلغاء'),
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('مسح الباركود'),
        backgroundColor: theme.colorScheme.primary,
        foregroundColor: theme.colorScheme.onPrimary,
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.qr_code_scanner_outlined,
              size: 120,
              color: theme.colorScheme.primary.withAlpha(128),
            ),
            const SizedBox(height: 24),
            Text(
              'مسح باركود الجامعة',
              style: theme.textTheme.headlineSmall,
            ),
            const SizedBox(height: 8),
            Text(
              'قم بمسح الباركود الموجود على الجهاز\nللتحقق من تسجيله أو إضافته',
              style: theme.textTheme.bodyLarge?.copyWith(
                color: theme.colorScheme.onSurface.withAlpha(179),
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 32),
            FilledButton.icon(
              onPressed: _scanBarcode,
              icon: const Icon(Icons.qr_code_scanner),
              label: const Text('مسح الباركود'),
            ),
          ],
        ),
      ),
    );
  }
}
