# Data Extraction & Processing Pipeline

## Overview
This document explains how we extract data from various sources (bills, statements, voice) and convert them into standardized JSON format.

---

## Pipeline Architecture

```
┌─────────────────┐
│  Input Source   │
<!-- Physical Gold extraction removed - category deprecated -->

---

**Advantages:**
- Fast and offline
- No API costs
- Deterministic results

**Disadvantages:**
- Needs patterns for each company
- Breaks if format changes
- Struggles with variations

### Example: Tanishq Bill Processing

**Input:** Bill image → **OCR** → Raw text:
```
TANISHQ JEWELLERY LIMITED
Phoenix Market City, Chennai
GST: 33AAACT2727Q1ZV
Bill No: TNQ/CHN/2025/00123
Date: 15/01/2025

Item Description: 22K Gold Necklace with Ruby
Item Code: TNQ-NK-12345
Gross Weight: 25.500 gms
Stone Weight: 1.300 gms
Net Weight: 24.200 gms
Purity: 916 (22K)
Gold Rate/Gm: Rs. 6,800
Gold Value: Rs. 1,64,560
Making Charges: Rs. 12,100
Wastage @ 8%: Rs. 13,164.80
Stone Charges: Rs. 5,000
------------------------------
Sub Total: Rs. 1,94,824.80
CGST @ 1.5%: Rs. 2,922.37
SGST @ 1.5%: Rs. 2,922.37
Total GST: Rs. 5,844.74
Round Off: Rs. -0.54
Grand Total: Rs. 2,00,669
```

**Output:** Standardized JSON (see [physical_gold_tanishq.json](sample_data/physical_gold_tanishq.json))

---

## 2. Diamond Jewellery Bills

### Challenge: Most Complex Format
Diamond jewelry bills are the most complex as they include:
- **Multiple materials**: Gold/Platinum/White Gold base
- **Diamond specifications**: Carats, cut, clarity, color (4Cs)
- **Certifications**: GIA, IGI certificates
- **Other stones**: Rubies, emeralds, sapphires
- **Multiple charges**: Metal, diamonds, making, setting, wastage

### Fields to Extract (Universal)
| Field | Variations in Bills | Our Standard Field |
|-------|-------------------|-------------------|
| Metal Type | "18K WG", "White Gold", "Platinum PT950" | `metalDetails.metalType` |
| Metal Weight | "Net Wt", "Gold Wt", "Metal Weight" | `metalDetails.weight.net` |
| Metal Purity | "18K", "750", "PT950" | `metalDetails.purity` |
| Diamond Carats | "Dia Wt", "Total Carats", "TCW" | `diamondDetails.totalCarats` |
| Diamond Quality | "VVS2/E", "VS1-F", "SI1 G" | `diamonds[].clarity`, `diamonds[].color` |
| Diamond Cut | "Round", "Princess", "Emerald" | `diamonds[].cut` |
| Certificate | "GIA 2197845623", "IGI Cert" | `diamonds[].certificateNumber` |
| Setting Charges | "Setting", "Labour", "Polish" | `settingCharges` |
| Making Charge | "MC", "Making" | `makingCharge.amount` |

### Extraction Strategy

**LLM-Based (Strongly Recommended)**

Diamond bills need intelligent parsing:
```dart
String diamondPrompt = '''\nExtract diamond jewelry details from this bill:

$ocrText

Extract:
1. Vendor details (name, branch, bill number, GSTIN)
2. Jewelry type (ring, pendant, earrings, etc.)
3. Metal details:
   - Type (gold/platinum/white gold)
   - Net weight in grams
   - Purity (18K, 22K, PT950, etc.)
   - Rate per gram
4. Diamond details:
   - Total carats
   - For each significant diamond:
     * Carats
     * Cut (round, princess, etc.)
     * Clarity (VVS1, VS1, SI1, etc.)
     * Color (D, E, F, G, etc.)
   - Certificate number (GIA/IGI)
5. Other stones if any (ruby, emerald, sapphire)
6. All charges:
   - Metal value
   - Diamond value
   - Making charges
   - Setting charges
   - Wastage
   - Certification fees
7. GST breakdown and final amount
8. Warranty details

Return JSON matching diamond_jewellery_schema.json
''';
```

### Example: Tanishq Diamond Ring

**Input:** Bill → **OCR** → Raw text:
```
TANISHQ JEWELLERY LIMITED
Express Avenue, Chennai
Bill: TNQ/CHN/EA/2025/00567
Date: 18/01/2025

