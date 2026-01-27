from fastapi import APIRouter, File, UploadFile, HTTPException
from fastapi.responses import JSONResponse
import base64
import json
import os
import uuid

from ..services.openai_client import OpenAIClient
from ..services.pdf_service import pdf_first_page_to_png_bytes


router = APIRouter()


EXTRACTION_PROMPT = """You are an expert at extracting structured data from Indian jewelry/gold bill receipts.

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
  "stoneCost": number or null,
  "grossPrice": number or null,
  "gst": { "cgst": number or null, "sgst": number or null, "total": number or null },
  "discounts": number or null,
  "finalPrice": number or null,
  "goldPurity": string or null
}

IMPORTANT field definitions for Indian jewellery bills:
- goldRatePerGram: The BASE GOLD RATE per gram. This is the LARGER number (typically 6000-10000 Rs/gm in 2024-2025). Often labeled "Gold Rate", "Rate", "Rate/gm", "Gold Price". This is the market price of gold.
- makingChargesPerGram: Making/wastage/labor charges PER GRAM. This is the SMALLER number (typically 500-3000 Rs/gm). Often labeled "Making", "MC", "Wastage", "VA", "MC/gm", "Making Charges".
- CRITICAL: goldRatePerGram should ALWAYS be larger than makingChargesPerGram. If you see two per-gram rates, the bigger one is goldRatePerGram.
- stoneCost: Cost of stones/diamonds embedded. Often labeled "Stone", "Stone Cost", "Diamond". This is NOT a discount.
- discounts: Actual discounts or offers applied. Only use this for amounts explicitly labeled as "Discount", "Offer", "Less".
- grossPrice: Total price before GST.
- finalPrice: Final amount paid (after GST, after discounts).

Rules:
- Use numbers without currency symbols or commas.
- Dates must be YYYY-MM-DD or null.
- If a value is missing or unreadable, set it to null.
- Do NOT add any extra keys.
- Do NOT include any text before or after the JSON.
"""


@router.post("/upload")
async def upload_bill(file: UploadFile = File(...)) -> JSONResponse:
  content_type = file.content_type or "application/octet-stream"
  print(f"[bills.upload] Received file: name={file.filename}, content_type={content_type}")

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
    result = await client.call_gpt4o_vision(EXTRACTION_PROMPT, data_url)
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
    result = await client.call_gpt4o_vision(EXTRACTION_PROMPT, data_url)
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
