import 'dart:convert';
import 'package:chat_app1/pages/profile_page.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import '../models/post.dart';
import 'chat_page.dart';
import 'package:http/http.dart' as http;

class HomeScreen extends StatefulWidget {
  const HomeScreen({Key? key}) : super(key: key);

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final FirebaseAuth auth = FirebaseAuth.instance;
  var collection = FirebaseFirestore.instance.collection('users');
  late List<Map<String, dynamic>> users;
  bool isLoaded = false;
  late List<Map<String, dynamic>> chats;
  bool isChatsLoaded = false;
  final userRef = FirebaseFirestore.instance.collection('chat_rooms');
  String currentUserImage = '';
  User? user;
  final _firebaseMessaging = FirebaseMessaging.instance;
  late Post post;
  String token = '';

  _getUsers() async {
    List<Map<String, dynamic>> tempList = [];
    var data = await collection.get();

    data.docs.forEach((element) {
      tempList.add(element.data());
    });
    setState(() {
      users = tempList;
      isLoaded = true;
    });
  }

  @override
  void initState() {
    super.initState();
    _getUsers();
    setUserToken(auth.currentUser!);
    _getUserData();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: const Color(0xFF8F91F5),
        title: const Text('Chat App'),
        automaticallyImplyLeading: false,
        actions: [
          IconButton(
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => ProfilePage(
                    currentImgUrl: currentUserImage,
                  ),
                ),
              );
            },
            icon: const Icon(Icons.person),
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(8.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            isLoaded
                ? SizedBox(
                    height: 100,
                    child: ListView.builder(
                      scrollDirection: Axis.horizontal,
                      itemCount: users.length,
                      itemBuilder: (context, index) {
                        return Padding(
                          padding: const EdgeInsets.all(8.0),
                          child: Column(
                            children: [
                              GestureDetector(
                                onTap: () => Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (context) => ChatPage(
                                      receiverUserName: users[index]['name'],
                                      receiverId: users[index]['user_id'],
                                    ),
                                  ),
                                ),
                                child: CircleAvatar(
                                  radius: 30,
                                  backgroundColor: Colors.black12,
                                  backgroundImage: NetworkImage(
                                    users[index]['image'] ??
                                        'https://firebasestorage.googleapis.com/v0/b/chatapp-7b4ec.appspot.com/o/images%2F2023-08-29%2016%3A02%3A07.882993?alt=media&token=07b1e168-4abf-4447-8e86-23873fa45b7e',
                                  ),
                                ),
                              ),
                              Text(
                                users[index]['name'],
                              ),
                            ],
                          ),
                        );
                      },
                    ),
                  )
                : const Center(
                    child: CircularProgressIndicator(),
                  ),
            const Padding(
              padding: EdgeInsets.all(8.0),
              child: Text(
                'Your Chats',
                style: TextStyle(
                  color: Colors.black,
                  fontSize: 30,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            Expanded(
              child: StreamBuilder(
                stream: FirebaseFirestore.instance
                    .collection('chat_rooms')
                    .where('user_ids',
                        arrayContains: auth.currentUser?.uid ?? "NULL")
                    .snapshots(),
                builder: (context, snapshot) {
                  if (snapshot.hasError) {
                    return const Text('Error');
                  }
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const Center(
                      child: CircularProgressIndicator(),
                    );
                  }
                  var docs = snapshot.data!.docs;
                  return ListView.builder(
                    shrinkWrap: true,
                    itemCount: docs.length,
                    itemBuilder: (context, index) {
                      List<dynamic> ids = docs[index].data()['user_ids'];
                      ids.remove(auth.currentUser!.uid);
                      String receiverID = ids.first.toString();
                      return Padding(
                        padding: const EdgeInsets.all(8.0),
                        child: Column(
                          children: [
                            GestureDetector(
                              onTap: () => Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) => ChatPage(
                                    receiverUserName: 'receiver name',
                                    receiverId: receiverID,
                                  ),
                                ),
                              ),
                              child: StreamBuilder(
                                stream: FirebaseFirestore.instance
                                    .collection('users')
                                    .where('user_id', isEqualTo: receiverID)
                                    .snapshots(),
                                builder: (context, snapshot) {
                                  if (!snapshot.hasData) {
                                    return const Center(
                                        child: CircularProgressIndicator());
                                  }
                                  var user = snapshot.data?.docs.first;
                                  return Row(
                                    children: [
                                      CircleAvatar(
                                        radius: 30,
                                        backgroundColor: Colors.black12,
                                        backgroundImage: NetworkImage(
                                          user?.data()['image'] ??
                                              'https://firebasestorage.googleapis.com/v0/b/chatapp-7b4ec.appspot.com/o/images%2F2023-08-29%2016%3A02%3A11.767125?alt=media&token=e7c32d8f-75fc-44d3-8f05-dc8543098bf7',
                                        ),
                                      ),
                                      Text(
                                        user?.data()['name'] ?? "",
                                      ),
                                    ],
                                  );
                                },
                              ),
                            ),
                          ],
                        ),
                      );
                    },
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _getUserData() async {
    final snapshot = await FirebaseFirestore.instance
        .collection('users')
        .doc(auth.currentUser!.uid)
        .get();

    final userData = snapshot.data() as Map<String, dynamic>;
    setState(() {
      currentUserImage = userData['image'];
      token = userData['user_token'];
    });
  }

  Future<void> setUserToken(User user) async {
    await _firebaseMessaging.requestPermission();
    final fCMToken = await _firebaseMessaging.getToken();
    final snapshot = await FirebaseFirestore.instance.collection('users').doc(user.uid).get();
    final userData = snapshot.data() as Map<String, dynamic>;

    await FirebaseFirestore.instance.collection('users').doc(user.uid).update({
      'user_token': fCMToken,
    });

    setState(() {
      userData['user_token'] = fCMToken;
    });
  }
}
