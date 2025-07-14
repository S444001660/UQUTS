// home_screen.dart

import 'package:flutter/material.dart';

// استيراد الملفات الضرورية لربط البيانات الحقيقية
import 'package:uquts1/services/firebase_database_service.dart';
import '../models/lab_model.dart';
import '../models/device_model.dart';
import 'lab_details_screen.dart'; // شاشة تفاصيل المعمل (للمعامل)
import 'view_device_screen.dart'; // شاشة عرض الجهاز فقط.

// استيراد الشاشات الأخرى
import 'add_lab_screen.dart';
import 'add_device_screen.dart';
import 'barcode_scanner_screen.dart';
import 'settings_screen.dart';
import 'labs_list_screen.dart';
import 'package:uquts1/screens/devices_list_screen.dart'; // تأكد من المسار الصحيح

//------------------------------------------------------------------------------

/// كلاس محلي لتوحيد بيانات المعامل والأجهزة في قائمة واحدة للأنشطة الأخيرة.
class RecentActivity {
  final String id;
  final String title;
  final String type;
  final DateTime timestamp;
  final dynamic originalObject; // يمكن أن يكون LabModel أو DeviceModel

  RecentActivity({
    required this.id,
    required this.title,
    required this.type,
    required this.timestamp,
    required this.originalObject,
  });
}

//------------------------------------------------------------------------------

/// ويدجت الشاشة الرئيسية للتطبيق.
class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

//------------------------------------------------------------------------------

/// كلاس الحالة الخاص بـ HomeScreen، مع إضافة TickerProviderStateMixin لدعم التبويبات.
class _HomeScreenState extends State<HomeScreen> with TickerProviderStateMixin {
  // متغيرات الحالة (State) لإدارة الواجهة.
  bool _isLoading = true;
  List<RecentActivity> _recentActivities = [];
  String? _error;

  // --- متحكم التبويبات ---
  late TabController _tabController;

  //------------------------------------------------------------------------------

