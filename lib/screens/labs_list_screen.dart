import 'package:flutter/material.dart';
import '../models/lab_model.dart';
import '../services/database_service.dart';
import 'add_lab_screen.dart';
import 'lab_details_screen.dart';

class LabsListScreen extends StatefulWidget {
  const LabsListScreen({super.key});

  @override
  State<LabsListScreen> createState() => _LabsListScreenState();
}

class _LabsListScreenState extends State<LabsListScreen> {
  List<LabModel> _allLabs = [];
  List<LabModel> _filteredLabs = [];
  bool _isLoading = true;

  // Map to store device counts for each lab
  Map<String, int> _labDeviceCounts = {};

  // Search and filter controllers
  final TextEditingController _searchController = TextEditingController();
  LabStatus? _selectedStatus;
  String? _selectedCollege;
  String? _selectedFloor;

  // Dropdown options
  final List<String> _colleges = [
    'جميع الكليات',
    'كلية الهندسة',
    'كلية الطب',
    'كلية الحاسب الآلي',
    'كلية العلوم',
    'كلية الإدارة والاقتصاد',
  ];

  final List<String> _floors = [
    'جميع الأدوار',
    'الدور الأرضي',
    'الدور الأول',
    'الدور الثاني',
    'الدور الثالث',
  ];

