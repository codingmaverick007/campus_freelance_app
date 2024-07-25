import 'package:campus_freelance_app/firebase_options.dart';
import 'package:campus_freelance_app/providers/user_data_provider.dart';
import 'package:campus_freelance_app/screens/splash_screen.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'providers/freelancer_provider.dart';
import 'package:rxdart/rxdart.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (ctx) => FreelancerProvider()),
        ChangeNotifierProvider(create: (ctx) => UserData()),
      ],
      child: MaterialApp(
        debugShowCheckedModeBanner: false,
        title: 'Campus Freelance App',
        theme: ThemeData(
          primaryColor: const Color(0xFF007BFF),
          scaffoldBackgroundColor: const Color(0xFFF8F9FA),
          colorScheme: ColorScheme.fromSeed(seedColor: Colors.blue),
          tabBarTheme: const TabBarTheme(
            labelColor: Colors.blue, // Change as per your design
            unselectedLabelColor: Colors.grey,
            indicator: UnderlineTabIndicator(
              borderSide:
                  BorderSide(width: 2.0, color: Colors.blue), // Indicator color
              insets:
                  EdgeInsets.symmetric(horizontal: 16.0), // Indicator padding
            ),
          ),
          textTheme: TextTheme(
            headlineLarge: GoogleFonts.montserrat(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: Colors.black,
            ),
            headlineMedium: GoogleFonts.montserrat(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: Colors.black,
            ),
            headlineSmall: GoogleFonts.montserrat(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: Colors.black,
            ),
            titleLarge: GoogleFonts.montserrat(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: Colors.black,
            ),
            titleMedium: GoogleFonts.montserrat(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: Colors.black,
            ),
            titleSmall: GoogleFonts.montserrat(
              fontSize: 14,
              fontWeight: FontWeight.bold,
              color: Colors.black,
            ),
            displayLarge: GoogleFonts.montserrat(
              fontSize: 30,
              fontWeight: FontWeight.bold,
              color: Colors.black,
            ),
            displayMedium: GoogleFonts.montserrat(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: const Color(0xFF343A40),
            ),
            displaySmall: GoogleFonts.montserrat(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: const Color(0xFF343A40),
            ),
            bodyLarge: GoogleFonts.openSans(
              fontSize: 18,
              fontWeight: FontWeight.w500,
              color: Colors.black,
            ),
            bodyMedium: GoogleFonts.openSans(
              fontSize: 16,
              fontWeight: FontWeight.normal,
              color: Colors.black,
            ),
            bodySmall: GoogleFonts.openSans(
              fontSize: 18,
              fontWeight: FontWeight.normal,
              color: const Color(0xFF343A40),
            ),
            labelLarge: GoogleFonts.openSans(
              fontSize: 20,
              fontWeight: FontWeight.w500,
              color: Colors.white,
            ),
            labelMedium: GoogleFonts.openSans(
              fontSize: 14,
              fontWeight: FontWeight.normal,
              color: Colors.blue,
            ),
            labelSmall: GoogleFonts.openSans(
              fontSize: 14,
              fontWeight: FontWeight.normal,
              color: Colors.black,
            ),
          ),
        ),
        home: SplashScreen(),
      ),
    );
  }
}
