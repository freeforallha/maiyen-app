part of '../home_page.dart';

extension _SecurityAutoAway on _MaiYenState {
  int _normalizeSecurityModeRepeatMinutes(dynamic value) {
    return _homeAlarmSecurityService.normalizeSecurityModeRepeatMinutes(value);
  }

  Future<bool> setSecurityModeRepeatMinutes(int minutes) async {
    final homeId = selectedHome;
    final result = await _homeAlarmSecurityService.setSecurityModeRepeatMinutes(
      ownerUid: homeId.isEmpty ? "" : getHomeOwnerUid(),
      homeId: homeId,
      canManageHome: canManageHome(),
      minutes: minutes,
    );

    if (!mounted) {
      return result.status == HomeSecurityRepeatStatus.saved;
    }

    switch (result.status) {
      case HomeSecurityRepeatStatus.homeUnavailable:
        return false;
      case HomeSecurityRepeatStatus.noPermission:
        showTopToast(
          context,
          _strings.t(
            "Chỉ Chủ nhà hoặc Quản trị viên mới có quyền thay đổi lặp báo động",
          ),
          color: Colors.orange,
          icon: Icons.lock_outline_rounded,
        );
        return false;
      case HomeSecurityRepeatStatus.failed:
        if (mounted) {
          showTopToast(
            context,
            _strings.t("Không lưu được thời gian lặp báo động"),
            color: Colors.red,
            icon: Icons.error_outline_rounded,
          );
        }
        return false;
      case HomeSecurityRepeatStatus.saved:
        if (!mounted) {
          return true;
        }

        final normalized = result.normalizedMinutes;

        setState(() {
          final cachedHome = safeMap(homes[homeId]);
          cachedHome["securityModeRepeatMinutes"] = normalized;
          homes[homeId] = cachedHome;
        });

        showTopToast(
          context,
          _strings.homeSecurityRepeatToast(normalized),
          color: MaiYenColors.primary,
          icon: Icons.repeat_rounded,
        );

        return true;
    }
  }

