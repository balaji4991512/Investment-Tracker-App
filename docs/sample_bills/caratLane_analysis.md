# CaratLane Bill Analysis - Real vs Schema

## Bill Details Extracted:

### Invoice Information
- **Order No:** EZCHNVRM9598O-JR
- **Doc No (Invoice):** SA2470126-00081  
- **Date:** 17/01/2026
- **Store:** VR Chennai Mall, Anna Nagar
- **GST No:** 33AADCC1791Q1ZB

### Customer Information
- Name: Balaji S
- Profile ID: CL48643D43
- State: Tamil Nadu (Code: 33)

### Product Details
**Product Code:** JP03780-1YS300-NA
**Description:** Classic Leaves Diamond Pendant
**Certificate No:** HF06XRPZUAP-0

**CaratLane Fields → Our Schema Mapping:**

| CaratLane Bill Field | Value | Our Schema Field | Notes |
|---------------------|-------|------------------|-------|
| **Purity (Karat)** | 14 KT | `metalDetails.purity.karat` | ✅ Matches |
| **HSN Codes** | AC71131930 | NEW - Need to add | ❌ Missing |
| **Net Qty** | 1 N | Not needed | Item count |
| **Gross WT (g)** | 1.011 | `metalDetails.weight.gross` | ✅ Matches |
| **Diamond WT (CT/g)** | 0.106/0.021 | `diamondDetails.totalCarats` | ⚠️ Format: ct/grams |
| **Gemstone WT (CT/g)** | 0.000/0.000 | `otherStones` | ✅ Matches |
| **Net WT (g)** | 0.990 | `metalDetails.weight.net` | ✅ Matches |
| **Making Charges (₹)** | 4500.00 | `makingCharge.amount` | ✅ Matches |
| **Price (₹)** | 28530.00 | Item subtotal | ✅ Matches |

### Price Breakdown Structure

| CaratLane Field | Value | Our Schema | Notes |
|----------------|-------|------------|-------|
| **Pre-Discount Value** | ₹28,530 | `totalAmount.subtotal` | Before discounts |
| **Strike-Through Discount** | -₹4,706 | NEW - Need to add | ❌ Missing |
| **Coupon Discount/xCLusive Points** | -₹4,765 | NEW - Need to add | ❌ Missing |
| **Cash Discount** | ₹0 | `totalAmount.discount` | ✅ Matches |
| **Taxable Value** | ₹19,059 | NEW - Calculate | After all discounts |
| **CGST (1.50%)** | ₹286 | `totalAmount.gst.cgst` | ✅ Matches |
| **SGST (1.50%)** | ₹286 | `totalAmount.gst.sgst` | ✅ Matches |
| **IGST (0.00%)** | ₹0 | `totalAmount.gst.igst` | ⚠️ Need to add |
| **Total Invoice Price** | ₹19,631 | `totalAmount.finalAmount` | ✅ Matches |
| **TCS** | ₹0 | NEW - Need to add | ❌ Missing (Tax Collected at Source) |

### Payment Details
**CaratLane shows:**
- Payment Mode: Credit Card
- Date: 2026-01-17
- Amount: ₹17,603
- PB-REC (Additional payment): ₹2,028

**Our schema:** ✅ Has `paymentMethod` but might need multiple payment entries

### Additional CaratLane Fields

| Field | Value | Purpose |
|-------|-------|---------|
| **Standard Gold Rate** | 24KT: ₹14,406, 22KT: ₹13,205, 18KT: ₹10,805, 14KT: ₹8,428 | Market reference |
| **Platinum Rate** | ₹7,793 | Market reference |
| **Certificate Number** | HF06XRPZUAP-0 | Diamond cert |
| **Product Code** | JP03780-1YS300-NA | Internal SKU |

---

## Schema Changes Required:

### ✅ Fields We Have Correctly:
1. Metal purity (karat)
2. Gross weight, net weight
3. Diamond weight (carats)
4. Making charges
5. CGST, SGST
6. Final amount
7. Payment method

### ❌ Missing Fields (Need to Add):

1. **HSN Code** - Tax classification code
2. **Strike-Through Discount** - Initial discount
3. **Coupon/xCLusive Points Discount** - Loyalty discount
4. **Multiple Discounts** - Need array instead of single discount
5. **Taxable Value** - After all discounts, before GST
6. **TCS** - Tax Collected at Source (for high-value purchases)
7. **IGST** - Interstate GST (in addition to CGST/SGST)
8. **Product Code/SKU** - Store's internal code
9. **Multiple Payments** - Split payments
10. **Certificate Number** - Should be per diamond/item
11. **Market Rates Reference** - Gold/Platinum rates on purchase date

### ⚠️ Format Issues:

1. **Diamond Weight Format:** Bill shows "0.106/0.021" (carats/grams) - we only store carats
2. **Discount Structure:** Multiple types of discounts, not just one amount
3. **Payment Split:** Two payment entries - need to handle multiple

---

## Recommendation:

**Keep our schema flexible** - it's comprehensive enough. Add these optional fields:

```json
"hsnCode": "AC71131930",
"productCode": "JP03780-1YS300-NA",
"certificateNumber": "HF06XRPZUAP-0",

"discounts": [
  {"type": "strike_through", "amount": 4706},
  {"type": "coupon", "amount": 4765},
  {"type": "cash", "amount": 0}
],

"taxableValue": 19059,
"tcs": 0,

"gst": {
  "cgst": 286,
  "sgst": 286, 
  "igst": 0,
  "total": 572
},

"payments": [
  {"method": "credit_card", "amount": 17603, "date": "2026-01-17"},
  {"method": "voucher", "reference": "PB-REC/MUMFC/2025-26/NOV/20", "amount": 2028, "date": "2026-01-17"}
],

"marketRates": {
  "gold14K": 8428,
  "gold18K": 10805,
  "gold22K": 13205,
  "gold24K": 14406,
  "platinum": 7793
}
```

**Should we update the schema now, or see more bills first?**
