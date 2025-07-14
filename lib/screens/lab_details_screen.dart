import 'dart:io'; // للتعامل مع الملفات، مثل التحقق من وجود صورة المعمل.
import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart'; // مكتبة لفتح الروابط الخارجية مثل روابط خرائط جوجل.

import '../models/device_model.dart'; // نموذج بيانات الجهاز.
import '../models/lab_model.dart'; // نموذج بيانات المعمل.
import 'package:uquts1/services/firebase_database_service.dart';
import 'add_device_screen.dart'; // شاشة إضافة/تعديل جهاز.
import 'add_lab_screen.dart'; // شاشة إضافة/تعديل معمل.
import '../utils/ui_helpers.dart'; // دوال مساعدة لعرض عناصر واجهة المستخدم.
import 'view_device_screen.dart'; // شاشة عرض الجهاز فقط. <-- تم التأكيد على الاستيراد

//------------------------------------------------------------------------------

/// ويدجت شاشة تفاصيل المعمل، وهي StatefulWidget لإدارة الحالات الداخلية.
class LabDetailsScreen extends StatefulWidget {
  /// متغير لتخزين بيانات المعمل الذي سيتم عرضه.
  final LabModel lab;

  const LabDetailsScreen({
    super.key,
    required this.lab,
  });

  @override
  State<LabDetailsScreen> createState() => _LabDetailsScreenState();
}

//------------------------------------------------------------------------------

/// كلاس الحالة (State) الخاص بـ LabDetailsScreen.
class _LabDetailsScreenState extends State<LabDetailsScreen> {
  // --- متغيرات الحالة (State Variables) ---
  late LabModel _currentLab; // لتخزين بيانات المعمل الحالية، ويمكن تحديثها.
  bool _isLoading = true; // لتتبع حالة تحميل قائمة الأجهزة.
  List<DeviceModel> _devices = []; // قائمة لتخزين الأجهزة الموجودة في المعمل.

  //------------------------------------------------------------------------------

  // خريطة لتوفير مواقع افتراضية للكليات في حال لم يكن للمعمل موقع محدد.
  final Map<String, String> _collegeLocations = {
    'كلية الهندسة': 'https://maps.app.goo.gl/4PfbWDc36XAdfRnM7',
    'كلية الطب': 'https://maps.app.goo.gl/mSET1C88At97o6s46',
    'كلية الحاسب الآلي': 'https://maps.app.goo.gl/yfHBYYpfLaoWu1qd8',
    'كلية العلوم': 'https://maps.app.goo.gl/iVGvJTV6e1Vquxqt6',
    'كلية الإدارة والاقتصاد': 'https://maps.app.goo.gl/7ysTpqfdpZPPQTAn8',
  };

  //------------------------------------------------------------------------------

  /// دالة initState: يتم استدعاؤها مرة واحدة عند إنشاء الويدجت.
  @override
  void initState() {
    super.initState();
    // تهيئة متغير الحالة بالبيانات الممررة من الويدجت.
    _currentLab = widget.lab;
    _loadLabDetails(); // تحميل أحدث تفاصيل المعمل.
    _loadDevices(); // تحميل الأجهزة المرتبطة بالمعمل.
  }

  //------------------------------------------------------------------------------

  /// دالة لجلب أحدث تفاصيل المعمل من قاعدة البيانات.
  /// هذا يضمن أن البيانات المعروضة محدثة دائمًا.
  Future<void> _loadLabDetails() async {
    try {
      final updatedLab =
          await FirebaseDatabaseService.getLabById(_currentLab.id);
      if (updatedLab != null && mounted) {
        setState(() {
          _currentLab = updatedLab; // تحديث الحالة بالبيانات الجديدة.
        });
      }
    } catch (e) {
      debugPrint('خطأ في تحديث تفاصيل المعمل: $e');
    }
  }

  //------------------------------------------------------------------------------

