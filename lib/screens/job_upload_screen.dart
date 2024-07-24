import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_chip_tags/flutter_chip_tags.dart'; // Reintroduced for job tags
import 'package:lottie/lottie.dart';
import 'package:uuid/uuid.dart';

class JobUploadScreen extends StatefulWidget {
  @override
  State<JobUploadScreen> createState() => _JobUploadScreenState();
}

class _JobUploadScreenState extends State<JobUploadScreen> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _titleController = TextEditingController();
  final TextEditingController _descriptionController = TextEditingController();
  final TextEditingController _locationController = TextEditingController();
  final TextEditingController _requirementsController = TextEditingController();
  final TextEditingController _tagsController = TextEditingController();

  List<String> _requirementsList = [];
  List<String> _jobTagsList = [];
  bool _isLoading = false;
  String? _selectedCategory;

  final List<String> _categories = [
    'Tutoring',
    'Proofreading and Editing',
    'Graphic Design',
    'Photography and Videography',
    'Writing',
    'IT Support',
    'Web Development',
    'App Development',
    'Data Entry',
    'Virtual Assistance',
    'Event Planning',
    'Event Assistance',
    'Fitness Training',
    'Language Lessons',
    'Music Lessons',
    'Handyman Services',
    'Moving Assistance',
    'House Sitting / Pet Sitting',
    'Custom Requests',
  ];

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    _locationController.dispose();
    _requirementsController.dispose();
    _tagsController.dispose();
    super.dispose();
  }

  void _addRequirement() {
    if (_requirementsController.text.isNotEmpty) {
      setState(() {
        _requirementsList.add(_requirementsController.text);
        _requirementsController.clear();
      });
    }
  }

  void _addTag() {
    if (_tagsController.text.isNotEmpty) {
      setState(() {
        _jobTagsList.add(_tagsController.text);
        _tagsController.clear();
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Post a Job'),
        backgroundColor: Colors.blue,
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Center(
                  child: SizedBox(
                    height: 200,
                    child: Lottie.asset('assets/animations/post.json'),
                  ),
                ),
                const SizedBox(height: 20),
                Text(
                  'Job Title',
                  style: Theme.of(context).textTheme.bodySmall,
                ),
                TextFormField(
                  controller: _titleController,
                  decoration: _inputDecoration(),
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Please enter a job title';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 20),
                Text(
                  'Job Description',
                  style: Theme.of(context).textTheme.bodySmall,
                ),
                TextFormField(
                  controller: _descriptionController,
                  decoration: _inputDecoration(),
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Please enter a job description';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 20),
                Text(
                  'Select Category',
                  style: Theme.of(context).textTheme.bodySmall,
                ),
                DropdownButtonFormField<String>(
                  value: _selectedCategory,
                  hint: const Text('Select Category'),
                  decoration: _inputDecoration(),
                  items: _categories.map((String category) {
                    return DropdownMenuItem<String>(
                      value: category,
                      child: Text(category),
                    );
                  }).toList(),
                  onChanged: (newValue) {
                    setState(() {
                      _selectedCategory = newValue;
                    });
                  },
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Please select a category';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 20),
                Text(
                  'Enter tags',
                  style: Theme.of(context).textTheme.bodySmall,
                ),
                _jobTagsInput(),
                const SizedBox(height: 20),
                Text(
                  'Requirements',
                  style: Theme.of(context).textTheme.bodySmall,
                ),
                Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: _requirementsController,
                        decoration: InputDecoration(
                          labelText: 'Enter requirement',
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(20.0),
                          ),
                          suffixIcon: IconButton(
                            icon: Icon(Icons.add),
                            onPressed: _addRequirement,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                _requirementsList.isNotEmpty
                    ? Wrap(
                        spacing: 8.0,
                        runSpacing: 4.0,
                        children: _requirementsList
                            .map((requirement) => Chip(
                                  label: Text(requirement,
                                      style: TextStyle(
                                          fontSize:
                                              12)), // Smaller font size for requirements
                                  onDeleted: () {
                                    setState(() {
                                      _requirementsList.remove(requirement);
                                    });
                                  },
                                  deleteIcon: Icon(Icons.close,
                                      size: 16), // Smaller delete icon
                                  backgroundColor: Colors.blue.withOpacity(0.2),
                                ))
                            .toList(),
                      )
                    : Container(),
                const SizedBox(height: 20),
                Text(
                  'Enter Location',
                  style: Theme.of(context).textTheme.bodySmall,
                ),
                TextFormField(
                  controller: _locationController,
                  decoration: _inputDecoration(),
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Please enter a location';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 30),
                _postJobButton(),
              ],
            ),
          ),
        ),
      ),
    );
  }

  InputDecoration _inputDecoration() {
    return InputDecoration(
      border: OutlineInputBorder(
        borderSide: const BorderSide(color: Colors.black),
        borderRadius: BorderRadius.circular(20.0),
      ),
      contentPadding: EdgeInsets.symmetric(horizontal: 16.0, vertical: 12.0),
    );
  }

  Widget _jobTagsInput() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Expanded(
              child: TextFormField(
                controller: _tagsController,
                decoration: InputDecoration(
                  border: OutlineInputBorder(
                    borderSide: const BorderSide(color: Colors.black),
                    borderRadius: BorderRadius.circular(20.0),
                  ),
                  contentPadding:
                      EdgeInsets.symmetric(horizontal: 16.0, vertical: 12.0),
                  suffixIcon: IconButton(
                    icon: Icon(Icons.add),
                    onPressed: () {
                      if (_tagsController.text.isNotEmpty) {
                        _addTag();
                      }
                    },
                  ),
                ),
                onFieldSubmitted: (value) {
                  if (value.isNotEmpty) {
                    _addTag();
                  }
                },
              ),
            ),
          ],
        ),
        const SizedBox(height: 10),
        _jobTagsList.isNotEmpty
            ? Wrap(
                spacing: 8.0,
                runSpacing: 4.0,
                children: _jobTagsList
                    .map((tag) => Chip(
                          label: Text(tag,
                              style: TextStyle(
                                  fontSize: 12)), // Smaller font size for tags
                          onDeleted: () {
                            setState(() {
                              _jobTagsList.remove(tag);
                            });
                          },
                          deleteIcon: Icon(Icons.close,
                              size: 16), // Smaller delete icon
                          backgroundColor: Colors.blue.withOpacity(0.2),
                        ))
                    .toList(),
              )
            : Container(),
      ],
    );
  }

  Widget _postJobButton() {
    return InkWell(
      onTap: _isLoading ? null : () => _submitJob(context),
      child: Container(
        height: 50,
        width: double.infinity,
        color: _isLoading ? Colors.grey : Colors.blue,
        child: Center(
          child: _isLoading
              ? const CircularProgressIndicator(color: Colors.white)
              : const Text(
                  'Post Job',
                  style: TextStyle(color: Colors.white, fontSize: 20),
                ),
        ),
      ),
    );
  }

  void _submitJob(BuildContext context) async {
    final jobId = const Uuid().v4();
    User? user = FirebaseAuth.instance.currentUser;
    final _uid = user!.uid;

    if (_formKey.currentState!.validate()) {
      setState(() {
        _isLoading = true;
      });
      try {
        await FirebaseFirestore.instance.collection('jobs').doc(jobId).set({
          'jobId': jobId,
          'jobTitle': _titleController.text,
          'uploadedBy': _uid,
          'status': 'open',
          'email': user.email,
          'jobDescription': _descriptionController.text,
          'jobCategory': _selectedCategory,
          'jobTags': _jobTagsList, // Updated field
          'location': _locationController.text,
          'requirements': _requirementsList,
          'createdAt': Timestamp.now(),
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Job Posted Successfully!')),
        );
        _clearForm();
        Navigator.of(context).pop();
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: ${e.toString()}')),
        );
      } finally {
        setState(() {
          _isLoading = false;
        });
      }
    } else {
      print('Form is not valid');
    }
  }

  void _clearForm() {
    _titleController.clear();
    _descriptionController.clear();
    _locationController.clear();
    _requirementsController.clear();
    _tagsController.clear();
    setState(() {
      _requirementsList.clear();
      _jobTagsList.clear();
      _selectedCategory = null;
    });
  }
}
