import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

const _userProfileKey = 'user_profile_v1';

class UserProfile {
  const UserProfile({
    this.fullName = '',
    this.email = '',
    this.phone = '',
    this.linkedin = '',
    this.github = '',
    this.website = '',
    this.twitter = '',
    this.instagram = '',
    this.customFields = const {},
  });

  final String fullName;
  final String email;
  final String phone;
  final String linkedin;
  final String github;
  final String website;
  final String twitter;
  final String instagram;
  final Map<String, String> customFields;

  static const empty = UserProfile();

  bool get isEmpty =>
      fullName.trim().isEmpty &&
      email.trim().isEmpty &&
      phone.trim().isEmpty &&
      linkedin.trim().isEmpty &&
      github.trim().isEmpty &&
      website.trim().isEmpty &&
      twitter.trim().isEmpty &&
      instagram.trim().isEmpty &&
      customFields.isEmpty;

  Map<String, dynamic> toJson() => {
    'fullName': fullName,
    'email': email,
    'phone': phone,
    'linkedin': linkedin,
    'github': github,
    'website': website,
    'twitter': twitter,
    'instagram': instagram,
    'customFields': customFields,
  };

  factory UserProfile.fromJson(Map<String, dynamic> json) {
    final rawCustom = json['customFields'];
    return UserProfile(
      fullName: (json['fullName'] as String? ?? '').trim(),
      email: (json['email'] as String? ?? '').trim(),
      phone: (json['phone'] as String? ?? '').trim(),
      linkedin: (json['linkedin'] as String? ?? '').trim(),
      github: (json['github'] as String? ?? '').trim(),
      website: (json['website'] as String? ?? '').trim(),
      twitter: (json['twitter'] as String? ?? '').trim(),
      instagram: (json['instagram'] as String? ?? '').trim(),
      customFields: rawCustom is Map<String, dynamic>
          ? rawCustom.map((k, v) => MapEntry(k, (v as String? ?? '').trim()))
          : const {},
    );
  }

  UserProfile copyWith({
    String? fullName,
    String? email,
    String? phone,
    String? linkedin,
    String? github,
    String? website,
    String? twitter,
    String? instagram,
    Map<String, String>? customFields,
  }) {
    return UserProfile(
      fullName: fullName ?? this.fullName,
      email: email ?? this.email,
      phone: phone ?? this.phone,
      linkedin: linkedin ?? this.linkedin,
      github: github ?? this.github,
      website: website ?? this.website,
      twitter: twitter ?? this.twitter,
      instagram: instagram ?? this.instagram,
      customFields: customFields ?? this.customFields,
    );
  }

  /// Maps spoken aliases to actual user values.
  Map<String, String> get aliasMap {
    final map = <String, String>{};
    void addAliases(List<String> keys, String value) {
      final clean = value.trim();
      if (clean.isEmpty) return;
      for (final key in keys) {
        map[key] = clean;
      }
    }

    addAliases(['my name', 'my full name'], fullName);
    addAliases(['my email', 'my email address'], email);
    addAliases(['my phone', 'my phone number', 'my number'], phone);
    addAliases(['my linkedin', 'my linked in'], linkedin);
    addAliases(['my github', 'my git hub'], github);
    addAliases(['my website', 'my site'], website);
    addAliases(['my twitter', 'my x profile'], twitter);
    addAliases(['my instagram', 'my insta'], instagram);
    for (final entry in customFields.entries) {
      final key = entry.key.trim().toLowerCase();
      final value = entry.value.trim();
      if (key.isNotEmpty && value.isNotEmpty) {
        map[key] = value;
      }
    }
    return map;
  }
}

class UserProfileService extends ChangeNotifier {
  UserProfile _profile = UserProfile.empty;
  bool _loaded = false;

  bool get isLoaded => _loaded;
  UserProfile get profile => _profile;

  Future<UserProfile> loadProfile() async {
    if (_loaded) return _profile;
    try {
      final prefs = await SharedPreferences.getInstance();
      final raw = prefs.getString(_userProfileKey);
      if (raw != null && raw.isNotEmpty) {
        _profile = UserProfile.fromJson(
          jsonDecode(raw) as Map<String, dynamic>,
        );
      }
    } catch (_) {
      _profile = UserProfile.empty;
    }
    _loaded = true;
    notifyListeners();
    return _profile;
  }

  Future<void> saveProfile(UserProfile value) async {
    _profile = value;
    _loaded = true;
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_userProfileKey, jsonEncode(value.toJson()));
    } catch (_) {}
    notifyListeners();
  }
}