  Future<void> setSecurityMode(String mode) async {
    final homeId = selectedHome;
    final currentHome = safeMap(homes[homeId]);
    final plan = _homeAlarmSecurityService.planSecurityModeChange(
      homeId: homeId,
      canManageHome: canManageHome(),
      isOwner: uid == getHomeOwnerUid(),
      mode: mode,
      currentHome: currentHome,
    );

    switch (plan.status) {
      case HomeSecurityModePlanStatus.homeUnavailable:
      case HomeSecurityModePlanStatus.unchanged:
        return;
      case HomeSecurityModePlanStatus.noPermission:
        showTopToast(
          context,
          _strings.t(
            "Chỉ Chủ nhà hoặc Quản trị viên mới có quyền thay đổi Chế độ Bảo vệ",
          ),
          color: Colors.orange,
          icon: Icons.lock_outline_rounded,
        );
        return;
      case HomeSecurityModePlanStatus.ownerRequired:
        showTopToast(
          context,
          _strings.t("Chỉ Chủ nhà mới có quyền bật chế độ Không bảo vệ"),
          color: Colors.orange,
          icon: Icons.lock_outline_rounded,
        );
        return;
      case HomeSecurityModePlanStatus.requiresUnprotectedConfirmation:
        final confirmed = await _confirmUnprotectedMode();

        if (!confirmed || !mounted) {
          return;
        }

        await WidgetsBinding.instance.endOfFrame;

        if (!mounted) {
          return;
        }

        final passwordConfirmed = await _reauthenticateForManualSecurityMode();

        if (!passwordConfirmed || !mounted) {
          return;
        }
        break;
      case HomeSecurityModePlanStatus.requiresManualConfirmation:
        final confirmed = await _confirmManualSecurityMode();

        if (!confirmed || !mounted) {
          return;
        }

        // Đợi dialog cảnh báo đóng hoàn toàn rồi mới mở dialog mật khẩu.
        await WidgetsBinding.instance.endOfFrame;

        if (!mounted) {
          return;
        }

        final passwordConfirmed = await _reauthenticateForManualSecurityMode();

        if (!passwordConfirmed || !mounted) {
          return;
        }
        break;
      case HomeSecurityModePlanStatus.ready:
        break;
    }

    final nextMode = plan.nextMode;

    if (nextMode == "normal" &&
        safeMap(currentHome["autoAway"])["enabled"] == true) {
      final confirmed = await showConfirmNormalModeWithAutoAwayDialog(
        context: context,
        strings: _strings,
      );

      if (!confirmed || !mounted) {
        return;
      }
    }

    final ownerUid = getHomeOwnerUid();
    final homeName = getHomeDisplayName(homeId);
    final actorName = userName.trim().isNotEmpty
        ? userName.trim()
        : FirebaseAuth.instance.currentUser?.email?.trim() ??
              _strings.t("Một thành viên");

    final saveResult = await _homeAlarmSecurityService.setSecurityMode(
      ownerUid: ownerUid,
      homeId: homeId,
      nextMode: nextMode,
    );

    if (!mounted) {
      return;
    }

    if (saveResult.status == HomeSecurityModeSaveStatus.failed) {
      showTopToast(
        context,
        _strings.t("Không thể thay đổi chế độ nhà"),
        color: Colors.red,
        icon: Icons.error_outline_rounded,
      );
      return;
    }

    setState(() {
      securityMode = nextMode;

      final cachedHome = safeMap(homes[homeId]);
      cachedHome["securityMode"] = nextMode;

      if (nextMode == "normal") {
        cachedHome.remove("securityModeSource");
      } else {
        cachedHome["securityModeSource"] = "manual";
      }

      homes[homeId] = cachedHome;
    });

    if (nextMode == "armed") {
      final notificationStatus = await _homeAlarmSecurityService
          .notifyManualSecurityModeEnabled(
            ownerUid: ownerUid,
            homeId: homeId,
            homeName: homeName,
            actorUid: uid,
            actorName: actorName,
            securityModeRepeatMinutes: plan.repeatMinutes,
          );

      if (notificationStatus == HomeSecurityNotificationStatus.failed) {
        if (mounted) {
          showTopToast(
            context,
            _strings.t("Đã bật Bảo vệ nhưng chưa gửi được thông báo"),
            color: Colors.orange,
            icon: Icons.notifications_off_outlined,
          );
        }

        return;
      }

      if (mounted) {
        showTopToast(
          context,
          _strings.t("Đã bật Chế độ Bảo vệ thủ công"),
          color: MaiYenColors.danger,
          icon: Icons.shield_rounded,
        );
      }

      return;
    }

    if (nextMode == "unprotected") {
      final notificationStatus = await _homeAlarmSecurityService
          .notifyUnprotectedModeEnabled(
            ownerUid: ownerUid,
            homeId: homeId,
            homeName: homeName,
            actorUid: uid,
            actorName: actorName,
          );

      if (!mounted) {
        return;
      }

      showTopToast(
        context,
        notificationStatus == HomeSecurityNotificationStatus.failed
            ? _strings.t(
                "Đã chuyển sang Không bảo vệ nhưng chưa gửi được thông báo",
              )
            : _strings.t("Đã chuyển nhà sang Không bảo vệ"),
        color: MaiYenColors.warning,
        icon: Icons.shield_outlined,
      );
      return;
    }

    final notificationStatus = await _homeAlarmSecurityService
        .notifyNormalModeEnabled(
          ownerUid: ownerUid,
          homeId: homeId,
          homeName: homeName,
          actorUid: uid,
          actorName: actorName,
        );

    if (mounted) {
      showTopToast(
        context,
        notificationStatus == HomeSecurityNotificationStatus.failed
            ? _strings.t(
                "Đã chuyển về Bình thường nhưng chưa gửi được thông báo",
              )
            : _strings.t("Đã chuyển nhà về Bình thường"),
        color: notificationStatus == HomeSecurityNotificationStatus.failed
            ? Colors.orange
            : MaiYenColors.safe,
        icon: Icons.shield_rounded,
      );
    }
  }

