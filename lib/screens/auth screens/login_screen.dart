import 'package:campus_freelance_app/providers/user_data_provider.dart';
import 'package:campus_freelance_app/screens/auth%20screens/forgot_password.dart';
import 'package:campus_freelance_app/screens/auth%20screens/sign%20up%20screens/signup_screen.dart';
import 'package:campus_freelance_app/screens/screen_scaffold.dart';
import 'package:campus_freelance_app/user_state.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:lottie/lottie.dart';
import 'package:provider/provider.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final GlobalKey<FormState> _loginFormKey = GlobalKey<FormState>();
  String? _email;
  String? _password;
  bool _isObscure = true;
  final TextEditingController _emailTextController =
      TextEditingController(text: '');
  final TextEditingController _passwordTextController =
      TextEditingController(text: '');
  bool _isLoading = false;

  final FirebaseAuth _auth = FirebaseAuth.instance;

  @override
  void dispose() {
    _emailTextController.dispose();
    _passwordTextController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Column(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          Text(
            'Login',
            style: Theme.of(context).textTheme.displayLarge,
          ),
          Center(
            child: Lottie.asset('assets/animations/login.json'),
          ),
          SingleChildScrollView(
            padding: const EdgeInsets.all(12.0),
            child: Form(
              key: _loginFormKey,
              child: Column(
                mainAxisSize: MainAxisSize.max,
                children: [
                  TextFormField(
                    keyboardType: TextInputType.emailAddress,
                    decoration: InputDecoration(
                      labelText: 'Email',
                      border: OutlineInputBorder(
                        borderSide: const BorderSide(color: Colors.black),
                        borderRadius: BorderRadius.circular(12.0),
                      ),
                    ),
                    controller: _emailTextController,
                    onSaved: (_value) {
                      setState(() {
                        _email = _value;
                      });
                    },
                    validator: (_value) {
                      bool _result = _value!.contains(
                        RegExp(
                            r"^[a-zA-Z0-9.!#$%&'*+/=?^_`{|}~-]+@[a-zA-Z0-9](?:[a-zA-Z0-9-]{0,61}[a-zA-Z0-9])?(?:\.[a-zA-Z0-9](?:[a-zA-Z0-9-]{0,61}[a-zA-Z0-9])?)*$"),
                      );
                      return _result ? null : "Please enter a valid email";
                    },
                  ),
                  const SizedBox(height: 16),
                  TextFormField(
                    decoration: InputDecoration(
                      labelText: 'Password',
                      border: OutlineInputBorder(
                        borderSide: const BorderSide(color: Colors.black),
                        borderRadius: BorderRadius.circular(12.0),
                      ),
                      suffixIcon: GestureDetector(
                        onTap: () {
                          setState(() {
                            _isObscure = !_isObscure;
                          });
                        },
                        child: Icon(_isObscure
                            ? Icons.visibility_off
                            : Icons.visibility),
                      ),
                    ),
                    obscureText: _isObscure,
                    controller: _passwordTextController,
                    onSaved: (_value) {
                      setState(() {
                        _password = _value;
                      });
                    },
                    validator: (_value) => _value!.length > 6
                        ? null
                        : "Please enter a password greater than 6 characters.",
                  ),
                  Align(
                    alignment: AlignmentDirectional.bottomEnd,
                    child: TextButton(
                      onPressed: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                              builder: (context) => ForgotPasswordScreen()),
                        );
                      },
                      child: Text('Forgot Password?',
                          style: Theme.of(context).textTheme.labelMedium),
                    ),
                  ),
                  const SizedBox(height: 35),
                  loginButton(),
                  const SizedBox(height: 70),
                  TextButton(
                    onPressed: () {
                      Navigator.pushReplacement(
                        context,
                        MaterialPageRoute(
                            builder: (context) => const SignUpScreen()),
                      );
                    },
                    child: Text('Don\'t have an account? Sign up',
                        style: Theme.of(context).textTheme.labelMedium),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget loginButton() {
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton(
        style: ButtonStyle(
          backgroundColor: WidgetStateProperty.all<Color>(
              Color(0xFF007BFF)), // Primary color
          padding: WidgetStateProperty.all<EdgeInsets>(
            EdgeInsets.symmetric(vertical: 16.0), // Padding inside the button
          ),
          shape: WidgetStateProperty.all<RoundedRectangleBorder>(
            RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(30.0), // Rounded corners
            ),
          ),
        ),
        onPressed: () {
          _loginUser();
        },
        child: _isLoading
            ? const CircularProgressIndicator()
            : Text('Login', style: Theme.of(context).textTheme.labelLarge),
      ),
    );
  }

  Future<void> _loginUser() async {
    if (_loginFormKey.currentState!.validate()) {
      _loginFormKey.currentState!.save();
      setState(() {
        _isLoading = true;
      });
      try {
        UserCredential userCredential = await _auth.signInWithEmailAndPassword(
          email: _emailTextController.text.trim().toLowerCase(),
          password: _passwordTextController.text.trim(),
        );

        // Get the FCM token
        String? fcmToken = await FirebaseMessaging.instance.getToken();

        // Update the FCM token in Firestore
        if (fcmToken != null) {
          await FirebaseFirestore.instance
              .collection('users')
              .doc(userCredential.user!.uid)
              .update({'fcmToken': fcmToken});
        }
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => const UserState()),
        );
      } catch (e) {
        setState(() {
          _isLoading = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error occured ${e.toString()}')),
        );
      }
    }
  }
}
