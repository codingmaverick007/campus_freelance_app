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
  late List<String> _tags;

  @override
  void initState() {
    super.initState();
    _titleController = TextEditingController();
    _descriptionController = TextEditingController();
    _requirementsController = TextEditingController();
    _locationController = TextEditingController();
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
        actions: [
          IconButton(
            icon: const Icon(Icons.save),
            onPressed: _saveJobDetails,
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                TextFormField(
                  controller: _titleController,
                  decoration: const InputDecoration(labelText: 'Job Title'),
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Please enter a job title';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 16.0),
                TextFormField(
                  controller: _descriptionController,
                  decoration:
                      const InputDecoration(labelText: 'Job Description'),
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Please enter a job description';
                    }
                    return null;
                  },
                  maxLines: 3,
                ),
                const SizedBox(height: 16.0),
                TextFormField(
                  controller: _requirementsController,
                  decoration: const InputDecoration(labelText: 'Requirements'),
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Please enter the job requirements';
                    }
                    return null;
                  },
                  maxLines: 3,
                ),
                const SizedBox(height: 16.0),
                TextFormField(
                  controller: _locationController,
                  decoration: const InputDecoration(labelText: 'Location'),
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
                    );
                  }).toList(),
                ),
                TextFormField(
                  decoration: const InputDecoration(labelText: 'Add a tag'),
                  onFieldSubmitted: (value) {
                    if (value.isNotEmpty) {
                      _addTag(value);
                    }
                  },
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
