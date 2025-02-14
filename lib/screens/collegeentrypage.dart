import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:typed_data';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class CollegeEntryPage extends StatefulWidget {
  const CollegeEntryPage({Key? key}) : super(key: key);

  @override
  State<CollegeEntryPage> createState() => _CollegeEntryPageState();
}

class _CollegeEntryPageState extends State<CollegeEntryPage> {
  final _formKey = GlobalKey<FormState>();
  DateTime selectedDate = DateTime.now();
  String? selectedDepartment;
  String? selectedActivity;
  TextEditingController titleController = TextEditingController();
  TextEditingController descriptionController = TextEditingController();
  Uint8List? _imageBytes;
  String? uploadedImageUrl;
  XFile? _videoFile;
  String? uploadedVideoUrl;
  bool isUploading = false;

  // Cloudinary credentials
  static const String cloudName = 'dvv3cnhmq';
  static const String uploadPreset = 'project1';

  final FirebaseStorage _storage = FirebaseStorage.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  final List<String> departments = [
    'BCA',
    'BCOM',
    'BSW',
    'BBA',
    'MCA',
    'Mathematics',
    'MMH',
    'MSW',
  ];

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

  Future<void> _selectDate(BuildContext context) async {
    final DateTime? pickedDate = await showDatePicker(
      context: context,
      initialDate: selectedDate,
      firstDate: DateTime(2000),
      lastDate: DateTime.now(),
    );
    if (pickedDate != null && pickedDate != selectedDate) {
      setState(() {
        selectedDate = pickedDate;
      });
    }
  }

  Future<void> _getImage() async {
    try {
      final picker = ImagePicker();
      final XFile? pickedImage = await picker.pickImage(
        source: ImageSource.gallery,
        maxWidth: 1920,
        maxHeight: 1080,
        imageQuality: 85,
      );
      
      if (pickedImage != null) {
        final bytes = await pickedImage.readAsBytes();
        setState(() {
          _imageBytes = bytes;
          uploadedImageUrl = null;
        });
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Error picking image: $e")),
      );
    }
  }

  Future<void> _pickVideo() async {
    try {
      final picker = ImagePicker();
      final XFile? pickedVideo = await picker.pickVideo(
        source: ImageSource.gallery,
        maxDuration: const Duration(minutes: 5),
      );
      
      if (pickedVideo != null) {
        setState(() {
          _videoFile = pickedVideo;
          uploadedVideoUrl = null;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Video selected successfully")),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Error picking video: $e")),
      );
    }
  }

  Future<void> _uploadImageToCloudinary() async {
    if (_imageBytes == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Please select an image first")),
      );
      return;
    }

    setState(() {
      isUploading = true;
    });

