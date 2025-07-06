import 'package:flutter/material.dart';
import '../models/lab_model.dart';
import '../services/database_service.dart';
import 'add_lab_screen.dart';
import 'lab_details_screen.dart';

class LabsScreen extends StatefulWidget {
  const LabsScreen({super.key});

  @override
  State<LabsScreen> createState() => _LabsScreenState();
}

class _LabsScreenState extends State<LabsScreen> {
  String? _selectedFloor;
  String? _selectedCollege;
  List<LabModel> _labs = [];
  bool _isLoading = true;
  String? _error;

  final List<String> _floors = [
    'جميع الأدوار',
    'الدور الأول',
    'الدور الثاني',
    'الدور الثالث',
  ];

  final List<String> _colleges = [
    'جميع الكليات',
    'كلية الهندسة',
    'كلية الطب',
    'كلية الحاسب الآلي',
    'كلية العلوم',
    'كلية الإدارة والاقتصاد',
  ];

  @override
  void initState() {
    super.initState();
    _selectedFloor = _floors.first;
    _selectedCollege = _colleges.first;
    _loadLabs();
  }

  Future<void> _loadLabs() async {
    try {
      setState(() => _isLoading = true);
      if (_selectedCollege != null && _selectedCollege != _colleges.first) {
        _labs = await DatabaseService.getLabsByCollege(_selectedCollege!);
      } else {
        _labs = await DatabaseService.getLabs();
      }

      if (_selectedFloor != null && _selectedFloor != _floors.first) {
        _labs =
            _labs.where((lab) => lab.floorNumber == _selectedFloor).toList();
      }

      setState(() {
        _isLoading = false;
        _error = null;
      });
    } catch (e) {
      setState(() {
        _error = e.toString();
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('المعامل'),
        backgroundColor: theme.colorScheme.primary,
        foregroundColor: theme.colorScheme.onPrimary,
      ),
      body: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            color: theme.colorScheme.primary,
            child: Row(
              children: [
                Expanded(
                  child: _buildDropdown(
                    value: _selectedFloor,
                    items: _floors,
                    onChanged: (value) {
                      setState(() => _selectedFloor = value);
                      _loadLabs();
                    },
                    hint: 'الدور',
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: _buildDropdown(
                    value: _selectedCollege,
                    items: _colleges,
                    onChanged: (value) {
                      setState(() => _selectedCollege = value);
                      _loadLabs();
                    },
                    hint: 'الكلية',
                  ),
                ),
              ],
            ),
          ),
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : _error != null
                    ? Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.error_outline,
                              size: 64,
                              color: theme.colorScheme.error,
                            ),
                            const SizedBox(height: 16),
                            Text(
                              'حدث خطأ: $_error',
                              style: theme.textTheme.titleMedium,
                              textAlign: TextAlign.center,
                            ),
                            const SizedBox(height: 16),
                            FilledButton.icon(
                              onPressed: _loadLabs,
                              icon: const Icon(Icons.refresh),
                              label: const Text('إعادة المحاولة'),
                            ),
                          ],
                        ),
                      )
                    : _labs.isEmpty
                        ? Center(
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(
                                  Icons.science_outlined,
                                  size: 64,
                                  color:
                                      theme.colorScheme.primary.withAlpha(128),
                                ),
                                const SizedBox(height: 16),
                                Text(
                                  'لا توجد معامل مسجلة',
                                  style: theme.textTheme.titleLarge?.copyWith(
                                    color: theme.colorScheme.onSurface
                                        .withAlpha(179),
                                  ),
                                ),
                                const SizedBox(height: 8),
                                Text(
                                  'اضغط على + لإضافة معمل جديد',
                                  style: theme.textTheme.bodyMedium?.copyWith(
                                    color: theme.colorScheme.onSurface
                                        .withAlpha(179),
                                  ),
                                ),
                              ],
                            ),
                          )
                        : ListView.builder(
                            padding: const EdgeInsets.all(8),
                            itemCount: _labs.length,
                            itemBuilder: (context, index) {
                              final lab = _labs[index];
                              return Card(
                                margin: const EdgeInsets.only(bottom: 8),
                                child: ListTile(
                                  title: Text('معمل ${lab.labNumber}'),
                                  subtitle: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(lab.college),
                                      Text(lab.department),
                                    ],
                                  ),
                                  trailing: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Text(lab.floorNumber),
                                      const SizedBox(width: 8),
                                      Icon(
                                        lab.status == LabStatus.openWithDevices
                                            ? Icons.check_circle
                                            : lab.status ==
                                                    LabStatus.openNoDevices
                                                ? Icons.warning
                                                : Icons.cancel,
                                        color: lab.status ==
                                                LabStatus.openWithDevices
                                            ? Colors.green
                                            : lab.status ==
                                                    LabStatus.openNoDevices
                                                ? Colors.orange
                                                : Colors.red,
                                      ),
                                    ],
                                  ),
                                  onTap: () {
                                    if (lab.locationUrl == null ||
                                        lab.locationUrl!.isEmpty) {
                                      ScaffoldMessenger.of(context)
                                          .showSnackBar(
                                        const SnackBar(
                                          content:
                                              Text('لم يتم تحديد موقع للمعمل'),
                                          backgroundColor: Colors.red,
                                        ),
                                      );
                                      return;
                                    }

                                    Navigator.push(
                                      context,
                                      MaterialPageRoute(
                                        builder: (context) =>
                                            LabDetailsScreen(lab: lab),
                                      ),
                                    ).then((_) => _loadLabs());
                                  },
                                ),
                              );
                            },
                          ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => const AddLabScreen(),
          ),
        ).then((_) => _loadLabs()),
        backgroundColor: theme.colorScheme.primary,
        foregroundColor: theme.colorScheme.onPrimary,
        child: const Icon(Icons.add),
      ),
    );
  }

  Widget _buildDropdown({
    required String? value,
    required List<String> items,
    required ValueChanged<String?> onChanged,
    required String hint,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
      ),
      child: DropdownButton<String>(
        value: value,
        items: items.map((item) {
          return DropdownMenuItem(
            value: item,
            child: Text(item),
          );
        }).toList(),
        onChanged: onChanged,
        isExpanded: true,
        hint: Text(hint),
        underline: const SizedBox(),
        icon: const Icon(Icons.arrow_drop_down),
      ),
    );
  }
}
