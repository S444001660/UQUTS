import 'dart:io';
import 'package:flutter/material.dart';
import 'package:uuid/uuid.dart';
import 'package:image_picker/image_picker.dart';
import '../models/lab_model.dart';
import '../services/database_service.dart';
import 'add_device_screen.dart';
import 'package:path_provider/path_provider.dart';

class AddLabScreen extends StatefulWidget {
  final LabModel? lab;

  const AddLabScreen({super.key, this.lab});

  @override
  State<AddLabScreen> createState() => _AddLabScreenState();
}

class _AddLabScreenState extends State<AddLabScreen> {
  final _formKey = GlobalKey<FormState>();
  final _labNumberController = TextEditingController();
  final _notesController = TextEditingController();
  final _locationUrlController = TextEditingController();
  String? _selectedCollege;
  String? _selectedDepartment;
  String? _selectedFloor;
  LabStatus _labStatus = LabStatus.openWithDevices;
  bool _isLoading = false;
  File? _capturedImage;
  double? _latitude;
  double? _longitude;

  final List<String> _types = [
    'معمل',
    'مكتب',
    'قاعة',
    'مستودع',
    'أخرى',
  ];

  String? _selectedType;

  final List<String> _colleges = [
    'كلية الهندسة',
    'كلية الطب',
    'كلية الحاسب الآلي',
    'كلية العلوم',
    'كلية الإدارة والاقتصاد',
  ];

  final Map<String, List<String>> _departments = {
    'كلية الهندسة': [
      'قسم الهندسة الكهربائية',
      'قسم الهندسة المدنية',
      'قسم الهندسة الميكانيكية',
      'قسم الهندسة الصناعية',
    ],
    'كلية الطب': [
      'قسم الطب البشري',
      'قسم طب الأسنان',
      'قسم العلوم الطبية التطبيقية',
    ],
    'كلية الحاسب الآلي': [
      'قسم علوم الحاسب و الذكاء الاصطناعي',
      'قسم هندسة البرمجيات',
      'قسم الامن السيبراني',
      'قسم هندسة الحاسب',
      'قسم علم المعلومات'
    ],
    'كلية العلوم': [
      'قسم الرياضيات',
      'قسم الفيزياء',
      'قسم الكيمياء',
      'قسم الأحياء',
    ],
    'كلية الإدارة والاقتصاد': [
      'قسم إدارة الأعمال',
      'قسم المحاسبة',
      'قسم الاقتصاد',
      'قسم التسويق',
    ],
  };

  final List<String> _floors = [
    'الدور الأرضي',
    'الدور الأول',
    'الدور الثاني',
    'الدور الثالث',
  ];

  @override
  void initState() {
    super.initState();
    if (widget.lab != null) {
      _labNumberController.text = widget.lab!.labNumber;
      _selectedFloor = widget.lab!.floorNumber;
      _labStatus = widget.lab!.status;
      _notesController.text = widget.lab!.notes;
      _locationUrlController.text = widget.lab?.locationUrl ?? '';
      _latitude = widget.lab?.latitude;
      _longitude = widget.lab?.longitude;

      // Set college first
      setState(() {
        _selectedCollege = widget.lab!.college;
      });

      // Then set department
      if (_departments[widget.lab!.college]?.contains(widget.lab!.department) ??
          false) {
        setState(() {
          _selectedDepartment = widget.lab!.department;
        });
      }

      if (widget.lab!.imagePath != null) {
        _capturedImage = File(widget.lab!.imagePath!);
      }
    }
  }

