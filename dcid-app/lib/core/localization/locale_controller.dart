import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'app_locale.dart';
import 'app_strings.dart';

/// Riverpod Notifier for managing application language/locale.
class LocaleController extends Notifier<AppLocale> {
  @override
  AppLocale build() {
    // Defaults to Vietnamese as per industrial factory primary use case
    return AppLocale.vi;
  }

  /// Switch between Vietnamese and English
  void toggle() {
    state = state == AppLocale.vi ? AppLocale.en : AppLocale.vi;
  }

  /// Set explicit locale
  void setLocale(AppLocale locale) {
    state = locale;
  }
}

/// Global locale provider
final localeProvider =
    NotifierProvider<LocaleController, AppLocale>(LocaleController.new);

/// Provider exposing reactive localized strings
final appStringsProvider = Provider<AppStrings>((ref) {
  final locale = ref.watch(localeProvider);
  return AppStrings.of(locale);
});
