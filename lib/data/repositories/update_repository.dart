import 'dart:convert';

import 'package:http/http.dart' as http;
import 'package:shorebird_code_push/shorebird_code_push.dart';

import 'repository_error.dart';

const appReleaseTag = 'v0.1.8-test';
const appReleaseVersionLabel = '0.1.8-test';

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

class PatchUpdateInfo {
  const PatchUpdateInfo({
    required this.isAvailable,
    required this.status,
    required this.currentPatchNumber,
    required this.nextPatchNumber,
  });

  final bool isAvailable;
  final UpdateStatus status;
  final int? currentPatchNumber;
  final int? nextPatchNumber;

  bool get canDownload => isAvailable && status == UpdateStatus.outdated;
  bool get restartRequired => status == UpdateStatus.restartRequired;

  String get statusLabel {
    if (!isAvailable || status == UpdateStatus.unavailable) {
      return 'Indisponible sur cette installation';
    }
    return switch (status) {
      UpdateStatus.upToDate => 'Aucun patch rapide disponible',
      UpdateStatus.outdated => 'Patch rapide disponible',
      UpdateStatus.restartRequired => 'Redemarrage requis',
      UpdateStatus.unavailable => 'Indisponible sur cette installation',
    };
  }
}

class UpdateCheckResult {
  const UpdateCheckResult({required this.patch, required this.release});

  final PatchUpdateInfo patch;
  final AppUpdateInfo release;
}

class UpdateRepository {
  UpdateRepository({http.Client? client, ShorebirdUpdater? updater})
      : _client = client ?? http.Client(),
        _updater = updater ?? ShorebirdUpdater();

  static final _latestReleaseUri = Uri.parse(
    'https://api.github.com/repos/chezramzy/novaishop-mobile-clean/releases/latest',
  );

  final http.Client _client;
  final ShorebirdUpdater _updater;

  Future<UpdateCheckResult> checkUpdates() async {
    final patch = await checkPatchUpdate();
    final release = await checkLatestRelease();
    return UpdateCheckResult(patch: patch, release: release);
  }

  Future<PatchUpdateInfo> checkPatchUpdate() async {
    if (!_updater.isAvailable) {
      return const PatchUpdateInfo(
        isAvailable: false,
        status: UpdateStatus.unavailable,
        currentPatchNumber: null,
        nextPatchNumber: null,
      );
    }

    try {
      final currentPatch = await _updater.readCurrentPatch();
      final nextPatch = await _updater.readNextPatch();
      final status = await _updater.checkForUpdate();
      return PatchUpdateInfo(
        isAvailable: true,
        status: status,
        currentPatchNumber: currentPatch?.number,
        nextPatchNumber: nextPatch?.number,
      );
    } on ReadPatchException catch (error) {
      throw RepositoryException(
        'Lecture du patch Shorebird impossible: ${error.message}',
      );
    } catch (_) {
      throw RepositoryException('Verification Shorebird impossible.');
    }
  }

  Future<PatchUpdateInfo> downloadPatchUpdate() async {
    if (!_updater.isAvailable) {
      throw RepositoryException(
        'Patch rapide indisponible sur cette installation.',
      );
    }

    try {
      final status = await _updater.checkForUpdate();
      if (status != UpdateStatus.outdated) {
        return checkPatchUpdate();
      }

      await _updater.update();
      return checkPatchUpdate();
    } on UpdateException catch (error) {
      throw RepositoryException(
        'Telechargement du patch impossible: ${error.message}',
      );
    } on ReadPatchException catch (error) {
      throw RepositoryException(
        'Verification du patch telecharge impossible: ${error.message}',
      );
    } catch (_) {
      throw RepositoryException('Telechargement du patch impossible.');
    }
  }

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
