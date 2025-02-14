import 'package:flutter/material.dart';
import 'package:line_awesome_flutter/line_awesome_flutter.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:marianmemories/screens/profilescreen.dart';
import 'package:image_picker/image_picker.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'dart:typed_data';

class UpdateProfileScreen extends StatefulWidget {
  const UpdateProfileScreen({Key? key}) : super(key: key);

  @override
  _UpdateProfileScreenState createState() => _UpdateProfileScreenState();
}

class _UpdateProfileScreenState extends State<UpdateProfileScreen> {
  final ThemeProvider _themeProvider = ThemeProvider();
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // Controllers for TextFields
  final TextEditingController _firstNameController = TextEditingController();
  final TextEditingController _lastNameController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _rollNumberController = TextEditingController();

  bool _isLoading = false;
  String? _profileImageUrl;
  Uint8List? _selectedImageBytes;

  // Cloudinary credentials
  static const String cloudName = 'dvv3cnhmq';
  static const String uploadPreset = 'project1';

  @override
  void initState() {
    super.initState();
    _fetchUserData();
  }

  Future<void> _fetchUserData() async {
    setState(() => _isLoading = true);
    try {
      User? currentUser = _auth.currentUser;
      if (currentUser != null) {
        DocumentSnapshot userDoc = await _firestore
            .collection('users')
            .doc(currentUser.uid)
            .get();

        if (userDoc.exists) {
          Map<String, dynamic> userData = userDoc.data() as Map<String, dynamic>;
          
          _firstNameController.text = userData['first_name'] ?? '';
          _lastNameController.text = userData['last_name'] ?? '';
          _emailController.text = userData['email'] ?? '';
          _rollNumberController.text = userData['roll_number'] ?? '';
          setState(() {
            _profileImageUrl = userData['profile_image'] ?? '';
          });
        }
      }
    } catch (e) {
      print('Error fetching user data: $e');
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _pickImage() async {
    try {
      final ImagePicker picker = ImagePicker();
      final XFile? image = await picker.pickImage(
        source: ImageSource.gallery,
        imageQuality: 70,
      );
      
      if (image != null) {
        final bytes = await image.readAsBytes();
        setState(() {
          _selectedImageBytes = bytes;
        });
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error picking image: $e')),
      );
    }
  }

  Future<String?> _uploadImageToCloudinary() async {
    if (_selectedImageBytes == null) return _profileImageUrl;

    final cloudinaryUrl = "https://api.cloudinary.com/v1_1/$cloudName/image/upload";

    try {
      final request = http.MultipartRequest('POST', Uri.parse(cloudinaryUrl))
        ..fields['upload_preset'] = uploadPreset
        ..fields['folder'] = 'profile_pictures'
        ..fields['resource_type'] = 'image'
        ..files.add(http.MultipartFile.fromBytes(
          'file',
          _selectedImageBytes!,
          filename: 'profile_image.jpg',
        ));

      final response = await request.send();
      final responseBody = await response.stream.bytesToString();

      if (response.statusCode == 200) {
        final jsonResponse = json.decode(responseBody);
        return jsonResponse['secure_url'];
      } else {
        throw Exception('Failed to upload image: ${response.statusCode}');
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error uploading image: $e')),
      );
      return null;
    }
  }

  Future<void> _updateProfile() async {
    setState(() => _isLoading = true);
    try {
      User? currentUser = _auth.currentUser;
      if (currentUser != null) {
        // Upload image if new image is selected
        String? imageUrl = _selectedImageBytes != null 
            ? await _uploadImageToCloudinary()
            : _profileImageUrl;

        // Update Firestore document
        await _firestore.collection('users').doc(currentUser.uid).update({
          'first_name': _firstNameController.text.trim(),
          'last_name': _lastNameController.text.trim(),
          'email': _emailController.text.trim(),
          'roll_number': _rollNumberController.text.trim(),
          'profile_image': imageUrl,
        });

        // Update email in Firebase Authentication if changed
        if (currentUser.email != _emailController.text.trim()) {
          await currentUser.updateEmail(_emailController.text.trim());
        }

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Profile updated successfully!')),
        );
        Navigator.pop(context);
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error updating profile: $e')),
      );
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Widget _buildProfileImage() {
    if (_selectedImageBytes != null) {
      return Image.memory(
        _selectedImageBytes!,
        fit: BoxFit.cover,
        width: 120,
        height: 120,
      );
    } else if (_profileImageUrl != null && _profileImageUrl!.isNotEmpty) {
      return Image.network(
        _profileImageUrl!,
        fit: BoxFit.cover,
        width: 120,
        height: 120,
        loadingBuilder: (context, child, loadingProgress) {
          if (loadingProgress == null) return child;
          return Center(
            child: CircularProgressIndicator(
              value: loadingProgress.expectedTotalBytes != null
                  ? loadingProgress.cumulativeBytesLoaded / 
                    loadingProgress.expectedTotalBytes!
                  : null,
            ),
          );
        },
        errorBuilder: (context, error, stackTrace) {
          return const Image(
            image: AssetImage('assets/background.png'),
            fit: BoxFit.cover,
            width: 120,
            height: 120,
          );
        },
      );
    } else {
      return const Image(
        image: AssetImage('assets/background.png'),
        fit: BoxFit.cover,
        width: 120,
        height: 120,
      );
    }
  }

  @override
  void dispose() {
    _firstNameController.dispose();
    _lastNameController.dispose();
    _emailController.dispose();
    _rollNumberController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: _themeProvider,
      builder: (context, child) {
        final isDark = _themeProvider.isDarkMode;
        final primaryColor = isDark ? ThemeColors.darkPrimary : ThemeColors.lightPrimary;
        final accentColor = isDark ? ThemeColors.darkAccent : ThemeColors.lightAccent;
        final backgroundColor = isDark ? Colors.grey[900] : Colors.white;

        return MaterialApp(
          debugShowCheckedModeBanner: false,
          theme: ThemeData(
            brightness: isDark ? Brightness.dark : Brightness.light,
            primaryColor: primaryColor,
          ),
          home: Scaffold(
            backgroundColor: backgroundColor,
            appBar: AppBar(
              backgroundColor: primaryColor,
              leading: IconButton(
                onPressed: () => Navigator.pop(context),
                icon: const Icon(LineAwesomeIcons.angle_left),
              ),
              actions: [
                IconButton(
                  icon: Icon(isDark ? Icons.light_mode : Icons.dark_mode),
                  onPressed: () {
                    _themeProvider.toggleTheme();
                  },
                ),
              ],
              title: Text(
                'Update Profile',
                style: TextStyle(
                  color: isDark ? Colors.white : Colors.white,
                  fontWeight: FontWeight.bold
                ),
              ),
            ),
            body: _isLoading 
              ? Center(child: CircularProgressIndicator(color: primaryColor))
              : SingleChildScrollView(
                  child: Padding(
                    padding: const EdgeInsets.all(20.0),
                    child: Column(
                      children: [
                        // Profile Image
                        Stack(
                          children: [
                            SizedBox(
                              width: 120,
                              height: 120,
                              child: ClipRRect(
                                borderRadius: BorderRadius.circular(100),
                                child: _buildProfileImage(),
                              ),
                            ),
                            Positioned(
                              bottom: 0,
                              right: 0,
                              child: GestureDetector(
                                onTap: _pickImage,
                                child: Container(
                                  width: 35,
                                  height: 35,
                                  decoration: BoxDecoration(
                                    borderRadius: BorderRadius.circular(100),
                                    color: accentColor,
                                  ),
                                  child: Icon(
                                    LineAwesomeIcons.camera,
                                    color: isDark ? Colors.white : Colors.black,
                                    size: 20,
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 20),

                        // Text Fields
                        _buildTextField(
                          controller: _firstNameController,
                          label: 'First Name',
                          icon: LineAwesomeIcons.user,
                          isDark: isDark,
                          primaryColor: primaryColor,
                        ),
                        const SizedBox(height: 15),
                        _buildTextField(
                          controller: _lastNameController,
                          label: 'Last Name',
                          icon: LineAwesomeIcons.user,
                          isDark: isDark,
                          primaryColor: primaryColor,
                        ),
                        const SizedBox(height: 15),
                        _buildTextField(
                          controller: _emailController,
                          label: 'Email',
                          icon: LineAwesomeIcons.envelope,
                          isDark: isDark,
                          primaryColor: primaryColor,
                        ),
                        const SizedBox(height: 15),
                        _buildTextField(
                          controller: _rollNumberController,
                          label: 'Roll Number',
                          icon: Icons.confirmation_number,
                          isDark: isDark,
                          primaryColor: primaryColor,
                        ),
                        const SizedBox(height: 30),

                        // Save Button
                        SizedBox(
                          width: 200,
                          child: ElevatedButton(
                            onPressed: _updateProfile,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: primaryColor,
                              shape: const StadiumBorder(),
                            ),
                            child: Text(
                              'Save Changes',
                              style: TextStyle(color: isDark ? Colors.white : Colors.white),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
          ),
        );
      },
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    required bool isDark,
    required Color primaryColor,
  }) {
    return TextField(
      controller: controller,
      decoration: InputDecoration(
        prefixIcon: Icon(
          icon, 
          color: isDark ? Colors.white : primaryColor
        ),
        labelText: label,
        labelStyle: TextStyle(
          color: isDark ? Colors.white70 : Colors.black54
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(100),
          borderSide: BorderSide(
            color: isDark ? Colors.white24 : primaryColor.withOpacity(0.3),
          ),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(100),
          borderSide: BorderSide(
            color: primaryColor,
            width: 2,
          ),
        ),
      ),
    );
  }
}