import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/router/app_routes.dart';
import '../controllers/phone_entry_controller.dart';

/// Entry point of Samvaad's sign-in flow: collect a phone number and
/// request an OTP.
///
/// Accessibility notes (deliberate, not incidental):
/// - The phone field uses `TextInputType.phone` so on-screen keyboards
///   surface the right layout automatically.
/// - Error text is announced via `Semantics(liveRegion: true)` so
///   screen readers pick up validation/network errors without the
///   user needing to re-focus the field.
/// - The submit button's minimum 52dp height comes from `AppTheme`
///   (Phase 1) — no ad hoc sizing here.
class PhoneEntryPage extends ConsumerStatefulWidget {
  const PhoneEntryPage({super.key});

  @override
  ConsumerState<PhoneEntryPage> createState() => _PhoneEntryPageState();
}

class _PhoneEntryPageState extends ConsumerState<PhoneEntryPage> {
  final _formKey = GlobalKey<FormState>();
  final _phoneController = TextEditingController();

  @override
  void dispose() {
    _phoneController.dispose();
    super.dispose();
  }

  String? _validatePhone(String? value) {
    final String input = (value ?? '').trim();
    if (input.isEmpty) {
      return 'Enter your phone number';
    }
    // E.164: a leading '+', then 8–15 digits total. This is a
    // deliberately loose check — Firebase itself is the source of
    // truth on validity (invalid-phone-number failure), this just
    // catches obviously-malformed input before a network round trip.
    final RegExp e164 = RegExp(r'^\+[1-9]\d{7,14}$');
    if (!e164.hasMatch(input)) {
      return 'Include your country code, e.g. +919876543210';
    }
    return null;
  }

  void _submit() {
    if (!(_formKey.currentState?.validate() ?? false)) return;
    ref.read(phoneEntryControllerProvider.notifier).submit(_phoneController.text.trim());
  }

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    final PhoneEntryState state = ref.watch(phoneEntryControllerProvider);
    final bool isSubmitting = state is PhoneEntrySubmitting;

    // PhoneEntrySent handling (navigation) is deferred to Milestone
    // 2.6 once routing/guards exist. For now we surface it as an
    // inline confirmation so this milestone is independently verifiable.
    final String? errorMessage = state is PhoneEntryFailed ? state.message : null;
    final String? sentNotice = state is PhoneEntrySent
        ? 'Code sent to ${state.phoneNumber} (verification id: ${state.verificationId})'
        : null;
    // if (state is PhoneEntrySent) {
    //   WidgetsBinding.instance.addPostFrameCallback((_) {
    //     context.push(AppRoutes.otpVerification, extra: {
    //       'verificationId': state.verificationId,
    //       'phoneNumber': state.phoneNumber,
    //     });
    //   });
    // }

    return Scaffold(
      appBar: AppBar(title: const Text('Sign in')),
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
                  'Enter your phone number',
                  style: theme.textTheme.headlineMedium,
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 8),
                Text(
                  'We\'ll send you a one-time code to verify it\'s you.',
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 32),
                TextFormField(
                  controller: _phoneController,
                  keyboardType: TextInputType.phone,
                  textInputAction: TextInputAction.done,
                  autofillHints: const [AutofillHints.telephoneNumber],
                  enabled: !isSubmitting,
                  decoration: const InputDecoration(
                    labelText: 'Phone number',
                    hintText: '+919876543210',
                    prefixIcon: Icon(Icons.phone_outlined),
                  ),
                  validator: _validatePhone,
                  onFieldSubmitted: (_) => _submit(),
                ),
                const SizedBox(height: 16),
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
                if (sentNotice != null)
                  Semantics(
                    liveRegion: true,
                    child: Padding(
                      padding: const EdgeInsets.only(bottom: 16),
                      child: Text(
                        sentNotice,
                        style: theme.textTheme.bodyMedium?.copyWith(
                          color: theme.colorScheme.primary,
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
                      : const Text('Send code'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}