from fastapi import APIRouter, File, UploadFile, HTTPException
from fastapi import APIRouter, File, UploadFile, HTTPException, Form
from fastapi.responses import JSONResponse
import base64
import json
import os
import uuid

from ..services.openai_client import OpenAIClient
from ..services.pdf_service import pdf_first_page_to_png_bytes


router = APIRouter()


EXTRACTION_PROMPT_GOLD = """You are an expert at extracting structured data from Indian GOLD jewellery bill receipts.

First, identify the bill's main LINE-ITEM being purchased (e.g., a necklace/ring/chain) and IGNORE any generic rate tables (e.g., "Standard Rate of 24 Karat / 22 Karat / 18 Karat Gold").

Return ONLY a single JSON object with EXACTLY these keys:

{
  "vendor": string or null,
  "productName": string or null,
  "purchaseDate": string or null,
  "netMetalWeight": number or null,
  "stoneWeight": number or null,
  "grossWeight": number or null,
  "goldRatePerGram": number or null,
  "makingChargesPerGram": number or null,
  "hallmarkCharges": number or null,
  "stoneCost": number or null,
  "grossPrice": number or null,
  "gst": { "cgst": number or null, "sgst": number or null, "total": number or null },
  "discounts": number or null,
  "finalPrice": number or null,
  "goldPurity": string or null
}

IMPORTANT field definitions for Indian jewellery bills:
- productName: The purchased item's name/description (e.g., "Diamond ring", "Gold chain"). Do NOT return generic headings like "Standard Rate of ...".
- goldRatePerGram: The BASE GOLD RATE per gram (ONLY if explicitly stated on the bill). This is the LARGER 4-5 digit number (typically 6000-10000 Rs/gm in 2024-2025). Look for headers like "Gold Rate", "Rate", "Rate/gm", "Gold Price". This is the market price of gold per gram. Do NOT infer or calculate this from other values. Do NOT use values from making charges rows.
- makingChargesPerGram: Making/wastage/labor charges PER GRAM. This is a SMALLER 3-4 digit number (typically 500-3000 Rs/gm). Often labeled "Making", "MC", "Wastage", "VA", "MC/gm", "Making Charges". Do NOT confuse with goldRatePerGram.
- hallmarkCharges: Hallmark assay charges (TOTAL amount, NOT per-gram). Often labeled "HM", "HM Charges", "Hallmark", "Assay". This is separate from making charges.
- CRITICAL ACCURACY: goldRatePerGram should ALWAYS be larger than makingChargesPerGram. If you extract goldRatePerGram < makingChargesPerGram, you likely swapped them. Correct this.
- CRITICAL: If a table column header spans TWO LINES like "NET STONE WEIGHT (Carats/Grams)", extract BOTH values: Carats (first number) and Grams (second number). Map Carats → stoneWeight and Grams → a separate value (diamondCarat for diamond bills). NEVER swap or merge these values.
- stoneCost: Cost of stones/diamonds embedded. Often labeled "Stone", "Stone Cost", "Diamond". This is NOT a discount.
- discounts: Actual discounts or offers applied. Only use this for amounts explicitly labeled as "Discount", "Offer", "Less".
- grossPrice: Total price before GST.
- finalPrice: Final amount paid (after GST, after discounts).

CRITICAL FIELD ACCURACY RULES:
1. GOLD RATE PER GRAM: Extract ONLY from rows/columns explicitly labeled with "Gold Rate", "Rate", "Rate/gm", or similar. This is a 4-5 digit number (e.g., 7510.89). Do NOT infer from making charges or other values. Do NOT auto-fill based on proximity.
2. HEADER-VALUE ALIGNMENT: Always match extracted values to their EXACT header by position. Do NOT move values between columns.
3. UNIT CONTEXT: Pay attention to units (Rs/gm, gm, ct, g, etc.) to confirm field accuracy.
4. NO SWAPPING: If goldRatePerGram < makingChargesPerGram, you have the values reversed. Swap them back.

MULTI-VALUE COLUMN HANDLING:
When a single column has multiple values on the same row (e.g., "NET STONE WEIGHT" with values "0.159" and "0.032"):
1. The FIRST value (left-most) typically corresponds to the header's first unit (e.g., Carats for "NET STONE WEIGHT (Carats/Grams)")
2. The SECOND value (next in row) corresponds to the second unit (e.g., Grams)
3. Extract EACH value to its designated field separately. Do NOT merge, swap, or drop any values.

GROUPED CHARGES HANDLING:
When charges are listed together (e.g., "Making Charges: 9885" and "HM Charges: 90" in the same section):
1. Extract BOTH values separately
2. Do NOT merge or combine them
3. Assign makingChargesPerGram = 9885 (or per-gram if labeled as such)
4. Assign hallmarkCharges = 90 (total HM charge)

Validation rules (must obey):
- grossWeight should be >= netMetalWeight (if both present).
- finalPrice should be >= 0.
- If you see a "Standard Rate" table, do NOT use it as productName.

Rules:
- Use numbers without currency symbols or commas.
- Dates must be YYYY-MM-DD or null.
- If a value is missing or unreadable, set it to null.
- Do NOT add any extra keys.
- Do NOT include any text before or after the JSON.
"""

