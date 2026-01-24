# Investment Categories Overview

This document provides a quick reference for all investment types tracked by the Investment Tracker App.

---

## 1. 📈 Mutual Funds

**What it tracks:**
- Equity funds, debt funds, hybrid funds, index funds
- SIP investments and one-time purchases
- Multiple platforms (Zerodha, Groww, Paytm Money, etc.)

**Key Data Points:**
- Fund name and AMC
- Units, NAV, Amount
- Folio number
- Transaction type (Purchase/SIP/Redemption)
- Platform used

**Sample Use Cases:**
- Monthly SIP in HDFC Top 100 via Zerodha
- One-time ₹50,000 in ICICI Bluechip via Groww
- Redemption from Axis Long Term Equity

**Schema:** [mutual_fund_schema.json](../lib/models/schemas/mutual_fund_schema.json)  
**Samples:** [mutual_fund_zerodha.json](../lib/models/sample_data/mutual_fund_zerodha.json)

---

## 2. 🥇 Digital Gold

**What it tracks:**
- 24K gold purchased through apps
- Google Pay, PhonePe, Paytm, Amazon
- Buy/Sell transactions
- Physical delivery requests

**Key Data Points:**
- Weight in grams (24K purity)
- Rate per gram
- Platform and provider (MMTC-PAMP, Augmont, SafeGold)
- Current holdings
- GST and platform fees

**Sample Use Cases:**
- Buy 0.5g gold on Google Pay every month
- Sell 2g digital gold from PhonePe
- Request physical delivery of 10g gold

**Schema:** [digital_gold_schema.json](../lib/models/schemas/digital_gold_schema.json)  
**Samples:** [digital_gold_gpay.json](../lib/models/sample_data/digital_gold_gpay.json)

---

## 3. ⭐ Physical Gold

**What it tracks:**
- Jewelry (necklace, ring, chain, bracelet, bangle, earrings)
- Gold coins and bars (22K, 24K)
- Purchases from Tanishq, Kalyan, Malabar, local jewelers

**Key Data Points:**
- Gross weight, net weight, stone weight
- Purity (22K/916, 24K/999)
- Gold rate per gram
- Making charges, wastage, stone charges
- GST breakdown
- Bill image storage

**Sample Use Cases:**
- 22K gold necklace from Tanishq (25g, with ruby stones)
- 24K gold coin from Kalyan (10g, investment)
- Gold bangle from local jeweler (15g, 22K)

**Schema:** [physical_gold_schema.json](../lib/models/schemas/physical_gold_schema.json)  
**Samples:**
- [physical_gold_tanishq.json](../lib/models/sample_data/physical_gold_tanishq.json) - Complex necklace with stones
- [physical_gold_kalyan.json](../lib/models/sample_data/physical_gold_kalyan.json) - Simple gold coin

---

## 4. 💎 Diamond Jewellery

**What it tracks:**
- Diamond jewelry with mixed materials
- Gold/Platinum/White Gold base
- Certified and non-certified diamonds
- Multiple stones (diamonds, rubies, emeralds, sapphires)

**Key Data Points:**

### Metal Component:
- Type: Gold (18K/22K), Platinum (PT950/PT900), White Gold, Rose Gold
- Net weight in grams
- Metal rate and value

### Diamond Component:
- Total carats
- Individual diamond specs:
  - **Cut**: Round, Princess, Emerald, Cushion, etc.
  - **Clarity**: FL, IF, VVS1, VVS2, VS1, VS2, SI1, SI2
  - **Color**: D, E, F, G, H, I, J (D is colorless)
  - **Carat**: Weight
- GIA/IGI certificate numbers

### Additional Info:
- Other stones (rubies, emeralds, sapphires)
- Making charges + Setting charges
- Certification fees
- Exchange details (if old jewelry traded)
- EMI details (if applicable)
- Warranty information

**Sample Use Cases:**
- 18K white gold solitaire ring (0.5ct, VS1-F, GIA certified) from Tanishq
- 18K gold diamond earrings (0.4ct total, SI1-G, IGI) from CaratLane with exchange
- Platinum diamond pendant (0.65ct, VVS2-E, GIA + side stones) from Malabar on EMI

**Schema:** [diamond_jewellery_schema.json](../lib/models/schemas/diamond_jewellery_schema.json)  
**Samples:**
- [diamond_jewellery_tanishq.json](../lib/models/sample_data/diamond_jewellery_tanishq.json) - Solitaire ring
- [diamond_jewellery_caratLane.json](../lib/models/sample_data/diamond_jewellery_caratLane.json) - Earrings with exchange
- [diamond_jewellery_platinum.json](../lib/models/sample_data/diamond_jewellery_platinum.json) - Platinum pendant on EMI

---

## 5. 🪙 Precious Metals Jewellery

**What it tracks:**
- Platinum jewelry (chains, rings, bracelets)
- Silver jewelry (Sterling 925, 999 pure silver)
- Copper items (utensils, decorative pieces)
- Brass, bronze, panchaloha items
- Other precious metal jewelry without diamonds

**Key Data Points:**

### Metal Types:
- **Platinum**: PT999 (99.9%), PT950 (95%), PT900, PT850
- **Silver**: 999 (pure), 925 (Sterling), 900, 800
- **Copper**: 99.9% pure, 99.5%, alloy
- **Others**: Brass, bronze, white metal, panchaloha (5-metal alloy)

### Common Data:
- Gross weight, net weight, stone weight (if any)
- Purity/fineness
- Metal rate per gram
- Making charges
- Wastage (mainly for silver)
- BIS hallmark details
- Design finish (polished, matte, antique, oxidized)

