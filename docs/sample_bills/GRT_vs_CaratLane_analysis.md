# GRT Jewellers Bill Analysis - Comparison with CaratLane

## Bill Details Extracted:

### Invoice Information
- **Invoice No:** GRA2425SA253247
- **Date:** 29-Mar-2025, Time: 21:32:00
- **Store:** GR Thanga Maligai, 21 Coats Road, T Nagar, Chennai-17
- **GST No:** 33AAGEG3557L1Z8
- **State Code:** 33 (Tamil Nadu)
- **PAN:** AAGFG3557L

### Customer Information
- Name: ARCHANA V
- Location: Pallikaranai, Chennai
- Pincode: 600100
- Mobile: +919171907807

### Product Details
**Description:** GOLD BHAVALI (9) 
**Purity:** 22KT (91.60% fineness)
**HSN/SAC:** 7007/HD

---

## GRT Bill Fields vs Schema:

| GRT Bill Field | Value | CaratLane Field | Our Schema | Match? |
|---------------|-------|-----------------|------------|--------|
| **Purity** | 22KT\91.60 | 14 KT | `metalDetails.purity.karat` & `fineness` | ✅ Both |
| **Gross Wt. (Gms)** | 1.097 | Gross WT (g): 1.011 | `metalDetails.weight.gross` | ✅ |
| **Stones** | 0.060 | Diamond WT: 0.106/0.021 | `metalDetails.weight.stone` | ✅ |
| **Net Wt. (Gms)** | 1.037 | Net WT: 0.990 | `metalDetails.weight.net` | ✅ |
| **V.Addn.** | 0.060 | - | NEW? | ⚠️ Unknown |
| **Rate** | 2267.00/Gm | Price: 28530 | `metalDetails.rate` | ✅ |
| **Mc (Making Charges)** | - | 4500.00 | `makingCharge.amount` | ⚠️ Not shown separately |
| **Stones charges** | 0.300 Ct x 550.00 Per Ct = 165.00 | Stone charges | `stoneCharges` | ✅ |
| **HSN/SAC** | 7007/HD | AC71131930 | Need to add | ❌ |

---

## Price Breakdown Comparison:

### GRT Structure:
```
Base Amount:        Rs. 11,020.20  (Taxable value)
CGST @ 1.5%:        Rs. 167.78
SGST @ 1.5%:        Rs. 167.78
Total:              Rs. 11,355.76
Rounded off:        +20.76
Final Amount:       Rs. 11,500.00
```

### CaratLane Structure:
```
Pre-Discount:       Rs. 28,530.00
- Discounts:        Rs. -9,471.00
Taxable Value:      Rs. 19,059.00
+ GST 3%:          Rs. 572.00
Final Amount:       Rs. 19,631.00
```

---

## Key Differences Between Bills:

| Aspect | GRT | CaratLane | Notes |
|--------|-----|-----------|-------|
| **Format** | Simple, direct | Detailed breakdown | GRT more concise |
| **Discounts** | None shown | Multiple types | CaratLane has loyalty program |
| **Making Charges** | ❓ Included in price | ✅ Shown separately (₹4,500) | GRT doesn't break it out |
| **Stone Charges** | ✅ Shown: 0.3ct × ₹550 = ₹165 | ❌ Included in price | Different approaches |
| **HSN Code** | 7007/HD | AC71131930 | Different codes |
| **GST Rate** | 3% (1.5% CGST + 1.5% SGST) | 3% (1.5% CGST + 1.5% SGST) | Same |
| **Metal Type** | 22KT Gold (91.60) | 14KT Gold | Different purities |
| **Rounding** | +₹20.76 | -₹0.44 | Both round to nearest rupee |
| **Product Type** | Bhavali (ornament) | Diamond Pendant | Different items |

---

## New Fields Discovered in GRT Bill:

### ❌ Fields Not in Our Schema:

1. **"V.Addn."** - Unknown field (0.060) - possibly "Value Addition"?
2. **Hallmarking Charges** - Rs. 45 per piece (mentioned in T&C)
3. **Salesman/Cashier Info** - Employee codes
4. **Shop Code** - (SM/OP : 82267/59851/S)
5. **Live Rate Reference** - www.grtjewels.com/live
6. **Rounding Amount** - +20.76 (shows direction)

### ⚠️ Different Approaches:

**GRT doesn't show:**
- Making charges breakdown
- Diamond details (if any)
- Multiple discounts
- Payment split

**CaratLane doesn't show:**
- Stone charges separately
- V.Addn field
- Hallmarking charges

---

## Common Fields Across Both Bills:

✅ **Universal fields we must support:**

1. ✅ Invoice number & date
2. ✅ Store details (name, address, GST)
3. ✅ Customer info
4. ✅ Purity (karat + fineness)
5. ✅ Gross weight, net weight, stone weight
6. ✅ Rate per gram/carat
7. ✅ CGST, SGST
8. ✅ Final amount
9. ✅ HSN code (though format varies)

---

## Schema Updates Needed:

### High Priority (Seen in 2+ bills):
```json
{
  "hsnCode": "7007/HD",  // or "AC71131930"
  "roundingAdjustment": {
    "amount": 20.76,
    "direction": "up"  // or "down"
  },
  "hallmarkingCharges": 45,
  "taxableValue": 11020.20,  // Pre-GST
}
```

### Medium Priority (Vendor-specific):
```json
{
  "stoneChargesBreakdown": {
    "weight": 0.300,
    "unit": "ct",
    "ratePerUnit": 550.00,
    "total": 165.00
  },
  "valueAddition": 0.060,  // GRT specific?
  "employeeCodes": {
    "salesman": "82267",
    "operator": "59851",
    "cashier": "S"
  }
}
```

---

## Comparison Summary:

| Feature | CaratLane | GRT | Universal? |
|---------|-----------|-----|------------|
| **Bill Style** | Detailed, modern | Simple, traditional | - |
| **Discounts** | Multiple types | Not shown | ❌ |
| **Making Charges** | Separate | Hidden | ⚠️ |
| **Stone Charges** | Included | Separate | ⚠️ |
| **Diamond Details** | Full 4Cs | Basic | ❌ |
| **HSN Code** | ✅ | ✅ | ✅ |
| **GST Breakdown** | ✅ | ✅ | ✅ |
| **Weight Details** | ✅ | ✅ | ✅ |

---

## Recommendation:

**Our schema is flexible enough!** Key learnings:

1. ✅ **Keep it flexible** - vendors show different details
2. ✅ **Make fields optional** - not all bills have all fields
3. ✅ **Store original bill** - OCR might miss vendor-specific fields
4. ⚠️ **Add rounding adjustment** field
5. ⚠️ **Add hallmarking charges** (becoming mandatory)
6. ⚠️ **Add taxable value** (before GST)

**Next: See one more bill type (Tanishq/Kalyan/Malabar) to finalize schema?**
