import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:marianmemories/screens/NewEntrypage.dart';
import 'package:marianmemories/screens/collegeentrypage.dart';
import 'package:marianmemories/screens/dairyhomepge.dart';
import 'package:marianmemories/screens/homepage.dart';
import 'package:marianmemories/screens/profilescreen.dart';
import 'package:marianmemories/screens/signup.dart';
import 'package:marianmemories/screens/welcome_screen.dart';
import 'package:marianmemories/screens/admin_config.dart';
import 'firebase_options.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

  try {
    if (await AdminConfig.needsInitialSetup()) {
      await AdminConfig.setupInitialAdmin();
      print('Admin setup completed successfully');
    }
  } catch (e) {
    print('Error during admin setup: $e');
  }

  runApp(const MarianMemoriesApp());
}

class MarianMemoriesApp extends StatelessWidget {
  const MarianMemoriesApp({super.key});

  @override
  Widget build(BuildContext context) {
    return GetMaterialApp( // Changed to GetMaterialApp
      debugShowCheckedModeBanner: false,
      title: 'Marian Memories',
      theme: ThemeData(
        primarySwatch: Colors.orange,
        primaryColor: const Color.fromRGBO(49, 39, 79, 1),
        scaffoldBackgroundColor: Colors.white,
      ),
      home: const WelcomeScreen(),
    );
  }
}