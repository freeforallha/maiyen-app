import 'dart:async';

import 'package:flutter/foundation.dart';

/// Một nguồn nhịp duy nhất cho toàn bộ UI cảnh báo Nguy hiểm.
///
/// Mọi widget cùng lắng nghe [phase], vì vậy HomeTab, StatusPanel,
/// cảm biến Nguy hiểm và còi vật lý đổi vàng/đỏ trong cùng một frame.
class EmergencyPulseTicker {
  EmergencyPulseTicker._();

  static const int intervalMilliseconds = 650;

  static final ValueNotifier<bool> phase =
      ValueNotifier<bool>(_currentPhase());

  static Timer? _alignmentTimer;
  static Timer? _periodicTimer;
  static bool _started = false;

  static bool _currentPhase() {
    return (DateTime.now().millisecondsSinceEpoch ~/ intervalMilliseconds)
        .isOdd;
  }

  static void ensureStarted() {
    if (_started) return;
    _started = true;

    _publishCurrentPhase();

    final now = DateTime.now().millisecondsSinceEpoch;
    final remainder = now % intervalMilliseconds;
    final delay = remainder == 0
        ? intervalMilliseconds
        : intervalMilliseconds - remainder;

    _alignmentTimer = Timer(Duration(milliseconds: delay), () {
      _publishCurrentPhase();
      _periodicTimer = Timer.periodic(
        const Duration(milliseconds: intervalMilliseconds),
        (_) => _publishCurrentPhase(),
      );
    });
  }

  static void _publishCurrentPhase() {
    final next = _currentPhase();
    if (phase.value != next) {
      phase.value = next;
    }
  }
}
