import 'dart:convert';
import 'dart:developer';
import 'dart:io';
import 'package:chat_app1/models/notification_screen.dart';
import 'package:chat_app1/models/post.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:http/http.dart' as http;

final navigatorKey = GlobalKey<NavigatorState>();

Future<void> handleBackgroundMessage(RemoteMessage message) async {
  print('Title: ${message.notification?.title}');
  print('Body: ${message.notification?.body}');
  print('Payload: ${message.data}');
}

class FirebaseApi {
  final _firebaseMessaging = FirebaseMessaging.instance;
  late Post post;

  final _androidChannel = const AndroidNotificationChannel(
    'high_importance_channel',
    'High importance Notifications',
    description: 'This channel is used for important Notifications',
    importance: Importance.defaultImportance,
  );

  final _localNotifications = FlutterLocalNotificationsPlugin();

  void handleMessage(RemoteMessage? message) {
    if (message == null) return;

    navigatorKey.currentState
        ?.pushNamed(NotificationScreen.route, arguments: message);
  }

  Future initPushNotification() async {
    await FirebaseMessaging.instance
        .setForegroundNotificationPresentationOptions(
      alert: true,
      badge: true,
      sound: true,
    );

    FirebaseMessaging.instance.getInitialMessage().then(handleMessage);
    FirebaseMessaging.onMessageOpenedApp.listen(handleMessage);
    FirebaseMessaging.onBackgroundMessage(handleBackgroundMessage);
    FirebaseMessaging.onMessage.listen((message) {
      final notification = message.notification;
      if (notification == null) return;

      _localNotifications.show(
        notification.hashCode,
        notification.title,
        notification.body,
        NotificationDetails(
          android: AndroidNotificationDetails(
            _androidChannel.id,
            _androidChannel.name,
            channelDescription: _androidChannel.description,
            icon: '@drawable/ic_launcher',
          ),
        ),
        payload: jsonEncode(message.toMap()),
      );
    });
  }

  Future<void> initNotifications() async {
    await _firebaseMessaging.requestPermission();
    final fCMToken = await _firebaseMessaging.getToken();
    //print('Token: $fCMToken');
    initNotifications();
  }

  FirebaseMessaging fmessaging = FirebaseMessaging.instance;

  Future<void> getFirebaseMessageToken() async {
    await fmessaging.requestPermission();

    await fmessaging.getToken().then((t) {
      if (t != null) {}
    });
  }

  Future<Post> fetchMessage() async {
    final uri = Uri.parse('https://fcm.googleapis.com/fcm/send');
    final response = await http.get(uri);

    if (response.statusCode == 200) {
      return Post.fromJson(json.decode(response.body));
    } else {
      throw Exception('Fail');
    }
  }

  Future<Post> sendMessage(String to, String title, String body) async {
    Map<String, dynamic> request = {
      'to':
          'dgilCvbyRVeascBARKVK5H:APA91bF7FM4SCaKWUTBk57KeoDwYfQbvZMOOr8c8W138RmVP1cDYSuRy0eCMcejIrN7B4OzOsBFR6rGn_VKrife_OtwkMZydYs6kFhb-dPcU4CodU1lg6X8vOBveFXEFb0rH0mEBKw9i',
    };
    final uri = Uri.parse('https://fcm.googleapis.com/fcm/send');
    final response = await http.post(uri, body: request);

    if (response.statusCode == 201) {
      return Post.fromJson(json.decode(response.body));
    } else {
      throw Exception('Fail');
    }
  }

  Future<void> sendPushNotification(User user, String msg) async {
    try {
      final body = {
        "to": '',
        "notification": {"title": "title", "body": msg}
      };
      var response =
          await http.post(Uri.parse('https://fcm.googleapis.com/fcm/send'),
              headers: {
                HttpHeaders.contentTypeHeader: 'application/json',
                HttpHeaders.authorizationHeader:
                    'key=AAAArImybbs:APA91bFlCjRApyw3Xt4S2o4x_itd2tvnTg2BWYZvVa4pBnk7sDPiQ5aob7o3d_gdEQS7lqcjcViOWjUsFHsFfffB3usRCa4cX1VSGp7va1AfmeKh2VqMru2VRi2Ql35LGPExKlFHuEa4',
              },
              body: jsonEncode(body));
      log('Response stauts: ${response.statusCode}');
      log('Response body: ${response.body}');
    } catch (e) {
      log('\nsendPushNotificationE: $e');
    }
  }
}
