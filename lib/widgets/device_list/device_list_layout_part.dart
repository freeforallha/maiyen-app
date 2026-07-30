part of '../device_list.dart';

extension _Layout on _DeviceListState {
  String _sirenAlertStatusText(AppStrings strings) {
    return strings.choose(
      vi: "Đang báo động",
      en: "Alarm active",
      zh: "警报正在响起",
      ko: "경보 작동 중",
      ja: "警報作動中",
      de: "Alarm aktiv",
      ru: "Тревога активна",
      fr: "Alarme active",
      es: "Alarma activa",
      id: "Alarm aktif",
      th: "สัญญาณเตือนทำงาน",
      ms: "Penggera aktif",
      fil: "Aktibo ang alarma",
      km: "សំឡេងរោទិ៍កំពុងដំណើរការ",
      my: "အချက်ပေးသံ လုပ်ဆောင်နေသည်",
      lo: "ສັນຍານເຕືອນໄພກຳລັງເຮັດວຽກ",
      ta: "அலாரம் செயல்பாட்டில் உள்ளது",
      pt: "Alarme ativo",
      tet: "Alarme ativu",
    );
  }

  Widget _deviceGridItem({
    required String sectionKey,
    required MapEntry<String, dynamic> entry,
    required double itemWidth,
    required bool compact,
    required AppStrings strings,
  }) {
    return SizedBox(
      width: itemWidth,
      child: _deviceCard(
        id: entry.key,
        d: safeMap(entry.value),
        compact: compact,
        strings: strings,
      ),
    );
  }

