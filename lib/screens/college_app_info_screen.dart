// TODO Implement this library.import 'package:flutter/material.dart';
import 'package:flutter/material.dart';
import 'package:line_awesome_flutter/line_awesome_flutter.dart';

class CollegeAppInfoScreen extends StatefulWidget {
  const CollegeAppInfoScreen({Key? key}) : super(key: key);

  @override
  _CollegeAppInfoScreenState createState() => _CollegeAppInfoScreenState();
}

class _CollegeAppInfoScreenState extends State<CollegeAppInfoScreen> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('College App Information'),
        leading: IconButton(
          icon: Icon(LineAwesomeIcons.angle_left),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: SingleChildScrollView(
        padding: EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildInfoSection(
              'About Our marian memoriesS',
              'A comprehensive mobile application designed for college and personal Dairy '
              ,
            ),
            SizedBox(height: 20),
            _buildInfoSection(
              'Key Features',
              '• student Dairy\n'
              '• college dairy\n'
              '• profile screen\n'
              '• photo upload\n'
              '• Campus Announcements',
            ),
            SizedBox(height: 20),
            _buildInfoSection(
              'Version',
              'Version 1.0.0\nLast Updated: January 2024',
            ),
            SizedBox(height: 20),
            _buildInfoSection(
              'Contact Support',
              'Email: support@collegeapp.com\n'
              'Phone: +1 (555) 123-4567',
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoSection(String title, String content) {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(15),
      decoration: BoxDecoration(
        color: Colors.blue.shade50,
        borderRadius: BorderRadius.circular(10),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.2),
            spreadRadius: 1,
            blurRadius: 3,
            offset: Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Colors.blue.shade800,
            ),
          ),
          SizedBox(height: 10),
          Text(
            content,
            style: TextStyle(
              fontSize: 16,
              color: Colors.black87,
            ),
          ),
        ],
      ),
    );
  }
}