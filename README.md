# Dravidian Learn — Intelligent Tutoring System (ITS)

A multi-platform Tamil and Telugu language learning application built with **Flutter** (frontend) and **FastAPI** (backend), using **Supabase** for authentication and PostgreSQL storage.

## 📋 Overview

Dravidian Learn includes:
- **Learner Mode** for children and beginners
- **Parent/Adult Dashboard** for monitoring learner progress
- **Adaptive learning** with skill mastery tracking
- **Cross-platform support**: iOS, Android, Web, macOS, Windows, Linux
- **Onboarding flow** with language, goal, style, and accessibility preferences
- **Accessible experience** with audio-forward learning and high contrast support

---

## 📁 Repository Structure

```text
drav2/
├── drav/
│   ├── backend/                      # FastAPI backend
│   │   ├── main.py                   # Application entry point
│   │   ├── requirements.txt          # Python dependencies
│   │   ├── .env.example              # Backend environment template
│   │   ├── .env                      # Local backend environment (DO NOT COMMIT)
│   │   └── sql_migration_profiles.sql # Supabase/PostgreSQL migration script
│   │
│   ├── dravidian_flutter/            # Flutter frontend app
│   │   ├── lib/
│   │   │   ├── main.dart
│   │   │   ├── theme.dart
│   │   │   ├── screens/
│   │   │   ├── services/
│   │   │   ├── models/
│   │   │   ├── widgets/
│   │   │   └── quiz/
│   │   ├── pubspec.yaml              # Flutter dependencies
│   │   ├── .env.example              # Frontend environment template
│   │   └── .env                      # Local frontend environment (DO NOT COMMIT)
│   │
│   └── assets/
│       └── data/                     # Offline language data
│           ├── tamil.json
│           ├── telugu.json
│           ├── telugu_greetings.json
│           └── telugu_vowels.json
├── .gitignore
└── README.md
```

---

## 🚀 Quick Start

### Prerequisites
- Python 3.9+
- Flutter 3.0+
- Supabase account
- Git

### 1. Supabase Setup

1. Create a Supabase project at https://supabase.com
2. Copy the generated Project URL and Anon Key
3. Run the SQL migration script in Supabase SQL Editor:
   ```sql
   -- Use the contents of drav/backend/sql_migration_profiles.sql
   ```

### 2. Backend Setup

```bash
cd drav/backend
cp .env.example .env
# Add your Supabase credentials to .env
pip install -r requirements.txt
python main.py
```

Open http://localhost:8000/docs to verify the API docs.

### 3. Flutter Frontend Setup

```bash
cd drav/dravidian_flutter
cp .env.example .env
# Add your Supabase and backend values to .env
flutter pub get
flutter run -d chrome
```

To launch on Android emulator:
```bash
flutter run -d emulator-5554
```

---

## 🔐 Environment Variables

### Backend (`drav/backend/.env`)
```bash
SUPABASE_URL=https://your-project.supabase.co
SUPABASE_ANON_KEY=your-anon-key-here
```

### Frontend (`drav/dravidian_flutter/.env`)
```bash
SUPABASE_URL=https://your-project.supabase.co
SUPABASE_ANON_KEY=your-anon-key-here
BACKEND_URL=http://127.0.0.1:8000
```

> Do not commit `.env` files. Use the `.env.example` templates instead.

---

## 📝 Notes

- Learner roles include child and adult/parent.
- The onboarding flow captures language, goals, learning style, and accessibility options.
- The backend uses Supabase Auth and PostgreSQL for profile and progress data.

---

## 📝 License

See `LICENSE` for project licensing details.
