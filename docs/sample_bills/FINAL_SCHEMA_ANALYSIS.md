# Universal Schema Analysis - 3 Major Vendors

## Bills Analyzed:
1. **CaratLane** - Modern online jeweler (Titan subsidiary)
2. **GRT Jewellers** - Traditional Tamil Nadu jeweler
3. **Tanishq** - Premium retail jeweler (Titan Company)

---

## TANISHQ BILL STRUCTURE

### Invoice Information
- **Doc No:** DOCIMPJ656
- **Date:** 23/10/2025, 7:23 pm
- **Store:** MIA by Tanishq, Phoenix Mall, Velachery, Chennai-600042
- **GSTIN:** 33AAACTS131A124
- **State Code:** 33
- **CIN:** L749991Z1984PLC001456

### Product Details
- **Variant No:** 553024VQLE1A09
- **Description:** BANGLES
- **Purity:** 14 Karat (585 fineness)
- **HSN:** 71131930

### Weight Details
| Field | Value |
|-------|-------|
| Gross Product Weight | 5.463 grams |
| Net Stone Weight | 0.163 carats / 0.033 grams |
| Net Metal Weight | 5.430 grams |

### Price Breakdown
| Item | Amount (₹) |
|------|-----------|
| Gross Product Price | 71,274.17 |
| Making Charges | 13,709.00 |
| HM (Hallmark) Charges | 45.00 |
| Other Charges | 4,245.00 |
| **Subtotal** | **64,931.00** |
| Product Discount | -4,157.70 |
| **Net Invoice Value** | **69,176.31** |
| CGST @ 1.5% | 1,007.42 |
| SGST @ 1.5% | 1,007.42 |
| **Final Amount** | **₹69,176.00** |

### Payment
- Mode: TATANEU DC (Tata Neu digital card)
- Encircle ID: 700412936358

### Market Rates (Reference)
- 24KT: ₹12,550.80
- 22KT: ₹11,505.00
- 18KT: ₹9,413.16
- 14KT: ₹7,321.32
- Platinum (95%): ₹5,760.00

---

## COMPARATIVE ANALYSIS: 3 VENDORS

### Field Mapping Across Vendors

| **Our Schema Field** | **CaratLane** | **GRT** | **Tanishq** | **Universal?** |
|---------------------|--------------|---------|-------------|----------------|
| **Invoice Number** | Doc No: SA2470126-00081 | Invoice: GRA2425SA253247 | Doc: DOCIMPJ656 | ✅ YES |
| **Date** | 17/01/2026 | 29-Mar-2025 | 23/10/2025 | ✅ YES |
| **Metal Purity** | 14 KT | 22KT\91.60 | 14 Karat (585) | ✅ YES |
| **Gross Weight** | 1.011g | 1.097g | 5.463g | ✅ YES |
| **Net Metal Weight** | 0.990g | 1.037g | 5.430g | ✅ YES |
| **Stone Weight** | 0.106ct / 0.021g | 0.060g | 0.163ct / 0.033g | ✅ YES |
| **HSN Code** | AC71131930 | 7007/HD | 71131930 | ✅ YES (format varies) |
| **CGST** | ₹286 @ 1.5% | ₹167.78 @ 1.5% | ₹1,007.42 @ 1.5% | ✅ YES |
| **SGST** | ₹286 @ 1.5% | ₹167.78 @ 1.5% | ₹1,007.42 @ 1.5% | ✅ YES |
| **Hallmark Charges** | ❌ Not shown | ₹45 (in T&C) | ✅ ₹45 (separate line) | ⚠️ VARIES |
| **Making Charges** | ✅ ₹4,500 | ❌ Hidden | ✅ ₹13,709 | ⚠️ VARIES |
| **Stone Charges** | ❌ Included | ✅ ₹165 (0.3ct × ₹550) | ❌ In "Other Charges" | ⚠️ VARIES |
| **Product Code/SKU** | JP03780-1YS300-NA | - | 553024VQLE1A09 | ⚠️ VARIES |
| **Discounts** | Multiple (strike-through, coupon) | ❌ None | ✅ Product discount ₹4,157.70 | ⚠️ VARIES |

---

## KEY INSIGHTS

### 1. **Universal Fields (Must Have):**
```json
{
  "vendor": {
    "name": "CaratLane / GRT / Tanishq",
    "billNumber": "...",
    "gstin": "...",
    "stateCode": "33"
  },
  "date": "YYYY-MM-DD",
  "items": [{
    "description": "...",
    "metalType": "gold",
    "purity": {
      "karat": 14,
      "fineness": 585
    },
    "weight": {
      "gross": 5.463,
      "net": 5.430,
      "stone": 0.033
    },
    "hsnCode": "71131930"
  }],
  "totalAmount": {
    "subtotal": 64931.00,
    "gst": {
      "cgst": 1007.42,
      "sgst": 1007.42,
      "total": 2014.84
    },
    "finalAmount": 69176.00
  }
}
```

### 2. **Vendor-Specific Fields (Optional):**

**CaratLane (Modern Online):**
- Multiple discount types
- xCLusive points
- Certificate numbers for diamonds
- Product codes
- Split payments

