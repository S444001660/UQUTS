// lib/screens/add_device_screen.dart
import 'package:flutter/material.dart';
import 'package:uuid/uuid.dart';
import '../models/device_model.dart';
import '../models/lab_model.dart';
import '../services/database_service.dart';
import '../services/barcode_service.dart';
import 'dart:io';
import 'package:image_picker/image_picker.dart';

class AddDeviceScreen extends StatefulWidget {
  final DeviceModel? device;
  final String? labId;

  const AddDeviceScreen({
    super.key,
    this.device,
    this.labId,
  });

  @override
  State<AddDeviceScreen> createState() => _AddDeviceScreenState();
}

class _AddDeviceScreenState extends State<AddDeviceScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _collegeController = TextEditingController();
  final _modelController = TextEditingController();
  final _serialNumberController = TextEditingController();
  final _processorController = TextEditingController();
  final _storageTypeController = TextEditingController();
  final _storageSizeController = TextEditingController();
  final _osVersionController = TextEditingController();
  final _notesController = TextEditingController();
  final _barcodeController = TextEditingController();
  final _assetCodeController = TextEditingController();
  bool _hasExtraStorage = false;
  bool _needsMaintenance = false;
  String? _selectedLabId;
  List<LabModel> _availableLabs = [];
  bool _isLoading = false;
  String? _selectedDepartment;
  Map<String, List<String>> _departments = {};
  String? _error;
  String? _extraStorageType;
  String? _extraStorageSize;
  String? _selectedCollege;

  File? _capturedImage;

  Future<void> _pickImageFromCamera() async {
    final picked = await ImagePicker().pickImage(source: ImageSource.camera);
    if (picked != null) {
      setState(() {
        _capturedImage = File(picked.path);
      });
    }
  }

  // Predefined lists for dropdowns
  final List<String> _colleges = [
    'كلية الهندسة',
    'كلية الطب',
    'كلية الحاسب الآلي',
    'كلية العلوم',
    'كلية الإدارة والاقتصاد',
  ];

  final List<String> _models = [
    'HP Compaq 6005 Pro Microtower PC',
    'Lenovo A740 AIO',
    'HP Z2 Mini G4 Workstation',
    'HP Elite Mini 800 G9 Desktop PC',
    'HP EliteOne 800 G3 All-in-One PC',
  ];

  final List<String> _processors = [
    'Core 2',
    'Core i3',
    'Core i5',
    'Core i7',
    'Core i9',
  ];

  final List<String> _storageTypes = ['SSD', 'HDD', 'NVME'];

  final List<String> _storageSizes = [
    '128 GB',
    '256 GB',
    '512 GB',
    '1 TB',
    '2 TB',
  ];

  final List<String> _osVersions = [
    'Windows 7',
    'Windows 10',
    'Windows 11',
    'macOS',
    'Linux',
  ];

  // تهيئة قائمة الأقسام
  void _initializeDepartments() {
    _departments = {
      'كلية الهندسة': {
        'قسم الهندسة الكهربائية',
        'قسم الهندسة المدنية',
        'قسم الهندسة الميكانيكية',
        'قسم هندسة الحاسب',
        'قسم الهندسة الصناعية',
      }.toList(), // Remove duplicates
      'كلية الطب': {
        'قسم الطب البشري',
        'قسم طب الأسنان',
        'قسم العلوم الطبية التطبيقية',
      }.toList(),
      'كلية الحاسب الآلي': {
        'قسم علوم الحاسب',
        'قسم نظم المعلومات',
        'قسم تقنية المعلومات',
      }.toList(),
      'كلية العلوم': {
        'قسم الرياضيات',
        'قسم الفيزياء',
        'قسم الكيمياء',
        'قسم الأحياء',
      }.toList(),
      'كلية الإدارة والاقتصاد': {
        'قسم إدارة الأعمال',
        'قسم المحاسبة',
        'قسم الاقتصاد',
        'قسم التسويق',
      }.toList(),
    };
  }

  @override
  void initState() {
    super.initState();

    // تهيئة قائمة الأقسام
    _initializeDepartments();

    _selectedLabId = widget.labId ?? widget.device?.labId;
    _loadLabs();

    // Load device data if editing an existing device
    if (widget.device != null) {
      _loadDeviceData(widget.device!);
    }

    // تحديد كلية الجهاز تلقائيًا بناءً على المعمل
    if (_selectedLabId != null) {
      _loadLabDetails(_selectedLabId!);
    }
  }

  // دالة تحميل المعامل مع التأكد من عدم وجود قيم null
  Future<void> _loadLabs() async {
    try {
      setState(() => _isLoading = true);
      final labs = await DatabaseService.getLabs();

      // التأكد من أن كل معمل له معلومات صالحة
      _availableLabs = labs
          .where((lab) =>
              (lab.id).isNotEmpty &&
              lab.labNumber.isNotEmpty &&
              lab.college.isNotEmpty)
          .toList();

      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
        debugPrint('خطأ في تحميل المعامل: $e');
      }
    }
  }

  void _loadDeviceData(DeviceModel device) {
    _nameController.text = device.name;
    _collegeController.text = device.college;
    _modelController.text = device.model;
    _serialNumberController.text = device.serialNumber;
    _processorController.text = device.processor;
    _storageTypeController.text = device.storageType;
    _storageSizeController.text = device.storageSize;
    _osVersionController.text = device.osVersion;
    _notesController.text = device.notes;
    _barcodeController.text = device.universityBarcode ?? '';
    _assetCodeController.text = device.assetCode ?? '';

    setState(() {
      _selectedLabId = device.labId;
      _selectedCollege = device.college;
      _selectedDepartment = null; // Will be set by _loadLabDetails

      // Load lab details to set department
      _loadLabDetails(device.labId);

      _hasExtraStorage = device.hasExtraStorage;
      _extraStorageType = device.extraStorageType;
      _extraStorageSize = device.extraStorageSize;
      _needsMaintenance = device.needsMaintenance;

      // استخراج مسار صورة الصيانة من الملاحظات
      final maintenanceImageRegex = RegExp(r'صورة الصيانة: (.+)');
      final match = maintenanceImageRegex.firstMatch(device.notes);
      if (match != null) {
        final imagePath = match.group(1);
        if (imagePath != null && File(imagePath).existsSync()) {
          _capturedImage = File(imagePath);
        }
      }
    });
  }

  // دالة تحميل تفاصيل المعمل
  Future<void> _loadLabDetails(String labId) async {
    try {
      final lab = await DatabaseService.getLabById(labId);
      if (lab != null) {
        if (mounted) {
          setState(() {
            // تعيين الكلية تلقائيًا بناءً على كلية المعمل
            _selectedCollege = lab.college;
            _collegeController.text = lab.college;

            // تحديث قائمة الأقسام بناءً على الكلية
            _updateDepartmentsForCollege(lab.college);

            // تعيين القسم تلقائيًا
            _selectedDepartment = lab.department;
          });
        }
      } else {
        // إذا لم يتم العثور على المعمل
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('لم يتم العثور على تفاصيل المعمل'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('تعذر تحميل تفاصيل المعمل: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  // دالة تحديث قائمة الأقسام
  void _updateDepartmentsForCollege(String college) {
    setState(() {
      // التأكد من أن القسم ينتمي للكلية المحددة
      final departmentsForCollege = _departments[college] ?? [];

      // إذا كان القسم الحالي غير موجود في القائمة، قم بإعادة تعيينه
      if (!departmentsForCollege.contains(_selectedDepartment)) {
        _selectedDepartment = null;
      }
    });
  }

  // دالة إنشاء عناصر القائمة المنسدلة للأقسام
  List<DropdownMenuItem<String>> _buildDepartmentDropdownItems() {
    // التأكد من وجود كلية محددة
    if (_selectedCollege == null || _selectedCollege!.isEmpty) {
      return [];
    }

    // الحصول على قائمة الأقسام للكلية المحددة
    final departments = _departments[_selectedCollege!] ?? [];

    // إنشاء عناصر القائمة المنسدلة
    return departments.map((department) {
      return DropdownMenuItem(
        value: department,
        child: Text(department),
      );
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isEditing = widget.device != null;
    final isLabSelected = _selectedLabId != null;

    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        appBar: AppBar(
          title: Text(isEditing ? 'تعديل جهاز' : 'إضافة جهاز'),
          backgroundColor: theme.colorScheme.primary,
          foregroundColor: theme.colorScheme.onPrimary,
          actions: [
            if (widget.device != null)
              IconButton(
                onPressed: _deleteDevice,
                icon: const Icon(Icons.delete),
                tooltip: 'حذف الجهاز',
              ),
          ],
        ),
        body: _isLoading
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
                : Form(
                    key: _formKey,
                    child: ListView(
                      padding: const EdgeInsets.all(16),
                      children: [
                        // Device Status Card
                        Card(
                          child: Padding(
                            padding: const EdgeInsets.all(16),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'حالة الجهاز',
                                  style: theme.textTheme.titleLarge,
                                ),
                                const SizedBox(height: 16),
                                SwitchListTile(
                                  title: const Text('يحتاج إلى صيانة'),
                                  subtitle: Text(
                                    _needsMaintenance
                                        ? 'الجهاز في حالة صيانة'
                                        : 'الجهاز يعمل بشكل طبيعي',
                                    style: TextStyle(
                                      color: _needsMaintenance
                                          ? Colors.orange
                                          : Colors.green,
                                    ),
                                  ),
                                  value: _needsMaintenance,
                                  onChanged: (value) {
                                    setState(() => _needsMaintenance = value);
                                  },
                                  activeColor: Colors.orange,
                                ),
                              ],
                            ),
                          ),
                        ),
                        const SizedBox(height: 16),
                        // Lab Selection
                        if (_availableLabs.isNotEmpty)
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              DropdownButtonFormField<String>(
                                value: _selectedLabId,
                                decoration: const InputDecoration(
                                  labelText: 'المعمل',
                                  border: OutlineInputBorder(),
                                ),
                                items: _availableLabs.map((lab) {
                                  return DropdownMenuItem(
                                    value: lab.id,
                                    child: Text(
                                        'معمل ${lab.labNumber} - ${lab.college}'),
                                  );
                                }).toList(),
                                onChanged: (value) {
                                  setState(() {
                                    _selectedLabId = value;
                                    // تحميل تفاصيل المعمل تلقائيًا
                                    if (value != null) {
                                      _loadLabDetails(value);
                                    }
                                  });
                                },
                                // validator: (value) {
                                // if (value == null) {
                                //  return 'الرجاء اختيار معمل';
                                // }
                                //return null;
                                // },
                              ),
                              // بطاقة معلومات المعمل
                              if (_selectedLabId != null)
                                Padding(
                                  padding: const EdgeInsets.only(top: 16),
                                  child: Card(
                                    color: theme
                                        .colorScheme.surfaceContainerHighest,
                                    child: Padding(
                                      padding: const EdgeInsets.all(16),
                                      child: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            'تفاصيل المعمل',
                                            style: theme.textTheme.titleMedium
                                                ?.copyWith(
                                              fontWeight: FontWeight.bold,
                                            ),
                                          ),
                                          const SizedBox(height: 8),
                                          _buildDetailRow(
                                            icon: Icons.school_outlined,
                                            label: 'الكلية',
                                            value: _collegeController.text,
                                          ),
                                          const SizedBox(height: 8),
                                          _buildDetailRow(
                                            icon: Icons.account_tree_outlined,
                                            label: 'القسم',
                                            value: _selectedDepartment ??
                                                'غير محدد',
                                          ),
                                          const SizedBox(height: 8),
                                          _buildDetailRow(
                                            icon: Icons.layers_outlined,
                                            label: 'رقم المعمل',
                                            value: _availableLabs
                                                .firstWhere((lab) =>
                                                    lab.id == _selectedLabId)
                                                .labNumber,
                                          ),
                                        ],
                                      ),
                                    ),
                                  ),
                                ),
                            ],
                          ),
                        const SizedBox(height: 16),
                        // Barcode Scan Button
                        Container(
                          width: double.infinity,
                          height: 60,
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              colors: [
                                theme.colorScheme.primary.withAlpha(204),
                                theme.colorScheme.primary,
                              ],
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                            ),
                            borderRadius: BorderRadius.circular(12),
                            boxShadow: [
                              BoxShadow(
                                color: theme.colorScheme.primary.withAlpha(76),
                                blurRadius: 10,
                                offset: const Offset(0, 4),
                              ),
                            ],
                          ),
                          child: Material(
                            color: Colors.transparent,
                            child: InkWell(
                              borderRadius: BorderRadius.circular(12),
                              onTap: _scanBarcode,
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(
                                    Icons.qr_code_scanner,
                                    color: theme.colorScheme.onPrimary,
                                    size: 30,
                                  ),
                                  const SizedBox(width: 16),
                                  Text(
                                    'مسح باركود الجهاز',
                                    style:
                                        theme.textTheme.titleMedium?.copyWith(
                                      color: theme.colorScheme.onPrimary,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(height: 16),
                        // Name Field
                        TextFormField(
                          controller: _nameController,
                          decoration: const InputDecoration(
                            labelText: 'اسم الجهاز',
                            border: OutlineInputBorder(),
                          ),
                          validator: (value) {
                            if (value == null || value.isEmpty) {
                              return 'الرجاء إدخال اسم الجهاز';
                            }
                            return null;
                          },
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
                          onChanged: isLabSelected
                              ? null // تعطيل التعديل إذا تم اختيار معمل
                              : (value) {
                                  setState(() {
                                    _selectedCollege = value;
                                    // إعادة تعيين القسم عند تغيير الكلية
                                    _selectedDepartment = null;
                                    // تحديث قائمة الأقسام
                                    _updateDepartmentsForCollege(value!);
                                  });
                                },
                          validator: (value) {
                            if (value == null || value.isEmpty) {
                              return 'الرجاء اختيار الكلية';
                            }
                            return null;
                          },
                        ),
                        const SizedBox(height: 16),
                        // Department Dropdown
                        if (_colleges.contains(_collegeController.text)) ...[
                          const SizedBox(height: 16),
                          DropdownButtonFormField<String>(
                            value: _selectedDepartment,
                            decoration: const InputDecoration(
                              labelText: 'القسم',
                              border: OutlineInputBorder(),
                            ),
                            items: _buildDepartmentDropdownItems(),
                            onChanged: isLabSelected
                                ? null // تعطيل التعديل إذا تم اختيار معمل
                                : (value) {
                                    setState(() {
                                      _selectedDepartment = value;
                                    });
                                  },
                            validator: (value) {
                              if (value == null || value.isEmpty) {
                                return 'الرجاء اختيار القسم';
                              }
                              return null;
                            },
                          ),
                        ],
                        const SizedBox(height: 16),
                        // Model Dropdown
                        DropdownButtonFormField<String>(
                          value: _modelController.text.isEmpty
                              ? null
                              : _modelController.text,
                          decoration: const InputDecoration(
                            labelText: 'موديل الجهاز',
                            border: OutlineInputBorder(),
                          ),
                          items: _models.map((String model) {
                            return DropdownMenuItem<String>(
                              value: model,
                              child: Text(model),
                            );
                          }).toList(),
                          onChanged: (String? value) {
                            if (value != null) {
                              setState(() => _modelController.text = value);
                            }
                          },
                          validator: (value) {
                            if (value == null || value.isEmpty) {
                              return 'الرجاء اختيار موديل الجهاز';
                            }
                            return null;
                          },
                        ),
                        const SizedBox(height: 16),
                        // Serial Number Field
                        TextFormField(
                          controller: _serialNumberController,
                          decoration: const InputDecoration(
                            labelText: 'الرقم التسلسلي',
                            border: OutlineInputBorder(),
                          ),
                          validator: (value) {
                            if (value == null || value.isEmpty) {
                              return 'الرجاء إدخال الرقم التسلسلي';
                            }
                            return null;
                          },
                        ),
                        const SizedBox(height: 16),
                        // Processor Dropdown
                        DropdownButtonFormField<String>(
                          value: _processorController.text.isEmpty
                              ? null
                              : _processorController.text,
                          decoration: const InputDecoration(
                            labelText: 'المعالج',
                            border: OutlineInputBorder(),
                          ),
                          items: _processors.map((String processor) {
                            return DropdownMenuItem<String>(
                              value: processor,
                              child: Text(processor),
                            );
                          }).toList(),
                          onChanged: (String? value) {
                            if (value != null) {
                              setState(() => _processorController.text = value);
                            }
                          },
                          validator: (value) {
                            if (value == null || value.isEmpty) {
                              return 'الرجاء اختيار نوع المعالج';
                            }
                            return null;
                          },
                        ),
                        const SizedBox(height: 16),
                        // Storage Type Dropdown
                        DropdownButtonFormField<String>(
                          value: _storageTypeController.text.isEmpty
                              ? null
                              : _storageTypeController.text,
                          decoration: const InputDecoration(
                            labelText: 'نوع التخزين',
                            border: OutlineInputBorder(),
                          ),
                          items: _storageTypes.map((String type) {
                            return DropdownMenuItem<String>(
                              value: type,
                              child: Text(type),
                            );
                          }).toList(),
                          onChanged: (String? value) {
                            if (value != null) {
                              setState(
                                  () => _storageTypeController.text = value);
                            }
                          },
                          validator: (value) {
                            if (value == null || value.isEmpty) {
                              return 'الرجاء اختيار نوع التخزين';
                            }
                            return null;
                          },
                        ),
                        const SizedBox(height: 16),
                        // Storage Size Dropdown
                        DropdownButtonFormField<String>(
                          value: _storageSizeController.text.isEmpty
                              ? null
                              : _storageSizeController.text,
                          decoration: const InputDecoration(
                            labelText: 'حجم التخزين',
                            border: OutlineInputBorder(),
                          ),
                          items: _storageSizes.map((String size) {
                            return DropdownMenuItem<String>(
                              value: size,
                              child: Text(size),
                            );
                          }).toList(),
                          onChanged: (String? value) {
                            if (value != null) {
                              setState(
                                  () => _storageSizeController.text = value);
                            }
                          },
                          validator: (value) {
                            if (value == null || value.isEmpty) {
                              return 'الرجاء اختيار حجم التخزين';
                            }
                            return null;
                          },
                        ),
                        const SizedBox(height: 16),
                        // Extra Storage Switch
                        SwitchListTile(
                          title: const Text('وحدة تخزين إضافية'),
                          value: _hasExtraStorage,
                          onChanged: (bool value) {
                            setState(() {
                              _hasExtraStorage = value;
                            });
                          },
                        ),
                        if (_hasExtraStorage) ...[
                          const SizedBox(height: 16),
                          DropdownButtonFormField<String>(
                            value: _extraStorageType,
                            decoration: const InputDecoration(
                              labelText: 'نوع وحدة التخزين الإضافية',
                              border: OutlineInputBorder(),
                            ),
                            items: _storageTypes.map((type) {
                              return DropdownMenuItem(
                                value: type,
                                child: Text(type),
                              );
                            }).toList(),
                            onChanged: (value) {
                              setState(() {
                                _extraStorageType = value;
                              });
                            },
                            validator: (value) {
                              if (_hasExtraStorage &&
                                  (value == null || value.isEmpty)) {
                                return 'الرجاء اختيار نوع وحدة التخزين الإضافية';
                              }
                              return null;
                            },
                          ),
                          const SizedBox(height: 16),
                          DropdownButtonFormField<String>(
                            value: _extraStorageSize,
                            decoration: const InputDecoration(
                              labelText: 'حجم وحدة التخزين الإضافية',
                              border: OutlineInputBorder(),
                            ),
                            items: _storageSizes.map((size) {
                              return DropdownMenuItem(
                                value: size,
                                child: Text(size),
                              );
                            }).toList(),
                            onChanged: (value) {
                              setState(() {
                                _extraStorageSize = value;
                              });
                            },
                            validator: (value) {
                              if (_hasExtraStorage &&
                                  (value == null || value.isEmpty)) {
                                return 'الرجاء اختيار حجم وحدة التخزين الإضافية';
                              }
                              return null;
                            },
                          ),
                        ],
                        const SizedBox(height: 16),
                        // OS Version Dropdown
                        DropdownButtonFormField<String>(
                          value: _osVersionController.text.isEmpty
                              ? null
                              : _osVersionController.text,
                          decoration: const InputDecoration(
                            labelText: 'نظام التشغيل',
                            border: OutlineInputBorder(),
                          ),
                          items: _osVersions.map((String os) {
                            return DropdownMenuItem<String>(
                              value: os,
                              child: Text(os),
                            );
                          }).toList(),
                          onChanged: (String? value) {
                            if (value != null) {
                              setState(() => _osVersionController.text = value);
                            }
                          },
                          validator: (value) {
                            if (value == null || value.isEmpty) {
                              return 'الرجاء اختيار نظام التشغيل';
                            }
                            return null;
                          },
                        ),
                        const SizedBox(height: 16),
                        // Notes Field
                        TextFormField(
                          controller: _notesController,
                          decoration: const InputDecoration(
                            labelText: 'ملاحظات',
                            border: OutlineInputBorder(),
                          ),
                          maxLines: 3,
                        ),

                        if (_needsMaintenance) ...[
                          const SizedBox(height: 16),
                          FilledButton.icon(
                            onPressed: _pickImageFromCamera,
                            icon: const Icon(Icons.camera_alt),
                            label: Text(_capturedImage == null
                                ? 'التقاط صورة'
                                : 'تغيير الصورة'),
                          ),
                          const SizedBox(height: 12),
                          if (_capturedImage != null)
                            Stack(
                              children: [
                                ClipRRect(
                                  borderRadius: BorderRadius.circular(12),
                                  child: Image.file(
                                    _capturedImage!,
                                    height: 200,
                                    width: double.infinity,
                                    fit: BoxFit.cover,
                                  ),
                                ),
                                Positioned(
                                  bottom: 8,
                                  right: 8,
                                  child: CircleAvatar(
                                    backgroundColor: Colors.black54,
                                    child: IconButton(
                                      icon: const Icon(Icons.zoom_out_map,
                                          color: Colors.white),
                                      onPressed: () {
                                        showDialog(
                                          context: context,
                                          builder: (_) => Dialog(
                                            child: InteractiveViewer(
                                              child:
                                                  Image.file(_capturedImage!),
                                            ),
                                          ),
                                        );
                                      },
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          const SizedBox(height: 16),
                        ],

                        const SizedBox(height: 24),
                        ElevatedButton(
                          onPressed: _isLoading ? null : _saveDevice,
                          style: ElevatedButton.styleFrom(
                            minimumSize: const Size(double.infinity, 50),
                          ),
                          child: _isLoading
                              ? const CircularProgressIndicator()
                              : Text(
                                  isEditing ? 'حفظ التغييرات' : 'إضافة الجهاز'),
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
  }) {
    return Row(
      children: [
        Icon(icon, color: Colors.grey[700]),
        const SizedBox(width: 12),
        Text(
          '$label: ',
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        Text(value),
      ],
    );
  }

  Future<void> _scanBarcode() async {
    final result = await BarcodeService.scanBarcode(context);
    if (result != null) {
      final parsedBarcode = BarcodeService.parseUniversityBarcode(result);

      // التحقق من صحة الباركود
      if (parsedBarcode['barcode'] == null ||
          parsedBarcode['barcode']!.isEmpty) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('باركود غير صالح. الرجاء المحاولة مرة أخرى.'),
              backgroundColor: Colors.red,
            ),
          );
        }
        return;
      }

      // إخفاء تفاصيل الباركود تمامًا
      _barcodeController.text = ''; // إخفاء باركود الجامعة
      _assetCodeController.text = ''; // إخفاء رمز الأصل

      // حفظ معلومات الباركود للاستخدام المستقبلي في حقول النموذج
      _serialNumberController.text = parsedBarcode['serialNumber'] ?? '';
      _modelController.text = parsedBarcode['model'] ?? '';

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('تم مسح الباركود بنجاح'),
            backgroundColor: Colors.green,
          ),
        );
      }
    }
  }

  Future<void> _saveDevice() async {
    if (_formKey.currentState!.validate()) {
      try {
        setState(() => _isLoading = true);

        // التأكد من وجود باركود صالح
        final universityBarcode = _barcodeController.text.trim();
        final assetCode = _assetCodeController.text.trim();

        // تحليل الباركود
        final barcodeData =
            BarcodeService.parseUniversityBarcode(universityBarcode);

        // التحقق من عدم وجود جهاز مسجل بنفس الباركود
        final existingDevices = await DatabaseService.getDevices();
        DeviceModel? duplicateDevice;

        for (var device in existingDevices) {
          if ((device.universityBarcode != null &&
                  device.universityBarcode == universityBarcode) ||
              (device.assetCode != null && device.assetCode == assetCode)) {
            duplicateDevice = device;
            break;
          }
        }

        if (duplicateDevice != null) {
          // إذا كان الجهاز موجودًا بالفعل
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(
                    'الجهاز مسجل مسبقًا برقم الأصل: ${duplicateDevice.assetCode}'),
                backgroundColor: Colors.red,
              ),
            );
            setState(() => _isLoading = false);
            return;
          }
        }

        // إنشاء معرف فريد للجهاز
        final deviceId = widget.device?.id ?? const Uuid().v4().toString();

        // إنشاء نموذج الجهاز
        final device = DeviceModel(
          id: deviceId,
          name: _nameController.text.trim(),
          college: _selectedCollege ?? '',
          department: _selectedDepartment ?? '',
          model: _modelController.text.trim(),
          serialNumber: _serialNumberController.text.trim(),
          processor: _processorController.text.trim(),
          storageType: _storageTypeController.text.trim(),
          storageSize: _storageSizeController.text.trim(),
          hasExtraStorage: _hasExtraStorage,
          extraStorageType: _hasExtraStorage ? _extraStorageType : null,
          extraStorageSize: _hasExtraStorage ? _extraStorageSize : null,
          osVersion: _osVersionController.text.trim(),
          notes: _notesController.text.trim(),
          labId: _selectedLabId ?? '',
          universityBarcode:
              universityBarcode.isNotEmpty ? universityBarcode : null,
          assetSource: barcodeData['assetSource'],
          assetCategory: barcodeData['assetCategory'],
          assetCode: barcodeData['assetCode'],
          needsMaintenance: _needsMaintenance,
          createdAt: widget.device?.createdAt ?? DateTime.now(),
          updatedAt: DateTime.now(),
        );

        // حفظ الجهاز في قاعدة البيانات
        if (widget.device == null) {
          await DatabaseService.addDevice(device);
        } else {
          await DatabaseService.updateDeviceRecord(device);
        }

        // إغلاق الشاشة والعودة
        if (mounted) {
          Navigator.pop(context, device);
        }
      } catch (e) {
        // معالجة الأخطاء
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('حدث خطأ أثناء حفظ الجهاز: $e'),
              backgroundColor: Colors.red,
            ),
          );
        }
      } finally {
        if (mounted) {
          setState(() => _isLoading = false);
        }
      }
    }
  }

  // دالة حذف الجهاز مع تحديث حالة المعمل
  Future<void> _deleteDevice() async {
    if (widget.device == null) return;

    try {
      // التحقق من المعمل
      final lab = await DatabaseService.getLabById(widget.device!.labId);
      if (lab == null) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('خطأ: المعمل غير موجود'),
              backgroundColor: Colors.red,
            ),
          );
        }
        return;
      }

      // حذف الجهاز
      await DatabaseService.deleteDevice(widget.device!.id);

      // تحديث قائمة معرفات الأجهزة في المعمل
      final updatedDeviceIds =
          lab.deviceIds.where((id) => id != widget.device!.id).toList();

      // تحديث حالة المعمل
      final updatedLab = LabModel(
        id: lab.id,
        labNumber: lab.labNumber,
        college: lab.college,
        department: lab.department,
        floorNumber: lab.floorNumber,
        // تغيير الحالة إذا لم يعد هناك أجهزة
        status: updatedDeviceIds.isEmpty
            ? LabStatus.openNoDevices
            : LabStatus.openWithDevices,
        notes: lab.notes,
        deviceIds: updatedDeviceIds,
        imagePath: lab.imagePath,
        createdAt: lab.createdAt,
        updatedAt: DateTime.now(),
        locationUrl: lab.locationUrl,
        latitude: lab.latitude,
        longitude: lab.longitude,
      );

      await DatabaseService.updateLab(updatedLab);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('تم حذف الجهاز بنجاح'),
            backgroundColor: Colors.green,
          ),
        );
        Navigator.pop(context);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('خطأ في حذف الجهاز: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }
}
