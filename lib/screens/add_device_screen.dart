// استيراد المكتبات الضرورية
import 'dart:io'; // مكتبة للتعامل مع الملفات، مثل ملف الصورة الملتقطة
import 'package:flutter/material.dart'; // مكتبة فلاتر الأساسية لبناء واجهة المستخدم
import 'package:image_picker/image_picker.dart'; // مكتبة لاختيار الصور من الكاميرا أو المعرض
import 'package:uuid/uuid.dart'; // مكتبة لتوليد معرفات فريدة عالميًا (UUIDs)
import '../models/device_model.dart'; // استيراد نموذج بيانات الجهاز
import '../models/lab_model.dart'; // استيراد نموذج بيانات المعمل
import 'package:uquts1/services/firebase_database_service.dart'; // استيراد خدمة قاعدة بيانات Firebase
import '../utils/ui_helpers.dart'; // استيراد دوال مساعدة لواجهة المستخدم (مثل عرض SnackBar)
import '../utils/validation_utils.dart'; // استيراد دوال التحقق من صحة الإدخال
import '../utils/image_utils.dart'; // استيراد دوال مساعدة للتعامل مع الصور
import '../utils/device_form_constants.dart'; // استيراد الثوابت المستخدمة في الفورم (مثل قوائم الكليات والأقسام)
import 'dart:developer' as developer; // لاستخدام developer.log

//------------------------------------------------------------------------------

// تعريف الويدجت الرئيسية للشاشة وهي من نوع StatefulWidget لأن حالتها تتغير
class AddDeviceScreen extends StatefulWidget {
  final DeviceModel? device;
  final String? labId;
  final Map<String, String?>? scannedBarcodeData;

  const AddDeviceScreen({
    super.key,
    this.device,
    this.labId,
    this.scannedBarcodeData,
  });

  @override
  State<AddDeviceScreen> createState() => _AddDeviceScreenState();
}

//------------------------------------------------------------------------------

// تعريف كلاس الحالة (State) للـ AddDeviceScreen
class _AddDeviceScreenState extends State<AddDeviceScreen> {
  // مفتاح عالمي للتحكم في الفورم والتحقق من صحة المدخلات.
  final _formKey = GlobalKey<FormState>();

  //------------------------------------------------------------------------------

  // وحدات التحكم (Controllers) لربط حقول الإدخال النصية بالـ State.
  final _nameController = TextEditingController();
  final _serialNumberController = TextEditingController();
  final _notesController = TextEditingController();
  final _modelController = TextEditingController();
  final _processorController = TextEditingController();
  final _storageTypeController = TextEditingController();
  final _storageSizeController = TextEditingController();
  final _osVersionController = TextEditingController();
  final _extraStorageTypeController = TextEditingController();
  final _extraStorageSizeController = TextEditingController();
  final _universityBarcodeController = TextEditingController();
  final _assetSourceController = TextEditingController();
  final _assetCategoryController = TextEditingController();
  final _assetCodeController = TextEditingController();

  //------------------------------------------------------------------------------

  // متغيرات الحالة (State variables) لتخزين القيم المتغيرة في الواجهة.
  String? _selectedCollege;
  String? _selectedDepartment;
  String? _selectedLab;
  bool _needsMaintenance = false;
  bool _hasExtraStorage = false;
  File? _capturedImage;
  String? _existingImageUrl;
  List<LabModel> _availableLabs = [];
  bool _isLoading = false;
  String? _error;
  LabModel? _currentSelectedLabDetails;

  //------------------------------------------------------------------------------

  // دالة تُستدعى مرة واحدة عند إنشاء الويدجت لأول مرة.
  // تستخدم لتحميل البيانات الأولية اللازمة للشاشة.
  @override
  void initState() {
    super.initState();
    _loadInitialData();
  }

  //------------------------------------------------------------------------------

