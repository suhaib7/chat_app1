import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';
import 'home_screen.dart';
import 'login_screen.dart';

class ProfilePage extends StatefulWidget {
  const ProfilePage({super.key,required this.currentImgUrl});

  final String currentImgUrl;

  @override
  State<ProfilePage> createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> {
  User? user;
  File? _selectedImage;
  final TextEditingController _nameController = TextEditingController();
  final _formKey = GlobalKey<FormState>();
  String imgUrl = '';
  final auth = FirebaseAuth.instance;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Your Profile'),
        backgroundColor: const Color(0xFF8F91F5),
      ),
      body: Form(
        key: _formKey,
        child: SingleChildScrollView(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const SizedBox(height: 20,),
              CircleAvatar(
                backgroundColor: _selectedImage == null
                    ? Colors.black45
                    : Colors.transparent,
                backgroundImage: NetworkImage(widget.currentImgUrl),
                radius: 100,
              ),
              const SizedBox(
                height: 20,
              ),
              Padding(
                padding: const EdgeInsets.only(left: 90),
                child: GestureDetector(
                  onTap: _pickImageFromGallery,
                  child: const Row(
                    children: [
                      SizedBox(
                        width: 20,
                      ),
                      Text(
                        'Update your image',
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
              const SizedBox(
                height: 100,
              ),
              TextFormField(
                autovalidateMode: AutovalidateMode.onUserInteraction,
                validator: (v) {
                  if (v == null ||
                      v.isEmpty ||
                      v.length < 3) {
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
                height: 50,
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
                    if (_nameController.text.length >= 3 &&
                        _formKey.currentState!.validate()) {
                      updateData();
                    } else {
                      return;
                    }
                  },
                  child: const Text(
                    'Update',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
              const SizedBox(
                height: 20,
              ),
              Container(
                width: 150,
                height: 50,
                decoration: const BoxDecoration(
                  color: Color(0xFF8F91F5),
                  borderRadius: BorderRadius.all(
                    Radius.circular(20),
                  ),
                ),
                child: TextButton(
                  onPressed: (){
                    signOut();
                    Navigator.push(context, MaterialPageRoute(builder: (context) => const LoginScreen()));
                    },
                  child: const Text(
                    'Sign Out',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 20,
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

  Future<void> updateData() async {
    await FirebaseFirestore.instance.collection('users').doc(user!.uid).update({
      'name': _nameController.text,
      'image': imgUrl.isNotEmpty ? imgUrl : null,
    });
  }

  Future<void> getUserData(User user) async {
    final snapshot = await FirebaseFirestore.instance
        .collection('users')
        .doc(user.uid)
        .get();
    final userData = snapshot.data() as Map<String, dynamic>;
    setState(() {
      _nameController.text = userData['name'];
      imgUrl = userData['image'] ?? '';
    });
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

  Future<void> signOut() async {
    await FirebaseAuth.instance.signOut();
  }
}