  @override
  void initState() {
    super.initState();
    _selectedCollege = _colleges.first;
    _selectedFloor = _floors.first;
    _loadLabs();
    _searchController.addListener(_filterLabs);
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadLabs() async {
    try {
      setState(() => _isLoading = true);

      // Remove old labs (older than 3 months)
      await DatabaseService.removeOldLabs();

      // Get all labs
      final labs = await DatabaseService.getLabs();

      // Get all devices
      final devices = await DatabaseService.getDevices();

      // Calculate device counts for each lab
      final labDeviceCounts = <String, int>{};
      for (var device in devices) {
        if (device.labId.isNotEmpty) {
          labDeviceCounts[device.labId] =
              (labDeviceCounts[device.labId] ?? 0) + 1;
        }
      }

      setState(() {
        _allLabs = labs;
        _filteredLabs = labs;
        _labDeviceCounts = labDeviceCounts;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
    }
  }

  void _filterLabs() {
    final query = _searchController.text.toLowerCase();
    setState(() {
      _filteredLabs = _allLabs.where((lab) {
        // Search condition
        final matchesSearch = lab.labNumber.toLowerCase().contains(query) ||
            lab.college.toLowerCase().contains(query) ||
            lab.department.toLowerCase().contains(query);

        // College filter condition
        final matchesCollege = _selectedCollege == _colleges.first ||
            lab.college == _selectedCollege;

        // Floor filter condition
        final matchesFloor = _selectedFloor == _floors.first ||
            lab.floorNumber == _selectedFloor;

        // Status filter condition
        final matchesStatus =
            _selectedStatus == null || lab.status == _selectedStatus;

        return matchesSearch && matchesCollege && matchesFloor && matchesStatus;
      }).toList();
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('المعامل'),
        backgroundColor: theme.colorScheme.primary,
        foregroundColor: theme.colorScheme.onPrimary,
        actions: [
          // Filter Button
          IconButton(
            icon: const Icon(Icons.filter_list),
            onPressed: _showFilterBottomSheet,
          ),
          IconButton(
            icon: const Icon(Icons.add),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const AddLabScreen(),
                ),
              ).then((_) => _loadLabs());
            },
          ),
        ],
      ),
      body: Column(
        children: [
          // Search Bar
          Padding(
            padding: const EdgeInsets.all(16),
            child: TextField(
              controller: _searchController,
              decoration: InputDecoration(
                hintText: 'البحث في المعامل',
                prefixIcon: const Icon(Icons.search),
                suffixIcon: _searchController.text.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.clear),
                        onPressed: () {
                          _searchController.clear();
                          _filterLabs();
                        },
                      )
                    : null,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              onChanged: (_) => _filterLabs(),
            ),
          ),

          // Labs List
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : _filteredLabs.isEmpty
                    ? Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.science_outlined,
                              size: 64,
                              color: theme.colorScheme.primary.withAlpha(128),
                            ),
                            const SizedBox(height: 16),
                            Text(
                              'لا توجد معامل مسجلة',
                              style: theme.textTheme.titleLarge?.copyWith(
                                color:
                                    theme.colorScheme.onSurface.withAlpha(178),
                              ),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              'اضغط على + لإضافة معمل جديد',
                              style: theme.textTheme.bodyMedium?.copyWith(
                                color:
                                    theme.colorScheme.onSurface.withAlpha(128),
                              ),
                            ),
                          ],
                        ),
                      )
                    : ListView.builder(
                        padding: const EdgeInsets.all(8),
                        itemCount: _filteredLabs.length,
                        itemBuilder: (context, index) {
                          final lab = _filteredLabs[index];
                          // Get device count for this lab
                          final deviceCount = _labDeviceCounts[lab.id] ?? 0;

                          return Card(
                            margin: const EdgeInsets.only(bottom: 8),
                            child: ListTile(
                              title: Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
                                children: [
                                  Text('معمل ${lab.labNumber}'),
                                  // عداد الأجهزة
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                        horizontal: 8, vertical: 4),
                                    decoration: BoxDecoration(
                                      color: deviceCount > 0
                                          ? theme.colorScheme.primary
                                              .withAlpha(26)
                                          : theme.colorScheme.error
                                              .withAlpha(26),
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                    child: Text(
                                      'عدد الأجهزة: $deviceCount',
                                      style:
                                          theme.textTheme.bodySmall?.copyWith(
                                        color: deviceCount > 0
                                            ? theme.colorScheme.primary
                                            : theme.colorScheme.error,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                              subtitle: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
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
                                        : lab.status == LabStatus.openNoDevices
                                            ? Icons.warning
                                            : Icons.cancel,
                                    color: lab.status ==
                                            LabStatus.openWithDevices
                                        ? Colors.green
                                        : lab.status == LabStatus.openNoDevices
                                            ? Colors.orange
                                            : Colors.red,
                                  ),
                                ],
                              ),
                              onTap: () => Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) =>
                                      LabDetailsScreen(lab: lab),
                                ),
                              ).then((_) => _loadLabs()),
                            ),
                          );
                        },
                      ),
          ),
        ],
      ),
    );
  }

  // New method to show filter bottom sheet
  void _showFilterBottomSheet() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            return Padding(
              padding: EdgeInsets.only(
                bottom: MediaQuery.of(context).viewInsets.bottom,
                top: 16,
                left: 16,
                right: 16,
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Text(
                    'تصفية المعامل',
                    style: Theme.of(context).textTheme.titleLarge,
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 16),

                  // College Dropdown
                  DropdownButtonFormField<String>(
                    value: _selectedCollege,
                    decoration: const InputDecoration(
                      labelText: 'الكلية',
                      border: OutlineInputBorder(),
                    ),
                    items: _colleges.map((college) {
                      return DropdownMenuItem(
                        value: college,
                        child: Text(college),
                      );
                    }).toList(),
                    onChanged: (value) {
                      setModalState(() {
                        _selectedCollege = value;
                      });
                    },
                  ),
                  const SizedBox(height: 16),

                  // Floor Dropdown
                  DropdownButtonFormField<String>(
                    value: _selectedFloor,
                    decoration: const InputDecoration(
                      labelText: 'الدور',
                      border: OutlineInputBorder(),
                    ),
                    items: _floors.map((floor) {
                      return DropdownMenuItem(
                        value: floor,
                        child: Text(floor),
                      );
                    }).toList(),
                    onChanged: (value) {
                      setModalState(() {
                        _selectedFloor = value;
                      });
                    },
                  ),
                  const SizedBox(height: 16),

                  // Status Dropdown
                  DropdownButtonFormField<LabStatus?>(
                    value: _selectedStatus,
                    decoration: const InputDecoration(
                      labelText: 'الحالة',
                      border: OutlineInputBorder(),
                    ),
                    items: const [
                      DropdownMenuItem(
                        value: null,
                        child: Text('جميع الحالات'),
                      ),
                      DropdownMenuItem(
                        value: LabStatus.openWithDevices,
                        child: Row(
                          children: [
                            Icon(Icons.check_circle, color: Colors.green),
                            SizedBox(width: 8),
                            Text('مفتوح مع أجهزة'),
                          ],
                        ),
                      ),
                      DropdownMenuItem(
                        value: LabStatus.openNoDevices,
                        child: Row(
                          children: [
                            Icon(Icons.warning, color: Colors.orange),
                            SizedBox(width: 8),
                            Text('يوجد مشكلة'),
                          ],
                        ),
                      ),
                      DropdownMenuItem(
                        value: LabStatus.closed,
                        child: Row(
                          children: [
                            Icon(Icons.cancel, color: Colors.red),
                            SizedBox(width: 8),
                            Text('مغلق'),
                          ],
                        ),
                      ),
                    ],
                    onChanged: (value) {
                      setModalState(() {
                        _selectedStatus = value;
                      });
                    },
                  ),
                  const SizedBox(height: 16),

                  // Apply and Reset Buttons
                  Row(
                    children: [
                      Expanded(
                        child: ElevatedButton(
                          onPressed: () {
                            _filterLabs();
                            Navigator.pop(context);
                          },
                          child: const Text('تطبيق التصفية'),
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: TextButton(
                          onPressed: () {
                            setState(() {
                              _selectedCollege = _colleges.first;
                              _selectedFloor = _floors.first;
                              _selectedStatus = null;
                              _searchController.clear();
                            });
                            _filterLabs();
                            Navigator.pop(context);
                          },
                          child: const Text('إعادة تعيين'),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                ],
              ),
            );
          },
        );
      },
    );
  }
}
