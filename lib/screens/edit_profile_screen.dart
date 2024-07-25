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
      padding: const EdgeInsets.symmetric(vertical: 20.0, horizontal: 10.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          IconButton(
            icon: const Icon(Icons.arrow_back, color: Colors.black),
            onPressed: () {
              Navigator.of(context).pop();
            },
          ),
          const Text(
            'Edit Profile',
            style: TextStyle(color: Colors.black, fontSize: 25.0),
          ),
          const SizedBox(width: 48), // Placeholder for balance in AppBar
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
                  child: Stack(
                    children: [
                      CircleAvatar(
                        radius: 50,
                        backgroundImage: _profileImageFile != null
                            ? FileImage(_profileImageFile!)
                            : (_profileImageUrl != null
                                    ? NetworkImage(_profileImageUrl!)
                                    : const AssetImage('assets/avatar.png'))
                                as ImageProvider,
                      ),
                      Positioned(
                        bottom: 0,
                        right: 0,
                        child: CircleAvatar(
                          radius: 15,
                          backgroundColor: Colors.grey[300],
                          child: const Icon(
                            Icons.edit,
                            size: 15,
                            color: Colors.black,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 20),
              buildTextFormField(
                label: 'Full Name',
                initialValue: _fullName,
                onSaved: (value) => _fullName = value,
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter your full name';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 20),
              buildTextFormField(
                label: 'Email',
                initialValue: _email,
                onSaved: (value) => _email = value,
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter your email';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 20),
              buildTextFormField(
                label: 'Programme',
                initialValue: _programme,
                onSaved: (value) => _programme = value,
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter your programme';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 20),
              buildTextFormField(
                label: 'Student ID',
                initialValue: _studentId,
                onSaved: (value) => _studentId = value,
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter your student ID';
                  }
                  return null;
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
              if (_isFreelancer) buildFreelancerSection(),
              const SizedBox(height: 20),
              buildTextFormField(
                label: 'Bio',
                initialValue: _bio,
                onSaved: (value) => _bio = value,
              ),
              const SizedBox(height: 20),
              buildTextFormField(
                label: 'Portfolio URL',
                initialValue: _portfolioUrl,
                onSaved: (value) => _portfolioUrl = value,
              ),
              const SizedBox(height: 20),
              buildTextFormField(
                label: 'Work Experience',
                initialValue: _workExperience,
                onSaved: (value) => _workExperience = value,
              ),
              const SizedBox(height: 20),
              Center(
                child: ElevatedButton.icon(
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
                    color: Colors.white,
                    size: 16.0,
                  ),
                  label: const Text(
                    'Save',
                    style: TextStyle(
                      fontSize: 16.0,
                      color: Colors.white,
                    ),
                  ),
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 24.0, vertical: 12.0),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(20.0),
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

  Widget buildTextFormField({
    required String label,
    String? initialValue,
    FormFieldValidator<String>? validator,
    FormFieldSetter<String>? onSaved,
  }) {
    return TextFormField(
      initialValue: initialValue,
      decoration: InputDecoration(
        labelText: label,
        border: OutlineInputBorder(
          borderSide: const BorderSide(color: Colors.black),
          borderRadius: BorderRadius.circular(20.0),
        ),
      ),
      validator: validator,
      onSaved: onSaved,
    );
  }

  Widget buildFreelancerSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        buildTextFormField(
          label: 'Job Title',
          initialValue: _title,
          onSaved: (value) => _title = value,
          validator: (value) {
            if (value == null || value.isEmpty) {
              return 'Please enter a job title';
            }
            return null;
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