Item: 18K White Gold Solitaire Ring
Metal: White Gold 18K (750)
Gross Wt: 4.500 gms
Diamond Wt: 0.500 ct
Net Metal Wt: 3.800 gms

Diamond Details:
Center Stone: 0.50 ct
Cut: Round Brilliant
Clarity: VS1
Color: F
GIA Certificate: GIA2197845623

Metal Rate/gm: Rs. 5,200
Metal Value: Rs. 19,760
Diamond Rate/ct: Rs. 4,50,000
Diamond Value: Rs. 2,25,000
Side Stones: Rs. 2,400
Making Charges: Rs. 15,000
Setting Charges: Rs. 8,000
Certification: Rs. 1,500
------------------------------
Sub Total: Rs. 2,72,160
CGST @ 1.5%: Rs. 4,082.40
SGST @ 1.5%: Rs. 4,082.40
Grand Total: Rs. 2,80,324

Warranty: Lifetime
```

**Output:** Standardized JSON (see [diamond_jewellery_tanishq.json](../lib/models/sample_data/diamond_jewellery_tanishq.json))

### Key Points for Diamond Jewelry

1. **4Cs of Diamonds**: Always capture Cut, Clarity, Color, Carat
2. **Certification**: GIA/IGI certificates add significant value
3. **Metal Type**: White gold, yellow gold, rose gold, or platinum
4. **Multiple Stones**: One bill may have center stone + side stones
5. **Exchange**: Many purchases involve old jewelry exchange
6. **EMI Options**: High-value items often on EMI
7. **Warranty**: Lifetime or limited period warranties

---

## 2. Diamond Jewellery Bills

### Challenge: Most Complex Format
Diamond jewelry bills are the most complex as they include:
- **Multiple materials**: Gold/Platinum/White Gold base
- **Diamond specifications**: Carats, cut, clarity, color (4Cs)
- **Certifications**: GIA, IGI certificates
- **Other stones**: Rubies, emeralds, sapphires
- **Multiple charges**: Metal, diamonds, making, setting, wastage

### Fields to Extract (Universal)
| Field | Variations in Bills | Our Standard Field |
|-------|-------------------|-------------------|
| Metal Type | "18K WG", "White Gold", "Platinum PT950" | `metalDetails.metalType` |
| Metal Weight | "Net Wt", "Gold Wt", "Metal Weight" | `metalDetails.weight.net` |
| Metal Purity | "18K", "750", "PT950" | `metalDetails.purity` |
| Diamond Carats | "Dia Wt", "Total Carats", "TCW" | `diamondDetails.totalCarats` |
| Diamond Quality | "VVS2/E", "VS1-F", "SI1 G" | `diamonds[].clarity`, `diamonds[].color` |
| Diamond Cut | "Round", "Princess", "Emerald" | `diamonds[].cut` |
| Certificate | "GIA 2197845623", "IGI Cert" | `diamonds[].certificateNumber` |
| Setting Charges | "Setting", "Labour", "Polish" | `settingCharges` |
| Making Charge | "MC", "Making" | `makingCharge.amount` |

### Extraction Strategy

**LLM-Based (Strongly Recommended)**

Diamond bills need intelligent parsing:
```dart
String diamondPrompt = '''
Extract diamond jewelry details from this bill:

$ocrText

Extract:
1. Vendor details (name, branch, bill number, GSTIN)
2. Jewelry type (ring, pendant, earrings, etc.)
3. Metal details:
   - Type (gold/platinum/white gold)
   - Net weight in grams
   - Purity (18K, 22K, PT950, etc.)
   - Rate per gram
4. Diamond details:
   - Total carats
   - For each significant diamond:
     * Carats
     * Cut (round, princess, etc.)
     * Clarity (VVS1, VS1, SI1, etc.)
     * Color (D, E, F, G, etc.)
   - Certificate number (GIA/IGI)
5. Other stones if any (ruby, emerald, sapphire)
6. All charges:
   - Metal value
   - Diamond value
   - Making charges
   - Setting charges
   - Wastage
   - Certification fees
7. GST breakdown and final amount
8. Warranty details

Return JSON matching diamond_jewellery_schema.json
''';
```

### Example: Tanishq Diamond Ring

**Input:** Bill → **OCR** → Raw text:
```
TANISHQ JEWELLERY LIMITED
Express Avenue, Chennai
Bill: TNQ/CHN/EA/2025/00567
Date: 18/01/2025

