import 'package:flutter/material.dart';
// تأكد من المسار الصحيح
// هذا الـ import موجود عندك بالفعل

//------------------------------------------------------------------------------

/// ويدجت شاشة الإعدادات، وهي حاليًا شاشة بسيطة لعرض الإعدادات المستقبلية.
class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

//------------------------------------------------------------------------------

/// كلاس الحالة (State) الخاص بـ SettingsScreen.
class _SettingsScreenState extends State<SettingsScreen> {
  // تم حذف متغيرات الحالة _isRecreatingDatabase و _isExportingData
  // لأنه تم حذف الدوال المرتبطة بها التي كانت تقوم بوظائف تجريبية.

  // تم حذف دالة _recreateDatabase() التي كانت تستخدم لإعادة إنشاء قاعدة البيانات.
  // تم حذف دالة _exportDataToJson() التي كانت تستخدم لتصدير البيانات.

  //------------------------------------------------------------------------------

  /// الدالة الأساسية لبناء واجهة المستخدم (UI) للشاشة بأكملها.
  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('الإعدادات'),
        centerTitle: true,
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // تم حذف "Database Recreation Card"
          // تم حذف "Export Data to JSON Card"

          // يمكنك إضافة المزيد من الكاردز هنا لإعدادات أخرى
          // إذا كنت تريد إضافة إعدادات جديدة في المستقبل، يمكنك وضعها هنا.
          Card(
            elevation: 4,
            child: ListTile(
              title: const Text('لا توجد إعدادات متاحة حاليًا'),
              subtitle: const Text(
                  'هذه الشاشة مخصصة للإعدادات الإضافية في المستقبل.'),
              leading: Icon(Icons.settings, color: theme.colorScheme.primary),
            ),
          ),
        ],
      ),
    );
  }
}
