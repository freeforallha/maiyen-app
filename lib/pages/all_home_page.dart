import 'dart:async';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:flutter/material.dart';
import 'package:qr_flutter/qr_flutter.dart';
import '../helpers/top_toast.dart';
import '../helpers/home_helper.dart';
import '../maiyen_theme.dart';
import '../localization/app_strings.dart';
import '../services/home_realtime_coordinator.dart';
import 'package:maiyen_app/helpers/debug_log.dart';
import '../navigation/maiyen_navigation.dart';
import '../config/maiyen_identifiers.dart';
import '../widgets/maiyen_wordmark.dart';

part 'all_home/all_home_lifecycle_part.dart';
part 'all_home/all_home_summary_realtime_part.dart';
part 'all_home/all_home_grouping_part.dart';
part 'all_home/all_home_cards_part.dart';
part 'all_home/all_home_alarm_time_part.dart';
part 'all_home/all_home_alarm_config_part.dart';
part 'all_home/all_home_bulk_alarm_part.dart';
part 'all_home/all_home_sharing_part.dart';
part 'all_home/all_home_delete_part.dart';
part 'all_home/all_home_layout_part.dart';

class AllHome extends StatefulWidget {
  final List<String> homeOrder;

  const AllHome({super.key, required this.homeOrder});

  @override
  State<AllHome> createState() => _AllHomeState();
}

class _AllHomeState extends State<AllHome> {
  AppStrings get _strings => AppStrings.of(context);
  Map<String, dynamic> homes = {};
  Map<String, int> unreadChatCounts = {};
  final HomeRealtimeCoordinator _homeRealtimeCoordinator =
      HomeRealtimeCoordinator();
  String _chatUnreadUid = "";
  final ValueNotifier<int> homesRevision = ValueNotifier<int>(0);

  Set<String> selectedHomes = {};

  Map<String, String> customNames = {};
  String search = "";
  final TextEditingController searchController = TextEditingController();
  bool isSearching = false;
  int summaryIndex = 0;
  Timer? summaryTimer;
  Timer? _emergencyPulseTimer;
  bool _emergencyPulseDanger = false;

  StreamSubscription<DatabaseEvent>? ownHomesSubscription;
  StreamSubscription<DatabaseEvent>? sharedHomesSubscription;
  StreamSubscription<DatabaseEvent>? groupNamesSubscription;
  StreamSubscription<User?>? chatAuthSubscription;

  final Map<String, StreamSubscription<DatabaseEvent>> sharedHomeSubscriptions =
      {};

  @override
  void initState() {
    super.initState();
    _initializeAllHomePage();
  }

  @override
  Widget build(BuildContext context) => _buildAllHomePage(context);

  @override
  void dispose() {
    _disposeAllHomePageResources();
    super.dispose();
  }
}
