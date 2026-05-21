# Dravidian Learn — Intelligent Tutoring System (ITS)

A modern multi-platform language learning application for Tamil and Telugu with AI-driven personalized lesson sequencing, built with **Flutter** (frontend) and **FastAPI** (backend), backed by **Supabase** PostgreSQL and authentication.

## 📋 Overview

Dravidian Learn provides:
- **Child/Learner Mode**: Age-appropriate lessons, progress tracking, and personalized exercises
- **Parent/Adult Dashboard**: Monitor child progress and learning analytics
- **Intelligent Tutoring System (ITS)**: Rule-based skill mastery scoring and adaptive exercise selection
- **Multi-Platform**: iOS, Android, Web, macOS, Windows, Linux
- **Onboarding Flow**: 4-step preference collection (language, goal, style, accessibility)
- **Accessibility First**: Support for larger text, audio-first learning, reduced animations, high contrast mode

---

## 🏗️ Architecture

```
┌─────────────────────────────────────────────────────────────┐
│                    Dravidian Learn                          │
├─────────────────────────────────────────────────────────────┤
│  Frontend (Flutter)          │       Backend (FastAPI)      │
│  ─────────────────────────── │       ─────────────────────  │
│  • Signup / Login             │  • /auth/register           │
│  • Onboarding (4 steps)       │  • /auth/sync               │
│  • Home Dashboard             │  • /exercises/next (ITS)    │
│  • Lessons & Quizzes          │  • /exercises/submit        │
│  • Progress Tracking          │  • /progress/{user_id}      │
│                               │                             │
│  HTTP / REST API              │  Supabase Postgre SQL       │
└─────────────────────────────────────────────────────────────┘
         ↓
    Supabase (Auth + Database)
    ├── auth.users (Supabase Auth)
    ├── profiles (user preferences, onboarding status)
    ├── skills (language skills hierarchy)
    ├── exercises (skill-specific exercises)
    ├── skill_mastery (user progress tracking)
    ├── sessions (user learning sessions)
    └── session_events (exercise submissions & analytics)
```

---

## 📁 Project Structure

```
drav2/
├── drav/
│   ├── backend/                      # FastAPI backend
│   │   ├── main.py                   # Entry point, all endpoints
│   │   ├── requirements.txt          # Python dependencies
│   │   ├── .env.example              # Environment template
│   │   ├── .env                      # Local env vars (DO NOT COMMIT)
│   │   └── sql_migration_profiles.sql # PostgreSQL setup
│   │
│   ├── dravidian_flutter/            # Flutter app
│   │   ├── lib/
│   │   │   ├── main.dart             # Entry point, routing
│   │   │   ├── theme.dart            # Design system
│   │   │   ├── screens/
│   │   │   │   ├── signup_screen.dart
│   │   │   │   ├── onboarding_screen.dart (4-step flow)
│   │   │   │   ├── login_screen.dart
│   │   │   │   ├── home_screen.dart
│   │   │   │   ├── lesson_screen.dart
│   │   │   │   ├── quiz_screen.dart
│   │   │   │   ├── result_screen.dart
│   │   │   │   └── adult_dashboard_screen.dart
│   │   │   ├── services/
│   │   │   │   ├── auth_service.dart
│   │   │   │   ├── api_service.dart
│   │   │   │   └── mock_exercises.dart
│   │   │   ├── models/
│   │   │   ├── widgets/
│   │   │   └── quiz/
│   │   ├── pubspec.yaml              # Flutter dependencies
│   │   ├── .env.example              # Environment template
│   │   └── .env                      # Local env vars (DO NOT COMMIT)
│   │
│   └── assets/
│       └── data/                     # JSON language data
│           ├── tamil.json
│           ├── telugu.json
│           ├── telugu_greetings.json
│           └── telugu_vowels.json
│
├── .gitignore
└── README.md (this file)
```

---

## 🚀 Quick Start

