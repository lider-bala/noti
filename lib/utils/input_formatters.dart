import 'package:flutter/services.dart';

class AppInputFormatters {
  static final TextInputFormatter phoneDigitsOnly =
      FilteringTextInputFormatter.allow(RegExp(r'[0-9+]'));

  static final TextInputFormatter latinAndNumbersOnly =
      FilteringTextInputFormatter.allow(RegExp(r'[A-Za-z0-9]'));
}
