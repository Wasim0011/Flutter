import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../controllers/otp_verification_controller.dart';
import '../controllers/phone_entry_controller.dart';

/// Second step of Samvaad's sign-in flow: enter the OTP sent to
/// [phoneNumber], with a resend option gated by a cooldown timer.
///
/// Accessibility notes:
/// - The OTP field uses `TextInputType.number` with a 6-digit limit
///   and `autofillHints: [AutofillHints.oneTimeCode]`, which lets
///   Android/iOS offer auto-fill from an SMS the OS itself detected —
///   reducing manual entry for everyone, not just as an accessibility
///   nicety.
/// - Error/status text uses `Semantics(liveRegion: true)`, consistent
///   with PhoneEntryPage.
class OtpVerificationPage extends ConsumerStatefulWidget {
  const OtpVerificationPage({
    required this.verificationId,
    required this.phoneNumber,
    super.key,
  });

  final String verificationId;
  final String phoneNumber;

  @override
  ConsumerState<OtpVerificationPage> createState() => _OtpVerificationPageState();
}

class _OtpVerificationPageState extends ConsumerState<OtpVerificationPage> {
  final _formKey = GlobalKey<FormState>();
  final _otpController = TextEditingController();
  late String _verificationId;

  @override
  void initState() {
    super.initState();
    _verificationId = widget.verificationId;
  }

  @override
  void dispose() {
    _otpController.dispose();
    super.dispose();
  }

  String? _validateOtp(String? value) {
    final String input = (value ?? '').trim();
    if (input.isEmpty) return 'Enter the code';
    if (!RegExp(r'^\d{6}$').hasMatch(input)) return 'Enter the 6-digit code';
    return null;
  }

  void _submit() {
    if (!(_formKey.currentState?.validate() ?? false)) return;
    ref.read(otpVerificationControllerProvider.notifier).submit(
      verificationId: _verificationId,
      otp: _otpController.text.trim(),
    );
  }

  Future<void> _resend() async {
    final phoneController = ref.read(phoneEntryControllerProvider.notifier);
    await phoneController.submit(widget.phoneNumber);

    final phoneState = ref.read(phoneEntryControllerProvider);
    if (phoneState is PhoneEntrySent) {
      setState(() => _verificationId = phoneState.verificationId);
      ref.read(resendCooldownControllerProvider.notifier).restart();
      phoneController.reset();
    }
    // If resend fails, PhoneEntryController's own failed state isn't
    // surfaced on this screen — a known limitation, see Future
    // improvements. The cooldown simply won't restart, so the user
    // can try Resend again once it expires.
  }

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    final OtpVerificationState state = ref.watch(otpVerificationControllerProvider);
    final int secondsRemaining = ref.watch(resendCooldownControllerProvider);
    final bool isSubmitting = state is OtpVerificationSubmitting;
    final String? errorMessage = state is OtpVerificationFailed ? state.message : null;

    return Scaffold(
      appBar: AppBar(title: const Text('Verify your number')),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              mainAxisAlignment: MainAxisAlignment.center,
              children: <Widget>[
                Text(
                  'Enter the code',
                  style: theme.textTheme.headlineMedium,
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 8),
                Text(
                  'We sent a 6-digit code to ${widget.phoneNumber}',
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 32),
                TextFormField(
                  controller: _otpController,
                  keyboardType: TextInputType.number,
                  textInputAction: TextInputAction.done,
                  autofillHints: const [AutofillHints.oneTimeCode],
                  maxLength: 6,
                  enabled: !isSubmitting,
                  textAlign: TextAlign.center,
                  style: theme.textTheme.headlineMedium,
                  decoration: const InputDecoration(
                    labelText: 'Verification code',
                    counterText: '',
                  ),
                  validator: _validateOtp,
                  onFieldSubmitted: (_) => _submit(),
                ),
                if (errorMessage != null)
                  Semantics(
                    liveRegion: true,
                    child: Padding(
                      padding: const EdgeInsets.only(bottom: 16),
                      child: Text(
                        errorMessage,
                        style: theme.textTheme.bodyMedium?.copyWith(
                          color: theme.colorScheme.error,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ),
                  ),
                ElevatedButton(
                  onPressed: isSubmitting ? null : _submit,
                  child: isSubmitting
                      ? const SizedBox(
                    height: 22,
                    width: 22,
                    child: CircularProgressIndicator(strokeWidth: 2.5),
                  )
                      : const Text('Verify'),
                ),
                const SizedBox(height: 16),
                Semantics(
                  liveRegion: true,
                  child: TextButton(
                    onPressed: secondsRemaining == 0 ? _resend : null,
                    child: Text(
                      secondsRemaining == 0
                          ? 'Resend code'
                          : 'Resend code in ${secondsRemaining}s',
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}