EXTRACTION_PROMPT_DIAMOND = """You are an expert at extracting structured data from Indian DIAMOND jewellery bill receipts.

First, identify the bill's main LINE-ITEM being purchased (e.g., diamond ring/earrings/necklace) and IGNORE any generic rate tables (e.g., "Standard Rate of 24 Karat / 22 Karat / 18 Karat Gold").

Return ONLY a single JSON object with EXACTLY these keys:

{
  "vendor": string or null,
  "productName": string or null,
  "purchaseDate": string or null,
  "netMetalWeight": number or null,
  "stoneWeight": number or null,
  "grossWeight": number or null,
  "goldRatePerGram": number or null,
  "makingChargesPerGram": number or null,
  "hallmarkCharges": number or null,
  "stoneCost": number or null,
  "grossPrice": number or null,
  "gst": { "cgst": number or null, "sgst": number or null, "total": number or null },
  "discounts": number or null,
  "finalPrice": number or null,
  "goldPurity": string or null,
  "diamondCarat": number or null,
  "diamondCut": string or null,
  "diamondClarity": string or null,
  "diamondColor": string or null,
  "diamondCertificate": string or null
}

IMPORTANT field definitions:
- productName: The purchased item's name/description. Do NOT return generic headings like "Standard Rate of ...".
- diamondCarat: Total diamond weight in CARATS (ct). Look for headers labeled "Diamond Carat", "Carat", or "Ct". This is the FIRST value in multi-value columns like "NET STONE WEIGHT (Carats/Grams)". Example: 0.159 ct → diamondCarat = 0.159
- stoneWeight: Stone/diamond weight in GRAMS (g). This is the SECOND value in multi-value columns like "NET STONE WEIGHT (Carats/Grams)". Example: 0.032 g → stoneWeight = 0.032
- diamondCertificate: Certificate/report number (e.g., IGI/GIA) if present.
- stoneCost: Cost of stones/diamonds (often the diamond amount on the bill). If the bill has a separate diamond line-item amount, put it here.
- goldRatePerGram: The BASE GOLD RATE per gram (ONLY if explicitly stated on the bill). Look for headers like "Gold Rate", "Rate/gm", "Rate", "Gold Price". This is typically a 4-digit number (e.g., 7510.89). Do NOT infer or calculate this from other values. Do NOT swap this with making charges.
- makingChargesPerGram: Making/labor charges PER GRAM. This is typically a 3-4 digit number (e.g., 1234). Do NOT confuse with goldRatePerGram.
- hallmarkCharges: Hallmark assay charges (TOTAL amount). Only if explicitly present on diamond bills.

CRITICAL FIELD ACCURACY RULES:
1. DIAMOND CARAT vs STONE WEIGHT: If you see "NET STONE WEIGHT (Carats/Grams) 0.159 0.032", then:
   - diamondCarat = 0.159 (first value, in carats)
   - stoneWeight = 0.032 (second value, in grams)
   NEVER swap these values.
2. GOLD RATE PER GRAM: Extract from the row/column explicitly labeled "Gold Rate", "Rate", or "Gold Price". Look for the LARGER per-gram value (typically 4-5 digits like 7510.89). Do NOT use values from making charges rows.
3. HEADER-VALUE ALIGNMENT: Always match extracted values to their exact header by position. Do NOT move values between columns.
4. UNIT CONTEXT: Pay attention to units (ct, g, rs/gm, etc.) to confirm field accuracy.

MULTI-VALUE COLUMN HANDLING:
When a single column has multiple values on the same row (e.g., "NET STONE WEIGHT" with values "0.159" and "0.032"):
1. The FIRST value (left-most) corresponds to the header's first unit (e.g., Carats for "NET STONE WEIGHT (Carats/Grams)")
2. The SECOND value (next in row) corresponds to the second unit (e.g., Grams)
3. For example: "NET STONE WEIGHT (Carats/Grams)" with row values "0.159  0.032" means:
   - 0.159 = diamondCarat (carats)
   - 0.032 = stoneWeight (grams)
4. Extract EACH value to its designated field separately. Do NOT merge, swap, or drop any values.

GROUPED CHARGES HANDLING:
When charges are listed together (e.g., "Making Charges: 9885" and "HM Charges: 90" in the same section):
1. Extract BOTH values separately
2. Do NOT merge or combine them
3. Assign makingChargesPerGram = 9885 (or per-gram if labeled as such)
4. Assign hallmarkCharges = 90 (total HM charge)

Validation rules (must obey):
- grossWeight should be >= netMetalWeight (if both present).
- finalPrice should be >= 0.
- If you see a "Standard Rate" table, do NOT use it as productName.

Rules:
- Use numbers without currency symbols or commas.
- Dates must be YYYY-MM-DD or null.
- If a value is missing or unreadable, set it to null.
- Do NOT add any extra keys.
- Do NOT include any text before or after the JSON.
"""


