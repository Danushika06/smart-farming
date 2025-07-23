from fastapi import FastAPI, UploadFile, File, Form
from fastapi.middleware.cors import CORSMiddleware  # ✅ Import CORS Middleware
import joblib
import torch
from torchvision import models, transforms
from PIL import Image
import google.generativeai as genai
import config
import json
import re  # Import re for text cleaning

# ✅ Initialize FastAPI
app = FastAPI()

# ✅ Enable CORS (Allow all origins, methods, headers for testing)
app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],  # In production, replace "*" with specific frontend URLs
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)

# ✅ Load Crop Recommendation Model
crop_model = joblib.load(r"E:\New folder\backup app\backend\models\crop_recommendation_model.pkl")

# ✅ Load Plant Disease Detection Model
disease_model = models.efficientnet_b0(weights=None)
disease_model.classifier[1] = torch.nn.Linear(disease_model.classifier[1].in_features, 19)
disease_model.load_state_dict(torch.load(r"E:\New folder\backup app\backend\models\plant_disease_model.pth", map_location="cpu"))
disease_model.eval()

# ✅ Define Disease Classes
disease_classes = [
    "Bacterial Blight in Rice", "Flag Smut", "Gray Leaf Spot", "Healthy Maize", "Healthy Wheat", 
    "Maize Ear Rot", "Maize Fall Armyworm", "Maize Stem Borer", "Rice Blast", "Tungro", 
    "Wheat Aphid", "Wheat Black Rust", "Wheat Brown Leaf Rust", "Wheat Leaf Blight", 
    "Wheat Mite", "Wheat Powdery Mildew", "Wheat Scab", "Wheat Stem Fly", "Wheat Yellow Rust"
]

# ✅ Initialize Gemini API
genai.configure(api_key=config.GEMINI_API_KEY)
gemini_model = genai.GenerativeModel("gemini-1.5-pro-latest")  # Recommended latest stable version


# ✅ Function to clean and format Gemini response
def clean_gemini_response(response_text):
    cleaned_text = re.sub(r"[\*\#]+", "", response_text).strip()
    lines = cleaned_text.split("\n")
    pesticides = [line for line in lines if "pesticide" in line.lower()]
    
    if len(pesticides) > 3:
        pesticides = pesticides[:3]

    formatted_lines = []
    pesticide_count = 1

    for line in lines:
        if line.lower().startswith(("remedy", "fertilizer", "tips", "water", "crop duration", "best pesticide")):
            formatted_lines.append(f"{line.split(':')[0].strip()}: {line.split(':', 1)[1].strip()}")
        elif line in pesticides:
            formatted_lines.append(f"{pesticide_count}) {line.strip()}")
            pesticide_count += 1
        else:
            formatted_lines.append(line.strip())

    return "\n".join(formatted_lines).strip()

# ✅ 1️⃣ Crop Recommendation API
@app.post("/recommend-crop/")
async def recommend_crop(data: dict):
    try:
        features = [[data["N"], data["P"], data["K"], data["temperature"], data["humidity"], data["ph"], data["rainfall"]]]
        predicted_crop = crop_model.predict(features)[0]

        if predicted_crop.lower() == "healthy":
            return {"crop": "Healthy", "gemini_insights": "Crop is healthy. No additional recommendations needed."}

        language = "Tamil" if data.get("language") == "ta" else "English"

        gemini_prompt = f"""
        Given the soil conditions (N={data["N"]}, P={data["P"]}, K={data["K"]}), temperature={data["temperature"]}, humidity={data["humidity"]}, pH={data["ph"]}, and rainfall={data["rainfall"]} 
        for {data["location"]} with {data["area"]} acres of land, provide a short response in {language} with points covering:
        - Crop Duration for {predicted_crop}  
        - Water Required (in liters per crop and total for input acres)
        - Recommended Fertilizer (with name)
        Do not use ## or *** in the response.
        """

        gemini_response = gemini_model.generate_content(gemini_prompt)

        return {
            "crop": predicted_crop,
            "gemini_insights": clean_gemini_response(gemini_response.text)
        }
    
    except Exception as e:
        return {"error": str(e)}

# ✅ 2️⃣ Plant Disease Detection API
@app.post("/detect-disease/")
async def detect_disease(image: UploadFile = File(...), language: str = Form("en")):
    try:
        img = Image.open(image.file).convert("RGB")
        transform = transforms.Compose([transforms.Resize((224, 224)), transforms.ToTensor()])
        img_tensor = transform(img).unsqueeze(0)

        with torch.no_grad():
            outputs = disease_model(img_tensor)
            _, predicted = outputs.max(1)

        detected_disease = disease_classes[predicted.item()]

        if "healthy" in detected_disease.lower():
            return {"disease": "Healthy", "gemini_insights": "Plant is healthy. No issues detected."}

        language = "Tamil even the pesticides names" if language == "ta" else "English"

        gemini_prompt = f"""
        Provide a short summary in {language} for {detected_disease} including:
        - Top 3 Pesticides (List only the 3 best)  
        - Best Pesticide (Explain its application and use case)  
        - Prevention Tips  
        Do not use ## or *** in the response. Format pesticides as 1), 2), 3).
        """

        gemini_response = gemini_model.generate_content(gemini_prompt)

        return {
            "disease": detected_disease,
            "gemini_insights": clean_gemini_response(gemini_response.text)
        }
    
    except Exception as e:
        return {"error": str(e)}

# ✅ 3️⃣ Health Check API (To test if API is running)
@app.get("/")
async def root():
    return {"message": "FastAPI backend is running!"}
