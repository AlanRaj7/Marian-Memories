import 'package:animate_do/animate_do.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:get/get.dart';
import 'package:line_awesome_flutter/line_awesome_flutter.dart';
import 'package:marianmemories/screens/admin_dashboard.dart';
import 'package:marianmemories/screens/homepage.dart';
import 'package:marianmemories/screens/signup.dart';

class WelcomeScreen extends StatelessWidget {
  const WelcomeScreen({super.key});

  Future<bool> validateAdmin(String email, String password) async {
    try {
      // Query Firestore for admin credentials
      final QuerySnapshot adminSnapshot = await FirebaseFirestore.instance
          .collection('admin')
          .where('email', isEqualTo: email)
          .where('password', isEqualTo: password)
          .limit(1)  // Added limit for efficiency
          .get();

      return adminSnapshot.docs.isNotEmpty;
    } catch (e) {
      debugPrint('Error validating admin: $e');
      return false;
    }
  }

  void showErrorSnackbar(String message) {
    Get.closeAllSnackbars(); // Close any existing snackbars
    Get.snackbar(
      'Error',
      message,
      snackPosition: SnackPosition.BOTTOM,
      backgroundColor: Colors.red.withOpacity(0.9),
      colorText: Colors.white,
      margin: const EdgeInsets.all(10),
      duration: const Duration(seconds: 3),
      borderRadius: 10,
      isDismissible: true,
      dismissDirection: DismissDirection.horizontal,
    );
  }

  void showSuccessSnackbar(String message) {
    Get.closeAllSnackbars(); // Close any existing snackbars
    Get.snackbar(
      'Success',
      message,
      snackPosition: SnackPosition.BOTTOM,
      backgroundColor: Colors.green.withOpacity(0.9),
      colorText: Colors.white,
      margin: const EdgeInsets.all(10),
      duration: const Duration(seconds: 2),
      borderRadius: 10,
      isDismissible: true,
      dismissDirection: DismissDirection.horizontal,
    );
  }

  Widget _buildAdminLoginDialog(BuildContext context) {
    final TextEditingController emailController = TextEditingController();
    final TextEditingController passwordController = TextEditingController();
    final FocusNode emailFocus = FocusNode();
    final FocusNode passwordFocus = FocusNode();

    return Dialog(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
      ),
      child: Container(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  "Admin Login",
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: Color.fromRGBO(49, 39, 79, 1),
                  ),
                ),
                IconButton(
                  onPressed: () => Get.back(),
                  icon: const Icon(LineAwesomeIcons.times),
                ),
              ],
            ),
            const SizedBox(height: 20),
            TextField(
              controller: emailController,
              focusNode: emailFocus,
              keyboardType: TextInputType.emailAddress,
              textInputAction: TextInputAction.next,
              onSubmitted: (_) => passwordFocus.requestFocus(),
              decoration: InputDecoration(
                labelText: "Admin Email",
                prefixIcon: const Icon(LineAwesomeIcons.envelope),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                  borderSide: const BorderSide(color: Colors.grey),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                  borderSide: const BorderSide(
                    color: Color.fromRGBO(49, 39, 79, 1),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 15),
            TextField(
              controller: passwordController,
              focusNode: passwordFocus,
              obscureText: true,
              textInputAction: TextInputAction.done,
              onSubmitted: (_) async {
                // Trigger login when Enter/Done is pressed
                await _handleLogin(
                  emailController.text.trim(),
                  passwordController.text,
                );
              },
              decoration: InputDecoration(
                labelText: "Admin Password",
                prefixIcon: const Icon(LineAwesomeIcons.lock),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                  borderSide: const BorderSide(color: Colors.grey),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                  borderSide: const BorderSide(
                    color: Color.fromRGBO(49, 39, 79, 1),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 20),
            MaterialButton(
              onPressed: () async {
                await _handleLogin(
                  emailController.text.trim(),
                  passwordController.text,
                );
              },
              color: const Color.fromRGBO(196, 135, 198, 1),
              minWidth: double.infinity,
              height: 45,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Text(
                "Login",
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 16,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _handleLogin(String email, String password) async {
    if (email.isEmpty || password.isEmpty) {
      showErrorSnackbar("Please fill in all fields");
      return;
    }

    try {
      // Show loading indicator
      Get.dialog(
        const Center(
          child: CircularProgressIndicator(),
        ),
        barrierDismissible: false,
      );

      // Validate admin credentials
      final isValid = await validateAdmin(email, password);

      // Hide loading indicator
      Get.back();

      if (isValid) {
        Get.back(); // Close login dialog
        showSuccessSnackbar("Login successful!");
        // Navigate to admin dashboard using GetX
        await Get.offAll(() => const AdminDashboard());
      } else {
        showErrorSnackbar("Invalid email or password");
      }
    } catch (e) {
      Get.back(); // Hide loading indicator
      showErrorSnackbar("An error occurred. Please try again.");
      debugPrint('Login error: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: SingleChildScrollView(
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 30),
            height: MediaQuery.of(context).size.height,
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                // Logo Section
                FadeInUp(
                  duration: const Duration(milliseconds: 1000),
                  child: Container(
                    height: 200,
                    decoration: const BoxDecoration(
                      image: DecorationImage(
                        image: AssetImage('assets/background.png'),
                        fit: BoxFit.contain,
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 40),
                
                // Welcome Text
                FadeInUp(
                  duration: const Duration(milliseconds: 1200),
                  child: const Text(
                    "Welcome To Marian Memories!",
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 30,
                      fontWeight: FontWeight.bold,
                      color: Color.fromRGBO(49, 39, 79, 1),
                    ),
                  ),
                ),
                const SizedBox(height: 10),
                FadeInUp(
                  duration: const Duration(milliseconds: 1300),
                  child: const Text(
                    "All marinates under one umbrella.",
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 16,
                      color: Colors.grey,
                    ),
                  ),
                ),
                const SizedBox(height: 60),

                // Sign In Button
                FadeInUp(
                  duration: const Duration(milliseconds: 1400),
                  child: MaterialButton(
                    onPressed: () => Get.to(() => const HomePage()),
                    height: 50,
                    color: const Color.fromRGBO(49, 39, 79, 1),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(50),
                    ),
                    minWidth: double.infinity,
                    child: const Text(
                      "Sign In",
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 16,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 20),

                // Sign Up Button
                FadeInUp(
                  duration: const Duration(milliseconds: 1500),
                  child: MaterialButton(
                    onPressed: () => Get.to(() => const SignUpScreen()),
                    height: 50,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(50),
                      side: const BorderSide(
                        color: Color.fromRGBO(49, 39, 79, 1),
                        width: 1,
                      ),
                    ),
                    minWidth: double.infinity,
                    color: Colors.transparent,
                    child: const Text(
                      "Sign Up",
                      style: TextStyle(
                        color: Color.fromRGBO(49, 39, 79, 1),
                        fontSize: 16,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 20),

                // Admin Login Button
                FadeInUp(
                  duration: const Duration(milliseconds: 1600),
                  child: MaterialButton(
                    onPressed: () => Get.dialog(_buildAdminLoginDialog(context)),
                    height: 50,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(50),
                    ),
                    minWidth: double.infinity,
                    color: const Color.fromRGBO(196, 135, 198, 1),
                    child: const Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          LineAwesomeIcons.user_shield,
                          color: Colors.white,
                        ),
                        SizedBox(width: 10),
                        Text(
                          "Admin Login",
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 16,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}