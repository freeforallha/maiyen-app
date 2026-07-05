import 'package:flutter/foundation.dart';

void safeDebugPrint(Object? message) {
  if (kDebugMode) {
    debugPrint(message?.toString());
  }
}
