# 💰 Investment Tracker App

A comprehensive investment tracking application built with Flutter to track Mutual Funds, Digital Gold, and Physical Gold with XIRR calculations.

## 📱 Features

- **Mutual Fund Tracking** - Track all your MF investments across platforms (Zerodha, Groww, etc.)
- **Digital Gold Tracking** - Monitor digital gold from Gullak, Jar, PhonePe, Paytm
- **Physical Gold Tracking** - Track jewellery, coins, bars with accurate XIRR
- **Smart Input Methods** - Voice, Text, and Bill/OCR scanning
- **Live Data** - Real-time NAV updates and gold prices
- **Offline-First** - Works without internet, syncs when available
- **Privacy-Focused** - Local-first storage, no mandatory cloud sync

## 🚀 Getting Started

### Prerequisites

- Flutter 3.38.7 or higher
- Dart 3.10.7 or higher
- Android Studio (for Android development)
- Xcode (for iOS development - macOS only)

### Installation

1. **Clone the repository**
   ```bash
   git clone <repository-url>
   cd investment-tracker-app
   ```

2. **Install dependencies**
   ```bash
   flutter pub get
   ```

3. **Run the app**
   ```bash
   flutter run
   ```

## 📁 Project Structure

```
lib/
├── main.dart                 # App entry point
├── models/                   # Data models
├── screens/                  # UI screens
│   └── home_screen.dart     # Main dashboard
├── widgets/                  # Reusable widgets
├── services/                 # API & business logic
├── providers/                # State management (Provider)
├── database/                 # SQLite database helpers
└── utils/                    # Utilities & constants
    └── app_theme.dart       # App theme & colors

assets/
├── images/                   # Image assets
└── icons/                    # App icons
```

## 🎨 Tech Stack

- **Framework:** Flutter 3.38.7
- **Language:** Dart 3.10.7
- **State Management:** Provider
- **Local Database:** sqflite + Hive
- **Backend:** Python FastAPI (for CAS parsing, NAV updates)
- **OCR:** Google ML Kit
- **Voice Input:** speech_to_text
- **Charts:** fl_chart

## 📋 Development Progress

See [PROJECT_PLAN.md](PROJECT_PLAN.md) for detailed step-by-step development plan.

**Current Phase:** Phase 1 - Foundation & Core Features  
**Status:** ✅ Step 1 Complete - Project Setup

## 🔧 Building for Production

### Android
```bash
flutter build apk --release
# or for app bundle
flutter build appbundle --release
```

### iOS
```bash
flutter build ios --release
```

## 📄 License

Private project - Not licensed for public use

## 👨‍💻 Developer

Built with ❤️ for personal investment tracking

---

**Note:** This is an active development project. Features are being added incrementally.
