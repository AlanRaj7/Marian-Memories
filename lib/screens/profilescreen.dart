import 'package:flutter/material.dart';
import 'package:line_awesome_flutter/line_awesome_flutter.dart';
import 'package:marianmemories/screens/homepage.dart';
import 'package:marianmemories/screens/updateprofilescreens.dart';
import 'package:marianmemories/screens/user_management_screen.dart';
import 'package:marianmemories/screens/college_app_info_screen.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:marianmemories/screens/auth_service.dart';

// Constants
const double tDefaultSize = 20.0;
const String tProfile = "Profile";
const String tProfileImage = "assets/background.png";
const String tEditProfile = "Edit Profile";

// Theme Colors
class ThemeColors {
  static const Color lightPrimary = Color(0xFF4A90E2);
  static const Color lightAccent = Color(0xFF50E3C2);
  static const Color lightHeadingText = Color(0xFF222222);
  static const Color lightSubHeadingText = Color(0xFF555555);
  
  static const Color darkPrimary = Color(0xFF2D5F9E);
  static const Color darkAccent = Color(0xFF2C7A6B);
  static const Color darkHeadingText = Color(0xFFE0E0E0);
  static const Color darkSubHeadingText = Color(0xFFB0B0B0);
}

class ThemeProvider extends ChangeNotifier {
  bool _isDarkMode = false;
  bool get isDarkMode => _isDarkMode;

