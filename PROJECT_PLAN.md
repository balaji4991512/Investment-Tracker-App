# Investment Tracker App - Step-by-Step Plan

**Project Start Date:** January 24, 2026  
**Target Platform:** Android first, iOS capable (Flutter)  
**Architecture:** Local-first, offline-capable, cross-platform ready

---

## 🎯 Project Goals

- Track Mutual Funds from all platforms (Zerodha, Groww, etc.)
- Track Digital Gold (Gullak, Jar, PhonePe, Paytm, etc.)
- Track Physical Gold with XIRR calculations
- Support Voice, Text, and Bill/OCR inputs
- Daily usage focused - simple, fast, reliable

---

## 📐 Technical Stack

- **Frontend:** Flutter (Dart)
- **Database:** sqflite (local SQLite) + Hive (fast key-value storage)
- **State Management:** Riverpod or Provider
- **Backend:** Python FastAPI (for CAS parsing, NAV updates)
- **AI/ML:** Google ML Kit (OCR via flutter_mlkit), speech_to_text plugin
- **Data Sources:** AMFI (NAV), Gold Price APIs

---

## 🗂️ Phase 1: Foundation & Core Features (Weeks 1-2)

### Step 1: Project Setup
- [x] 1.1 Create Flutter project (flutter create)
- [x] 1.2 Setup project structure (Clean Architecture / Feature-first)
- [x] 1.3 Add dependencies (sqflite, provider/riverpod, http, intl)
- [x] 1.4 Setup version control (Git)
- [x] 1.5 Create basic app theme and design system (Material 3)

### Step 2: Database Design & Implementation
- [ ] 2.1 Design database schema
  - Users table
  - Investments table (parent)
  - MutualFunds table
  - DigitalGold table
  - PhysicalGold table
  - Transactions table (for SIPs, multiple purchases)
- [ ] 2.2 Create data models (Dart classes with JSON serialization)
- [ ] 2.3 Implement database helper (sqflite)
- [ ] 2.4 Create Repository layer
- [ ] 2.5 Write sample data for testing

### Step 3: Home Screen & Portfolio Overview
- [x] 3.1 Design Home Screen UI (Figma/sketch)
- [x] 3.2 Implement Home Screen Flutter UI
  - Total Net Worth card
  - Today's change indicator
  - Category breakdown (MF, Digital Gold, Physical Gold)
  - Quick action buttons (FloatingActionButton)
- [ ] 3.3 Create Provider/Riverpod state with dummy data
- [ ] 3.4 Connect to sqflite database
- [ ] 3.5 Implement pull-to-refresh (RefreshIndicator)
- [ ] 3.5 Implement pull-to-refresh (RefreshIndicator)

### Step 4: Manual Entry - Mutual Funds
- [ ] 4.1 Design Add MF screen
- [ ] 4.2 Create input form
  - Scheme name (searchable dropdown later)
  - Folio number
  - Investment type (SIP/Lumpsum)
  - Date picker
  - Amount
  - Units (optional)
  - Current NAV (optional)
- [ ] 4.3 Implement validation
- [ ] 4.4 Save to database
- [ ] 4.5 Display MF list screen
- [ ] 4.6 Edit/Delete functionality

### Step 5: Manual Entry - Digital Gold
- [ ] 5.1 Design Add Digital Gold screen
- [ ] 5.2 Create input form
  - Platform (dropdown: Gullak, Jar, PhonePe, Paytm, etc.)
  - Date picker
  - Amount invested
  - Grams purchased
  - Purchase rate per gram
- [ ] 5.3 Implement validation
- [ ] 5.4 Save to database
- [ ] 5.5 Display Digital Gold list screen
- [ ] 5.6 Edit/Delete functionality

### Step 6: Manual Entry - Physical Gold
- [ ] 6.1 Design Add Physical Gold screen
- [ ] 6.2 Create comprehensive input form
  - Item type (jewellery, coin, bar)
  - Date of purchase
  - Weight (grams)
  - Purity (24k, 22k, 18k)
  - Purchase rate per gram
  - Making charges
  - Total amount paid
  - Store name (optional)
  - Photo upload (optional)
- [ ] 6.3 Implement validation
- [ ] 6.4 Calculate investment value vs total value
- [ ] 6.5 Save to database
- [ ] 6.6 Display Physical Gold list screen
- [ ] 6.7 Edit/Delete functionality

### Step 7: XIRR Calculation Engine
- [ ] 7.1 Research XIRR algorithm (Newton-Raphson method)
- [ ] 7.2 Implement XIRR calculation function
- [ ] 7.3 Handle edge cases
  - Single transaction (absolute return)
  - Multiple cash flows (SIPs)
  - Ongoing investments (use current date as exit)
- [ ] 7.4 Unit tests for XIRR
- [ ] 7.5 Integrate with portfolio display

### Step 8: Current Value Calculations
- [ ] 8.1 MF current value
  - Units × Current NAV
  - Store NAV with timestamp
- [ ] 8.2 Digital Gold current value
  - Grams × Current gold rate
