/// Centralized, typed route paths for Samvaad.
abstract final class AppRoutes {
  static const String splash = '/';
  static const String splashName = 'splash';

  static const String phoneEntry = '/auth/phone';
  static const String phoneEntryName = 'phoneEntry';

  static const String otpVerification = '/auth/verify';
  static const String otpVerificationName = 'otpVerification';

  static const String onboarding = '/onboarding';
  static const String onboardingName = 'onboarding';

  static const String home = '/home';
  static const String homeName = 'home';

  static const String startChat = '/home/start-chat';
  static const String startChatName = 'startChat';

  static const String createGroup = '/home/create-group';
  static const String createGroupName = 'createGroup';

  static const String conversation = '/home/conversation';
  static const String conversationName = 'conversation';
}