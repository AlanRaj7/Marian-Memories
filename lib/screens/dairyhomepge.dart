import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:marianmemories/screens/homepage.dart';
import 'package:marianmemories/screens/NewEntrypage.dart';
import 'package:marianmemories/screens/collegeentrypage.dart';
import 'package:marianmemories/screens/profilescreen.dart';
import 'package:marianmemories/screens/DiaryEntryDetailsPage.dart';
import 'package:marianmemories/screens/auth_service.dart';
import 'package:marianmemories/screens/college_activity_details_page.dart';
import 'package:marianmemories/screens/updateprofilescreens.dart';

class DiaryHomePage extends StatefulWidget {
  const DiaryHomePage({Key? key}) : super(key: key);

  @override
  State<DiaryHomePage> createState() => _DiaryHomePageState();
}

class _DiaryHomePageState extends State<DiaryHomePage> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final AuthService _authService = AuthService();
  
  final List<Color> noteColors = [
    const Color(0xFFFFE0E0),
    const Color(0xFFE0FFE0),
    const Color(0xFFE0E0FF),
    const Color(0xFFFFF0E0),
    const Color(0xFFE0FFFF),
    const Color(0xFFFFE0FF),
  ];

  String _userFullName = 'User';
  String _userEmail = '';
  String _profileImageUrl = '';

  final List<String> activities = [
    "Academics",
    "Lab Work",
    "Events",
    "Group Study",
    "Library",
    "Sports",
    "NSS Activities",
    "Club Activities",
    "Tour",
    "Seminars",
  ];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _fetchUserDetails();
  }

  Future<void> _fetchUserDetails() async {
    try {
      // Get current user
      User? currentUser = FirebaseAuth.instance.currentUser;
      
      if (currentUser != null) {
        // Get the user's email
        String userEmail = currentUser.email ?? '';
        
        // Get user document from Firestore
        DocumentSnapshot userDoc = await FirebaseFirestore.instance
            .collection('users')
            .doc(currentUser.uid)
            .get();

        if (userDoc.exists && mounted) {
          Map<String, dynamic> userData = userDoc.data() as Map<String, dynamic>;
          
          setState(() {
            // Set email from Firebase Auth
            _userEmail = userEmail;
            
            // Set name from Firestore document
            String firstName = userData['first_name'] ?? '';
            String lastName = userData['last_name'] ?? '';
            _userFullName = '$firstName $lastName'.trim();
            
            // Set profile image if it exists
            _profileImageUrl = userData['profile_image'] ?? '';
          });
        } else {
          print('User document does not exist in Firestore');
          if (mounted) {
            setState(() {
              _userFullName = 'User';
              _userEmail = userEmail;
            });
          }
        }
      } else {
        print('No user currently logged in');
        if (mounted) {
          setState(() {
            _userFullName = 'User';
            _userEmail = '';
          });
        }
      }
    } catch (e) {
      print('Error fetching user details: $e');
      if (mounted) {
        setState(() {
          _userFullName = 'User';
          _userEmail = '';
        });
      }
    }
  }


  void _logout() async {
    await _authService.signOut();
    Navigator.of(context).pushReplacement(
      MaterialPageRoute(builder: (context) => HomePage()),
    );
  }

  String _formatDate(DateTime date) {
    final months = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 
                   'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];
    return '${months[date.month - 1]} ${date.day}, ${date.year}';
  }

  Widget _buildActivitiesTab() {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('college_diary_entries')
          .snapshots(),
      builder: (context, snapshot) {
        Map<String, int> activityCounts = {};
        if (snapshot.hasData) {
          for (var doc in snapshot.data!.docs) {
            String activity = doc['activity'] ?? 'Unknown';
            activityCounts[activity] = (activityCounts[activity] ?? 0) + 1;
          }
        }

        return GridView.builder(
          padding: const EdgeInsets.all(16),
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 2,
            crossAxisSpacing: 16,
            mainAxisSpacing: 16,
            childAspectRatio: 0.8,
          ),
          itemCount: activities.length,
          itemBuilder: (context, index) {
            String activityName = activities[index];
            int reportCount = activityCounts[activityName] ?? 0;

            return GestureDetector(
              onTap: () {
                Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (context) => CollegeActivityDetailsPage(
                      activityName: activityName,
                    ),
                  ),
                );
              },
              child: Container(
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.grey.withOpacity(0.1),
                      spreadRadius: 1,
                      blurRadius: 5,
                      offset: const Offset(0, 3),
                    ),
                  ],
                ),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: noteColors[index % noteColors.length],
                        shape: BoxShape.circle,
                      ),
                      child: Icon(
                        _getActivityIcon(index),
                        size: 40,
                        color: const Color(0xFF6B4EFF),
                      ),
                    ),
                    const SizedBox(height: 16),
                    Text(
                      activityName,
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      "$reportCount Reports",
                      style: TextStyle(
                        color: Colors.grey[600],
                        fontSize: 14,
                      ),
                    ),
                    const SizedBox(height: 16),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16, 
                        vertical: 8
                      ),
                      decoration: BoxDecoration(
                        color: const Color(0xFF6B4EFF).withOpacity(0.1),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: const Text(
                        "View Details",
                        style: TextStyle(
                          color: Color(0xFF6B4EFF),
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  IconData _getActivityIcon(int index) {
    List<IconData> icons = [
      Icons.school,           // Academics
      Icons.science,          // Lab Work
      Icons.event,            // Events
      Icons.group,            // Group Study
      Icons.menu_book,        // Library
      Icons.sports_soccer,    // Sports
      Icons.people_outline,   // NSS Activities
      Icons.account_balance,  // Club Activities
      Icons.directions_bus,   // Tour
      Icons.laptop,           // Seminars
    ];
    return icons[index % icons.length];
  }

  void _showDiaryTypeDialog() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Select Diary Type'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ListTile(
                title: const Text('Individual Diary'),
                onTap: () {
                  Navigator.pop(context);
                  Navigator.push(context, MaterialPageRoute(builder: (_) => const NewEntryPage()));
                },
              ),
              ListTile(
                title: const Text('College Diary'),
                onTap: () {
                  Navigator.pop(context);
                  Navigator.push(context, MaterialPageRoute(builder: (_) => const CollegeEntryPage()));
                },
              ),
            ],
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[100],
      appBar: _buildAppBar(),
      floatingActionButton: FloatingActionButton(
        onPressed: _showDiaryTypeDialog,
        backgroundColor: const Color(0xFF6B4EFF),
        child: const Icon(Icons.add),
      ),
      body: Column(
        children: [
          _buildProfileCard(),
          Container(
            color: Colors.white,
            child: TabBar(
              controller: _tabController,
              labelColor: const Color(0xFF6B4EFF),
              unselectedLabelColor: Colors.grey,
              indicatorColor: const Color(0xFF6B4EFF),
              tabs: const [
                Tab(text: "My Notes"),
                Tab(text: "Activities"),
              ],
            ),
          ),
          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: [
                _buildNotesTab(),
                _buildActivitiesTab(),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildNotesTab() {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance.collection('dairyentry').orderBy('createdAt', descending: true).snapshots(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
          return const Center(child: Text("No entries yet! Create your first diary entry."));
        }

        return ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: snapshot.data!.docs.length,
          itemBuilder: (context, index) {
            var entry = snapshot.data!.docs[index];
            return Card(
              elevation: 2,
              margin: const EdgeInsets.only(bottom: 16),
              color: noteColors[index % noteColors.length],
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
              child: ListTile(
                onTap: () {
                  Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (context) => DiaryEntryDetailsPage(entry: entry, title: null, description: null, date: '',),
                    ),
                  );
                },
                contentPadding: const EdgeInsets.all(16),
                title: Text(
                  entry['title'] ?? 'Untitled',
                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
                ),
                subtitle: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const SizedBox(height: 8),
                    Text(
                      entry['description'] ?? '',
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 8),
                    Text(
                      _formatDate((entry['createdAt'] as Timestamp).toDate()),
                      style: TextStyle(color: Colors.grey[600], fontSize: 14),
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  AppBar _buildAppBar() {
    return AppBar(
      elevation: 0,
      backgroundColor: Colors.white,
      title: const Text(
        "Marian Memories",
        style: TextStyle(
          color: Color(0xFF1E1E1E),
          fontWeight: FontWeight.bold,
        ),
      ),
      actions: [
        IconButton(
          icon: const Icon(Icons.search, color: Color(0xFF1E1E1E)),
          onPressed: () {},
        ),
        IconButton(
          icon: const Icon(Icons.notifications_outlined, color: Color(0xFF1E1E1E)),
          onPressed: () {},
        ),
        PopupMenuButton(
          icon: const Icon(Icons.more_vert, color: Color(0xFF1E1E1E)),
          itemBuilder: (context) => [
            const PopupMenuItem(
              value: 'settings',
              child: Text('Settings'),
            ),
            const PopupMenuItem(
              value: 'help',
              child: Text('Help'),
            ),
            PopupMenuItem(
              value: 'logout',
              child: const Text('Logout'),
              onTap: _logout,
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildProfileCard() {
    return Container(
      padding: const EdgeInsets.all(16),
      color: Colors.white,
      child: Row(
        children: [
          _profileImageUrl.isNotEmpty
              ? CircleAvatar(
                  radius: 30,
                  backgroundColor: const Color(0xFF6B4EFF),
                  child: CircleAvatar(
                    radius: 28,
                    backgroundImage: NetworkImage(_profileImageUrl),
                    backgroundColor: Colors.white,
                  ),
                )
              : CircleAvatar(
                  radius: 30,
                  backgroundColor: const Color(0xFF6B4EFF),
                  child: CircleAvatar(
                    radius: 28,
                    backgroundColor: Colors.white,
                    child: Icon(Icons.person, size: 40, color: Colors.grey[600]),
                  ),
                ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  _userFullName,
                  style: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Text(
                  _userEmail,
                  style: TextStyle(
                    color: Colors.grey[600],
                    fontSize: 14,
                  ),
                ),
              ],
            ),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (context) => ProfileScreen(),
                ),
              );
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF6B4EFF),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(20),
              ),
            ),
            child: const Text("Edit Profile"),
          ),
        ],
      ),
    );
  }
}