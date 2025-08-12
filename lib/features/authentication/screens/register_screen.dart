import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../app_colors.dart';
import '../../../services/auth_service.dart';
import '../../../widgets/file_upload_widget.dart';

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _phoneController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  final _licenseController = TextEditingController();
  final _nationalIdController = TextEditingController();

  bool _isLoading = false;
  bool _obscurePassword = true;
  bool _obscureConfirmPassword = true;
  String _selectedCity = 'Baghdad';
  String _selectedVehicleType = 'motorcycle';

  // File upload data
  Map<String, dynamic>? _drivingLicenseFile;
  Map<String, dynamic>? _registrationPaperFile;
  String? _drivingLicenseError;
  String? _registrationPaperError;

  final List<Map<String, String>> _iraqiCities = [
    {'value': 'Baghdad', 'label': 'بغداد'},
    {'value': 'Basra', 'label': 'البصرة'},
    {'value': 'Erbil', 'label': 'أربيل'},
    {'value': 'Mosul', 'label': 'الموصل'},
    {'value': 'Najaf', 'label': 'النجف'},
    {'value': 'Karbala', 'label': 'كربلاء'},
  ];

  final List<Map<String, String>> _vehicleTypes = [
    {'value': 'motorcycle', 'label': 'دراجة نارية'},
    {'value': 'car', 'label': 'سيارة'},
    {'value': 'bicycle', 'label': 'دراجة هوائية'},
  ];

  @override
  void dispose() {
    _nameController.dispose();
    _phoneController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    _licenseController.dispose();
    _nationalIdController.dispose();
    super.dispose();
  }

  void _onVehicleTypeChanged(String? value) {
    setState(() {
      _selectedVehicleType = value!;
      // Clear file errors when vehicle type changes
      _drivingLicenseError = null;
      _registrationPaperError = null;
    });
  }

  void _onDrivingLicenseSelected(Map<String, dynamic> fileData) {
    setState(() {
      _drivingLicenseFile = fileData;
      _drivingLicenseError = null;
    });
  }

  void _onDrivingLicenseRemoved() {
    setState(() {
      _drivingLicenseFile = null;
      _drivingLicenseError = null;
    });
  }

  void _onRegistrationPaperSelected(Map<String, dynamic> fileData) {
    setState(() {
      _registrationPaperFile = fileData;
      _registrationPaperError = null;
    });
  }

  void _onRegistrationPaperRemoved() {
    setState(() {
      _registrationPaperFile = null;
      _registrationPaperError = null;
    });
  }

  bool _validateFiles() {
    bool isValid = true;

    // Validate driving license for car and motorcycle
    if (['car', 'motorcycle'].contains(_selectedVehicleType)) {
      if (_drivingLicenseFile == null) {
        setState(() {
          _drivingLicenseError = 'رخصة القيادة مطلوبة للسيارة والدراجة النارية';
        });
        isValid = false;
      }
    }

    // Validate registration paper for car
    if (_selectedVehicleType == 'car') {
      if (_registrationPaperFile == null) {
        setState(() {
          _registrationPaperError = 'ورقة تسجيل المركبة مطلوبة للسيارة';
        });
        isValid = false;
      }
    }

    return isValid;
  }

  Future<void> _register() async {
    if (!_formKey.currentState!.validate()) return;
    if (!_validateFiles()) return;

    setState(() {
      _isLoading = true;
    });

    try {
      final result = await AuthService.register(
        name: _nameController.text.trim(),
        phone: _phoneController.text.trim(),
        password: _passwordController.text,
        city: _selectedCity,
        vehicleType: _selectedVehicleType,
        licenseNumber: _licenseController.text.trim(),
        nationalId: _nationalIdController.text.trim(),
      );

      if (result['success']) {
        if (mounted) {
          // Navigate to phone verification
          context.pushReplacement(
            '/verify-phone',
            extra: {'phone': _phoneController.text.trim()},
          );
        }
      } else {
        if (mounted) {
          // Handle different error types
          final errorType = result['error_type'];

          if (errorType == 'phone_verification_required') {
            // Phone exists but needs verification - go to verification screen
            context.pushReplacement(
              '/verify-phone',
              extra: {'phone': result['phone'] ?? _phoneController.text.trim()},
            );
          } else if (errorType == 'phone_already_registered') {
            // Phone is fully registered - show option to go to login
            _showAlreadyRegisteredDialog(result['message']);
          } else {
            // Other errors - show error message
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(result['message'] ?? 'فشل في التسجيل'),
                backgroundColor: AppColors.error,
              ),
            );
          }
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('خطأ في الاتصال: ${e.toString()}'),
            backgroundColor: AppColors.error,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  void _showAlreadyRegisteredDialog(String message) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('رقم مسجل مسبقاً'),
        content: Text(message),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text(
              'إلغاء',
              style: TextStyle(color: AppColors.textSecondary),
            ),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              // Navigate to login screen
              context.go('/login');
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary,
              foregroundColor: Colors.white,
            ),
            child: const Text('تسجيل الدخول'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('تسجيل حساب جديد'),
        backgroundColor: AppColors.white,
        foregroundColor: AppColors.textPrimary,
        elevation: 0,
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24.0),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const SizedBox(height: 20),

                // Header
                const Text(
                  'انضم إلى فريق حاضر',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: AppColors.textPrimary,
                  ),
                ),
                const SizedBox(height: 8),
                const Text(
                  'املأ البيانات التالية لبدء العمل كسائق',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 14,
                    color: AppColors.textSecondary,
                  ),
                ),
                const SizedBox(height: 32),

                // Name field
                TextFormField(
                  controller: _nameController,
                  decoration: const InputDecoration(
                    labelText: 'الاسم الكامل',
                    prefixIcon: Icon(Icons.person),
                    border: OutlineInputBorder(),
                  ),
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'يرجى إدخال الاسم الكامل';
                    }
                    if (value.length < 3) {
                      return 'الاسم يجب أن يكون 3 أحرف على الأقل';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 16),

                // Phone number field
                TextFormField(
                  controller: _phoneController,
                  keyboardType: TextInputType.phone,
                  textDirection: TextDirection.ltr,
                  decoration: const InputDecoration(
                    labelText: 'رقم الهاتف',
                    hintText: '07XX XXX XXXX',
                    prefixIcon: Icon(Icons.phone),
                    border: OutlineInputBorder(),
                  ),
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'يرجى إدخال رقم الهاتف';
                    }
                    // Clean input for validation (remove spaces and dashes)
                    String cleanValue = value.trim().replaceAll(
                      RegExp(r'[\s\-]'),
                      '',
                    );
                    if (!RegExp(
                      r'^(\+964|0)(7[0-9]{9})$',
                    ).hasMatch(cleanValue)) {
                      return 'رقم الهاتف غير صحيح (مثال: 07XXXXXXXXX)';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 16),

                // City dropdown
                DropdownButtonFormField<String>(
                  value: _selectedCity,
                  decoration: const InputDecoration(
                    labelText: 'المدينة',
                    prefixIcon: Icon(Icons.location_city),
                    border: OutlineInputBorder(),
                  ),
                  items: _iraqiCities.map((city) {
                    return DropdownMenuItem<String>(
                      value: city['value'],
                      child: Text(city['label']!),
                    );
                  }).toList(),
                  onChanged: (value) {
                    setState(() {
                      _selectedCity = value!;
                    });
                  },
                ),
                const SizedBox(height: 16),

                // Vehicle type dropdown
                DropdownButtonFormField<String>(
                  value: _selectedVehicleType,
                  decoration: const InputDecoration(
                    labelText: 'نوع المركبة',
                    prefixIcon: Icon(Icons.directions_bike),
                    border: OutlineInputBorder(),
                  ),
                  items: _vehicleTypes.map((vehicle) {
                    return DropdownMenuItem<String>(
                      value: vehicle['value'],
                      child: Text(vehicle['label']!),
                    );
                  }).toList(),
                  onChanged: _onVehicleTypeChanged,
                ),
                const SizedBox(height: 16),

                // License number field
                TextFormField(
                  controller: _licenseController,
                  decoration: const InputDecoration(
                    labelText: 'رقم رخصة القيادة',
                    prefixIcon: Icon(Icons.card_membership),
                    border: OutlineInputBorder(),
                  ),
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'يرجى إدخال رقم رخصة القيادة';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 16),

                // National ID field
                TextFormField(
                  controller: _nationalIdController,
                  decoration: const InputDecoration(
                    labelText: 'رقم الهوية الوطنية',
                    prefixIcon: Icon(Icons.badge),
                    border: OutlineInputBorder(),
                  ),
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'يرجى إدخال رقم الهوية الوطنية';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 16),

                // File upload section
                if (['car', 'motorcycle'].contains(_selectedVehicleType)) ...[
                  // Driving License Upload
                  FileUploadWidget(
                    label: 'رخصة القيادة',
                    hint: 'ارفع صورة أو ملف PDF لرخصة القيادة',
                    isRequired: true,
                    errorText: _drivingLicenseError,
                    onFileSelected: _onDrivingLicenseSelected,
                    onFileRemoved: _onDrivingLicenseRemoved,
                    allowedExtensions: ['pdf', 'jpg', 'jpeg', 'png', 'heic'],
                    maxSizeMB: 10,
                  ),
                  const SizedBox(height: 16),
                ],

                // Registration Paper Upload (only for car)
                if (_selectedVehicleType == 'car') ...[
                  FileUploadWidget(
                    label: 'ورقة تسجيل المركبة',
                    hint: 'ارفع صورة أو ملف PDF لورقة تسجيل المركبة',
                    isRequired: true,
                    errorText: _registrationPaperError,
                    onFileSelected: _onRegistrationPaperSelected,
                    onFileRemoved: _onRegistrationPaperRemoved,
                    allowedExtensions: ['pdf', 'jpg', 'jpeg', 'png', 'heic'],
                    maxSizeMB: 10,
                  ),
                  const SizedBox(height: 16),
                ],

                // Password field
                TextFormField(
                  controller: _passwordController,
                  obscureText: _obscurePassword,
                  decoration: InputDecoration(
                    labelText: 'كلمة المرور',
                    hintText: 'مثال: MyPass123!',
                    helperText:
                        '8 أحرف على الأقل، حرف كبير، صغير، رقم، ورمز خاص',
                    helperMaxLines: 2,
                    prefixIcon: const Icon(Icons.lock),
                    suffixIcon: IconButton(
                      icon: Icon(
                        _obscurePassword
                            ? Icons.visibility
                            : Icons.visibility_off,
                      ),
                      onPressed: () {
                        setState(() {
                          _obscurePassword = !_obscurePassword;
                        });
                      },
                    ),
                    border: const OutlineInputBorder(),
                  ),
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'يرجى إدخال كلمة المرور';
                    }
                    if (value.length < 8) {
                      return 'كلمة المرور يجب أن تكون 8 أحرف على الأقل';
                    }
                    if (!RegExp(
                      r'^(?=.*[a-z])(?=.*[A-Z])(?=.*\d)(?=.*[@$!%*?&])[A-Za-z\d@$!%*?&]+$',
                    ).hasMatch(value)) {
                      return 'كلمة المرور يجب أن تحتوي على حرف كبير وصغير ورقم ورمز خاص';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 16),

                // Confirm password field
                TextFormField(
                  controller: _confirmPasswordController,
                  obscureText: _obscureConfirmPassword,
                  decoration: InputDecoration(
                    labelText: 'تأكيد كلمة المرور',
                    prefixIcon: const Icon(Icons.lock_outline),
                    suffixIcon: IconButton(
                      icon: Icon(
                        _obscureConfirmPassword
                            ? Icons.visibility
                            : Icons.visibility_off,
                      ),
                      onPressed: () {
                        setState(() {
                          _obscureConfirmPassword = !_obscureConfirmPassword;
                        });
                      },
                    ),
                    border: const OutlineInputBorder(),
                  ),
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'يرجى تأكيد كلمة المرور';
                    }
                    if (value != _passwordController.text) {
                      return 'كلمة المرور غير متطابقة';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 32),

                // Register button
                SizedBox(
                  height: 50,
                  child: ElevatedButton(
                    onPressed: _isLoading ? null : _register,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primary,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                    child: _isLoading
                        ? const CircularProgressIndicator(color: Colors.white)
                        : const Text(
                            'تسجيل الحساب',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                  ),
                ),
                const SizedBox(height: 16),

                // Login link
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Text(
                      'لديك حساب؟ ',
                      style: TextStyle(color: AppColors.textSecondary),
                    ),
                    TextButton(
                      onPressed: () {
                        context.go('/login');
                      },
                      child: const Text(
                        'سجل الدخول',
                        style: TextStyle(
                          color: AppColors.primary,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
