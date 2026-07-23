/// Centralized, typed route paths for Samvaad.
///
/// Every navigable destination gets a named constant here instead of a
/// magic string scattered across the app — this is what makes routes
/// refactor-safe and gives GoRouter's named-navigation (`context.goNamed`)
/// something reliable to reference.
abstract final class AppRoutes {
  static const String splash = '/';

  // Route names (used with context.goNamed / pushNamed for type-safety).
  static const String splashName = 'splash';
}