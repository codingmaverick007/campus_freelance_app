import 'package:flutter/material.dart';
import 'package:lottie/lottie.dart';
import 'package:provider/provider.dart';
import 'package:campus_freelance_app/providers/user_data_provider.dart';
import 'package:campus_freelance_app/screens/auth%20screens/sign%20up%20screens/finish_profile_screen.dart';
import 'package:campus_freelance_app/screens/auth%20screens/sign%20up%20screens/freelancer_services_screen.dart';

class UserTypeScreen extends StatefulWidget {
  @override
  _UserTypeScreenState createState() => _UserTypeScreenState();
}

class _UserTypeScreenState extends State<UserTypeScreen> {
  final TextEditingController _titleController = TextEditingController();
  bool _isFreelancerSelected = false;
  bool _isLoading = false;

  @override
  Widget build(BuildContext context) {
    final userData = Provider.of<UserData>(context);

    void saveUserRole(bool isFreelancer) {
      setState(() {
        _isLoading = true;
      });

      userData.updateIsFreelancer(isFreelancer);

      if (isFreelancer) {
        userData.updateTitle(_titleController.text); // Update job title
      }

      if (isFreelancer) {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => FreelancerServicesScreen(),
          ),
        );
      } else {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => FinishProfileScreen(),
          ),
        );
      }

      setState(() {
        _isLoading = false;
      });
    }

    return Scaffold(
      appBar: AppBar(title: Text('User Type')),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Lottie.asset('assets/animations/startup.json'),
              const SizedBox(height: 20),
              const Text(
                'Are you a freelancer or a client?',
                style: TextStyle(fontSize: 20.0, fontWeight: FontWeight.bold),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 20),
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                  foregroundColor: _isFreelancerSelected
                      ? Colors.grey
                      : Theme.of(context).primaryColor,
                  padding: EdgeInsets.symmetric(vertical: 16.0),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8.0),
                  ),
                ),
                onPressed: () {
                  setState(() {
                    _isFreelancerSelected = true;
                  });
                },
                child: const Text(
                  'Freelancer',
                  style: TextStyle(fontSize: 16, color: Colors.white),
                ),
              ),
              const SizedBox(height: 10),
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                  foregroundColor: !_isFreelancerSelected
                      ? Colors.grey
                      : Theme.of(context).primaryColor,
                  padding: EdgeInsets.symmetric(vertical: 16.0),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8.0),
                  ),
                ),
                onPressed: () {
                  setState(() {
                    _isFreelancerSelected = false;
                  });
                  saveUserRole(false);
                },
                child: const Text(
                  'Client',
                  style: TextStyle(fontSize: 16, color: Colors.white),
                ),
              ),
              if (_isFreelancerSelected) ...[
                const SizedBox(height: 20),
                TextFormField(
                  controller: _titleController,
                  decoration: InputDecoration(
                    labelText: 'Job Title',
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8.0),
                    ),
                  ),
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Please enter a job title';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 20),
                ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    foregroundColor: Theme.of(context).primaryColor,
                    padding: EdgeInsets.symmetric(vertical: 16.0),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8.0),
                    ),
                  ),
                  onPressed: _isLoading
                      ? null
                      : () {
                          if (_titleController.text.isNotEmpty) {
                            saveUserRole(true);
                          } else {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                  content: Text('Please enter a job title')),
                            );
                          }
                        },
                  child: _isLoading
                      ? CircularProgressIndicator(color: Colors.white)
                      : const Text(
                          'Continue as Freelancer',
                          style: TextStyle(fontSize: 16, color: Colors.white),
                        ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
