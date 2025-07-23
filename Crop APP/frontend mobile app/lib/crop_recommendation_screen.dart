import 'dart:convert';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:open_file/open_file.dart';
import 'pdf_report.dart';

class CropRecommendationScreen extends StatefulWidget {
  final String language;
  CropRecommendationScreen({required this.language});

  @override
  _CropRecommendationScreenState createState() =>
      _CropRecommendationScreenState();
}

class _CropRecommendationScreenState extends State<CropRecommendationScreen> {
  final TextEditingController locationController = TextEditingController();
  final TextEditingController areaController = TextEditingController();

  String? recommendedCrop;
  String? additionalInfo;
  bool isLoading = false;
  Map<String, dynamic>? sensorData;
  String? pdfPath;

  // ✅ Use `10.0.2.2` for emulator API connection
  final String baseUrl = "http://10.0.2.2:8980";

  @override
  void initState() {
    super.initState();
    sensorData = generateSensorData();
  }

  Map<String, dynamic> generateSensorData() {
    Random random = Random();
    return {
      "N": random.nextDouble() * 140,
      "P": 5 + random.nextDouble() * 140,
      "K": 5 + random.nextDouble() * 200,
      "temperature": 8.83 + random.nextDouble() * 35,
      "humidity": 14.26 + random.nextDouble() * 85,
      "ph": 3.5 + random.nextDouble() * 6.44,
      "rainfall": 20.21 + random.nextDouble() * 278.35,
    };
  }

  Future<void> fetchCropRecommendation() async {
    if (locationController.text.isEmpty || areaController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            widget.language == "ta"
                ? "இடம் மற்றும் பரப்பளவை உள்ளிடவும்"
                : "Please enter location and area",
          ),
        ),
      );
      return;
    }

    setState(() {
      isLoading = true;
      recommendedCrop = null;
      additionalInfo = null;
      pdfPath = null;
    });

    try {
      var requestData = {
        ...sensorData!,
        'location': locationController.text,
        'area': areaController.text,
        'language': widget.language, // Pass language to API
      };

      var response = await http.post(
        Uri.parse("$baseUrl/recommend-crop/"),
        headers: {"Content-Type": "application/json"},
        body: jsonEncode(requestData),
      );

      if (response.statusCode == 200) {
        var data = jsonDecode(utf8.decode(response.bodyBytes));

        setState(() {
          recommendedCrop = data["crop"];
          additionalInfo = data["gemini_insights"];
        });

        // ✅ Generate PDF report
        pdfPath = await ReportGenerator.generateCropReport(
          location: locationController.text,
          area: areaController.text,
          sensorData: sensorData!,
          recommendedCrop: recommendedCrop!,
          insights: additionalInfo!,
          language: widget.language, // Pass language for Tamil PDF
        );
      } else {
        setState(() {
          recommendedCrop =
              widget.language == "ta"
                  ? "தரவு பெறுவதில் சிக்கல்"
                  : "Error fetching data";
        });
      }
    } catch (e) {
      setState(() {
        recommendedCrop =
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
          widget.language == "ta" ? "பயிர் பரிந்துரை" : "Crop Recommendation",
        ),
      ),
      body: SingleChildScrollView(
        padding: EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Card(
              child: Padding(
                padding: EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      widget.language == "ta"
                          ? "தற்போதைய சென்சார் மதிப்புகள்:"
                          : "Current Sensor Readings:",
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    SizedBox(height: 10),
                    ...sensorData?.entries.map(
                          (e) => Padding(
                            padding: EdgeInsets.symmetric(vertical: 4),
                            child: Text(
                              "${e.key}: ${e.value.toStringAsFixed(2)}",
                            ),
                          ),
                        ) ??
                        [],
                  ],
                ),
              ),
            ),
            SizedBox(height: 20),
            TextField(
              controller: locationController,
              decoration: InputDecoration(
                labelText:
                    widget.language == "ta"
                        ? "இடத்தை உள்ளிடவும்"
                        : "Enter Location",
                border: OutlineInputBorder(),
              ),
            ),
            SizedBox(height: 10),
            TextField(
              controller: areaController,
              decoration: InputDecoration(
                labelText:
                    widget.language == "ta"
                        ? "பரப்பளவை (ஏக்கர்) உள்ளிடவும்"
                        : "Enter Area (in acres)",
                border: OutlineInputBorder(),
              ),
              keyboardType: TextInputType.number,
            ),
            SizedBox(height: 20),
            Center(
              child: ElevatedButton(
                onPressed: fetchCropRecommendation,
                child:
                    isLoading
                        ? CircularProgressIndicator(color: Colors.white)
                        : Text(
                          widget.language == "ta"
                              ? "பரிந்துரையைப் பெறுங்கள்"
                              : "Get Recommendation",
                        ),
              ),
            ),
            if (recommendedCrop != null) ...[
              SizedBox(height: 20),
              Card(
                child: Padding(
                  padding: EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        widget.language == "ta"
                            ? "பரிந்துரைக்கப்பட்ட பயிர்: $recommendedCrop"
                            : "Recommended Crop: $recommendedCrop",
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      SizedBox(height: 10),
                      if (additionalInfo != null) Text(additionalInfo!),
                    ],
                  ),
                ),
              ),
            ],
            if (pdfPath != null) ...[
              SizedBox(height: 20),
              Center(
                child: ElevatedButton.icon(
                  onPressed: () => OpenFile.open(pdfPath),
                  icon: Icon(Icons.download),
                  label: Text(
                    widget.language == "ta"
                        ? "அறிக்கையைப் பதிவிறக்கவும்"
                        : "Download Report",
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
