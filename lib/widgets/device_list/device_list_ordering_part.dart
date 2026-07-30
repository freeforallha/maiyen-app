part of '../device_list.dart';

extension _Ordering on _DeviceListState {
  bool _sameDeviceOrder(Map<String, int> a, Map<String, int> b) {
    if (a.length != b.length) {
      return false;
    }

    for (final entry in a.entries) {
      if (b[entry.key] != entry.value) {
        return false;
      }
    }

    return true;
  }

  Map<String, int> _effectiveSectionOrders(String sectionKey) {
    return <String, int>{
      ...?_deviceOrderMap[sectionKey],
      ...?_localDeviceOrderMap[sectionKey],
      ...?_optimisticDeviceOrderMap[sectionKey],
    };
  }

  String _sectionKeyForGroup(String groupName) {
    switch (groupName) {
      case "An ninh ra/vào":
        return "access";
      case "Nguy hiểm khẩn cấp":
        return "emergency";
      case "Điều khiển & hạ tầng":
        return "infrastructure";
      case "Môi trường":
        return "environment";
      default:
        return "other";
    }
  }

  int _deviceOrderOf(String sectionKey, String deviceId, int fallbackIndex) {
    return _effectiveSectionOrders(sectionKey)[deviceId] ??
        (1000000 + fallbackIndex);
  }

  String _deviceSortName(MapEntry<String, dynamic> entry) {
    final d = safeMap(entry.value);
    final name = d["name"]?.toString().trim() ?? "";

    return name.isNotEmpty ? name.toLowerCase() : entry.key.toLowerCase();
  }

  void _sortDeviceEntries(
    String sectionKey,
    List<MapEntry<String, dynamic>> entries,
  ) {
    final fallbackIndexes = <String, int>{};
    final sectionOrders = _effectiveSectionOrders(sectionKey);

    for (var i = 0; i < entries.length; i++) {
      fallbackIndexes[entries[i].key] = i;
    }

    entries.sort((a, b) {
      final aOrder = sectionOrders[a.key];
      final bOrder = sectionOrders[b.key];

      if (aOrder != null || bOrder != null) {
        final orderCompare =
            _deviceOrderOf(
              sectionKey,
              a.key,
              fallbackIndexes[a.key] ?? 0,
            ).compareTo(
              _deviceOrderOf(sectionKey, b.key, fallbackIndexes[b.key] ?? 0),
            );

        if (orderCompare != 0) {
          return orderCompare;
        }
      }

      final nameCompare = _deviceSortName(a).compareTo(_deviceSortName(b));

      if (nameCompare != 0) {
        return nameCompare;
      }

      return a.key.compareTo(b.key);
    });
  }

  String _deviceOrderPath(String sectionKey, String deviceId) {
    return "accounts/$_currentUid/${_DeviceListState._deviceOrderRoot}/$_homeId/$sectionKey/$deviceId";
  }

  GlobalKey _sectionGridKey(String sectionKey) {
    return _sectionGridKeys.putIfAbsent(
      sectionKey,
      () => GlobalKey(debugLabel: "device_grid_$sectionKey"),
    );
  }

  void _clearDeviceDragState() {
    _deviceDropTimer?.cancel();
    _deviceDropTimer = null;
    _draggingDeviceId = null;
    _draggingSectionKey = null;
    _draggingSectionOrder = null;
    _draggingCardOffset = Offset.zero;
    _draggingPointerOffset = Offset.zero;
    _draggingDeviceDropping = false;
  }

  double _deviceGridItemHeight(
    bool compact,
    List<MapEntry<String, dynamic>> entries,
    AppStrings strings,
  ) {
    // Font Myanmar có phần glyph cao hơn một chút. Chừa riêng 1 px để
    // tránh RenderFlex overflow 0.x px mà không làm thay đổi UI ngôn ngữ khác.
    final localeHeightExtra = strings.isBurmese ? 1.0 : 0.0;

    final hasActiveSiren = entries.any((entry) {
      final device = safeMap(entry.value);
      final type = device["type"]?.toString() ?? "";

      return type == "siren" && isConfirmedSirenActiveForUi(device);
    });
    if (hasActiveSiren) {
      return (compact ? 106.0 : 114.0) + localeHeightExtra;
    }

    // Nút xác nhận thay thế đúng vùng trạng thái phía dưới, không được
    // làm thay đổi chiều cao của ô thiết bị khi xuất hiện hoặc biến mất.
    // Giữ card gọn như layout cũ nhưng chừa dư rất nhẹ
    // để Column bên trong không bị overflow 0.x pixels.
    return (compact ? 70.0 : 75.0) + localeHeightExtra;
  }