  void toggleTheme() {
    _isDarkMode = !_isDarkMode;
    notifyListeners();
  }
}

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({Key? key}) : super(key: key);

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  final ThemeProvider _themeProvider = ThemeProvider();
  final AuthService _authService = AuthService();
  String _userFullName = 'User';
  String _userEmail = '';

  @override
  void initState() {
    super.initState();
    _fetchUserDetails();
  }

  Future<void> _fetchUserDetails() async {
    User? currentUser = FirebaseAuth.instance.currentUser;
    if (currentUser != null) {
      try {
        DocumentSnapshot userDoc = await FirebaseFirestore.instance
            .collection('users')
            .doc(currentUser.uid)
            .get();

        if (userDoc.exists) {
          setState(() {
            _userFullName = '${userDoc['first_name'] ?? ''} ${userDoc['last_name'] ?? ''}'.trim();
            _userEmail = currentUser.email ?? '';
          });
        }
      } catch (e) {
        print('Error fetching user details: $e');
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: _themeProvider,
      builder: (context, child) {
        final isDark = _themeProvider.isDarkMode;
        final primaryColor = isDark ? ThemeColors.darkPrimary : ThemeColors.lightPrimary;
        final accentColor = isDark ? ThemeColors.darkAccent : ThemeColors.lightAccent;
        final headingTextColor = isDark ? ThemeColors.darkHeadingText : ThemeColors.lightHeadingText;
        final subHeadingTextColor = isDark ? ThemeColors.darkSubHeadingText : ThemeColors.lightSubHeadingText;
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
                tProfile,
                style: TextStyle(
                  color: isDark ? Colors.white : Colors.white,
                  fontWeight: FontWeight.bold
                ),
              ),
            ),
            body: SingleChildScrollView(
              child: Container(
                padding: const EdgeInsets.all(tDefaultSize),
                child: Column(
                  children: [
                    // Profile Image with Edit Icon
                    Stack(
                      children: [
                        SizedBox(
                          width: 120,
                          height: 120,
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(100),
                            child: const Image(image: AssetImage(tProfileImage)),
                          ),
                        ),
                        Positioned(
                          bottom: 0,
                          right: 0,
                          child: GestureDetector(
                            onTap: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(builder: (context) => UpdateProfileScreen()),
                              );
                            },
                            child: Container(
                              width: 35,
                              height: 35,
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(100),
                                color: accentColor,
                              ),
                              child: Icon(
                                LineAwesomeIcons.alternate_pencil,
                                color: isDark ? Colors.white : Colors.black,
                                size: 20,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 20),

                    // Profile Name and Email
                    Text(
                      _userFullName,
                      style: TextStyle(
                        color: headingTextColor,
                        fontWeight: FontWeight.w700,
                        fontSize: 24,
                      ),
                    ),
                    Text(
                      _userEmail,
                      style: TextStyle(
                        color: subHeadingTextColor,
                        fontSize: 16,
                      ),
                    ),
                    const SizedBox(height: 20),

                    // Edit Profile Button
                    SizedBox(
                      width: 200,
                      child: ElevatedButton(
                        onPressed: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(builder: (context) => UpdateProfileScreen()),
                          );
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: primaryColor,
                          shape: const StadiumBorder(),
                        ),
                        child: Text(
                          tEditProfile,
                          style: TextStyle(color: isDark ? Colors.white : Colors.white),
                        ),
                      ),
                    ),
                    const SizedBox(height: 30),
                    Divider(color: isDark ? Colors.grey[700] : Colors.grey[300]),
                    const SizedBox(height: 10),

                    // Menu Items
                    ProfileMenuWidget(
                      title: "Settings",
                      icon: LineAwesomeIcons.cog,
                      onPress: () {},
                      isDarkMode: isDark,
                      accentColor: accentColor,
                    ),
                    ProfileMenuWidget(
                      title: "User Management",
                      icon: LineAwesomeIcons.user_check,
                      onPress: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(builder: (context) => UserManagementScreen()),
                        );
                      },
                      isDarkMode: isDark,
                      accentColor: accentColor,
                    ),
                    Divider(color: isDark ? Colors.grey[700] : Colors.grey[300]),
                    const SizedBox(height: 10),
                    ProfileMenuWidget(
                      title: "Information",
                      icon: LineAwesomeIcons.info,
                      onPress: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(builder: (context) => CollegeAppInfoScreen()),
                        );
                      },
                      isDarkMode: isDark,
                      accentColor: accentColor,
                    ),
                    ProfileMenuWidget(
                      title: "Logout",
                      icon: LineAwesomeIcons.alternate_sign_out,
                      textColor: Colors.red,
                      endIcon: false,
                      isDarkMode: isDark,
                      accentColor: accentColor,
                      onPress: () {
                        showDialog(
                          context: context,
                          builder: (context) => AlertDialog(
                            backgroundColor: backgroundColor,
                            title: Text("Logout", 
                              style: TextStyle(color: headingTextColor)
                            ),
                            content: Text(
                              "Are you sure you want to logout?",
                              style: TextStyle(color: subHeadingTextColor)
                            ),
                            actions: [
                              TextButton(
                                onPressed: () => Navigator.pop(context),
                                child: Text("No", style: TextStyle(color: primaryColor)),
                              ),
                              TextButton(
                                onPressed: () async {
                                  // Navigate to Home/Signup Screen
                                  await _authService.signOut();
                                  Navigator.of(context).pushAndRemoveUntil(
                                    MaterialPageRoute(builder: (context) => HomePage()), 
                                    (Route<dynamic> route) => false
                                  );
                                },
                                child: Text("Yes", style: TextStyle(color: primaryColor)),
                              ),
                            ],
                          ),
                        );
                      },
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
}

class ProfileMenuWidget extends StatelessWidget {
  const ProfileMenuWidget({
    Key? key,
    required this.title,
    required this.icon,
    required this.onPress,
    this.endIcon = true,
    this.textColor,
    required this.isDarkMode,
    required this.accentColor,
  }) : super(key: key);

  final String title;
  final IconData icon;
  final VoidCallback onPress;
  final bool endIcon;
  final Color? textColor;
  final bool isDarkMode;
  final Color accentColor;

  @override
  Widget build(BuildContext context) {
    return ListTile(
      onTap: onPress,
      leading: Container(
        width: 40,
        height: 40,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(100),
          color: accentColor.withOpacity(0.1),
        ),
        child: Icon(icon, color: accentColor),
      ),
      title: Text(
        title,
        style: TextStyle(
          color: textColor ?? (isDarkMode ? Colors.white : Colors.black),
          fontWeight: FontWeight.w500,
        ),
      ),
      trailing: endIcon
          ? Icon(
              LineAwesomeIcons.angle_right,
              color: isDarkMode ? Colors.white54 : Colors.grey,
              size: 18,
            )
          : null,
    );
  }
}