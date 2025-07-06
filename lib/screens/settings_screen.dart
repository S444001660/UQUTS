import 'package:flutter/material.dart';
import '../services/database_service.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  bool _isRecreatingDatabase = false;

  Future<void> _recreateDatabase() async {
    try {
      setState(() => _isRecreatingDatabase = true);

      // عرض تحذير قبل إعادة إنشاء قاعدة البيانات
      final confirmRecreate = await showDialog<bool>(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('إعادة إنشاء قاعدة البيانات'),
          content: const Text('هذا سيؤدي إلى مسح جميع البيانات. هل أنت متأكد؟'),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: const Text('إلغاء'),
            ),
            ElevatedButton(
              onPressed: () => Navigator.of(context).pop(true),
              style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
              child: const Text('إعادة الإنشاء'),
            ),
          ],
        ),
      );

      if (confirmRecreate == true) {
        await DatabaseService.recreateDatabase();

        // عرض رسالة نجاح
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('تمت إعادة إنشاء قاعدة البيانات بنجاح'),
              backgroundColor: Colors.green,
            ),
          );
        }
      }
    } catch (e) {
      // عرض رسالة خطأ
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('خطأ في إعادة إنشاء قاعدة البيانات: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isRecreatingDatabase = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('الإعدادات'),
        backgroundColor: theme.colorScheme.primary,
        foregroundColor: theme.colorScheme.onPrimary,
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Card(
            child: ListTile(
              title: const Text('إعادة إنشاء قاعدة البيانات'),
              subtitle: const Text('مسح وإعادة إنشاء جميع البيانات'),
              trailing: _isRecreatingDatabase
                  ? const CircularProgressIndicator()
                  : IconButton(
                      icon: const Icon(Icons.refresh, color: Colors.red),
                      onPressed: _recreateDatabase,
                    ),
            ),
          ),
          // يمكنك إضافة المزيد من خيارات الإعدادات هنا
        ],
      ),
    );
  }
}
