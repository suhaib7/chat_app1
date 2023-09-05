import 'dart:io';
import 'package:chat_app1/pages/home_screen.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

class SignupScreen extends StatefulWidget {
  const SignupScreen({super.key});

  @override
  State<SignupScreen> createState() => _SignupScreenState();
}

class _SignupScreenState extends State<SignupScreen> {
  File? _selectedImage;
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final TextEditingController _nameController = TextEditingController();
  final _formKey = GlobalKey<FormState>();
  String imgUrl = '';
  final _firebaseMessaging = FirebaseMessaging.instance;
  var fCMToken;

  @override
  void initState() {
    // TODO: implement initState
    super.initState();
    initNotifications();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              CircleAvatar(
                backgroundColor: _selectedImage == null
                    ? Colors.black45
                    : Colors.transparent,
                backgroundImage: _selectedImage == null
                    ? const NetworkImage('https://firebasestorage.googleapis.com/v0/b/chatapp-7b4ec.appspot.com/o/images%2F2023-08-29%2016%3A02%3A11.767125?alt=media&token=e7c32d8f-75fc-44d3-8f05-dc8543098bf7')
                        as ImageProvider<Object>?
                    : FileImage(_selectedImage!),
                radius: 100,
              ),
              const SizedBox(
                height: 20,
              ),
              Padding(
                padding: const EdgeInsets.only(left: 110),
                child: GestureDetector(
                  onTap: _pickImageFromGallery,
                  child: const Row(
                    children: [
                      SizedBox(
                        width: 20,
                      ),
                      Text(
                        'Pick an image',
                        style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 20,
                            color: Color(0xFF8F91F5)),
                      ),
                      SizedBox(
                        width: 20,
                      ),
                      Icon(Icons.camera_alt, size: 30),
                      SizedBox(
                        height: 20,
                      ),
                    ],
                  ),
                ),
              ),
              TextFormField(
                autovalidateMode: AutovalidateMode.onUserInteraction,
                validator: (v) {
                  if (v == null || v.isEmpty || v.length < 3) {
                    return 'Name not valid';
                  }
                  return null;
                },
                controller: _nameController,
                decoration: const InputDecoration(
                  hintText: 'Name',
                  icon: Icon(Icons.person),
                ),
              ),
              const SizedBox(
                height: 20,
              ),
              TextFormField(
                autovalidateMode: AutovalidateMode.onUserInteraction,
                validator: (v) {
                  if (v == null || v.isEmpty || !v.contains('@')) {
                    return 'Email not valid';
                  }
                  return null;
                },
                controller: _emailController,
                decoration: const InputDecoration(
                  hintText: 'Email',
                  icon: Icon(Icons.email),
                ),
              ),
              const SizedBox(
                height: 20,
              ),
              TextFormField(
                autovalidateMode: AutovalidateMode.onUserInteraction,
                validator: (v) {
                  if (v == null || v.isEmpty || v.length < 6) {
                    return 'Password not valid enter one longer than 6 character';
                  }
                  return null;
                },
                obscureText: true,
                controller: _passwordController,
                decoration: const InputDecoration(
                  hintText: 'Password',
                  icon: Icon(Icons.lock),
                ),
              ),
              const SizedBox(
                height: 20,
              ),
              Container(
                width: 350,
                height: 50,
                decoration: const BoxDecoration(
                  color: Color(0xFF8F91F5),
                  borderRadius: BorderRadius.all(
                    Radius.circular(20),
                  ),
                ),
                child: TextButton(
                  onPressed: () {
                    if (_emailController.text.isNotEmpty &&
                        _passwordController.text.length > 6 &&
                        _formKey.currentState!.validate()) {
                      signUp();
                      Navigator.push(
                          context,
                          MaterialPageRoute(
                              builder: (context) => HomeScreen()));
                    } else {
                      return;
                    }
                  },
                  child: const Text(
                    'Sign up',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future _pickImageFromGallery() async {
    final returnedImage =
        await ImagePicker().pickImage(source: ImageSource.gallery);
    setState(() {
      _selectedImage = File(returnedImage!.path);
    });

    String uniqueFileName = DateTime.now().toString();

    Reference referenceRoot = FirebaseStorage.instance.ref();
    Reference referenceDirImage = referenceRoot.child('images');
    Reference referenceImageToUpload = referenceDirImage.child(uniqueFileName);

    try {
      await referenceImageToUpload.putFile(File(returnedImage!.path));
      imgUrl = await referenceImageToUpload.getDownloadURL();
    } catch (e) {
      //
    }
  }

  Future<void> signUp() async {
    final auth = FirebaseAuth.instance;
    final userCredential = await auth.createUserWithEmailAndPassword(
      email: _emailController.text,
      password: _passwordController.text,
    );

    final user = userCredential.user;
    if (user != null) {
      await saveUser(user);
    } else {
      return;
    }
  }

  Future<void> saveUser(User user) async {
    FirebaseFirestore.instance.collection("users").doc(user.uid).set({
      "name": _nameController.text,
      "image": _selectedImage != null ? imgUrl : null,
      "user_id": user.uid,
      "user_token": fCMToken,
    });
  }

  Future<void> initNotifications() async {
    await _firebaseMessaging.requestPermission();
    fCMToken = await _firebaseMessaging.getToken();
  }
}
