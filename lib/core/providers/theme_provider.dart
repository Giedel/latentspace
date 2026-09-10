import 'package:flutter_riverpod/legacy.dart';

enum AppThemeChoice {
  system,
  defaultTheme,
  ocean,
  forest,
  sunset,
}

final themeChoiceProvider = StateProvider<AppThemeChoice>((ref) {
  return AppThemeChoice.defaultTheme;
});
