import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/router/app_router.dart';
import '../../../../core/router/app_routes.dart';
import '../../../auth/presentation/providers/auth_providers.dart';
import '../providers/incoming_call_providers.dart';

/// Wraps the entire app so an incoming call can be surfaced regardless
/// of which screen the user is currently on — chat, home, settings,
/// wherever. Uses the GoRouter instance's own `.push()` directly
/// (rather than `context.push`) since this widget sits above the
/// routed content in the tree and calling through `BuildContext`
/// would require a descendant of the Router, which this isn't.
class IncomingCallGate extends ConsumerStatefulWidget {
  const IncomingCallGate({required this.child, super.key});

  final Widget child;

  @override
  ConsumerState<IncomingCallGate> createState() => _IncomingCallGateState();
}

class _IncomingCallGateState extends ConsumerState<IncomingCallGate> {
  final Set<String> _handledCallIds = {};

  @override
  Widget build(BuildContext context) {
    final String? userId = ref.watch(authStateChangesProvider).value?.id;

    if (userId != null) {
      ref.listen(nextIncomingCallProvider(userId), (previous, next) {
        final call = next.value;
        if (call != null && !_handledCallIds.contains(call.id)) {
          _handledCallIds.add(call.id);
          ref.read(appRouterProvider).push(AppRoutes.incomingCall, extra: call);
        }
      });
    }

    return widget.child;
  }
}