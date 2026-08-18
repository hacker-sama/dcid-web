import 'package:flutter/material.dart';

enum AppLocale {
  vi('vi', 'Tiếng Việt', 'VI', '🇻🇳', 'Tiếng Việt'),
  en('en', 'English', 'EN', '🇺🇸', 'English'),
  hi('hi', 'हिन्दी', 'HI', '🇮🇳', 'Hindi'),
  ja('ja', '日本語', 'JA', '🇯🇵', 'Japanese');

  const AppLocale(
    this.code,
    this.displayName,
    this.shortCode,
    this.flag,
    this.englishName,
  );

  final String code;
  final String displayName;
  final String shortCode;
  final String flag;
  final String englishName;

  bool get isVietnamese => this == AppLocale.vi;
  bool get isEnglish => this == AppLocale.en;
  bool get isHindi => this == AppLocale.hi;
  bool get isJapanese => this == AppLocale.ja;
  Locale get flutterLocale => Locale(code);
}