  // دالة تُستدعى عند إزالة الويدجت من الشجرة.
  // تستخدم لتحرير الموارد التي تم حجزها، مثل وحدات التحكم (Controllers)، لمنع تسرب الذاكرة.
  @override
  void dispose() {
    _nameController.dispose();
    _serialNumberController.dispose();
    _notesController.dispose();
    _modelController.dispose();
    _processorController.dispose();
    _storageTypeController.dispose();
    _storageSizeController.dispose();
    _osVersionController.dispose();
    _extraStorageTypeController.dispose();
    _extraStorageSizeController.dispose();
    _universityBarcodeController.dispose();
    _assetSourceController.dispose();
    _assetCategoryController.dispose();
    _assetCodeController.dispose();
    super.dispose();
  }

  //------------------------------------------------------------------------------

  // دالة غير متزامنة لتحميل البيانات الأولية مثل قائمة المعامل من Firebase.
  // وتقوم بملء الحقول إذا كان هناك جهاز للتعديل أو بيانات من باركود ممسوح.
  Future<void> _loadInitialData() async {
    setState(() => _isLoading = true);
    try {
      final labs = await FirebaseDatabaseService.getLabs();
      if (!mounted) return;

      setState(() {
        _availableLabs = labs
            .where((lab) =>
                lab.id.isNotEmpty &&
                lab.labNumber.isNotEmpty &&
                lab.college.isNotEmpty)
            .toList();
      });

      if (widget.device != null) {
        _loadDeviceData(widget.device!);
      } else if (widget.scannedBarcodeData != null) {
        _loadScannedBarcodeData(widget.scannedBarcodeData!);
      }

      if (widget.labId != null) {
        await _loadLabDetails(widget.labId!);
      }
    } catch (e) {
      if (mounted) {
        _error = 'خطأ في تحميل البيانات: $e';
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  //------------------------------------------------------------------------------

  // دالة لملء حقول الفورم ببيانات جهاز موجود مسبقًا (في حالة التعديل).
  void _loadDeviceData(DeviceModel device) {
    _nameController.text = device.name;
    _serialNumberController.text = device.serialNumber;
    _modelController.text = device.model;
    _processorController.text = device.processor;
    _storageTypeController.text = device.storageType;
    _storageSizeController.text = device.storageSize;
    _osVersionController.text = device.osVersion;
    _notesController.text = device.notes;
    _selectedCollege = device.college;
    _selectedDepartment = device.department;
    _needsMaintenance = device.needsMaintenance;
    _hasExtraStorage = device.hasExtraStorage;
    _universityBarcodeController.text = device.universityBarcode ?? '';
    _assetSourceController.text = device.assetSource ?? '';
    _assetCategoryController.text = device.assetCategory ?? '';
    _assetCodeController.text = device.assetCode ?? '';
    _extraStorageTypeController.text = device.extraStorageType ?? '';
    _extraStorageSizeController.text = device.extraStorageSize ?? '';
    _existingImageUrl = device.imagePath;

    if (_availableLabs.any((lab) => lab.id == device.labId)) {
      _selectedLab = device.labId;
      _currentSelectedLabDetails =
          _availableLabs.firstWhere((lab) => lab.id == device.labId);
    }
  }

  //------------------------------------------------------------------------------

  // دالة لملء حقول الفورم بالبيانات المستخرجة من الباركود الممسوح ضوئيًا.
  void _loadScannedBarcodeData(Map<String, String?> barcodeData) {
    _universityBarcodeController.text = barcodeData['barcode'] ?? '';
    _assetCodeController.text = barcodeData['assetCode'] ?? '';
    _serialNumberController.text = barcodeData['serialNumber'] ?? '';
    _assetSourceController.text = barcodeData['assetSource'] ?? '';
    _assetCategoryController.text = barcodeData['assetCategory'] ?? '';
  }

  //------------------------------------------------------------------------------

  // دالة غير متزامنة لجلب تفاصيل معمل معين من Firebase باستخدام معرفه (ID).
  Future<void> _loadLabDetails(String labId) async {
    try {
      final lab = await FirebaseDatabaseService.getLabById(labId);
      if (lab != null && mounted) {
        setState(() {
          _selectedLab = lab.id;
          _selectedCollege = lab.college;
          _selectedDepartment = lab.department;
          _currentSelectedLabDetails = lab;
        });
      }
    } catch (e) {
      if (mounted) {
        UIHelpers.showSnackBar(
            context: context,
            message: 'خطأ في تحميل تفاصيل المعمل: $e',
            type: SnackBarType.error);
      }
    }
  }

  //------------------------------------------------------------------------------

  // دالة تُستدعى عند اختيار معمل من القائمة المنسدلة لتحديث بيانات الكلية والقسم تلقائيًا.
  void _onLabSelected(LabModel? lab) {
    setState(() {
      _selectedLab = lab?.id;
      _selectedCollege = lab?.college;
      _selectedDepartment = lab?.department;
      _currentSelectedLabDetails = lab;
    });
  }

  //------------------------------------------------------------------------------

  // دالة غير متزامنة لفتح الكاميرا والتقاط صورة وتخزينها في متغير الحالة `_capturedImage`.
  Future<void> _pickImage() async {
    final pickedImage = await ImageUtils.pickImage(
        context: context, source: ImageSource.camera);
    if (pickedImage != null) {
      setState(() {
        _capturedImage = pickedImage;
        _existingImageUrl = null;
      });
    }
  }

 //------------------------------------------------------------------------------
// دالة مساعدة للتحقق من كل الشروط قبل الحفظ
// وظيفتها فقط التحقق، وإذا فشل شرط ما، تطلق خطأ (throw exception)
Future<void> _validateInputs() async {
  // 1. التحقق من صحة حقول الفورم
  if (!(_formKey.currentState?.validate() ?? false)) {
    throw 'يرجى التحقق من صحة البيانات المدخلة';
  }

  // 2. التحقق من شرط الصورة في حالة الصيانة
  if (_needsMaintenance && _capturedImage == null && _existingImageUrl == null) {
    throw 'يجب التقاط صورة عند تحديد "يحتاج إلى صيانة".';
  }

  // 3. التحقق من عدم تكرار الرقم التسلسلي
  final serialExists = await FirebaseDatabaseService.serialNumberExists(
    _serialNumberController.text.trim(),
    excludeId: widget.device?.id,
  );
  if (serialExists) {
    throw 'الرقم التسلسلي موجود بالفعل لجهاز آخر.';
  }
}

//------------------------------------------------------------------------------

// دالة مساعدة مسؤولة فقط عن معالجة ورفع الصورة
// تُرجع رابط الصورة النهائي بعد الرفع أو المعالجة
Future<String?> _handleImageUpload() async {
  // إذا لم تكن هناك صورة جديدة، وكانت الصيانة غير مفعلة، نحذف الصورة القديمة
  if (_capturedImage == null) {
    return _needsMaintenance ? _existingImageUrl : null;
  }
  
  // إذا كانت هناك صورة جديدة، نقوم برفعها
  final storagePath = 'device_images/${widget.device?.id ?? const Uuid().v4()}';
  return await FirebaseDatabaseService.uploadImageToFirebaseStorage(
    _capturedImage!,
    storagePath,
  );
}

//------------------------------------------------------------------------------

// الدالة الرئيسية للحفظ بعد إعادة هيكلتها، أصبحت الآن مجرد منسق للعمليات
Future<DeviceModel?> _performSave() async {
  try {
    // الخطوة 1: التحقق من كل شيء أولاً
    await _validateInputs();

    // الخطوة 2: تحديث الواجهة لبدء التحميل
    if (!mounted) return null;
    setState(() => _isLoading = true);

    // الخطوة 3: معالجة الصورة والحصول على رابطها
    final String? finalImageUrl = await _handleImageUpload();

    // الخطوة 4: استدعاء وبناء من نموذج البيانات (Data Model)
    final now = DateTime.now();
    final deviceId = widget.device?.id ?? const Uuid().v4();
    final deviceToSave = DeviceModel(
      id: deviceId,
      name: _nameController.text.trim(),
      college: _selectedCollege ?? '',
      department: _selectedDepartment ?? '',
      serialNumber: _serialNumberController.text.trim(),
      model: _modelController.text.trim(),
      processor: _processorController.text.trim(),
      storageType: _storageTypeController.text.trim(),
      storageSize: _storageSizeController.text.trim(),
      hasExtraStorage: _hasExtraStorage,
      extraStorageType: _hasExtraStorage ? _extraStorageTypeController.text.trim() : null,
      extraStorageSize: _hasExtraStorage ? _extraStorageSizeController.text.trim() : null,
      osVersion: _osVersionController.text.trim(),
      notes: _notesController.text.trim(),
      needsMaintenance: _needsMaintenance,
      labId: _selectedLab ?? widget.labId ?? '',
      universityBarcode: _universityBarcodeController.text.trim().isNotEmpty
          ? _universityBarcodeController.text.trim()
          : null,
      assetSource: _assetSourceController.text.trim().isNotEmpty
          ? _assetSourceController.text.trim()
          : null,
      assetCategory: _assetCategoryController.text.trim().isNotEmpty
          ? _assetCategoryController.text.trim()
          : null,
      assetCode: _assetCodeController.text.trim().isNotEmpty
          ? _assetCodeController.text.trim()
          : null,
      createdAt: widget.device?.createdAt ?? now,
      updatedAt: now,
      imagePath: finalImageUrl,
    );

    // الخطوة 5: حفظ النموذج في قاعدة البيانات
    await FirebaseDatabaseService.addOrUpdateDevice(deviceToSave);
    return deviceToSave;

  } catch (e) {
    // إذا حدث أي خطأ في أي من الخطوات السابقة، سيتم التقاطه هنا
    if (mounted) {
      UIHelpers.showSnackBar(
        context: context,
        message: 'خطأ في حفظ الجهاز: $e',
        type: SnackBarType.error,
      );
    }
    return null; // إرجاع null للإشارة إلى فشل العملية
  } finally {
    // الخطوة الأخيرة: التأكد من إيقاف مؤشر التحميل دائماً
    if (mounted) {
      setState(() => _isLoading = false);
    }
  }
}
  //------------------------------------------------------------------------------

  // دالة لمسح حقول الفورم المتعلقة بالجهاز فقط، مع الإبقاء على المعمل المحدد.
  // تستخدم بعد الحفظ للمتابعة وإضافة جهاز آخر في نفس المعمل.
  void _resetFormForNextDevice() {
    _formKey.currentState?.reset();
    _nameController.clear();
    _serialNumberController.clear();
    _notesController.clear();
    _modelController.clear();
    _processorController.clear();
    _storageTypeController.clear();
    _storageSizeController.clear();
    _osVersionController.clear();
    _extraStorageTypeController.clear();
    _extraStorageSizeController.clear();
    _universityBarcodeController.clear();
    _assetSourceController.clear();
    _assetCategoryController.clear();
    _assetCodeController.clear();

    setState(() {
      _needsMaintenance = false;
      _hasExtraStorage = false;
      _capturedImage = null;
      _existingImageUrl = null;
    });
  }

  //------------------------------------------------------------------------------

  // دالة الحفظ والخروج : تستدعي دالة الحفظ ثم تغلق الشاشة الحالية عند النجاح.
  Future<void> _saveAndPop() async {
    final savedDevice = await _performSave();
    if (savedDevice != null && mounted) {
      UIHelpers.showSnackBar(
          context: context,
          message: 'تم حفظ الجهاز بنجاح',
          type: SnackBarType.success);
      Navigator.pop(context, savedDevice);
    }
  }

  //------------------------------------------------------------------------------

  // دالة الحفظ والمتابعة : تستدعي دالة الحفظ ثم تمسح حقول الفورم عند النجاح للاستعداد لإضافة جهاز جديد.
  Future<void> _saveAndAddAnother() async {
    final savedDevice = await _performSave();
    if (savedDevice != null && mounted) {
      UIHelpers.showSnackBar(
          context: context,
          message: 'تم حفظ "${savedDevice.name}". يمكنك إضافة جهاز آخر.',
          type: SnackBarType.success);
      _resetFormForNextDevice();
    }
  }

  //------------------------------------------------------------------------------

  // دالة غير متزامنة لحذف الجهاز الحالي (فقط في وضع التعديل).
  // تعرض مربع حوار للتأكيد قبل تنفيذ عملية الحذف.
  Future<void> _deleteDevice() async {
    if (widget.device == null) return;
    final confirmDelete = await UIHelpers.showConfirmationDialog(
        context: context,
        title: 'حذف الجهاز',
        content: 'هل أنت متأكد من حذف هذا الجهاز؟',
        confirmText: 'حذف',
        cancelText: 'إلغاء');
    if (confirmDelete == true) {
      setState(() => _isLoading = true);
      try {
        await FirebaseDatabaseService.deleteDevice(widget.device!.id);
        if (!mounted) return;
        UIHelpers.showSnackBar(
            context: context,
            message: 'تم حذف الجهاز بنجاح',
            type: SnackBarType.success);
        Navigator.pop(context);
      } catch (e) {
        if (mounted) {
          UIHelpers.showSnackBar(
              context: context,
              message: 'خطأ في حذف الجهاز: $e',
              type: SnackBarType.error);
        }
      } finally {
        if (mounted) {
          setState(() => _isLoading = false);
        }
      }
    }
  }

  //------------------------------------------------------------------------------

  // ويدجت مساعدة لبناء صف يعرض أيقونة وعنوان وقيمة، لتوحيد شكل عرض التفاصيل.
  Widget _buildDetailRow(
      {required IconData icon, required String label, required String value}) {
    return Row(children: [
      Icon(icon, color: Colors.grey[700]),
      const SizedBox(width: 12),
      Text('$label: ', style: const TextStyle(fontWeight: FontWeight.bold)),
      Expanded(child: Text(value)),
    ]);
  }

  //------------------------------------------------------------------------------

  // ويدجت مساعدة لبناء بطاقة (Card) تعرض تفاصيل المعمل المحدد.
  Widget _buildLabDetailsCard(LabModel lab) {
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      _buildDetailRow(
          icon: Icons.school_outlined, label: 'الكلية', value: lab.college),
      const SizedBox(height: 8),
      _buildDetailRow(
          icon: Icons.account_tree_outlined,
          label: 'القسم',
          value: lab.department),
      const SizedBox(height: 8),
      _buildDetailRow(
          icon: Icons.layers_outlined,
          label: 'رقم المعمل',
          value: lab.labNumber),
      const SizedBox(height: 8),
      _buildDetailRow(
          icon: Icons.category_outlined, label: 'النوع', value: lab.type),
      const SizedBox(height: 8),
      _buildDetailRow(
          icon: Icons.info_outline,
          label: 'الحالة',
          value: lab.getStatusText()),
    ]);
  }

  //------------------------------------------------------------------------------

  // الدالة الأساسية لبناء واجهة المستخدم (UI) للشاشة بأكملها.
  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isEditing = widget.device != null;
    final isLabSelected = _selectedLab != null;
    final hasScannedBarcodeDataForNewDevice =
        widget.scannedBarcodeData != null && !isEditing;
    final currentDeviceHasBarcodeData =
        isEditing && (widget.device!.universityBarcode?.isNotEmpty == true);
    final shouldShowBarcodeSection =
        hasScannedBarcodeDataForNewDevice || currentDeviceHasBarcodeData;

    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        appBar: AppBar(
          title: Text(isEditing ? 'تعديل جهاز' : 'إضافة جهاز'),
          actions: [
            if (isEditing)
              IconButton(
                  onPressed: _deleteDevice,
                  icon: const Icon(Icons.delete),
                  tooltip: 'حذف الجهاز'),
          ],
        ),
        body: _isLoading
            ? const Center(child: CircularProgressIndicator())
            : _error != null
                ? Center(
                    child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                        Icon(Icons.error_outline,
                            size: 64, color: theme.colorScheme.error),
                        const SizedBox(height: 16),
                        Text('حدث خطأ: $_error',
                            style: theme.textTheme.titleMedium,
                            textAlign: TextAlign.center),
                        const SizedBox(height: 16),
                        FilledButton.icon(
                            onPressed: _loadInitialData,
                            icon: const Icon(Icons.refresh),
                            label: const Text('إعادة المحاولة')),
                      ]))
                : SingleChildScrollView(
                    padding: const EdgeInsets.all(16),
                    child: Form(
                      key: _formKey,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          DropdownButtonFormField<LabModel>(
                            decoration: InputDecoration(
                              labelText: 'اختيار المعمل',
                              border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(12)),
                            ),
                            value: _availableLabs
                                    .any((lab) => lab.id == _selectedLab)
                                ? _availableLabs
                                    .firstWhere((lab) => lab.id == _selectedLab)
                                : null,
                            items: _availableLabs
                                .map((lab) => DropdownMenuItem<LabModel>(
                                    value: lab,
                                    child: Text(
                                        '${lab.labNumber} - ${lab.college}')))
                                .toList(),
                            onChanged: _onLabSelected,
                            validator: (value) =>
                                ValidationUtils.validateDropdown(value?.id,
                                    errorMessage: 'الرجاء اختيار المعمل'),
                          ),
                          const SizedBox(height: 16),
                          if (isLabSelected) ...[
                            Padding(
                              padding: const EdgeInsets.only(bottom: 16),
                              child: Card(
                                color:
                                    theme.colorScheme.surfaceContainerHighest,
                                child: Padding(
                                  padding: const EdgeInsets.all(16),
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text('تفاصيل المعمل',
                                          style: theme.textTheme.titleMedium
                                              ?.copyWith(
                                                  fontWeight: FontWeight.bold)),
                                      const SizedBox(height: 8),
                                      if (_currentSelectedLabDetails != null)
                                        _buildLabDetailsCard(
                                            _currentSelectedLabDetails!),
                                    ],
                                  ),
                                ),
                              ),
                            ),
                            if (shouldShowBarcodeSection)
                              Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Row(children: [
                                      Text('بيانات الباركود',
                                          style: theme.textTheme.titleMedium
                                              ?.copyWith(
                                                  fontWeight: FontWeight.bold)),
                                      const SizedBox(width: 8),
                                      const Icon(Icons.check_circle,
                                          color: Colors.green, size: 20),
                                    ]),
                                    const SizedBox(height: 16),
                                  ]),
                            SwitchListTile(
                              title: const Text('يحتاج إلى صيانة'),
                              subtitle: Text(
                                  _needsMaintenance
                                      ? 'الجهاز في حالة صيانة'
                                      : 'الجهاز يعمل بشكل طبيعي',
                                  style: TextStyle(
                                      color: _needsMaintenance
                                          ? Colors.orange
                                          : Colors.green)),
                              value: _needsMaintenance,
                              onChanged: (value) {
                                setState(() {
                                  _needsMaintenance = value;
                                  if (!value) {
                                    _capturedImage = null;
                                    _existingImageUrl = null;
                                  }
                                });
                              },
                              activeColor: Colors.orange,
                            ),
                            const SizedBox(height: 16),
                            if (_needsMaintenance) ...[
                              ElevatedButton.icon(
                                onPressed: _pickImage,
                                icon: const Icon(Icons.camera_alt),
                                label: Text(_capturedImage == null &&
                                        _existingImageUrl == null
                                    ? 'التقاط صورة الصيانة'
                                    : 'تغيير الصورة'),
                              ),
                              const SizedBox(height: 12),
                              if (_capturedImage != null ||
                                  _existingImageUrl != null)
                                Stack(children: [
                                  ClipRRect(
                                    borderRadius: BorderRadius.circular(12),
                                    child: _capturedImage != null
                                        ? Image.file(_capturedImage!,
                                            height: 200,
                                            width: double.infinity,
                                            fit: BoxFit.cover)
                                        : Image.network(_existingImageUrl!,
                                            height: 200,
                                            width: double.infinity,
                                            fit: BoxFit.cover, loadingBuilder:
                                                (context, child,
                                                    loadingProgress) {
                                            if (loadingProgress == null)
                                              return child;
                                            return const Center(
                                                child:
                                                    CircularProgressIndicator());
                                          }, errorBuilder:
                                                (context, error, stackTrace) {
                                            return const Center(
                                                child: Icon(Icons.broken_image,
                                                    size: 50));
                                          }),
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
                                          if (_capturedImage != null) {
                                            UIHelpers.showImageDialog(
                                                context: context,
                                                imageFile: _capturedImage!);
                                          } else if (_existingImageUrl !=
                                              null) {
                                            UIHelpers.showImageDialog(
                                                context: context,
                                                imageUrl: _existingImageUrl!);
                                          }
                                        },
                                      ),
                                    ),
                                  ),
                                ]),
                              const SizedBox(height: 16),
                            ],
                            TextFormField(
                                controller: _nameController,
                                decoration: InputDecoration(
                                    labelText: 'اسم الجهاز',
                                    border: OutlineInputBorder(
                                        borderRadius:
                                            BorderRadius.circular(12))),
                                validator: ValidationUtils.validateName),
                            const SizedBox(height: 16),
                            DropdownButtonFormField<String>(
                              decoration: InputDecoration(
                                  labelText: 'الموديل',
                                  border: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(12))),
                              value: _modelController.text.isNotEmpty
                                  ? _modelController.text
                                  : null,
                              items: DeviceFormConstants.models
                                  .map((model) => DropdownMenuItem(
                                      value: model, child: Text(model)))
                                  .toList(),
                              onChanged: (value) =>
                                  _modelController.text = value ?? '',
                              validator: (value) =>
                                  ValidationUtils.validateDropdown(value,
                                      errorMessage: 'الرجاء اختيار الموديل'),
                            ),
                            const SizedBox(height: 16),
                            TextFormField(
                                controller: _serialNumberController,
                                decoration: InputDecoration(
                                    labelText: 'الرقم التسلسلي',
                                    border: OutlineInputBorder(
                                        borderRadius:
                                            BorderRadius.circular(12))),
                                validator:
                                    ValidationUtils.validateSerialNumber),
                            const SizedBox(height: 16),
                            DropdownButtonFormField<String>(
                              decoration: InputDecoration(
                                  labelText: 'المعالج',
                                  border: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(12))),
                              value: _processorController.text.isNotEmpty
                                  ? _processorController.text
                                  : null,
                              items: DeviceFormConstants.processors
                                  .map((processor) => DropdownMenuItem(
                                      value: processor, child: Text(processor)))
                                  .toList(),
                              onChanged: (value) =>
                                  _processorController.text = value ?? '',
                              validator: (value) =>
                                  ValidationUtils.validateDropdown(value,
                                      errorMessage: 'الرجاء اختيار المعالج'),
                            ),
                            const SizedBox(height: 16),
                            DropdownButtonFormField<String>(
                              decoration: InputDecoration(
                                  labelText: 'نوع التخزين',
                                  border: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(12))),
                              value: _storageTypeController.text.isNotEmpty
                                  ? _storageTypeController.text
                                  : null,
                              items: DeviceFormConstants.storageTypes
                                  .map((storageType) => DropdownMenuItem(
                                      value: storageType,
                                      child: Text(storageType)))
                                  .toList(),
                              onChanged: (value) =>
                                  _storageTypeController.text = value ?? '',
                              validator: (value) =>
                                  ValidationUtils.validateDropdown(value,
                                      errorMessage:
                                          'الرجاء اختيار نوع التخزين'),
                            ),
                            const SizedBox(height: 16),
                            DropdownButtonFormField<String>(
                              decoration: InputDecoration(
                                  labelText: 'حجم التخزين',
                                  border: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(12))),
                              value: _storageSizeController.text.isNotEmpty
                                  ? _storageSizeController.text
                                  : null,
                              items: DeviceFormConstants.storageSizes
                                  .map((storageSize) => DropdownMenuItem(
                                      value: storageSize,
                                      child: Text(storageSize)))
                                  .toList(),
                              onChanged: (value) =>
                                  _storageSizeController.text = value ?? '',
                              validator: (value) =>
                                  ValidationUtils.validateDropdown(value,
                                      errorMessage:
                                          'الرجاء اختيار حجم التخزين'),
                            ),
                            const SizedBox(height: 16),
                            SwitchListTile(
                              title: const Text('تخزين إضافي'),
                              subtitle: Text(
                                  _hasExtraStorage
                                      ? 'يوجد تخزين إضافي'
                                      : 'لا يوجد تخزين إضافي',
                                  style: TextStyle(
                                      color: _hasExtraStorage
                                          ? Colors.blue
                                          : Colors.grey)),
                              value: _hasExtraStorage,
                              onChanged: (value) =>
                                  setState(() => _hasExtraStorage = value),
                              activeColor: Colors.blue,
                            ),
                            const SizedBox(height: 16),
                            if (_hasExtraStorage) ...[
                              TextFormField(
                                  controller: _extraStorageTypeController,
                                  decoration: InputDecoration(
                                      labelText: 'نوع التخزين الإضافي',
                                      border: OutlineInputBorder(
                                          borderRadius:
                                              BorderRadius.circular(12))),
                                  validator: (value) =>
                                      ValidationUtils.validateRequired(
                                          value, 'نوع التخزين الإضافي مطلوب')),
                              const SizedBox(height: 16),
                              TextFormField(
                                  controller: _extraStorageSizeController,
                                  decoration: InputDecoration(
                                      labelText: 'حجم التخزين الإضافي',
                                      border: OutlineInputBorder(
                                          borderRadius:
                                              BorderRadius.circular(12))),
                                  validator: (value) =>
                                      ValidationUtils.validateRequired(
                                          value, 'حجم التخزين الإضافي مطلوب')),
                              const SizedBox(height: 16),
                            ],
                            DropdownButtonFormField<String>(
                              decoration: InputDecoration(
                                  labelText: 'إصدار نظام التشغيل',
                                  border: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(12))),
                              value: _osVersionController.text.isNotEmpty
                                  ? _osVersionController.text
                                  : null,
                              items: DeviceFormConstants.osVersions
                                  .map((osVersion) => DropdownMenuItem(
                                      value: osVersion, child: Text(osVersion)))
                                  .toList(),
                              onChanged: (value) =>
                                  _osVersionController.text = value ?? '',
                              validator: (value) =>
                                  ValidationUtils.validateDropdown(value,
                                      errorMessage:
                                          'الرجاء اختيار إصدار نظام التشغيل'),
                            ),
                            const SizedBox(height: 16),
                            TextFormField(
                                controller: _notesController,
                                maxLines: 3,
                                decoration: InputDecoration(
                                    labelText: 'ملاحظات',
                                    border: OutlineInputBorder(
                                        borderRadius:
                                            BorderRadius.circular(12)))),
                            const SizedBox(height: 24),
                            // ✅ 5. تحديث منطقة الأزرار
                            if (isEditing)
                              ElevatedButton(
                                onPressed: _saveAndPop,
                                style: ElevatedButton.styleFrom(
                                    minimumSize:
                                        const Size(double.infinity, 50)),
                                child: const Text('حفظ التغييرات'),
                              )
                            else
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.stretch,
                                children: [
                                  ElevatedButton(
                                    onPressed: _saveAndPop,
                                    style: ElevatedButton.styleFrom(
                                        minimumSize:
                                            const Size(double.infinity, 50)),
                                    child: const Text('إضافة الجهاز'),
                                  ),
                                  const SizedBox(height: 8),
                                  ElevatedButton.icon(
                                    onPressed: _saveAndAddAnother,
                                    icon: const Icon(
                                        Icons.add_to_photos_outlined),
                                    label: const Text('إضافة ومتابعة'),
                                    style: ElevatedButton.styleFrom(
                                      minimumSize:
                                          const Size(double.infinity, 50),
                                      backgroundColor:
                                          theme.colorScheme.secondary,
                                      foregroundColor:
                                          theme.colorScheme.onSecondary,
                                    ),
                                  ),
                                ],
                              ),
                          ],
                        ],
                      ),
                    ),
                  ),
      ),
    );
  }
}
