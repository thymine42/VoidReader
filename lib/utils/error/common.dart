import 'dart:ui';

import 'package:void_reader/utils/log/common.dart';
import 'package:flutter/material.dart';

class VoidError {
  static Future<void> init() async {
    VoidLog.info('VoidError init');
    FlutterError.onError = (details) {
      FlutterError.presentError(details);
      VoidLog.severe(details.exceptionAsString(), details.stack);
    };
    PlatformDispatcher.instance.onError = (error, stack) {
      VoidLog.severe(error.toString(), stack);
      return false;
    };
  }
}
