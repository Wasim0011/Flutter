import 'package:flutter/material.dart';
import 'package:get_it/get_it.dart';
import 'package:go_router/go_router.dart';
import '../../core/plugins/flutter_plugin.dart';
import '../../core/theme/app_colors.dart';
import 'presentation/screens/hs_shell_screen.dart';
import 'presentation/screens/hs_booking_flow_screen.dart';
import 'presentation/screens/hs_orders_screen.dart';

import '../../core/network/api_client.dart';
import 'data/repositories/house_shifting_repository.dart';
import 'presentation/bloc/house_shifting_cubit.dart';

class HouseShiftingPlugin extends FlutterPlugin {
  @override
  String get slug => 'house_shifting';

  @override
  String get name => 'House Shifting';

  @override
  void registerDependencies(GetIt getIt) {
    if (!getIt.isRegistered<HouseShiftingRepository>()) {
      getIt.registerLazySingleton<HouseShiftingRepository>(
        () => HouseShiftingRepository(getIt<ApiClient>()),
      );
    }
    if (!getIt.isRegistered<HouseShiftingCubit>()) {
      getIt.registerLazySingleton<HouseShiftingCubit>(
        () => HouseShiftingCubit(getIt<HouseShiftingRepository>()),
      );
    }
  }

  @override
  List<RouteBase> get routes => [
    GoRoute(
      path: '/house-shifting',
      builder: (context, state) => const HsShellScreen(),
      routes: [
        GoRoute(
          path: 'book',
          builder: (context, state) {
            final args = state.extra;
            if (args is! HsBookingArgs) {
              // Fallback: pop back to home if args are missing
              WidgetsBinding.instance.addPostFrameCallback((_) {
                if (context.canPop()) context.pop();
              });
              return const Scaffold(
                body: Center(child: CircularProgressIndicator()),
              );
            }
            return HsBookingFlowScreen(args: args);
          },
        ),
        GoRoute(
          path: 'orders',
          builder: (context, state) => const HsOrdersScreen(),
        ),
        GoRoute(
          path: 'order-success',
          builder: (context, state) {
            final result = state.extra as Map<String, dynamic>?;
            return _HsOrderSuccessScreen(orderData: result);
          },
        ),
      ],
    ),
  ];

  @override
  PluginModuleButton? get moduleButton => const PluginModuleButton(
    icon: Icons.local_shipping,
    label: 'House Shifting',
    routePath: '/house-shifting',
  );

  @override
  PluginHeaderTab? get headerTab => const PluginHeaderTab(
    icon: Icons.local_shipping_outlined,
    label: 'Shifting',
    routePath: '/house-shifting',
  );
}

// ─────────────────────────────────────────────────────────────────────────────
// Order success screen (inline — simple)
// ─────────────────────────────────────────────────────────────────────────────
class _HsOrderSuccessScreen extends StatelessWidget {
  final Map<String, dynamic>? orderData;

  const _HsOrderSuccessScreen({this.orderData});

  @override
  Widget build(BuildContext context) {
    final order = orderData?['order'] as Map<String, dynamic>? ?? orderData ?? {};
    final orderNumber = order['order_number']?.toString() ?? '#${order['id'] ?? '-'}';

    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                width: 100,
                height: 100,
                decoration: BoxDecoration(
                  color: AppColors.primary,
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: AppColors.primary.withValues(alpha: 0.3),
                      blurRadius: 20,
                      offset: const Offset(0, 8),
                    ),
                  ],
                ),
                child: const Icon(Icons.check_rounded, size: 52, color: Colors.white),
              ),
              const SizedBox(height: 28),
              const Text(
                'Order Placed!',
                style: TextStyle(fontSize: 26, fontWeight: FontWeight.w900, color: Color(0xFF1F2937)),
              ),
              const SizedBox(height: 10),
              Text(
                'Your shifting order $orderNumber has been placed successfully.',
                textAlign: TextAlign.center,
                style: const TextStyle(fontSize: 14, color: Color(0xFF6B7280), height: 1.5),
              ),
              const SizedBox(height: 40),
              SizedBox(
                width: double.infinity,
                height: 50,
                child: ElevatedButton(
                  onPressed: () => context.go('/house-shifting/orders'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                    elevation: 0,
                  ),
                  child: const Text('View Orders',
                      style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700, color: Colors.white)),
                ),
              ),
              const SizedBox(height: 12),
              TextButton(
                onPressed: () => context.go('/house-shifting'),
                child: const Text('Back to Home',
                    style: TextStyle(fontSize: 14, color: Color(0xFF6B7280))),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
