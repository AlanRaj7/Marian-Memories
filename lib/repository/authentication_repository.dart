import 'package:get/get.dart';

class AuthenticationRepository {
  static AuthenticationRepository get instance => Get.find();

  // You can add actual authentication logic here later
  Future<void> logout() async {
    // Add your logout logic here
    Get.offAllNamed('/login'); // Navigate to login screen
    // or simply:
    // Get.offAll(() => const LoginScreen());
  }
}