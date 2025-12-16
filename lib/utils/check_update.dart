import 'package:void_reader/config/shared_preference_provider.dart';
import 'package:void_reader/l10n/generated/L10n.dart';
import 'package:void_reader/main.dart';
import 'package:void_reader/utils/app_version.dart';
import 'package:void_reader/utils/env_var.dart';
import 'package:void_reader/utils/log/common.dart';
import 'package:void_reader/utils/toast/common.dart';
import 'package:void_reader/widgets/markdown/styled_markdown.dart';
import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_smart_dialog/flutter_smart_dialog.dart';
import 'package:url_launcher/url_launcher.dart';
import 'dart:io';

Future<void> checkUpdate(bool manualCheck) async {
  if (!EnvVar.enableCheckUpdate) {
    return;
  }
  // if is today
  if (!manualCheck &&
      DateTime.now().difference(Prefs().lastShowUpdate) <
          const Duration(days: 1)) {
    return;
  }
  Prefs().lastShowUpdate = DateTime.now();

  BuildContext context = navigatorKey.currentContext!;
  Response response;
  try {
    // Fetch latest release from GitHub Releases for VoidReader
    response = await Dio().get('https://api.github.com/repos/thymine42/VoidReader/releases/latest');
  } catch (e) {
    if (manualCheck) {
      VoidToast.show(L10n.of(context).commonFailed);
    }
    VoidLog.severe('Update: Failed to check for updates $e');
    return;
  }

  // GitHub returns tag_name like "v1.2.3" and body for release notes
  String newVersionRaw = '';
  try {
    newVersionRaw = response.data['tag_name'] ?? response.data['name'] ?? '';
  } catch (e) {
    newVersionRaw = '';
  }
  String newVersion = newVersionRaw.startsWith('v') ? newVersionRaw.substring(1) : newVersionRaw;
  String currentVersion = await getAppVersion();
  VoidLog.info('Update: new version $newVersion');

  // currentVersion is like '1.10.1+6279' from pubspec; split out build
  final curParts = currentVersion.split('+');
  final newParts = newVersion.split('+');
  List<String> newVersionList = newParts[0].split('.');
  List<String> currentVersionList = curParts[0].split('.');
  VoidLog.info(
      'Current version: $currentVersionList, New version: $newVersionList');
  bool needUpdate = false;
  final maxLen = newVersionList.length > currentVersionList.length
      ? newVersionList.length
      : currentVersionList.length;
  for (int i = 0; i < maxLen; i++) {
    final nv = i < newVersionList.length ? int.tryParse(newVersionList[i]) ?? 0 : 0;
    final cv = i < currentVersionList.length ? int.tryParse(currentVersionList[i]) ?? 0 : 0;
    if (nv > cv) {
      needUpdate = true;
      break;
    } else if (nv < cv) {
      needUpdate = false;
      break;
    }
  }

  // If semantic versions are equal, compare build numbers (if present)
  if (!needUpdate) {
    final nvBuild = newParts.length > 1 ? int.tryParse(newParts[1]) ?? 0 : 0;
    final cvBuild = curParts.length > 1 ? int.tryParse(curParts[1]) ?? 0 : 0;
    if (nvBuild > cvBuild) {
      needUpdate = true;
    }
  }

  if (needUpdate) {
    if (manualCheck) {
      Navigator.of(context).pop();
    }
    SmartDialog.show(
      builder: (BuildContext context) {
        final body = response.data['body']?.toString() ?? '';
        return AlertDialog(
          title: Text(L10n.of(context).commonNewVersion,
              style: const TextStyle(
                fontWeight: FontWeight.bold,
              )),
          content: SingleChildScrollView(
            child: StyledMarkdown(
                data: '''### ${L10n.of(context).updateNewVersion} $newVersion\n
${L10n.of(context).updateCurrentVersion} $currentVersion\n
$body'''),
          ),
          actions: <Widget>[
            TextButton(
              onPressed: () {
                SmartDialog.dismiss();
              },
              child: Text(L10n.of(context).commonCancel),
            ),
            TextButton(
              onPressed: () async {
                // Try to download the appropriate asset for this platform and launch it.
                SmartDialog.showLoading(msg: L10n.of(context).commonDownloading);
                try {
                  final assets = response.data['assets'] as List? ?? [];
                  String? downloadUrl;
                  String? assetName;
                  String lowerName;
                  for (final a in assets) {
                    final name = (a['name'] ?? '').toString();
                    lowerName = name.toLowerCase();
                    final url = a['browser_download_url']?.toString();
                    if (url == null) continue;
                    if (Platform.isWindows &&
                        (lowerName.endsWith('.exe') || lowerName.endsWith('.msi') || lowerName.endsWith('.zip'))) {
                      downloadUrl = url;
                      assetName = name;
                      break;
                    }
                    if (Platform.isMacOS &&
                        (lowerName.endsWith('.dmg') || lowerName.endsWith('.pkg') || lowerName.endsWith('.zip'))) {
                      downloadUrl = url;
                      assetName = name;
                      break;
                    }
                    if (Platform.isLinux &&
                        (lowerName.endsWith('.AppImage'.toLowerCase()) || lowerName.endsWith('.deb') || lowerName.endsWith('.tar.gz') || lowerName.endsWith('.zip'))) {
                      downloadUrl = url;
                      assetName = name;
                      break;
                    }
                    // For Android APKs in releases (rare) prefer direct APK
                    if (!Platform.isWindows && !Platform.isMacOS && !Platform.isLinux && lowerName.endsWith('.apk')) {
                      downloadUrl = url;
                      assetName = name;
                      break;
                    }
                  }

                  if (downloadUrl == null) {
                    SmartDialog.dismiss();
                    // Fallback: open releases page in browser
                    await launchUrl(
                        Uri.parse('https://github.com/thymine42/VoidReader/releases/latest'),
                        mode: LaunchMode.externalApplication);
                    return;
                  }

                  final tempDir = Directory.systemTemp.createTempSync('void_update_');
                  final filename = assetName ?? downloadUrl.split('/').last;
                  final filePath = '${tempDir.path}${Platform.pathSeparator}$filename';
                  final file = File(filePath);

                  // Download
                  await Dio().download(downloadUrl, file.path,
                      onReceiveProgress: (received, total) {
                    // Optionally update UI with progress
                  });

                  SmartDialog.dismiss();

                  // Launch installer/open file depending on platform
                  if (Platform.isWindows) {
                    await Process.start(file.path, [], runInShell: true);
                    exit(0);
                  } else if (Platform.isMacOS) {
                    await Process.start('open', [file.path]);
                    // Do not force-exit on macOS — let user installer flow continue
                  } else if (Platform.isLinux) {
                    await Process.start('xdg-open', [file.path]);
                  } else {
                    // For mobile / unknown platforms, open the release page
                    await launchUrl(
                        Uri.parse('https://github.com/thymine42/VoidReader/releases/latest'),
                        mode: LaunchMode.externalApplication);
                  }
                } catch (e) {
                  SmartDialog.dismiss();
                  VoidLog.severe('Update: Failed to download or launch update: $e');
                  // fallback open release page
                  await launchUrl(
                      Uri.parse('https://github.com/thymine42/VoidReader/releases/latest'),
                      mode: LaunchMode.externalApplication);
                }
              },
              child: Text(L10n.of(context).updateViaGithub),
            ),
            TextButton(
              onPressed: () {
                launchUrl(Uri.parse('https://github.com/thymine42/VoidReader'),
                    mode: LaunchMode.externalApplication);
              },
              child: Text(L10n.of(context).updateViaOfficialWebsite),
            ),
          ],
        );
      },
    );
  } else {
    if (manualCheck) {
      VoidToast.show(L10n.of(context).commonNoNewVersion);
    }
  }
}
