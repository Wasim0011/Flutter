import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:samvaad/bootstrap.dart';
import 'package:samvaad/features/auth/presentation/controllers/onboarding_controller.dart';
import 'package:samvaad/features/auth/presentation/providers/auth_providers.dart';
import 'package:samvaad/features/calling/presentation/providers/call_providers.dart';
import 'package:samvaad/features/chat/presentation/providers/chat_providers.dart';
import 'package:samvaad/features/community/presentation/providers/community_providers.dart';
import 'package:samvaad/features/translation/presentation/providers/translation_providers.dart';

import '../test/features/auth/fakes/fake_auth_repository.dart';
import '../test/features/auth/fakes/fake_user_profile_repository.dart';
import '../test/features/calling/fakes/fake_call_repository.dart';
import '../test/features/chat/fakes/fake_chat_repository.dart';
import '../test/features/community/fakes/fake_community_repository.dart';
import '../test/features/translation/fakes/fake_sign_interpretation_repository.dart';
import '../test/test_utils/firebase_test_setup.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  late FakeAuthRepository fakeAuth;
  late FakeUserProfileRepository fakeProfiles;
  late FakeChatRepository fakeChat;
  late FakeCommunityRepository fakeCommunity;
  late FakeCallRepository fakeCalls;

  const String secondUserId = 'friend-uid';
  const String secondUserPhone = '+919000000001';

  setUp(() async {
    // Defensive safety net, same lesson as test/widget_test.dart: if
    // any code path were ever reached that isn't covered by one of
    // the overrides below, this prevents a bare "no Firebase app"
    // crash rather than masking a real gap in the override list.
    await ensureFirebaseTestSetup();

    fakeAuth = FakeAuthRepository();
    fakeProfiles = FakeUserProfileRepository();
    fakeChat = FakeChatRepository();
    fakeCommunity = FakeCommunityRepository();
    fakeCalls = FakeCallRepository();

    // A second, pre-existing user to chat and call with during the test.
    await fakeProfiles.ensureUserDocument(
      userId: secondUserId,
      phoneNumber: secondUserPhone,
    );
    await fakeProfiles.saveDisplayName(
      userId: secondUserId,
      displayName: 'Friend',
    );
  });

  tearDown(() {
    fakeChat.dispose();
    fakeCalls.dispose();
  });

  testWidgets('core journey: sign in, onboard, send a message, start a call', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          authRepositoryProvider.overrideWithValue(fakeAuth),
          userProfileRepositoryProvider.overrideWithValue(fakeProfiles),
          chatRepositoryProvider.overrideWithValue(fakeChat),
          communityRepositoryProvider.overrideWithValue(fakeCommunity),
          callRepositoryProvider.overrideWithValue(fakeCalls),
          signInterpretationRepositoryProvider.overrideWithValue(
            FakeSignInterpretationRepository(),
          ),
        ],
        child: const SamvaadApp(),
      ),
    );
    await tester.pumpAndSettle();

    // --- Sign in ---
    expect(find.text('Sign in'), findsOneWidget);
    await tester.enterText(find.byType(TextFormField).first, '+919999999999');
    await tester.tap(find.text('Send code'));
    await tester.pumpAndSettle();

    // --- OTP ---
    expect(find.text('Verify your number'), findsOneWidget);
    await tester.enterText(
      find.byType(TextFormField).first,
      fakeAuth.correctOtp,
    );
    await tester.tap(find.text('Verify'));
    await tester.pumpAndSettle();

    // --- Onboarding ---
    expect(find.text('Set up your profile'), findsOneWidget);
    await tester.enterText(find.byType(TextField).first, 'Me');
    await tester.tap(find.text('Text first'));
    await tester.pump();
    await tester.tap(find.text('Continue'));
    await tester.pumpAndSettle();

    // --- Home ---
    expect(find.text('Samvaad'), findsOneWidget);

    // --- Start a chat with the second user ---
    await tester.tap(find.byTooltip('New chat'));
    await tester.pumpAndSettle();
    await tester.enterText(find.byType(TextFormField).first, secondUserPhone);
    await tester.tap(find.text('Start chat'));
    await tester.pumpAndSettle();

    // --- Send a message ---
    await tester.enterText(find.byType(TextField).first, 'Hello there');
    await tester.tap(find.bySemanticsLabel('Send message'));
    await tester.pumpAndSettle();
    expect(find.text('Hello there'), findsOneWidget);

    // --- Start a call ---
    // Bounded manual pumps, not pumpAndSettle — a real network attempt
    // to LiveKit is still in flight here (or failing), and
    // pumpAndSettle cannot return while the connecting spinner is
    // still animating. We just need enough pumps to observe the
    // resulting state, not to wait for it to fully settle.
    await tester.tap(find.byTooltip('Start call'));
    for (int i = 0; i < 20; i++) {
      await tester.pump(const Duration(milliseconds: 300));
    }
    final bool connecting = find
        .byType(CircularProgressIndicator)
        .evaluate()
        .isNotEmpty;
    final bool failedToJoin = find
        .textContaining('Couldn\'t join the call')
        .evaluate()
        .isNotEmpty;
    expect(
      connecting || failedToJoin,
      isTrue,
      reason:
          'Expected the call screen to either still be connecting or report a '
          'join failure — a real LiveKit connection is not exercised in this test.',
    );
  });
}
