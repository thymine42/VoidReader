import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:sqflite/sqflite.dart';

import 'get_base_path.dart';

Future<String> getVoidDatabasePath() async {
  switch (defaultTargetPlatform) {
    case TargetPlatform.android:
      final path = await getDatabasesPath();
      return path;
    case TargetPlatform.linux:
    case TargetPlatform.windows:
    case TargetPlatform.macOS:
    case TargetPlatform.iOS:
      final documentsPath = await getAnxDocumentsPath();
      return '$documentsPath${Platform.pathSeparator}databases';
    default:
      throw Exception('Unsupported platform');
  }
}

Future<Directory> getVoidDatabaseDir() async {
  return Directory(await getVoidDatabasePath());
}
