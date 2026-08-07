part of '../status_panel.dart';

extension _StatusPanelSirenPart on _StatusPanelState {
  bool _isSirenActive(Map<String, dynamic> device) {
    return isConfirmedSirenActiveForUi(device);
  }

  bool _isSirenConnected(Map<String, dynamic> device) {
    return isSirenConnectedForUi(device);
  }

  Future<void> _muteHomeSiren() async {
    if (_mutingHomeSiren || !mounted) {
      return;
    }

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: Text(_strings.confirmStopSirenTitle()),
          content: Text(_strings.confirmStopSirenBody()),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext, false),
              child: Text(_strings.t("HỦY")),
            ),
            ElevatedButton.icon(
              onPressed: () => Navigator.pop(dialogContext, true),
              icon: const Icon(Icons.campaign_rounded),
              label: Text(_strings.stopSirenLabel()),
            ),
          ],
        );
      },
    );

    if (confirmed != true || !mounted) {
      return;
    }

    setState(() {
      _mutingHomeSiren = true;
    });

    final muted = await NotificationService.muteHomeSiren(
      homeId: widget.homeId,
      hubId: "",
    );

    if (!mounted) {
      return;
    }

    setState(() {
      _mutingHomeSiren = false;
    });

    if (muted) {
      showTopToast(
        context,
        _strings.sirenMutedShortMessage(),
        color: MaiYenColors.safe,
        icon: Icons.campaign_rounded,
      );
      return;
    }

    showTopToast(
      context,
      _strings.sirenStopUnavailableMessage(),
      color: MaiYenColors.danger,
      icon: Icons.error_outline_rounded,
    );
  }

  Widget _buildQuickSirenAction() {
    final cleanOwnerUid = widget.ownerUid.trim();
    final cleanHomeId = widget.homeId.trim();

    if (cleanOwnerUid.isEmpty || cleanHomeId.isEmpty) {
      return _quickSirenButton(
        hasSiren: false,
        sirenActive: false,
        sirenConnected: false,
      );
    }

    return StreamBuilder<DatabaseEvent>(
      stream: FirebaseDatabase.instance
          .ref("accounts/$cleanOwnerUid/homes/$cleanHomeId/devices")
          .onValue,
      builder: (context, snapshot) {
        final devices = safeMap(snapshot.data?.snapshot.value);
        var hasSiren = false;
        var sirenActive = false;
        var allSirensConnected = true;

        for (final value in devices.values) {
          final device = safeMap(value);
          final type = device["type"]?.toString().trim().toLowerCase();

          if (type != "siren") {
            continue;
          }

          hasSiren = true;

          if (!_isSirenConnected(device)) {
            allSirensConnected = false;
          }

          if (_isSirenActive(device)) {
            sirenActive = true;
          }
        }

        return _quickSirenButton(
          hasSiren: hasSiren,
          sirenActive: sirenActive,
          sirenConnected: hasSiren && allSirensConnected,
        );
      },
    );
  }

  void _showQuickSirenMessage({
    required String message,
    required Color color,
    required IconData icon,
  }) {
    showTopToast(context, message, color: color, icon: icon);
  }

  Future<void> _handleQuickSirenTap({
    required bool hasSiren,
    required bool sirenActive,
    required bool sirenConnected,
  }) async {
    if (_mutingHomeSiren || !mounted) {
      return;
    }

    if (!hasSiren) {
      _showQuickSirenMessage(
        message: _strings.noPhysicalSirenMessage(),
        color: MaiYenColors.textSecondary,
        icon: Icons.campaign_rounded,
      );
      return;
    }

    if (sirenActive) {
      await _muteHomeSiren();
      return;
    }

    if (!sirenConnected) {
      _showQuickSirenMessage(
        message: _strings.sirenConnectionIssueMessage(),
        color: MaiYenColors.warning,
        icon: Icons.wifi_off_rounded,
      );
      return;
    }

    _showQuickSirenMessage(
      message: _strings.sirenReadyMessage(),
      color: MaiYenColors.safe,
      icon: Icons.campaign_rounded,
    );
  }

  Widget _quickSirenButton({
    required bool hasSiren,
    required bool sirenActive,
    required bool sirenConnected,
  }) {
    final tooltip = !hasSiren
        ? _strings.noPhysicalSirenMessage()
        : sirenActive
        ? _strings.muteHomeSirenLabel()
        : !sirenConnected
        ? _strings.sirenConnectionIssueMessage()
        : _strings.sirenReadyMessage();

    return ValueListenableBuilder<bool>(
      valueListenable: EmergencyPulseTicker.phase,
      builder: (context, dangerPhase, child) {
        final color = !hasSiren
            ? MaiYenColors.textSecondary
            : sirenActive
            ? (dangerPhase ? MaiYenColors.danger : MaiYenColors.warning)
            : !sirenConnected
            ? MaiYenColors.warning
            : MaiYenColors.safe;

        return Tooltip(
          message: tooltip,
          child: Semantics(
            button: true,
            enabled: !_mutingHomeSiren,
            label: tooltip,
            child: Material(
              color: color.withValues(alpha: hasSiren ? 0.12 : 0.08),
              borderRadius: BorderRadius.circular(9),
              child: InkWell(
                onTap: _mutingHomeSiren
                    ? null
                    : () => _handleQuickSirenTap(
                        hasSiren: hasSiren,
                        sirenActive: sirenActive,
                        sirenConnected: sirenConnected,
                      ),
                borderRadius: BorderRadius.circular(9),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 320),
                  curve: Curves.easeInOut,
                  width: 35,
                  height: 33,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(9),
                    border: Border.all(
                      color: color.withValues(alpha: sirenActive ? 0.82 : 0.36),
                      width: sirenActive ? 1.15 : 1,
                    ),
                  ),
                  alignment: Alignment.center,
                  child: _mutingHomeSiren
                      ? SizedBox(
                          width: 15,
                          height: 15,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: color,
                          ),
                        )
                      : Icon(
                          !hasSiren
                              ? Icons.campaign_rounded
                              : sirenActive
                              ? Icons.campaign_rounded
                              : !sirenConnected
                              ? Icons.campaign_rounded
                              : Icons.campaign_rounded,
                          size: 22,
                          color: color,
                        ),
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildEnvironmentAction(String environment) {
    if (environment.isEmpty) {
      return const SizedBox.shrink();
    }

    return InkWell(
      onTap: widget.onEnvironmentTap,
      borderRadius: BorderRadius.circular(8),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 2, vertical: 3),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(
              Icons.thermostat_rounded,
              size: 15,
              color: MaiYenColors.textSecondary,
            ),
            const SizedBox(width: 3),
            Text(
              environment,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                fontSize: 11.2,
                height: 1,
                fontWeight: FontWeight.w800,
                color: MaiYenColors.textPrimary,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
