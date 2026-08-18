import 'package:flutter/material.dart';

enum AppLocale {
  vi('vi', 'Tiếng Việt', 'VI'),
  en('en', 'English', 'EN');

  const AppLocale(this.code, this.displayName, this.shortCode);

  final String code;
  final String displayName;
  final String shortCode;

  bool get isVietnamese => this == AppLocale.vi;
  bool get isEnglish => this == AppLocale.en;
  Locale get flutterLocale => Locale(code);
}
