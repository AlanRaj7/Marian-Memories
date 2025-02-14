import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:image_picker/image_picker.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

class EditCollegeDiaryPage extends StatefulWidget {
  final DocumentSnapshot entry;
  
  const EditCollegeDiaryPage({Key? key, required this.entry}) : super(key: key);

  @override
  State<EditCollegeDiaryPage> createState() => _EditCollegeDiaryPageState();
}

class _EditCollegeDiaryPageState extends State<EditCollegeDiaryPage> {
  late TextEditingController _titleController;
  late TextEditingController _descriptionController;
  late TextEditingController _departmentController;
  late TextEditingController _activityController;
  late TextEditingController _dateController;
  String? _imageUrl;
  Uint8List? _imageBytes;
  bool _isLoading = false;

  static const String cloudName = 'dvv3cnhmq';
  static const String uploadPreset = 'project1';

  @override
  void initState() {
    super.initState();
    _titleController = TextEditingController(text: widget.entry['title'] ?? '');
    _descriptionController = TextEditingController(text: widget.entry['description'] ?? '');
    _departmentController = TextEditingController(text: widget.entry['department'] ?? '');
    _activityController = TextEditingController(text: widget.entry['activity'] ?? '');
    _dateController = TextEditingController(text: widget.entry['date'] ?? '');
    _imageUrl = widget.entry['imageUrl'];
  }

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    _departmentController.dispose();
    _activityController.dispose();
    _dateController.dispose();
    super.dispose();
  }

  Future<void> _selectDate(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime(2000),
      lastDate: DateTime.now(),
    );
    if (picked != null) {
      setState(() {
        // Format date as "yyyy-MM-dd" to match your Firebase format
        _dateController.text = "${picked.year}-${picked.month.toString().padLeft(2, '0')}-${picked.day.toString().padLeft(2, '0')}";
      });
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
          _imageBytes = bytes;
          _imageUrl = null;
        });
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error picking image: $e')),
        );
      }
    }
  }

  Future<String?> _uploadImage() async {
    if (_imageBytes == null) return _imageUrl;

    final cloudinaryUrl = "https://api.cloudinary.com/v1_1/$cloudName/image/upload";

    try {
      final request = http.MultipartRequest('POST', Uri.parse(cloudinaryUrl))
        ..fields['upload_preset'] = uploadPreset
        ..fields['folder'] = 'college_diary_entries'
        ..fields['resource_type'] = 'image'
        ..files.add(http.MultipartFile.fromBytes(
          'file',
          _imageBytes!,
          filename: 'college_diary_image.jpg',
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
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error uploading image: $e')),
        );
      }
      return null;
    }
  }

  Future<void> _saveChanges() async {
    if (_titleController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter a title')),
      );
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      String? imageUrl = _imageBytes != null ? await _uploadImage() : _imageUrl;

      await widget.entry.reference.update({
        'title': _titleController.text.trim(),
        'description': _descriptionController.text.trim(),
        'department': _departmentController.text.trim(),
        'activity': _activityController.text.trim(),
        'date': _dateController.text.trim(),
        'imageUrl': imageUrl,
        'updatedAt': Timestamp.now(),
      });

      if (mounted) {
        Navigator.pop(context, true);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error updating entry: $e')),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String hint,
    required IconData icon,
    int maxLines = 1,
  }) {
    return Container(
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
      child: TextField(
        controller: controller,
        maxLines: maxLines,
        decoration: InputDecoration(
          hintText: hint,
          prefixIcon: Icon(icon, color: const Color(0xFF6B4EFF)),
          contentPadding: const EdgeInsets.all(16),
          border: InputBorder.none,
        ),
        style: TextStyle(
          fontSize: maxLines > 1 ? 16 : 18,
          color: Colors.grey[800],
          height: 1.5,
        ),
      ),
    );
  }

  Widget _buildImageWidget() {
    if (_imageBytes != null) {
      return Image.memory(
        _imageBytes!,
        width: double.infinity,
        height: 200,
        fit: BoxFit.cover,
      );
    } else if (_imageUrl != null && _imageUrl!.isNotEmpty) {
      return Image.network(
        _imageUrl!,
        width: double.infinity,
        height: 200,
        fit: BoxFit.cover,
        loadingBuilder: (context, child, loadingProgress) {
          if (loadingProgress == null) return child;
          return Center(
            child: CircularProgressIndicator(
              value: loadingProgress.expectedTotalBytes != null
                  ? loadingProgress.cumulativeBytesLoaded / 
                    loadingProgress.expectedTotalBytes!
                  : null,
              valueColor: const AlwaysStoppedAnimation<Color>(Color(0xFF6B4EFF)),
            ),
          );
        },
        errorBuilder: (context, error, stackTrace) {
          return Container(
            width: double.infinity,
            height: 200,
            color: Colors.grey[200],
            child: const Center(
              child: Icon(Icons.error_outline, color: Colors.grey, size: 50),
            ),
          );
        },
      );
    } else {
      return Container(
        width: double.infinity,
        height: 200,
        color: Colors.grey[200],
        child: const Center(
          child: Icon(Icons.add_photo_alternate, size: 50, color: Colors.grey),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[100],
      appBar: AppBar(
        elevation: 0,
        backgroundColor: Colors.white,
        leading: IconButton(
          icon: const Icon(Icons.close, color: Color(0xFF1E1E1E)),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: const Text(
          'Edit College Diary',
          style: TextStyle(
            color: Color(0xFF1E1E1E),
            fontWeight: FontWeight.bold,
          ),
        ),
        actions: [
          if (_isLoading)
            const Center(
              child: Padding(
                padding: EdgeInsets.all(16.0),
                child: SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF6B4EFF)),
                  ),
                ),
              ),
            )
          else
            TextButton(
              onPressed: _saveChanges,
              child: const Text(
                'Save',
                style: TextStyle(
                  color: Color(0xFF6B4EFF),
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                ),
              ),
            ),
        ],
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildTextField(
                controller: _titleController,
                hint: 'Entry Title',
                icon: Icons.title,
              ),
              const SizedBox(height: 16),

              _buildTextField(
                controller: _activityController,
                hint: 'Activity',
                icon: Icons.local_activity,
              ),
              const SizedBox(height: 16),

              _buildTextField(
                controller: _departmentController,
                hint: 'Department',
                icon: Icons.business,
              ),
              const SizedBox(height: 16),

              GestureDetector(
                onTap: () => _selectDate(context),
                child: Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(16),
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
                  child: Row(
                    children: [
                      const Icon(
                        Icons.calendar_today,
                        color: Color(0xFF6B4EFF),
                        size: 24,
                      ),
                      const SizedBox(width: 16),
                      Text(
                        _dateController.text,
                        style: const TextStyle(
                          fontSize: 16,
                          color: Color(0xFF1E1E1E),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 16),

              Container(
                width: double.infinity,
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
                child: Stack(
                  children: [
                    ClipRRect(
                      borderRadius: BorderRadius.circular(16),
                      child: _buildImageWidget(),
                    ),
                    Positioned(
                      right: 8,
                      bottom: 8,
                      child: FloatingActionButton(
                        mini: true,
                        backgroundColor: const Color(0xFF6B4EFF),
                        onPressed: _pickImage,
                        child: const Icon(Icons.camera_alt, size: 20),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),

              _buildTextField(
                controller: _descriptionController,
                hint: 'Write about your college activity...',
                icon: Icons.edit_note,
                maxLines: 8,
              ),
            ],
          ),
        ),
      ),
    );
  }
}