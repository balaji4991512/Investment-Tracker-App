from typing import List, Optional

from fastapi import APIRouter, HTTPException
from pydantic import BaseModel
from datetime import date

from ..services import investment_store
import os
import shutil
from fastapi import HTTPException


router = APIRouter()


class InvestmentIn(BaseModel):
  bill_id: str
  category: str
  name: str
  vendor: Optional[str] = None
  date: Optional[str] = None  # Accept string, parse later
  total_amount: float
  weight_grams: Optional[float] = None
  purity_karat: Optional[int] = None
  gold_rate_per_gram: Optional[float] = None
  making_charges: Optional[float] = None
  hallmark_charges: Optional[float] = None
  metadata: Optional[dict] = None


class InvestmentOut(BaseModel):
  model_config = {"from_attributes": True}
  
  id: str
  bill_id: str
  category: str
  name: str
  vendor: Optional[str] = None
  date: Optional[date] = None
  total_amount: float
  weight_grams: Optional[float] = None
  purity_karat: Optional[int] = None
  gold_rate_per_gram: Optional[float] = None
  making_charges: Optional[float] = None
  hallmark_charges: Optional[float] = None
  metadata: Optional[dict] = None


@router.get("/")
async def list_investments():
  records = investment_store.list_investments()
  # Convert dates to strings for JSON serialization
  results = []
  for r in records:
    item = dict(r)
    if item.get('date') is not None:
      item['date'] = item['date'].isoformat() if hasattr(item['date'], 'isoformat') else str(item['date'])
    results.append(item)
  return results


@router.post("/")
async def create_investment(payload: InvestmentIn):
  print(f"[investments.create] Received payload: {payload}")
  
  # Normalize empty strings to None for optional fields to avoid 422 issues
  clean_payload = payload.model_dump()
  for key, value in list(clean_payload.items()):
    if value == "":
      clean_payload[key] = None

  print(f"[investments.create] Cleaned payload: {clean_payload}")
  # If a bill was uploaded earlier, move it from temp to final bills directory now that user confirmed save
  bill_id = clean_payload.get('bill_id')
  if bill_id:
    base_dir = os.path.abspath(os.path.join(os.path.dirname(__file__), '..', 'files'))
    temp_dir = os.path.join(base_dir, 'temp_bills')
    final_dir = os.path.join(base_dir, 'bills')
    try:
      os.makedirs(final_dir, exist_ok=True)
    except OSError:
      pass

    # Look for a temp file that starts with bill_id_
    found = None
    if os.path.isdir(temp_dir):
      for fname in os.listdir(temp_dir):
        if fname.startswith(f"{bill_id}_"):
          found = fname
          break

    if found:
      src = os.path.join(temp_dir, found)
      # Original name is after the first underscore
      original_name = found.split('_', 1)[1] if '_' in found else found
      dest = os.path.join(final_dir, original_name)
      if os.path.exists(dest):
        # Conflict: do not overwrite final file
        raise HTTPException(status_code=400, detail=f"A file named {original_name} already exists")
      try:
        shutil.move(src, dest)
        print(f"[investments.create] Moved bill from {src} to {dest}")
      except OSError as e:
        print(f"[investments.create] Failed to move bill file: {e}")
        raise HTTPException(status_code=500, detail="Failed to save uploaded bill file")
  
  stored = investment_store.create_investment(clean_payload)
  print(f"[investments.create] Stored successfully with id: {stored.get('id')}")
  
  # Convert date to string for JSON serialization
  result = dict(stored)
  if result.get('date') is not None:
    result['date'] = result['date'].isoformat() if hasattr(result['date'], 'isoformat') else str(result['date'])
  
  return result


@router.get("/{investment_id}")
async def get_investment(investment_id: str):
  inv = investment_store.get_investment(investment_id)
  if not inv:
    raise HTTPException(status_code=404, detail="Investment not found")
  
  result = dict(inv)
  if result.get('date') is not None:
    result['date'] = result['date'].isoformat() if hasattr(result['date'], 'isoformat') else str(result['date'])
  return result


@router.delete("/{investment_id}")
async def delete_investment(investment_id: str):
  deleted = investment_store.delete_investment(investment_id)
  if not deleted:
    raise HTTPException(status_code=404, detail="Investment not found")
  return {"deleted": True, "id": investment_id}
