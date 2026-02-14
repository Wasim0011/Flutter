import 'package:flutter/material.dart';

class NavigatorService {
  static GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();

  static Future<dynamic> pushNamed(
    String routeName, {
    dynamic arguments,
  }) async {
    return navigatorKey.currentState
        ?.pushNamed(routeName, arguments: arguments);
  }

  static void goBack() {
    return navigatorKey.currentState?.pop();
  }

  static Future<dynamic> pushNamedAndRemoveUntil(
    String routeName, {
    RoutePredicate? predicate,
    dynamic arguments,
  }) async {
    return navigatorKey.currentState?.pushNamedAndRemoveUntil(
      routeName,
      predicate ?? (route) => false,
      arguments: arguments,
    );
  }

  static Future<dynamic> popAndPushNamed(
    String routeName, {
    dynamic arguments,
  }) async {
    return navigatorKey.currentState
        ?.popAndPushNamed(routeName, arguments: arguments);
  }
}