  Widget _animatedPositionedDeviceCard({
    required String sectionKey,
    required MapEntry<String, dynamic> entry,
    required int index,
    required double itemWidth,
    required double itemHeight,
    required double spacing,
    required bool compact,
    required AppStrings strings,
    required List<MapEntry<String, dynamic>> sourceEntries,
  }) {
    final deviceId = entry.key;
    final isDragging =
        _draggingSectionKey == sectionKey && _draggingDeviceId == deviceId;
    final safeIndex = index < 0 ? 0 : index;
    final isSectionDragging =
        _draggingSectionKey == sectionKey && _draggingDeviceId != null;
    final targetOffset = isDragging
        ? _draggingCardOffset
        : _deviceGridOffsetForIndex(
            index: safeIndex,
            itemWidth: itemWidth,
            itemHeight: itemHeight,
            spacing: spacing,
          );

    final card = SizedBox(
      width: itemWidth,
      height: itemHeight,
      child: _deviceGridItem(
        sectionKey: sectionKey,
        entry: entry,
        itemWidth: itemWidth,
        compact: compact,
        strings: strings,
      ),
    );

    final wrappedCard = isDragging
        ? Transform.scale(
            scale: _draggingDeviceDropping ? 1.0 : 1.012,
            child: Material(
              color: Colors.transparent,
              surfaceTintColor: Colors.transparent,
              elevation: _draggingDeviceDropping ? 0 : 7,
              shadowColor: Colors.black.withValues(alpha: 0.14),
              borderRadius: BorderRadius.circular(17),
              child: card,
            ),
          )
        : card;

    return AnimatedPositioned(
      key: ValueKey("device_positioned_${sectionKey}_$deviceId"),
      duration: isDragging
          ? (_draggingDeviceDropping
                ? const Duration(milliseconds: 340)
                : Duration.zero)
          : isSectionDragging
          ? const Duration(milliseconds: 270)
          : Duration.zero,
      curve: Curves.easeOutCubic,
      left: targetOffset.dx,
      top: targetOffset.dy,
      width: itemWidth,
      height: itemHeight,
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onLongPressStart: isDragging
            ? null
            : (details) {
                _startDeviceDrag(
                  sectionKey: sectionKey,
                  entries: sourceEntries,
                  deviceId: deviceId,
                  index: index,
                  itemWidth: itemWidth,
                  itemHeight: itemHeight,
                  spacing: spacing,
                  details: details,
                );
              },
        onLongPressMoveUpdate: (details) {
          _updateDeviceDrag(
            sectionKey: sectionKey,
            itemCount: sourceEntries.length,
            itemWidth: itemWidth,
            itemHeight: itemHeight,
            spacing: spacing,
            details: details,
          );
        },
        onLongPressEnd: (_) {
          unawaited(
            _finishDeviceDrag(
              sectionKey,
              itemWidth: itemWidth,
              itemHeight: itemHeight,
              spacing: spacing,
            ),
          );
        },
        onLongPressCancel: _cancelDeviceDrag,
        child: wrappedCard,
      ),
    );
  }

  Widget _reorderableDeviceSection({
    required String groupName,
    required List<MapEntry<String, dynamic>> entries,
    required double spacing,
    required double itemWidth,
    required bool compact,
    required AppStrings strings,
  }) {
    final sectionKey = _sectionKeyForGroup(groupName);
    final canReorder = _canReorderDevices && entries.length > 1;
    final itemHeight = _deviceGridItemHeight(compact, entries, strings);
    final visibleEntries = canReorder
        ? _dragPreviewEntries(sectionKey, entries)
        : entries;
    final rowCount = visibleEntries.length <= 2 ? 1 : 2;
    final columnCount = _twoRowHorizontalColumnCount(visibleEntries.length);
    final sectionHeight = visibleEntries.isEmpty
        ? 0.0
        : (rowCount * itemHeight) + ((rowCount - 1) * spacing);
    final sectionWidth = visibleEntries.isEmpty
        ? 0.0
        : (columnCount * itemWidth) + ((columnCount - 1) * spacing);
    final gridKey = _sectionGridKey(sectionKey);

    Widget buildStaticContent() {
      return SizedBox(
        width: sectionWidth,
        height: sectionHeight,
        child: Stack(
          key: gridKey,
          clipBehavior: Clip.none,
          children: [
            for (var index = 0; index < visibleEntries.length; index++)
              Positioned(
                left: _deviceGridOffsetForIndex(
                  index: index,
                  itemWidth: itemWidth,
                  itemHeight: itemHeight,
                  spacing: spacing,
                ).dx,
                top: _deviceGridOffsetForIndex(
                  index: index,
                  itemWidth: itemWidth,
                  itemHeight: itemHeight,
                  spacing: spacing,
                ).dy,
                width: itemWidth,
                height: itemHeight,
                child: _deviceGridItem(
                  sectionKey: sectionKey,
                  entry: visibleEntries[index],
                  itemWidth: itemWidth,
                  compact: compact,
                  strings: strings,
                ),
              ),
          ],
        ),
      );
    }

    Widget buildAnimatedContent() {
      final activeDraggingDeviceId = _draggingSectionKey == sectionKey
          ? _draggingDeviceId
          : null;
      final paintEntries = <MapEntry<String, dynamic>>[
        ...visibleEntries.where(
          (entry) => entry.key != activeDraggingDeviceId,
        ),
        if (activeDraggingDeviceId != null)
          ...visibleEntries.where(
            (entry) => entry.key == activeDraggingDeviceId,
          ),
      ];

      return SizedBox(
        width: sectionWidth,
        height: sectionHeight,
        child: Stack(
          key: gridKey,
          clipBehavior: Clip.none,
          children: [
            for (final entry in paintEntries)
              _animatedPositionedDeviceCard(
                sectionKey: sectionKey,
                entry: entry,
                index: visibleEntries.indexWhere(
                  (visibleEntry) => visibleEntry.key == entry.key,
                ),
                itemWidth: itemWidth,
                itemHeight: itemHeight,
                spacing: spacing,
                compact: compact,
                strings: strings,
                sourceEntries: entries,
              ),
          ],
        ),
      );
    }

    final content = canReorder
        ? buildAnimatedContent()
        : buildStaticContent();

    if (visibleEntries.length <= 4) {
      return SizedBox(
        key: ValueKey(
          "device-section-${canReorder ? 'animated' : 'static'}-${widget.homeId}-$selectedRoomId-$sectionKey",
        ),
        height: sectionHeight,
        child: content,
      );
    }

    return SizedBox(
      key: ValueKey(
        "device-section-horizontal-${widget.homeId}-$selectedRoomId-$sectionKey",
      ),
      height: sectionHeight,
      child: _horizontalDeviceFade(
        child: SingleChildScrollView(
          key: PageStorageKey<String>(
            "device-horizontal-${widget.homeId}-$selectedRoomId-$sectionKey",
          ),
          scrollDirection: Axis.horizontal,
          padding: const EdgeInsets.only(right: 34),
          child: content,
        ),
      ),
    );
  }

  Widget _addDeviceButton() {
    return Material(
      color: MaiYenColors.primarySoft,
      borderRadius: BorderRadius.circular(12),
      child: InkWell(
        onTap: onPairSensor,
        borderRadius: BorderRadius.circular(12),
        child: const SizedBox(
          width: 34,
          height: 34,
          child: Icon(
            Icons.add_rounded,
            size: 20,
            color: MaiYenColors.primary,
          ),
        ),
      ),
    );
  }

  Future<void> _openDeviceCategoryPage({
    required String groupName,
    required String title,
    required List<MapEntry<String, dynamic>> entries,
  }) async {
    if (entries.isEmpty || !mounted) {
      return;
    }

    final initialDevices = <String, dynamic>{
      for (final entry in entries) entry.key: entry.value,
    };
    final devicesRef = FirebaseDatabase.instance.ref(
      "accounts/$_ownerUid/homes/$_homeId/devices",
    );

    await MaiYenNavigation.pushChildPage<void>(
      context: context,
      routeName: "device_category_${_sectionKeyForGroup(groupName)}",
      builder: (pageContext) {
        final strings = AppStrings.of(pageContext);

        return ColoredBox(
          color: MaiYenColors.background,
          child: StreamBuilder<DatabaseEvent>(
            stream: devicesRef.onValue,
            builder: (context, snapshot) {
              final sourceDevices = snapshot.hasData
                  ? safeMap(snapshot.data?.snapshot.value)
                  : initialDevices;
              final categoryEntries = sourceDevices.entries.where((entry) {
                final device = safeMap(entry.value);
                final type = device["type"]?.toString() ?? "unknown";

                if (getDeviceGroup(type) != groupName) {
                  return false;
                }

                if (selectedRoomId == "overview") {
                  return true;
                }

                final roomId =
                    device["roomId"]?.toString().trim() ?? "unassigned";

                return roomId == selectedRoomId;
              }).toList();

              _sortDeviceEntries(
                _sectionKeyForGroup(groupName),
                categoryEntries,
              );

              return LayoutBuilder(
                builder: (context, constraints) {
                  final crossAxisCount = constraints.maxWidth >= 720
                      ? 9
                      : constraints.maxWidth >= 520
                      ? 7
                      : 5;

                  return CustomScrollView(
                    slivers: [
                      SliverPadding(
                        padding: const EdgeInsets.fromLTRB(20, 20, 20, 14),
                        sliver: SliverToBoxAdapter(
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.center,
                            children: [
                              Expanded(
                                child: Text(
                                  title,
                                  maxLines: 2,
                                  overflow: TextOverflow.ellipsis,
                                  style: const TextStyle(
                                    fontSize: 22,
                                    height: 1.05,
                                    fontWeight: FontWeight.w900,
                                    color: MaiYenColors.textPrimary,
                                    letterSpacing: -0.45,
                                  ),
                                ),
                              ),
                              const SizedBox(width: 12),
                              Container(
                                constraints: const BoxConstraints(
                                  minWidth: 38,
                                  minHeight: 32,
                                ),
                                alignment: Alignment.center,
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 10,
                                  vertical: 6,
                                ),
                                decoration: BoxDecoration(
                                  color: MaiYenColors.primarySoft,
                                  borderRadius: BorderRadius.circular(999),
                                ),
                                child: Text(
                                  categoryEntries.length.toString(),
                                  style: const TextStyle(
                                    fontSize: 12,
                                    height: 1,
                                    fontWeight: FontWeight.w900,
                                    color: MaiYenColors.primaryDark,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                      if (categoryEntries.isEmpty)
                        SliverFillRemaining(
                          hasScrollBody: false,
                          child: Center(
                            child: Text(
                              strings.t("Không có thiết bị"),
                              style: const TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.w700,
                                color: MaiYenColors.textSecondary,
                              ),
                            ),
                          ),
                        )
                      else
                        SliverPadding(
                          padding: const EdgeInsets.fromLTRB(12, 0, 12, 28),
                          sliver: SliverGrid(
                            gridDelegate:
                                SliverGridDelegateWithFixedCrossAxisCount(
                                  crossAxisCount: crossAxisCount,
                                  mainAxisSpacing: 6,
                                  crossAxisSpacing: 6,
                                  childAspectRatio: 1,
                                ),
                            delegate: SliverChildBuilderDelegate((
                              context,
                              index,
                            ) {
                              final entry = categoryEntries[index];

                              return _deviceCategorySquareCard(
                                id: entry.key,
                                device: safeMap(entry.value),
                                strings: strings,
                              );
                            }, childCount: categoryEntries.length),
                          ),
                        ),
                    ],
                  );
                },
              );
            },
          ),
        );
      },
    );
  }

  Widget _deviceCategorySquareCard({
    required String id,
    required Map<String, dynamic> device,
    required AppStrings strings,
  }) {
    final type = device["type"]?.toString().trim().toLowerCase() ?? "unknown";
    final rawName = device["name"]?.toString().trim() ?? "";
    final displayName = rawName.isEmpty ? id : rawName;
    final statusText = getMainStatus(device, strings);
    final connectionStatus = getConnectionStatus(device);
    final connectionColor = getConnectionColor(connectionStatus);
    final emergencyIsActive = _isEmergencyDeviceActiveForUi(id, device);
    final pulseColor = _sirenAlertPulseDanger
        ? MaiYenColors.danger
        : MaiYenColors.warning;
    final accentColor = emergencyIsActive
        ? pulseColor
        : getAccentColor(device);
    final cardColor = emergencyIsActive
        ? pulseColor.withValues(alpha: _sirenAlertPulseDanger ? 0.20 : 0.15)
        : MaiYenColors.surface;

    return Material(
      color: Colors.transparent,
      borderRadius: BorderRadius.circular(12),
      child: InkWell(
        onTap: () => onTapDevice(id),
        borderRadius: BorderRadius.circular(12),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 420),
          curve: Curves.easeInOut,
          padding: const EdgeInsets.fromLTRB(4, 3, 4, 3),
          decoration: BoxDecoration(
            color: cardColor,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: accentColor.withValues(
                alpha: emergencyIsActive ? 0.95 : 0.62,
              ),
              width: emergencyIsActive ? 1.5 : 1.15,
            ),
            boxShadow: [
              BoxShadow(
                color: accentColor.withValues(
                  alpha: emergencyIsActive ? 0.20 : 0.055,
                ),
                blurRadius: emergencyIsActive ? 14 : 8,
                offset: const Offset(0, 3),
              ),
            ],
          ),
          child: Stack(
            children: [
              Positioned(
                top: 0,
                right: 0,
                child: Container(
                  width: 5,
                  height: 5,
                  decoration: BoxDecoration(
                    color: connectionColor,
                    shape: BoxShape.circle,
                  ),
                ),
              ),
              Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      width: 23,
                      height: 23,
                      decoration: BoxDecoration(
                        color: accentColor.withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(7),
                      ),
                      child: Icon(
                        getDeviceIcon(type),
                        size: 13,
                        color: accentColor,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      displayName,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        fontSize: 8.2,
                        height: 1.0,
                        fontWeight: FontWeight.w900,
                        color: MaiYenColors.textPrimary,
                        letterSpacing: -0.12,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      statusText,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 7.0,
                        height: 1.0,
                        fontWeight: FontWeight.w800,
                        color: accentColor,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _sectionHeader({
    required String title,
    required int count,
    required bool showAddButton,
    VoidCallback? onTap,
  }) {
    return Padding(
      padding: const EdgeInsets.only(top: 0, bottom: 7),
      child: Row(
        children: [
          Expanded(
            child: Material(
              color: Colors.transparent,
              borderRadius: BorderRadius.circular(10),
              child: InkWell(
                onTap: onTap,
                borderRadius: BorderRadius.circular(10),
                child: Padding(
                  padding: const EdgeInsets.symmetric(vertical: 4),
                  child: Row(
                    children: [
                      Expanded(
                        child: Text.rich(
                          TextSpan(
                            children: [
                              TextSpan(
                                text: title,
                                style: const TextStyle(
                                  fontSize: 14.5,
                                  height: 1,
                                  fontWeight: FontWeight.w800,
                                  color: MaiYenColors.textPrimary,
                                  letterSpacing: -0.15,
                                ),
                              ),
                              TextSpan(
                                text: " ($count)",
                                style: const TextStyle(
                                  fontSize: 13,
                                  height: 1,
                                  fontWeight: FontWeight.w700,
                                  color: MaiYenColors.textSecondary,
                                ),
                              ),
                            ],
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      if (onTap != null) ...[
                        const SizedBox(width: 4),
                        const Icon(
                          Icons.chevron_right_rounded,
                          size: 20,
                          color: MaiYenColors.textSecondary,
                        ),
                      ],
                    ],
                  ),
                ),
              ),
            ),
          ),
          if (showAddButton) ...[
            const SizedBox(width: 6),
            _addDeviceButton(),
          ],
        ],
      ),
    );
  }

  Widget _emptySecurityState(AppStrings strings) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 12),
      child: Center(
        child: Text(
          strings.t(
            "Chưa có thiết bị, hãy nhấn nút + để thêm để bắt đầu duy trì an ninh",
          ),
          textAlign: TextAlign.center,
          style: const TextStyle(
            fontSize: 12.5,
            height: 1.35,
            fontWeight: FontWeight.w600,
            color: MaiYenColors.textSecondary,
          ),
        ),
      ),
    );
  }

}
