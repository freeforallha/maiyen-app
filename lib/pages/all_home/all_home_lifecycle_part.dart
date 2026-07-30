part of '../all_home_page.dart';

extension _AllHomeLifecyclePart on _AllHomeState {
  void _initializeAllHomePage() {
    summaryTimer = Timer.periodic(const Duration(seconds: 4), (_) {
      if (!mounted) return;

      setState(() {
        summaryIndex++;
      });
    });
    final currentUser = FirebaseAuth.instance.currentUser;

    if (currentUser == null) {
      return;
    }

    final uid = currentUser.uid;

    syncChatUnreadCounts();
    chatAuthSubscription = FirebaseAuth.instance.authStateChanges().listen((
      user,
    ) {
      if (!mounted) return;

      if (user == null) {
        _homeRealtimeCoordinator.dispose();
        _chatUnreadUid = "";

        if (unreadChatCounts.isNotEmpty) {
          setState(() {
            unreadChatCounts = {};
          });
        }

        return;
      }

      syncChatUnreadCounts();
    });

    ownHomesSubscription = FirebaseDatabase.instance
        .ref("accounts/$uid/homes")
        .onValue
        .listen((event) {
          final ownHomes = event.snapshot.value is Map
              ? Map<String, dynamic>.from(event.snapshot.value as Map)
              : <String, dynamic>{};

          if (!mounted) return;

          setState(() {
            homes.removeWhere((key, value) {
              final home = safeMap(value);
              return home["_shared"] != true;
            });

            for (final entry in ownHomes.entries) {
              homes[entry.key] = entry.value;
            }
          });
          notifyHomesChanged();
        });

    sharedHomesSubscription = FirebaseDatabase.instance
        .ref("accounts/$uid/sharedHomes")
        .onValue
        .listen((event) {
          final sharedHomes = event.snapshot.value is Map
              ? Map<String, dynamic>.from(event.snapshot.value as Map)
              : <String, dynamic>{};

          final activeIds = sharedHomes.keys.map((e) => e.toString()).toSet();

          for (final oldId in sharedHomeSubscriptions.keys.toList()) {
            if (!activeIds.contains(oldId)) {
              sharedHomeSubscriptions.remove(oldId)?.cancel();

              if (mounted) {
                setState(() {
                  homes.remove(oldId);
                });
                notifyHomesChanged();
              }
            }
          }

          for (final entry in sharedHomes.entries) {
            final homeId = entry.key.toString();
            final sharedInfo = safeMap(entry.value);

            final ownerUid = sharedInfo["ownerUid"]?.toString().trim() ?? "";

            final role = sharedInfo["role"]?.toString().trim() ?? "member";

            if (ownerUid.isEmpty) {
              continue;
            }

            if (sharedHomeSubscriptions.containsKey(homeId)) {
              continue;
            }

            final sub = FirebaseDatabase.instance
                .ref("accounts/$ownerUid/homes/$homeId")
                .onValue
                .listen(
                  (homeEvent) {
                    final rawHome = homeEvent.snapshot.value;

                    if (rawHome is! Map) {
                      if (!mounted) return;

                      setState(() {
                        homes.remove(homeId);
                      });
                      notifyHomesChanged();

                      return;
                    }

                    final newHome = {
                      ...Map<String, dynamic>.from(rawHome),
                      "_shared": true,
                      "_ownerUid": ownerUid,
                      "_ownerEmail": "",
                      "_ownerName": "",
                      "_ownerPhotoUrl": "",
                      "_role": role,
                    };

                    if (!mounted) return;

                    setState(() {
                      homes[homeId] = newHome;
                    });
                    notifyHomesChanged();
                  },
                  onError: (Object error) {
                    safeDebugPrint("ALL_HOME_SHARED_HOME_ERROR: $error");
                  },
                );

            sharedHomeSubscriptions[homeId] = sub;

            FirebaseDatabase.instance
                .ref("userDirectory/$ownerUid")
                .get()
                .then((directorySnap) {
                  final directory = safeMap(directorySnap.value);

                  final ownerEmail =
                      directory["email"]?.toString().trim() ?? "";

                  final ownerName = directory["name"]?.toString().trim() ?? "";

                  final ownerPhotoUrl =
                      directory["photoUrl"]?.toString().trim() ?? "";

                  if (!mounted) return;

                  setState(() {
                    final currentHome = safeMap(homes[homeId]);

                    if (currentHome.isEmpty) {
                      return;
                    }

                    homes[homeId] = {
                      ...currentHome,
                      "_ownerEmail": ownerEmail,
                      "_ownerName": ownerName,
                      "_ownerPhotoUrl": ownerPhotoUrl,
                      "_role": role,
                    };
                  });
                  notifyHomesChanged();
                })
                .catchError((Object error) {
                  safeDebugPrint("ALL_HOME_USER_DIRECTORY_ERROR: $error");
                });
          }
        });

    groupNamesSubscription = FirebaseDatabase.instance
        .ref("accounts/$uid/groupNames")
        .onValue
        .listen((event) {
          final names = event.snapshot.value is Map
              ? Map<String, String>.from(event.snapshot.value as Map)
              : <String, String>{};

          if (!mounted) return;

          setState(() {
            customNames = names;
          });
        });
  }

  void _disposeAllHomePageResources() {
    ownHomesSubscription?.cancel();
    sharedHomesSubscription?.cancel();
    groupNamesSubscription?.cancel();
    chatAuthSubscription?.cancel();
    _homeRealtimeCoordinator.dispose();
    unreadChatCounts.clear();

    for (final sub in sharedHomeSubscriptions.values) {
      sub.cancel();
    }

    sharedHomeSubscriptions.clear();
    summaryTimer?.cancel();
    _emergencyPulseTimer?.cancel();
    searchController.dispose();

    homesRevision.dispose();
  }
}
