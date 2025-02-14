import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:video_player/video_player.dart';
import 'package:chewie/chewie.dart';
import 'edit_college_dairy_page.dart';

class CollegeDiaryEntryDetailsPage extends StatefulWidget {
  final DocumentSnapshot entry;

  const CollegeDiaryEntryDetailsPage({Key? key, required this.entry}) : super(key: key);

  @override
  State<CollegeDiaryEntryDetailsPage> createState() => _CollegeDiaryEntryDetailsPageState();
}

class _CollegeDiaryEntryDetailsPageState extends State<CollegeDiaryEntryDetailsPage> {
  bool _isDeleting = false;
  VideoPlayerController? _videoPlayerController;
  ChewieController? _chewieController;

  @override
  void initState() {
    super.initState();
    _initializeVideoIfAvailable();
  }

  Future<void> _initializeVideoIfAvailable() async {
    // Safely check if videoUrl exists in the document
    if (widget.entry.data() != null) {
      final data = widget.entry.data() as Map<String, dynamic>;
      final videoUrl = data['videoUrl'] as String?;
      
      if (videoUrl != null && videoUrl.isNotEmpty) {
        await _initializeVideo(videoUrl);
      }
    }
  }

  Future<void> _initializeVideo(String videoUrl) async {
    try {
      _videoPlayerController = VideoPlayerController.network(videoUrl);
      await _videoPlayerController!.initialize();
      
      if (mounted) {
        setState(() {
          _chewieController = ChewieController(
            videoPlayerController: _videoPlayerController!,
            autoPlay: false,
            looping: false,
            showControls: true,
            aspectRatio: _videoPlayerController!.value.aspectRatio,
            errorBuilder: (context, errorMessage) {
              return Center(
                child: Text('Error: $errorMessage'),
              );
            },
          );
        });
      }
    } catch (e) {
      debugPrint('Video initialization error: $e');
      // Handle video initialization error gracefully
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error loading video: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  @override
  void dispose() {
    _chewieController?.dispose();
    _videoPlayerController?.dispose();
    super.dispose();
  }

  Widget _buildVideoPlayer() {
    // Safely access videoUrl from document data
    final data = widget.entry.data() as Map<String, dynamic>?;
    final videoUrl = data?['videoUrl'] as String?;
    
    if (data == null || videoUrl == null || videoUrl.isEmpty) {
      return const SizedBox.shrink();
    }

    if (_chewieController == null) {
      return Container(
        height: 200,
        decoration: BoxDecoration(
          color: Colors.black12,
          borderRadius: BorderRadius.circular(12),
        ),
        child: const Center(
          child: CircularProgressIndicator(),
        ),
      );
    }

    return Container(
      height: 200,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        color: Colors.black,
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(12),
        child: Chewie(controller: _chewieController!),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    // Safely access document data
    final data = widget.entry.data() as Map<String, dynamic>?;
    if (data == null) {
      return const Scaffold(
        body: Center(
          child: Text('Error: Entry data not found'),
        ),
      );
    }

    // Safely extract fields with null-safety
    final title = data['title'] as String? ?? 'Untitled Entry';
    final description = data['description'] as String? ?? 'No description available';
    final date = data['date'] as String? ?? 'Date not specified';
    final department = data['department'] as String? ?? 'Unknown Department';
    final activity = data['activity'] as String? ?? 'Unspecified Activity';
    final imageUrl = data['imageUrl'] as String? ?? '';

    return Scaffold(
      backgroundColor: const Color(0xFFF5F5F5),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black),
          onPressed: () => Navigator.of(context).pop(false),
        ),
        title: Text(
          activity,
          style: const TextStyle(
            color: Colors.black,
            fontWeight: FontWeight.bold,
          ),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.edit, color: Colors.black),
            onPressed: _isDeleting ? null : () async {
              final result = await Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => EditCollegeDiaryPage(entry: widget.entry),
                ),
              );
              
              if (result == true) {
                Navigator.pop(context, true);
              }
            },
          ),
          IconButton(
            icon: _isDeleting 
              ? const SizedBox(
                  width: 24,
                  height: 24,
                  child: CircularProgressIndicator(strokeWidth: 2)
                )
              : const Icon(Icons.delete, color: Colors.black),
            onPressed: _isDeleting ? null : _deleteEntry,
          ),
        ],
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Card(
            elevation: 5,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(15),
            ),
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        date,
                        style: TextStyle(
                          fontSize: 16,
                          color: Colors.grey[700],
                        ),
                      ),
                      Text(
                        department,
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: Colors.blue,
                        ),
                      ),
                    ],
                  ),
                  const Divider(height: 24),
                  Text(
                    title,
                    style: const TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 16),
                  if (imageUrl.isNotEmpty)
                    Container(
                      width: double.infinity,
                      height: 200,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(12),
                        image: DecorationImage(
                          image: NetworkImage(imageUrl),
                          fit: BoxFit.cover,
                        ),
                      ),
                    ),
                  const SizedBox(height: 16),
                  _buildVideoPlayer(),
                  const SizedBox(height: 16),
                  const Text(
                    'Description',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    description,
                    style: const TextStyle(
                      fontSize: 16,
                      height: 1.5,
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

  Future<void> _deleteEntry() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Entry'),
        content: const Text('Are you sure you want to delete this entry?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Delete', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );

    if (confirmed ?? false) {
      setState(() => _isDeleting = true);
      
      try {
        await FirebaseFirestore.instance
            .collection('college_diary_entries')
            .doc(widget.entry.id)
            .delete();
            
        if (mounted) {
          Navigator.pop(context, true);
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Entry deleted successfully'),
              backgroundColor: Colors.green,
            ),
          );
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Error deleting entry: $e'),
              backgroundColor: Colors.red,
            ),
          );
        }
      } finally {
        if (mounted) {
          setState(() => _isDeleting = false);
        }
      }
    }
  }
}