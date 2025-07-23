import 'dart:io';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:path_provider/path_provider.dart';
import 'package:intl/intl.dart';
import 'package:flutter/services.dart' show rootBundle;

class ReportGenerator {
  static Future<String> generateCropReport({
    required String location,
    required String area,
    required Map<String, dynamic> sensorData,
    required String recommendedCrop,
    required String insights,
    required String language, // Pass selected language
  }) async {
    final pdf = pw.Document();

    // Load Tamil Font
    final tamilFont = pw.Font.ttf(
      await rootBundle.load("assets/fonts/NotoSansTamil-Regular.ttf"),
    );
    final boldTamilFont = pw.Font.ttf(
      await rootBundle.load("assets/fonts/NotoSansTamil-Bold.ttf"),
    );

    pdf.addPage(
      pw.MultiPage(
        build:
            (context) => [
              pw.Header(
                level: 0,
                child: pw.RichText(
                  text: pw.TextSpan(
                    text:
                        language == "ta"
                            ? "பயிர் பரிந்துரை அறிக்கை"
                            : "Crop Recommendation Report",
                    style: pw.TextStyle(font: boldTamilFont, fontSize: 24),
                  ),
                ),
              ),
              pw.RichText(
                text: pw.TextSpan(
                  text:
                      "Generated on: ${DateFormat('yyyy-MM-dd HH:mm').format(DateTime.now())}",
                  style: pw.TextStyle(font: tamilFont),
                ),
              ),
              pw.SizedBox(height: 20),
              pw.RichText(
                text: pw.TextSpan(
                  text:
                      language == "ta"
                          ? "இடம்: $location"
                          : "Location: $location",
                  style: pw.TextStyle(font: tamilFont),
                ),
              ),
              pw.RichText(
                text: pw.TextSpan(
                  text:
                      language == "ta"
                          ? "பரப்பு (ஏக்கர்): $area"
                          : "Area (Acres): $area",
                  style: pw.TextStyle(font: tamilFont),
                ),
              ),
              pw.SizedBox(height: 20),
              pw.Header(
                level: 1,
                child: pw.RichText(
                  text: pw.TextSpan(
                    text:
                        language == "ta" ? "சென்சார் தகவல்" : "Sensor Readings",
                    style: pw.TextStyle(font: boldTamilFont),
                  ),
                ),
              ),
              ...sensorData.entries.map(
                (e) => pw.RichText(
                  text: pw.TextSpan(
                    text: '${e.key}: ${e.value.toStringAsFixed(2)}',
                    style: pw.TextStyle(font: tamilFont),
                  ),
                ),
              ),
              pw.SizedBox(height: 20),
              pw.Header(
                level: 1,
                child: pw.RichText(
                  text: pw.TextSpan(
                    text:
                        language == "ta"
                            ? "பரிந்துரைக்கப்பட்ட பயிர்"
                            : "Recommended Crop",
                    style: pw.TextStyle(font: boldTamilFont),
                  ),
                ),
              ),
              pw.RichText(
                text: pw.TextSpan(
                  text: recommendedCrop,
                  style: pw.TextStyle(font: tamilFont),
                ),
              ),
              pw.SizedBox(height: 20),
              pw.Header(
                level: 1,
                child: pw.RichText(
                  text: pw.TextSpan(
                    text:
                        language == "ta"
                            ? "வளர்ப்பு வழிமுறைகள்"
                            : "Growing Guidelines",
                    style: pw.TextStyle(font: boldTamilFont),
                  ),
                ),
              ),
              pw.RichText(
                text: pw.TextSpan(
                  text: insights,
                  style: pw.TextStyle(font: tamilFont),
                ),
              ),
            ],
      ),
    );

    final output = await getTemporaryDirectory();
    final file = File('${output.path}/crop_report.pdf');
    await file.writeAsBytes(await pdf.save());
    return file.path;
  }

  static Future<String> generateDiseaseReport({
    required String diseaseName,
    required String treatment,
    required File? imageFile,
    required String language, // Pass selected language
  }) async {
    final pdf = pw.Document();

    // Load Tamil Font
    final tamilFont = pw.Font.ttf(
      await rootBundle.load("assets/fonts/NotoSansTamil-Regular.ttf"),
    );
    final boldTamilFont = pw.Font.ttf(
      await rootBundle.load("assets/fonts/NotoSansTamil-Bold.ttf"),
    );

    final image =
        imageFile != null
            ? pw.MemoryImage(await imageFile.readAsBytes())
            : null;

    pdf.addPage(
      pw.MultiPage(
        build:
            (context) => [
              pw.Header(
                level: 0,
                child: pw.RichText(
                  text: pw.TextSpan(
                    text:
                        language == "ta"
                            ? "தாவர நோய் அறிக்கை"
                            : "Plant Disease Detection Report",
                    style: pw.TextStyle(font: boldTamilFont, fontSize: 24),
                  ),
                ),
              ),
              pw.RichText(
                text: pw.TextSpan(
                  text:
                      "Generated on: ${DateFormat('yyyy-MM-dd HH:mm').format(DateTime.now())}",
                  style: pw.TextStyle(font: tamilFont),
                ),
              ),
              pw.SizedBox(height: 20),

              if (image != null) ...[
                pw.Header(
                  level: 1,
                  child: pw.RichText(
                    text: pw.TextSpan(
                      text: language == "ta" ? "தாவரப் படம்" : "Plant Image",
                      style: pw.TextStyle(font: boldTamilFont),
                    ),
                  ),
                ),
                pw.Image(image, height: 200),
                pw.SizedBox(height: 20),
              ],

              pw.Header(
                level: 1,
                child: pw.RichText(
                  text: pw.TextSpan(
                    text: language == "ta" ? "நோய் விவரம்" : "Disease Details",
                    style: pw.TextStyle(font: boldTamilFont),
                  ),
                ),
              ),
              pw.RichText(
                text: pw.TextSpan(
                  text: diseaseName,
                  style: pw.TextStyle(font: tamilFont),
                ),
              ),
              pw.SizedBox(height: 20),
              pw.Header(
                level: 1,
                child: pw.RichText(
                  text: pw.TextSpan(
                    text:
                        language == "ta"
                            ? "சிகிச்சை வழிமுறைகள்"
                            : "Treatment Guidelines",
                    style: pw.TextStyle(font: boldTamilFont),
                  ),
                ),
              ),
              pw.RichText(
                text: pw.TextSpan(
                  text: treatment,
                  style: pw.TextStyle(font: tamilFont),
                ),
              ),
            ],
      ),
    );

    final output = await getTemporaryDirectory();
    final file = File('${output.path}/disease_report.pdf');
    await file.writeAsBytes(await pdf.save());
    return file.path;
  }
}