  /// دالة غير متزامنة لتحميل قائمة الأجهزة الخاصة بالمعمل.
  Future<void> _loadDevices() async {
    try {
      if (mounted) setState(() => _isLoading = true);
      // استخدام دالة getDevicesForLab لجلب الأجهزة المرتبطة بالمعمل مباشرة.
      final labDevices =
          await FirebaseDatabaseService.getDevicesForLab(_currentLab.id);

      if (mounted) {
        setState(() {
          _devices = labDevices;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
        UIHelpers.showErrorSnackBar(context, 'خطأ في تحميل الأجهزة: $e');
      }
    }
  }

  //------------------------------------------------------------------------------

  /// دالة لفتح موقع المعمل في خرائط جوجل.
  Future<void> _openLocationInMaps() async {
    // استخدام رابط الموقع المخصص للمعمل، أو الرابط الافتراضي للكلية كخيار بديل.
    final locationUrl = _currentLab.locationUrl ??
        _collegeLocations[_currentLab.college] ??
        'https://maps.app.goo.gl/4PfbWDc36XAdfRnM7';

    final Uri url = Uri.parse(locationUrl);
    // محاولة فتح الرابط في تطبيق خارجي (خرائط جوجل).
    if (!await launchUrl(url, mode: LaunchMode.externalApplication)) {
      if (mounted) {
        UIHelpers.showErrorSnackBar(context, 'تعذر فتح الموقع');
      }
    }
  }

  //------------------------------------------------------------------------------

  /// دالة بناء الواجهة الرئيسية للشاشة.
  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: Text('تفاصيل المعمل ${_currentLab.labNumber}'),
        backgroundColor: theme.colorScheme.primary,
        foregroundColor: theme.colorScheme.onPrimary,
        actions: [
          // زر "تعديل" للانتقال إلى شاشة تعديل المعمل.
          IconButton(
            icon: const Icon(Icons.edit),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => AddLabScreen(lab: _currentLab),
                ),
                // استخدام .then() لتحديث البيانات تلقائيًا بعد العودة من شاشة التعديل.
              ).then((_) {
                _loadLabDetails();
                _loadDevices();
              });
            },
          ),
        ],
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // عرض صورة المعمل إن وجدت.
              if (_currentLab.imagePath != null &&
                  // التحقق إذا كان المسار يبدأ بـ 'http' (يعني أنه URL)
                  _currentLab.imagePath!.startsWith('http'))
                GestureDetector(
                  onTap: () {
                    // عرض الصورة في نافذة منبثقة عند الضغط عليها.
                    UIHelpers.showImageDialog(
                      context: context,
                      imageUrl: _currentLab.imagePath!, // تمرير URL الصورة
                    );
                  },
                  child: Container(
                    height: 250,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: theme.colorScheme.primary),
                    ),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(12),
                      child: Image.network(
                        // استخدام Image.network لـ URL
                        _currentLab.imagePath!,
                        fit: BoxFit.cover,
                        loadingBuilder: (context, child, loadingProgress) {
                          if (loadingProgress == null) return child;
                          return Center(
                            child: CircularProgressIndicator(
                              value: loadingProgress.expectedTotalBytes != null
                                  ? loadingProgress.cumulativeBytesLoaded /
                                      loadingProgress.expectedTotalBytes!
                                  : null,
                            ),
                          );
                        },
                        errorBuilder: (context, error, stackTrace) {
                          return Center(
                            child: Icon(Icons.broken_image,
                                size: 50, color: theme.colorScheme.error),
                          );
                        },
                      ),
                    ),
                  ),
                )
              else
                // عرض عنصر نائب في حال عدم وجود صورة أو كانت مسارًا محليًا غير صالح.
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Row(
                      children: [
                        Icon(Icons.image_not_supported,
                            color: theme.colorScheme.primary),
                        const SizedBox(width: 16),
                        Text('لم يتم إضافة صورة للمعمل',
                            style: theme.textTheme.bodyLarge),
                      ],
                    ),
                  ),
                ),
              const SizedBox(height: 16),

              // بطاقة معلومات المعمل.
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('معلومات المعمل', style: theme.textTheme.titleLarge),
                      const SizedBox(height: 16),
                      // بناء صفوف التفاصيل باستخدام دالة مساعدة.
                      _buildDetailRow(
                          icon: Icons.numbers,
                          label: 'رقم المعمل',
                          value: _currentLab.labNumber),
                      const SizedBox(height: 8),
                      _buildDetailRow(
                          icon: Icons.school_outlined,
                          label: 'الكلية',
                          value: _currentLab.college),
                      const SizedBox(height: 8),
                      _buildDetailRow(
                          icon: Icons.account_tree_outlined,
                          label: 'القسم',
                          value: _currentLab.department),
                      const SizedBox(height: 8),
                      _buildDetailRow(
                          icon: Icons.layers_outlined,
                          label: 'الدور',
                          value: _currentLab.floorNumber),
                      const SizedBox(height: 8),
                      // تغيير الأيقونة واللون بناءً على حالة المعمل.
                      _buildDetailRow(
                        icon: _currentLab
                            .status.icon, // استخدام getter من النموذج
                        label: 'الحالة',
                        value: _currentLab
                            .status.displayName, // استخدام getter من النموذج
                        color: _currentLab
                            .status.color, // استخدام getter من النموذج
                      ),
                      const SizedBox(height: 8),
                      // عرض الملاحظات فقط إذا كانت موجودة.
                      if (_currentLab.notes.isNotEmpty)
                        _buildDetailRow(
                            icon: Icons.notes_outlined,
                            label: 'ملاحظات',
                            value: _currentLab.notes),
                      const SizedBox(height: 8),
                      // زر فتح الموقع في خرائط جوجل.
                      ElevatedButton.icon(
                        onPressed: _openLocationInMaps,
                        icon: const Icon(Icons.map_outlined),
                        label: const Text('فتح الموقع في Google Maps'),
                        style: ElevatedButton.styleFrom(
                            minimumSize: const Size(double.infinity, 50)),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 16),

              // بطاقة عرض الأجهزة.
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text('الأجهزة', style: theme.textTheme.titleLarge),
                          // إخفاء زر إضافة جهاز إذا كان المعمل مغلقًا.
                          if (_currentLab.status != LabStatus.closed)
                            IconButton(
                              icon: const Icon(Icons.add),
                              onPressed: () {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (context) =>
                                        AddDeviceScreen(labId: _currentLab.id),
                                  ),
                                ).then((_) =>
                                    _loadDevices()); // تحديث قائمة الأجهزة بعد الإضافة.
                              },
                            ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      // إخفاء قسم الأجهزة بالكامل إذا كان المعمل مغلقًا.
                      if (_currentLab.status != LabStatus.closed)
                        _isLoading
                            ? const Center(child: CircularProgressIndicator())
                            : _devices.isEmpty
                                // عرض رسالة في حال عدم وجود أجهزة.
                                ? Center(
                                    child: Column(
                                      children: [
                                        Icon(Icons.computer_outlined,
                                            size: 64,
                                            color: theme.colorScheme.primary
                                                .withAlpha(128)),
                                        const SizedBox(height: 16),
                                        Text('لا توجد أجهزة مسجلة',
                                            style: theme.textTheme.titleMedium),
                                      ],
                                    ),
                                  )
                                // عرض قائمة الأجهزة.
                                : ListView.builder(
                                    shrinkWrap:
                                        true, // لمنع التعارض مع SingleChildScrollView.
                                    physics:
                                        const NeverScrollableScrollPhysics(),
                                    itemCount: _devices.length,
                                    itemBuilder: (context, index) {
                                      final device = _devices[index];
                                      return Card(
                                        margin:
                                            const EdgeInsets.only(bottom: 8),
                                        child: ListTile(
                                          leading: device.imagePath != null &&
                                                  device.imagePath!
                                                      .startsWith('http')
                                              ? CircleAvatar(
                                                  backgroundImage: NetworkImage(
                                                      device.imagePath!),
                                                  onBackgroundImageError:
                                                      (exception, stackTrace) {
                                                    debugPrint(
                                                        'Error loading device image: $exception');
                                                  },
                                                )
                                              : const CircleAvatar(
                                                  child: Icon(Icons.computer),
                                                ),
                                          title: Text(device.name),
                                          subtitle: Column(
                                            crossAxisAlignment:
                                                CrossAxisAlignment.start,
                                            children: [
                                              Text(device.model),
                                              Text(device.serialNumber),
                                            ],
                                          ),
                                          // تغيير الأيقونة بناءً على حالة الصيانة.
                                          trailing: Icon(
                                            device.needsMaintenance
                                                ? Icons.build_circle
                                                : Icons.check_circle,
                                            color: device.needsMaintenance
                                                ? Colors.orange
                                                : Colors.green,
                                          ),
                                          onTap: () {
                                            // الانتقال إلى شاشة عرض الجهاز (ViewDeviceScreen)
                                            Navigator.push(
                                              // <--- تم التغيير هنا
                                              context,
                                              MaterialPageRoute(
                                                  builder: (context) =>
                                                      ViewDeviceScreen(
                                                          // <--- تم التغيير هنا
                                                          device: device)),
                                            ).then((_) =>
                                                _loadDevices()); // تحديث القائمة بعد العودة.
                                          },
                                        ),
                                      );
                                    },
                                  )
                      else
                        // عرض رسالة بأن المعمل مغلق.
                        Center(
                          child: Column(
                            children: [
                              Icon(Icons.lock_outlined,
                                  size: 64,
                                  color:
                                      theme.colorScheme.error.withAlpha(128)),
                              const SizedBox(height: 16),
                              Text('المعمل مغلق',
                                  style: theme.textTheme.titleMedium?.copyWith(
                                      color: theme.colorScheme.error)),
                              Text('لا يمكن إضافة أو عرض الأجهزة',
                                  style: theme.textTheme.bodyMedium?.copyWith(
                                      color: theme.colorScheme.error
                                          .withAlpha(179))),
                            ],
                          ),
                        ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  //------------------------------------------------------------------------------

  /// دالة مساعدة قابلة لإعادة الاستخدام لبناء صف تفصيلي منسق.
  Widget _buildDetailRow(
      {required IconData icon,
      required String label,
      required String value,
      Color? color}) {
    return Row(
      children: [
        Icon(icon, color: color ?? Colors.grey[700]),
        const SizedBox(width: 12),
        Text('$label: ', style: const TextStyle(fontWeight: FontWeight.bold)),
        Expanded(child: Text(value, style: TextStyle(color: color))),
      ],
    );
  }
}

//------------------------------------------------------------------------------

/// إضافة Getters إلى Enum لتحسين قراءة الكود في واجهة المستخدم وتجميع المنطق.
extension LabStatusExtension on LabStatus {
  /// ترجع نصاً قابلاً للعرض لحالة المعمل.
  String get displayName {
    switch (this) {
      case LabStatus.openWithDevices:
        return 'مفتوح مع أجهزة';
      case LabStatus.openNoDevices:
        return 'يوجد مشكلة';
      case LabStatus.closed:
        return 'مغلق';
    }
  }

  /// ترجع أيقونة مناسبة لحالة المعمل.
  IconData get icon {
    switch (this) {
      case LabStatus.openWithDevices:
        return Icons.check_circle;
      case LabStatus.openNoDevices:
        return Icons.warning;
      case LabStatus.closed:
        return Icons.cancel;
    }
  }

  /// ترجع لوناً مناسباً لحالة المعمل.
  Color get color {
    switch (this) {
      case LabStatus.openWithDevices:
        return Colors.green;
      case LabStatus.openNoDevices:
        return Colors.orange;
      case LabStatus.closed:
        return Colors.red;
    }
  }
}
