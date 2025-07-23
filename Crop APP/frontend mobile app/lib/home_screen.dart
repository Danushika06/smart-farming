import 'package:flutter/material.dart';
import 'crop_recommendation_screen.dart';
import 'disease_detection_screen.dart';

class HomeScreen extends StatelessWidget {
  final String language;

  HomeScreen({required this.language});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          language == "ta" ? "ஸ்மார்ட் விவசாயம்" : "Smart Farming Dashboard",
        ),
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            ElevatedButton(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder:
                        (context) =>
                            CropRecommendationScreen(language: language),
                  ),
                );
              },
              child: Text(
                language == "ta" ? "பயிர் பரிந்துரை" : "Crop Recommendation",
              ),
            ),
            SizedBox(height: 20),
            ElevatedButton(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder:
                        (context) => DiseaseDetectionScreen(language: language),
                  ),
                );
              },
              child: Text(
                language == "ta" ? "நோய் கண்டறிதல்" : "Disease Detection",
              ),
            ),
          ],
        ),
      ),
    );
  }
}
