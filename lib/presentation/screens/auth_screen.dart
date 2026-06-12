import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../core/localization.dart';
import '../../core/theme.dart';
import '../../logic/auth/auth_cubit.dart';
import '../../logic/language/language_cubit.dart';
import '../widgets/theme_language_header.dart';
import 'role_selection_screen.dart';

class AuthScreen extends StatefulWidget {
  const AuthScreen({super.key});

  @override
  State<AuthScreen> createState() => _AuthScreenState();
}

class _AuthScreenState extends State<AuthScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _phoneController = TextEditingController();

  bool _isRegisterMode = false;
  bool _obscurePassword = true; // التحكم في رؤية كلمة المرور

  // قائمة الدول العربية الموسعة مع رموزها وأعلامها
  String _selectedCountryCode = "+218"; // الافتراضي ليبيا
  final List<Map<String, String>> _countries = [
    {"code": "+218", "name": "LY 🇱🇾"},
    {"code": "+20", "name": "EG 🇪🇬"},
    {"code": "+216", "name": "TN 🇹🇳"},
    {"code": "+212", "name": "MA 🇲🇦"},
    {"code": "+213", "name": "DZ 🇩🇿"},
    {"code": "+966", "name": "SA 🇸🇦"},
    {"code": "+971", "name": "AE 🇦🇪"},
    {"code": "+964", "name": "IQ 🇮🇶"},
    {"code": "+962", "name": "JO 🇯🇴"},
    {"code": "+965", "name": "KW 🇰🇼"},
    {"code": "+974", "name": "QA 🇶🇦"},
    {"code": "+961", "name": "LB 🇱🇧"},
    {"code": "+963", "name": "SY 🇸🇾"},
    {"code": "+968", "name": "OM 🇴🇲"},
    {"code": "+973", "name": "BH 🇧🇭"},
  ];

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    _phoneController.dispose();
    super.dispose();
  }

  // دالة الفحص الذكي لقوة كلمة المرور
  String? _validatePassword(String? value, String langCode) {
    if (value == null || value.isEmpty) {
      return langCode == 'ar' ? 'الرجاء إدخال كلمة المرور' : 'Please enter password';
    }
    if (value.length < 6) {
      return langCode == 'ar' ? 'كلمة المرور قصيرة جداً (6 خانات فما فوق)' : 'Password too short (min 6 characters)';
    }
    // فحص الحروف والأرقام معاً لقوة أكبر
    bool hasLetters = value.contains(RegExp(r'[a-zA-Z]'));
    bool hasDigits = value.contains(RegExp(r'[0-9]'));
    if (!hasLetters || !hasDigits) {
      return langCode == 'ar' ? 'كلمة المرور ضعيفة! يجب أن تحتوي على حروف وأرقام' : 'Weak password! Must include letters and numbers';
    }
    return null;
  }

  void _submitForm(String langCode) {
    if (_formKey.currentState!.validate()) {
      final fullPhoneNumber = _isRegisterMode ? "$_selectedCountryCode${_phoneController.text.trim()}" : "";

      if (_isRegisterMode) {
        context.read<AuthCubit>().register(
          email: _emailController.text.trim(),
          password: _passwordController.text,
          phone: fullPhoneNumber,
          langCode: langCode,
        );
      } else {
        context.read<AuthCubit>().login(
          _emailController.text.trim(),
          _passwordController.text,
          langCode,
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final langCode = context.watch<LanguageCubit>().state;

    return Scaffold(
      appBar: ThemeLanguageHeader(
        titleKey: _isRegisterMode ? 'register' : 'login',
        showBackButton: true,
      ),
      body: BlocConsumer<AuthCubit, AuthState>(
        listener: (context, state) {
          // الانتقال فوراً عند نجاح الـ Authenticated
          if (state is AuthAuthenticated) {
            Navigator.of(context).pushAndRemoveUntil(
              MaterialPageRoute(
                builder: (context) => const RoleSelectionScreen(),
              ),
                  (route) => false,
            );
          } else if (state is AuthError && state.message != null) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(state.message!),
                backgroundColor: AppColors.error,
              ),
            );
          }
        },
        builder: (context, state) {
          Map<String, String>? fieldErrors;
          bool isLoading = false;

          if (state is AuthError) {
            fieldErrors = state.fieldErrors;
          } else if (state is AuthLoading) {
            isLoading = true;
          }

          return SafeArea(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(24.0),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    const SizedBox(height: 16),
                    // شعار التطبيق
                    Center(
                      child: Container(
                        height: 100,
                        width: 100,
                        decoration: BoxDecoration(
                          color: AppColors.primary.withAlpha(25),
                          borderRadius: BorderRadius.circular(24),
                        ),
                        child: const Icon(
                          Icons.security_rounded,
                          color: AppColors.primary,
                          size: 48,
                        ),
                      ),
                    ),
                    const SizedBox(height: 36),

                    // حقل البريد الإلكتروني
                    TextFormField(
                      controller: _emailController,
                      keyboardType: TextInputType.emailAddress,
                      decoration: InputDecoration(
                        hintText: AppLocalization.translate('email', langCode),
                        errorText: fieldErrors?['email'],
                        prefixIcon: const Icon(Icons.email_outlined),
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(16)),
                      ),
                      validator: (value) {
                        if (value == null || value.trim().isEmpty) {
                          return langCode == 'ar' ? 'الرجاء إدخال البريد الإلكتروني' : 'Please enter email';
                        }
                        if (!RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$').hasMatch(value.trim())) {
                          return langCode == 'ar' ? 'صيغة البريد الإلكتروني غير صحيحة' : 'Invalid email format';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 16),

                    // حقل كلمة المرور مع العين السحرية وفحص القوة
                    TextFormField(
                      controller: _passwordController,
                      obscureText: _obscurePassword,
                      decoration: InputDecoration(
                        hintText: AppLocalization.translate('password', langCode),
                        errorText: fieldErrors?['password'],
                        prefixIcon: const Icon(Icons.lock_outline_rounded),
                        suffixIcon: IconButton(
                          icon: Icon(_obscurePassword ? Icons.visibility_off_outlined : Icons.visibility_outlined),
                          onPressed: () {
                            setState(() {
                              _obscurePassword = !_obscurePassword;
                            });
                          },
                        ),
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(16)),
                      ),
                      validator: (value) => _validatePassword(value, langCode),
                    ),
                    const SizedBox(height: 16),

                    // حقل الهاتف مع اختيار الدول العربية (يظهر فقط في التسجيل)
                    if (_isRegisterMode) ...[
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 12),
                            height: 56,
                            decoration: BoxDecoration(
                              border: Border.all(color: Colors.grey.shade400),
                              borderRadius: BorderRadius.circular(16),
                            ),
                            child: DropdownButtonHideUnderline(
                              child: DropdownButton<String>(
                                value: _selectedCountryCode,
                                items: _countries.map((country) {
                                  return DropdownMenuItem<String>(
                                    value: country['code'],
                                    child: Text("${country['name']} (${country['code']})"),
                                  );
                                }).toList(),
                                onChanged: (value) {
                                  if (value != null) {
                                    setState(() {
                                      _selectedCountryCode = value;
                                    });
                                  }
                                },
                              ),
                            ),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: TextFormField(
                              controller: _phoneController,
                              keyboardType: TextInputType.phone,
                              decoration: InputDecoration(
                                hintText: AppLocalization.translate('phone_number', langCode),
                                errorText: fieldErrors?['phone'],
                                prefixIcon: const Icon(Icons.phone_android_rounded),
                                border: OutlineInputBorder(borderRadius: BorderRadius.circular(16)),
                              ),
                              validator: (value) {
                                if (value == null || value.trim().isEmpty) {
                                  return langCode == 'ar' ? 'الرجاء إدخال رقم الهاتف' : 'Please enter phone number';
                                }
                                if (value.trim().length < 8) {
                                  return langCode == 'ar' ? 'رقم الهاتف قصير جداً' : 'Phone number is too short';
                                }
                                return null;
                              },
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 24),
                    ] else ...[
                      const SizedBox(height: 8),
                    ],

                    // زر الإجراء الرئيسي
                    SizedBox(
                      height: 56,
                      child: ElevatedButton(
                        onPressed: isLoading ? null : () => _submitForm(langCode),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.primary,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16),
                          ),
                        ),
                        child: isLoading
                            ? const CircularProgressIndicator(color: Colors.white)
                            : Text(
                          AppLocalization.translate(
                            _isRegisterMode ? 'register' : 'login',
                            langCode,
                          ),
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 20),

                    // تبديل الوضع بين دخول وإنشاء حساب
                    TextButton(
                      onPressed: () {
                        context.read<AuthCubit>().clearErrors();
                        _formKey.currentState?.reset();
                        setState(() {
                          _isRegisterMode = !_isRegisterMode;
                        });
                      },
                      child: Text(
                        AppLocalization.translate(
                          _isRegisterMode ? 'have_account' : 'dont_have_account',
                          langCode,
                        ),
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          color: AppColors.primary,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}
