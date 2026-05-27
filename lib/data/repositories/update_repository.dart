import 'dart:convert';

import 'package:http/http.dart' as http;

import 'repository_error.dart';

const appReleaseTag = 'v0.1.3-test';
const appReleaseVersionLabel = '0.1.3-test';

class AppUpdateInfo {
  const AppUpdateInfo({
    required this.latestTag,
    required this.releaseUrl,
    required this.apkUrl,
    required this.apkName,
    required this.isUpdateAvailable,
  });

  final String latestTag;
  final String releaseUrl;
  final String apkUrl;
  final String apkName;
  final bool isUpdateAvailable;
}

class UpdateRepository {
  UpdateRepository({http.Client? client}) : _client = client ?? http.Client();

  static final _latestReleaseUri = Uri.parse(
    'https://api.github.com/repos/chezramzy/novaishop-mobile-clean/releases/latest',
  );

  final http.Client _client;

  Future<AppUpdateInfo> checkLatestRelease() async {
    final response = await _client.get(
      _latestReleaseUri,
      headers: const {
        'Accept': 'application/vnd.github+json',
        'User-Agent': 'NovaShop-Mobile-Updater',
      },
    );
    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw RepositoryException(
        'Verification GitHub impossible (${response.statusCode}).',
      );
    }

    final decoded = jsonDecode(response.body);
    if (decoded is! Map<String, dynamic>) {
      throw RepositoryException('Reponse GitHub invalide.');
    }

    final tag = '${decoded['tag_name'] ?? ''}'.trim();
    final releaseUrl = '${decoded['html_url'] ?? ''}'.trim();
    final assets = decoded['assets'];
    if (tag.isEmpty || releaseUrl.isEmpty || assets is! List) {
      throw RepositoryException('Release GitHub incomplete.');
    }

    Map<String, dynamic>? apkAsset;
    for (final asset in assets.whereType<Map>()) {
      final name = '${asset['name'] ?? ''}';
      if (name.toLowerCase().endsWith('.apk')) {
        apkAsset = Map<String, dynamic>.from(asset);
        break;
      }
    }
    if (apkAsset == null) {
      throw RepositoryException('Aucun APK trouve dans la derniere release.');
    }

    final apkUrl = '${apkAsset['browser_download_url'] ?? ''}'.trim();
    final apkName = '${apkAsset['name'] ?? 'NovaShop.apk'}'.trim();
    if (apkUrl.isEmpty) {
      throw RepositoryException('Lien APK GitHub manquant.');
    }

    return AppUpdateInfo(
      latestTag: tag,
      releaseUrl: releaseUrl,
      apkUrl: apkUrl,
      apkName: apkName,
      isUpdateAvailable: tag != appReleaseTag,
    );
  }
}