  Offset _deviceGridOffsetForIndex({
    required int index,
    required double itemWidth,
    required double itemHeight,
    required double spacing,
  }) {
    // Giữ cách đọc quen thuộc theo từng cụm 2 cột x 2 hàng:
    // 0 1 | 4 5 | ...
    // 2 3 | 6 7 | ...
    // Khi vượt quá 4 thiết bị, cụm tiếp theo kéo dài sang bên phải.
    final pageIndex = index ~/ 4;
    final indexInPage = index % 4;
    final column = (pageIndex * 2) + (indexInPage % 2);
    final row = indexInPage ~/ 2;

    return Offset(
      column * (itemWidth + spacing),
      row * (itemHeight + spacing),
    );
  }

  int _twoRowHorizontalColumnCount(int itemCount) {
    if (itemCount <= 0) {
      return 0;
    }

    final fullPages = itemCount ~/ 4;
    final remainder = itemCount % 4;
    final remainderColumns = remainder == 0
        ? 0
        : remainder == 1
        ? 1
        : 2;

    return (fullPages * 2) + remainderColumns;
  }

  Widget _horizontalDeviceFade({required Widget child}) {
    return ShaderMask(
      shaderCallback: (rect) {
        return const LinearGradient(
          begin: Alignment.centerLeft,
          end: Alignment.centerRight,
          colors: [
            Colors.transparent,
            Colors.white,
            Colors.white,
            Colors.transparent,
          ],
          stops: [0.0, 0.025, 0.93, 1.0],
        ).createShader(rect);
      },
      blendMode: BlendMode.dstIn,
      child: child,
    );
  }

  int _nearestDeviceGridIndex({
    required Offset pointer,
    required int itemCount,
    required double itemWidth,
    required double itemHeight,
    required double spacing,
  }) {
    if (itemCount <= 1) {
      return 0;
    }

    var bestIndex = 0;
    var bestDistance = double.infinity;

    for (var i = 0; i < itemCount; i++) {
      final topLeft = _deviceGridOffsetForIndex(
        index: i,
        itemWidth: itemWidth,
        itemHeight: itemHeight,
        spacing: spacing,
      );

      final center = topLeft + Offset(itemWidth / 2, itemHeight / 2);
      final distance = (center - pointer).distance;

      if (distance < bestDistance) {
        bestDistance = distance;
        bestIndex = i;
      }
    }

    return bestIndex;
  }

  List<MapEntry<String, dynamic>> _dragPreviewEntries(
    String sectionKey,
    List<MapEntry<String, dynamic>> entries,
  ) {
    final dragOrder = _draggingSectionOrder;

    if (_draggingSectionKey != sectionKey || dragOrder == null) {
      return entries;
    }

    final byId = {for (final entry in entries) entry.key: entry};

    final ordered = <MapEntry<String, dynamic>>[];

    for (final id in dragOrder) {
      final entry = byId.remove(id);

      if (entry != null) {
        ordered.add(entry);
      }
    }

    ordered.addAll(byId.values);
    return ordered;
  }

  void _startDeviceDrag({
    required String sectionKey,
    required List<MapEntry<String, dynamic>> entries,
    required String deviceId,
    required int index,
    required double itemWidth,
    required double itemHeight,
    required double spacing,
    required LongPressStartDetails details,
  }) {
    if (!_canReorderDevices || entries.length <= 1) {
      return;
    }

    final gridKey = _sectionGridKey(sectionKey);
    final renderObject = gridKey.currentContext?.findRenderObject();

    if (renderObject is! RenderBox) {
      return;
    }

    final pointer = renderObject.globalToLocal(details.globalPosition);
    final itemOffset = _deviceGridOffsetForIndex(
      index: index,
      itemWidth: itemWidth,
      itemHeight: itemHeight,
      spacing: spacing,
    );

    _deviceDropTimer?.cancel();
    _deviceDropTimer = null;

    setState(() {
      _draggingSectionKey = sectionKey;
      _draggingDeviceId = deviceId;
      _draggingSectionOrder = entries.map((entry) => entry.key).toList();
      _draggingPointerOffset = pointer - itemOffset;
      _draggingCardOffset = itemOffset;
      _draggingDeviceDropping = false;
    });
  }

