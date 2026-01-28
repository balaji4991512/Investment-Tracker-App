from typing import List, Optional

from fastapi import APIRouter, HTTPException
from pydantic import BaseModel
from datetime import date

from ..services import investment_store


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
