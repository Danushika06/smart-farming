import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:http/http.dart' as http;
import 'package:open_file/open_file.dart';
import 'pdf_report.dart';

class DiseaseDetectionScreen extends StatefulWidget {
  final String language;
  DiseaseDetectionScreen({required this.language});

  @override
  _DiseaseDetectionScreenState createState() => _DiseaseDetectionScreenState();
}

class _DiseaseDetectionScreenState extends State<DiseaseDetectionScreen> {
  File? _image;
  String? detectedDisease;
  String? treatmentInfo;
  bool isLoading = false;
  String? pdfPath;

  final ImagePicker _picker = ImagePicker();
  final String baseUrl = "http://192.168.248.134:8980";

  Future<void> pickImage(ImageSource source) async {
    final pickedFile = await _picker.pickImage(source: source);

    if (pickedFile != null) {
      setState(() {
        _image = File(pickedFile.path);
        detectedDisease = null;
        treatmentInfo = null;
        pdfPath = null;
      });

      detectDisease();
    }
  }

  Future<void> detectDisease() async {
    if (_image == null) return;

    setState(() {
      isLoading = true;
    });

    try {
      var request = http.MultipartRequest(
        "POST",
        Uri.parse("$baseUrl/detect-disease/"),
      );

      request.files.add(
        await http.MultipartFile.fromPath("image", _image!.path),
      );

      request.fields['language'] = widget.language; // Pass language

      var response = await request.send();
      var responseData = await response.stream.bytesToString();

      if (response.statusCode == 200) {
        var data = jsonDecode(responseData);
        setState(() {
          detectedDisease = data["disease"];
          treatmentInfo = data["gemini_insights"];
        });

        // Generate PDF report
        pdfPath = await ReportGenerator.generateDiseaseReport(
          diseaseName: detectedDisease!,
          treatment: treatmentInfo!,
          imageFile: _image,
          language: widget.language, // Pass language for Tamil PDF
        );
      } else {
        setState(() {
          detectedDisease =
              widget.language == "ta"
                  ? "நோய் கண்டறிய முடியவில்லை"
                  : "Error detecting disease";
        });
      }
    } catch (e) {
      setState(() {
        detectedDisease =
            widget.language == "ta"
                ? "API இணைப்பில் தோல்வி"
                : "Failed to connect to API";
      });
    }

    setState(() {
      isLoading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          widget.language == "ta" ? "நோய் கண்டறிதல்" : "Disease Detection",
        ),
      ),
      body: SingleChildScrollView(
        padding: EdgeInsets.all(16.0),
        child: Column(
          children: [
            if (_image != null)
              Card(
                child: Padding(
                  padding: EdgeInsets.all(8.0),
                  child: Image.file(_image!, height: 200),
                ),
              )
            else
              Card(
                child: Container(
                  height: 200,
                  alignment: Alignment.center,
                  child: Text(
                    widget.language == "ta"
                        ? "படம் தேர்ந்தெடுக்கப்படவில்லை"
                        : "No image selected",
                    style: TextStyle(fontSize: 16),
                  ),
                ),
              ),
            SizedBox(height: 20),
            Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                ElevatedButton.icon(
                  onPressed: () => pickImage(ImageSource.camera),
                  icon: Icon(Icons.camera_alt),
                  label: Text(
                    widget.language == "ta"
                        ? "கேமரா பயன்படுத்தவும்"
                        : "Use Camera",
                  ),
                ),
                SizedBox(height: 10), // Adds space between buttons
                ElevatedButton.icon(
                  onPressed: () => pickImage(ImageSource.gallery),
                  icon: Icon(Icons.photo_library),
                  label: Text(
                    widget.language == "ta"
                        ? "படத்தை பதிவேற்றவும்"
                        : "Upload Image",
                  ),
                ),
              ],
            ),

            SizedBox(height: 20),
            if (isLoading)
              CircularProgressIndicator()
            else if (detectedDisease != null)
              Card(
                child: Padding(
                  padding: EdgeInsets.all(16.0),
                  child: Column(
                    children: [
                      Text(
                        widget.language == "ta"
                            ? "கண்டறியப்பட்ட நோய்: $detectedDisease"
                            : "Detected Disease: $detectedDisease",
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      SizedBox(height: 10),
                      if (treatmentInfo != null)
                        Text(treatmentInfo!, textAlign: TextAlign.center),
                    ],
                  ),
                ),
              ),
            if (pdfPath != null) ...[
              SizedBox(height: 20),
              ElevatedButton.icon(
                onPressed: () => OpenFile.open(pdfPath),
                icon: Icon(Icons.download),
                label: Text(
                  widget.language == "ta"
                      ? "அறிக்கையைப் பதிவிறக்கவும்"
                      : "Download Report",
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
