import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/di/injection.dart';
import '../../../../core/services/storage_service.dart';
import '../../../popups/domain/services/popup_manager.dart';
import '../../../popups/presentation/widgets/popup_overlay_dialog.dart';
import '../../../../core/widgets/country_code_picker.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/router/routes.dart';
import '../../../../core/router/route_names.dart';
import '../../../app_config/presentation/bloc/app_config_bloc.dart';
import '../bloc/auth_bloc.dart';



class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> with SingleTickerProviderStateMixin {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _phoneController = TextEditingController();

  bool _obscurePassword = true;
  bool _phoneOtpEnabled = false;
  bool _emailOtpEnabled = false;
  bool _configLoaded = false;
  bool _isFirebaseProvider = false;
  int _otpLength = 6;
  int _resendCooldown = 60;
  bool _isSubmitting = false;

  late Country _selectedCountry;
  late AnimationController _fadeCtrl;
  late Animation<double> _fadeAnim;

  int get _effectiveOtpLength => _isFirebaseProvider ? 6 : _otpLength;

  @override
  void initState() {
    super.initState();
    _selectedCountry = detectUserCountry();
    _fadeCtrl = AnimationController(vsync: this, duration: const Duration(milliseconds: 500));
    _fadeAnim = CurvedAnimation(parent: _fadeCtrl, curve: Curves.easeOut);
    _fadeCtrl.forward();

    final currentState = context.read<AuthBloc>().state;
    if (currentState is AuthConfigLoaded) {
      _applyAuthConfig(currentState.config);
    } else {
      context.read<AuthBloc>().add(FetchAuthConfigEvent());
    }
  }

