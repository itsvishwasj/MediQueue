# MediQueue: AI-Powered Symptom Triage & Smart Travel Logistics (Hackathon Project)

**MediQueue** is a full-stack healthcare ecosystem designed to eliminate hospital overcrowding and streamline the patient experience. By leveraging **Google Gemini AI** for intelligent symptom triage and integrating an **Open-Source Smart Travel Engine**, MediQueue ensures patients get to the right specialist exactly when it is their turn.

## 🚀 Key Features

* **AI-Driven Triage:** An interactive symptom checker powered by Gemini AI that asks follow-up questions to accurately recommend the correct hospital department.
* **📍 Smart Travel Engine (Virtual Waiting Room):** Integrates the **OSRM (Open Source Routing Machine) API** to calculate real-time driving ETAs from the patient's live GPS location, alerting them exactly when to leave for the hospital.
* **🗺️ Frictionless Onboarding:** Uses **OpenStreetMap (Nominatim API)** on the Admin portal to automatically geocode hospital addresses into precise Latitude/Longitude coordinates via live search.
* **Live Queue Monitoring:** Real-time, socket-driven visibility into current wait times and queue positions.
* **Voice-Enabled Input:** Integrated Speech-to-Text for a hands-free, accessible symptom description experience.

---

## 🏗️ Project Structure

The project is deployed across a three-tier architecture:

```text
MediQueue/
├── medi_queue_app/       # Flutter Mobile Application (iOS/Android)
├── mediqueue-backend/    # Node.js & Express API
└── mediqueue-admin/      # Vanilla JS/React Admin Dashboard
```

---

## 🛠️ Tech Stack

* **Frontend:** Flutter (Mobile App), HTML/Vanilla JS (Admin Portal).
* **Backend:** Node.js, Express.js.
* **Database:** MongoDB Atlas (Cloud).
* **AI Engine:** Google Gemini API (NLP & Intent Recognition).
* **Mapping & Logistics:** OpenStreetMap (Nominatim) for Geocoding, OSRM for dynamic distance/ETA calculations.
* **Deployment:** Render (Backend), Netlify (Admin UI).

---

## ⚙️ Installation & Setup

### 1. Backend (Node.js)
```bash
cd mediqueue-backend
npm install
# Create a .env file and add:
# PORT=10000
# MONGO_URI=your_mongodb_connection_string
# GEMINI_API_KEY=your_google_ai_key
npm start
```

### 2. Admin Portal (Frontend)
```bash
cd mediqueue-admin
# If using a bundler like Vite:
npm install
npm run dev
# If using plain HTML, simply launch index.html via Live Server
```

### 3. Mobile App (Flutter)
Ensure you have the Flutter SDK installed.
```bash
cd medi_queue_app
flutter pub get
# Connect a device or emulator
flutter run
```

---

## 📋 How It Works (The Patient Flow)

1.  **AI Triage:** The patient describes their symptoms (text/voice). Gemini AI analyzes the input and recommends a specialized medical department.
2.  **Geospatial Discovery:** The app fetches the user's live GPS location and displays nearby hospitals with the required department, sorted by wait time and distance.
3.  **Smart Travel Routing:** The patient joins the digital queue from home. The OSRM engine continuously calculates travel time against queue time, notifying the patient precisely when to depart.
4.  **QR Check-In:** Upon arrival, the patient scans the hospital's Reception QR code, instantly syncing their physical presence with the Doctor's Live Dashboard.

---

## 📱 Screenshots & Demo

| Feature | Link |
| :--- | :--- |
| **Live Backend API** | [https://mediqueue-backend-el5a.onrender.com](https://mediqueue-backend-el5a.onrender.com) |
| **Admin Dashboard** | [https://mediqueue-admin-portal.netlify.app](https://mediqueue-admin-portal.netlify.app) |
| **GitHub Profile** | [itsvishwasj](https://github.com/itsvishwasj) |

---

## 📄 License
Developed for Hackverse 2026. Open-source under the MIT License.