- [ ] 8.3 Physical Gold current value
  - (Grams × Current rate) - Making charges
  - Show recoverable value
- [ ] 8.4 Calculate absolute returns
- [ ] 8.5 Calculate percentage returns
- [ ] 8.6 Display on home screen

---

## 🎤 Phase 2: Smart Input Features (Week 3)

### Step 9: Voice Input Integration
- [ ] 9.1 Add speech_to_text package and permissions (Android/iOS)
- [ ] 9.2 Create voice input UI component (floating mic button)
- [ ] 9.3 Implement speech-to-text (works on both platforms)
- [ ] 9.4 Parse voice commands
  - "I bought 10 grams of gold on March 15 2025 for 60000 rupees"
  - "Invested 5000 in HDFC Midcap fund today"
- [ ] 9.5 Create AI parser (simple NLP or LLM API)
- [ ] 9.6 Pre-fill forms from voice input
- [ ] 9.7 Confirmation screen before saving
- [ ] 9.8 Handle errors gracefully

### Step 10: Bill/Receipt OCR
- [ ] 10.1 Add image_picker package and camera permissions
- [ ] 10.2 Implement camera capture UI (or use image_picker)
- [ ] 10.3 Integrate Google ML Kit (google_mlkit_text_recognition)
- [ ] 10.4 Create OCR processing pipeline
  - Detect text from image
  - Extract key information (date, amount, weight, purity)
  - Pattern matching for common bill formats
- [ ] 10.5 Display extracted data for verification
- [ ] 10.6 Manual correction interface
- [ ] 10.7 Save bill image to local storage
- [ ] 10.8 Link image to investment record

### Step 11: Smart Parsing & AI
- [ ] 11.1 Setup local or cloud-based LLM
- [ ] 11.2 Create prompts for data extraction
- [ ] 11.3 Parse unstructured text → structured data
- [ ] 11.4 Handle Indian formats
  - ₹ vs Rs
  - Date formats (DD/MM/YYYY)
  - Lakhs, Crores
- [ ] 11.5 Confidence scoring
- [ ] 11.6 Fallback to manual entry if low confidence

---

## 📊 Phase 3: Live Data Integration (Week 4)

### Step 12: Gold Price API Integration
- [ ] 12.1 Research Indian gold price APIs
  - GoodReturns
  - IBJA
  - MMTC
  - Fallback: web scraping
- [ ] 12.2 Create backend API endpoint (FastAPI)
- [ ] 12.3 Implement daily price fetch
- [ ] 12.4 Store historical prices in DB
- [ ] 12.5 Update UI with live prices
- [ ] 12.6 Show 24k and 22k rates separately
- [ ] 12.7 Display last updated timestamp
- [ ] 12.8 Offline fallback (use last known price)

### Step 13: Mutual Fund NAV Updates
- [ ] 13.1 Download AMFI NAV data (daily CSV)
- [ ] 13.2 Parse NAV file
- [ ] 13.3 Match scheme names (fuzzy matching)
- [ ] 13.4 Update NAVs in database
- [ ] 13.5 Background job (daily at 9 PM)
- [ ] 13.6 Show NAV date in UI
- [ ] 13.7 Manual refresh option
- [ ] 13.8 Handle scheme mergers/closures

### Step 14: CAS (Consolidated Account Statement) Upload
- [ ] 14.1 Design CAS upload screen
- [ ] 14.2 PDF picker from file system
- [ ] 14.3 Backend: PDF password handling (PAN/DOB)
- [ ] 14.4 Parse CAMS format
- [ ] 14.5 Parse KFintech format
- [ ] 14.6 Extract:
  - Folio numbers
  - Scheme names
  - Units held
  - Transactions history
- [ ] 14.7 Import to database
- [ ] 14.8 Detect duplicates
- [ ] 14.9 Show import summary
- [ ] 14.10 Periodic refresh prompt

### Step 15: Background Sync & Jobs
- [ ] 15.1 Setup workmanager (Flutter plugin for background tasks)
- [ ] 15.2 Daily NAV update job
- [ ] 15.3 Daily gold price update job
- [ ] 15.4 Weekly CAS refresh reminder
- [ ] 15.5 Notification for significant changes (flutter_local_notifications)
- [ ] 15.6 Battery optimization handling

---

## 🎨 Phase 4: Polish & Enhancement (Week 5)

### Step 16: Detailed Views & Analytics
- [ ] 16.1 Investment detail screen (drill-down)
- [ ] 16.2 Transaction history per investment
- [ ] 16.3 Charts & Graphs (fl_chart or syncfusion_flutter_charts)
  - Portfolio allocation pie chart
  - Returns over time (line chart)
  - Category-wise performance bar chart
- [ ] 16.4 Filters & Sorting
  - By date
  - By returns
  - By category
- [ ] 16.5 Search functionality

### Step 17: Reports & Export
- [ ] 17.1 Generate PDF report
  - Portfolio summary
  - Category breakdown
  - Individual holdings
- [ ] 17.2 Export to Excel/CSV
- [ ] 17.3 Share options
- [ ] 17.4 Tax reporting helper
  - Capital gains calculator
  - Holding period