  void _applyAuthConfig(Map<String, dynamic> config) {
    _phoneOtpEnabled = config['phone_otp_enabled'] ?? false;
    _emailOtpEnabled = config['email_otp_enabled'] ?? false;
    _isFirebaseProvider = config['phone_otp_provider']?['is_firebase'] ?? false;
    _otpLength = config['otp_length'] ?? 6;
    _resendCooldown = config['resend_cooldown_seconds'] ?? 60;
    _configLoaded = true;
  }

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    _phoneController.dispose();
    _fadeCtrl.dispose();
    super.dispose();
  }

  String get _activeMethod {
    if (_phoneOtpEnabled) return 'phone';
    if (_emailOtpEnabled) return 'email_otp';
    return 'manual';
  }

  String get _fullPhone => '${_selectedCountry.code}${_phoneController.text.trim()}';

  void _triggerLoginPopup(BuildContext context, String targetRoute) async {
    final popupManager = getIt<PopupManager>();
    final storage = getIt<StorageService>();
    final userData = storage.getUser();
    final isVipUser = userData?['is_vip'] == true || userData?['vip_status'] == 'active';
    final lang = storage.getLanguage() ?? 'en';

    context.go(targetRoute);

    final popup = await popupManager.evaluateEligiblePopup(
      contextTrigger: PopupContextTrigger.onLogin,
      isUserLoggedIn: true,
      isVipUser: isVipUser,
      currentLanguage: lang,
    );

    if (popup != null && context.mounted) {
      await popupManager.recordPopupPresented(popup);
      if (context.mounted) {
        PopupOverlayDialog.show(context, popup);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;

    return PopScope(
      canPop: true,
      onPopInvokedWithResult: (didPop, result) {
        if (didPop) return;
        if (context.canPop()) {
          context.pop();
        } else {
          context.go(Routes.home);
        }
      },
      child: Scaffold(
        backgroundColor: const Color(0xFFF8F9FF),
      body: BlocConsumer<AuthBloc, AuthState>(
        listener: (context, state) {
          if (state is Authenticated) {
            setState(() => _isSubmitting = false);
            final redirect = GoRouterState.of(context).uri.queryParameters['redirect'];
            _triggerLoginPopup(context, redirect ?? Routes.home);
          } else if (state is AuthError) {
            setState(() => _isSubmitting = false);
            _showSnack(state.message, isError: true);
            if (!_configLoaded) {
              setState(() {
                _phoneOtpEnabled = false;
                _emailOtpEnabled = false;
                _configLoaded = true;
              });
            }
          } else if (state is OtpSent) {
            setState(() => _isSubmitting = false);
            if (state.data['is_firebase'] == true) {
              _startFirebaseVerification(context, state.identifier);
            } else {
              context.pushNamed(RouteNames.verifyOtp, extra: {
                'identifier': state.identifier,
                'type': state.type,
                'otpLength': _effectiveOtpLength,
                'resendCooldown': _resendCooldown,
              });
            }
          } else if (state is AuthConfigLoaded) {
            setState(() => _applyAuthConfig(state.config));
          }
        },
        builder: (context, state) {
          final isLoading = _isSubmitting;

          return Stack(
            children: [
              // ── Background blobs ──────────────────────────────────────
              Positioned(
                top: -80,
                right: -60,
                child: Container(
                  width: 260,
                  height: 260,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: AppColors.primary.withValues(alpha: 0.08),
                  ),
                ),
              ),
              Positioned(
                bottom: size.height * 0.25,
                left: -80,
                child: Container(
                  width: 200,
                  height: 200,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: AppColors.secondary.withValues(alpha: 0.06),
                  ),
                ),
              ),

              SafeArea(
                child: FadeTransition(
                  opacity: _fadeAnim,
                  child: SingleChildScrollView(
                    physics: const ClampingScrollPhysics(),
                    child: ConstrainedBox(
                      constraints: BoxConstraints(minHeight: size.height - MediaQuery.of(context).padding.top),
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 24),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const SizedBox(height: 24),

                            // ── Logo + brand ──────────────────────────
                            Image.asset(
                              'assets/images/applogo.png',
                              height: 44,
                              fit: BoxFit.contain,
                            ),

                            const SizedBox(height: 40),

                            // ── Headline ──────────────────────────────
                            if (_activeMethod == 'phone') ...[
                              const Text(
                                'Enter your\nphone number',
                                style: TextStyle(
                                  fontSize: 32,
                                  fontWeight: FontWeight.w800,
                                  color: Color(0xFF0F0F1A),
                                  height: 1.15,
                                  letterSpacing: -0.8,
                                ),
                              ),
                              const SizedBox(height: 10),
                              Text(
                                "We'll send you a verification code",
                                style: TextStyle(
                                  fontSize: 15,
                                  color: AppColors.textSecondary,
                                  fontWeight: FontWeight.w400,
                                ),
                              ),
                            ] else if (_activeMethod == 'email_otp') ...[
                              const Text(
                                'Enter your\nemail address',
                                style: TextStyle(
                                  fontSize: 32,
                                  fontWeight: FontWeight.w800,
                                  color: Color(0xFF0F0F1A),
                                  height: 1.15,
                                  letterSpacing: -0.8,
                                ),
                              ),
                              const SizedBox(height: 10),
                              Text(
                                "We'll send you a one-time code",
                                style: TextStyle(
                                  fontSize: 15,
                                  color: AppColors.textSecondary,
                                ),
                              ),
                            ] else ...[
                              const Text(
                                'Welcome\nback 👋',
                                style: TextStyle(
                                  fontSize: 32,
                                  fontWeight: FontWeight.w800,
                                  color: Color(0xFF0F0F1A),
                                  height: 1.15,
                                  letterSpacing: -0.8,
                                ),
                              ),
                              const SizedBox(height: 10),
                              Text(
                                'Sign in to continue',
                                style: TextStyle(
                                  fontSize: 15,
                                  color: AppColors.textSecondary,
                                ),
                              ),
                            ],

                            const SizedBox(height: 40),

                            // ── Form ──────────────────────────────────
                            if (!_configLoaded)
                              const Center(
                                child: Padding(
                                  padding: EdgeInsets.symmetric(vertical: 40),
                                  child: CircularProgressIndicator(strokeWidth: 2),
                                ),
                              )
                            else
                              Form(
                                key: _formKey,
                                child: _buildForm(isLoading),
                              ),

                            const SizedBox(height: 32),

                            // ── Footer ────────────────────────────────
                            Center(
                              child: Wrap(
                                alignment: WrapAlignment.center,
                                crossAxisAlignment: WrapCrossAlignment.center,
                                children: [
                                  Text(
                                    "New here? ",
                                    style: TextStyle(
                                      color: AppColors.textSecondary,
                                      fontSize: 14,
                                    ),
                                  ),
                                  GestureDetector(
                                    onTap: isLoading ? null : () => context.push(Routes.register),
                                    child: Text(
                                      'Create account',
                                      style: TextStyle(
                                        color: AppColors.primary,
                                        fontSize: 14,
                                        fontWeight: FontWeight.w700,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(height: 8),
                            Center(
                              child: TextButton(
                                onPressed: isLoading ? null : () => context.go(Routes.home),
                                style: TextButton.styleFrom(
                                  foregroundColor: AppColors.textTertiary,
                                ),
                                child: const Text(
                                  'Skip for now',
                                  style: TextStyle(fontSize: 13),
                                ),
                              ),
                            ),
                            const SizedBox(height: 24),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ],
          );
        },
      ),
    ),
  );
}

  // ── Form switcher ────────────────────────────────────────────────────────────
  Widget _buildForm(bool isLoading) {
    switch (_activeMethod) {
      case 'phone':
        return _buildPhoneForm(isLoading);
      case 'email_otp':
        return _buildEmailOtpForm(isLoading);
      default:
        return _buildManualForm(isLoading);
    }
  }

  // ── Phone form ───────────────────────────────────────────────────────────────
  Widget _buildPhoneForm(bool isLoading) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Country + number row
        Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: const Color(0xFFE8E8F0), width: 1.5),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.04),
                blurRadius: 16,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Row(
            children: [
              // Country picker
              GestureDetector(
                onTap: isLoading ? null : () => _showCountryPicker(),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 18),
                  decoration: BoxDecoration(
                    border: Border(
                      right: BorderSide(color: const Color(0xFFE8E8F0), width: 1.5),
                    ),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        _selectedCountry.flag,
                        style: const TextStyle(fontSize: 22),
                      ),
                      const SizedBox(width: 6),
                      Text(
                        _selectedCountry.code,
                        style: const TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w600,
                          color: Color(0xFF0F0F1A),
                        ),
                      ),
                      const SizedBox(width: 4),
                      Icon(
                        Icons.keyboard_arrow_down_rounded,
                        size: 18,
                        color: AppColors.textSecondary,
                      ),
                    ],
                  ),
                ),
              ),

              // Phone number input
              Expanded(
                child: TextFormField(
                  controller: _phoneController,
                  keyboardType: TextInputType.phone,
                  enabled: !isLoading,
                  inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                  style: const TextStyle(
                    fontSize: 17,
                    fontWeight: FontWeight.w500,
                    color: Color(0xFF0F0F1A),
                    letterSpacing: 0.5,
                  ),
                  decoration: InputDecoration(
                    hintText: 'Enter Correct Phone Number',
                    hintStyle: TextStyle(
                      color: AppColors.textTertiary,
                      fontSize: 15,
                      fontWeight: FontWeight.w400,
                    ),
                    border: InputBorder.none,
                    contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 18),
                  ),
                  validator: (v) {
                    if (v == null || v.isEmpty) return 'Enter your phone number';
                    if (v.length < 6) return 'Enter a valid phone number';
                    return null;
                  },
                ),
              ),
            ],
          ),
        ),

        const SizedBox(height: 12),
        Padding(
          padding: const EdgeInsets.only(left: 4),
          child: Text(
            'Enter Correct Phone Number',
            style: TextStyle(
              fontSize: 12,
              color: AppColors.textTertiary,
            ),
          ),
        ),

        const SizedBox(height: 24),
        _buildPrimaryButton(isLoading, 'Continue', _submitPhone),
      ],
    );
  }

  // ── Email OTP form ───────────────────────────────────────────────────────────
  Widget _buildEmailOtpForm(bool isLoading) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildInputField(
          controller: _emailController,
          hint: 'Email address',
          icon: Icons.mail_outline_rounded,
          keyboardType: TextInputType.emailAddress,
          enabled: !isLoading,
          validator: (v) {
            if (v == null || v.isEmpty) return 'Enter your email';
            if (!v.contains('@')) return 'Enter a valid email';
            return null;
          },
        ),
        const SizedBox(height: 28),
        _buildPrimaryButton(isLoading, 'Continue', _submitEmailOtp),
      ],
    );
  }

  // ── Manual form ──────────────────────────────────────────────────────────────
  Widget _buildManualForm(bool isLoading) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildInputField(
          controller: _emailController,
          hint: 'Email address',
          icon: Icons.mail_outline_rounded,
          keyboardType: TextInputType.emailAddress,
          enabled: !isLoading,
          validator: (v) {
            if (v == null || v.isEmpty) return 'Enter your email';
            if (!v.contains('@')) return 'Enter a valid email';
            return null;
          },
        ),
        const SizedBox(height: 14),
        _buildInputField(
          controller: _passwordController,
          hint: 'Password',
          icon: Icons.lock_outline_rounded,
          obscure: _obscurePassword,
          enabled: !isLoading,
          suffixIcon: IconButton(
            icon: Icon(
              _obscurePassword ? Icons.visibility_off_outlined : Icons.visibility_outlined,
              color: AppColors.textSecondary,
              size: 20,
            ),
            onPressed: () => setState(() => _obscurePassword = !_obscurePassword),
          ),
          validator: (v) {
            if (v == null || v.isEmpty) return 'Enter your password';
            return null;
          },
        ),
        const SizedBox(height: 28),
        _buildPrimaryButton(isLoading, 'Sign In', _submitManual),
      ],
    );
  }

  // ── Shared input field ───────────────────────────────────────────────────────
  Widget _buildInputField({
    required TextEditingController controller,
    required String hint,
    required IconData icon,
    TextInputType keyboardType = TextInputType.text,
    bool enabled = true,
    bool obscure = false,
    Widget? suffixIcon,
    String? Function(String?)? validator,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE8E8F0), width: 1.5),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 16,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: TextFormField(
        controller: controller,
        keyboardType: keyboardType,
        obscureText: obscure,
        enabled: enabled,
        style: const TextStyle(
          fontSize: 15,
          fontWeight: FontWeight.w500,
          color: Color(0xFF0F0F1A),
        ),
        decoration: InputDecoration(
          hintText: hint,
          hintStyle: TextStyle(
            color: AppColors.textTertiary,
            fontSize: 15,
            fontWeight: FontWeight.w400,
          ),
          prefixIcon: Icon(icon, color: AppColors.textSecondary, size: 20),
          suffixIcon: suffixIcon,
          border: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 18),
        ),
        validator: validator,
      ),
    );
  }

  // ── Primary CTA button ───────────────────────────────────────────────────────
  Widget _buildPrimaryButton(bool isLoading, String label, VoidCallback onTap) {
    return SizedBox(
      width: double.infinity,
      height: 56,
      child: ElevatedButton(
        onPressed: isLoading ? null : onTap,
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.primary,
          foregroundColor: Colors.white,
          disabledBackgroundColor: AppColors.primary.withValues(alpha: 0.6),
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
        ),
        child: isLoading
            ? const SizedBox(
                width: 22,
                height: 22,
                child: CircularProgressIndicator(
                  strokeWidth: 2.5,
                  color: Colors.white,
                ),
              )
            : Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    label,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                      letterSpacing: 0.2,
                    ),
                  ),
                  const SizedBox(width: 8),
                  const Icon(Icons.arrow_forward_rounded, size: 18),
                ],
              ),
      ),
    );
  }

  // ── Country picker bottom sheet ──────────────────────────────────────────────
  void _showCountryPicker() {
    showCountryPickerModal(
      context,
      selectedCountry: _selectedCountry,
      onSelect: (c) => setState(() => _selectedCountry = c),
    );
  }

  // ── Helpers ──────────────────────────────────────────────────────────────────
  void _showSnack(String msg, {bool isError = false}) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(msg),
        backgroundColor: isError ? AppColors.error : AppColors.success,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        margin: const EdgeInsets.all(16),
      ),
    );
  }

  void _submitManual() {
    if (_formKey.currentState!.validate()) {
      setState(() => _isSubmitting = true);
      context.read<AuthBloc>().add(LoginEvent(
        email: _emailController.text.trim(),
        password: _passwordController.text,
      ));
    }
  }

  void _submitPhone() {
    if (_formKey.currentState!.validate()) {
      setState(() => _isSubmitting = true);
      context.read<AuthBloc>().add(SendPhoneOtpEvent(_fullPhone));
    }
  }

  void _submitEmailOtp() {
    if (_formKey.currentState!.validate()) {
      setState(() => _isSubmitting = true);
      context.read<AuthBloc>().add(SendEmailOtpEvent(_emailController.text.trim()));
    }
  }

  Future<void> _startFirebaseVerification(BuildContext context, String phoneNumber) async {
    final configState = context.read<AppConfigBloc>().state;
    final isDemoMode = configState is AppConfigLoaded && configState.config.isDemoMode;

    // In DEMO_MODE or fallback, bypass Firebase SMS billing check and go directly to OTP screen
    if (isDemoMode) {
      if (mounted) {
        context.pushNamed(RouteNames.verifyOtp, extra: {
          'identifier': phoneNumber,
          'type': 'phone',
          'isFirebase': false,
          'otpLength': _otpLength,
          'resendCooldown': _resendCooldown,
        });
      }
      return;
    }

    try {
      await FirebaseAuth.instance.verifyPhoneNumber(
        phoneNumber: phoneNumber,
        verificationCompleted: (PhoneAuthCredential credential) async {
          try {
            final userCredential = await FirebaseAuth.instance.signInWithCredential(credential);
            final idToken = await userCredential.user?.getIdToken();
            if (idToken != null && context.mounted) {
              context.read<AuthBloc>().add(VerifyFirebaseTokenEvent(token: idToken, phone: phoneNumber));
            }
          } catch (e) {
            if (mounted) _showSnack('Auto-verification failed: $e', isError: true);
          }
        },
        verificationFailed: (FirebaseAuthException e) {
          debugPrint('Firebase Auth Error: ${e.code} - ${e.message}');
          // If billing is not enabled or quota exceeded, fall back to standard OTP screen
          if (mounted) {
            context.pushNamed(RouteNames.verifyOtp, extra: {
              'identifier': phoneNumber,
              'type': 'phone',
              'isFirebase': false,
              'otpLength': _otpLength,
              'resendCooldown': _resendCooldown,
            });
          }
        },
        codeSent: (String verificationId, int? resendToken) {
          if (mounted) {
            context.pushNamed(RouteNames.verifyOtp, extra: {
              'identifier': phoneNumber,
              'type': 'phone',
              'isFirebase': true,
              'verificationId': verificationId,
              'otpLength': _effectiveOtpLength,
              'resendCooldown': _resendCooldown,
            });
          }
        },
        codeAutoRetrievalTimeout: (_) {},
      );
    } catch (e) {
      if (mounted) {
        context.pushNamed(RouteNames.verifyOtp, extra: {
          'identifier': phoneNumber,
          'type': 'phone',
          'isFirebase': false,
          'otpLength': _otpLength,
          'resendCooldown': _resendCooldown,
        });
      }
    }
  }
}
