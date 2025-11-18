import 'package:flutter/foundation.dart';

class IO {
  static void printFullText(String message) {
    if (kDebugMode) {
      debugPrint(message);
    }
  }
}
