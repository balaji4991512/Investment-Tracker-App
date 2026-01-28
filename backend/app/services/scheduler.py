import asyncio
import datetime as dt

from .goodreturns_scraper import fetch_goodreturns_gold_rates
from . import rate_store


IST = dt.timezone(dt.timedelta(hours=5, minutes=30))


async def _run_once() -> None:
  rates = await fetch_goodreturns_gold_rates()
  rate_store.upsert_daily_rate(
    rates["date"],
    rates["inr_per_gram_24k"],
    rates["inr_per_gram_22k"],
    rates["inr_per_gram_18k"],
    rates["inr_per_gram_14k"],
    rates["inr_per_gram_9k"],
    rates["source"],
    rates["captured_at_ist"],
  )


def _seconds_until_next_1030_ist(now: dt.datetime) -> float:
  now_ist = now.astimezone(IST)
  target = now_ist.replace(hour=10, minute=30, second=0, microsecond=0)
  if now_ist >= target:
    target = target + dt.timedelta(days=1)
  return (target - now_ist).total_seconds()


async def run_daily_1030_job() -> None:
  while True:
    wait_s = _seconds_until_next_1030_ist(dt.datetime.now(tz=dt.timezone.utc))
    await asyncio.sleep(wait_s)
    try:
      await _run_once()
      print("[scheduler] stored daily gold rates snapshot")
    except Exception as e:
      print(f"[scheduler] failed to store daily gold rates: {e}")