Item: 18K White Gold Solitaire Ring
Metal: White Gold 18K (750)
Gross Wt: 4.500 gms
Diamond Wt: 0.500 ct
Net Metal Wt: 3.800 gms

Diamond Details:
Center Stone: 0.50 ct
Cut: Round Brilliant
Clarity: VS1
Color: F
GIA Certificate: GIA2197845623

Metal Rate/gm: Rs. 5,200
Metal Value: Rs. 19,760
Diamond Rate/ct: Rs. 4,50,000
Diamond Value: Rs. 2,25,000
Side Stones: Rs. 2,400
Making Charges: Rs. 15,000
Setting Charges: Rs. 8,000
Certification: Rs. 1,500
------------------------------
Sub Total: Rs. 2,72,160
CGST @ 1.5%: Rs. 4,082.40
SGST @ 1.5%: Rs. 4,082.40
Grand Total: Rs. 2,80,324

Warranty: Lifetime
```

**Output:** Standardized JSON (see [diamond_jewellery_tanishq.json](../lib/models/sample_data/diamond_jewellery_tanishq.json))

### Key Points for Diamond Jewelry

1. **4Cs of Diamonds**: Always capture Cut, Clarity, Color, Carat
2. **Certification**: GIA/IGI certificates add significant value
3. **Metal Type**: White gold, yellow gold, rose gold, or platinum
4. **Multiple Stones**: One bill may have center stone + side stones
5. **Exchange**: Many purchases involve old jewelry exchange
6. **EMI Options**: High-value items often on EMI
7. **Warranty**: Lifetime or limited period warranties

---

## 3. Mutual Fund Statements

### Challenge: Multiple Platforms
Each platform shows data differently:
- **Zerodha Coin**: Clean tabular format
- **Groww**: Colorful cards with emojis
- **Paytm Money**: Detailed breakup
- **Email Statements**: Plain text or PDF

### Fields to Extract
- Platform name
- Fund name (full name with plan type)
- Transaction type (Buy/SIP/Sell)
- Units, NAV, Amount
- Folio number
- Date

### Extraction Strategy

**Best approach:** API integration where possible
- Zerodha has Kite Connect API
- Groww has unofficial APIs
- Can use CAMS/Karvy statement upload

For OCR from screenshots:
```dart
String mfPrompt = '''
Extract mutual fund transaction details from this statement:

$ocrText

Extract:
- Platform name (Zerodha, Groww, etc.)
- Fund name
- Transaction type (Purchase/SIP/Redemption)
- Units, NAV, Amount
- Date
- Folio number
- Order number

Return JSON matching mutual_fund_schema.json
''';
```

---

## 3. Digital Gold Transactions

### Challenge: Minimal Info
Digital gold transactions are simple but need tracking:
- Platform (Google Pay, PhonePe, Paytm)
- Weight purchased
- Rate and amount
- Current holdings

### Fields to Extract
- Date/time
- Platform
- Weight in grams
- Rate per gram
- Amount paid
- GST
- Transaction ID
- Current total holdings

### Extraction Strategy

**Easiest type to extract:**
- Usually a single screenshot
- Standardized formats per platform
- Key info prominently displayed

Pattern matching works well:
```dart
// Google Pay digital gold pattern
r'Gold\s+(\d+(?:\.\d+)?)\s*g'
r'₹(\d+(?:,\d+)*(?:\.\d+)?)/g'
r'Total:\s*₹(\d+(?:,\d+)*(?:\.\d+)?)'
```

---

## 4. Voice Input Processing

### Strategy
1. **Speech-to-Text** (using `speech_to_text` package)
2. **NLU Processing** (LLM understands intent)
3. **Structured Data Extraction**

### Example Voice Commands
```
"I bought a gold necklace from Tanishq today for 2 lakh rupees, 
24 grams, 22 karat"

