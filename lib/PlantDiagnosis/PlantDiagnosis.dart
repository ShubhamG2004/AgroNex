import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_spinkit/flutter_spinkit.dart';
import 'package:image_picker/image_picker.dart';
import 'package:http/http.dart' as http;
// import 'api_service.dart';
import 'api_constants.dart';
class ImageChat extends StatefulWidget {
  const ImageChat({super.key});

  @override
  State<ImageChat> createState() => _ImageChatState();
}

class _ImageChatState extends State<ImageChat> {
  XFile? pickedImage;
  String mytext = '';
  bool scanning = false;
  TextEditingController prompt = TextEditingController();
  final ImagePicker _imagePicker = ImagePicker();

  // Corrected API URL for Gemini 1.5 Flash
  final apiUrl = 'https://generativelanguage.googleapis.com/v1/models/gemini-1.5-flash:generateContent?key=${api_constants.apiKey}';

  final header = {
    'Content-Type': 'application/json',
  };

  getImage(ImageSource ourSource) async {
    XFile? result = await _imagePicker.pickImage(source: ourSource);
    if (result != null) {
      setState(() {
        pickedImage = result;
      });
    }
  }

  getdata(XFile? image, String promptValue) async {
    if (image == null) {
      setState(() {
        mytext = 'Please select an image first!';
      });
      return;
    }

    setState(() {
      scanning = true;
      mytext = '';
    });

    try {
      // Read image and convert to base64
      List<int> imageBytes = await File(image.path).readAsBytes();
      String base64File = base64Encode(imageBytes);

      // Corrected JSON format for Gemini 1.5 Flash
      final data = {
        "contents": [
          {
            "parts": [
              {"text": promptValue},
              {
                "inline_data": {
                  "mime_type": "image/jpeg",
                  "data": base64File
                }
              }
            ]
          }
        ]
      };

      final response = await http.post(Uri.parse(apiUrl), headers: header, body: jsonEncode(data));

      if (response.statusCode == 200) {
        var result = jsonDecode(response.body);
        mytext = result['candidates'][0]['content']['parts'][0]['text'];
      } else {
        mytext = 'Response error: ${response.statusCode}\n${response.body}';
      }
    } catch (e) {
      mytext = 'Error: $e';
    }

    setState(() {
      scanning = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Disease Diagnosis',
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
        backgroundColor: Colors.black,
        actions: [
          IconButton(
            onPressed: () {
              getImage(ImageSource.gallery);
            },
            icon: const Icon(Icons.photo, color: Colors.white),
          ),
          const SizedBox(width: 10),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(20.0),
        child: ListView(
          children: [
            pickedImage == null
                ? Container(
              height: 340,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(20.0),
                border: Border.all(color: Colors.black, width: 2.0),
              ),
              child: const Center(
                child: Text('No Image Selected', style: TextStyle(fontSize: 22)),
              ),
            )
                : Container(
              height: 340,
              child: Center(
                child: Image.file(File(pickedImage!.path), height: 400),
              ),
            ),
            const SizedBox(height: 20),
            TextField(
              controller: prompt,
              decoration: InputDecoration(
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10.0),
                  borderSide: const BorderSide(color: Colors.black, width: 2.0),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10.0),
                  borderSide: const BorderSide(color: Colors.black, width: 2.0),
                ),
                prefixIcon: const Icon(Icons.pending_sharp, color: Colors.black),
                hintText: 'Enter your prompt here',
              ),
            ),
            const SizedBox(height: 20),
            ElevatedButton.icon(
              onPressed: () {
                getdata(pickedImage, prompt.text);
              },
              icon: const Icon(Icons.generating_tokens_rounded, color: Colors.white),
              label: const Padding(
                padding: EdgeInsets.all(10),
                child: Text(
                  'Generate Answer',
                  style: TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold),
                ),
              ),
              style: ElevatedButton.styleFrom(backgroundColor: Colors.black),
            ),
            const SizedBox(height: 30),
            scanning
                ? const Padding(
              padding: EdgeInsets.only(top: 60),
              child: Center(child: SpinKitThreeBounce(color: Colors.black, size: 20)),
            )
                : Text(mytext, textAlign: TextAlign.center, style: const TextStyle(fontSize: 20)),
          ],
        ),
      ),
    );
  }
}
