import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/router/routes.dart';
import '../../../../core/theme/app_colors.dart';
import '../bloc/auth_bloc.dart';

class CompleteProfilePage extends StatefulWidget {
  final String? phone;

  const CompleteProfilePage({super.key, this.phone});

  @override
  State<CompleteProfilePage> createState() => _CompleteProfilePageState();
}

class _CompleteProfilePageState extends State<CompleteProfilePage>
    with SingleTickerProviderStateMixin {
  final _formKey = GlobalKey<FormState>();
  final _firstNameCtrl = TextEditingController();
  final _lastNameCtrl = TextEditingController();
  final _referralCtrl = TextEditingController();

  bool _isSubmitting = false;

  late AnimationController _fadeCtrl;
  late Animation<double> _fadeAnim;

  @override
  void initState() {
    super.initState();
    _fadeCtrl = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 500));
    _fadeAnim = CurvedAnimation(parent: _fadeCtrl, curve: Curves.easeOut);
    _fadeCtrl.forward();
  }

  @override
  void dispose() {
    _firstNameCtrl.dispose();
    _lastNameCtrl.dispose();
    _referralCtrl.dispose();
    _fadeCtrl.dispose();
    super.dispose();
  }

  String get _fullName =>
      '${_firstNameCtrl.text.trim()} ${_lastNameCtrl.text.trim()}'.trim();

  void _submit() {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _isSubmitting = true);
    context.read<AuthBloc>().add(UpdateProfileEvent(
      name: _fullName,
      // phone already verified — don't overwrite it
    ));
  }

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
        backgroundColor: const Color(0xFFF8F9FF),
      body: BlocConsumer<AuthBloc, AuthState>(
        listener: (context, state) {
          if (state is Authenticated) {
            context.go(Routes.home);
          } else if (state is AuthError) {
            setState(() => _isSubmitting = false);
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(state.message),
                backgroundColor: AppColors.error,
                behavior: SnackBarBehavior.floating,
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12)),
                margin: const EdgeInsets.all(16),
              ),
            );
          }
        },
        builder: (context, state) {
          final isLoading = _isSubmitting || state is AuthLoading;

          return SafeArea(
            child: FadeTransition(
              opacity: _fadeAnim,
              child: SingleChildScrollView(
                physics: const ClampingScrollPhysics(),
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 24),
                  child: Form(
                    key: _formKey,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const SizedBox(height: 48),

                        // Icon badge
                        Container(
                          width: 56,
                          height: 56,
                          decoration: BoxDecoration(
                            color: AppColors.primary.withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(16),
                          ),
                          child: Icon(
                            Icons.waving_hand_rounded,
                            color: AppColors.primary,
                            size: 28,
                          ),
                        ),

                        const SizedBox(height: 24),

                        const Text(
                          'What should we\ncall you?',
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
                          'You can always change this later',
                          style: TextStyle(
                            fontSize: 15,
                            color: AppColors.textSecondary,
                          ),
                        ),

                        const SizedBox(height: 40),

                        // First + Last name
                        Row(
                          children: [
                            Expanded(
                              child: _Field(
                                controller: _firstNameCtrl,
                                hint: 'First name',
                                icon: Icons.person_outline_rounded,
                                enabled: !isLoading,
                                autofocus: true,
                                textCapitalization: TextCapitalization.words,
                                validator: (v) => (v == null || v.trim().isEmpty)
                                    ? 'Required'
                                    : null,
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: _Field(
                                controller: _lastNameCtrl,
                                hint: 'Last name',
                                enabled: !isLoading,
                                textCapitalization: TextCapitalization.words,
                                validator: (v) => (v == null || v.trim().isEmpty)
                                    ? 'Required'
                                    : null,
                              ),
                            ),
                          ],
                        ),

                        const SizedBox(height: 14),

                        // Referral code (optional)
                        _Field(
                          controller: _referralCtrl,
                          hint: 'Referral code (optional)',
                          icon: Icons.card_giftcard_outlined,
                          enabled: !isLoading,
                          textCapitalization: TextCapitalization.characters,
                        ),

                        const SizedBox(height: 32),

                        // CTA
                        SizedBox(
                          width: double.infinity,
                          height: 56,
                          child: ElevatedButton(
                            onPressed: isLoading ? null : _submit,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: AppColors.primary,
                              foregroundColor: Colors.white,
                              disabledBackgroundColor:
                                  AppColors.primary.withValues(alpha: 0.6),
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
                                : const Row(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      Text(
                                        'Get Started',
                                        style: TextStyle(
                                          fontSize: 16,
                                          fontWeight: FontWeight.w700,
                                          letterSpacing: 0.2,
                                        ),
                                      ),
                                      SizedBox(width: 8),
                                      Icon(Icons.arrow_forward_rounded,
                                          size: 18),
                                    ],
                                  ),
                          ),
                        ),

                        const SizedBox(height: 16),

                        Center(
                          child: TextButton(
                            onPressed:
                                isLoading ? null : () => context.go(Routes.home),
                            style: TextButton.styleFrom(
                              foregroundColor: AppColors.textTertiary,
                            ),
                            child: const Text(
                              'Skip for now',
                              style: TextStyle(fontSize: 13),
                            ),
                          ),
                        ),

                        const SizedBox(height: 32),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          );
        },
      ),
    ),
  );
}
}

// ─── Input field ──────────────────────────────────────────────────────────────

class _Field extends StatelessWidget {
  final TextEditingController controller;
  final String hint;
  final IconData? icon;
  final bool enabled;
  final bool autofocus;
  final TextCapitalization textCapitalization;
  final String? Function(String?)? validator;

  const _Field({
    required this.controller,
    required this.hint,
    this.icon,
    this.enabled = true,
    this.autofocus = false,
    this.textCapitalization = TextCapitalization.none,
    this.validator,
  });

  @override
  Widget build(BuildContext context) {
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
        keyboardType: TextInputType.text,
        enabled: enabled,
        autofocus: autofocus,
        textCapitalization: textCapitalization,
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
          prefixIcon: icon != null
              ? Icon(icon, color: AppColors.textSecondary, size: 20)
              : null,
          border: InputBorder.none,
          enabledBorder: InputBorder.none,
          focusedBorder: InputBorder.none,
          errorBorder: InputBorder.none,
          focusedErrorBorder: InputBorder.none,
          contentPadding:
              const EdgeInsets.symmetric(horizontal: 16, vertical: 18),
          errorStyle: const TextStyle(fontSize: 11),
        ),
        validator: validator,
      ),
    );
  }
}


