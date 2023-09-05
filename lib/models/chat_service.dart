import 'dart:convert';
import 'dart:developer';
import 'dart:io';

import 'package:chat_app1/models/message.dart';
import 'package:chat_app1/models/post.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/cupertino.dart';
import 'package:http/http.dart' as http;
import 'package:chat_app1/models/firebase_api.dart';

class ChatService extends ChangeNotifier {
  final FirebaseAuth auth = FirebaseAuth.instance;
  final FirebaseFirestore firestore = FirebaseFirestore.instance;

  Future<String> getCurrentUserName() async {
    final String currentUserId = auth.currentUser!.uid;
    final _firebaseMessaging = FirebaseMessaging.instance;
    late Post post;

    final DocumentSnapshot userSnapshot =
    await firestore.collection('users').doc(currentUserId).get();

    if (userSnapshot.exists) {
      final Map<String, dynamic> userData =
      userSnapshot.data() as Map<String, dynamic>;
      final String displayName = userData['name'];
      return displayName;
    } else {
      return '';
    }
  }

  // Future<void> sendPhoto(String receiverId, String photoMessage) async {
  //   final String currentUserID = auth.currentUser!.uid;
  //   final String currentUserName = await getCurrentUserName();
  //   final Timestamp timestamp = Timestamp.now();
  //
  //   PhotoMessage newPhotoMessage = PhotoMessage(
  //     timestamp: timestamp,
  //     photoMessage: photoMessage,
  //     receiverID: receiverId,
  //     senderID: currentUserID,
  //     senderName: currentUserName,
  //   );
  //   List<String> ids = [currentUserID, receiverId];
  //
  //   ids.sort();
  //   String chatRoomId = ids.join("_");
  //
  //   await firestore
  //       .collection('chat_rooms')
  //       .doc(chatRoomId)
  //       .collection('messages')
  //       .add(newPhotoMessage.toMap());
  // }

  Future<void> sendMessage(String receiverId, String message,
      String? photoMessage) async {
    final String currentUserId = auth.currentUser!.uid;
    final String currentUserName = await getCurrentUserName();
    final Timestamp timestamp = Timestamp.now();

    Message newMessage = Message(
        timestamp: timestamp,
        receiverId: receiverId,
        message: message,
        senderId: currentUserId,
        photoMessage: photoMessage,
        senderName: currentUserName);

    List<String> ids = [currentUserId, receiverId];
    ids.sort();
    String chatID = ids.join(',');
    var chat = await firestore.collection('chat_rooms').doc(chatID);
    chat.set({'user_ids': ids});
    chat.collection('messages').doc().set(newMessage.toMap()).then((value) => sendPushNotification(receiverId, message));
  }

  Stream<QuerySnapshot> getMessages(String chatID) {
    return firestore
        .collection('chat_rooms')
        .doc(chatID)
        .collection('messages')
        .orderBy('timestamp', descending: false)
        .snapshots();
  }

  Future<void> sendPushNotification(String user, String msg) async {
    try {
      final body = {
        "to": 'fMRWlDbZQmqrsajiqQRjhr:APA91bFNeDI6zjxWenqIkBz2ICtmt5E5ND9tS1vyfoFdMa2MovRNd9RhYdVUFdYu0WirE8G95FS98SzfcgEbfKdH5Hzo5S-9kt5w1KniKu2bvI3_vVmTVTmQzYbhvruhZ5feopxVxe12',
        "notification": {"title": user, "body": msg}
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
