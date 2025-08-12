import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../app_colors.dart';
import '../../../config/app_config.dart';
import '../../../providers/riverpod/services_provider.dart';
import '../../../services/new_auth_service.dart';

class NewDriverSignupScreen extends ConsumerStatefulWidget {
  const NewDriverSignupScreen({super.key});

  @override
  ConsumerState<NewDriverSignupScreen> createState() =>
      _NewDriverSignupScreenState();
}

class _NewDriverSignupScreenState extends ConsumerState<NewDriverSignupScreen>
    with TickerProviderStateMixin {
  late PageController _pageController;
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;

  int _currentStep = 0;
  bool _isLoading = false;
  String _authMethod = 'email'; // 'email' or 'phone'

  // Form keys
  final _personalFormKey = GlobalKey<FormState>();
  final _vehicleFormKey = GlobalKey<FormState>();
  final _passwordFormKey = GlobalKey<FormState>();

  // Personal Info Controllers
  final _fullNameController = TextEditingController();
  final _emailController = TextEditingController();
  final _phoneController = TextEditingController();
  final _cityController = TextEditingController();
  final _nationalIdController = TextEditingController();

  // Vehicle Info Controllers
  final _vehicleTypeController = TextEditingController();
  final _licenseNumberController = TextEditingController();

  // Password Controllers
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();

  final List<String> _iraqiCities = [
    'بغداد',
    'البصرة',
    'أربيل',
    'النجف',
    'كركوك',
    'السليمانية',
    'الموصل',
    'الحلة',
    'الرمادي',
    'الناصرية',
    'العمارة',
    'الديوانية',
    'كربلاء',
    'تكريت',
    'بعقوبة',
    'سامراء',
    'الكوت',
  ];

  final List<String> _vehicleTypes = [
    'سيارة شخصية',
    'دراجة نارية',
    'شاحنة صغيرة',
    'فان',
    'سيارة كهربائية',
  ];

  @override
  void initState() {
    super.initState();
    _pageController = PageController();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );
    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeInOut),
    );
    _animationController.forward();
  }

  @override
  void dispose() {
    _pageController.dispose();
    _animationController.dispose();
    _fullNameController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    _cityController.dispose();
    _nationalIdController.dispose();
    _vehicleTypeController.dispose();
    _licenseNumberController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  void _nextStep() {
    if (_currentStep < 2) {
      setState(() {
        _currentStep++;
      });
      _pageController.nextPage(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
    }
  }

  void _previousStep() {
    if (_currentStep > 0) {
      setState(() {
        _currentStep--;
      });
      _pageController.previousPage(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
    }
  }

  bool _validateCurrentStep() {
    switch (_currentStep) {
      case 0:
        return _personalFormKey.currentState?.validate() ?? false;
      case 1:
        return _vehicleFormKey.currentState?.validate() ?? false;
      case 2:
        return _passwordFormKey.currentState?.validate() ?? false;
      default:
        return false;
    }
  }

  Future<void> _submitRegistration() async {
    if (!_validateCurrentStep()) {
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      Map<String, dynamic> result;

      if (AppConfig.enableAWSIntegration) {
        // Use AWS Cognito for registration
        final cognitoService = ref.read(cognitoAuthServiceProvider);

        if (_authMethod == 'email') {
          result = await cognitoService.registerWithEmail(
            email: _emailController.text.trim(),
            password: _passwordController.text,
            fullName: _fullNameController.text.trim(),
            phone: _phoneController.text.trim(),
            city: _cityController.text,
            vehicleType: _vehicleTypeController.text,
            licenseNumber: _licenseNumberController.text.trim(),
            nationalId: _nationalIdController.text.trim(),
          );
        } else {
          result = await cognitoService.registerWithPhone(
            phone: _phoneController.text.trim(),
            password: _passwordController.text,
            fullName: _fullNameController.text.trim(),
            city: _cityController.text,
            vehicleType: _vehicleTypeController.text,
            licenseNumber: _licenseNumberController.text.trim(),
            nationalId: _nationalIdController.text.trim(),
          );
        }
      } else {
        // Use mock auth service for offline mode
        final authService = ref.read(newAuthServiceProvider);

        if (_authMethod == 'email') {
          result = await authService.registerWithEmail(
            email: _emailController.text.trim(),
            password: _passwordController.text,
            fullName: _fullNameController.text.trim(),
            phone: _phoneController.text.trim(),
            city: _cityController.text,
            vehicleType: _vehicleTypeController.text,
            licenseNumber: _licenseNumberController.text.trim(),
            nationalId: _nationalIdController.text.trim(),
          );
        } else {
          result = await authService.registerWithPhone(
            phone: _phoneController.text.trim(),
            password: _passwordController.text,
            fullName: _fullNameController.text.trim(),
            city: _cityController.text,
            vehicleType: _vehicleTypeController.text,
            licenseNumber: _licenseNumberController.text.trim(),
            nationalId: _nationalIdController.text.trim(),
          );
        }
      }

      if (mounted) {
        if (result['success'] == true) {
          _showSuccessDialog(result['message']);

          // Handle navigation based on confirmation requirements
          if (AppConfig.enableAWSIntegration) {
            if (result['confirmation_required'] == true ||
                result['phone_verification_required'] == true) {
              // Navigate to verification screen
              if (_authMethod == 'email') {
                context.go(
                  '/email-verification',
                  extra: {
                    'email': _emailController.text.trim(),
                    'fromSignup': true,
                  },
                );
              } else {
                context.go(
                  '/phone-verification',
                  extra: {
                    'phone': _phoneController.text.trim(),
                    'fromSignup': true,
                  },
                );
              }
            } else {
              // Account created and verified, go to login
              context.go('/new-login');
            }
          } else {
            // Mock mode - navigate to verification screen
            if (_authMethod == 'email') {
              context.go(
                '/email-verification',
                extra: {
                  'email': _emailController.text.trim(),
                  'fromSignup': true,
                },
              );
            } else {
              context.go(
                '/phone-verification',
                extra: {
                  'phone': _phoneController.text.trim(),
                  'fromSignup': true,
                },
              );
            }
          }
        } else {
          _showErrorDialog(result['message'] ?? 'فشل في التسجيل');
        }
      }
    } catch (e) {
      if (mounted) {
        _showErrorDialog('خطأ في التسجيل: $e');
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  void _showSuccessDialog(String message) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppColors.surface,
        title: Text(
          'تم التسجيل بنجاح',
          style: TextStyle(color: AppColors.primary),
          textAlign: TextAlign.right,
        ),
        content: Text(
          message,
          style: TextStyle(color: AppColors.textPrimary),
          textAlign: TextAlign.right,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: Text('حسناً', style: TextStyle(color: AppColors.primary)),
          ),
        ],
      ),
    );
  }

  void _showErrorDialog(String message) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppColors.surface,
        title: Text(
          'خطأ في التسجيل',
          style: TextStyle(color: AppColors.error),
          textAlign: TextAlign.right,
        ),
        content: Text(
          message,
          style: TextStyle(color: AppColors.textPrimary),
          textAlign: TextAlign.right,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: Text('حسناً', style: TextStyle(color: AppColors.primary)),
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
        backgroundColor: AppColors.primary,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: AppColors.white),
          onPressed: () => context.go('/new-login'),
        ),
        title: Text(
          'تسجيل سائق جديد',
          style: TextStyle(
            color: AppColors.white,
            fontSize: 20,
            fontWeight: FontWeight.bold,
          ),
        ),
        centerTitle: true,
      ),
      body: FadeTransition(
        opacity: _fadeAnimation,
        child: Column(
          children: [
            // Progress Indicator
            Container(
              padding: const EdgeInsets.all(20),
              child: Row(
                children: List.generate(3, (index) {
                  bool isActive = index <= _currentStep;
                  bool isCurrent = index == _currentStep;

                  return Expanded(
                    child: Container(
                      margin: const EdgeInsets.symmetric(horizontal: 4),
                      child: Row(
                        children: [
                          Expanded(
                            child: Container(
                              height: 4,
                              decoration: BoxDecoration(
                                color: isActive
                                    ? AppColors.primary
                                    : AppColors.border,
                                borderRadius: BorderRadius.circular(2),
                              ),
                            ),
                          ),
                          if (index < 2)
                            Container(
                              width: 20,
                              height: 20,
                              margin: const EdgeInsets.symmetric(horizontal: 8),
                              decoration: BoxDecoration(
                                color: isCurrent
                                    ? AppColors.primary
                                    : isActive
                                    ? AppColors.primary.withAlpha(77)
                                    : AppColors.border,
                                shape: BoxShape.circle,
                                border: isCurrent
                                    ? Border.all(
                                        color: AppColors.primary,
                                        width: 2,
                                      )
                                    : null,
                              ),
                              child: isCurrent
                                  ? Icon(
                                      Icons.circle,
                                      color: AppColors.white,
                                      size: 12,
                                    )
                                  : null,
                            ),
                        ],
                      ),
                    ),
                  );
                }),
              ),
            ),

            // Page Content
            Expanded(
              child: PageView(
                controller: _pageController,
                physics: const NeverScrollableScrollPhysics(),
                children: [
                  _buildPersonalInfoStep(),
                  _buildVehicleInfoStep(),
                  _buildPasswordStep(),
                ],
              ),
            ),

            // Navigation Buttons
            Container(
              padding: const EdgeInsets.all(20),
              child: Row(
                children: [
                  if (_currentStep > 0)
                    Expanded(
                      child: TextButton(
                        onPressed: _previousStep,
                        style: TextButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 15),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10),
                          ),
                        ),
                        child: Text(
                          'السابق',
                          style: TextStyle(
                            color: AppColors.primary,
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),
                  if (_currentStep > 0) const SizedBox(width: 16),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: _isLoading
                          ? null
                          : () {
                              if (_validateCurrentStep()) {
                                if (_currentStep < 2) {
                                  _nextStep();
                                } else {
                                  _submitRegistration();
                                }
                              }
                            },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primary,
                        padding: const EdgeInsets.symmetric(vertical: 15),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                        elevation: 2,
                      ),
                      child: _isLoading
                          ? SizedBox(
                              height: 20,
                              width: 20,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                valueColor: AlwaysStoppedAnimation<Color>(
                                  AppColors.white,
                                ),
                              ),
                            )
                          : Text(
                              _currentStep < 2 ? 'التالي' : 'إنشاء الحساب',
                              style: TextStyle(
                                color: AppColors.white,
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPersonalInfoStep() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Form(
        key: _personalFormKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'المعلومات الشخصية',
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: AppColors.primary,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'يرجى إدخال بياناتك الشخصية بدقة',
              style: TextStyle(fontSize: 16, color: AppColors.textSecondary),
            ),
            const SizedBox(height: 30),

            // Auth Method Toggle
            Container(
              decoration: BoxDecoration(
                color: AppColors.surface,
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: AppColors.border),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: GestureDetector(
                      onTap: () => setState(() => _authMethod = 'email'),
                      child: Container(
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        decoration: BoxDecoration(
                          color: _authMethod == 'email'
                              ? AppColors.primary
                              : Colors.transparent,
                          borderRadius: const BorderRadius.horizontal(
                            left: Radius.circular(10),
                          ),
                        ),
                        child: Text(
                          'البريد الإلكتروني',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            color: _authMethod == 'email'
                                ? AppColors.white
                                : AppColors.textPrimary,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),
                  ),
                  Expanded(
                    child: GestureDetector(
                      onTap: () => setState(() => _authMethod = 'phone'),
                      child: Container(
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        decoration: BoxDecoration(
                          color: _authMethod == 'phone'
                              ? AppColors.primary
                              : Colors.transparent,
                          borderRadius: const BorderRadius.horizontal(
                            right: Radius.circular(10),
                          ),
                        ),
                        child: Text(
                          'رقم الهاتف',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            color: _authMethod == 'phone'
                                ? AppColors.white
                                : AppColors.textPrimary,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),

            // Full Name
            TextFormField(
              controller: _fullNameController,
              textAlign: TextAlign.right,
              style: TextStyle(color: AppColors.textPrimary),
              decoration: InputDecoration(
                labelText: 'الاسم الكامل',
                labelStyle: TextStyle(color: AppColors.textSecondary),
                prefixIcon: Icon(Icons.person, color: AppColors.primary),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                  borderSide: BorderSide(color: AppColors.border),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                  borderSide: BorderSide(color: AppColors.primary, width: 2),
                ),
                filled: true,
                fillColor: AppColors.surface,
              ),
              validator: (value) {
                if (value == null || value.trim().isEmpty) {
                  return 'يرجى إدخال الاسم الكامل';
                }
                if (value.trim().length < 3) {
                  return 'يجب أن يكون الاسم 3 أحرف على الأقل';
                }
                return null;
              },
            ),
            const SizedBox(height: 16),

            // Email or Phone based on auth method
            if (_authMethod == 'email') ...[
              TextFormField(
                controller: _emailController,
                keyboardType: TextInputType.emailAddress,
                textAlign: TextAlign.right,
                style: TextStyle(color: AppColors.textPrimary),
                decoration: InputDecoration(
                  labelText: 'البريد الإلكتروني',
                  labelStyle: TextStyle(color: AppColors.textSecondary),
                  prefixIcon: Icon(Icons.email, color: AppColors.primary),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                    borderSide: BorderSide(color: AppColors.border),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                    borderSide: BorderSide(color: AppColors.primary, width: 2),
                  ),
                  filled: true,
                  fillColor: AppColors.surface,
                ),
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'يرجى إدخال البريد الإلكتروني';
                  }
                  if (!NewAuthService.isValidEmail(value.trim())) {
                    return 'يرجى إدخال بريد إلكتروني صحيح';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _phoneController,
                keyboardType: TextInputType.phone,
                textAlign: TextAlign.right,
                style: TextStyle(color: AppColors.textPrimary),
                decoration: InputDecoration(
                  labelText: 'رقم الهاتف (اختياري)',
                  labelStyle: TextStyle(color: AppColors.textSecondary),
                  prefixIcon: Icon(Icons.phone, color: AppColors.primary),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                    borderSide: BorderSide(color: AppColors.border),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                    borderSide: BorderSide(color: AppColors.primary, width: 2),
                  ),
                  filled: true,
                  fillColor: AppColors.surface,
                ),
              ),
            ] else ...[
              TextFormField(
                controller: _phoneController,
                keyboardType: TextInputType.phone,
                textAlign: TextAlign.right,
                style: TextStyle(color: AppColors.textPrimary),
                decoration: InputDecoration(
                  labelText: 'رقم الهاتف',
                  labelStyle: TextStyle(color: AppColors.textSecondary),
                  prefixIcon: Icon(Icons.phone, color: AppColors.primary),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                    borderSide: BorderSide(color: AppColors.border),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                    borderSide: BorderSide(color: AppColors.primary, width: 2),
                  ),
                  filled: true,
                  fillColor: AppColors.surface,
                ),
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'يرجى إدخال رقم الهاتف';
                  }
                  if (!NewAuthService.isValidIraqiPhone(value.trim())) {
                    return 'يرجى إدخال رقم هاتف عراقي صحيح (07XXXXXXXXX)';
                  }
                  return null;
                },
              ),
            ],
            const SizedBox(height: 16),

            // City Dropdown
            DropdownButtonFormField<String>(
              value: _cityController.text.isNotEmpty
                  ? _cityController.text
                  : null,
              style: TextStyle(color: AppColors.textPrimary),
              decoration: InputDecoration(
                labelText: 'المحافظة',
                labelStyle: TextStyle(color: AppColors.textSecondary),
                prefixIcon: Icon(Icons.location_city, color: AppColors.primary),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                  borderSide: BorderSide(color: AppColors.border),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                  borderSide: BorderSide(color: AppColors.primary, width: 2),
                ),
                filled: true,
                fillColor: AppColors.surface,
              ),
              items: _iraqiCities.map((city) {
                return DropdownMenuItem(
                  value: city,
                  child: Text(city, textAlign: TextAlign.right),
                );
              }).toList(),
              onChanged: (value) {
                _cityController.text = value ?? '';
              },
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'يرجى اختيار المحافظة';
                }
                return null;
              },
            ),
            const SizedBox(height: 16),

            // National ID
            TextFormField(
              controller: _nationalIdController,
              keyboardType: TextInputType.number,
              textAlign: TextAlign.right,
              style: TextStyle(color: AppColors.textPrimary),
              decoration: InputDecoration(
                labelText: 'رقم الهوية الوطنية',
                labelStyle: TextStyle(color: AppColors.textSecondary),
                prefixIcon: Icon(Icons.badge, color: AppColors.primary),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                  borderSide: BorderSide(color: AppColors.border),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                  borderSide: BorderSide(color: AppColors.primary, width: 2),
                ),
                filled: true,
                fillColor: AppColors.surface,
              ),
              validator: (value) {
                if (value == null || value.trim().isEmpty) {
                  return 'يرجى إدخال رقم الهوية الوطنية';
                }
                if (value.trim().length < 8) {
                  return 'رقم الهوية الوطنية غير صحيح';
                }
                return null;
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildVehicleInfoStep() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Form(
        key: _vehicleFormKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'معلومات المركبة',
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: AppColors.primary,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'معلومات مركبة التوصيل الخاصة بك',
              style: TextStyle(fontSize: 16, color: AppColors.textSecondary),
            ),
            const SizedBox(height: 30),

            // Vehicle Type Dropdown
            DropdownButtonFormField<String>(
              value: _vehicleTypeController.text.isNotEmpty
                  ? _vehicleTypeController.text
                  : null,
              style: TextStyle(color: AppColors.textPrimary),
              decoration: InputDecoration(
                labelText: 'نوع المركبة',
                labelStyle: TextStyle(color: AppColors.textSecondary),
                prefixIcon: Icon(
                  Icons.directions_car,
                  color: AppColors.primary,
                ),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                  borderSide: BorderSide(color: AppColors.border),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                  borderSide: BorderSide(color: AppColors.primary, width: 2),
                ),
                filled: true,
                fillColor: AppColors.surface,
              ),
              items: _vehicleTypes.map((type) {
                return DropdownMenuItem(
                  value: type,
                  child: Text(type, textAlign: TextAlign.right),
                );
              }).toList(),
              onChanged: (value) {
                _vehicleTypeController.text = value ?? '';
              },
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'يرجى اختيار نوع المركبة';
                }
                return null;
              },
            ),
            const SizedBox(height: 16),

            // License Number
            TextFormField(
              controller: _licenseNumberController,
              textAlign: TextAlign.right,
              style: TextStyle(color: AppColors.textPrimary),
              decoration: InputDecoration(
                labelText: 'رقم رخصة القيادة',
                labelStyle: TextStyle(color: AppColors.textSecondary),
                prefixIcon: Icon(Icons.credit_card, color: AppColors.primary),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                  borderSide: BorderSide(color: AppColors.border),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                  borderSide: BorderSide(color: AppColors.primary, width: 2),
                ),
                filled: true,
                fillColor: AppColors.surface,
              ),
              validator: (value) {
                if (value == null || value.trim().isEmpty) {
                  return 'يرجى إدخال رقم رخصة القيادة';
                }
                if (value.trim().length < 5) {
                  return 'رقم رخصة القيادة غير صحيح';
                }
                return null;
              },
            ),
            const SizedBox(height: 20),

            // Requirements Info
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppColors.primary.withAlpha(26),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: AppColors.primary.withAlpha(77)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'متطلبات التسجيل:',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: AppColors.primary,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    '• رخصة قيادة سارية المفعول\n'
                    '• مركبة صالحة للتوصيل\n'
                    '• هوية وطنية صحيحة\n'
                    '• هاتف ذكي مع اتصال إنترنت',
                    style: TextStyle(
                      fontSize: 14,
                      color: AppColors.textSecondary,
                      height: 1.5,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPasswordStep() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Form(
        key: _passwordFormKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'إنشاء كلمة المرور',
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: AppColors.primary,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'قم بإنشاء كلمة مرور قوية لحسابك',
              style: TextStyle(fontSize: 16, color: AppColors.textSecondary),
            ),
            const SizedBox(height: 30),

            // Password
            TextFormField(
              controller: _passwordController,
              obscureText: true,
              textAlign: TextAlign.right,
              style: TextStyle(color: AppColors.textPrimary),
              decoration: InputDecoration(
                labelText: 'كلمة المرور',
                labelStyle: TextStyle(color: AppColors.textSecondary),
                prefixIcon: Icon(Icons.lock, color: AppColors.primary),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                  borderSide: BorderSide(color: AppColors.border),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                  borderSide: BorderSide(color: AppColors.primary, width: 2),
                ),
                filled: true,
                fillColor: AppColors.surface,
              ),
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'يرجى إدخال كلمة المرور';
                }
                if (value.length < 8) {
                  return 'كلمة المرور يجب أن تكون 8 أحرف على الأقل';
                }
                if (!RegExp(r'^(?=.*[a-zA-Z])(?=.*\d)').hasMatch(value)) {
                  return 'كلمة المرور يجب أن تحتوي على أحرف وأرقام';
                }
                return null;
              },
            ),
            const SizedBox(height: 16),

            // Confirm Password
            TextFormField(
              controller: _confirmPasswordController,
              obscureText: true,
              textAlign: TextAlign.right,
              style: TextStyle(color: AppColors.textPrimary),
              decoration: InputDecoration(
                labelText: 'تأكيد كلمة المرور',
                labelStyle: TextStyle(color: AppColors.textSecondary),
                prefixIcon: Icon(Icons.lock_outline, color: AppColors.primary),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                  borderSide: BorderSide(color: AppColors.border),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                  borderSide: BorderSide(color: AppColors.primary, width: 2),
                ),
                filled: true,
                fillColor: AppColors.surface,
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
            const SizedBox(height: 20),

            // Password Requirements
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppColors.primary.withAlpha(26),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: AppColors.primary.withAlpha(77)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'متطلبات كلمة المرور:',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: AppColors.primary,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    '• 8 أحرف على الأقل\n'
                    '• أحرف كبيرة وصغيرة\n'
                    '• رقم واحد على الأقل\n'
                    '• رمز خاص (اختياري)',
                    style: TextStyle(
                      fontSize: 14,
                      color: AppColors.textSecondary,
                      height: 1.5,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),

            // Terms and Conditions
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppColors.surface,
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: AppColors.border),
              ),
              child: Text(
                'بالضغط على "إنشاء الحساب" فإنك توافق على شروط الخدمة وسياسة الخصوصية الخاصة بنا.',
                style: TextStyle(
                  fontSize: 14,
                  color: AppColors.textSecondary,
                  height: 1.5,
                ),
                textAlign: TextAlign.center,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