  Future<List<HomeAutoAwayMember>> _loadAutoAwayMembers({
    required String ownerUid,
    required String homeId,
  }) async {
    final db = FirebaseDatabase.instance;
    final membersByUid = <String, HomeAutoAwayMember>{};

    Map<String, dynamic> asStringMap(Object? value) {
      if (value is Map) {
        return Map<String, dynamic>.from(value);
      }

      return <String, dynamic>{};
    }

    try {
      final membersSnap = await db.ref(FirebasePaths.sharedByHome(homeId)).get();
      final membersData = asStringMap(membersSnap.value);

      for (final entry in membersData.entries) {
        final memberUid = entry.key.trim();

        if (memberUid.isEmpty) {
          continue;
        }

        final raw = asStringMap(entry.value);
        final email = raw['email']?.toString().trim() ?? '';
        final rawName = raw['name']?.toString().trim() ?? '';
        final name = rawName.isNotEmpty
            ? rawName
            : email.isNotEmpty
            ? email
            : memberUid;
        final role = memberUid == ownerUid
            ? 'owner'
            : raw['role']?.toString().trim() == 'admin'
            ? 'admin'
            : 'member';

        membersByUid[memberUid] = HomeAutoAwayMember(
          uid: memberUid,
          name: name,
          role: role,
          email: email,
          photoUrl: raw['photoUrl']?.toString().trim() ?? '',
        );
      }
    } catch (error) {
      safeDebugPrint('AUTO_AWAY_MEMBER_LIST_ERROR: $error');
    }

    if (!membersByUid.containsKey(ownerUid)) {
      var ownerName = ownerUid == uid ? userName.trim() : '';
      var ownerEmail = '';
      var ownerPhotoUrl = ownerUid == uid ? userPhotoUrl.trim() : '';

      try {
        final ownerDirectorySnap = await db.ref('userDirectory/$ownerUid').get();
        final ownerDirectory = asStringMap(ownerDirectorySnap.value);
        final directoryName = ownerDirectory['name']?.toString().trim() ?? '';
        final directoryEmail = ownerDirectory['email']?.toString().trim() ?? '';
        final directoryPhoto =
            ownerDirectory['photoUrl']?.toString().trim() ?? '';

        if (directoryName.isNotEmpty) {
          ownerName = directoryName;
        }
        if (directoryEmail.isNotEmpty) {
          ownerEmail = directoryEmail;
        }
        if (directoryPhoto.isNotEmpty) {
          ownerPhotoUrl = directoryPhoto;
        }
      } catch (error) {
        safeDebugPrint('AUTO_AWAY_OWNER_PROFILE_ERROR: $error');
      }

      if (ownerName.isEmpty) {
        ownerName = ownerEmail.isNotEmpty ? ownerEmail : _strings.owner;
      }

      membersByUid[ownerUid] = HomeAutoAwayMember(
        uid: ownerUid,
        name: ownerName,
        role: 'owner',
        email: ownerEmail,
        photoUrl: ownerPhotoUrl,
      );
    }

    // Dữ liệu sharedByHome cũ có thể thiếu chính tài khoản Admin đang mở nhà.
    // Bổ sung từ hồ sơ cục bộ để Admin vẫn xuất hiện trong danh sách lựa chọn,
    // còn Firebase Rules sẽ kiểm tra membership qua sharedHomes.
    final currentUid = uid.trim();
    if (currentUid.isNotEmpty && !membersByUid.containsKey(currentUid)) {
      final currentRole = getMyRole();
      final currentName = userName.trim().isNotEmpty
          ? userName.trim()
          : currentUid;

      membersByUid[currentUid] = HomeAutoAwayMember(
        uid: currentUid,
        name: currentName,
        role: currentUid == ownerUid ? 'owner' : currentRole,
        email: '',
        photoUrl: userPhotoUrl.trim(),
      );
    }

    final members = membersByUid.values.toList();

    int roleOrder(String role) {
      switch (role) {
        case 'owner':
          return 0;
        case 'admin':
          return 1;
        default:
          return 2;
      }
    }

    members.sort((first, second) {
      final roleCompare = roleOrder(first.role).compareTo(
        roleOrder(second.role),
      );

      if (roleCompare != 0) {
        return roleCompare;
      }

      return first.name.toLowerCase().compareTo(second.name.toLowerCase());
    });

    return members;
  }

