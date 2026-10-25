// Renders the launcher icons in assets/icon/ from LogoPainter.
//
//   RENDER_ICONS=1 flutter test test/tool/render_icons_test.dart
//   dart run flutter_launcher_icons
@Tags(['tool'])
library;

import 'dart:io';
import 'dart:ui' as ui;

import 'package:cash_register/core/theme/app_theme.dart';
import 'package:cash_register/core/widgets/app_logo.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

Future<void> _render(
  String path,
  LogoPainter painter, {
  int size = 1024,
}) async {
  final recorder = ui.PictureRecorder();
  painter.paint(Canvas(recorder), Size.square(size.toDouble()));
  final image = await recorder.endRecording().toImage(size, size);
  final png = await image.toByteData(format: ui.ImageByteFormat.png);
  File(path).writeAsBytesSync(png!.buffer.asUint8List());
}

void main() {
  final start = AppPalette.light.heroStart;
  final end = AppPalette.light.heroEnd;

  test('render launcher icons', () async {
    // iOS, Android legacy, Windows, web: full square; the OS rounds it.
    await _render(
      'assets/icon/app_icon.png',
      LogoPainter(start: start, end: end, cornerRadius: 0),
    );
    // Android adaptive foreground: receipt only, inside the safe zone.
    await _render(
      'assets/icon/app_icon_foreground.png',
      LogoPainter(start: start, end: end, tile: false, receiptScale: .62),
    );
    // macOS: rounded tile with the standard margin.
    await _render(
      'assets/icon/app_icon_macos.png',
      LogoPainter(start: start, end: end, cornerRadius: .225, inset: .098),
    );
  }, skip: Platform.environment['RENDER_ICONS'] == null);
}
