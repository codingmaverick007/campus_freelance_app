import 'package:campus_freelance_app/screens/profile_screen.dart';
import 'package:campus_freelance_app/screens/screen_scaffold.dart';
import 'package:flutter/material.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_chip_tags/flutter_chip_tags.dart';
import 'dart:io';
import 'package:image_picker/image_picker.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class EditProfileScreen extends StatefulWidget {
  @override
  _EditProfileScreenState createState() => _EditProfileScreenState();
}

class _EditProfileScreenState extends State<EditProfileScreen> {
  final _formKey = GlobalKey<FormState>();
  String? _fullName;
  String? _email;
  String? _programme;
  String? _studentId;
  String? _profileImageUrl;
  File? _profileImageFile;
  String? _studentIdImageUrl;
  File? _studentIdImageFile;
  bool _isFreelancer = false;
  String? _title;
  List<String> _services = [];
  String? _bio;
  List<String> _skills = [];
  List<String> _interests = [];
  String? _portfolioUrl;
  String? _workExperience;

  @override
  void initState() {
    super.initState();
    _fetchUserData();
  }

  Future<void> _fetchUserData() async {
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user != null) {
        final userData = await FirebaseFirestore.instance
            .collection('users')
            .doc(user.uid)
            .get();

        if (userData.exists) {
          setState(() {
            final data = userData.data()!;
            _fullName = data['fullName'] ?? '';
            _email = data['email'] ?? '';
            _programme = data['programme'] ?? '';
            _studentId = data['studentId'] ?? '';
            _profileImageUrl = data['profileImageUrl'];
            _studentIdImageUrl = data['studentIdImageUrl'];
            _isFreelancer = data['isFreelancer'] ?? false;
            _title = data['title'] ?? '';
            _services = List<String>.from(data['services'] ?? []);
            _bio = data['bio'] ?? '';
            _skills = List<String>.from(data['skills'] ?? []);
            _interests = List<String>.from(data['interests'] ?? []);
            _portfolioUrl = data['portfolioUrl'] ?? '';
            _workExperience = data['workExperience'] ?? '';
          });
        }
      }
    } catch (e) {
      print("Error fetching user data: $e");
    }
  }

  Future<void> _pickImage(ImageSource source, bool isProfile) async {
    final pickedFile = await ImagePicker().pickImage(source: source);
    if (pickedFile != null) {
      setState(() {
        if (isProfile) {
          _profileImageFile = File(pickedFile.path);
        } else {
          _studentIdImageFile = File(pickedFile.path);
        }
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: _fullName == null
          ? const Center(child: CircularProgressIndicator())
          : buildForm(),
    );
  }

  Widget customAppBar() {
    return Container(
      padding: const EdgeInsets.all(10.0),
      child: Row(
        children: [
          Container(
            decoration: BoxDecoration(
                shape: BoxShape.circle, color: Colors.grey.withOpacity(0.2)),
            child: IconButton(
              icon: const Icon(Icons.arrow_back),
              onPressed: () {
                Navigator.of(context).pop();
              },
            ),
          ),
          const SizedBox(width: 122),
          const Text(
            'Edit Profile',
            style: TextStyle(color: Colors.black, fontSize: 25.0),
          )
        ],
      ),
    );
  }

  Widget buildForm() {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Form(
        key: _formKey,
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              customAppBar(),
              const SizedBox(height: 30),
              Center(
                child: GestureDetector(
                  onTap: () => _pickImage(ImageSource.gallery, true),
                  child: CircleAvatar(
                    radius: 50,
                    backgroundImage: _profileImageFile != null
                        ? FileImage(_profileImageFile!)
                        : (_profileImageUrl != null
                                ? NetworkImage(_profileImageUrl!)
                                : const AssetImage('assets/avatar.png'))
                            as ImageProvider,
                  ),
                ),
              ),
              const SizedBox(height: 20),
              TextFormField(
                initialValue: _fullName,
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
                onSaved: (value) {
                  _fullName = value!;
                },
              ),
              const SizedBox(height: 20),
              TextFormField(
                initialValue: _email,
                decoration: InputDecoration(
                  labelText: 'Email',
                  border: OutlineInputBorder(
                    borderSide: const BorderSide(color: Colors.black),
                    borderRadius: BorderRadius.circular(20.0),
                  ),
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter your email';
                  }
                  return null;
                },
                onSaved: (value) {
                  _email = value!;
                },
              ),
              const SizedBox(height: 20),
              TextFormField(
                initialValue: _programme,
                decoration: InputDecoration(
                  labelText: 'Programme',
                  border: OutlineInputBorder(
                    borderSide: const BorderSide(color: Colors.black),
                    borderRadius: BorderRadius.circular(20.0),
                  ),
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter your programme';
                  }
                  return null;
                },
                onSaved: (value) {
                  _programme = value!;
                },
              ),
              const SizedBox(height: 20),
              TextFormField(
                initialValue: _studentId,
                decoration: InputDecoration(
                  labelText: 'Student ID',
                  border: OutlineInputBorder(
                    borderSide: const BorderSide(color: Colors.black),
                    borderRadius: BorderRadius.circular(20.0),
                  ),
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter your student ID';
                  }
                  return null;
                },
                onSaved: (value) {
                  _studentId = value!;
                },
              ),
              const SizedBox(height: 20),

              SwitchListTile(
                title: const Text('Freelancer'),
                value: _isFreelancer,
                onChanged: (value) {
                  setState(() {
                    _isFreelancer = value;
                  });
                },
              ),
              const SizedBox(height: 20),
              if (_isFreelancer)
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    TextFormField(
                      initialValue: _title,
                      decoration: InputDecoration(
                        labelText: 'Job Title',
                        border: OutlineInputBorder(
                          borderSide: const BorderSide(color: Colors.black),
                          borderRadius: BorderRadius.circular(20.0),
                        ),
                      ),
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Please enter a job title';
                        }
                        return null;
                      },
                      onSaved: (value) {
                        _title = value!;
                      },
                    ),
                    const SizedBox(height: 20),
                    ChipTags(
                      list: _services,
                      decoration: InputDecoration(
                        labelText: 'Services Offered (comma separated)',
                        border: OutlineInputBorder(
                          borderSide: const BorderSide(color: Colors.black),
                          borderRadius: BorderRadius.circular(20.0),
                        ),
                      ),
                      separator: ',',
                      chipColor: Colors.grey,
                      createTagOnSubmit: true,
                    ),
                  ],
                ),
              const SizedBox(height: 20),
              TextFormField(
                initialValue: _bio,
                decoration: InputDecoration(
                  labelText: 'Bio',
                  border: OutlineInputBorder(
                    borderSide: const BorderSide(color: Colors.black),
                    borderRadius: BorderRadius.circular(20.0),
                  ),
                ),
                onSaved: (value) {
                  _bio = value!;
                },
              ),
              const SizedBox(height: 20),

              TextFormField(
                initialValue: _portfolioUrl,
                decoration: InputDecoration(
                  labelText: 'Portfolio URL',
                  border: OutlineInputBorder(
                    borderSide: const BorderSide(color: Colors.black),
                    borderRadius: BorderRadius.circular(20.0),
                  ),
                ),
                onSaved: (value) {
                  _portfolioUrl = value!;
                },
              ),
              const SizedBox(height: 20),

              TextFormField(
                initialValue: _workExperience,
                decoration: InputDecoration(
                  labelText: 'Work Experience',
                  border: OutlineInputBorder(
                    borderSide: const BorderSide(color: Colors.black),
                    borderRadius: BorderRadius.circular(20.0),
                  ),
                ),
                onSaved: (value) {
                  _workExperience = value!;
                },
              ),
              // Add more fields as needed

              const SizedBox(height: 20),
              Center(
                child: TextButton.icon(
                  onPressed: () {
                    if (_formKey.currentState!.validate()) {
                      _formKey.currentState!.save();
                      _updateUserData().then((_) {
                        Navigator.pop(
                          context,
                        );
                      });
                    }
                  },
                  icon: const Icon(
                    Icons.save_alt_rounded,
                    color: Colors.blueGrey,
                    size: 16.0,
                  ),
                  label: const Text(
                    'Save',
                    style: TextStyle(
                      fontSize: 16.0,
                      color: Colors.blueGrey,
                    ),
                  ),
                ),
              )
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _updateUserData() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      final userDoc =
          FirebaseFirestore.instance.collection('users').doc(user.uid);
      final updatedData = {
        'fullName': _fullName,
        'email': _email,
        'programme': _programme,
        'studentId': _studentId,
        'isFreelancer': _isFreelancer,
        'title': _title,
        'services': _services,
        'bio': _bio,
        'skills': _skills,
        'interests': _interests,
        'portfolioUrl': _portfolioUrl,
        'workExperience': _workExperience,
      };

      if (_profileImageFile != null) {
        // Upload new profile image to storage and get URL
        // Update `_profileImageUrl` with new URL
      }

      if (_studentIdImageFile != null) {
        // Upload new student ID image to storage and get URL
        // Update `_studentIdImageUrl` with new URL
      }

      await userDoc.update(updatedData);
    }
  }
}
