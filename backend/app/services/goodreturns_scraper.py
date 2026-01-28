import datetime as dt
import re
from typing import Dict

import httpx


GOODRETURNS_URL = "https://www.goodreturns.in/gold-rates/"


def _parse_inr(text: str) -> float:
  # Accept values like "₹7,245" or "7,245"
  digits = re.sub(r"[^0-9.]", "", text)
  return float(digits)


async def fetch_goodreturns_gold_rates() -> Dict[str, object]:
  """Scrape Goodreturns page for per-gram rates for 24K/22K/18K/14K/9K.

  This is best-effort and may break if the site layout changes.
  """
  async with httpx.AsyncClient(timeout=20, headers={"User-Agent": "Mozilla/5.0"}) as client:
    r = await client.get(GOODRETURNS_URL)
    r.raise_for_status()
    html = r.text

  # Extremely simple patterns; adjust if Goodreturns changes markup.
  def find_rate(label: str) -> float:
    # Look for e.g. "24K" then the next currency-like token.
    m = re.search(label + r"[\s\S]{0,300}?(₹\s?[0-9,]+(?:\.[0-9]+)?)", html, re.IGNORECASE)
    if not m:
      raise ValueError(f"Could not find rate for {label}")
    return _parse_inr(m.group(1))

  # Goodreturns commonly shows per-gram for these karats.
  r24 = find_rate("24K")
  r22 = find_rate("22K")
  r18 = find_rate("18K")
  r14 = find_rate("14K")
  r9 = find_rate("9K")

  now_ist = dt.datetime.now(dt.timezone(dt.timedelta(hours=5, minutes=30)))
  return {
    "date": now_ist.date().isoformat(),
    "captured_at_ist": now_ist.isoformat(timespec="seconds"),
    "source": GOODRETURNS_URL,
    "inr_per_gram_24k": r24,
    "inr_per_gram_22k": r22,
    "inr_per_gram_18k": r18,
    "inr_per_gram_14k": r14,
    "inr_per_gram_9k": r9,
  }
