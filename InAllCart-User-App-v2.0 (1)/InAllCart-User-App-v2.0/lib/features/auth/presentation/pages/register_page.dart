import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/router/route_names.dart';
import '../../../../core/router/routes.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/widgets/global_app_bar.dart';
import '../../../../core/widgets/country_code_picker.dart';
import '../bloc/auth_bloc.dart';

class RegisterPage extends StatefulWidget {
  final String? referralCode;

  const RegisterPage({super.key, this.referralCode});

  @override
  State<RegisterPage> createState() => _RegisterPageState();
}

class _RegisterPageState extends State<RegisterPage> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _phoneController = TextEditingController();
  final _passwordController = TextEditingController();
  late final TextEditingController _referralCodeController;

  bool _obscurePassword = true;
  bool _acceptTerms = true;

  bool _phoneOtpEnabled = false;
  bool _emailOtpEnabled = false;
  bool _configLoaded = false;
  bool _isFirebaseProvider = false;
  int _otpLength = 6;
  int _resendCooldown = 60;

  // Tracks whether the user has actively submitted a form action.
  // Separate from AuthLoading so a stale bloc state doesn't freeze the UI.
  bool _isSubmitting = false;

  // Firebase and Twilio always send exactly 6-digit codes regardless of
  // the admin's auth_otp_length setting. The backend returns otp_length: 6
  // for these providers, but we also check is_firebase as a safety net.
  late Country _selectedCountry;

  int get _effectiveOtpLength => _isFirebaseProvider ? 6 : _otpLength;

  String get _fullPhone {
    final raw = _phoneController.text.trim();
    if (raw.startsWith('+')) return raw;
    return '${_selectedCountry.code}$raw';
  }

  @override
  void initState() {
    super.initState();
    _selectedCountry = detectUserCountry();
    _referralCodeController = TextEditingController(text: widget.referralCode);
    // If the singleton AuthBloc already has a loaded config, apply it immediately
    // so the page doesn't wait for a listener that will never fire.
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
    _nameController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    _passwordController.dispose();
    _referralCodeController.dispose();
    super.dispose();
  }

  String get _activeMethod {
    if (_phoneOtpEnabled) return 'phone';
    if (_emailOtpEnabled) return 'email_otp';
    return 'manual';
  }

  String get _fullName => _nameController.text.trim();

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: true,
      onPopInvokedWithResult: (didPop, result) {
        if (didPop) return;
        if (context.canPop()) {
          context.pop();
        } else {
          context.go(Routes.login);
        }
      },
      child: Scaffold(
        appBar: const GlobalAppBar(title: 'Sign Up'),
      body: BlocConsumer<AuthBloc, AuthState>(
        listener: (context, state) {
          if (state is Authenticated) {
            setState(() => _isSubmitting = false);
            context.go(Routes.home);
          } else if (state is AuthError) {
            setState(() => _isSubmitting = false);
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text(state.message), backgroundColor: AppColors.error),
            );
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
              context.pushNamed(RouteNames.verifyOtp, extra: {
                'identifier': state.identifier,
                'type': state.type,
                'isFirebase': true,
                'name': _fullName,
                'otpLength': _effectiveOtpLength,
                'resendCooldown': _resendCooldown,
                'referralCode': _referralCodeController.text.trim().isNotEmpty
                    ? _referralCodeController.text.trim()
                    : null,
              });
            } else {
              context.pushNamed(RouteNames.verifyOtp, extra: {
                'identifier': state.identifier,
                'type': state.type,
                'name': _fullName,
                'phone': _phoneController.text.trim().isNotEmpty
                    ? _phoneController.text.trim()
                    : null,
                'otpLength': _effectiveOtpLength,
                'resendCooldown': _resendCooldown,
                'referralCode': _referralCodeController.text.trim().isNotEmpty
                    ? _referralCodeController.text.trim()
                    : null,
              });
            }
          } else if (state is AuthConfigLoaded) {
            setState(() => _applyAuthConfig(state.config));
          } else if (state is AuthError && !_configLoaded) {
            setState(() {
              _phoneOtpEnabled = false;
              _emailOtpEnabled = false;
              _configLoaded = true;
            });
          }
        },
        builder: (context, state) {
          final isLoading = _isSubmitting;

          return SafeArea(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Create Account',
                    style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Sign up to get started',
                    style: TextStyle(fontSize: 16, color: Colors.grey[600]),
                  ),
                  const SizedBox(height: 32),
                  if (!_configLoaded)
                    const Center(child: CircularProgressIndicator())
                  else
                    Form(
                      key: _formKey,
                      child: _buildForm(isLoading),
                    ),
                  const SizedBox(height: 32),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        'Already have an account? ',
                        style: TextStyle(color: Colors.grey[600]),
                      ),
                      TextButton(
                        onPressed: isLoading ? null : () => context.go(Routes.login),
                        child: const Text('Sign In'),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          );
        },
      ),
    ),
  );
}

  Widget _buildForm(bool isLoading) {
    switch (_activeMethod) {
      case 'phone':
        return _buildPhoneOtpForm(isLoading);
      case 'email_otp':
        return _buildEmailOtpForm(isLoading);
      case 'manual':
      default:
        return _buildManualForm(isLoading);
    }
  }

  // ── Phone OTP signup ──────────────────────────────────────────────────────
  // Fields: Name, Phone → OTP screen
  Widget _buildPhoneOtpForm(bool isLoading) {
    return Column(
      children: [
        _nameFields(isLoading),
        const SizedBox(height: 16),
        _buildPhoneInput(isLoading),
        const SizedBox(height: 16),
        _referralField(isLoading),
        const SizedBox(height: 16),
        _termsRow(isLoading),
        const SizedBox(height: 24),
        _submitButton(
          isLoading: isLoading,
          label: 'Send Code',
          onPressed: _submitPhoneOtp,
          requireTerms: true,
        ),
      ],
    );
  }

  // ── Email OTP signup ──────────────────────────────────────────────────────
  // Fields: Name, Email, Phone → OTP screen
  Widget _buildEmailOtpForm(bool isLoading) {
    return Column(
      children: [
        _nameFields(isLoading),
        const SizedBox(height: 16),
        TextFormField(
          controller: _emailController,
          keyboardType: TextInputType.emailAddress,
          enabled: !isLoading,
          decoration: const InputDecoration(
            labelText: 'Email Address',
            prefixIcon: Icon(Icons.email_outlined),
          ),
          validator: (v) {
            if (v == null || v.isEmpty) return 'Enter your email';
            if (!v.contains('@')) return 'Enter a valid email';
            return null;
          },
        ),
        const SizedBox(height: 16),
        _buildPhoneInput(isLoading),
        const SizedBox(height: 16),
        _referralField(isLoading),
        const SizedBox(height: 16),
        _termsRow(isLoading),
        const SizedBox(height: 24),
        _submitButton(
          isLoading: isLoading,
          label: 'Send Code',
          onPressed: _submitEmailOtp,
          requireTerms: true,
        ),
      ],
    );
  }

  // ── Manual signup ─────────────────────────────────────────────────────────
  // Fields: Full Name, Email, Phone (optional), Password
  Widget _buildManualForm(bool isLoading) {
    return Column(
      children: [
        _nameFields(isLoading),
        const SizedBox(height: 16),
        TextFormField(
          controller: _emailController,
          keyboardType: TextInputType.emailAddress,
          enabled: !isLoading,
          decoration: const InputDecoration(
            labelText: 'Email',
            prefixIcon: Icon(Icons.email_outlined),
          ),
          validator: (v) {
            if (v == null || v.isEmpty) return 'Enter your email';
            if (!v.contains('@')) return 'Enter a valid email';
            return null;
          },
        ),
        const SizedBox(height: 16),
        _buildPhoneInput(isLoading, isOptional: true),
        const SizedBox(height: 16),
        TextFormField(
          controller: _passwordController,
          obscureText: _obscurePassword,
          enabled: !isLoading,
          decoration: InputDecoration(
            labelText: 'Password',
            prefixIcon: const Icon(Icons.lock_outlined),
            suffixIcon: IconButton(
              icon: Icon(_obscurePassword ? Icons.visibility_off : Icons.visibility),
              onPressed: () => setState(() => _obscurePassword = !_obscurePassword),
            ),
          ),
          validator: (v) {
            if (v == null || v.isEmpty) return 'Enter a password';
            if (v.length < 8) return 'Password must be at least 8 characters';
            return null;
          },
        ),
        const SizedBox(height: 16),
        _referralField(isLoading),
        const SizedBox(height: 16),
        _termsRow(isLoading),
        const SizedBox(height: 24),
        _submitButton(
          isLoading: isLoading,
          label: 'Create Account',
          onPressed: _submitManual,
          requireTerms: true,
        ),
      ],
    );
  }

  // ── Shared widgets ────────────────────────────────────────────────────────

  Widget _nameFields(bool isLoading) {
    return TextFormField(
      controller: _nameController,
      textCapitalization: TextCapitalization.words,
      enabled: !isLoading,
      decoration: const InputDecoration(
        labelText: 'Name',
        prefixIcon: Icon(Icons.person_outlined),
        hintText: 'Enter your full name',
      ),
      validator: (v) {
        if (v == null || v.isEmpty) return 'Enter your name';
        return null;
      },
    );
  }

  Widget _referralField(bool isLoading) {
    return TextFormField(
      controller: _referralCodeController,
      textCapitalization: TextCapitalization.characters,
      enabled: !isLoading,
      decoration: const InputDecoration(
        labelText: 'Referral Code (Optional)',
        prefixIcon: Icon(Icons.card_giftcard_outlined),
      ),
    );
  }

  Widget _termsRow(bool isLoading) {
    return Row(
      children: [
        Checkbox(
          value: _acceptTerms,
          onChanged: isLoading ? null : (v) => setState(() => _acceptTerms = v ?? false),
        ),
        Expanded(
          child: Text.rich(
            TextSpan(
              text: 'I agree to the ',
              style: TextStyle(color: Colors.grey[600]),
              children: [
                TextSpan(
                  text: 'Terms of Service',
                  style: TextStyle(color: AppColors.primary),
                ),
                const TextSpan(text: ' and '),
                TextSpan(
                  text: 'Privacy Policy',
                  style: TextStyle(color: AppColors.primary),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _submitButton({
    required bool isLoading,
    required String label,
    required VoidCallback onPressed,
    bool requireTerms = false,
  }) {
    final enabled = !isLoading && (!requireTerms || _acceptTerms);
    return SizedBox(
      width: double.infinity,
      height: 48,
      child: ElevatedButton(
        onPressed: enabled ? onPressed : null,
        child: isLoading
            ? const SizedBox(
                height: 20,
                width: 20,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                ),
              )
            : Text(label),
      ),
    );
  }

  Widget _buildPhoneInput(bool isLoading, {bool isOptional = false}) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE8E8F0), width: 1.5),
      ),
      child: Row(
        children: [
          // Country picker
          GestureDetector(
            onTap: isLoading
                ? null
                : () => showCountryPickerModal(
                      context,
                      selectedCountry: _selectedCountry,
                      onSelect: (c) => setState(() => _selectedCountry = c),
                    ),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 16),
              decoration: const BoxDecoration(
                border: Border(
                  right: BorderSide(color: Color(0xFFE8E8F0), width: 1.5),
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

          // Input field
          Expanded(
            child: TextFormField(
              controller: _phoneController,
              keyboardType: TextInputType.phone,
              enabled: !isLoading,
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w500,
                color: Color(0xFF0F0F1A),
              ),
              decoration: InputDecoration(
                hintText: 'Enter Correct Phone Number',
                hintStyle: TextStyle(
                  color: AppColors.textTertiary,
                  fontSize: 14,
                ),
                border: InputBorder.none,
                enabledBorder: InputBorder.none,
                focusedBorder: InputBorder.none,
                contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 16),
              ),
              validator: isOptional
                  ? null
                  : (v) {
                      if (v == null || v.isEmpty) return 'Enter your phone number';
                      return null;
                    },
            ),
          ),
        ],
      ),
    );
  }

  // ── Submit handlers ───────────────────────────────────────────────────────

  void _submitPhoneOtp() {
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

  void _submitManual() {
    if (_formKey.currentState!.validate()) {
      setState(() => _isSubmitting = true);
      context.read<AuthBloc>().add(RegisterEvent(
        name: _fullName,
        email: _emailController.text.trim(),
        password: _passwordController.text,
        phone: _phoneController.text.trim().isNotEmpty ? _fullPhone : null,
        referralCode: _referralCodeController.text.trim().isNotEmpty
            ? _referralCodeController.text.trim()
            : null,
      ));
    }
  }
}