→ Extracts:
- vendor.name: "Tanishq"
- date: today's date
- type: "necklace"
- weight.net: 24
- purity.karat: 22
- totalAmount.finalAmount: 200000
- extractedBy: "voice"
```

```
"Added 5000 rupees to HDFC Top 100 fund through Zerodha"

→ Extracts:
- platform: "zerodha"
- fundName: "HDFC Top 100"
- amount: 5000
- transactionType: "purchase"
- extractedBy: "voice"
```

LLM fills in missing data or prompts user:
- "What was the NAV?"
- "How many units did you get?"
- "Was this a SIP or one-time purchase?"

---

## 5. Data Validation

After extraction, validate against schemas:

```dart
// Validate against JSON schema
final validator = JsonSchemaValidator();
final result = validator.validate(
  extractedData, 
  physicalGoldSchema
);

if (result.hasErrors) {
  // Show errors to user
  // Ask for manual correction
}
```

### Common Validations
- Date format (YYYY-MM-DD)
- Positive numbers (weight, amount)
- Enum values (type, purity, platform)
- Required fields present
- Calculations match (gold value = net weight × rate)

---

## 6. Database Storage

After validation, store in multiple places:

1. **JSON Files** (backup & debugging)
   - Save to `storage/transactions/`
   - One file per transaction
   - Easy to inspect and debug

2. **SQLite Database** (primary storage)
   - Normalized tables
   - Fast queries
   - Relational data

3. **Hive Cache** (quick access)
   - Recent transactions
   - Dashboard data
   - Offline support

---

## Implementation Plan

### Phase 1: Manual Entry (Working)
- ✅ JSON schemas defined
- ✅ Sample data created
- Next: Build input forms matching schemas

### Phase 2: OCR + Pattern Matching
- Implement ML Kit text recognition
- Create patterns for common bill formats
- Extract and validate

### Phase 3: LLM Integration
- Add OpenAI/Claude API
- Intelligent extraction from any format
- Handle edge cases

### Phase 4: Voice Input
- Implement speech-to-text
- NLU processing
- Interactive data collection

---

## Example Usage

```dart
// User scans Tanishq bill
final image = await ImagePicker().pickImage(source: ImageSource.camera);
final ocrText = await MLKitTextRecognition.extractText(image);

// Extract structured data
final extractor = DataExtractor();
final jsonData = await extractor.extractPhysicalGold(
  ocrText,
  vendor: 'tanishq', // Optional hint
);

// Validate
final isValid = PhysicalGoldValidator.validate(jsonData);

if (isValid) {
  // Save to database
  await InvestmentDatabase.insert(jsonData);
  
  // Show success
  showSuccess('Gold purchase added: ${jsonData['items'][0]['type']}');
}
```

---

## Next Steps

1. Review these schemas and samples
2. Share your real bills (we'll test extraction)
3. Build the database schema based on these JSON structures
4. Implement manual entry forms first
5. Add OCR later

