---

# MediQueue: AI-Powered Symptom Triage & Live Queue Management (Hackathon Project)

**MediQueue** is a full-stack healthcare solution designed to reduce hospital overcrowding and streamline the patient experience. By leveraging **Google Gemini AI** for intelligent symptom triage and providing **Real-time Queue Status**, MediQueue ensures patients get to the right specialist without the wait.

---

## 🚀 Key Features

* **AI-Driven Triage:** An interactive symptom checker powered by Gemini AI that asks follow-up questions to recommend the correct hospital department.
* **Live Queue Monitoring:** Real-time visibility into current wait times and queue positions for different hospital departments.
* **Admin Dashboard:** A centralized portal for hospital staff to manage appointments, update queue statuses, and view patient triage data.
* **Smart Travel Integration:** (Planned) Built-in travel planning and expense splitting for patients traveling from rural areas.
* **Voice-Enabled Input:** Integrated Speech-to-Text for a hands-free symptom description experience.

---

## 🏗️ Project Structure

The project is divided into three main components:

```text
MediQueue/
├── medi_queue_app/       # Flutter Mobile Application (iOS/Android)
├── mediqueue-backend/    # Node.js & Express API
└── mediqueue-admin/      # React/Vite Admin Dashboard
```

---

## 🛠️ Tech Stack

* **Frontend:** Flutter (Mobile), React.js (Admin Portal).
* **Backend:** Node.js, Express.js.
* **Database:** MongoDB Atlas (Cloud).
* **AI Engine:** Google Gemini API.
* **Deployment:** Render (Backend), Netlify (Admin), GitHub (Source Control).

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

### 2. Admin Portal (React)
```bash
cd mediqueue-admin
npm install
npm run dev
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

## 📋 How It Works

1.  **Patient Input:** The patient enters symptoms via text or voice in the Flutter app.
2.  **AI Analysis:** The Gemini-powered backend analyzes the input, asks clarifying questions, and recommends a specific department (e.g., Cardiology, ENT).
3.  **Booking:** The patient views the **Live Queue** and books a slot.
4.  **Hospital Management:** Hospital staff receive the booking on the **Admin Portal** and manage the patient's flow in real-time.

---

## 📱 Screenshots & Demo

| Feature | Link |
| :--- | :--- |
| **Live Backend API** | [https://mediqueue-backend-el5a.onrender.com](https://mediqueue-backend-el5a.onrender.com) |
| **Admin Dashboard** | [https://mediqueue-admin-portal.netlify.app](https://mediqueue-admin-portal.netlify.app) |
| **GitHub Profile** | [itsvishwasj](https://github.com/itsvishwasj) |

---

## 📄 License
This project was developed for a hackathon and is open-source under the MIT License.
