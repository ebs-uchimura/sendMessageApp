// @dart=2.9

// * import modules
import 'dart:async'; // asynchronous
import 'dart:convert'; // converter
import 'package:firebase_core/firebase_core.dart'; // firebase core
import 'package:firebase_messaging/firebase_messaging.dart'; // firebase messaing
import 'package:flutter/material.dart'; // materials
import 'package:flutter_local_notifications/flutter_local_notifications.dart';// flutter notification
import 'package:flutter_ringtone_player/flutter_ringtone_player.dart'; // flutter sound player
import 'package:http/http.dart' as http; // http
import 'message.dart'; // custom

// * init global variables
// sender ID
const String globalSenderId = ''; // sender id
// server API token
String globalToken = '';

// * setting
// create a [AndroidNotificationChannel] for heads up notifications.
const AndroidNotificationChannel channel = AndroidNotificationChannel(
  'high_importance_channel', // id
  'High Importance Notifications', // title
  // 'This channel is used for important notifications.', // description
  importance: Importance.high, // importance level
);
// initialize the [FlutterLocalNotificationsPlugin] package.
final FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin =
    FlutterLocalNotificationsPlugin();

// main
Future<void> main() async {
  // flutter widget preparation
  WidgetsFlutterBinding.ensureInitialized();
  // Initialize firebase
  await Firebase.initializeApp();
  // Set the background messaging handler early as a named top-level function
  FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);
  // Use `AndroidManifest.xml` file to override the default FCM channel to enable heads up notifications.
  await flutterLocalNotificationsPlugin
      .resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin>()
      ?.createNotificationChannel(channel);
  runApp(const SendMessagingApp());
}

// main window
class SendMessagingApp extends StatelessWidget {
  // set key
  const SendMessagingApp({Key key}) : super(key: key);
  // widget builder
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Send Messaging App',
      theme: ThemeData.dark(), // color theme
      // routing list
      routes: {
        '/': (context) => const Application(), // home
        '/message': (context) => const MessageView(), // message
      },
    );
  }
}

/// Renders the example application.
class Application extends StatefulWidget {
  // set key
  const Application({Key key}) : super(key: key);
  // create state
  @override
  State<StatefulWidget> createState() => _Application();
}

// app state
class _Application extends State<Application> {
  // initialize
  @override
  void initState() {
    // init state
    super.initState();
    // get token
    FirebaseMessaging.instance.getToken().then((token) {
      // token is not null
      if (token != null) {
        // set token
        globalToken = token; 
      }
    });
    // messaging
    FirebaseMessaging.instance.getInitialMessage() // get intial message
        .then((RemoteMessage message) {
      // message exists
      if (message != null) {
        // goto message
        Navigator.pushNamed(context, '/message',
            arguments: MessageArguments(message, openedApplication: true));
      }
    });

    // receive message
    FirebaseMessaging.onMessage.listen((RemoteMessage message) {
      final notification = message.notification; // notification data
      final android = message.notification?.android; // android exist

      // still not received message and android exists
      if (notification != null && android != null) {
        // play alarm
        playAlarmHandler();
        // show notification
        flutterLocalNotificationsPlugin.show(
            notification.hashCode, // hash code
            notification.title, // title
            notification.body, // body
            NotificationDetails(
              android: AndroidNotificationDetails(
                channel.id, // channel id
                channel.name, // channel name
                // channel.description,
                icon: 'launch_background', // notification icon
              ),
            ));
        // transfer window
        Navigator.pushNamed(context, '/message',
            arguments: MessageArguments(message, openedApplication: true));
      }
    });

    // background ignititon message app
    FirebaseMessaging.onMessageOpenedApp.listen((RemoteMessage message) {
      debugPrint('A new onMessageOpenedApp event was published!');
      // transfer window
      Navigator.pushNamed(context, '/message',
          arguments: MessageArguments(message, openedApplication: true));
    });
  }

// * widget builder
  @override
  Widget build(BuildContext context) {
    final ButtonStyle style = ElevatedButton.styleFrom(
        textStyle: const TextStyle(fontSize: 20)); // button style
    // main widget
    return Scaffold(
        appBar: AppBar(
          title: const Text('Cloud Messaging'), // title
        ),
        body: Center(
          child: Column(mainAxisSize: MainAxisSize.min, children: <Widget>[
            // push button
            ElevatedButton(
              style: style, // style
              onPressed: () =>
                  // ringing time
                  sendFirebaseMessageHandler(),
              child: const Text('通知を送る'), // button text
            ),
          ]),
        ));
  }
}

// background FCM handler
Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  await Firebase.initializeApp();
  debugPrint('Handling a background message ${message.messageId}');
  final bkNotification = message.notification; // notification flg
  final bkAndroid = message.notification?.android; // android exist flg

  // Still not received message and android exists
  if (bkNotification != null && bkAndroid != null) {
    // play alarm
    playAlarmHandler();
  }
}

// * custom module
// send firebase message
Future<void> sendFirebaseMessageHandler() async {
  final httpsUri = Uri.parse("https://fcm.googleapis.com/fcm/send"); // FCM url
  // http header
  Map<String, String> headers = {
    'content-type': 'application/json',
    'Authorization': 'key=$globalSenderId',
  };
  // http body
  Map<String, Object> body = {
    'to': globalToken, // fcm token
    'priority': 'high', // priority of notification
    'data': {}, // data
    'notification': {
      'title': 'FCM Message', // title
      'body': 'https://google.com', // body
    }
  };

  try {
    final resp = await http.post(httpsUri,
        headers: headers, body: json.encode(body)); // response
    // successed
    if (resp.statusCode == 200) {
      final jsonResponse =
          jsonDecode(resp.body) as Map<String, dynamic>; // response data
      final itemCount = jsonResponse['totalItems']; // number of items
      debugPrint('Number of books about http: $itemCount.');
      // failed
    } else {
      debugPrint('Request failed with status: ${resp.statusCode}.');
    }
  } catch (e) {
    debugPrint(e);
  }
}

// * tools
// play alarm
Future<void> playAlarmHandler() async {
  // play sound
  FlutterRingtonePlayer.playRingtone(asAlarm: false);
  debugPrint('afterPlay');
  // after few seconds
  Future.delayed(const Duration(seconds: 5), () {
    // stop ringing
    FlutterRingtonePlayer.stop();
  });
  debugPrint('afterStop');
}
