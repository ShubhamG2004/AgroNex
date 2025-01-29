import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:http/http.dart' as http;

class PlantDiseaseDetect extends StatefulWidget {
  @override
  _PlantDiseaseDetectState createState() => _PlantDiseaseDetectState();
}

class _PlantDiseaseDetectState extends State<PlantDiseaseDetect> {
  File? _image;
  final ImagePicker _picker = ImagePicker();
  String? _diseaseName;
  bool _isLoading = false;

  Future<void> _pickImage() async {
    final pickedFile = await _picker.pickImage(source: ImageSource.gallery);

    if (pickedFile != null) {
      setState(() {
        _image = File(pickedFile.path);
        _diseaseName = null; // Reset the previous result
      });
    }
  }

  Future<void> _detectDisease() async {
    if (_image == null) return;

    setState(() {
      _isLoading = true;
    });

    final apiUrl = "https://plant.id/api/v3/health_assessment";
    final apiKey = "U6Am7OtQVPPAg4JocQTPNfEu1b1bmwljeyVMCqgN0cl7dRqka4"; // Replace with your API key

    try {
      // Convert the image to base64
      final bytes = await _image!.readAsBytes();
      final base64Image = base64Encode(bytes);

      // Create the request payload (remove 'similar_images' modifier)
      final payload = {
        "images": ["data:image/jpg;base64,$base64Image"],
        "latitude": 49.207,
        "longitude": 16.608,
        "health": "only"
      };

      // Send the POST request
      final response = await http.post(
        Uri.parse(apiUrl),
        headers: {
          "Content-Type": "application/json",
          "Api-Key": apiKey,
        },
        body: jsonEncode(payload),
      );

      if (response.statusCode == 200) {
        final result = json.decode(response.body);
        final suggestions = result['result']['disease']['suggestions'];

        setState(() {
          if (suggestions != null && suggestions.isNotEmpty) {
            _diseaseName = suggestions[0]['name'];
          } else {
            _diseaseName = 'No disease detected';
          }
        });
      } else {
        setState(() {
          _diseaseName = "Error: ${response.body}";
        });
      }
    } catch (e) {
      setState(() {
        _diseaseName = "An error occurred: $e";
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
        title: Text('Plant Disease Detection'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            if (_image != null)
              Image.file(
                _image!,
                height: 200,
                width: 200,
                fit: BoxFit.cover,
              )
            else
              Container(
                height: 200,
                width: 200,
                color: Colors.grey[300],
                child: Center(
                  child: Text('No Image Selected'),
                ),
              ),
            SizedBox(height: 16),
            ElevatedButton(
              onPressed: _pickImage,
              child: Text('Pick Image'),
            ),
            SizedBox(height: 16),
            ElevatedButton(
              onPressed: _image != null && !_isLoading ? _detectDisease : null,
              child: _isLoading
                  ? SizedBox(
                height: 20,
                width: 20,
                child: CircularProgressIndicator(strokeWidth: 2),
              )
                  : Text('Detect Disease'),
            ),
            SizedBox(height: 16),
            if (_diseaseName != null)
              Text(
                'Disease: $_diseaseName',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                textAlign: TextAlign.center,
              ),
          ],
        ),
      ),
    );
  }
}