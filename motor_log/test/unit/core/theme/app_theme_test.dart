import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:motor_log/core/theme/app_theme.dart';

void main() {
  group('AppTheme', () {
    test('lightTheme keeps base application settings', () {
      final theme = AppTheme.lightTheme;

      expect(theme.useMaterial3, isTrue);
      expect(theme.scaffoldBackgroundColor, AppTheme.bgWhite);
      expect(theme.appBarTheme.backgroundColor, AppTheme.bgWhite);
      expect(theme.appBarTheme.centerTitle, isTrue);
    });

    test('lightTheme configures cards for garage and consumables lists', () {
      final theme = AppTheme.lightTheme;
      final shape = theme.cardTheme.shape as RoundedRectangleBorder;

      expect(theme.cardTheme.elevation, 0);
      expect(theme.cardTheme.color, Colors.white);
      expect(shape.borderRadius, BorderRadius.circular(24));
      expect(shape.side.color, AppTheme.primaryPurple);
      expect(shape.side.width, 1.5);
    });
  });
}
