import 'package:flutter_test/flutter_test.dart';
import 'package:samvaad/features/auth/domain/entities/app_user.dart';

void main() {
  group('AppUser', () {
    test('two instances with identical fields are equal', () {
      const AppUser a = AppUser(id: 'u1', phoneNumber: '+919876543210');
      const AppUser b = AppUser(id: 'u1', phoneNumber: '+919876543210');

      expect(a, equals(b));
      expect(a.hashCode, equals(b.hashCode));
    });

    test('instances differing by communicationPreference are not equal', () {
      const AppUser a = AppUser(
        id: 'u1',
        phoneNumber: '+919876543210',
        communicationPreference: CommunicationPreference.signLanguage,
      );
      const AppUser b = AppUser(
        id: 'u1',
        phoneNumber: '+919876543210',
        communicationPreference: CommunicationPreference.textFirst,
      );

      expect(a, isNot(equals(b)));
    });

    test('displayName and communicationPreference default to null', () {
      const AppUser user = AppUser(id: 'u1', phoneNumber: '+919876543210');

      expect(user.displayName, isNull);
      expect(user.communicationPreference, isNull);
    });
  });
}