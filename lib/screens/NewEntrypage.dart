import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:image_picker/image_picker.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:speech_to_text/speech_to_text.dart' as stt;
import 'dart:typed_data';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:permission_handler/permission_handler.dart';

class NewEntryPage extends StatefulWidget {
  const NewEntryPage({Key? key}) : super(key: key);

  @override
  State<NewEntryPage> createState() => _NewEntryPageState();
}

class _NewEntryPageState extends State<NewEntryPage> {
  DateTime selectedDate = DateTime.now();
  Uint8List? selectedImageBytes;
  String? uploadedImageUrl;
  final titleController = TextEditingController();
  final descriptionController = TextEditingController();

  static const String cloudName = 'dvv3cnhmq';
  static const String uploadPreset = 'project1';

  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  stt.SpeechToText _speech = stt.SpeechToText();
  bool _isListening = false;
  String _currentField = '';
  double _confidence = 0.0;

  @override
  void initState() {
    super.initState();
    _initializeSpeech();
    _requestPermissions();
  }

  Future<void> _requestPermissions() async {
    await Permission.microphone.request();
    await Permission.storage.request();
    await Permission.camera.request();
  }

  Future<void> _initializeSpeech() async {
    try {
      bool available = await _speech.initialize(
        onStatus: _onSpeechStatus,
        onError: _onSpeechError,
      );
      if (!available) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text("Speech recognition not available on this device")),
          );
        }
      }
    } catch (e) {
      print("Speech initialization error: $e");
    }
  }

  void _onSpeechStatus(String status) {
    print('Speech status: $status');
    if (status == 'done' && mounted) {
      setState(() => _isListening = false);
    }
  }

  void _onSpeechError(dynamic error) {
    print('Speech error: $error');
    if (mounted) {
      setState(() => _isListening = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Error occurred: $error")),
      );
    }
  }

  Future<void> _uploadImageToCloudinary() async {
    final cloudinaryUrl = "https://api.cloudinary.com/v1_1/$cloudName/image/upload";

    if (selectedImageBytes == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Please select an image first!"))
      );
      return;
    }

    try {
      final request = http.MultipartRequest('POST', Uri.parse(cloudinaryUrl))
        ..fields['upload_preset'] = uploadPreset
        ..fields['folder'] = 'diary_entries'
        ..fields['resource_type'] = 'image'
        ..files.add(http.MultipartFile.fromBytes(
          'file',
          selectedImageBytes!,
          filename: 'diary_image.jpg',
        ));

      final response = await request.send();
      final responseBody = await response.stream.bytesToString();

      if (response.statusCode == 200) {
        final jsonResponse = json.decode(responseBody);
        setState(() {
          uploadedImageUrl = jsonResponse['secure_url'];
        });
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Image uploaded successfully!"))
        );
      } else {
        print('Cloudinary Upload Error Response: $responseBody');
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Upload failed: ${response.statusCode}"))
        );
      }
    } catch (e) {
      print('Cloudinary Upload Error: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Failed to upload image: $e"))
      );
    }
  }

  Future<void> _startListening(String field) async {
    final micPermission = await Permission.microphone.status;
    if (micPermission.isDenied) {
      await Permission.microphone.request();
      return;
    }

    final TextEditingController controller = 
      field == 'title' ? titleController : descriptionController;

    if (!_speech.isAvailable) {
      await _initializeSpeech();
    }

    setState(() {
      _currentField = field;
      _isListening = true;
    });

    try {
      await _speech.listen(
        onResult: (result) {
          setState(() {
            _confidence = result.confidence;
            String newText = result.recognizedWords;
            if (newText.isNotEmpty) {
              String currentText = controller.text;
              if (currentText.isNotEmpty && !currentText.endsWith(' ')) {
                currentText += ' ';
              }
              controller.text = currentText + newText;
              controller.selection = TextSelection.fromPosition(
                TextPosition(offset: controller.text.length),
              );
            }
          });
        },
        listenMode: stt.ListenMode.dictation,
        pauseFor: const Duration(seconds: 3),
        cancelOnError: true,
        partialResults: true,
      );
    } catch (e) {
      print("Error starting speech recognition: $e");
      setState(() => _isListening = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Failed to start speech recognition: $e")),
      );
    }
  }

  void _stopListening() {
    _speech.stop();
    setState(() {
      _isListening = false;
      _currentField = '';
    });
  }

  Future<void> _saveEntry() async {
    if (_auth.currentUser == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please sign in to create an entry'))
      );
      return;
    }

    if (titleController.text.isEmpty || descriptionController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please fill in both title and description'))
      );
      return;
    }

    try {
      if (selectedImageBytes != null && uploadedImageUrl == null) {
        await _uploadImageToCloudinary();
      }

      DocumentReference docRef = await _firestore.collection('dairyentry').add({
        'title': titleController.text,
        'description': descriptionController.text,
        'date': '${selectedDate.year}-${selectedDate.month}-${selectedDate.day}',
        'imageUrl': uploadedImageUrl,
        'createdAt': DateTime.now(),
        'userId': _auth.currentUser!.uid,
        'userEmail': _auth.currentUser!.email,
        'speechConfidence': _confidence,
        'lastModified': DateTime.now(),
        'hasAudioInput': _speech.hasRecognized,
      });

      print('Diary entry saved with ID: ${docRef.id}');

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Diary entry saved successfully!'))
      );
      Navigator.pop(context);
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to save entry: $e'))
      );
    }
  }

  Future<void> _pickImage() async {
    final picker = ImagePicker();
    final pickedFile = await picker.pickImage(
      source: ImageSource.gallery,
      imageQuality: 85,
    );
    if (pickedFile != null) {
      final bytes = await pickedFile.readAsBytes();
      setState(() {
        selectedImageBytes = bytes;
        uploadedImageUrl = null;
      });
    }
  }

  Future<void> _selectDate() async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: selectedDate,
      firstDate: DateTime(2000),
      lastDate: DateTime(2100),
    );
    if (picked != null && picked != selectedDate) {
      setState(() {
        selectedDate = picked;
      });
    }
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    required String field,
    int maxLines = 1,
  }) {
    bool isCurrentlyListening = _isListening && _currentField == field;
    
    return Stack(
      children: [
        TextField(
          controller: controller,
          maxLines: maxLines,
          decoration: InputDecoration(
            labelText: label,
            suffixIcon: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (isCurrentlyListening)
                  Container(
                    width: 24,
                    height: 24,
                    margin: const EdgeInsets.only(right: 8),
                    child: const CircularProgressIndicator(
                      strokeWidth: 2,
                    ),
                  ),
                IconButton(
                  icon: Icon(
                    isCurrentlyListening ? Icons.mic : Icons.mic_none,
                    color: isCurrentlyListening ? Colors.red : null,
                  ),
                  onPressed: () {
                    if (isCurrentlyListening) {
                      _stopListening();
                    } else {
                      _startListening(field);
                    }
                  },
                ),
              ],
            ),
            labelStyle: TextStyle(color: Colors.grey[600]),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: Colors.grey[300]!),
            ),
          ),
        ),
        if (isCurrentlyListening)
          Positioned(
            right: 50,
            top: 0,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: Colors.red.withOpacity(0.1),
                borderRadius: BorderRadius.circular(4),
              ),
              child: const Text(
                'Listening...',
                style: TextStyle(
                  color: Colors.red,
                  fontSize: 12,
                ),
              ),
            ),
          ),
      ],
    );
  }

  Widget _buildCalendarSection() {
    return Container(
      margin: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            "Select Date",
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 10),
          GestureDetector(
            onTap: _selectDate,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.grey[300]!),
              ),
              child: Text(
                "${selectedDate.year}-${selectedDate.month}-${selectedDate.day}",
                style: const TextStyle(fontSize: 16),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildImageUploadSection() {
    return Column(
      children: [
        if (selectedImageBytes != null) ...[
          Image.memory(
            selectedImageBytes!,
            height: 200,
            fit: BoxFit.cover,
          ),
          const SizedBox(height: 16),
        ] else
          Container(
            height: 200,
            width: double.infinity,
            decoration: BoxDecoration(
              color: Colors.grey[200],
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Icon(
              Icons.image,
              size: 50,
              color: Colors.grey,
            ),
          ),
        const SizedBox(height: 16),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: [
            ElevatedButton.icon(
              onPressed: _pickImage,
              icon: const Icon(Icons.photo_library),
              label: const Text("Select Image"),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.blue,
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              ),
            ),
            if (selectedImageBytes != null)
              ElevatedButton.icon(
                onPressed: _uploadImageToCloudinary,
                icon: const Icon(Icons.cloud_upload),
                label: const Text("Upload"),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.green,
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                ),
              ),
          ],
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[100],
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Color(0xFF1E1E1E)),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          "New Diary Entry",
          style: TextStyle(
            color: Color(0xFF1E1E1E),
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildCalendarSection(),
            Container(
              margin: const EdgeInsets.all(16),
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
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildTextField(
                    controller: titleController,
                    label: "Title",
                    field: "title",
                  ),
                  const SizedBox(height: 16),
                  _buildTextField(
                    controller: descriptionController,
                    label: "Description",
                    field: "description",
                    maxLines: 5,
                  ),
                  const SizedBox(height: 24),
                  _buildImageUploadSection(),const SizedBox(height: 24),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: _saveEntry,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF6B4EFF),
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: const Text(
                        "Save Entry",
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  void dispose() {
    titleController.dispose();
    descriptionController.dispose();
    _speech.cancel();

    
    super.dispose();
  }
}