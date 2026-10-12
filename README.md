# Smart Farming — Crop Recommendation and Plant Disease Detection App

**A Flutter mobile app with a FastAPI backend that recommends a crop from soil and weather readings, identifies a plant disease from a leaf photo, adds Gemini-generated farming advice in English or Tamil, and exports the result as a PDF report.**

![Flutter](https://img.shields.io/badge/Flutter-02569B?style=flat&logo=flutter&logoColor=white) ![Dart](https://img.shields.io/badge/Dart-0175C2?style=flat&logo=dart&logoColor=white) ![Python](https://img.shields.io/badge/Python-3776AB?style=flat&logo=python&logoColor=white) ![FastAPI](https://img.shields.io/badge/FastAPI-009688?style=flat&logo=fastapi&logoColor=white) ![PyTorch](https://img.shields.io/badge/PyTorch-EE4C2C?style=flat&logo=pytorch&logoColor=white) ![scikit-learn](https://img.shields.io/badge/scikit--learn-F7931E?style=flat&logo=scikit-learn&logoColor=white) ![Google Gemini](https://img.shields.io/badge/Gemini%20API-4285F4?style=flat&logo=googlegemini&logoColor=white)

## Overview

Small farmers often have to guess which crop suits their soil and how to treat a sick plant. This project is my prototype of a phone app for that: the farmer enters a location and field size to get a crop suggestion, or photographs a leaf to get a disease name and treatment advice. The advice can be read in Tamil or English and saved as a PDF.

The code splits into a Flutter client (`lib/`) and a Python backend (`backend/main.py`) that hosts two pre-trained models and calls the Gemini API for the written advice. To be straight about status, it is a working prototype with rough edges:

- The soil and weather values on the crop screen are **randomly generated in the app** (`generateSensorData`), standing in for a real sensor feed. Nothing reads real sensors.
- The **login screen does not authenticate**. Any username and password moves on to the home screen; it mainly serves as the language picker.
- The training code and datasets for the two models are not in the repo, only the saved model files, so I cannot report accuracy figures.
- Server addresses are hard-coded for my development setup (see Getting Started).

## Key Features

- **Crop recommendation** — a scikit-learn model takes seven inputs (N, P, K, temperature, humidity, pH, rainfall) and returns a crop name via `POST /recommend-crop/`.
- **Plant disease detection** — an EfficientNet-B0 classifier with a 19-class head (rice, wheat and maize diseases plus healthy classes, listed in `disease_classes`) takes a 224x224 image via `POST /detect-disease/`.
- **Generated advice** — the prediction goes into a Gemini prompt that asks for crop duration, water need, and fertilizer for a crop, or top-3 pesticides, best pesticide and prevention tips for a disease. `clean_gemini_response` strips markdown symbols and numbers the pesticide lines.
- **English and Tamil** — a language dropdown on the login screen, saved with `shared_preferences`, switches every label in the app, and the same `language` value is sent to the backend so the Gemini text comes back in Tamil.
- **Camera or gallery input** — `image_picker` lets the user shoot or upload a leaf photo, and detection starts as soon as an image is chosen.
- **PDF reports** — `ReportGenerator` in `pdf_report.dart` builds a crop report or a disease report (with the photo) using the bundled Noto Sans Tamil fonts, saves it to a temporary directory and opens it with `open_file`.
- **Healthy short-circuit** — when the disease model returns a healthy class, the backend answers directly without calling Gemini.

## How It Works

**Client flow.** `main.dart` starts at `LoginScreen`, which stores the chosen language and moves to `HomeScreen`. The home screen has two buttons:

1. `CropRecommendationScreen` generates a random sensor map, asks for location and area in acres, and posts the sensor values plus location, area and language as JSON to `/recommend-crop/`. The reply's `crop` and `gemini_insights` are shown on screen and written into a PDF.
2. `DiseaseDetectionScreen` posts the chosen image as multipart form data (`image`, `language`) to `/detect-disease/` and shows `disease` and `gemini_insights`, then builds the disease PDF.

**Backend flow.** `backend/main.py` creates a FastAPI app with CORS open to all origins and loads both models at import time: the crop model with `joblib` (`crop_recommendation_model.pkl`) and the disease model as `torchvision.models.efficientnet_b0` with its final linear layer replaced by 19 outputs, then loaded from `plant_disease_model.pth` on CPU. For a disease request the image is converted to RGB, resized to 224x224, turned into a tensor (no normalisation step), and the argmax class is looked up in `disease_classes`. Gemini is configured with `gemini-1.5-pro-latest` and a key read from `backend/config.py`. Any exception comes back as `{"error": "..."}`.

## Tech Stack

- **Mobile:** Flutter / Dart (SDK ^3.7.0), `http`, `image_picker`, `pdf`, `path_provider`, `open_file`, `shared_preferences`, `intl`
- **Backend:** Python, FastAPI, joblib, PyTorch and torchvision, Pillow, `google-generativeai`
- **Models:** scikit-learn crop classifier (pickle), EfficientNet-B0 disease classifier (PyTorch weights)
- **Fonts:** Noto Sans Tamil (regular and bold) for the PDF reports

## Getting Started

### Prerequisites

- Flutter SDK (Dart ^3.7.0) and an Android emulator or device
- Python 3 for the backend
- A Gemini API key from Google AI Studio

### Backend

The repo's requirements file (`Crop APP/backend/requirment.text`) is a misspelled name and is not a standard `requirements.txt`. Going by the imports in `main.py`, you need:

```bash
git clone https://github.com/Danushika06/smart-farming.git
cd "smart-farming/Crop APP/backend"
pip install fastapi uvicorn joblib scikit-learn torch torchvision pillow google-generativeai python-multipart
```

Before running, three things must change:

1. Put your own key in `config.py` as `GEMINI_API_KEY` (better: read it from an environment variable). A key is currently committed in this file and should be treated as exposed.
2. Replace the two absolute model paths in `main.py` (`E:\New folder\backup app\backend\models\...`) with paths to the files in `backend/models/`.
3. Check that `gemini-1.5-pro-latest` is still offered by the API; older Gemini model names have been retired, so you may need to change it.

The code does not start a server itself, and the app expects port 8980, so run:

```bash
uvicorn main:app --host 0.0.0.0 --port 8980
```

### Mobile app

```bash
cd "smart-farming/Crop APP/frontend mobile app"
flutter pub get
flutter run
```

Set the server address first. `crop_recommendation_screen.dart` uses `http://10.0.2.2:8980` (the Android emulator's route to the host machine), while `disease_detection_screen.dart` uses a fixed LAN address, `http://192.168.248.134:8980`. Change both `baseUrl` values to your backend. A prebuilt `Crop APP/crop app.apk` is also committed; it was built against whatever addresses were set at the time, so it will only work if the backend is reachable at those addresses.

## Usage

Backend endpoints:

| Method | Route | Input | Output |
|---|---|---|---|
| GET | `/` | none | `{"message": "FastAPI backend is running!"}` |
| POST | `/recommend-crop/` | JSON: `N`, `P`, `K`, `temperature`, `humidity`, `ph`, `rainfall`, `location`, `area`, optional `language` (`ta` for Tamil) | `crop`, `gemini_insights` |
| POST | `/detect-disease/` | multipart: `image` file, `language` form field | `disease`, `gemini_insights` |

Using the app: choose a language and tap Login, then open Crop Recommendation (enter location and area, tap Get Recommendation) or Disease Detection (take or choose a photo). When the result appears, a Download Report button opens the generated PDF.

## Project Structure

```
smart-farming/
└── Crop APP/
    ├── backend/
    │   ├── main.py                 # FastAPI app, model loading, Gemini prompts, 2 POST routes
    │   ├── config.py               # Gemini API key (committed, should be removed)
    │   ├── requirment.text         # dependency list (misspelled name)
    │   └── models/
    │       ├── crop_recommendation_model.pkl
    │       └── plant_disease_model.pth
    ├── frontend mobile app/        # Flutter project
    │   ├── lib/
    │   │   ├── main.dart                       # app entry, starts at the login screen
    │   │   ├── login_screen.dart               # language picker, no real authentication
    │   │   ├── home_screen.dart                # two-button dashboard
    │   │   ├── crop_recommendation_screen.dart # random sensor data + crop API call
    │   │   ├── disease_detection_screen.dart   # camera/gallery + disease API call
    │   │   └── pdf_report.dart                 # PDF generation in English/Tamil
    │   ├── assets/fonts/           # Noto Sans Tamil
    │   ├── pubspec.yaml
    │   └── android/ ios/ web/ windows/ linux/ macos/   # generated Flutter platform folders
    ├── crop app.apk                # prebuilt Android build
    └── project report .docx        # written report
```

---

## Contact

<table>
  <tr><td><b>GitHub:</b> <a href="https://github.com/Danushika06">Danushika06</a></td><td><b>LinkedIn:</b> <a href="https://www.linkedin.com/in/danushika-n-323b4628b/">danushika-n</a></td></tr>
  <tr><td colspan="2" align="center"><b>Email:</b> <a href="mailto:danushikanagarajan@gmail.com">danushikanagarajan@gmail.com</a></td></tr>
</table>

Built by **Danushika N**
