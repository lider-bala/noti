import 'dart:ui';

enum AppLanguage {
  russian,
  kyrgyz;

  Locale get locale {
    switch (this) {
      case AppLanguage.russian:
        return const Locale('ru', 'KG');
      case AppLanguage.kyrgyz:
        return const Locale('ky', 'KG');
    }
  }

  String get code {
    switch (this) {
      case AppLanguage.russian:
        return 'ru';
      case AppLanguage.kyrgyz:
        return 'ky';
    }
  }

  String get shortLabel {
    switch (this) {
      case AppLanguage.russian:
        return 'RU';
      case AppLanguage.kyrgyz:
        return 'KG';
    }
  }
}