**GRT (Traditional):**
- Simple format
- Stone charges shown separately
- V.Addn field
- Minimal breakdown

**Tanishq (Premium Retail):**
- Detailed charge breakdown
- "Other charges" category
- Variant numbers
- Market rate reference (all karats)
- Encircle ID (loyalty program)
- Payment via Tata Neu

### 3. **Charge Structures Vary:**

| Charge Type | CaratLane | GRT | Tanishq |
|-------------|-----------|-----|---------|
| **Making Charges** | ✅ Separate (₹4,500) | ❌ Hidden | ✅ Separate (₹13,709) |
| **Stone Charges** | ❌ Included | ✅ Separate (₹165) | ⚠️ In "Other" (₹4,245) |
| **Hallmark** | ❌ Not shown | ⚠️ T&C only | ✅ Separate (₹45) |
| **Other Charges** | ❌ No | ❌ No | ✅ Yes (₹4,245) |
| **Discounts** | ✅ Multiple | ❌ No | ✅ Single (₹4,157.70) |

### 4. **Stone Weight Format:**

| Vendor | Format | Notes |
|--------|--------|-------|
| **CaratLane** | 0.106/0.021 | Carats / Grams |
| **GRT** | 0.060 | Grams only |
| **Tanishq** | 0.163 / 0.033 | Carats / Grams |

---

## RECOMMENDED SCHEMA STRUCTURE

Based on all 3 vendors, here's the finalized structure:

```json
{
  "id": "unique_id",
  "date": "YYYY-MM-DD",
  "time": "HH:MM:SS",
  
  "vendor": {
    "name": "string",
    "billNumber": "string",
    "branch": "string",
    "gstin": "string",
    "stateCode": "string",
    "pan": "string (optional)",
    "cin": "string (optional)"
  },
  
  "items": [{
    "productCode": "string (optional)",
    "description": "string",
    "quantity": 1,
    
    "metalDetails": {
      "metalType": "gold|platinum|silver",
      "purity": {
        "karat": 14,
        "fineness": 585
      },
      "weight": {
        "gross": 5.463,
        "net": 5.430,
        "stone": 0.033,
        "stoneCarats": 0.163
      },
      "rate": 7321.32,
      "metalValue": 39759.00
    },
    
    "charges": {
      "makingCharges": 13709.00,
      "hallmarkCharges": 45.00,
      "stoneCharges": 165.00,
      "otherCharges": 4245.00,
      "wastage": {
        "percentage": 0,
        "amount": 0
      }
    },
    
    "hsnCode": "71131930",
    "grossProductPrice": 71274.17
  }],
  
  "pricing": {
    "subtotal": 64931.00,
    "discounts": [
      {
        "type": "product_discount",
        "amount": 4157.70,
        "description": "Product level discount"
      }
    ],
    "taxableValue": 69176.31,
    "gst": {
      "cgst": 1007.42,
      "sgst": 1007.42,
      "igst": 0,
      "total": 2014.84,
      "rate": 3.0
    },
    "roundingAdjustment": -0.31,
    "finalAmount": 69176.00
  },
  
  "payment": {
    "method": "credit_card|debit_card|upi",
    "amount": 69176.00,
    "reference": "optional",
    "loyaltyId": "optional (Encircle ID / Profile ID)"
  },
  
  "marketRates": {
    "gold24K": 12550.80,
    "gold22K": 11505.00,
    "gold18K": 9413.16,
    "gold14K": 7321.32,
    "platinum95": 5760.00
  },
  
  "billImage": "/path/to/image",
  "extractedBy": "ocr|manual|voice"
}
```

---

## SCHEMA FLEXIBILITY RULES

### ✅ **Required Fields (All Vendors):**
1. Invoice number, date
2. Vendor name & GSTIN
3. Metal purity (karat + fineness)
4. Weights (gross, net)
5. CGST, SGST, Final amount

### ⚠️ **Optional/Conditional Fields:**
1. Making charges (separate or included)
2. Stone charges (separate or in "other")
3. Hallmark charges (₹45 if shown)
4. Discounts (vendor-specific)
5. Product codes (not all vendors)
6. Stone weight in carats (not GRT)
7. Other charges (Tanishq specific)

### ❌ **Vendor-Specific (Don't Force):**
1. xCLusive points (CaratLane)
2. V.Addn (GRT)
3. Encircle ID (Tanishq)
4. Certificate numbers (premium items only)

---

## RECOMMENDATIONS FOR APP:

1. ✅ **Use our flexible JSON schema** - covers all vendors
2. ✅ **Make most fields optional** - vendors vary greatly
3. ✅ **Store raw bill image** - fallback for missing data
4. ✅ **Support multiple discount types** - array structure
5. ✅ **Add "Other Charges" field** - Tanishq uses it
6. ✅ **Store market rates** - useful for tracking
7. ✅ **Add loyalty program IDs** - Profile ID, Encircle ID
8. ⚠️ **Don't over-validate** - let users enter what they have

---

## NEXT STEPS:

**Option 1:** Finalize schema and start building app with JSON storage  
**Option 2:** See more bills (Malabar, Kalyan) to be extra sure  
**Option 3:** Start building with current schema, adjust as we go

**What do you prefer?**
