import 'package:flutter/material.dart';
import 'package:get_it/get_it.dart';
import 'package:go_router/go_router.dart';

import '../../core/plugins/flutter_plugin.dart';
import '../../core/router/page_transitions.dart';
import '../../core/network/api_client.dart';
import '../../core/network/network_info.dart';
import '../../core/services/payment_gateway_service.dart';
import 'data/datasources/ride_sharing_remote_datasource.dart';
import 'data/repositories/ride_sharing_repository_impl.dart';
import 'domain/repositories/ride_sharing_repository.dart';
import 'presentation/bloc/ride_sharing_bloc.dart';
import 'presentation/pages/ride_shell_page.dart';
import 'presentation/pages/ride_history_page.dart';
import 'presentation/pages/ride_details_page.dart';
import 'presentation/pages/emergency_contacts_page.dart';

class RideSharingPlugin extends FlutterPlugin {
  @override
  String get slug => 'ride_sharing';

  @override
  String get name => 'Ride Sharing';

  @override
  void registerDependencies(GetIt getIt) {
    getIt.registerLazySingleton<RideSharingRemoteDataSource>(
      () => RideSharingRemoteDataSourceImpl(apiClient: getIt<ApiClient>()),
    );
    getIt.registerLazySingleton<RideSharingRepository>(
      () => RideSharingRepositoryImpl(
        remoteDataSource: getIt(),
        networkInfo: getIt<NetworkInfo>(),
      ),
    );
    getIt.registerFactory<RideSharingBloc>(
      () => RideSharingBloc(
        repository: getIt(),
        paymentService: getIt<PaymentGatewayService>(),
      ),
    );
  }

  @override
  List<RouteBase> get routes => [
        GoRoute(
          path: '/ride-sharing',
          name: 'rideSharing',
          pageBuilder: (context, state) => SlideTransitionPage(
            key: state.pageKey,
            child: const RideShellPage(),
          ),
        ),
        GoRoute(
          path: '/ride-sharing/history',
          name: 'rideHistory',
          pageBuilder: (context, state) => SlideTransitionPage(
            key: state.pageKey,
            child: const RideHistoryPage(),
          ),
        ),
        GoRoute(
          path: '/ride-sharing/details/:id',
          name: 'rideDetails',
          pageBuilder: (context, state) {
            final rideId = int.parse(state.pathParameters['id']!);
            return SlideTransitionPage(
              key: state.pageKey,
              child: RideDetailsPage(rideId: rideId),
            );
          },
        ),
        GoRoute(
          path: '/emergency-contacts',
          name: 'emergencyContacts',
          pageBuilder: (context, state) => SlideTransitionPage(
            key: state.pageKey,
            child: const EmergencyContactsPage(),
          ),
        ),
      ];

  @override
  PluginModuleButton get moduleButton => const PluginModuleButton(
        icon: Icons.directions_car_rounded,
        label: 'Book a Ride',
        routePath: '/ride-sharing',
      );

  @override
  PluginHeaderTab get headerTab => const PluginHeaderTab(
        icon: Icons.directions_car_rounded,
        label: 'Ride',
        routePath: '/ride-sharing',
      );
}
