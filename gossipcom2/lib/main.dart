import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_app_check/firebase_app_check.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:gossipcom/firebase_options.dart';
import 'package:gossipcom/profile/edit_username/edit_username_provider.dart';
import 'package:gossipcom/profile/report/report_provider.dart';
import 'package:gossipcom/profile/report_user/report_user_provider.dart';
import 'package:gossipcom/profile/review/review_provider.dart';
import 'package:gossipcom/splashscreen.dart';
import 'package:gossipcom/themes/themes.dart';
import 'package:provider/provider.dart';
import 'dart:developer';

final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();

Future<void> _initializeFirebaseIfNeeded() async {
  if (Firebase.apps.isEmpty) {
    log('🔧 Firebase.apps is empty, initializing default app...');
    await Firebase.initializeApp(
      name: "Gossip.com",
      options: DefaultFirebaseOptions.currentPlatform,
    );
    log('✅ Firebase initialized.');
  } else {
    log(
        '⚠️ Firebase already initialized. apps: ${Firebase.apps.map((a) => a.name).toList()}');
  }
}

@pragma('vm:entry-point')
Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  log('🔵 Background message handler STARTED (id=${message.messageId})');
  log('🔕 Background Message: ${message.messageId}, data: ${message.data}');
}

Future<void> initFCM() async {
  await _initializeFirebaseIfNeeded();
  FirebaseMessaging messaging = FirebaseMessaging.instance;
  NotificationSettings settings = await messaging.requestPermission();

  if (settings.authorizationStatus == AuthorizationStatus.authorized) {
    log("✅ User granted permission");

    if (Firebase.apps.isEmpty) {
      await Firebase.initializeApp(
        name: "Gossip.com",
        options: DefaultFirebaseOptions.currentPlatform,
      );
      await getFirebaseMessagingToken(messaging);
    } else {
      await getFirebaseMessagingToken(messaging);
    }
  } else {
    log("❌ FCM permission not granted: ${settings.authorizationStatus}");
  }
}

Future<dynamic> getFirebaseMessagingToken(FirebaseMessaging messaging) async {
  try {
    String? token = await messaging.getToken();
    log("FCM token: $token");
    if (Firebase.apps.isNotEmpty) {
      String? userId = FirebaseAuth.instance.currentUser?.uid;
      if (userId != null && token != null) {
        await FirebaseFirestore.instance
            .collection('users')
            .doc(userId)
            .set({'fcmToken': token}, SetOptions(merge: true));
      } else {
        log("⚠️ UserId or Token is null. Skipping Firestore update.");
      }

      FirebaseMessaging.onMessage.listen((RemoteMessage message) {
        log(
            "Foreground Notification: ${message.notification?.title}, body: ${message.notification?.body}");
      });

      FirebaseMessaging.onMessageOpenedApp.listen((RemoteMessage message) {
        log("App opened from notification: ${message.data}");
      });
    }
  } catch (e) {
    log("❌ Error in getFirebaseMessagingToken: $e");
  }
}

Future<void> initFCMinAppNotification() async {
  await _initializeFirebaseIfNeeded();
  try {
    FirebaseMessaging messaging = FirebaseMessaging.instance;
    NotificationSettings settings = await messaging.requestPermission();

    if (settings.authorizationStatus == AuthorizationStatus.authorized) {
      String? token = await messaging.getToken();
      log("FCM token (in-app notification): $token");

      String? userId = FirebaseAuth.instance.currentUser?.uid;
      if (userId != null && token != null) {
        await FirebaseFirestore.instance
            .collection("users")
            .doc(userId)
            .collection("notification")
            .doc(userId)
            .set({'fcmToken': token}, SetOptions(merge: true));
      }
      FirebaseMessaging.onMessage.listen((RemoteMessage message) {
        log("In-app Notification received: ${message.data}");

        _showInAppNotification(message);
      });
    } else {
      log(
          "❌ In-app notification permission not granted: ${settings.authorizationStatus}");
    }
  } catch (e) {
    log("❌ Error in initFCMinAppNotification: $e");
  }
}

