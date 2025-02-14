import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

class SignUpScreen extends StatefulWidget {
  const SignUpScreen({Key? key}) : super(key: key);

  @override
  State<SignUpScreen> createState() => _SignUpScreenState();
}

class _SignUpScreenState extends State<SignUpScreen> {
  final _formKey = GlobalKey<FormState>();
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  final TextEditingController _firstNameController = TextEditingController();
  final TextEditingController _lastNameController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _rollNumberController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final TextEditingController _confirmPasswordController = TextEditingController();

  bool _agreeToTerms = false;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: const Text("Sign Up"),
        centerTitle: true,
        backgroundColor: const Color.fromARGB(255, 174, 151, 238),
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const Text(
                "Create Your Account",
                style: TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                  color: Color.fromRGBO(49, 39, 79, 1),
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 20),
              Form(
                key: _formKey,
                child: Column(
                  children: [
                    _buildTextField(
                      "First Name",
                      "Enter your first name",
                      controller: _firstNameController,
                      icon: Icons.person,
                    ),
                    const SizedBox(height: 15),
                    _buildTextField(
                      "Last Name",
                      "Enter your last name",
                      controller: _lastNameController,
                      icon: Icons.person_outline,
                    ),
                    const SizedBox(height: 15),
                    _buildTextField(
                      "Email",
                      "Enter your email address",
                      controller: _emailController,
                      icon: Icons.email,
                    ),
                    const SizedBox(height: 15),
                    _buildTextField(
                      "Roll Number",
                      "Enter your roll number",
                      controller: _rollNumberController,
                      icon: Icons.confirmation_number,
                    ),
                    const SizedBox(height: 15),
                    _buildTextField(
                      "Password",
                      "Create a password",
                      controller: _passwordController,
                      obscureText: true,
                      icon: Icons.lock,
                    ),
                    const SizedBox(height: 15),
                    _buildTextField(
                      "Confirm Password",
                      "Confirm your password",
                      controller: _confirmPasswordController,
                      obscureText: true,
                      icon: Icons.lock_outline,
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),
              Row(
                children: [
                  Checkbox(
                    value: _agreeToTerms,
                    onChanged: (bool? value) {
                      setState(() {
                        _agreeToTerms = value ?? false;
                      });
                    },
                    activeColor: const Color.fromRGBO(196, 135, 198, 1),
                  ),
                  const Expanded(
                    child: Text(
                      "I agree to the Terms and Conditions",
                      style: TextStyle(fontSize: 14),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 15),
              MaterialButton(
                onPressed: _signUp,
                color: const Color.fromRGBO(49, 39, 79, 1),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(50),
                ),
                height: 50,
                child: const Text(
                  "Sign Up",
                  style: TextStyle(color: Colors.white),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTextField(
    String label,
    String hint, {
    required TextEditingController controller,
    bool obscureText = false,
    required IconData icon,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(
          color: const Color.fromRGBO(196, 135, 198, .3),
        ),
        boxShadow: const [
          BoxShadow(
            color: Color.fromRGBO(196, 135, 198, .3),
            blurRadius: 20,
            offset: Offset(0, 10),
          ),
        ],
      ),
      child: TextFormField(
        controller: controller,
        obscureText: obscureText,
        validator: (value) {
          if (value == null || value.isEmpty) {
            return "Please enter your $label";
          }
          if (label == "Confirm Password" &&
              value != _passwordController.text) {
            return "Passwords do not match";
          }
          return null;
        },
        decoration: InputDecoration(
          prefixIcon: Icon(icon, color: const Color.fromRGBO(196, 135, 198, 1)),
          labelText: label,
          hintText: hint,
          border: InputBorder.none,
          contentPadding: const EdgeInsets.all(10),
        ),
      ),
    );
  }

  Future<void> _signUp() async {
    if (!_formKey.currentState!.validate()) return;

    if (!_agreeToTerms) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Please agree to the terms")),
      );
      return;
    }

    try {
      UserCredential userCredential =
          await _auth.createUserWithEmailAndPassword(
        email: _emailController.text.trim(),
        password: _passwordController.text.trim(),
      );

      // Add user details to Firestore
      await _firestore.collection('users').doc(userCredential.user!.uid).set({
        'first_name': _firstNameController.text.trim(),
        'last_name': _lastNameController.text.trim(),
        'email': _emailController.text.trim(),
        'roll_number': _rollNumberController.text.trim(),
        'role': 'user',
        'created_at': FieldValue.serverTimestamp(),
      });

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Account created successfully!")),
      );

      // Clear form and reset
      _formKey.currentState!.reset();
      _firstNameController.clear();
      _lastNameController.clear();
      _emailController.clear();
      _rollNumberController.clear();
      _passwordController.clear();
      _confirmPasswordController.clear();
      setState(() => _agreeToTerms = false);
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Error: ${e.toString()}")),
      );
    }
  }
}