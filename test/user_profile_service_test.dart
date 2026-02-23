import 'package:flutter_test/flutter_test.dart';
import 'package:open_yapper/services/user_profile_service.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  group('UserProfileService', () {
    setUp(() {
      SharedPreferences.setMockInitialValues({});
    });

    test('saves and loads profile fields', () async {
      final service = UserProfileService();
      await service.saveProfile(
        const UserProfile(
          fullName: 'Matin Rahimi',
          email: 'matin@example.com',
          phone: '+1 555 0101',
          linkedin: 'https://linkedin.com/in/matin',
          customFields: {'my portfolio': 'https://example.com'},
        ),
      );

      final loadedService = UserProfileService();
      final loaded = await loadedService.loadProfile();

      expect(loaded.fullName, 'Matin Rahimi');
      expect(loaded.email, 'matin@example.com');
      expect(loaded.phone, '+1 555 0101');
      expect(loaded.linkedin, 'https://linkedin.com/in/matin');
      expect(loaded.customFields['my portfolio'], 'https://example.com');
    });

    test('generates expected alias map', () {
      const profile = UserProfile(
        fullName: 'Matin',
        email: 'matin@example.com',
        phone: '12345',
      );
      final aliasMap = profile.aliasMap;

      expect(aliasMap['my email'], 'matin@example.com');
      expect(aliasMap['my phone'], '12345');
      expect(aliasMap['my name'], 'Matin');
    });
  });
}
