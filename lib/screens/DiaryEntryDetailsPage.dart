import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'edit_diary_entry_page.dart';

class DiaryEntryDetailsPage extends StatefulWidget {
  final DocumentSnapshot entry;

  const DiaryEntryDetailsPage({Key? key, required this.entry, required title, required description, required String date}) : super(key: key);

  @override
  _DiaryEntryDetailsPageState createState() => _DiaryEntryDetailsPageState();
}

class _DiaryEntryDetailsPageState extends State<DiaryEntryDetailsPage> {
  final currentUser = FirebaseAuth.instance.currentUser;

  String _formatDate(DateTime date) {
    final months = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 
                    'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];
    return '${months[date.month - 1]} ${date.day}, ${date.year}';
  }

  void _deleteEntry() {
    // Check if current user is the creator of the entry
    if (currentUser?.uid != widget.entry['userId']) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('You can only delete your own diary entries!'),
          backgroundColor: Colors.red,
          duration: Duration(seconds: 2),
        ),
      );
      return;
    }

    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Delete Entry'),
          content: const Text('Are you sure you want to delete this diary entry?'),
          actions: [
            TextButton(
              child: const Text('Cancel'),
              onPressed: () {
                Navigator.of(context).pop();
              },
            ),
            TextButton(
              child: const Text('Delete'),
              onPressed: () {
                FirebaseFirestore.instance
                    .collection('dairyentry')
                    .doc(widget.entry.id)
                    .delete()
                    .then((_) {
                  Navigator.of(context).pop(); // Dismiss dialog
                  Navigator.of(context).pop(); // Go back to previous screen
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Diary entry deleted successfully'),
                      backgroundColor: Colors.green,
                    ),
                  );
                }).catchError((error) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('Error deleting entry: $error'),
                      backgroundColor: Colors.red,
                    ),
                  );
                });
              },
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final DateTime entryDate = (widget.entry['createdAt'] as Timestamp).toDate();
    final bool isCreator = currentUser?.uid == widget.entry['userId'];

    return Scaffold(
      backgroundColor: Colors.grey[200],
      appBar: AppBar(
        elevation: 0,
        backgroundColor: Colors.white,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Color(0xFF6B4EFF)),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: const Text(
          "Diary Entry",
          style: TextStyle(
            color: Color(0xFF6B4EFF),
            fontWeight: FontWeight.bold,
          ),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.edit, color: Color(0xFF6B4EFF)),
            onPressed: () async {
              final result = await Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => EditDiaryEntryPage(entry: widget.entry),
                ),
              );
              
              if (result == true) {
                Navigator.pop(context);
              }
            },
          ),
          if (isCreator) // Only show delete icon if user is the creator
            IconButton(
              icon: const Icon(Icons.delete, color: Color(0xFF6B4EFF)),
              onPressed: _deleteEntry,
            ),
        ],
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Container(
            decoration: BoxDecoration(
              color: const Color(0xFFFFFDE7),
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                  color: Colors.grey.withOpacity(0.3),
                  spreadRadius: 3,
                  blurRadius: 6,
                  offset: const Offset(0, 3),
                ),
              ],
            ),
            child: Padding(
              padding: const EdgeInsets.all(20.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    widget.entry['title'] ?? 'Diary Entry',
                    style: const TextStyle(
                      fontFamily: 'DancingScript',
                      fontSize: 28,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF6B4EFF),
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    _formatDate(entryDate),
                    style: const TextStyle(
                      fontFamily: 'Roboto',
                      fontSize: 14,
                      color: Colors.grey,
                    ),
                  ),
                  const Divider(
                    height: 30,
                    thickness: 1,
                    color: Colors.grey,
                  ),
                  Text(
                    'Description',
                    style: const TextStyle(
                      fontFamily: 'DancingScript',
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF6B4EFF),
                    ),
                  ),
                  const SizedBox(height: 10),
                  Text(
                    widget.entry['description'] ?? 'No description available',
                    style: TextStyle(
                      fontSize: 16,
                      fontFamily: 'Roboto',
                      color: Colors.grey[800],
                      height: 1.5,
                    ),
                  ),
                  const SizedBox(height: 16),
                  if (widget.entry['imageUrl'] != null)
                    Center(
                      child: Container(
                        width: double.infinity,
                        height: 250,
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(16),
                          image: DecorationImage(
                            image: NetworkImage(widget.entry['imageUrl']),
                            fit: BoxFit.cover,
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.grey.withOpacity(0.2),
                              spreadRadius: 1,
                              blurRadius: 5,
                              offset: const Offset(0, 3),
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
      ),
    );
  }
}