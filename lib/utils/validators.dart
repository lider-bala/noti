import 'package:flutter/widgets.dart';

import '../app/app_state.dart';

class InputValidators {
  static final RegExp _emailPattern =
      RegExp(r'^[\w.!#%&’*+/=?`{|}~^-]+@[\w.-]+\.[A-Za-z]{2,}$');
  static final RegExp _phonePattern = RegExp(r'^\+?[0-9]{10,15}$');
  static final RegExp _latinPassword = RegExp(r'^[A-Za-z0-9]+$');

  static String? validateFullName(BuildContext context, String? value) {
    if (value == null || value.trim().isEmpty) {
      return context.tr('Введите имя');
    }
    if (value.trim().length < 3) {
      return context.tr('Слишком короткое имя');
    }
    return null;
  }

  static String? validateEmail(BuildContext context, String? value) {
    if (value == null || value.trim().isEmpty) {
      return null;
    }
    if (!_emailPattern.hasMatch(value.trim())) {
      return context.tr('Некорректный email');
    }
    return null;
  }

  static String? validateRequiredEmail(BuildContext context, String? value) {
    final email = value?.trim() ?? '';
    if (email.isEmpty) {
      return context.tr('Введите email');
    }
    return validateEmail(context, email);
  }

  static String? validatePhone(BuildContext context, String? value) {
    if (value == null || value.trim().isEmpty) {
      return context.tr('Введите номер телефона');
    }
    final digitsOnly = value.replaceAll(RegExp('[^0-9+]'), '');
    if (!_phonePattern.hasMatch(digitsOnly)) {
      return context.tr('Только цифры, 10-15 символов');
    }
    return null;
  }

  static String? validatePassword(BuildContext context, String? value) {
    if (value == null || value.isEmpty) {
      return context.tr('Введите пароль');
    }
    if (!_latinPassword.hasMatch(value)) {
      return context.tr('Только латиница и цифры');
    }
    if (value.length < 6) {
      return context.tr('Минимум 6 символов');
    }
    return null;
  }

  static String? validatePasswordConfirmation(
    BuildContext context,
    String? confirmation,
    String original,
  ) {
    if (confirmation == null || confirmation.isEmpty) {
      return context.tr('Повторите пароль');
    }
    if (confirmation != original) {
      return context.tr('Пароли не совпадают');
    }
    return null;
  }
}