### Prerequisites
- **Python 3.9+** (backend)
- **Flutter 3.0+** (frontend)
- **Supabase Account** (free tier: https://supabase.com)
- **Git**

### 1. Supabase Setup

#### Create a Supabase Project
1. Go to [supabase.com](https://supabase.com)
2. Create a new project (save your **Project URL** and **Anon Key**)
3. Copy the SQL migration script and run it in the Supabase SQL Editor:
   ```sql
   -- Copy entire contents of: drav/backend/sql_migration_profiles.sql
   ```
   This creates the `profiles` table and auth trigger.

#### Get Your Credentials
- **SUPABASE_URL**: From Project Settings → API → Project URL
- **SUPABASE_ANON_KEY**: From Project Settings → API → Anon key

---

### 2. Backend Setup

```bash
cd drav/backend

# Create .env file
cp .env.example .env

# Edit .env and add your Supabase credentials
# SUPABASE_URL=https://your-project.supabase.co
# SUPABASE_ANON_KEY=your-anon-key-here

# Install dependencies
pip install -r requirements.txt

# Run the server (default: http://localhost:8000)
python main.py
```

**Verify**: Open http://localhost:8000/docs → Interactive API documentation

---

### 3. Flutter Setup

```bash
cd drav/dravidian_flutter

# Create .env file
cp .env.example .env

# Edit .env and add your configuration
# SUPABASE_URL=https://your-project.supabase.co
# SUPABASE_ANON_KEY=your-anon-key-here
# BACKEND_URL=http://127.0.0.1:8000

# Get dependencies
flutter pub get

# Run on Chrome (web development)
flutter run -d chrome

# Or run on mobile emulator
flutter run -d emulator-5554  # Android
flutter run -d ios            # iOS (macOS only)
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

**⚠️ IMPORTANT**: Never commit `.env` files. Use `.env.example` templates for sharing.

---

## 📱 User Flows

### Child Registration & Onboarding
1. **Signup Screen**: Username, email, password, role selection (child/adult)
2. **Backend**: Creates Supabase Auth user with metadata
3. **Postgres Trigger**: Auto-creates `profiles` row with defaults
4. **Onboarding Screen (4 Steps)**:
   - Step 1: Select learning language (Telugu / Tamil)
   - Step 2: Set learning goal (daily conversation, travel, school, etc.)
   - Step 3: Choose learning style (beginner, child, traveler, accessibility)
   - Step 4: Accessibility preferences (larger text, audio-first, etc.)
5. **Final**: Save preferences to `profiles` → Route to home dashboard

### Learning Flow
1. **Home Dashboard**: View progress, active skills
2. **Lesson**: Study content, practice exercises
3. **Quiz**: Answer skill-specific questions
4. **Results**: View score, receive feedback
5. **Progress Tracking**: Mastery score updated in database

### Parent/Adult Dashboard
- View all child profiles
- Monitor progress per skill
- See average mastery scores
- Track learning sessions

---

-
---

## 🧠 ITS Algorithm

The Intelligent Tutoring System selects the next exercise based on:

1. **Get all skills** for the selected language
2. **Retrieve user mastery scores** for each skill
3. **Find target skill**: First skill with mastery < 0.8
   - If all skills are ≥ 0.8, pick the lowest-scoring skill (review mode)
4. **Select random exercise** from target skill's exercises
5. **Update mastery after submission**:
   - Correct: +0.1 (clamped to 1.0)
   - Wrong: -0.05 (clamped to 0.0)

---


## 📚 Key Technologies

| Component | Technology | Version |
|-----------|-----------|---------|
| Frontend | Flutter | 3.0+ |
| Backend | FastAPI | 0.100+ |
| Database | PostgreSQL (Supabase) | 14+ |
| Auth | Supabase Auth | Latest |
| HTTP Client | http (Dart) | 1.2.0+ |
| State Mgmt | Provider | 6.1.2+ |

---

## 📝 License

This project is part of the Dravidian Learn initiative. See LICENSE file for details.

---
