import datetime as dt

from fastapi import APIRouter, HTTPException

from ..services import rate_store
from ..services.goodreturns_scraper import fetch_goodreturns_gold_rates


router = APIRouter()


@router.get("/gold/today")
async def gold_today():
  try:
    # cache-per-day in sqlite; scrape if missing
    today = __import__("datetime").date.today().isoformat()
    today_row = rate_store.get_rate_by_date(today)
    if not today_row or today_row.get("inr_per_gram_24k") is None:
      rates = await fetch_goodreturns_gold_rates()
      today_row = rate_store.upsert_daily_rate(
        rates["date"],
        rates["inr_per_gram_24k"],
        rates["inr_per_gram_22k"],
        rates["inr_per_gram_18k"],
        rates["inr_per_gram_14k"],
        rates["inr_per_gram_9k"],
        rates["source"],
        rates["captured_at_ist"],
      )

    return {
      "date": today_row["date"],
      "captured_at_ist": today_row.get("captured_at_ist"),
      "source": today_row.get("source"),
      "inr_per_gram": {
        "24": float(today_row["inr_per_gram_24k"]),
        "22": float(today_row["inr_per_gram_22k"]),
        "18": float(today_row["inr_per_gram_18k"]),
        "14": float(today_row["inr_per_gram_14k"]),
        "9": float(today_row["inr_per_gram_9k"]),
      },
    }
  except Exception as e:
    raise HTTPException(status_code=502, detail=f"Failed to fetch gold rate: {e}")


@router.post("/gold/today/manual")
async def gold_today_manual(payload: dict):
  """Manual override to store today's 10:30am IST snapshot.

  Body example:
  {
    "24": 16195,
    "22": 14845,
    "18": 12146,
    "14": 0,
    "9": 0
  }
  """
  today = dt.date.today().isoformat()
  now_ist = dt.datetime.now(dt.timezone(dt.timedelta(hours=5, minutes=30)))

  def req(k: str) -> float:
    if k not in payload:
      raise HTTPException(status_code=400, detail=f"Missing rate for {k}K")
    try:
      return float(payload[k])
    except Exception:
      raise HTTPException(status_code=400, detail=f"Invalid rate for {k}K")

  r24 = req("24")
  r22 = req("22")
  r18 = req("18")
  r14 = float(payload.get("14", 0))
  r9 = float(payload.get("9", 0))

  row = rate_store.upsert_daily_rate(
    today,
    r24,
    r22,
    r18,
    r14,
    r9,
    "manual",
    now_ist.isoformat(timespec="seconds"),
  )

  return {
    "date": row["date"],
    "captured_at_ist": row.get("captured_at_ist"),
    "source": row.get("source"),
    "inr_per_gram": {
      "24": row["inr_per_gram_24k"],
      "22": row["inr_per_gram_22k"],
      "18": row["inr_per_gram_18k"],
      "14": row["inr_per_gram_14k"],
      "9": row["inr_per_gram_9k"],
    },
  }
