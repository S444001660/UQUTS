import 'dart:io';
import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

import '../models/device_model.dart';
import '../models/lab_model.dart';
import '../services/database_service.dart';
import 'add_device_screen.dart';
import 'add_lab_screen.dart';

class LabDetailsScreen extends StatefulWidget {
  final LabModel lab;

  const LabDetailsScreen({
    super.key,
    required this.lab,
  });

  @override
  State<LabDetailsScreen> createState() => _LabDetailsScreenState();
}

class _LabDetailsScreenState extends State<LabDetailsScreen> {
  late LabModel _currentLab;
  bool _isLoading = true;
  List<DeviceModel> _devices = [];

  // خرائط الكليات الافتراضية
  final Map<String, String> _collegeLocations = {
    'كلية الهندسة': 'https://maps.app.goo.gl/4PfbWDc36XAdfRnM7',
    'كلية الطب': 'https://maps.app.goo.gl/mSET1C88At97o6s46',
    'كلية الحاسب الآلي': 'https://maps.app.goo.gl/yfHBYYpfLaoWu1qd8',
    'كلية العلوم': 'https://maps.app.goo.gl/iVGvJTV6e1Vquxqt6',
    'كلية الإدارة والاقتصاد': 'https://maps.app.goo.gl/7ysTpqfdpZPPQTAn8',
  };

  @override
  void initState() {
    super.initState();
    // Initialize with the passed lab
    _currentLab = widget.lab;
    _loadLabDetails();
    _loadDevices();
  }

  // دالة جديدة لتحميل تفاصيل المعمل
  Future<void> _loadLabDetails() async {
    try {
      // محاولة جلب أحدث بيانات المعمل من قاعدة البيانات
      final updatedLab = await DatabaseService.getLabById(_currentLab.id);

      if (updatedLab != null && mounted) {
        setState(() {
          _currentLab = updatedLab;
        });
      }
    } catch (e) {
      debugPrint('خطأ في تحديث تفاصيل المعمل: $e');
    }
  }

