import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:marianmemories/screens/college_diary_entry_details_page.dart';

class CollegeActivityDetailsPage extends StatefulWidget {
  final String activityName;

  const CollegeActivityDetailsPage({Key? key, required this.activityName}) : super(key: key);

  @override
  _CollegeActivityDetailsPageState createState() => _CollegeActivityDetailsPageState();
}

class _CollegeActivityDetailsPageState extends State<CollegeActivityDetailsPage> {
  final ScrollController _scrollController = ScrollController();
  final TextEditingController _searchController = TextEditingController();
  List<DocumentSnapshot> _entries = [];
  List<DocumentSnapshot> _filteredEntries = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _fetchEntries();
  }

  Future<void> _fetchEntries() async {
    setState(() {
      _isLoading = true;
    });
    
    try {
      QuerySnapshot querySnapshot = await FirebaseFirestore.instance
          .collection('college_diary_entries')
          .where('activity', isEqualTo: widget.activityName)
          .get();

      setState(() {
        _entries = querySnapshot.docs;
        _filteredEntries = _entries;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error fetching entries: $e')),
      );
    }
  }

  void _filterEntries(String query) {
    if (query.isEmpty) {
      setState(() {
        _filteredEntries = _entries;
      });
    } else {
      setState(() {
        _filteredEntries = _entries
            .where((entry) => (entry['department'] ?? '')
                .toString()
                .toLowerCase()
                .contains(query.toLowerCase()))
            .toList();
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        title: Text('${widget.activityName} Diaries'),
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      body: Stack(
        children: [
          // Background image
          Container(
            decoration: const BoxDecoration(
              image: DecorationImage(
                image: AssetImage('assets/marian1.jpg'),
                fit: BoxFit.cover,
              ),
            ),
          ),
          Column(
            children: [
              // Search bar
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 100, 16, 8),
                child: TextField(
                  controller: _searchController,
                  onChanged: _filterEntries,
                  decoration: InputDecoration(
                    hintText: 'Search Dairies',
                    filled: true,
                    fillColor: Colors.white.withOpacity(0.8),
                    prefixIcon: const Icon(Icons.search),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(16),
                      borderSide: BorderSide.none,
                    ),
                  ),
                ),
              ),
              // Entries list
              Expanded(
                child: _isLoading
                    ? const Center(child: CircularProgressIndicator())
                    : _filteredEntries.isEmpty
                        ? Center(
                            child: Text(
                              'No entries found for "${_searchController.text}".',
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 16,
                              ),
                            ),
                          )
                        : Scrollbar(
                            controller: _scrollController,
                            child: ListView.builder(
                              controller: _scrollController,
                              padding: const EdgeInsets.all(16),
                              itemCount: _filteredEntries.length,
                              itemBuilder: (context, index) {
                                var entry = _filteredEntries[index];
                                return Card(
                                  color: Colors.white.withOpacity(0.9),
                                  elevation: 4,
                                  margin: const EdgeInsets.only(bottom: 16),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(16),
                                  ),
                                  child: ListTile(
                                    onTap: () async {
                                      final result = await Navigator.of(context).push(
                                        MaterialPageRoute(
                                          builder: (context) =>
                                              CollegeDiaryEntryDetailsPage(entry: entry),
                                        ),
                                      );
                                      
                                      // If entry was deleted or edited, refresh the list
                                      if (result == true) {
                                        _fetchEntries();
                                      }
                                    },
                                    contentPadding: const EdgeInsets.all(16),
                                    title: Text(
                                      entry['title'] ?? 'Untitled',
                                      style: const TextStyle(
                                        fontWeight: FontWeight.bold,
                                        fontSize: 18,
                                      ),
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
                                        Row(
                                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                          children: [
                                            Text(
                                              entry['date'] ?? '',
                                              style: TextStyle(
                                                color: Colors.grey[600],
                                                fontSize: 14,
                                              ),
                                            ),
                                            Text(
                                              entry['department'] ?? '',
                                              style: TextStyle(
                                                color: Colors.grey[600],
                                                fontSize: 14,
                                              ),
                                            ),
                                          ],
                                        ),
                                      ],
                                    ),
                                  ),
                                );
                              },
                            ),
                          ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    _scrollController.dispose();
    _searchController.dispose();
    super.dispose();
  }
}