**Sample Use Cases:**
- PT950 platinum chain from Tanishq (25.5g, BIS certified, ₹1.03L)
- Sterling silver anklet with ghungroo from Malabar (45g, 925 purity, ₹5.5K)
- Pure copper water pot and glasses (health/religious use, ₹2.1K)
- Oxidized silver bangles from Kalyan (62g net, antique design with exchange, ₹8.7K)

**Why Track Separately:**
- Different pricing dynamics than gold
- Platinum valued for purity and rarity
- Silver has industrial + jewelry demand
- Copper/brass mainly for utility/religious use
- No diamond complexity, simpler valuation

**Schema:** [precious_metals_jewellery_schema.json](../lib/models/schemas/precious_metals_jewellery_schema.json)  
**Samples:**
- [platinum_chain_tanishq.json](../lib/models/sample_data/platinum_chain_tanishq.json) - PT950 chain
- [silver_anklet_malabar.json](../lib/models/sample_data/silver_anklet_malabar.json) - 925 sterling silver
- [copper_utensils.json](../lib/models/sample_data/copper_utensils.json) - Pure copper items
- [silver_bangles_kalyan.json](../lib/models/sample_data/silver_bangles_kalyan.json) - Oxidized silver with exchange

---

## Investment Category Comparison

| Feature | Mutual Funds | Digital Gold | Physical Gold | Diamond Jewellery | Precious Metals |
|---------|-------------|--------------|---------------|-------------------|-----------------|
| **Liquidity** | High | High | Medium | Low | Medium |
| **Ticket Size** | ₹100+ | ₹10+ | ₹10,000+ | ₹50,000+ | ₹5,000+ |
| **Storage** | None | Digital | Physical | Physical | Physical |
| **Making Charges** | No | No | Yes | Yes (High) | Yes |
| **Resale Value** | NAV-based | Gold rate | Gold rate minus making | Complex valuation | Metal rate minus making |
| **Returns Tracking** | XIRR | Gold price + weight | Gold price + weight | Metal + Diamond prices | Metal price + weight |
| **Documentation** | Statement | App screenshot | Bill + BIS hallmark | Bill + GIA/IGI certificate | Bill + BIS hallmark |
| **GST** | No | 3% | 3% | 3% | 3-18% (varies) |
| **Market Linked** | Yes | Yes (gold price) | Yes (gold price) | Yes (gold + diamond) | Yes (metal prices) |
| **Investment Angle** | Pure investment | Investment + liquidity | Investment + jewelry | Jewelry + status | Utility + investment |

---

## Data Input Methods

### 1. **OCR (Bill Scanning)**
- Take photo of physical bill
- ML Kit extracts text
- LLM structures data
- User reviews and confirms

**Best for:** Physical Gold, Diamond Jewellery bills

### 2. **Manual Entry**
- Fill form with all details
- Auto-calculate derived fields
- Save directly to database

**Best for:** When OCR fails, handwritten bills, quick entry

### 3. **Voice Input**
- Speak transaction details naturally
- Speech-to-text conversion
- NLU extracts structured data
- Interactive clarification prompts

**Best for:** Quick entries, on-the-go recording

**Example voice commands:**
- "I bought a gold necklace from Tanishq today for 2 lakh rupees, 24 grams, 22 karat"
- "Added 5000 rupees to HDFC Top 100 fund through Zerodha"
- "Bought half gram digital gold on Google Pay"
- "Purchased diamond ring, 18K white gold, half carat diamond from Tanishq for 2.8 lakhs"

### 4. **API Integration** (Future)
- Connect to Zerodha Kite API for auto-sync MF data
- Google Pay/PhonePe APIs for digital gold
- Email parsing for statements

---

## Returns Calculation

### Mutual Funds
- **Metric**: XIRR (Extended Internal Rate of Return)
- **Formula**: Considers all SIPs, purchases, redemptions with dates
- **Current Value**: Units × Current NAV
- **Gain/Loss**: Current Value - Total Invested

### Digital Gold
- **Metric**: Absolute Return %
- **Formula**: `((Current Gold Rate × Total Grams) - Total Invested) / Total Invested × 100`
- **Current Value**: Current Gold Rate × Total Grams
- **Gain/Loss**: Current Value - Total Invested

### Physical Gold
- **Metric**: Absolute Return % (Adjusted)
- **Formula**: `((Current Gold Rate × Net Weight) - Total Paid) / Total Paid × 100`
- **Notes**: 
  - Use net gold weight (exclude stones)
  - Making charges NOT recovered on resale
  - Actual resale value = Gold value - Melting charges
- **Current Value**: Current Rate × Net Weight
- **Gain/Loss**: Current Value - Total Paid

### Diamond Jewellery
- **Metric**: Complex valuation
- **Components**:
  1. **Metal Value**: Current Rate × Net Metal Weight
  2. **Diamond Value**: Based on 4Cs + certificate
  3. **Other Stones**: Market rates
- **Notes**:
  - Making/Setting charges NOT recovered
  - Diamond resale typically 50-70% of purchase
  - GIA/IGI certificates increase value
  - Market for used diamond jewelry is limited
- **Estimated Value**: Metal Value + (Diamond Purchase Value × 0.6)
- **Gain/Loss**: Complex, may show loss initially

---

## Next Steps

1. ✅ **Phase 1 Complete**: JSON schemas and sample data created
2. 🔄 **Phase 2 (Current)**: Design database schema based on these JSONs
3. ⏳ **Phase 3**: Build input forms for manual entry
4. ⏳ **Phase 4**: Implement OCR extraction
5. ⏳ **Phase 5**: Add voice input
6. ⏳ **Phase 6**: Calculate returns and portfolio analytics