  Future<void> _loadDevices() async {
    try {
      if (mounted) {
        setState(() => _isLoading = true);
      }
      final devices = await DatabaseService.getDevices();
      final labDevices =
          devices.where((d) => d.labId == _currentLab.id).toList();

      if (mounted) {
        setState(() {
          _devices = labDevices;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('خطأ في تحميل الأجهزة: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  // دالة فتح الموقع في Google Maps
  Future<void> _openLocationInMaps() async {
    // استخدام رابط الموقع المحدد أو الرابط الافتراضي للكلية
    final locationUrl = _currentLab.locationUrl ??
        _collegeLocations[_currentLab.college] ??
        'https://maps.app.goo.gl/4PfbWDc36XAdfRnM7';

    final Uri url = Uri.parse(locationUrl);
    if (!await launchUrl(url, mode: LaunchMode.externalApplication)) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('تعذر فتح الموقع'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: Text('تفاصيل المعمل ${_currentLab.labNumber}'),
        backgroundColor: theme.colorScheme.primary,
        foregroundColor: theme.colorScheme.onPrimary,
        actions: [
          IconButton(
            icon: const Icon(Icons.edit),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => AddLabScreen(lab: _currentLab),
                ),
              ).then((_) {
                // تحديث تفاصيل المعمل والأجهزة بعد التعديل
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
              // صورة المعمل
              if (_currentLab.imagePath != null &&
                  File(_currentLab.imagePath!).existsSync())
                GestureDetector(
                  onTap: () {
                    showDialog(
                      context: context,
                      builder: (context) => Dialog(
                        child: InteractiveViewer(
                          maxScale: 5.0,
                          child: Image.file(
                            File(_currentLab.imagePath!),
                            fit: BoxFit.contain,
                          ),
                        ),
                      ),
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
                      child: Image.file(
                        File(_currentLab.imagePath!),
                        fit: BoxFit.cover,
                      ),
                    ),
                  ),
                )
              else
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Row(
                      children: [
                        Icon(
                          Icons.image_not_supported,
                          color: theme.colorScheme.primary,
                        ),
                        const SizedBox(width: 16),
                        Text(
                          'لم يتم إضافة صورة للمعمل',
                          style: theme.textTheme.bodyLarge,
                        ),
                      ],
                    ),
                  ),
                ),

              const SizedBox(height: 16),

              // معلومات المعمل
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'معلومات المعمل',
                        style: theme.textTheme.titleLarge,
                      ),
                      const SizedBox(height: 16),
                      _buildDetailRow(
                        icon: Icons.numbers,
                        label: 'رقم المعمل',
                        value: _currentLab.labNumber,
                      ),
                      const SizedBox(height: 8),
                      _buildDetailRow(
                        icon: Icons.school_outlined,
                        label: 'الكلية',
                        value: _currentLab.college,
                      ),
                      const SizedBox(height: 8),
                      _buildDetailRow(
                        icon: Icons.account_tree_outlined,
                        label: 'القسم',
                        value: _currentLab.department,
                      ),
                      const SizedBox(height: 8),
                      _buildDetailRow(
                        icon: Icons.layers_outlined,
                        label: 'الدور',
                        value: _currentLab.floorNumber,
                      ),
                      const SizedBox(height: 8),
                      _buildDetailRow(
                        icon: _currentLab.status == LabStatus.openWithDevices
                            ? Icons.check_circle
                            : _currentLab.status == LabStatus.openNoDevices
                                ? Icons.warning
                                : Icons.cancel,
                        label: 'الحالة',
                        value: _currentLab.status == LabStatus.openWithDevices
                            ? 'مفتوح مع أجهزة'
                            : _currentLab.status == LabStatus.openNoDevices
                                ? 'يوجد مشكلة'
                                : 'مغلق',
                        color: _currentLab.status == LabStatus.openWithDevices
                            ? Colors.green
                            : _currentLab.status == LabStatus.openNoDevices
                                ? Colors.orange
                                : Colors.red,
                      ),
                      const SizedBox(height: 8),
                      // إضافة الملاحظات
                      if (_currentLab.notes.isNotEmpty)
                        _buildDetailRow(
                          icon: Icons.notes_outlined,
                          label: 'ملاحظات',
                          value: _currentLab.notes,
                        ),
                      const SizedBox(height: 8),
                      // زر خرائط جوجل
                      ElevatedButton.icon(
                        onPressed: _openLocationInMaps,
                        icon: const Icon(Icons.map_outlined),
                        label: const Text('فتح الموقع في Google Maps'),
                        style: ElevatedButton.styleFrom(
                          minimumSize: const Size(double.infinity, 50),
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              const SizedBox(height: 16),

              // الأجهزة
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            'الأجهزة',
                            style: theme.textTheme.titleLarge,
                          ),
                          // إخفاء زر إضافة الأجهزة للمعامل المغلقة
                          if (_currentLab.status != LabStatus.closed)
                            IconButton(
                              icon: const Icon(Icons.add),
                              onPressed: () {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (context) => AddDeviceScreen(
                                      labId: _currentLab.id,
                                    ),
                                  ),
                                ).then((_) => _loadDevices());
                              },
                            ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      // إخفاء قسم الأجهزة للمعامل المغلقة
                      if (_currentLab.status != LabStatus.closed)
                        _isLoading
                            ? const Center(child: CircularProgressIndicator())
                            : _devices.isEmpty
                                ? Center(
                                    child: Column(
                                      children: [
                                        Icon(
                                          Icons.computer_outlined,
                                          size: 64,
                                          color: theme.colorScheme.primary
                                              .withAlpha(128), // 0.5 opacity
                                        ),
                                        const SizedBox(height: 16),
                                        Text(
                                          'لا توجد أجهزة مسجلة',
                                          style: theme.textTheme.titleMedium,
                                        ),
                                      ],
                                    ),
                                  )
                                : ListView.builder(
                                    shrinkWrap: true,
                                    physics:
                                        const NeverScrollableScrollPhysics(),
                                    itemCount: _devices.length,
                                    itemBuilder: (context, index) {
                                      final device = _devices[index];
                                      return Card(
                                        margin:
                                            const EdgeInsets.only(bottom: 8),
                                        child: ListTile(
                                          title: Text(device.name),
                                          subtitle: Column(
                                            crossAxisAlignment:
                                                CrossAxisAlignment.start,
                                            children: [
                                              Text(device.model),
                                              Text(device.serialNumber),
                                            ],
                                          ),
                                          trailing: Icon(
                                            device.needsMaintenance
                                                ? Icons.build_circle
                                                : Icons.check_circle,
                                            color: device.needsMaintenance
                                                ? Colors.orange
                                                : Colors.green,
                                          ),
                                          onTap: () {
                                            Navigator.push(
                                              context,
                                              MaterialPageRoute(
                                                builder: (context) =>
                                                    AddDeviceScreen(
                                                        device: device),
                                              ),
                                            ).then((_) => _loadDevices());
                                          },
                                        ),
                                      );
                                    },
                                  )
                      else
                        Center(
                          child: Column(
                            children: [
                              Icon(
                                Icons.lock_outlined,
                                size: 64,
                                color: theme.colorScheme.error
                                    .withAlpha(128), // 0.5 opacity
                              ),
                              const SizedBox(height: 16),
                              Text(
                                'المعمل مغلق',
                                style: theme.textTheme.titleMedium?.copyWith(
                                  color: theme.colorScheme.error,
                                ),
                              ),
                              Text(
                                'لا يمكن إضافة أو عرض الأجهزة',
                                style: theme.textTheme.bodyMedium?.copyWith(
                                  color: theme.colorScheme.error
                                      .withAlpha(179), // 0.7 opacity
                                ),
                              ),
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

  // دالة مساعدة لبناء صف التفاصيل
  Widget _buildDetailRow({
    required IconData icon,
    required String label,
    required String value,
    Color? color,
  }) {
    return Row(
      children: [
        Icon(icon, color: color ?? Colors.grey[700]),
        const SizedBox(width: 12),
        Text(
          '$label: ',
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        Expanded(
          child: Text(
            value,
            style: TextStyle(color: color),
          ),
        ),
      ],
    );
  }
}
