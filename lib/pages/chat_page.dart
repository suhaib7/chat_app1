import 'dart:convert';
import 'dart:developer';

import 'package:chat_app1/models/chat_bubble.dart';
import 'package:chat_app1/models/chat_service.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';
import 'package:http/http.dart' as http;

import 'package:uuid/uuid.dart';

import '../models/post.dart';

class ChatPage extends StatefulWidget {
  ChatPage({
    super.key,
    required this.receiverUserName,
    required this.receiverId,
  });

  String receiverUserName;
  String receiverId;

  @override
  State<ChatPage> createState() => _ChatPageState();
}

class _ChatPageState extends State<ChatPage> {
  final TextEditingController _messageController = TextEditingController();
  final ChatService _chatService = ChatService();
  final FirebaseAuth _firebaseAuth = FirebaseAuth.instance;
  User? user;
  File? _selectedImage;
  String imgUrl = '';
  File? imageFile;
  final FirebaseFirestore firestore = FirebaseFirestore.instance;
  bool isPhoto = false;
  final FirebaseAuth auth = FirebaseAuth.instance;
  Post? post;
  String receiverToken = '';

  void sendMessage() async {
    if (_messageController.text.isNotEmpty) {
      await _chatService.sendMessage(
          widget.receiverId, _messageController.text, null);
      _messageController.clear();
    }
  }

  @override
  void initState() {
    getChatID();
    super.initState();
  }

  bool isLoading = true;
  String chatID = '';

  getChatID() async {
    isLoading = true;
    List<String> ids = [auth.currentUser!.uid, widget.receiverId];
    ids.sort();
    chatID = ids.join(',');
    isLoading = false;
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.receiverUserName),
        backgroundColor: const Color(0xFF8F91F5),
      ),
      body: Column(
        children: [
          Expanded(
            child: isLoading
                ? const Center(child: CircularProgressIndicator())
                : _buildMessageList(),
          ),
          _buildMessageInput(),
        ],
      ),
    );
  }

  Widget _buildMessageList() {
    return StreamBuilder(
      stream: _chatService.getMessages(chatID),
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          return const Text('Error has occurred');
        }
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(
            child: CircularProgressIndicator(),
          );
        }

        return ListView(
          children: snapshot.data!.docs
              .map((document) => _buildMessageItem(document))
              .toList(),
        );
      },
    );
  }

  Widget _buildMessageItem(DocumentSnapshot document) {
    Map<String, dynamic> data = document.data() as Map<String, dynamic>;
    var alignment = (data['senderID'] == _firebaseAuth.currentUser!.uid)
        ? Alignment.centerRight
        : Alignment.centerLeft;

    return Container(
      alignment: alignment,
      child: Padding(
        padding: const EdgeInsets.all(8.0),
        child: Column(
          crossAxisAlignment:
              (data['senderID'] == _firebaseAuth.currentUser!.uid)
                  ? CrossAxisAlignment.end
                  : CrossAxisAlignment.start,
          mainAxisAlignment:
              (data['senderID'] == _firebaseAuth.currentUser!.uid)
                  ? MainAxisAlignment.start
                  : MainAxisAlignment.end,
          children: [
            Text(
              data['senderName'] ?? '',
              style: const TextStyle(
                color: Colors.black,
                fontSize: 18,
              ),
            ),
            if (data['photoMessage'] != null)
              Column(
                children: [
                  if (data['photoMessage'] != null)
                    Image.network(data['photoMessage'],
                        width: 200, height: 200),
                ],
              ),
            if (data['photoMessage'] == null)
              ChatBubble(message: data['message'] ?? ''),
          ],
        ),
      ),
    );
  }

  Widget _buildMessageInput() {
    return Padding(
      padding: const EdgeInsets.all(8.0),
      child: Row(
        children: [
          Expanded(
            child: TextField(
              controller: _messageController,
              obscureText: false,
              decoration: const InputDecoration(hintText: 'Enter a message'),
            ),
          ),
          const SizedBox(
            width: 10,
          ),
          IconButton(
            onPressed: () => getImage(),
            icon: const Icon(
              Icons.camera_alt,
              size: 20,
            ),
          ),
          IconButton(
            onPressed: () {
              sendMessage();
              //sendPushNotification(receiverToken , _messageController.text);
            },
            icon: const Icon(
              Icons.arrow_upward,
              size: 20,
            ),
          ),
        ],
      ),
    );
  }

  Future getImage() async {
    ImagePicker picker = ImagePicker();

    await picker.pickImage(source: ImageSource.gallery).then((xFile) {
      if (xFile != null) {
        imageFile = File(xFile.path);
        getCurrentUserName().then((senderName) {
          uploadImage(senderName);
        });
      }
    });
  }

  Future uploadImage(String senderName) async {
    String fileName = const Uuid().v1();

    var ref = FirebaseStorage.instance.ref().child('images').child(fileName);

    var uploadTask = await ref.putFile(imageFile!);
    String imageUrl = await uploadTask.ref.getDownloadURL();
    _chatService.sendMessage(widget.receiverId, "", imageUrl);
  }

  Future<String> getCurrentUserName() async {
    final String currentUserId = auth.currentUser!.uid;

    final DocumentSnapshot userSnapshot =
        await firestore.collection('users').doc(currentUserId).get();

    if (userSnapshot.exists) {
      final Map<String, dynamic> userData =
          userSnapshot.data() as Map<String, dynamic>;
      final String? displayName = userData['displayName'];
      return displayName ?? '';
    } else {
      return '';
    }
  }

  Future<void> sendPushNotification(String token, String msg) async {
    try {
      final body = {
        "to": '',
        "notification": {"title": "New Message", "body": msg}
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
