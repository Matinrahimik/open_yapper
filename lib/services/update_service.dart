import 'dart:convert';

import 'package:http/http.dart' as http;
import 'package:package_info_plus/package_info_plus.dart';

class UpdateCheckResult {
  const UpdateCheckResult({
    required this.currentVersion,
    required this.latestVersion,
    required this.releaseTag,
    required this.hasUpdate,
    this.releaseNotes,
    this.releasePageUrl,
    this.downloadUrl,
  });

  final String currentVersion;
  final String latestVersion;
  final String releaseTag;
  final bool hasUpdate;
  final String? releaseNotes;
  final String? releasePageUrl;
  final String? downloadUrl;
}

class GitHubUpdateService {
  const GitHubUpdateService({
    required this.owner,
    required this.repo,
    this.client,
  });

  final String owner;
  final String repo;
  final http.Client? client;

  Future<UpdateCheckResult?> checkForUpdate() async {
    final info = await PackageInfo.fromPlatform();
    final currentVersion = _normalizeVersion(info.version);

    final uri = Uri.https(
      'api.github.com',
      '/repos/$owner/$repo/releases/latest',
    );
    final httpClient = client ?? http.Client();
    try {
      final response = await httpClient.get(
        uri,
        headers: const {
          'Accept': 'application/vnd.github+json',
          'X-GitHub-Api-Version': '2022-11-28',
          'User-Agent': 'open-yapper-updater',
        },
      );
      if (response.statusCode != 200) return null;

      final decoded = jsonDecode(response.body);
      if (decoded is! Map<String, dynamic>) return null;

      final tagName = (decoded['tag_name'] as String?)?.trim();
      if (tagName == null || tagName.isEmpty) return null;
      final latestVersion = _normalizeVersion(tagName);

      final assets = decoded['assets'];
      String? dmgDownloadUrl;
      if (assets is List) {
        for (final item in assets) {
          if (item is! Map<String, dynamic>) continue;
          final name = (item['name'] as String?)?.toLowerCase() ?? '';
          final url = item['browser_download_url'] as String?;
          if (url == null) continue;
          if (name.endsWith('.dmg')) {
            dmgDownloadUrl = url;
            break;
          }
        }
      }

      return UpdateCheckResult(
        currentVersion: currentVersion,
        latestVersion: latestVersion,
        releaseTag: tagName,
        hasUpdate: _compareSemver(latestVersion, currentVersion) > 0,
        releaseNotes: decoded['body'] as String?,
        releasePageUrl: decoded['html_url'] as String?,
        downloadUrl: dmgDownloadUrl,
      );
    } catch (_) {
      return null;
    } finally {
      if (client == null) {
        httpClient.close();
      }
    }
  }
}

String normalizeReleaseVersion(String version) => _normalizeVersion(version);

String _normalizeVersion(String version) {
  var normalized = version.trim();
  if (normalized.startsWith('v') || normalized.startsWith('V')) {
    normalized = normalized.substring(1);
  }
  final plusIndex = normalized.indexOf('+');
  if (plusIndex > 0) {
    normalized = normalized.substring(0, plusIndex);
  }
  final dashIndex = normalized.indexOf('-');
  if (dashIndex > 0) {
    normalized = normalized.substring(0, dashIndex);
  }
  return normalized;
}

int _compareSemver(String a, String b) {
  final aParts = a.split('.');
  final bParts = b.split('.');
  final maxLen = aParts.length > bParts.length ? aParts.length : bParts.length;
  for (var i = 0; i < maxLen; i++) {
    final aValue = i < aParts.length ? int.tryParse(aParts[i]) ?? 0 : 0;
    final bValue = i < bParts.length ? int.tryParse(bParts[i]) ?? 0 : 0;
    if (aValue != bValue) return aValue.compareTo(bValue);
  }
  return 0;
}