  /// دالة initState: تُستدعى مرة واحدة عند إنشاء الويدجت لأول مرة.
  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _tabController.addListener(() {
      if (mounted) {
        setState(() {});
      }
    });
    _loadData(); // تحميل البيانات الأولية عند بدء الشاشة.
  }

  //------------------------------------------------------------------------------

  /// دالة dispose: تُستدعى عند إزالة الويدجت لتحرير الموارد.
  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  //------------------------------------------------------------------------------

  /// دالة غير متزامنة لجلب وتجهيز بيانات الأنشطة الأخيرة.
  Future<void> _loadData() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final List<LabModel> labs = await FirebaseDatabaseService.getLabs();
      final List<DeviceModel> devices =
          await FirebaseDatabaseService.getDevices();
      List<RecentActivity> allActivities = [];

      for (var lab in labs) {
        allActivities.add(RecentActivity(
          id: lab.id,
          title: 'إضافة معمل ${lab.labNumber}',
          type: 'lab',
          timestamp: lab.createdAt,
          originalObject: lab,
        ));
      }

      for (var device in devices) {
        allActivities.add(RecentActivity(
          id: device.id,
          title: 'إضافة جهاز "${device.name}"',
          type: 'device',
          timestamp: device.createdAt,
          originalObject: device,
        ));
      }

      allActivities.sort((a, b) => b.timestamp.compareTo(a.timestamp));

      if (mounted) {
        setState(() {
          _recentActivities = allActivities.take(5).toList();
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _error = 'حدث خطأ في تحميل البيانات';
          _isLoading = false;
        });
      }
    }
  }

  //------------------------------------------------------------------------------

  /// دالة مساعدة لتحويل التاريخ إلى نص وصفي.
  String _formatTimestamp(DateTime timestamp) {
    final difference = DateTime.now().difference(timestamp);
    if (difference.inDays > 0) {
      return 'قبل ${difference.inDays} يوم';
    } else if (difference.inHours > 0) {
      return 'قبل ${difference.inHours} ساعة';
    } else if (difference.inMinutes > 0) {
      return 'قبل ${difference.inMinutes} دقيقة';
    } else {
      return 'الآن';
    }
  }

  //------------------------------------------------------------------------------

  /// دالة تُستدعى عند النقر على أحد عناصر شريط التنقل السفلي.
  void _onNavBarTapped(int index) {
    Widget page;
    switch (index) {
      case 0:
        page = const LabsListScreen();
        break;
      case 1:
        page = const DevicesListScreen();
        break;
      case 2:
        page = const BarcodeScannerScreen();
        break;
      case 3:
        page = const SettingsScreen();
        break;
      default:
        return;
    }
    Navigator.push(context, MaterialPageRoute(builder: (context) => page))
        .then((_) => _loadData());
  }

  //------------------------------------------------------------------------------

  /// دالة مساعدة للانتقال إلى شاشة وتحديث البيانات عند العودة.
  void _navigateAndReload(Widget screen) {
    Navigator.push(context, MaterialPageRoute(builder: (context) => screen))
        .then((_) => _loadData());
  }

  //------------------------------------------------------------------------------

  /// الدالة الأساسية لبناء واجهة المستخدم (UI) للشاشة بأكملها.
  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      backgroundColor: theme.colorScheme.surface,
      // --- تعديل: استخدام Column لتخطيط ثابت بدلاً من SingleChildScrollView ---
      body: Column(
        children: [
          _buildUserInfoHeader(theme),
          // --- تعديل: وضع قسم التبويبات في Column خاص به ---
          Padding(
            padding: const EdgeInsets.fromLTRB(16.0, 24.0, 16.0, 16.0),
            child: _buildCustomTabBar(theme),
          ),
          // --- تعديل: استخدام Expanded لجعل المحتوى يملأ المساحة المتبقية ---
          Expanded(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16.0),
              child: AnimatedSwitcher(
                duration: const Duration(milliseconds: 300),
                transitionBuilder: (Widget child, Animation<double> animation) {
                  return FadeTransition(
                    opacity: animation,
                    child: child,
                  );
                },
                child: _tabController.index == 0
                    ? _buildRecentActivitiesSection(theme)
                    : _buildTasksSection(theme),
              ),
            ),
          ),
          _buildQuickActions(),
        ],
      ),
      bottomNavigationBar: _buildBottomNavBar(theme),
    );
  }

  //------------------------------------------------------------------------------

  /// ويدجت مساعد لبناء شريط التبويب بتصميم محسن.
  Widget _buildCustomTabBar(ThemeData theme) {
    return Container(
      height: 48,
      padding: const EdgeInsets.all(4.0),
      decoration: BoxDecoration(
        color: theme.colorScheme.primary.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12.0),
      ),
      child: TabBar(
        controller: _tabController,
        indicator: BoxDecoration(
          borderRadius: BorderRadius.circular(10.0),
          color: theme.colorScheme.primary,
        ),
        labelColor: theme.colorScheme.onPrimary,
        unselectedLabelColor: theme.colorScheme.primary,
        labelStyle: const TextStyle(fontWeight: FontWeight.bold),
        indicatorSize: TabBarIndicatorSize.tab,
        splashBorderRadius: BorderRadius.circular(10.0),
        tabs: const [
          Tab(text: 'آخر العمليات'),
          Tab(text: 'المهام'),
        ],
      ),
    );
  }

  //------------------------------------------------------------------------------

  /// ويدجت مساعد لبناء شريط التنقل السفلي.
  Widget _buildBottomNavBar(ThemeData theme) {
    return BottomNavigationBar(
      onTap: _onNavBarTapped,
      type: BottomNavigationBarType.fixed,
      backgroundColor: theme.colorScheme.surface,
      selectedItemColor: Colors.grey,
      unselectedItemColor: Colors.grey,
      showUnselectedLabels: true,
      items: const [
        BottomNavigationBarItem(
            icon: Icon(Icons.science_outlined), label: 'المعامل'),
        BottomNavigationBarItem(
            icon: Icon(Icons.computer_outlined), label: 'الأجهزة'),
        BottomNavigationBarItem(
            icon: Icon(Icons.qr_code_scanner), label: 'مسح'),
        BottomNavigationBarItem(
            icon: Icon(Icons.settings_outlined), label: 'الإعدادات'),
      ],
    );
  }

  //------------------------------------------------------------------------------

  /// ويدجت مساعد لبناء الجزء العلوي من الشاشة.
  Widget _buildUserInfoHeader(ThemeData theme) {
    final double topPadding = MediaQuery.of(context).padding.top;
    return Container(
      padding: EdgeInsets.only(
          top: topPadding + 16, bottom: 20, left: 20, right: 20),
      decoration: BoxDecoration(
        color: theme.colorScheme.primary,
        borderRadius: const BorderRadius.only(
          bottomLeft: Radius.circular(30),
          bottomRight: Radius.circular(30),
        ),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'عمر الحسن بن عمر المعشي',
                  style: theme.textTheme.titleLarge?.copyWith(
                    color: theme.colorScheme.onPrimary,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'كلية الحاسبات',
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: theme.colorScheme.onPrimary.withOpacity(0.9),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 16),
          const CircleAvatar(
            radius: 35,
            backgroundColor: Colors.white,
            child: Icon(Icons.person, size: 40, color: Colors.grey),
          ),
        ],
      ),
    );
  }

  //------------------------------------------------------------------------------

  /// ويدجت مساعد لبناء قسم الإجراءات السريعة.
  Widget _buildQuickActions() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16.0, 16.0, 16.0, 24.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          _buildActionButton(context,
              icon: Icons.add_business_outlined,
              label: 'إضافة معمل',
              onTap: () => _navigateAndReload(const AddLabScreen())),
          _buildActionButton(context,
              icon: Icons.add_to_queue_outlined,
              label: 'إضافة جهاز',
              onTap: () => _navigateAndReload(const AddDeviceScreen())),
          _buildActionButton(context,
              icon: Icons.help_outline, label: 'زر مؤقت', onTap: () {}),
          _buildActionButton(context,
              icon: Icons.info_outline, label: 'زر مؤقت', onTap: () {}),
        ],
      ),
    );
  }

  //------------------------------------------------------------------------------

  /// ويدجت مساعد لبناء زر واحد في قسم الإجراءات السريعة.
  Widget _buildActionButton(BuildContext context,
      {required IconData icon,
      required String label,
      required VoidCallback onTap}) {
    final theme = Theme.of(context);
    return Expanded(
      child: Card(
        elevation: 2,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: onTap,
          child: Container(
            padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(icon, size: 30, color: theme.colorScheme.primary),
                const SizedBox(height: 8),
                Text(
                  label,
                  style: theme.textTheme.bodySmall,
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  //------------------------------------------------------------------------------

  /// ويدجت مساعد لبناء قسم "آخر العمليات".
  Widget _buildRecentActivitiesSection(ThemeData theme) {
    return Container(
      key: const ValueKey<int>(0),
      child: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _error != null
              ? _buildErrorState(theme, _error!)
              : _recentActivities.isEmpty
                  ? const Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.history_toggle_off,
                              size: 50, color: Colors.grey),
                          SizedBox(height: 16),
                          Text('لا يوجد أي عمليات أخيرة',
                              style:
                                  TextStyle(fontSize: 18, color: Colors.grey)),
                        ],
                      ),
                    )
                  : _buildActivitiesList(theme),
    );
  }

  //------------------------------------------------------------------------------

  /// ويدجت لبناء قسم المهام.
  Widget _buildTasksSection(ThemeData theme) {
    final List<Map<String, String>> tasks = [
      {'title': 'فحص أجهزة معمل 404', 'assignee': 'موكلة إلى: أحمد'},
      {
        'title': 'تحديث نظام التشغيل لأجهزة كلية الهندسة',
        'assignee': 'موكلة إلى: محمد'
      },
      {'title': 'صيانة طابعة معمل 201', 'assignee': 'موكلة إلى: خالد'},
    ];

    return Container(
      key: const ValueKey<int>(1),
      child: tasks.isEmpty
          ? const Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.task_alt, size: 50, color: Colors.grey),
                  SizedBox(height: 16),
                  Text('لا توجد مهام حالية',
                      style: TextStyle(fontSize: 18, color: Colors.grey)),
                ],
              ),
            )
          : _buildTasksList(theme, tasks),
    );
  }

  //------------------------------------------------------------------------------

  /// ويدجت مساعد لبناء قائمة الأنشطة الأخيرة.
  Widget _buildActivitiesList(ThemeData theme) {
    return Container(
      decoration: BoxDecoration(
          color: theme.colorScheme.surface,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.grey.shade300)),
      // --- تعديل: السماح للقائمة بالتمرير داخل مساحتها المحددة ---
      child: ListView.separated(
        itemCount: _recentActivities.length,
        itemBuilder: (context, index) {
          final activity = _recentActivities[index];
          return _buildActivityTile(activity, theme);
        },
        separatorBuilder: (context, index) =>
            const Divider(height: 1, indent: 16, endIndent: 16),
      ),
    );
  }

  //------------------------------------------------------------------------------

  /// ويدجت مساعد لبناء قائمة المهام.
  Widget _buildTasksList(ThemeData theme, List<Map<String, String>> tasks) {
    return Container(
      decoration: BoxDecoration(
          color: theme.colorScheme.surface,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.grey.shade300)),
      // --- تعديل: السماح للقائمة بالتمرير داخل مساحتها المحددة ---
      child: ListView.separated(
        itemCount: tasks.length,
        itemBuilder: (context, index) {
          final task = tasks[index];
          return ListTile(
            contentPadding:
                const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            leading: const Icon(Icons.chevron_left, color: Colors.grey),
            title: Text(task['title']!,
                style: theme.textTheme.titleMedium, textAlign: TextAlign.right),
            subtitle: Text(
              task['assignee']!,
              style: theme.textTheme.bodySmall,
              textAlign: TextAlign.right,
            ),
            trailing: CircleAvatar(
              backgroundColor: Colors.blue.withOpacity(0.1),
              child: Icon(
                Icons.assignment_turned_in_outlined,
                color: Colors.blue.shade700,
              ),
            ),
            onTap: () {},
          );
        },
        separatorBuilder: (context, index) =>
            const Divider(height: 1, indent: 16, endIndent: 16),
      ),
    );
  }

  //------------------------------------------------------------------------------

  /// ويدجت مساعد لبناء عنصر واحد في قائمة الأنشطة.
  Widget _buildActivityTile(RecentActivity activity, ThemeData theme) {
    return ListTile(
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      leading: const Icon(Icons.chevron_left, color: Colors.grey),
      title: Text(activity.title,
          style: theme.textTheme.titleMedium, textAlign: TextAlign.right),
      subtitle: Text(
        _formatTimestamp(activity.timestamp),
        style: theme.textTheme.bodySmall,
        textAlign: TextAlign.right,
      ),
      trailing: CircleAvatar(
        backgroundColor: theme.colorScheme.primary.withOpacity(0.1),
        child: Icon(
          activity.type == 'lab'
              ? Icons.science_outlined
              : Icons.computer_outlined,
          color: theme.colorScheme.primary,
        ),
      ),
      onTap: () {
        if (activity.type == 'lab') {
          if (activity.originalObject is LabModel) {
            _navigateAndReload(
                LabDetailsScreen(lab: activity.originalObject as LabModel));
          }
        } else if (activity.type == 'device') {
          if (activity.originalObject is DeviceModel) {
            _navigateAndReload(ViewDeviceScreen(
                device: activity.originalObject as DeviceModel));
          }
        }
      },
    );
  }

  //------------------------------------------------------------------------------

  /// ويدجت مساعد لبناء واجهة عرض الخطأ.
  Widget _buildErrorState(ThemeData theme, String errorMessage) {
    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
          side: BorderSide(color: theme.colorScheme.error.withOpacity(0.5))),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 48.0, horizontal: 16.0),
        child: Column(
          children: [
            Icon(Icons.error_outline, color: theme.colorScheme.error, size: 40),
            const SizedBox(height: 16),
            Text(errorMessage,
                style: theme.textTheme.titleMedium,
                textAlign: TextAlign.center),
            const SizedBox(height: 8),
            TextButton(
                onPressed: _loadData, child: const Text('إعادة المحاولة'))
          ],
        ),
      ),
    );
  }
}
