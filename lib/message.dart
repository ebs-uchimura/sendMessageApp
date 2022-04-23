// @dart=2.9

// * import modules
import 'package:firebase_messaging/firebase_messaging.dart'; // firebase message
import 'package:flutter/material.dart'; // materials
import 'package:url_launcher/url_launcher.dart'; // url launcher
import 'package:flutter/services.dart';// services

// url
String globalSiteUrl = '';

// * message route arguments.
class MessageArguments {
  // constructor
  MessageArguments(this.message, {this.openedApplication})
      : assert(message != null);
  final RemoteMessage message; // the RemoteMessage
  final bool
      openedApplication; // whether this message caused the application to open.
}

// * displays information about a [RemoteMessage].
class MessageView extends StatelessWidget {
  const MessageView({Key key}) : super(key: key); // set key

  // a single data row.
  Widget row(String title, String value) {
    return Padding(
      padding: const EdgeInsets.only(left: 8, right: 8, top: 8), // padding
      child: Row(children: [
        Text('$title: '), // title
        Text(value ?? 'N/A'), // value
      ]),
    );
  }

  // widget builder
  @override
  Widget build(BuildContext context) {
    final args =
        ModalRoute.of(context).settings.arguments as MessageArguments; // args
    final message = args.message; // message
    final notification = message.notification; // notification
    final ButtonStyle style = ElevatedButton.styleFrom(
        textStyle: const TextStyle(fontSize: 20)); // button style

    // set url
    globalSiteUrl = notification.body;

    return Scaffold(
      appBar: AppBar(
        title: Text(notification.title), // title
      ),
      body: Center(
        child: Column(mainAxisSize: MainAxisSize.min, children: <Widget>[
          // push button
          ElevatedButton(
            style: style, // style
            onPressed: _launchURL, // url
            child: const Text('対応する'), // button text
          ),
          ElevatedButton(
            style: style, // style
            onPressed: () {
              SystemNavigator.pop(); // close app
            },
            child: const Text('対応しない'), // button text
          ),
        ]),
      ),
    );
  }
}

// * launch specified url
void _launchURL() async {
  // no url
  if (!await launch(globalSiteUrl)) throw 'Could not launch $globalSiteUrl';
}