    try {
      final Uri uri = Uri.parse(
        "https://api.cloudinary.com/v1_1/$cloudName/image/upload"
      );

      final request = http.MultipartRequest('POST', uri)
        ..fields['upload_preset'] = uploadPreset
        ..fields['folder'] = 'college_diary_entries'
        ..fields['resource_type'] = 'image'
        ..files.add(http.MultipartFile.fromBytes(
          'file',
          _imageBytes!,
          filename: 'college_diary_image.jpg',
        ));

      final response = await request.send();
      final responseData = await response.stream.toBytes();
      final responseString = String.fromCharCodes(responseData);

      if (response.statusCode == 200) {
        final jsonResponse = json.decode(responseString);
        setState(() {
          uploadedImageUrl = jsonResponse['secure_url'];
        });
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Image uploaded successfully")),
        );
      } else {
        throw Exception('Upload failed with status: ${response.statusCode}');
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Failed to upload image: $e")),
      );
    } finally {
      setState(() {
        isUploading = false;
      });
    }
  }

  Future<void> _uploadVideoToCloudinary() async {
    if (_videoFile == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Please select a video first")),
      );
      return;
    }

    setState(() {
      isUploading = true;
    });

    try {
      final videoBytes = await _videoFile!.readAsBytes();
      final Uri uri = Uri.parse(
        "https://api.cloudinary.com/v1_1/$cloudName/video/upload"
      );

      final request = http.MultipartRequest('POST', uri)
        ..fields['upload_preset'] = uploadPreset
        ..fields['folder'] = 'college_diary_videos'
        ..fields['resource_type'] = 'video'
        ..files.add(http.MultipartFile.fromBytes(
          'file',
          videoBytes,
          filename: 'college_diary_video.mp4',
        ));

      final response = await request.send();
      final responseData = await response.stream.toBytes();
      final responseString = String.fromCharCodes(responseData);

      if (response.statusCode == 200) {
        final jsonResponse = json.decode(responseString);
        setState(() {
          uploadedVideoUrl = jsonResponse['secure_url'];
        });
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Video uploaded successfully")),
        );
      } else {
        throw Exception('Upload failed with status: ${response.statusCode}');
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Failed to upload video: $e")),
      );
    } finally {
      setState(() {
        isUploading = false;
      });
    }
  }

  Future<void> _submitEntry() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    if (selectedDepartment == null || selectedActivity == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("Please select both department and activity"),
        ),
      );
      return;
    }

    setState(() {
      isUploading = true;
    });

    try {
      if (_imageBytes != null && uploadedImageUrl == null) {
        await _uploadImageToCloudinary();
      }
      
      if (_videoFile != null && uploadedVideoUrl == null) {
        await _uploadVideoToCloudinary();
      }

      await _firestore.collection('college_diary_entries').add({
        'title': titleController.text.trim(),
        'description': descriptionController.text.trim(),
        'date': DateFormat('yyyy-MM-dd').format(selectedDate),
        'department': selectedDepartment,
        'activity': selectedActivity,
        'imageUrl': uploadedImageUrl,
        'videoUrl': uploadedVideoUrl,
        'createdAt': FieldValue.serverTimestamp(),
      });

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Entry submitted successfully!')),
      );
      Navigator.pop(context);
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error submitting entry: $e')),
      );
    } finally {
      setState(() {
        isUploading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'College Diary Entry',
          style: TextStyle(
            fontWeight: FontWeight.bold,
            letterSpacing: 1.2,
          ),
        ),
        flexibleSpace: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [
                Colors.blue.shade700,
                Colors.teal.shade500,
              ],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
          ),
        ),
        elevation: 0,
        centerTitle: true,
      ),
      body: Stack(
        children: [
          Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  Colors.blue.shade100.withOpacity(0.8),
                  Colors.white,
                ],
              ),
            ),
          ),
          SingleChildScrollView(
            padding: const EdgeInsets.all(16.0),
            child: Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildSectionTitle('Entry Details'),
                  const SizedBox(height: 16.0),
                  _buildTextField(
                    controller: titleController,
                    label: 'Title',
                    icon: Icons.title,
                    validator: (value) =>
                        value!.trim().isEmpty ? 'Please enter a title' : null,
                  ),
                  const SizedBox(height: 16.0),
                  _buildTextField(
                    controller: descriptionController,
                    label: 'Description',
                    icon: Icons.description,
                    maxLines: 3,
                    validator: (value) =>
                        value!.trim().isEmpty ? 'Please enter a description' : null,
                  ),
                  const SizedBox(height: 16.0),
                  _buildDropdown(
                    value: selectedDepartment,
                    items: departments,
                    label: 'Department',
                    icon: Icons.business,
                    onChanged: (value) {
                      setState(() {
                        selectedDepartment = value;
                      });
                    },
                  ),
                  const SizedBox(height: 16.0),
                  _buildDropdown(
                    value: selectedActivity,
                    items: activities,
                    label: 'Activity',
                    icon: Icons.category,
                    onChanged: (value) {
                      setState(() {
                        selectedActivity = value;
                      });
                    },
                  ),
                  const SizedBox(height: 24.0),
                  _buildDatePicker(),
                  const SizedBox(height: 24.0),
                  _buildSectionTitle('Media Upload'),
                  const SizedBox(height: 16.0),
                  _buildMediaUploadCard(
                    title: 'Image Upload',
                    icon: Icons.image,
                    content: _imageBytes != null
                        ? Image.memory(
                            _imageBytes!,
                            height: 150,
                            fit: BoxFit.cover,
                          )
                        : const Icon(
                            Icons.image_outlined,
                            size: 80,
                            color: Colors.grey,
                          ),
                    pickAction: _getImage,
                    uploadAction: _imageBytes == null ? null : _uploadImageToCloudinary,
                  ),
                  const SizedBox(height: 16.0),
                  _buildMediaUploadCard(
                    title: 'Video Upload',
                    icon: Icons.video_library,
                    content: Text(
                      _videoFile != null
                          ? 'Selected: ${_videoFile!.name}'
                          : 'No video selected',
                      style: const TextStyle(
                        fontSize: 16,
                        color: Colors.grey,
                      ),
                    ),
                    pickAction: _pickVideo,
                    uploadAction: _videoFile == null ? null : _uploadVideoToCloudinary,
                  ),
                  const SizedBox(height: 32.0),
                  _buildSubmitButton(),
                  const SizedBox(height: 24.0),
                ],
              ),
            ),
          ),
          if (isUploading)
            Container(
              color: Colors.black54,
              child: Center(
                child: Card(
                  elevation: 8,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: const Padding(
                    padding: EdgeInsets.all(20),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        CircularProgressIndicator(),
                        SizedBox(height: 16),
                        Text(
                          'Uploading...',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.blue.shade700,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        title,
        style: const TextStyle(
          color: Colors.white,
          fontSize: 18,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    int maxLines = 1,
    String? Function(String?)? validator,
  }) {
    return TextFormField(
      controller: controller,
      maxLines: maxLines,
      decoration: InputDecoration(
        labelText: label,
        prefixIcon: Icon(icon),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: Colors.blue.shade200),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: Colors.blue.shade200),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: Colors.blue.shade700, width: 2),
        ),
        filled: true,
        fillColor: Colors.white,
      ),
      validator: validator,
    );
  }

  Widget _buildDropdown({
    required String? value,
    required List<String> items,
    required String label,
    required IconData icon,
    required void Function(String?)? onChanged,
  }) {
    return DropdownButtonFormField<String>(
      value: value,
      decoration: InputDecoration(
        labelText: label,
        prefixIcon: Icon(icon),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: Colors.blue.shade200),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: Colors.blue.shade200),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: Colors.blue.shade700, width: 2),
        ),
        filled: true,
        fillColor: Colors.white,
      ),
      items: items.map((item) {
        return DropdownMenuItem(
          value: item,
          child: Text(item),
        );
      }).toList(),
      onChanged: onChanged,
    );
  }

  Widget _buildDatePicker() {
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Selected Date',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  DateFormat('yyyy-MM-dd').format(selectedDate),
                  style: const TextStyle(fontSize: 16),
                ),
              ],
            ),
            ElevatedButton.icon(
              icon: const Icon(Icons.calendar_today),
              label: const Text('Change'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.blue.shade700,
                padding: const EdgeInsets.symmetric(
                  horizontal: 20,
                  vertical: 12,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              onPressed: () => _selectDate(context),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMediaUploadCard({
    required String title,
    required IconData icon,
    required Widget content,
    required VoidCallback? pickAction,
    required VoidCallback? uploadAction,
  }) {
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(icon, color: Colors.blue.shade700),
                const SizedBox(width: 8),
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Center(child: content),
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                ElevatedButton.icon(
                  icon: const Icon(Icons.add_photo_alternate),
                  label: const Text('Select'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.blue.shade700,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 20,
                      vertical: 12,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  onPressed: pickAction,
                ),
                ElevatedButton.icon(
                  icon: const Icon(Icons.cloud_upload),
                  label: const Text('Upload'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.teal.shade600,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 20,
                      vertical: 12,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  onPressed: uploadAction,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSubmitButton() {
    return Center(
      child: SizedBox(
        width: double.infinity,
        child: ElevatedButton.icon(
          icon: isUploading
              ? const SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(
                    color: Colors.white,
                    strokeWidth: 2,
                  ),
                )
              : const Icon(Icons.send),
          label: Text(
            isUploading ? 'Submitting...' : 'Submit Entry',
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.blue.shade700,
            padding: const EdgeInsets.symmetric(
              horizontal: 40,
              vertical: 16,
            ),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
          onPressed: isUploading ? null : _submitEntry,
        ),
      ),
    );
  }

  @override
  void dispose() {
    titleController.dispose();
    descriptionController.dispose();
    super.dispose();
  }
}