import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../../../../core/router/routes.dart';
import '../../../../core/router/route_names.dart';
import '../../../../core/theme/app_colors.dart';
import '../bloc/auth_bloc.dart';

class OtpVerificationPage extends StatefulWidget {
  final String identifier;
  final String type;
  final String? name;
  final String? phone;
  final String? password;
  final String? referralCode;
  final bool isFirebase;
  final String? verificationId;
  final int otpLength;
  final int resendCooldown;

  const OtpVerificationPage({
    super.key,
    required this.identifier,
    required this.type,
    this.name,
    this.phone,
    this.password,
    this.referralCode,
    this.isFirebase = false,
    this.verificationId,
    this.otpLength = 6,
    this.resendCooldown = 60,
  });

  @override
  State<OtpVerificationPage> createState() => _OtpVerificationPageState();
}

class _OtpVerificationPageState extends State<OtpVerificationPage>
    with TickerProviderStateMixin {
  // Single controller for the hidden text field
  final _textController = TextEditingController();
  final _focusNode = FocusNode();

  Timer? _timer;
  int _secondsRemaining = 60;
  bool _canResend = false;
  bool _isVerifying = false;

  late AnimationController _shakeCtrl;
  late AnimationController _fadeCtrl;
  late Animation<double> _fadeAnim;

  @override
  void initState() {
    super.initState();

    _shakeCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 400),
    );
    _fadeCtrl = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 500));
    _fadeAnim = CurvedAnimation(parent: _fadeCtrl, curve: Curves.easeOut);
    _fadeCtrl.forward();

    _focusNode.addListener(() {
      if (mounted) setState(() {});
    });

    _textController.addListener(() {
      if (mounted) setState(() {});
    });

    _startTimer();

    WidgetsBinding.instance.addPostFrameCallback((_) {
      _focusNode.requestFocus();
    });
  }

  @override
  void dispose() {
    _textController.dispose();
    _focusNode.dispose();
    _timer?.cancel();
    _shakeCtrl.dispose();
    _fadeCtrl.dispose();
    super.dispose();
  }

  void _startTimer() {
    setState(() {
      _secondsRemaining = widget.resendCooldown;
      _canResend = false;
    });
    _timer?.cancel();
    _timer = Timer.periodic(const Duration(seconds: 1), (t) {
      if (!mounted) return;
      if (_secondsRemaining > 0) {
        setState(() => _secondsRemaining--);
      } else {
        setState(() => _canResend = true);
        t.cancel();
      }
    });
  }

  String get _code => _textController.text;
  bool get _isComplete => _code.length == widget.otpLength;

  void _onChanged(String value) {
    // Clamp to otpLength
    if (value.length > widget.otpLength) {
      _textController.text = value.substring(0, widget.otpLength);
      _textController.selection = TextSelection.collapsed(
          offset: widget.otpLength);
    }
    setState(() {});
    if (_textController.text.length == widget.otpLength) {
      _focusNode.unfocus();
      _verifyOtp();
    }
  }

  void _shake() => _shakeCtrl.forward(from: 0);

  void _clearCode() {
    _textController.clear();
    _focusNode.requestFocus();
  }

  Future<void> _verifyOtp() async {
    final code = _code;
    if (code.length < widget.otpLength) return;
    setState(() => _isVerifying = true);

    if (widget.isFirebase) {
      if (widget.verificationId == null) {
        _showError('Missing verification ID');
        setState(() => _isVerifying = false);
        return;
      }
      try {
        final credential = PhoneAuthProvider.credential(
          verificationId: widget.verificationId!,
          smsCode: code,
        );
        final uc = await FirebaseAuth.instance.signInWithCredential(credential);
        final idToken = await uc.user?.getIdToken();
        if (idToken != null && mounted) {
          context.read<AuthBloc>().add(VerifyFirebaseTokenEvent(
            token: idToken,
            phone: widget.identifier,
            name: widget.name,
            referralCode: widget.referralCode,
          ));
        }
      } on FirebaseAuthException catch (e) {
        if (mounted) {
          _shake();
          _clearCode();
          _showError(e.message ?? 'Invalid code. Try again.');
          setState(() => _isVerifying = false);
        }
      }
      return;
    }

    if (widget.type == 'phone') {
      context.read<AuthBloc>().add(VerifyPhoneOtpEvent(
        phone: widget.identifier,
        code: code,
        name: widget.name,
        referralCode: widget.referralCode,
      ));
    } else {
      context.read<AuthBloc>().add(VerifyEmailOtpEvent(
        email: widget.identifier,
        code: code,
        name: widget.name,
        phone: widget.phone,
        password: widget.password,
        referralCode: widget.referralCode,
      ));
    }
  }

  void _resendOtp() {
    if (!_canResend) return;
    _clearCode();
    if (widget.type == 'phone') {
      context.read<AuthBloc>().add(SendPhoneOtpEvent(widget.identifier));
    } else {
      context.read<AuthBloc>().add(SendEmailOtpEvent(widget.identifier));
    }
    _startTimer();
  }

  void _showError(String msg) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(msg),
        backgroundColor: AppColors.error,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        margin: const EdgeInsets.all(16),
      ),
    );
  }

  String get _maskedIdentifier {
    final id = widget.identifier;
    if (widget.type == 'phone' && id.length > 5) {
      final visible = id.substring(id.length - 4);
      final prefix = id.length > 6 ? id.substring(0, 3) : id.substring(0, 1);
      return '$prefix ••••• $visible';
    }
    if (id.contains('@')) {
      final parts = id.split('@');
      final n = parts[0];
      final masked = n.length > 2
          ? '${n.substring(0, 2)}${'•' * (n.length - 2)}'
          : n;
      return '$masked@${parts[1]}';
    }
    return id;
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
        backgroundColor: Colors.white,
      body: BlocConsumer<AuthBloc, AuthState>(
        listener: (context, state) {
          if (state is Authenticated) {
            context.go(Routes.home);
          } else if (state is NewUserAuthenticated) {
            // New user — go to profile completion
            context.pushReplacementNamed(
              RouteNames.completeProfile,
              extra: {
                'phone': state.phone ?? widget.identifier,
              },
            );
          } else if (state is AuthError) {
            _shake();
            _clearCode();
            _showError(state.message);
            setState(() => _isVerifying = false);
          } else if (state is OtpSent) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: const Text('Code resent successfully'),
                backgroundColor: AppColors.success,
                behavior: SnackBarBehavior.floating,
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12)),
                margin: const EdgeInsets.all(16),
              ),
            );
          }
        },
        builder: (context, state) {
          final isLoading = state is AuthLoading || _isVerifying;

          return SafeArea(
            child: FadeTransition(
              opacity: _fadeAnim,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Back button
                  Padding(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    child: IconButton(
                      onPressed: () => context.pop(),
                      icon: const Icon(Icons.arrow_back_ios_new_rounded,
                          size: 20),
                      color: const Color(0xFF0F0F1A),
                    ),
                  ),

                  Expanded(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 24),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const SizedBox(height: 16),

                          // Headline
                          const Text(
                            'Enter OTP',
                            style: TextStyle(
                              fontSize: 32,
                              fontWeight: FontWeight.w800,
                              color: Color(0xFF0F0F1A),
                              letterSpacing: -0.8,
                              height: 1.1,
                            ),
                          ),
                          const SizedBox(height: 10),
                          RichText(
                            text: TextSpan(
                              style: TextStyle(
                                fontSize: 15,
                                color: AppColors.textSecondary,
                                height: 1.4,
                              ),
                              children: [
                                const TextSpan(text: 'Sent to '),
                                TextSpan(
                                  text: _maskedIdentifier,
                                  style: const TextStyle(
                                    fontWeight: FontWeight.w700,
                                    color: Color(0xFF0F0F1A),
                                  ),
                                ),
                              ],
                            ),
                          ),

                          const SizedBox(height: 16),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                            decoration: BoxDecoration(
                              color: const Color(0xFFEFF6FF),
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(color: const Color(0xFFBFDBFE)),
                            ),
                            child: Row(
                              children: const [
                                Icon(Icons.info_outline_rounded, size: 20, color: Color(0xFF2563EB)),
                                SizedBox(width: 10),
                                Expanded(
                                  child: Text(
                                    'Demo Mode Active: Enter OTP code 123456 to verify.',
                                    style: TextStyle(
                                      fontSize: 13,
                                      fontWeight: FontWeight.w700,
                                      color: Color(0xFF1E40AF),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),

                          const SizedBox(height: 32),

                          // OTP boxes — tap anywhere to focus hidden field
                          GestureDetector(
                            onTap: () => _focusNode.requestFocus(),
                            child: AnimatedBuilder(
                              animation: _shakeCtrl,
                              builder: (_, child) {
                                final dx = _shakeCtrl.isAnimating
                                    ? 8 *
                                        (0.5 -
                                                (_shakeCtrl.value - 0.5)
                                                    .abs()) *
                                            2
                                    : 0.0;
                                return Transform.translate(
                                  offset: Offset(dx * 3, 0),
                                  child: child,
                                );
                              },
                              child: _OtpBoxes(
                                code: _code,
                                length: widget.otpLength,
                                isFocused: _focusNode.hasFocus,
                              ),
                            ),
                          ),

                          // Hidden text field that captures input
                          SizedBox(
                            width: 0,
                            height: 0,
                            child: TextField(
                              controller: _textController,
                              focusNode: _focusNode,
                              enabled: !isLoading,
                              keyboardType: TextInputType.number,
                              maxLength: widget.otpLength,
                              inputFormatters: [
                                FilteringTextInputFormatter.digitsOnly,
                                LengthLimitingTextInputFormatter(
                                    widget.otpLength),
                              ],
                              decoration: const InputDecoration(
                                border: InputBorder.none,
                                counterText: '',
                              ),
                              onChanged: _onChanged,
                            ),
                          ),

                          const SizedBox(height: 40),

                          // Resend
                          Wrap(
                            children: [
                              Text(
                                "Didn't receive the code? ",
                                style: TextStyle(
                                  fontSize: 14,
                                  color: AppColors.textSecondary,
                                ),
                              ),
                              GestureDetector(
                                onTap: _canResend ? _resendOtp : null,
                                child: Text(
                                  _canResend
                                      ? 'Resend'
                                      : 'Resend in ${_secondsRemaining}s',
                                  style: TextStyle(
                                    fontSize: 14,
                                    fontWeight: FontWeight.w700,
                                    color: _canResend
                                        ? AppColors.primary
                                        : AppColors.textTertiary,
                                  ),
                                ),
                              ),
                            ],
                          ),

                          const Spacer(),

                          // Verify button
                          AnimatedOpacity(
                            opacity: _isComplete ? 1.0 : 0.4,
                            duration: const Duration(milliseconds: 200),
                            child: SizedBox(
                              width: double.infinity,
                              height: 56,
                              child: ElevatedButton(
                                onPressed: isLoading
                                    ? null
                                    : (_isComplete ? _verifyOtp : null),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: AppColors.primary,
                                  foregroundColor: Colors.white,
                                  disabledBackgroundColor: AppColors.primary,
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
                                    : const Text(
                                        'Verify & Continue',
                                        style: TextStyle(
                                          fontSize: 16,
                                          fontWeight: FontWeight.w700,
                                          letterSpacing: 0.2,
                                        ),
                                      ),
                              ),
                            ),
                          ),

                          const SizedBox(height: 24),
                        ],
                      ),
                    ),
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
}

// ─── Pure visual OTP boxes — no TextField inside ─────────────────────────────

class _OtpBoxes extends StatelessWidget {
  final String code;
  final int length;
  final bool isFocused;

  const _OtpBoxes({
    required this.code,
    required this.length,
    required this.isFocused,
  });

  @override
  Widget build(BuildContext context) {
    // Active box = next empty slot (or last if complete)
    final activeIndex = code.length < length ? code.length : length - 1;

    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: List.generate(length, (i) {
        final char = i < code.length ? code[i] : '';
        final isFilled = char.isNotEmpty;
        final isActive = isFocused && i == activeIndex;

        return AnimatedContainer(
          duration: const Duration(milliseconds: 150),
          width: (MediaQuery.of(context).size.width - 48 - (12.0 * (length - 1))) / length,
          height: 60,
          decoration: BoxDecoration(
            color: isFilled
                ? AppColors.primary.withValues(alpha: 0.06)
                : const Color(0xFFF5F5FA),
            borderRadius: BorderRadius.circular(14),
            border: Border.all(
              color: isActive
                  ? AppColors.primary
                  : isFilled
                      ? AppColors.primary.withValues(alpha: 0.5)
                      : Colors.transparent,
              width: isActive ? 2 : 1.5,
            ),
          ),
          alignment: Alignment.center,
          child: isFilled
              ? Text(
                  char,
                  style: TextStyle(
                    fontSize: 26,
                    fontWeight: FontWeight.w800,
                    color: AppColors.primary,
                    height: 1,
                  ),
                )
              : isActive
                  ? _Cursor()
                  : const SizedBox.shrink(),
        );
      }),
    );
  }
}

// Blinking cursor for the active empty box
class _Cursor extends StatefulWidget {
  @override
  State<_Cursor> createState() => _CursorState();
}

class _CursorState extends State<_Cursor> with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return FadeTransition(
      opacity: _ctrl,
      child: Container(
        width: 2,
        height: 28,
        decoration: BoxDecoration(
          color: AppColors.primary,
          borderRadius: BorderRadius.circular(1),
        ),
      ),
    );
  }
}
