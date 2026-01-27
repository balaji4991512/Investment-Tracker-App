# All Investment Types - Quick Reference

## Summary of All 5 Investment Categories

### 1. 📈 **Mutual Funds** 
Financial investment via platforms like Zerodha, Groww  
**Track:** Fund name, units, NAV, SIP/one-time  
**Complexity:** ⭐⭐ (Simple)

### 2. 🥇 **Digital Gold** 
24K gold purchased via apps (Google Pay, PhonePe)  
**Track:** Weight, rate, platform  
**Complexity:** ⭐ (Very Simple)

### 3. 💎 **Diamond Jewellery** 
Diamonds with gold/platinum base  
**Track:** Metal + Diamond (4Cs) + certifications  
**Complexity:** ⭐⭐⭐⭐⭐ (Very Complex)

### 5. 🪙 **Precious Metals** 
Platinum, silver, copper jewelry  
**Track:** Metal type, purity, weight, hallmark  
**Complexity:** ⭐⭐ (Simple to Moderate)

---

## Category Decision Tree

```
Are you investing in...?

├─ Financial instruments (stocks, MFs)
│  └─ Mutual Funds 📈
│
├─ Gold
│  ├─ Via app/digital
│  │  └─ Digital Gold 🥇
│  │
│  └─ Physical
│     ├─ Has diamonds?
│     │  └─ YES → Diamond Jewellery 💎
│     │
│     └─ NO → Physical Gold ⭐
│
└─ Other metals
   ├─ Platinum, Silver, Copper
   │  ├─ Has diamonds?
   │  │  └─ YES → Diamond Jewellery 💎
   │  │
   │  └─ NO → Precious Metals 🪙
   │
   └─ Gold with diamonds
      └─ Diamond Jewellery 💎
```

---

## Schema Files

| Category | Schema File | Sample Files |
|----------|-------------|--------------|
| **Mutual Funds** | `mutual_fund_schema.json` | `mutual_fund_zerodha.json` |
| **Digital Gold** | `digital_gold_schema.json` | `digital_gold_gpay.json` |

| **Diamond Jewellery** | `diamond_jewellery_schema.json` | `diamond_jewellery_tanishq.json`<br>`diamond_jewellery_caratLane.json`<br>`diamond_jewellery_platinum.json` |
| **Precious Metals** | `precious_metals_jewellery_schema.json` | `platinum_chain_tanishq.json`<br>`silver_anklet_malabar.json`<br>`copper_utensils.json`<br>`silver_bangles_kalyan.json` |

---

## Key Differentiators

### Gold Categories

| Category | Gold Type | Diamond | Typical Use | Example |
|----------|-----------|---------|-------------|---------|
| **Digital Gold** | 24K pure | No | Investment | 0.5g on Google Pay |
| **Diamond Jewellery** | 18K/22K | Yes | High-end jewelry | Diamond ring ₹2.8L |

### Metal Categories

| Category | Metals | Typical Purity | Example |
|----------|--------|----------------|---------|
| **Diamond Jewellery** | Gold/Platinum/White Gold | 18K (750), PT950 | Diamond earrings |
| **Precious Metals** | Platinum/Silver/Copper | PT950, 925 Sterling, 99.9% | Silver anklet, platinum chain |
| **Precious Metals** | Platinum/Silver/Copper | PT950, 925 Sterling, 99.9% | Silver anklet, platinum chain |

---

## Returns Calculation Methods

### Simple (Absolute Return)
Used for: Digital Gold, Precious Metals
```
Return % = ((Current Value - Investment) / Investment) × 100
Current Value = Current Rate × Weight
```

### Moderate (Adjusted Return)
Used for: Diamond Jewellery
```
Consideration:
- Making charges NOT recovered
- Deduct resale costs (melting, certification)
- Actual value lower than metal value

Estimated Value = (Metal Rate × Weight) - Making Charges
```

### Complex (XIRR)
Used for: Mutual Funds
```
Considers:
- Multiple transactions (SIPs, purchases, redemptions)
- Time value of money
- Cash flow dates

Formula: Excel XIRR function
```

---

## Database Structure (Preview)

### Investment Types Table
```
investment_types:
- id
- name (Mutual Funds, Digital Gold, etc.)
- category (financial, precious_metals, jewelry)
- icon
- color
```

### Investments Table (Parent)
```
investments:
- id
- user_id
- investment_type_id
- date
- total_amount
- current_value
- gain_loss_percentage
```

### Type-Specific Tables (Children)
```
mutual_fund_investments:
- investment_id (FK)
- fund_name
- units
- nav
- platform
- ...

digital_gold_investments:
- investment_id (FK)
- weight
- rate
- platform
- ...

diamond_jewellery_investments:
- investment_id (FK)
- items (JSON)
 - metal_details (JSON)
 - diamond_details (JSON)
- ...

diamond_jewellery_investments:
- investment_id (FK)
- items (JSON)
- metal_details (JSON)
- diamond_details (JSON)
- ...

precious_metals_investments:
- investment_id (FK)
- metal_type
- items (JSON)
- purity
- ...
```

---

## UI Categories on Home Screen

```
┌─────────────────────────────────────┐
│  Net Worth: ₹12,45,000              │
│  Today: +₹2,340 (+0.19%)           │
└─────────────────────────────────────┘

┌─────────────────────────────────────┐
│ 📈 Mutual Funds         ₹5,45,000   │
│ +12.5%                              │
└─────────────────────────────────────┘

┌─────────────────────────────────────┐
│ 🥇 Digital Gold         ₹1,18,500   │
│ +8.2%                               │
└─────────────────────────────────────┘

┌─────────────────────────────────────┐
│ ⭐ Physical Gold        ₹3,32,750   │
│ +15.8%                              │
└─────────────────────────────────────┘

┌─────────────────────────────────────┐
│ 💎 Diamond Jewellery    ₹2,85,000   │
│ +5.3%                               │
└─────────────────────────────────────┘

┌─────────────────────────────────────┐
│ 🪙 Precious Metals      ₹1,08,750   │
│ +3.2%                               │
└─────────────────────────────────────┘
```

---

## Data Input Methods by Category

| Category | OCR | Manual | Voice | API |
|----------|-----|--------|-------|-----|
| **Mutual Funds** | ✅ Screenshots | ✅ | ✅ | ✅ Best |
| **Digital Gold** | ✅ Screenshots | ✅ | ✅ | ⚠️ Limited |
| **Physical Gold** | ✅ Best | ✅ | ✅ | ❌ |
| **Diamond Jewellery** | ✅ Best | ✅ | ⚠️ Complex | ❌ |
| **Precious Metals** | ✅ Best | ✅ | ✅ | ❌ |

---

## Next Steps

1. ✅ **Phase 1 Complete**: All schemas and samples created
2. 🔄 **Phase 2 (Current)**: Design database schema
3. ⏳ **Phase 3**: Build manual entry forms
4. ⏳ **Phase 4**: Implement OCR extraction
5. ⏳ **Phase 5**: Add voice input
6. ⏳ **Phase 6**: Calculate returns

