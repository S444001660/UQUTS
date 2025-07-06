import 'package:flutter/material.dart';
import 'package:flutter_barcode_scanner/flutter_barcode_scanner.dart';

class BarcodeService {
  static Future<String?> scanBarcode(BuildContext context) async {
    try {
      final result = await FlutterBarcodeScanner.scanBarcode(
        '#ff6666',
        'إلغاء',
        true,
        ScanMode.BARCODE,
      );

      if (result == '-1') return null;
      return result;
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('حدث خطأ أثناء مسح الباركود: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
      return null;
    }
  }

  static Map<String, String?> parseUniversityBarcode(String barcode) {
    // تنسيقات متعددة للباركود
    try {
      // إزالة المسافات الزائدة وتنظيف الباركود
      barcode = barcode.trim().replaceAll(RegExp(r'\s+'), '');

      // محاولة التعامل مع التنسيقات المختلفة
      // 1. التنسيق الأول: جامعة أم القرى اسم الأصل / الآلات والمعدات رمز الأصل / 0022958
      if (barcode.contains('/') && barcode.split('/').length == 3) {
        final parts = barcode.split('/');
        return {
          'barcode': barcode,
          'assetSource': parts[0].trim(), // جامعة أم القرى اسم الأصل
          'assetCategory': parts[1].trim(), // الآلات والمعدات رمز الأصل
          'assetCode': parts[2].trim(), // 0022958
        };
      }

      // 2. التنسيق الثاني: رقم تسلسلي بسيط
      if (RegExp(r'^\d+$').hasMatch(barcode)) {
        return {
          'barcode': barcode,
          'assetSource': 'جامعة أم القرى',
          'assetCategory': 'معدات',
          'assetCode': barcode,
        };
      }

      // 3. التنسيق الثالث: UQU-ASSET-0012498-COMPUTER
      if (barcode.contains('UQU-ASSET-')) {
        final parts = barcode.split('-');
        return {
          'barcode': barcode,
          'assetSource': 'جامعة أم القرى',
          'assetCategory': parts.length > 3 ? parts[3] : 'معدات',
          'assetCode': parts.length > 2 ? parts[2] : barcode,
        };
      }

      // 4. محاولة استخراج رمز الأصل من أي نص
      final assetCodeMatch = RegExp(r'\d{6,}').firstMatch(barcode);
      if (assetCodeMatch != null) {
        return {
          'barcode': barcode,
          'assetSource': 'جامعة أم القرى',
          'assetCategory': 'معدات',
          'assetCode': assetCodeMatch.group(0),
        };
      }

      // 5. محاولة تنظيف وتحسين الباركود
      final cleanedBarcode = barcode.replaceAll(RegExp(r'[^0-9]'), '');
      if (cleanedBarcode.isNotEmpty) {
        return {
          'barcode': barcode,
          'assetSource': 'جامعة أم القرى',
          'assetCategory': 'معدات',
          'assetCode': cleanedBarcode,
        };
      }

      // إذا لم يتم التعرف على التنسيق
      return {
        'barcode': barcode,
        'assetSource': 'جامعة أم القرى',
        'assetCategory': 'معدات',
        'assetCode': barcode,
      };
    } catch (e) {
      // في حالة حدوث خطأ غير متوقع
      debugPrint('خطأ في تحليل الباركود: $e');
      return {
        'barcode': barcode,
        'assetSource': 'جامعة أم القرى',
        'assetCategory': 'معدات',
        'assetCode': null,
      };
    }
  }

  // دالة إنشاء باركود متوافقة مع التنسيقات المختلفة
  static Future<String> generateBarcode({
    String? assetSource,
    String? assetCategory,
    required String assetCode,
  }) async {
    // إنشاء باركود بتنسيقات مختلفة
    if (assetSource != null && assetCategory != null) {
      // التنسيق الأول: جامعة أم القرى اسم الأصل / الآلات والمعدات رمز الأصل / 0022958
      return '$assetSource / $assetCategory / $assetCode';
    } else {
      // التنسيق الثاني: UQU-ASSET-0012498-COMPUTER
      return 'UQU-ASSET-$assetCode-${assetCategory ?? 'DEVICE'}';
    }
  }
}
