import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';

class AdminDashboard extends StatelessWidget {
  const AdminDashboard({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Admin Dashboard'),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: () async {
              await FirebaseAuth.instance.signOut();
              if (context.mounted) {
                Navigator.of(context).pushReplacementNamed('/');
              }
            },
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const StatisticsSection(),
            const SizedBox(height: 24),
            const NotesManagementSection(),
          ],
        ),
      ),
    );
  }
}

class StatisticsSection extends StatelessWidget {
  const StatisticsSection({super.key});

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance.collection('users').snapshots(),
      builder: (context, usersSnapshot) {
        return StreamBuilder<QuerySnapshot>(
          stream: FirebaseFirestore.instance.collection('college_diary_entries').snapshots(),
          builder: (context, collegeEntriesSnapshot) {
            return StreamBuilder<QuerySnapshot>(
              stream: FirebaseFirestore.instance.collection('dairyentry').snapshots(), // Updated collection
              builder: (context, dairyEntriesSnapshot) {
                if (!usersSnapshot.hasData || !collegeEntriesSnapshot.hasData || !dairyEntriesSnapshot.hasData) {
                  return const Center(child: CircularProgressIndicator());
                }

                final totalUsers = usersSnapshot.data!.docs.length;
                final totalCollegeNotes = collegeEntriesSnapshot.data!.docs.length;
                final totalDiaryNotes = dairyEntriesSnapshot.data!.docs.length;

                return Card(
                  elevation: 4,
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text('Statistics', style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
                        const SizedBox(height: 16),
                        GridView.count(
                          shrinkWrap: true,
                          crossAxisCount: 2,
                          childAspectRatio: 2,
                          crossAxisSpacing: 16,
                          mainAxisSpacing: 16,
                          children: [
                            StatisticCard(title: 'Total Users', value: totalUsers.toString(), icon: Icons.people),
                            StatisticCard(title: 'College Diaries', value: totalCollegeNotes.toString(), icon: Icons.school),
                            StatisticCard(title: 'Personal Diaries', value: totalDiaryNotes.toString(), icon: Icons.book),
                          ],
                        ),
                      ],
                    ),
                  ),
                );
              },
            );
          },
        );
      },
    );
  }
}

class StatisticCard extends StatelessWidget {
  final String title;
  final String value;
  final IconData icon;

  const StatisticCard({super.key, required this.title, required this.value, required this.icon});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.blue.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, size: 32, color: Colors.blue),
          const SizedBox(height: 8),
          Text(value, style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
          Text(title, style: const TextStyle(fontSize: 14, color: Colors.grey)),
        ],
      ),
    );
  }
}

class NotesManagementSection extends StatelessWidget {
  const NotesManagementSection({super.key});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        NotesList(collectionName: 'college_diary_entries', title: 'College Diaries'),
        const SizedBox(height: 16),
        NotesList(collectionName: 'dairyentry', title: 'Personal Diaries'), // Updated collection name
      ],
    );
  }
}

class NotesList extends StatelessWidget {
  final String collectionName;
  final String title;

  const NotesList({super.key, required this.collectionName, required this.title});

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance.collection(collectionName).orderBy('createdAt', descending: true).snapshots(),
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return const Center(child: CircularProgressIndicator());
        }

        final notes = snapshot.data!.docs;

        return Card(
          elevation: 4,
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(title, style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
                    Text('${notes.length} entries', style: const TextStyle(color: Colors.grey)),
                  ],
                ),
                const SizedBox(height: 16),
                if (notes.isEmpty)
                  const Center(
                    child: Padding(
                      padding: EdgeInsets.all(32.0),
                      child: Text('No entries available', style: TextStyle(color: Colors.grey)),
                    ),
                  )
                else
                  ListView.separated(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    itemCount: notes.length,
                    separatorBuilder: (context, index) => const Divider(),
                    itemBuilder: (context, index) {
                      final doc = notes[index];
                      final data = doc.data() as Map<String, dynamic>;

                      final title = collectionName == 'dairyentry' 
                          ? data['title'] ?? 'Untitled'
                          : data['activity'] ?? 'Untitled';
                          
                      final description = data['description'] ?? 'No description';
                      final date = data['createdAt'] as Timestamp?;

                      return ListTile(
                        leading: Icon(
                          collectionName == 'dairyentry' ? Icons.book : Icons.school,
                          color: Colors.blue,
                        ),
                        title: Text(
                          title,
                          style: const TextStyle(fontWeight: FontWeight.bold),
                        ),
                        subtitle: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(description),
                            if (date != null)
                              Text(
                                'Created: ${DateFormat('MMM d, y HH:mm').format(date.toDate())}',
                                style: const TextStyle(fontSize: 12),
                              ),
                            if (collectionName == 'college_diary_entries' && data['department'] != null)
                              Chip(
                                label: Text(data['department']),
                                backgroundColor: Colors.blue.withOpacity(0.1),
                              ),
                          ],
                        ),
                        trailing: IconButton(
                          icon: const Icon(Icons.delete, color: Colors.red),
                          onPressed: () {
                            showDialog(
                              context: context,
                              builder: (context) => AlertDialog(
                                title: const Text('Delete Entry'),
                                content: const Text('Are you sure you want to delete this entry? This action cannot be undone.'),
                                actions: [
                                  TextButton(
                                    onPressed: () => Navigator.pop(context),
                                    child: const Text('Cancel'),
                                  ),
                                  TextButton(
                                    onPressed: () async {
                                      await FirebaseFirestore.instance
                                          .collection(collectionName)
                                          .doc(doc.id)
                                          .delete();
                                      if (context.mounted) {
                                        Navigator.pop(context);
                                        ScaffoldMessenger.of(context).showSnackBar(
                                          const SnackBar(content: Text('Entry deleted successfully')),
                                        );
                                      }
                                    },
                                    child: const Text('Delete', style: TextStyle(color: Colors.red)),
                                  ),
                                ],
                              ),
                            );
                          },
                        ),
                      );
                    },
                  ),
              ],
            ),
          ),
        );
      },
    );
  }
}