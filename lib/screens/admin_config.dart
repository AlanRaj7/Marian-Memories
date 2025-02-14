// lib/config/admin_config.dart

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class AdminConfig {
  // Admin credentials
  static const String adminEmail = "alanraj7755@gmail.com";
  static const String adminPassword = "12345678";
  
  // Check if initial setup is needed
  static Future<bool> needsInitialSetup() async {
    QuerySnapshot adminQuery = await FirebaseFirestore.instance
        .collection('users')
        .where('role', isEqualTo: 'admin')
        .limit(1)
        .get();
    
    return adminQuery.docs.isEmpty;
  }

  // Setup initial admin account
  static Future<void> setupInitialAdmin() async {
    try {
      // Check if admin already exists in Auth
      try {
        await FirebaseAuth.instance.signInWithEmailAndPassword(
          email: adminEmail,
          password: adminPassword,
        );
        // If successful, admin already exists
        await FirebaseAuth.instance.signOut();
        return;
      } catch (e) {
        // Admin doesn't exist, continue with creation
      }

      // Create admin in Firebase Auth
      UserCredential userCredential = 
          await FirebaseAuth.instance.createUserWithEmailAndPassword(
        email: adminEmail,
        password: adminPassword,
      );

      // Set admin data in Firestore
      await FirebaseFirestore.instance
          .collection('users')
          .doc(userCredential.user!.uid)
          .set({
        'email': adminEmail,
        'role': 'admin',
        'name': 'System Admin',
        'created_at': FieldValue.serverTimestamp(),
      });

      print('Initial admin account created successfully');
      await FirebaseAuth.instance.signOut();
    } catch (e) {
      print('Error in admin setup: $e');
    }
  }

  static verifyAdminRole(String uid) {}
}