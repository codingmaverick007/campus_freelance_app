import 'dart:io';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:lottie/lottie.dart';
import 'package:provider/provider.dart';
import 'package:campus_freelance_app/providers/user_data_provider.dart';
import 'package:campus_freelance_app/screens/auth%20screens/sign%20up%20screens/user_type_screen.dart';

class UserDetailsScreen extends StatefulWidget {
  const UserDetailsScreen({Key? key}) : super(key: key);

  @override
  _UserDetailsScreenState createState() => _UserDetailsScreenState();
}

class _UserDetailsScreenState extends State<UserDetailsScreen> {
  final _formKey = GlobalKey<FormState>();
  final _programmeController = TextEditingController();
  final _studentIdController = TextEditingController();
  File? _uploadedImage;

  @override
  void dispose() {
    _programmeController.dispose();
    _studentIdController.dispose();
    super.dispose();
  }

  void _pickImage(BuildContext context, ImageSource source) async {
    final pickedFile = await ImagePicker().pickImage(source: source);
    if (pickedFile != null) {
      setState(() {
        _uploadedImage = File(pickedFile.path);
      });
      Provider.of<UserData>(context, listen: false)
          .updateStudentIdImage(File(pickedFile.path));
    }
  }

  void _saveDetails(BuildContext context) async {
    if (_formKey.currentState?.validate() ?? false) {
      final userData = Provider.of<UserData>(context, listen: false);
      userData.updateProgramme(_programmeController.text);
      userData.updateStudentId(_studentIdController.text);

      try {
        Navigator.push(
          context,
          MaterialPageRoute(builder: (context) => UserTypeScreen()),
        );
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to save user details')),
        );
        print('Error saving user details: $e');
      }
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please complete all fields')),
      );
    }
  }

  void _viewImage(BuildContext context) {
    if (_uploadedImage != null) {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => Scaffold(
            appBar: AppBar(),
            body: Center(
              child: Image.file(_uploadedImage!),
            ),
          ),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final userData = Provider.of<UserData>(context);
    _programmeController.text = userData.programme;
    _studentIdController.text = userData.studentId;

    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            children: [
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
                  const SizedBox(width: 90),
                  Text(
                    'User Details',
                    style: Theme.of(context).textTheme.displayLarge,
                  ),
                ],
              ),
              Lottie.asset('assets/animations/gears.json'),
              Expanded(
                child: SingleChildScrollView(
                  child: Form(
                    key: _formKey,
                    child: Column(
                      children: [
                        TextFormField(
                          controller: _programmeController,
                          decoration: InputDecoration(
                            labelText: 'Programme',
                            labelStyle: Theme.of(context).textTheme.labelSmall,
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(8.0),
                            ),
                          ),
                          validator: (value) {
                            if (value == null || value.isEmpty) {
                              return 'Please enter your programme';
                            }
                            return null;
                          },
                        ),
                        const SizedBox(height: 20),
                        TextFormField(
                          controller: _studentIdController,
                          decoration: InputDecoration(
                            labelText: 'Student ID',
                            labelStyle: Theme.of(context).textTheme.labelSmall,
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(8.0),
                            ),
                          ),
                          validator: (value) {
                            if (value == null || value.isEmpty) {
                              return 'Please enter your student ID';
                            }
                            return null;
                          },
                        ),
                        const SizedBox(height: 20),
                        if (_uploadedImage != null)
                          GestureDetector(
                            onTap: () => _viewImage(context),
                            child: Image.file(
                              _uploadedImage!,
                              height: 150,
                              width: 150,
                            ),
                          ),
                        const SizedBox(height: 20),
                        ElevatedButton.icon(
                          style: ElevatedButton.styleFrom(
                            padding: const EdgeInsets.symmetric(
                                vertical: 16.0, horizontal: 24.0),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(8.0),
                            ),
                          ),
                          icon: const Icon(Icons.image),
                          label: Text('Pick Student ID Image',
                              style: Theme.of(context).textTheme.labelSmall),
                          onPressed: () {
                            showModalBottomSheet(
                              context: context,
                              builder: (context) => SafeArea(
                                child: Column(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    ListTile(
                                      leading: Icon(Icons.camera),
                                      title: Text('Take a Picture'),
                                      onTap: () {
                                        Navigator.pop(context);
                                        _pickImage(context, ImageSource.camera);
                                      },
                                    ),
                                    ListTile(
                                      leading: Icon(Icons.photo),
                                      title: Text('Upload from Gallery'),
                                      onTap: () {
                                        Navigator.pop(context);
                                        _pickImage(
                                            context, ImageSource.gallery);
                                      },
                                    ),
                                  ],
                                ),
                              ),
                            );
                          },
                        ),
                        const SizedBox(height: 20),
                        ElevatedButton(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.blueAccent,
                            padding: const EdgeInsets.symmetric(
                                vertical: 16.0, horizontal: 24.0),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(8.0),
                            ),
                          ),
                          onPressed: () => _saveDetails(context),
                          child: Text('Save and Continue',
                              style: Theme.of(context).textTheme.labelLarge),
                        ),
                      ],
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
}
