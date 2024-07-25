import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class EditJobScreen extends StatefulWidget {
  final String jobId;

  EditJobScreen({super.key, required this.jobId});

  @override
  _EditJobScreenState createState() => _EditJobScreenState();
}

class _EditJobScreenState extends State<EditJobScreen> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _titleController;
  late TextEditingController _descriptionController;
  late TextEditingController _requirementsController;
  late TextEditingController _locationController;
  late TextEditingController _tagController;
  late List<String> _tags;

  @override
  void initState() {
    super.initState();
    _titleController = TextEditingController();
    _descriptionController = TextEditingController();
    _requirementsController = TextEditingController();
    _locationController = TextEditingController();
    _tagController = TextEditingController();
    _tags = [];

    _loadJobDetails();
  }

  Future<void> _loadJobDetails() async {
    DocumentSnapshot jobDoc = await FirebaseFirestore.instance
        .collection('jobs')
        .doc(widget.jobId)
        .get();

    Map<String, dynamic> jobData = jobDoc.data() as Map<String, dynamic>;
    _titleController.text = jobData['jobTitle'] ?? '';
    _descriptionController.text = jobData['jobDescription'] ?? '';
    _requirementsController.text = jobData['requirements'] ?? '';
    _locationController.text = jobData['location'] ?? '';
    _tags = List<String>.from(jobData['jobTags'] ?? []);
    setState(() {});
  }

  Future<void> _saveJobDetails() async {
    if (_formKey.currentState?.validate() ?? false) {
      await FirebaseFirestore.instance
          .collection('jobs')
          .doc(widget.jobId)
          .update({
        'jobTitle': _titleController.text,
        'jobDescription': _descriptionController.text,
        'requirements': _requirementsController.text,
        'location': _locationController.text,
        'jobTags': _tags,
      });

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Job details updated successfully')),
      );

      Navigator.of(context).pop();
    }
  }

  void _addTag(String tag) {
    setState(() {
      _tags.add(tag);
      _tagController.clear();
    });
  }

  void _removeTag(String tag) {
    setState(() {
      _tags.remove(tag);
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Edit Job'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                buildTextFormField(
                  controller: _titleController,
                  label: 'Job Title',
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Please enter a job title';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 16.0),
                buildTextFormField(
                  controller: _descriptionController,
                  label: 'Job Description',
                  maxLines: 3,
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Please enter a job description';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 16.0),
                buildTextFormField(
                  controller: _requirementsController,
                  label: 'Requirements',
                  maxLines: 3,
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Please enter the job requirements';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 16.0),
                buildTextFormField(
                  controller: _locationController,
                  label: 'Location',
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Please enter the job location';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 16.0),
                const Text('Tags', style: TextStyle(fontSize: 16)),
                Wrap(
                  spacing: 8.0,
                  children: _tags.map((tag) {
                    return Chip(
                      label: Text(tag),
                      onDeleted: () => _removeTag(tag),
                      backgroundColor: Colors.blueAccent,
                      labelStyle: const TextStyle(color: Colors.white),
                    );
                  }).toList(),
                ),
                buildTextFormField(
                  controller: _tagController,
                  label: 'Add a tag',
                  onFieldSubmitted: (value) {
                    if (value.isNotEmpty) {
                      _addTag(value);
                    }
                  },
                ),
                const SizedBox(height: 16.0),
                Align(
                  alignment: Alignment.centerRight,
                  child: ElevatedButton.icon(
                    onPressed: () {
                      if (_tagController.text.isNotEmpty) {
                        _addTag(_tagController.text);
                      }
                    },
                    icon: const Icon(Icons.add),
                    label: const Text('Add Tag'),
                    style: ElevatedButton.styleFrom(
                        iconColor: Colors.blue,
                        backgroundColor: Colors.white,
                        foregroundColor: Colors.blue,
                        maximumSize: Size(200, 50)),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
      bottomNavigationBar: Padding(
        padding: const EdgeInsets.all(16.0),
        child: ElevatedButton.icon(
          onPressed: _saveJobDetails,
          icon: const Icon(Icons.save),
          label: Text(
            'Save',
            style: Theme.of(context).textTheme.labelLarge,
          ),
          style: ElevatedButton.styleFrom(
            padding: const EdgeInsets.symmetric(vertical: 16.0),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(30.0),
            ),
            iconColor: Colors.white,
            backgroundColor: Colors.blue,
            foregroundColor: Colors.white,
          ),
        ),
      ),
    );
  }

  Widget buildTextFormField({
    required TextEditingController controller,
    required String label,
    int maxLines = 1,
    FormFieldValidator<String>? validator,
    ValueChanged<String>? onFieldSubmitted,
  }) {
    return TextFormField(
      controller: controller,
      decoration: InputDecoration(
        labelText: label,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(20.0),
        ),
      ),
      validator: validator,
      maxLines: maxLines,
      onFieldSubmitted: onFieldSubmitted,
    );
  }
}
