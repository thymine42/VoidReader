import 'dart:io';
import 'package:flutter/services.dart';
import 'package:window_manager/window_manager.dart';

void hideStatusBar() {
  if (Platform.isWindows) {
    windowManager.setFullScreen(true);
  } else {
    SystemChrome.setEnabledSystemUIMode(
      SystemUiMode.manual,
      overlays: [],
    );
  }
}

void showStatusBar() {
  if (Platform.isWindows) {
    windowManager.setFullScreen(false);
  } else {
    SystemChrome.setEnabledSystemUIMode(
      SystemUiMode.manual,
      overlays: SystemUiOverlay.values,
    );
  }
}

void showStatusBarWithoutResize() {
  if (Platform.isWindows) {
    return;
  }
  SystemChrome.setEnabledSystemUIMode(
    SystemUiMode.edgeToEdge,
  );
}

void onlyStatusBar() {
  if (Platform.isWindows) {
    return;
  }
  SystemChrome.setEnabledSystemUIMode(
    SystemUiMode.manual,
    overlays: [
      SystemUiOverlay.top,
    ],
  );
}
