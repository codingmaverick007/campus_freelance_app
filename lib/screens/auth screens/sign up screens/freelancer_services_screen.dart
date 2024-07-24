import 'package:campus_freelance_app/screens/auth%20screens/sign%20up%20screens/finish_profile_screen.dart';
import 'package:flutter/material.dart';
import 'package:lottie/lottie.dart';
import 'package:provider/provider.dart';
import 'package:campus_freelance_app/providers/user_data_provider.dart';

class FreelancerServicesScreen extends StatefulWidget {
  const FreelancerServicesScreen({Key? key}) : super(key: key);

  @override
  _FreelancerServicesScreenState createState() =>
      _FreelancerServicesScreenState();
}

class _FreelancerServicesScreenState extends State<FreelancerServicesScreen> {
  final TextEditingController _servicesController = TextEditingController();

  @override
  void dispose() {
    _servicesController.dispose();
    super.dispose();
  }

  void _addService(BuildContext context) {
    final userData = Provider.of<UserData>(context, listen: false);
    final service = _servicesController.text.trim();
    if (service.isNotEmpty) {
      userData.updateServices([...userData.services, service]);
      _servicesController.clear();
    }
  }

  @override
  Widget build(BuildContext context) {
    final userData = Provider.of<UserData>(context);

    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
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
                    'Your Services',
                    style: Theme.of(context).textTheme.displayLarge,
                  ),
                ],
              ),
              Lottie.asset('assets/animations/work animation.json'),
              TextField(
                controller: _servicesController,
                decoration: InputDecoration(
                  labelText: 'Enter a service',
                  suffixIcon: IconButton(
                    icon:
                        Icon(Icons.add, color: Theme.of(context).primaryColor),
                    onPressed: () => _addService(context),
                  ),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8.0),
                  ),
                ),
              ),
              const SizedBox(height: 20),
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: Theme.of(context).primaryColor,
                  padding: EdgeInsets.symmetric(vertical: 16.0),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8.0),
                  ),
                ),
                onPressed: () {
                  _addService(context);
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                        builder: (context) => const FinishProfileScreen()),
                  );
                },
                child: Text(
                  'Add Service',
                  style: Theme.of(context).textTheme.labelSmall,
                ),
              ),
              const SizedBox(height: 20),
              Expanded(
                child: ListView.builder(
                  itemCount: userData.services.length,
                  itemBuilder: (context, index) => Card(
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8.0),
                    ),
                    child: ListTile(
                      title: Text(userData.services[index]),
                      trailing: IconButton(
                        icon: const Icon(Icons.delete, color: Colors.red),
                        onPressed: () {
                          final updatedServices = [...userData.services];
                          updatedServices.removeAt(index);
                          userData.updateServices(updatedServices);
                        },
                      ),
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
