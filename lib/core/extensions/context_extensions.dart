import 'package:flutter/material.dart';
import 'package:gamdo/l10n/app_localizations.dart';

extension BuildContextExtensions on BuildContext {
  ThemeData get theme => Theme.of(this);
  TextTheme get textTheme => Theme.of(this).textTheme;
  ColorScheme get colorScheme => Theme.of(this).colorScheme;
  MediaQueryData get mediaQuery => MediaQuery.of(this);
  Size get screenSize => MediaQuery.sizeOf(this);
  AppLocalizations get l10n => AppLocalizations.of(this)!;
  bool get isDarkMode => Theme.of(this).brightness == Brightness.dark;
}
