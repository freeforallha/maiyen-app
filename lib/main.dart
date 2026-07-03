import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';

import 'firebase_options.dart';
import 'app/safe_home_app.dart';
import 'services/notification_service.dart';
import 'services/platform/platform_bootstrap_service.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await PlatformBootstrapService.initializeBeforeFirebase();
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);

  await PlatformBootstrapService.activateAppCheck();

  PlatformBootstrapService.registerBackgroundHandlers();

  await NotificationService.init();

  runApp(SafeHomeApp());
}
