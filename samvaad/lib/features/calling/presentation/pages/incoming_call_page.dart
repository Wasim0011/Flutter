import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:permission_handler/permission_handler.dart';

import '../../../../core/router/app_routes.dart';
import '../../../auth/presentation/providers/auth_providers.dart';
import '../../domain/entities/call.dart';
import '../providers/call_providers.dart';

/// Shown when [call] is ringing and the current user hasn't yet
/// answered. Requests camera/microphone permission before letting the
/// user proceed to accept — declining a call never touches
/// permissions at all, only accepting does.
class IncomingCallPage extends ConsumerStatefulWidget {
  const IncomingCallPage({required this.call, super.key});

  final Call call;

  @override
  ConsumerState<IncomingCallPage> createState() => _IncomingCallPageState();
}

class _IncomingCallPageState extends ConsumerState<IncomingCallPage> {
  bool _requesting = false;

  Future<void> _accept(String userId) async {
    setState(() => _requesting = true);

    final statuses = await [Permission.camera, Permission.microphone].request();
    final bool granted = statuses.values.every((s) => s.isGranted);

    if (!mounted) return;
    setState(() => _requesting = false);

    if (!granted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Camera and microphone access are required to join.')),
      );
      return;
    }

    context.pushReplacement(AppRoutes.call, extra: widget.call);
  }

  Future<void> _decline(String userId) async {
    await ref.read(callRepositoryProvider).decline(callId: widget.call.id, userId: userId);
    if (mounted) context.pop();
  }

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    final String? userId = ref.watch(authStateChangesProvider).value?.id;

    return Scaffold(
      backgroundColor: theme.colorScheme.surface,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.call, size: 72, color: theme.colorScheme.primary),
              const SizedBox(height: 24),
              Text(
                widget.call.isGroup ? 'Incoming group call' : 'Incoming call',
                style: theme.textTheme.headlineMedium,
              ),
              const Spacer(),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  _CallActionButton(
                    icon: Icons.call_end,
                    color: theme.colorScheme.error,
                    label: 'Decline',
                    onPressed: userId == null ? null : () => _decline(userId),
                  ),
                  _CallActionButton(
                    icon: Icons.call,
                    color: theme.colorScheme.primary,
                    label: 'Accept',
                    onPressed: (userId == null || _requesting) ? null : () => _accept(userId),
                    loading: _requesting,
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _CallActionButton extends StatelessWidget {
  const _CallActionButton({
    required this.icon,
    required this.color,
    required this.label,
    required this.onPressed,
    this.loading = false,
  });

  final IconData icon;
  final Color color;
  final String label;
  final VoidCallback? onPressed;
  final bool loading;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Semantics(
          button: true,
          label: label,
          child: FloatingActionButton(
            backgroundColor: color,
            onPressed: onPressed,
            child: loading
                ? const SizedBox(
              height: 20,
              width: 20,
              child: CircularProgressIndicator(strokeWidth: 2.5, color: Colors.white),
            )
                : Icon(icon, color: Colors.white),
          ),
        ),
        const SizedBox(height: 8),
        Text(label),
      ],
    );
  }
}