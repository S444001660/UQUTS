// lib/screens/device_details_screen.dart
import 'package:flutter/material.dart';
import 'package:barcode_widget/barcode_widget.dart';
import '../models/device_model.dart';
import 'add_device_screen.dart';

class DeviceDetailsScreen extends StatefulWidget {
  final DeviceModel device;

  const DeviceDetailsScreen({super.key, required this.device});

  @override
  State<DeviceDetailsScreen> createState() => _DeviceDetailsScreenState();
}

class _DeviceDetailsScreenState extends State<DeviceDetailsScreen> {
  bool _showQRCode = false;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('تفاصيل الجهاز'),
        actions: [
          IconButton(
            icon: const Icon(Icons.edit),
            onPressed: () => Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => AddDeviceScreen(device: widget.device),
              ),
            ),
          ),
        ],
      ),
      body: CustomScrollView(
        slivers: [
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // QR Code Card
                  Card(
                    child: Column(
                      children: [
                        if (_showQRCode) ...[
                          Padding(
                            padding: const EdgeInsets.all(24),
                            child: AspectRatio(
                              aspectRatio: 1,
                              child: Container(
                                decoration: BoxDecoration(
                                  color: Colors.white,
                                  borderRadius: BorderRadius.circular(16),
                                  border: Border.all(
                                    color: theme.colorScheme.outlineVariant,
                                  ),
                                ),
                                padding: const EdgeInsets.all(16),
                                child: BarcodeWidget(
                                  barcode: Barcode.qrCode(),
                                  data: widget.device.id,
                                  color: theme.colorScheme.primary,
                                ),
                              ),
                            ),
                          ),
                        ],
                        Padding(
                          padding: const EdgeInsets.all(16),
                          child: FilledButton.icon(
                            onPressed: () {
                              if (_showQRCode) {
                                _showBarcodeDialog(context);
                              } else {
                                setState(() => _showQRCode = true);
                              }
                            },
                            icon: const Icon(Icons.qr_code),
                            label: Text(_showQRCode
                                ? 'عرض الباركود'
                                : 'إنشاء الباركود'),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),

                  // Device Info Card
                  Card(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Padding(
                          padding: const EdgeInsets.all(16),
                          child: Text(
                            'معلومات الجهاز',
                            style: theme.textTheme.titleLarge,
                          ),
                        ),
                        const Divider(height: 1),
                        _buildDetailTile(
                          context,
                          icon: Icons.business,
                          label: 'الكلية',
                          value: widget.device.college,
                        ),
                        _buildDetailTile(
                          context,
                          icon: Icons.laptop,
                          label: 'الموديل',
                          value: widget.device.model,
                        ),
                        _buildDetailTile(
                          context,
                          icon: Icons.numbers,
                          label: 'السيريال نمبر',
                          value: widget.device.serialNumber,
                        ),
                        _buildDetailTile(
                          context,
                          icon: Icons.memory,
                          label: 'المعالج',
                          value: widget.device.processor,
                        ),
                        _buildDetailTile(
                          context,
                          icon: Icons.storage,
                          label: 'نوع التخزين',
                          value: widget.device.storageType,
                        ),
                        _buildDetailTile(
                          context,
                          icon: Icons.sd_storage,
                          label: 'مساحة التخزين',
                          value: widget.device.storageSize,
                        ),
                        _buildDetailTile(
                          context,
                          icon: Icons.system_update,
                          label: 'إصدار النظام',
                          value: widget.device.osVersion,
                        ),
                        if (widget.device.notes.isNotEmpty)
                          _buildDetailTile(
                            context,
                            icon: Icons.note,
                            label: 'ملاحظات',
                            value: widget.device.notes,
                          ),
                        _buildDetailTile(
                          context,
                          icon: Icons.calendar_today,
                          label: 'تاريخ الإضافة',
                          value: _formatDateTime(widget.device.createdAt),
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
    );
  }

  Widget _buildDetailTile(
    BuildContext context, {
    required IconData icon,
    required String label,
    required String value,
  }) {
    final theme = Theme.of(context);

    return ListTile(
      leading: Icon(icon, color: theme.colorScheme.primary),
      title: Text(
        label,
        style: theme.textTheme.titleMedium,
      ),
      subtitle: Text(
        value,
        style: theme.textTheme.bodyLarge?.copyWith(
          color: theme.colorScheme.onSurfaceVariant,
        ),
      ),
    );
  }

  String _formatDateTime(DateTime dateTime) {
    return '${dateTime.hour.toString().padLeft(2, '0')}:${dateTime.minute.toString().padLeft(2, '0')} – '
        '${dateTime.year}-${dateTime.month.toString().padLeft(2, '0')}-${dateTime.day.toString().padLeft(2, '0')}';
  }

  void _showBarcodeDialog(BuildContext context) {
    final theme = Theme.of(context);

    showDialog(
      context: context,
      builder: (context) => Dialog(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'باركود الجهاز',
                style: theme.textTheme.titleLarge,
              ),
              const SizedBox(height: 24),
              AspectRatio(
                aspectRatio: 1,
                child: Container(
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color: theme.colorScheme.outlineVariant,
                    ),
                  ),
                  padding: const EdgeInsets.all(16),
                  child: BarcodeWidget(
                    barcode: Barcode.qrCode(),
                    data: widget.device.id,
                    color: theme.colorScheme.primary,
                  ),
                ),
              ),
              const SizedBox(height: 24),
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('إغلاق'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