@router.post("/upload")
async def upload_bill(file: UploadFile = File(...), category: str | None = Form(default=None)) -> JSONResponse:
  content_type = file.content_type or "application/octet-stream"
  print(f"[bills.upload] Received file: name={file.filename}, content_type={content_type}")
  print(f"[bills.upload] Category: {category}")

  extraction_prompt = EXTRACTION_PROMPT_GOLD
  if category in {"diamond_jewellery", "diamond"}:
    extraction_prompt = EXTRACTION_PROMPT_DIAMOND

  if not (content_type.startswith("image/") or content_type == "application/pdf"):
    print("[bills.upload] Unsupported content type")
    raise HTTPException(status_code=400, detail="Only image or PDF files are supported")

  raw_bytes = await file.read()
  print(f"[bills.upload] Raw bytes length: {len(raw_bytes)}")

  bills_dir = os.path.join(os.path.dirname(os.path.dirname(__file__)), "..", "files", "bills")
  bills_dir = os.path.abspath(bills_dir)
  os.makedirs(bills_dir, exist_ok=True)
  print(f"[bills.upload] Bills directory: {bills_dir}")

  bill_id = str(uuid.uuid4())
  print(f"[bills.upload] Generated bill_id: {bill_id}")

  if content_type.startswith("image/"):
    file_path = os.path.join(bills_dir, f"{bill_id}.img")
    try:
      with open(file_path, "wb") as f:
        f.write(raw_bytes)
      print(f"[bills.upload] Saved image to {file_path}")
    except OSError as e:
      print(f"[bills.upload] Failed to save image: {e}")
      file_path = None

    b64 = base64.b64encode(raw_bytes).decode("utf-8")
    data_url = f"data:{content_type};base64,{b64}"
    client = OpenAIClient()
    result = await client.call_gpt4o_vision(extraction_prompt, data_url)
    extracted_raw = result["content"] or "{}"
    print(f"[bills.upload] OpenAI content length (image): {len(extracted_raw)}")
    try:
      extracted_json = json.loads(extracted_raw)
    except json.JSONDecodeError:
      print("[bills.upload] Failed to parse JSON from OpenAI content (image), wrapping as raw.")
      extracted_json = {"raw": extracted_raw}
    print(f"[bills.upload] extracted_json keys (image): {list(extracted_json.keys())}")
    print(f"[bills.upload] extracted_json (image): {extracted_json}")
    return JSONResponse({
      "bill_id": bill_id,
      "file_path": file_path,
      "extracted": extracted_json,
    })

  if content_type == "application/pdf":
    png_bytes = pdf_first_page_to_png_bytes(raw_bytes)
    if not png_bytes:
      print("[bills.upload] pdf_first_page_to_png_bytes returned no data")
      raise HTTPException(status_code=400, detail="Unable to render first page of PDF")
    print(f"[bills.upload] Rendered first page PNG length: {len(png_bytes)}")

    file_path = os.path.join(bills_dir, f"{bill_id}.pdf")
    try:
      with open(file_path, "wb") as f:
        f.write(raw_bytes)
      print(f"[bills.upload] Saved PDF to {file_path}")
    except OSError as e:
      print(f"[bills.upload] Failed to save PDF: {e}")
      file_path = None

    b64 = base64.b64encode(png_bytes).decode("utf-8")
    data_url = "data:image/png;base64," + b64
    client = OpenAIClient()
    result = await client.call_gpt4o_vision(extraction_prompt, data_url)
    extracted_raw = result["content"] or "{}"
    print(f"[bills.upload] OpenAI content length (pdf): {len(extracted_raw)}")
    try:
      extracted_json = json.loads(extracted_raw)
    except json.JSONDecodeError:
      print("[bills.upload] Failed to parse JSON from OpenAI content (pdf), wrapping as raw.")
      extracted_json = {"raw": extracted_raw}
    print(f"[bills.upload] extracted_json keys (pdf): {list(extracted_json.keys())}")
    print(f"[bills.upload] extracted_json (pdf): {extracted_json}")
    return JSONResponse({
      "bill_id": bill_id,
      "file_path": file_path,
      "extracted": extracted_json,
    })

  print("[bills.upload] Reached unsupported content type branch")
  raise HTTPException(status_code=400, detail="Unsupported content type")