  void _updateDeviceDrag({
    required String sectionKey,
    required int itemCount,
    required double itemWidth,
    required double itemHeight,
    required double spacing,
    required LongPressMoveUpdateDetails details,
  }) {
    final draggingDeviceId = _draggingDeviceId;
    final dragOrder = _draggingSectionOrder;

    if (draggingDeviceId == null ||
        dragOrder == null ||
        _draggingSectionKey != sectionKey ||
        _draggingDeviceDropping) {
      return;
    }

    final gridKey = _sectionGridKey(sectionKey);
    final renderObject = gridKey.currentContext?.findRenderObject();

    if (renderObject is! RenderBox) {
      return;
    }

    final pointer = renderObject.globalToLocal(details.globalPosition);
    final cardOffset = pointer - _draggingPointerOffset;
    final targetIndex = _nearestDeviceGridIndex(
      pointer: pointer,
      itemCount: itemCount,
      itemWidth: itemWidth,
      itemHeight: itemHeight,
      spacing: spacing,
    );

    final nextOrder = List<String>.from(dragOrder);
    nextOrder.remove(draggingDeviceId);

    final insertIndex = targetIndex.clamp(0, nextOrder.length);
    nextOrder.insert(insertIndex, draggingDeviceId);

    if (_sameStringList(nextOrder, dragOrder) &&
        (cardOffset - _draggingCardOffset).distance < 0.5) {
      return;
    }

    setState(() {
      _draggingCardOffset = cardOffset;
      _draggingSectionOrder = nextOrder;
    });
  }

  bool _sameStringList(List<String> a, List<String> b) {
    if (a.length != b.length) {
      return false;
    }

    for (var i = 0; i < a.length; i++) {
      if (a[i] != b[i]) {
        return false;
      }
    }

    return true;
  }

  Future<void> _finishDeviceDrag(
    String sectionKey, {
    required double itemWidth,
    required double itemHeight,
    required double spacing,
  }) async {
    final finalOrder = _draggingSectionOrder;
    final draggingDeviceId = _draggingDeviceId;
    final draggingSectionKey = _draggingSectionKey;

    if (finalOrder == null ||
        draggingDeviceId == null ||
        draggingSectionKey != sectionKey) {
      if (mounted) {
        setState(_clearDeviceDragState);
      }

      return;
    }

    final finalIndex = finalOrder.indexOf(draggingDeviceId);
    final finalOffset = finalIndex < 0
        ? _draggingCardOffset
        : _deviceGridOffsetForIndex(
            index: finalIndex,
            itemWidth: itemWidth,
            itemHeight: itemHeight,
            spacing: spacing,
          );

    final updatedOptimisticOrder = _copyDeviceOrderMap(
      _optimisticDeviceOrderMap,
    );
    final updatedLocalOrder = _copyDeviceOrderMap(_localDeviceOrderMap);
    final sectionOrder = Map<String, int>.from(
      _effectiveSectionOrders(sectionKey),
    );

    for (var i = 0; i < finalOrder.length; i++) {
      sectionOrder[finalOrder[i]] = i * 10;
    }

    updatedOptimisticOrder[sectionKey] = sectionOrder;
    updatedLocalOrder[sectionKey] = sectionOrder;

    if (mounted) {
      setState(() {
        _optimisticDeviceOrderMap = updatedOptimisticOrder;
        _localDeviceOrderMap = updatedLocalOrder;
        _draggingCardOffset = finalOffset;
        _draggingDeviceDropping = true;
      });

      _deviceDropTimer?.cancel();
      _deviceDropTimer = Timer(const Duration(milliseconds: 350), () {
        if (!mounted ||
            _draggingDeviceId != draggingDeviceId ||
            _draggingSectionKey != sectionKey) {
          return;
        }

        setState(_clearDeviceDragState);
      });
    }

    unawaited(
      _saveLocalDeviceOrder(
        uid: _currentUid,
        homeId: _homeId,
        orderMap: updatedLocalOrder,
      ),
    );

    final updates = <String, Object?>{};

    for (var i = 0; i < finalOrder.length; i++) {
      updates[_deviceOrderPath(sectionKey, finalOrder[i])] = i * 10;
    }

    try {
      await FirebaseDatabase.instance.ref().update(updates);
    } catch (_) {
      // Nếu Firebase Rules chưa mở deviceOrder, thứ tự vẫn được giữ local
      // trên máy này bằng SharedPreferences.
    }
  }

  void _cancelDeviceDrag() {
    if (!mounted) {
      return;
    }

    setState(_clearDeviceDragState);
  }

  List<MapEntry<String, dynamic>> _groupEntries(String groupName) {
    final sectionKey = _sectionKeyForGroup(groupName);
    final entries = devices.entries.where((entry) {
      final d = safeMap(entry.value);
      final type = d["type"]?.toString() ?? "door";

      if (getDeviceGroup(type) != groupName) {
        return false;
      }

      if (selectedRoomId == "overview") {
        return true;
      }

      final roomId = d["roomId"]?.toString() ?? "unassigned";

      return roomId == selectedRoomId;
    }).toList();

    _sortDeviceEntries(sectionKey, entries);

    return entries;
  }

}
