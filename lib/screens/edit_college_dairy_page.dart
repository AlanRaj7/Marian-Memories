import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:image_picker/image_picker.dart';
import 'package:video_player/video_player.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'dart:io';
import 'package:permission_handler/permission_handler.dart';
import 'package:get/get.dart';
import 'package:flutter/foundation.dart' show kIsWeb;

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
  String? _videoUrl;
  Uint8List? _imageBytes;
  XFile? _videoFile;
  VideoPlayerController? _videoController;
  bool _isLoading = false;
  bool _isUploadingVideo = false;
  bool _isVideoInitialized = false;

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
    
    // Safely check if 'videoUrl' exists in the document
    if (widget.entry.data() is Map && (widget.entry.data() as Map).containsKey('videoUrl')) {
      _videoUrl = widget.entry['videoUrl'];
      if (_videoUrl != null && _videoUrl!.isNotEmpty) {
        _initializeVideoController();
      }
    }
  }

  void _initializeVideoController() {
    _videoController = VideoPlayerController.network(_videoUrl!)
      ..initialize().then((_) {
        if (mounted) {
          setState(() {
            _isVideoInitialized = true;
          });
        }
      }).catchError((error) {
        if (mounted) {
          setState(() {
            _isVideoInitialized = false;
          });
          Get.snackbar(
            'Warning',
            'Could not load existing video. You may want to update it.',
            snackPosition: SnackPosition.BOTTOM,
            backgroundColor: Colors.amber,
            colorText: Colors.white,
          );
        }
      });
  }

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    _departmentController.dispose();
    _activityController.dispose();
    _dateController.dispose();
    _videoController?.dispose();
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
      // On web, we don't need to check permissions
      if (!kIsWeb) {
        final status = await Permission.photos.request();
        if (status.isPermanentlyDenied) {
          await openAppSettings();
          return;
        }
        
        if (status.isDenied) {
          Get.snackbar(
            'Permission Required',
            'Please grant photo gallery access to select an image',
            snackPosition: SnackPosition.BOTTOM,
            backgroundColor: Colors.orange,
            colorText: Colors.white,
          );
          return;
        }
      }
      
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
        Get.snackbar(
          'Error',
          'Error picking image: $e',
          snackPosition: SnackPosition.BOTTOM,
          backgroundColor: Colors.red,
          colorText: Colors.white,
        );
      }
    }
  }

  Future<void> _pickVideo() async {
    try {
      // Skip permission check on web platforms
      if (!kIsWeb) {
        final status = await Permission.storage.request();
        if (status.isPermanentlyDenied) {
          await openAppSettings();
          return;
        }
        
        if (status.isDenied) {
          Get.snackbar(
            'Permission Required',
            'Please grant storage access to select a video',
            snackPosition: SnackPosition.BOTTOM,
            backgroundColor: Colors.orange,
            colorText: Colors.white,
          );
          return;
        }
      }
      
      final ImagePicker picker = ImagePicker();
      final XFile? video = await picker.pickVideo(
        source: ImageSource.gallery,
        maxDuration: const Duration(minutes: 5),
      );
      
      if (video != null) {
        // Dispose previous controller if exists
        await _videoController?.dispose();
        _videoController = null;
        
        // Create new controller for selected video
        if (kIsWeb) {
          // For web, we need to use network controller with a blob URL
          // ignore: unused_local_variable
          final videoBytes = await video.readAsBytes();
          _videoController = VideoPlayerController.network(
            video.path,
            videoPlayerOptions: VideoPlayerOptions(mixWithOthers: true),
          );
        } else {
          // For mobile platforms
          _videoController = VideoPlayerController.file(File(video.path));
        }
        
        _videoController!.initialize().then((_) {
          if (mounted) {
            setState(() {
              _isVideoInitialized = true;
            });
          }
        }).catchError((error) {
          if (mounted) {
            setState(() {
              _isVideoInitialized = false;
            });
            Get.snackbar(
              'Warning',
              'Could not initialize video preview: $error',
              snackPosition: SnackPosition.BOTTOM,
              backgroundColor: Colors.amber,
              colorText: Colors.white,
            );
          }
        });
        
        setState(() {
          _videoFile = video;
          _videoUrl = null;
        });
      }
    } catch (e) {
      if (mounted) {
        Get.snackbar(
          'Error',
          'Error picking video: $e',
          snackPosition: SnackPosition.BOTTOM,
          backgroundColor: Colors.red,
          colorText: Colors.white,
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
        Get.snackbar(
          'Error',
          'Error uploading image: $e',
          snackPosition: SnackPosition.BOTTOM,
          backgroundColor: Colors.red,
          colorText: Colors.white,
        );
      }
      return null;
    }
  }

  Future<String?> _uploadVideo() async {
    if (_videoFile == null) return _videoUrl;

    setState(() {
      _isUploadingVideo = true;
    });

    final cloudinaryUrl = "https://api.cloudinary.com/v1_1/$cloudName/video/upload";

    try {
      final videoBytes = await _videoFile!.readAsBytes();
      
      final request = http.MultipartRequest('POST', Uri.parse(cloudinaryUrl))
        ..fields['upload_preset'] = uploadPreset
        ..fields['folder'] = 'college_diary_videos'
        ..fields['resource_type'] = 'video'
        ..files.add(http.MultipartFile.fromBytes(
          'file',
          videoBytes,
          filename: _videoFile!.name,
        ));

      final response = await request.send();
      final responseBody = await response.stream.bytesToString();

      if (response.statusCode == 200) {
        final jsonResponse = json.decode(responseBody);
        return jsonResponse['secure_url'];
      } else {
        throw Exception('Failed to upload video: ${response.statusCode}');
      }
    } catch (e) {
      if (mounted) {
        Get.snackbar(
          'Error',
          'Error uploading video: $e',
          snackPosition: SnackPosition.BOTTOM,
          backgroundColor: Colors.red,
          colorText: Colors.white,
        );
      }
      return null;
    } finally {
      if (mounted) {
        setState(() {
          _isUploadingVideo = false;
        });
      }
    }
  }

  void _removeVideo() {
    Get.dialog(
      AlertDialog(
        title: const Text('Remove Video'),
        content: const Text('Are you sure you want to remove this video?'),
        actions: [
          TextButton(
            onPressed: () => Get.back(),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              setState(() {
                _videoFile = null;
                _videoUrl = null;
                _videoController?.dispose();
                _videoController = null;
                _isVideoInitialized = false;
              });
              Get.back();
            },
            child: const Text('Remove', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }

  Future<void> _saveChanges() async {
    if (_titleController.text.trim().isEmpty) {
      Get.snackbar(
        'Error',
        'Please enter a title',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.red,
        colorText: Colors.white,
      );
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      String? imageUrl = _imageBytes != null ? await _uploadImage() : _imageUrl;
      String? videoUrl = _videoFile != null ? await _uploadVideo() : _videoUrl;

      final updateData = {
        'title': _titleController.text.trim(),
        'description': _descriptionController.text.trim(),
        'department': _departmentController.text.trim(),
        'activity': _activityController.text.trim(),
        'date': _dateController.text.trim(),
        'imageUrl': imageUrl,
        'updatedAt': Timestamp.now(),
      };

      // Only add videoUrl to the update if it's not null
      if (videoUrl != null) {
        updateData['videoUrl'] = videoUrl;
      } else if (_videoUrl == null) {
        // If both videoUrl and _videoUrl are null, then we need to remove the field
        // Check if the field exists before trying to delete it
        if (widget.entry.data() is Map && (widget.entry.data() as Map).containsKey('videoUrl')) {
          updateData['videoUrl'] = FieldValue.delete();
        }
      }

      await widget.entry.reference.update(updateData);

      if (mounted) {
        Get.back(result: true);
      }
    } catch (e) {
      if (mounted) {
        Get.snackbar(
          'Error',
          'Error updating entry: $e',
          snackPosition: SnackPosition.BOTTOM,
          backgroundColor: Colors.red,
          colorText: Colors.white,
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

  Widget _buildVideoWidget() {
    if (_videoController != null && _isVideoInitialized) {
      return Stack(
        alignment: Alignment.center,
        children: [
          AspectRatio(
            aspectRatio: _videoController!.value.aspectRatio,
            child: VideoPlayer(_videoController!),
          ),
          GestureDetector(
            onTap: () {
              setState(() {
                if (_videoController!.value.isPlaying) {
                  _videoController!.pause();
                } else {
                  _videoController!.play();
                }
              });
            },
            child: Icon(
              _videoController!.value.isPlaying
                  ? Icons.pause_circle_filled
                  : Icons.play_circle_filled,
              size: 60,
              color: Colors.white.withOpacity(0.7),
            ),
          ),
          Positioned(
            top: 8,
            right: 8,
            child: IconButton(
              icon: const Icon(Icons.delete, color: Colors.red, size: 30),
              onPressed: _removeVideo,
            ),
          ),
          // Update video button
          Positioned(
            bottom: 8,
            right: 8,
            child: FloatingActionButton(
              mini: true,
              backgroundColor: const Color(0xFF6B4EFF),
              onPressed: _pickVideo,
              child: const Icon(Icons.edit, size: 20),
            ),
          ),
        ],
      );
    } else if (_videoFile != null) {
      return Stack(
        alignment: Alignment.center,
        children: [
          Container(
            width: double.infinity,
            height: 150,
            color: const Color(0xFF2C2C2C),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.video_file, size: 40, color: Colors.white),
                const SizedBox(height: 8),
                Text(
                  _videoFile?.name ?? 'New video selected',
                  style: const TextStyle(color: Colors.white),
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
          Positioned(
            top: 8,
            right: 8,
            child: IconButton(
              icon: const Icon(Icons.delete, color: Colors.red, size: 30),
              onPressed: _removeVideo,
            ),
          ),
          // Update video button
          Positioned(
            bottom: 8,
            right: 8,
            child: FloatingActionButton(
              mini: true,
              backgroundColor: const Color(0xFF6B4EFF),
              onPressed: _pickVideo,
              child: const Icon(Icons.edit, size: 20),
            ),
          ),
        ],
      );
    } else if (_videoUrl != null && _videoUrl!.isNotEmpty) {
      return Stack(
        alignment: Alignment.center,
        children: [
          Container(
            width: double.infinity,
            height: 150,
            color: const Color(0xFF2C2C2C),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.video_library, size: 40, color: Colors.white),
                const SizedBox(height: 8),
                const Text(
                  'Current video',
                  style: TextStyle(color: Colors.white),
                ),
              ],
            ),
          ),
          if (_isUploadingVideo)
            Container(
              color: Colors.black.withOpacity(0.5),
              child: const Center(
                child: CircularProgressIndicator(
                  valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF6B4EFF)),
                ),
              ),
            ),
          Positioned(
            top: 8,
            right: 8,
            child: IconButton(
              icon: const Icon(Icons.delete, color: Colors.red, size: 30),
              onPressed: _removeVideo,
            ),
          ),
          // Update video button
          Positioned(
            bottom: 8,
            right: 8,
            child: FloatingActionButton(
              mini: true,
              backgroundColor: const Color(0xFF6B4EFF),
              onPressed: _pickVideo,
              child: const Icon(Icons.edit, size: 20),
            ),
          ),
        ],
      );
    } else {
      return Stack(
        alignment: Alignment.center,
        children: [
          Container(
            width: double.infinity,
            height: 100,
            color: Colors.grey[200],
            child: const Center(
              child: Text('No video attached', style: TextStyle(color: Colors.grey)),
            ),
          ),
          // Add video button
          Positioned(
            bottom: 8,
            right: 8,
            child: FloatingActionButton(
              mini: true,
              backgroundColor: const Color(0xFF6B4EFF),
              onPressed: _pickVideo,
              child: const Icon(Icons.add, size: 20),
            ),
          ),
        ],
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
          onPressed: () => Get.back(),
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
                        _dateController.text.isEmpty ? 'Select Date' : _dateController.text,
                        style: TextStyle(
                          fontSize: 16,
                          color: _dateController.text.isEmpty ? Colors.grey : const Color(0xFF1E1E1E),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 16),

              // Image Section
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
                        child: _imageBytes != null || (_imageUrl != null && _imageUrl!.isNotEmpty) 
                          ? const Icon(Icons.edit, size: 20)
                          : const Icon(Icons.add, size: 20),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),

              // Video Section
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
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Row(
                        children: [
                          const Icon(
                            Icons.videocam,
                            color: Color(0xFF6B4EFF),
                            size: 24,
                          ),
                          const SizedBox(width: 8),
                          const Text(
                            'Video',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: Color(0xFF1E1E1E),
                            ),
                          ),
                        ],
                      ),
                    ),
                    ClipRRect(
                      borderRadius: const BorderRadius.only(
                        bottomLeft: Radius.circular(16),
                        bottomRight: Radius.circular(16),
                      ),
                      child: _buildVideoWidget(),
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
              const SizedBox(height: 32),
            ],
          ),
        ),
      ),
    );
  }
}