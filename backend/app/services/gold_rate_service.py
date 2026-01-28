import datetime as dt
import os
from dataclasses import dataclass
from typing import Dict, Optional

import httpx


@dataclass
class GoldRates:
  date: str
  inr_per_gram_24k: float


def _grams_per_ounce() -> float:
  return 31.1034768


async def fetch_24k_inr_per_gram() -> GoldRates:
  """Best-effort: fetch XAU->INR from exchangerate.host and convert to INR/gram.

  Notes:
  - Many free FX APIs may not reliably support XAU; treat as best-effort.
  - Requires network access; on failure, raises.
  """
  today = dt.date.today().isoformat()
  url = "https://api.exchangerate.host/latest"
  params = {"base": "XAU", "symbols": "INR"}

  async with httpx.AsyncClient(timeout=20) as client:
    r = await client.get(url, params=params)
    r.raise_for_status()
    data = r.json()
    rate_per_ounce = float(data["rates"]["INR"])  # INR per 1 troy ounce gold
    inr_per_gram = rate_per_ounce / _grams_per_ounce()
    return GoldRates(date=today, inr_per_gram_24k=inr_per_gram)


def convert_24k_to_karat(inr_per_gram_24k: float) -> Dict[int, float]:
  """Simple karat conversion by purity ratio."""
  def r(k: int) -> float:
    return inr_per_gram_24k * (k / 24.0)

  return {
    24: inr_per_gram_24k,
    22: r(22),
    18: r(18),
    14: r(14),
    9: r(9),
  }


def get_scrape_mode_enabled() -> bool:
  return os.getenv("ALLOW_GOLD_WEB_SCRAPE", "false").lower() == "true"