  @override
  void dispose() {
    _labNumberController.dispose();
    _notesController.dispose();
    _locationUrlController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        appBar: AppBar(
          title: Text(widget.lab != null ? 'تعديل معمل' : 'إضافة معمل'),
          backgroundColor: theme.colorScheme.primary,
          foregroundColor: theme.colorScheme.onPrimary,
          actions: [
            if (_capturedImage != null)
              IconButton(
                icon: const Icon(Icons.delete),
                onPressed: () {
                  setState(() {
                    _capturedImage = null;
                  });
                },
              ),
          ],
        ),
        body: _isLoading
            ? const Center(child: CircularProgressIndicator())
            : Form(
                key: _formKey,
                child: ListView(
                  padding: const EdgeInsets.all(16),
                  children: [
                    // Lab Image Capture
                    if (_capturedImage == null)
                      ElevatedButton.icon(
                        onPressed: _showImageSourceDialog,
                        icon: const Icon(Icons.camera_alt),
                        label: Text(_capturedImage == null
                            ? 'التقاط صورة'
                            : 'تغيير الصورة'),
                      )
                    else
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
                                        child: Image.file(_capturedImage!),
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
                    Card(
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'حالة المعمل',
                              style: theme.textTheme.titleLarge,
                            ),
                            const SizedBox(height: 16),
                            DropdownButtonFormField<LabStatus>(
                              value: _labStatus,
                              decoration: const InputDecoration(
                                labelText: 'الحالة',
                                border: OutlineInputBorder(),
                              ),
                              items: const [
                                DropdownMenuItem(
                                  value: LabStatus.openWithDevices,
                                  child: Row(
                                    children: [
                                      Icon(Icons.check_circle,
                                          color: Colors.green),
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
                                setState(() {
                                  _labStatus = value!;
                                });
                              },
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: _labNumberController,
                      decoration: const InputDecoration(
                        labelText: 'رقم المعمل',
                        border: OutlineInputBorder(),
                      ),
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'الرجاء إدخال رقم المعمل';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 16),
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
                        setState(() {
                          _selectedCollege = value;
                          _selectedDepartment = null;
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
                    if (_selectedCollege != null) ...[
                      DropdownButtonFormField<String>(
                        value: _selectedDepartment,
                        decoration: const InputDecoration(
                          labelText: 'القسم',
                          border: OutlineInputBorder(),
                        ),
                        items: _buildDepartmentDropdownItems(),
                        onChanged: (value) {
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
                      onChanged: (value) =>
                          setState(() => _selectedFloor = value),
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'الرجاء اختيار الدور';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 16),
                    DropdownButtonFormField<String>(
                      decoration: const InputDecoration(
                        labelText: 'نوع الموقع',
                        border: OutlineInputBorder(),
                      ),
                      value: _selectedType,
                      onChanged: (newValue) {
                        setState(() {
                          _selectedType = newValue!;
                        });
                      },
                      items: _types
                          .map((type) => DropdownMenuItem(
                                value: type,
                                child: Text(type),
                              ))
                          .toList(),
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: _notesController,
                      decoration: const InputDecoration(
                        labelText: 'ملاحظات',
                        border: OutlineInputBorder(),
                      ),
                      maxLines: 3,
                    ),
                  ],
                ),
              ),
        bottomNavigationBar: SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (_labStatus != LabStatus.closed)
                  FilledButton.icon(
                    onPressed: _isLoading ? null : _saveThenAddDevices,
                    icon: const Icon(Icons.computer_outlined),
                    label: const Text('حفظ وإضافة الأجهزة'),
                  ),
                const SizedBox(height: 8),
                FilledButton(
                  onPressed: _isLoading ? null : _saveLab,
                  child: _isLoading
                      ? const SizedBox(
                          height: 20,
                          width: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            valueColor:
                                AlwaysStoppedAnimation<Color>(Colors.white),
                          ),
                        )
                      : Text(widget.lab != null
                          ? 'حفظ التغييرات'
                          : 'إضافة المعمل'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Future<LabModel?> _saveLab() async {
    if (!_formKey.currentState!.validate()) return null;

    if ((_labStatus == LabStatus.openNoDevices ||
            _labStatus == LabStatus.closed) &&
        _capturedImage == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('يرجى التقاط صورة توضح المشكلة أو الإغلاق'),
          backgroundColor: Colors.red,
        ),
      );
      return null;
    }

    setState(() => _isLoading = true);

    try {
      if (_selectedCollege == null ||
          _selectedDepartment == null ||
          _selectedFloor == null) {
        throw Exception('الرجاء إكمال جميع البيانات المطلوبة');
      }

      List<String> deviceIds = [];
      if (widget.lab != null) {
        final devices = await DatabaseService.getDevices();
        deviceIds = devices
            .where((d) => d.labId == widget.lab!.id)
            .map((d) => d.id)
            .toList();
      }

      LabStatus status = widget.lab == null
          ? (_labStatus == LabStatus.closed
              ? LabStatus.closed
              : LabStatus.openNoDevices)
          : _labStatus;

      String? imagePath;
      if (_capturedImage != null) {
        final appDir = await getApplicationDocumentsDirectory();
        final imagesDir = Directory('${appDir.path}/lab_images');
        await imagesDir.create(recursive: true);

        final fileName =
            '${widget.lab?.id}_${DateTime.now().millisecondsSinceEpoch}.jpg';
        final savedImage =
            await _capturedImage!.copy('${imagesDir.path}/$fileName');
        imagePath = savedImage.path;
      }

      final labId = widget.lab?.id ?? const Uuid().v4().toString();

      final lab = LabModel(
        id: labId,
        labNumber: _labNumberController.text,
        college: _selectedCollege!,
        department: _selectedDepartment!,
        floorNumber: _selectedFloor!,
        status: status,
        notes: _notesController.text,
        deviceIds: deviceIds,
        imagePath: imagePath ?? widget.lab?.imagePath,
        createdAt: widget.lab?.createdAt ?? DateTime.now(),
        updatedAt: DateTime.now(),
        locationUrl: _locationUrlController.text.isNotEmpty
            ? _locationUrlController.text
            : _getDefaultLocationForCollege(_selectedCollege!),
        latitude: _latitude,
        longitude: _longitude,
      );

      if (widget.lab == null) {
        await DatabaseService.addLab(lab);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('تم إضافة المعمل بنجاح'),
              backgroundColor: Colors.green,
            ),
          );
        }
      } else {
        await DatabaseService.updateLab(lab);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('تم تحديث المعمل بنجاح'),
              backgroundColor: Colors.green,
            ),
          );
        }
      }

      if (mounted) {
        Navigator.pop(context);
      }

      return lab;
    } catch (e) {
      debugPrint('خطأ في حفظ المعمل: $e');

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('خطأ في حفظ المعمل: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
      return null;
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  Future<void> _saveThenAddDevices() async {
    final lab = await _saveLab();
    if (lab != null && mounted) {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => AddDeviceScreen(labId: lab.id),
        ),
      );
    }
  }

  Future<void> _pickImageFromCamera() async {
    try {
      final picked = await ImagePicker().pickImage(source: ImageSource.camera);
      if (picked != null) {
        final File imageFile = File(picked.path);

        // Validate image size
        final bytes = await imageFile.length();
        const maxSizeInBytes = 5 * 1024 * 1024; // 5 MB

        if (bytes > maxSizeInBytes) {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('حجم الصورة كبير جدًا. الحد الأقصى 5 ميجابايت'),
                backgroundColor: Colors.red,
              ),
            );
          }
          return;
        }

        setState(() {
          _capturedImage = imageFile;
        });
      }
    } catch (e) {
      debugPrint('خطأ في التقاط الصورة: $e');

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('خطأ في التقاط الصورة: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _pickImageFromGallery() async {
    try {
      final picked = await ImagePicker().pickImage(source: ImageSource.gallery);
      if (picked != null) {
        final File imageFile = File(picked.path);

        // Validate image size
        final bytes = await imageFile.length();
        const maxSizeInBytes = 5 * 1024 * 1024; // 5 MB

        if (bytes > maxSizeInBytes) {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('حجم الصورة كبير جدًا. الحد الأقصى 5 ميجابايت'),
                backgroundColor: Colors.red,
              ),
            );
          }
          return;
        }

        setState(() {
          _capturedImage = imageFile;
        });
      }
    } catch (e) {
      debugPrint('خطأ في اختيار الصورة: $e');

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('خطأ في اختيار الصورة: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  void _showImageSourceDialog() {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const Text(
                'اختر مصدر الصورة',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 16),
              ElevatedButton.icon(
                onPressed: () {
                  Navigator.pop(context);
                  _pickImageFromCamera();
                },
                icon: const Icon(Icons.camera_alt),
                label: const Text('التقاط صورة'),
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 12),
                ),
              ),
              const SizedBox(height: 16),
              ElevatedButton.icon(
                onPressed: () {
                  Navigator.pop(context);
                  _pickImageFromGallery();
                },
                icon: const Icon(Icons.photo_library),
                label: const Text('اختيار من المعرض'),
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 12),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  String _getDefaultLocationForCollege(String college) {
    switch (college) {
      case 'كلية الهندسة':
        return 'https://maps.app.goo.gl/4PfbWDc36XAdfRnM7';
      case 'كلية الطب':
        return 'https://maps.app.goo.gl/mSET1C88At97o6s46';
      case 'كلية الحاسب الآلي':
        return 'https://maps.app.goo.gl/yfHBYYpfLaoWu1qd8';
      case 'كلية العلوم':
        return 'https://maps.app.goo.gl/iVGvJTV6e1Vquxqt6';
      case 'كلية الإدارة والاقتصاد':
        return 'https://maps.app.goo.gl/7ysTpqfdpZPPQTAn8';
      default:
        return '';
    }
  }

  List<DropdownMenuItem<String>> _buildDepartmentDropdownItems() {
    if (_selectedCollege == null || _selectedCollege!.isEmpty) {
      return [];
    }

    final departments = _departments[_selectedCollege!] ?? [];

    return departments.map((department) {
      return DropdownMenuItem(
        value: department,
        child: Text(department),
      );
    }).toList();
  }
}