  Future<void> openAutoAwaySetup() async {
    final homeId = selectedHome;

    if (homeId.isEmpty) {
      return;
    }

    if (!canManageHome()) {
      showTopToast(
        context,
        _strings.t('Bạn không có quyền thay đổi vị trí nhà'),
        color: Colors.orange,
        icon: Icons.lock_rounded,
      );
      return;
    }

    final ownerUid = getHomeOwnerUid();
    final currentHome = safeMap(homes[homeId]);
    final currentAutoAway = safeMap(currentHome['autoAway']);
    final pageContext = context;
    final members = await _loadAutoAwayMembers(
      ownerUid: ownerUid,
      homeId: homeId,
    );

    if (!mounted) {
      return;
    }

    double? readDouble(dynamic raw) {
      if (raw is num) {
        return raw.toDouble();
      }

      return double.tryParse(raw?.toString() ?? '');
    }

    Set<String> readParticipantUids() {
      final rawParticipants = safeMap(currentAutoAway['participantUids']);
      final validMemberUids = members.map((member) => member.uid).toSet();
      final selected = rawParticipants.entries
          .where((entry) => entry.value == true)
          .map((entry) => entry.key.toString().trim())
          .where(validMemberUids.contains)
          .toSet();

      if (selected.isEmpty) {
        selected.addAll(validMemberUids);
      }

      if (selected.isEmpty && ownerUid.isNotEmpty) {
        selected.add(ownerUid);
      }

      return selected;
    }

    Future<HomeAutoAwayLocation?> captureHomeLocation() async {
      try {
        final serviceEnabled = await Geolocator.isLocationServiceEnabled();

        if (!serviceEnabled) {
          if (!mounted) {
            return null;
          }

          showTopToast(
            context,
            _strings.t('Hãy bật GPS để đặt vị trí nhà'),
            color: Colors.orange,
            icon: Icons.location_off_rounded,
          );

          await Geolocator.openLocationSettings();
          return null;
        }

        var permission = await Geolocator.checkPermission();

        if (permission == LocationPermission.denied) {
          permission = await Geolocator.requestPermission();
        }

        if (permission == LocationPermission.denied) {
          if (!mounted) {
            return null;
          }

          showTopToast(
            context,
            _strings.t('Bạn chưa cấp quyền vị trí'),
            color: Colors.orange,
            icon: Icons.location_disabled_rounded,
          );
          return null;
        }

        if (permission == LocationPermission.deniedForever) {
          if (!mounted) {
            return null;
          }

          showTopToast(
            context,
            _strings.t('Hãy cấp quyền vị trí trong Cài đặt ứng dụng'),
            color: Colors.orange,
            icon: Icons.settings_rounded,
          );

          await Geolocator.openAppSettings();
          return null;
        }

        final position = await Geolocator.getCurrentPosition(
          locationSettings: const LocationSettings(
            accuracy: LocationAccuracy.high,
            timeLimit: Duration(seconds: 20),
          ),
        );

        if (!mounted) {
          return null;
        }

        return HomeAutoAwayLocation(
          latitude: position.latitude,
          longitude: position.longitude,
        );
      } catch (error) {
        if (!mounted) {
          return null;
        }

        showTopToast(
          context,
          _strings.sanitizeUserMessage(
            error.toString(),
            fallback: _strings.t('Không lấy được vị trí hiện tại'),
          ),
          color: Colors.red,
          icon: Icons.error_outline_rounded,
        );
        return null;
      }
    }

    final radiusMeters =
        int.tryParse(currentAutoAway['radiusMeters']?.toString() ?? '') ?? 150;

    await showHomeAutoAwaySheet(
      context: context,
      strings: _strings,
      initialEnabled: currentAutoAway['enabled'] == true,
      initialLatitude: readDouble(currentAutoAway['latitude']),
      initialLongitude: readDouble(currentAutoAway['longitude']),
      radiusMeters: radiusMeters.clamp(100, 1000).toInt(),
      members: members,
      initialParticipantUids: readParticipantUids(),
      onCaptureLocation: captureHomeLocation,
      onPickLocationOnMap:
          ({required latitude, required longitude, required radiusMeters}) {
            return showHomeAutoAwayMapPicker(
              context: pageContext,
              strings: _strings,
              initialLatitude: latitude,
              initialLongitude: longitude,
              radiusMeters: radiusMeters,
              onGetCurrentLocation: captureHomeLocation,
            );
          },
      onSave: (data) async {
        final allowedParticipantUids = members
            .map((member) => member.uid.trim())
            .where((memberUid) => memberUid.isNotEmpty)
            .toSet()
          ..add(ownerUid);

        // Chỉ ghi các UID đang thật sự thuộc nhà. Việc này loại bỏ UID cũ
        // còn sót trong cấu hình trước đây và tránh Firebase Rules từ chối cả
        // lần lưu của Owner lẫn Admin.
        final normalizedParticipantUids = data.participantUids
            .map((participantUid) => participantUid.trim())
            .where(
              (participantUid) =>
                  participantUid.isNotEmpty &&
                  allowedParticipantUids.contains(participantUid),
            )
            .toSet();

        if (normalizedParticipantUids.isEmpty && ownerUid.isNotEmpty) {
          normalizedParticipantUids.add(ownerUid);
        }

        final currentUserParticipates = normalizedParticipantUids.contains(uid);
        final hasLocation = data.latitude != null && data.longitude != null;
        final sortedParticipantUids = normalizedParticipantUids.toList()..sort();
        final clientUpdatedAt = DateTime.now().millisecondsSinceEpoch;
        final autoAwayData = <String, Object?>{
          'enabled': data.enabled,
          'radiusMeters': data.radiusMeters,
          'participantUids': {
            for (final participantUid in sortedParticipantUids)
              participantUid: true,
          },
          'updatedAt': clientUpdatedAt,
          'updatedBy': uid,
        };

        if (hasLocation) {
          autoAwayData['latitude'] = data.latitude;
          autoAwayData['longitude'] = data.longitude;
        }

        try {
          final autoAwayRef = FirebaseDatabase.instance.ref(
            'accounts/$ownerUid/homes/$homeId/autoAway',
          );

          await autoAwayRef.set(autoAwayData);

          if (!mounted) {
            return false;
          }

          setState(() {
            final cachedHome = safeMap(homes[homeId]);
            cachedHome['autoAway'] = Map<String, Object?>.from(autoAwayData);
            homes[homeId] = cachedHome;
          });

          unawaited(
            AutoAwayService.syncForHomes(
              uid: uid,
              homes: homes,
              force: true,
            ).catchError((Object error) {
              safeDebugPrint('AUTO_AWAY_SYNC_AFTER_SAVE_ERROR: $error');
            }),
          );
          unawaited(_syncAutoAwayLocationMonitoring());

          // Đóng sheet ngay sau khi Firebase đã lưu thành công. Xin quyền vị trí
          // chạy sau đó để hộp thoại hệ thống không làm người dùng tưởng nút Lưu
          // bị treo hoặc không hoạt động.
          unawaited(
            Future<void>.delayed(Duration.zero, () async {
              var backgroundPermissionReady = true;

              if (data.enabled && currentUserParticipates) {
                backgroundPermissionReady =
                    await AutoAwayService.ensureBackgroundPermission();
              }

              if (!mounted || !pageContext.mounted) {
                return;
              }

              final permissionRequired =
                  data.enabled &&
                  currentUserParticipates &&
                  !backgroundPermissionReady;

              showTopToast(
                pageContext,
                permissionRequired
                    ? _strings.autoAwaySavedPermissionRequired
                    : data.enabled
                    ? _strings.autoAwayEnabledForSelectedParticipants
                    : _strings.t(
                        'Đã tắt tự động Bảo vệ khi mọi người rời nhà',
                      ),
                color: permissionRequired
                    ? Colors.orange
                    : MaiYenColors.safe,
                icon: permissionRequired
                    ? Icons.location_disabled_rounded
                    : Icons.check_circle_rounded,
              );
            }),
          );
          return true;
        } on FirebaseException catch (error) {
          safeDebugPrint(
            'AUTO_AWAY_SAVE_FIREBASE_ERROR: '
            'code=${error.code} message=${error.message} '
            'ownerUid=$ownerUid homeId=$homeId actorUid=$uid '
            'participants=${sortedParticipantUids.join(',')}',
          );

          if (!mounted) {
            return false;
          }

          showTopToast(
            context,
            _strings.sanitizeUserMessage(
              error.message ?? error.toString(),
              fallback: _strings.t('Không lưu được cài đặt'),
            ),
            color: Colors.red,
            icon: Icons.error_outline_rounded,
          );
          return false;
        } catch (error) {
          safeDebugPrint('AUTO_AWAY_SAVE_ERROR: $error');

          if (!mounted) {
            return false;
          }

          showTopToast(
            context,
            _strings.sanitizeUserMessage(
              error.toString(),
              fallback: _strings.t('Không lưu được cài đặt'),
            ),
            color: Colors.red,
            icon: Icons.error_outline_rounded,
          );
          return false;
        }
      },
    );
  }

  bool _hasEnabledAutoAwayHome() {
    return _homeAutoAwayCoordinator.hasEnabledAutoAwayHome(homes);
  }

  void _refreshAutoAwayPresenceNow({
    Position? position,
    String event = 'foreground_check',
  }) {
    if (!mounted) return;

    _homeAutoAwayCoordinator.refreshPresenceNow(
      uid: uid,
      homes: homes,
      position: position,
      event: event,
    );
  }

  void _startAutoAwayPresenceRefreshTimer() {
    _homeAutoAwayCoordinator.startPresenceRefreshTimer(
      uid: uid,
      homesProvider: () => homes,
    );
  }

  Future<void> _syncAutoAwayLocationMonitoring() async {
    if (!mounted || uid.isEmpty) {
      return;
    }

    await _homeAutoAwayCoordinator.syncLocationMonitoring(
      uid: uid,
      homesProvider: () => homes,
    );
  }

}