bool isAppInForeground = false;

void _showInAppNotification(RemoteMessage message) {
  if (isAppInForeground) {
    Fluttertoast.showToast(
      msg:
          "${message.notification?.title ?? ''}: ${message.notification?.body ?? ''}",
      backgroundColor: Colors.black87,
      textColor: Colors.white,
    );
  } else {
    showLocalNotificationPush(message);
  }
}

Future<void> showLocalNotificationPush(RemoteMessage message) async {
  final AndroidNotificationDetails androidDetails = AndroidNotificationDetails(
    message.notification?.title ?? '',
    message.notification?.body ?? '',
    importance: Importance.max,
    priority: Priority.high,
  );

  final NotificationDetails platformDetails =
      NotificationDetails(android: androidDetails);

  await flutterLocalNotificationsPlugin.show(
    DateTime.now().millisecondsSinceEpoch ~/ 1000,
    message.notification?.title ?? '',
    message.notification?.body ?? '',
    platformDetails,
  );
}

final FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin =
    FlutterLocalNotificationsPlugin();

Future<void> initLocalNotifications() async {
  const AndroidInitializationSettings androidInit =
      AndroidInitializationSettings('@mipmap/ic_launcher');

  const InitializationSettings initSettings =
      InitializationSettings(android: androidInit);

  await flutterLocalNotificationsPlugin.initialize(initSettings);
}

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  log('🔷 main() starting, checking Firebase initialization...');
  await _initializeFirebaseIfNeeded();

  FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);
// Initialize App Check with a debug provider for development
  await FirebaseAppCheck.instance.activate(
    // Use a debug provider for non-release builds
    androidProvider:
        kDebugMode ? AndroidProvider.debug : AndroidProvider.playIntegrity,
    appleProvider: kDebugMode ? AppleProvider.debug : AppleProvider.deviceCheck,
  );
  // Call this here or from Splashscreen:
  await initFCM();
  await initLocalNotifications();
  SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
    DeviceOrientation.portraitDown,
  ]);

  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => ReportProvider()),
        ChangeNotifierProvider(create: (_) => ReviewProvider()),
        ChangeNotifierProvider(create: (_) => EditUserNameProvider()),
        ChangeNotifierProvider(create: (_) => ReportUserProvider()),
      ],
      child: const MyApp(),
    ),
  );
}

class MyApp extends StatefulWidget {
  const MyApp({super.key});

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> with WidgetsBindingObserver {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    log("📱 App state: $state");

    if (state == AppLifecycleState.resumed) {
      log("🟢 APP IS FOREGROUND");
      isAppInForeground = true;
    } else if (state == AppLifecycleState.paused) {
      log("🟡 APP IS BACKGROUND");
      isAppInForeground = false;
    } else if (state == AppLifecycleState.inactive) {
      log("⚪ APP IS INACTIVE");
      isAppInForeground = false;
    } else if (state == AppLifecycleState.detached) {
      log("🔴 APP IS DETACHED (about to close)");
      isAppInForeground = false;
    }
  }

  @override
  Widget build(BuildContext context) {
    return ScreenUtilInit(
      designSize: const Size(375, 812),
      minTextAdapt: true,
      splitScreenMode: true,
      builder: (context, child) {
        final mediaQuery = MediaQuery.of(context);
        final scaleFactor = mediaQuery.textScaler.clamp(minScaleFactor: 1.0, maxScaleFactor: 1.2);
        return MediaQuery(
          data: mediaQuery.copyWith(textScaler: scaleFactor),
          child: MaterialApp(
            navigatorKey: navigatorKey,
            debugShowCheckedModeBanner: false,
            theme: lightTheme,
            darkTheme: darkTheme,
            home: const Splashscreen(),
          ),
        );
      },
    );
  }
}
