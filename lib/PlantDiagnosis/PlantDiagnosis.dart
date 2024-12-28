import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

class PlantDiagnosis extends StatefulWidget {
  @override
  _PlantDiagnosisState createState() => _PlantDiagnosisState();
}

class _PlantDiagnosisState extends State<PlantDiagnosis> {
  File? _image;
  String _diagnosisResult = "";
  bool _isLoading = false;

  final ImagePicker _picker = ImagePicker();

  // Replace with your AI endpoint
  final String _apiEndpoint = 'https://your-ai-api-endpoint/analyze';

  // Function to select an image from the gallery
  Future<void> _pickImageFromGallery() async {
    final pickedFile = await _picker.pickImage(source: ImageSource.gallery);

    if (pickedFile != null) {
      setState(() {
        _image = File(pickedFile.path);
        _diagnosisResult = ""; // Clear previous results
      });
      _analyzeImage(_image!);
    }
  }

  // Function to capture an image from the camera
  Future<void> _captureImage() async {
    final pickedFile = await _picker.pickImage(source: ImageSource.camera);

    if (pickedFile != null) {
      setState(() {
        _image = File(pickedFile.path);
        _diagnosisResult = ""; // Clear previous results
      });
      _analyzeImage(_image!);
    }
  }

  // Function to send the image to the AI backend for analysis
  Future<void> _analyzeImage(File imageFile) async {
    setState(() {
      _isLoading = true;
    });

    try {
      final request = http.MultipartRequest(
        'POST',
        Uri.parse(_apiEndpoint),
      );
      request.files.add(
        await http.MultipartFile.fromPath(
          'image',
          imageFile.path,
        ),
      );

      final response = await request.send();

      if (response.statusCode == 200) {
        final responseData = await response.stream.bytesToString();
        final decodedResponse = json.decode(responseData);

        setState(() {
          _diagnosisResult =
          "Disease: ${decodedResponse['disease']}\nSolution: ${decodedResponse['solution']}";
        });
      } else {
        setState(() {
          _diagnosisResult = "Error: Unable to diagnose the plant.";
        });
      }
    } catch (e) {
      setState(() {
        _diagnosisResult = "Error: ${e.toString()}";
      });
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Plant Diagnosis'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            if (_image != null)
              Image.file(
                _image!,
                height: 200,
                width: double.infinity,
                fit: BoxFit.cover,
              ),
            SizedBox(height: 16),
            ElevatedButton.icon(
              onPressed: _captureImage,
              icon: Icon(Icons.camera),
              label: Text('Capture Plant Image'),
            ),
            SizedBox(height: 16),
            ElevatedButton.icon(
              onPressed: _pickImageFromGallery,
              icon: Icon(Icons.photo_library),
              label: Text('Pick Image from Gallery'),
            ),
            SizedBox(height: 16),
            _isLoading
                ? CircularProgressIndicator()
                : Text(
              _diagnosisResult.isEmpty
                  ? "Capture or pick an image to diagnose the plant."
                  : _diagnosisResult,
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}
