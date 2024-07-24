import 'dart:io';
import 'dart:typed_data';

import 'package:campus_freelance_app/user_state.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:campus_freelance_app/providers/user_data_provider.dart';
import 'package:firebase_messaging/firebase_messaging.dart';

class FinishProfileScreen extends StatefulWidget {
  const FinishProfileScreen({Key? key}) : super(key: key);

  @override
  _FinishProfileScreenState createState() => _FinishProfileScreenState();
}

class _FinishProfileScreenState extends State<FinishProfileScreen> {
  Uint8List? _image;
  final _formKey = GlobalKey<FormState>();
  final _fullNameController = TextEditingController();
  bool _isLoading = false;

  Future<void> _pickImage() async {
    XFile? pickedFile =
        await ImagePicker().pickImage(source: ImageSource.gallery);
    if (pickedFile != null) {
      Uint8List pickedImageBytes = await pickedFile.readAsBytes();
      setState(() {
        _image = pickedImageBytes;
      });
      Provider.of<UserData>(context, listen: false)
          .updateProfileImage(File(pickedFile.path));
    }
  }

  Future<String> _uploadProfileImage(Uint8List imageBytes) async {
    final userData = Provider.of<UserData>(context, listen: false);
    Reference storageRef = FirebaseStorage.instance
        .ref()
        .child('profileImages/${userData.userId}.jpg');
    UploadTask uploadTask = storageRef.putData(imageBytes);
    TaskSnapshot snapshot = await uploadTask;
    return await snapshot.ref.getDownloadURL();
  }

  Future<void> _saveProfileDetails() async {
    if (_formKey.currentState?.validate() ?? false) {
      setState(() {
        _isLoading = true;
      });

      final userData = Provider.of<UserData>(context, listen: false);
      userData.updateFullName(_fullNameController.text);

      try {
        // Create user with email and password if not already registered
        if (!userData.isRegistered) {
          UserCredential userCredential =
              await FirebaseAuth.instance.createUserWithEmailAndPassword(
            email: userData.email,
            password: userData.password,
          );
          userData.setUserId(userCredential.user!.uid);
        }

        // Upload profile image if it exists
        String? profileImageUrl;
        if (_image != null) {
          profileImageUrl = await _uploadProfileImage(_image!);
        }

        // Get the FCM token
        String? fcmToken = await FirebaseMessaging.instance.getToken();

        // Save user details to Firestore
        FirebaseFirestore firestore = FirebaseFirestore.instance;
        DocumentReference userRef =
            firestore.collection('users').doc(userData.userId);

        await userRef.set({
          'email': userData.email,
          'fullName': userData.fullName,
          'programme': userData.programme,
          'studentId': userData.studentId,
          'isFreelancer': userData.isFreelancer,
          'title': userData.title,
          'services': userData.services,
          if (profileImageUrl != null) 'profileImageUrl': profileImageUrl,
          if (fcmToken != null) 'fcmToken': fcmToken, // Save the FCM token
        });

        // Navigate to home screen after successful profile setup
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => const UserState()),
        );
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to save profile details: $e')),
        );
      } finally {
        setState(() {
          _isLoading = false;
        });
      }
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please complete all fields')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final userData = Provider.of<UserData>(context);
    _fullNameController.text = userData.fullName;

    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Row(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    Container(
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: Colors.grey.withOpacity(0.2),
                      ),
                      child: IconButton(
                        icon: const Icon(Icons.arrow_back),
                        onPressed: () {
                          Navigator.of(context).pop();
                        },
                      ),
                    ),
                    const SizedBox(width: 45),
                    Text(
                      'Complete Details',
                      style: Theme.of(context).textTheme.displayLarge,
                    ),
                  ],
                ),
                const SizedBox(height: 30),
                Center(
                  child: Stack(
                    children: <Widget>[
                      CircleAvatar(
                        radius: 60,
                        backgroundImage:
                            _image != null ? MemoryImage(_image!) : null,
                        child: _image == null
                            ? const Icon(Icons.person, size: 60)
                            : null,
                      ),
                      Positioned(
                        bottom: 0,
                        right: 0,
                        child: IconButton(
                          icon: const Icon(Icons.camera_alt),
                          onPressed: _pickImage,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 20),
                TextFormField(
                  controller: _fullNameController,
                  decoration: InputDecoration(
                    labelText: 'Full Name',
                    border: OutlineInputBorder(
                      borderSide: const BorderSide(color: Colors.black),
                      borderRadius: BorderRadius.circular(20.0),
                    ),
                  ),
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Please enter your full name';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 20),
                Center(
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Theme.of(context).primaryColor,
                      padding: EdgeInsets.symmetric(vertical: 16.0),
                      minimumSize: Size(double.infinity, 20),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8.0),
                      ),
                    ),
                    onPressed: _isLoading ? null : _saveProfileDetails,
                    child: _isLoading
                        ? const CircularProgressIndicator()
                        : Text(
                            'Finish',
                            style: Theme.of(context).textTheme.labelLarge,
                          ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
