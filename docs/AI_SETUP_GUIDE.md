# AI Bill Parsing Setup Guide

## Why AI?
Jewelry bills have complex layouts with varied formats across vendors. AI (Google Gemini) can intelligently extract data regardless of format.

## Setup Steps

### 1. Get Free Gemini API Key
1. Go to: https://makersuite.google.com/app/apikey
2. Sign in with your Google account
3. Click "Create API Key"
4. Copy the key (starts with `AIza...`)

### 2. Add API Key to .env File
Open: `.env` file in the project root

Add your key:
```
GEMINI_API_KEY=AIzaSyC...your-actual-key...
```

**Note**: The `.env` file is gitignored and won't be committed to version control, keeping your key safe!

### 3. Restart the App
```bash
flutter run -d chrome
```

## How It Works

1. **Extract Text**: PDF/Image → Text using Syncfusion/ML Kit
2. **AI Analysis**: Text → Gemini AI → Structured JSON
3. **Parse Result**: JSON → Form fields
4. **Confirm**: User verifies/corrects → Save

## AI Extracts:
- ✅ Vendor name (Tanishq, GRT, CaratLane, etc.)
- ✅ Product type (Ring, Chain, Necklace, etc.)
- ✅ Weight in grams
- ✅ Purity (22K, 18K, 14K, 24K)
- ✅ Final amount in rupees
- ✅ Bill number
- ✅ Date
- ✅ Metal type (Gold/Platinum/Silver)

## Benefits
- Works with ANY bill format
- Handles variations (different vendors, languages, layouts)
- More accurate than regex patterns
- Self-improving (Gemini keeps getting better)

## Free Tier Limits
- **60 requests per minute**
- **1,500 requests per day**
- More than enough for personal use!

## Security Note
The API key is stored locally in your app code. For production apps, you'd want to:
- Store it securely (flutter_secure_storage)
- Or use a backend server to proxy API calls

## Fallback
If AI parsing fails, the app still works - you can manually fill all fields!