### Step 18: Backup & Restore
- [ ] 18.1 Local backup (JSON export to device storage)
- [ ] 18.2 Restore from backup
- [ ] 18.3 Cloud backup option (Google Drive via googleapis)
- [ ] 18.4 Auto-backup settings
- [ ] 18.5 Data encryption (flutter_secure_storage)

### Step 19: Settings & Preferences
- [ ] 19.1 Settings screen
- [ ] 19.2 Theme selection (Light/Dark/Auto)
- [ ] 19.3 Currency format
- [ ] 19.4 Notification preferences
- [ ] 19.5 Data refresh intervals
- [ ] 19.6 Privacy settings
- [ ] 19.7 About & Help section

### Step 20: Testing & Optimization
- [ ] 20.1 Unit tests for business logic (Flutter test framework)
- [ ] 20.2 Widget tests (Flutter widget testing)
- [ ] 20.3 Integration tests (integration_test package)
- [ ] 20.4 Performance profiling (Flutter DevTools)
- [ ] 20.5 Memory leak checks
- [ ] 20.6 Battery usage optimization
- [ ] 20.7 Edge case handling
- [ ] 20.8 User testing (beta)
- [ ] 20.9 Bug fixes
- [ ] 20.10 Accessibility improvements

---

## 🚀 Phase 5: Launch Preparation (Week 6)

### Step 21: Production Readiness
- [ ] 21.1 App icon & splash screen (flutter_launcher_icons, flutter_native_splash)
- [ ] 21.2 Onboarding flow (introduction_screen or custom)
- [ ] 21.3 Privacy policy
- [ ] 21.4 Terms of service
- [ ] 21.5 Disclaimers (not financial advice)
- [ ] 21.6 App signing (Android keystore, iOS certificates)
- [ ] 21.7 Code obfuscation (flutter build --obfuscate)
- [ ] 21.8 Version management (pubspec.yaml)
- [ ] 21.9 Crash reporting (Firebase Crashlytics or Sentry)
- [ ] 21.10 Analytics (optional, privacy-first)

### Step 22: Documentation
- [ ] 22.1 User guide
- [ ] 22.2 FAQ
- [ ] 22.3 Code documentation
- [ ] 22.4 Architecture document
- [ ] 22.5 API documentation (backend)

### Step 23: Deployment
- [ ] 23.1 Generate signed APK/AAB (Android) and IPA (iOS)
- [ ] 23.2 Internal testing
- [ ] 23.3 Closed beta (friends/family) via TestFlight & Play Console
- [ ] 23.4 Open beta
- [ ] 23.5 Play Store & App Store listings
- [ ] 23.6 Screenshots & promotional material (both platforms)
- [ ] 23.7 Play Store & App Store submission
- [ ] 23.8 Monitor reviews & crashes

---

## 🔮 Future Enhancements (Post-Launch)

### Phase 6: Advanced Features
- [ ] Bank account linking (read-only via AA framework)
- [ ] FD/RD tracking
- [ ] PPF/EPF tracking
- [ ] Stock portfolio (equity)
- [ ] Real estate tracking
- [ ] Loan tracking (EMIs)
- [ ] Credit card bill reminders
- [ ] Goal-based investing
- [ ] Retirement calculator
- [ ] Multi-user support (family)
- [ ] Web dashboard (responsive Flutter web)

---

## 📝 Notes & Decisions

### Architecture Decisions
- **Local-first:** All data stored locally with sqflite, cloud optional
- **Offline-capable:** Core features work without internet
- **No login initially:** Privacy-first approach
- **Cross-platform ready:** Build for Android first, iOS deployment ready
- **Modular:** Easy to add new investment types

### Design Principles
- **Simplicity:** No feature bloat
- **Speed:** Fast app launch, instant updates
- **Trust:** No data collection without consent
- **Daily use:** Designed for quick check-ins

### Key Risks & Mitigations
1. **CAS parsing complexity** → Start with manual entry, add CAS later
2. **NAV matching accuracy** → Fuzzy search + manual verification
3. **Gold price API reliability** → Multiple fallback sources
4. **Privacy concerns** → Local-first, optional sync

---

## ✅ Current Status

**Phase:** Phase 1 - Foundation & Core Features  
**Tech Stack:** Flutter 3.38.7 (cross-platform ready)  
**Completed:** 
- ✅ Step 1 - Project Setup (100%)
- ✅ Step 3.1, 3.2 - Home Screen UI (Partial)

**In Progress:** Step 2 - Database Design  
**Next Step:** Step 2.1 - Design database schema

### 🎉 Today's Accomplishments (January 24, 2026):
- Flutter & Android SDK installed and configured
- Android Studio setup with Flutter plugin
- Full project structure created with 25+ dependencies
- Beautiful Material 3 theme implemented
- Home screen with portfolio breakdown built
- App successfully running in Chrome
- GitHub repository created and pushed
- 3 commits with working code

**GitHub:** https://github.com/balaji4991512/Investment-Tracker-App

---

**Last Updated:** January 24, 2026
