import 'package:firebase_core/firebase_core.dart';
import 'firebase_options.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_native_splash/flutter_native_splash.dart';
import 'package:webview_flutter/webview_flutter.dart';
import 'dart:developer';

String baseUrl = "https://profcosmetik.com/";
String url = baseUrl;

WebViewController? controller;

void main() async {
  await initialization(null);
  FlutterNativeSplash.removeAfter(initialization);

  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

  final fcmToken = await FirebaseMessaging.instance.getToken();
  log('FCM token messaging token: $fcmToken');

  FirebaseMessaging messaging = FirebaseMessaging.instance;

  NotificationSettings settings = await messaging.requestPermission(
    alert: true,
    announcement: false,
    badge: true,
    carPlay: false,
    criticalAlert: false,
    provisional: false,
    sound: true,
  );

  FirebaseMessaging.onBackgroundMessage(firebaseMessagingBackgroundHandler);

  runApp(
    const MaterialApp(
      home: WebViewApp(),
    ),
  );
}

Future initialization(BuildContext? context) async {
  await Future.delayed(const Duration(seconds: 3));
}

Future<void> firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  await Firebase.initializeApp();
}

class WebViewApp extends StatefulWidget {
  const WebViewApp({Key? key}) : super(key: key);

  @override
  State<WebViewApp> createState() => _WebViewAppState();
}

class _WebViewAppState extends State<WebViewApp> {
  @override
  void initState() {
    super.initState();

    FirebaseMessaging.onMessageOpenedApp.listen((RemoteMessage message) async {
      log('URL: $url');
      log('RemoteMessage: ${message.notification?.body}');

      var messageNotification = message.notification?.body ?? "";
      var urlFromNotification = getURLFromMessage(messageNotification);

      if (urlFromNotification != "") {
        url = urlFromNotification;
      } else {
        url = baseUrl;
      }

      setState(() {
        controller?.loadUrl(url);
      });

      log('URL: $url');
    });
  }

  String getURLFromMessage(String message) {
    RegExp exp = RegExp(r'(?:(?:https?|ftp):\/\/)?[\w/\-?=%.]+\.[\w/\-?=%.]+');
    Iterable<RegExpMatch> matches = exp.allMatches(message);

    for (var match in matches) {
      return message.substring(match.start, match.end);
    }
    return "";
  }

  @override
  Widget build(BuildContext context) {
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersiveSticky);

    return WebView(
        initialUrl: url,
        javascriptMode: JavascriptMode.unrestricted,
        onWebViewCreated: (WebViewController webViewController) {
          controller = webViewController;
        });
  }
}
