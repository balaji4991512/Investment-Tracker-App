import datetime as dt
import os
import sqlite3
from typing import Any, Dict, Optional


DB_DIR = os.path.abspath(os.path.join(os.path.dirname(__file__), "..", "db"))
DB_PATH = os.path.join(DB_DIR, "investments.db")


def init_rates_table() -> None:
  os.makedirs(DB_DIR, exist_ok=True)
  conn = sqlite3.connect(DB_PATH)
  try:
    conn.execute(
      """
      CREATE TABLE IF NOT EXISTS daily_gold_rates (
        date TEXT PRIMARY KEY,
        inr_per_gram_24k REAL,
        inr_per_gram_22k REAL,
        inr_per_gram_18k REAL,
        inr_per_gram_14k REAL,
        inr_per_gram_9k REAL,
        source TEXT,
        captured_at_ist TEXT
      )
      """
    )
    # Back-compat: add columns if the table existed previously.
    for col, typ in [
      ("inr_per_gram_22k", "REAL"),
      ("inr_per_gram_18k", "REAL"),
      ("inr_per_gram_14k", "REAL"),
      ("inr_per_gram_9k", "REAL"),
      ("source", "TEXT"),
      ("captured_at_ist", "TEXT"),
    ]:
      try:
        conn.execute(f"ALTER TABLE daily_gold_rates ADD COLUMN {col} {typ}")
      except sqlite3.OperationalError:
        pass
    conn.commit()
  finally:
    conn.close()


def upsert_daily_rate(
  date: str,
  inr_per_gram_24k: float,
  inr_per_gram_22k: float,
  inr_per_gram_18k: float,
  inr_per_gram_14k: float,
  inr_per_gram_9k: float,
  source: str,
  captured_at_ist: str,
) -> Dict[str, Any]:
  conn = sqlite3.connect(DB_PATH)
  try:
    conn.execute(
      """
      INSERT INTO daily_gold_rates (
        date,
        inr_per_gram_24k,
        inr_per_gram_22k,
        inr_per_gram_18k,
        inr_per_gram_14k,
        inr_per_gram_9k,
        source,
        captured_at_ist
      )
      VALUES (?, ?, ?, ?, ?, ?, ?, ?)
      ON CONFLICT(date) DO UPDATE SET
        inr_per_gram_24k=excluded.inr_per_gram_24k,
        inr_per_gram_22k=excluded.inr_per_gram_22k,
        inr_per_gram_18k=excluded.inr_per_gram_18k,
        inr_per_gram_14k=excluded.inr_per_gram_14k,
        inr_per_gram_9k=excluded.inr_per_gram_9k,
        source=excluded.source,
        captured_at_ist=excluded.captured_at_ist
      """,
      (
        date,
        float(inr_per_gram_24k),
        float(inr_per_gram_22k),
        float(inr_per_gram_18k),
        float(inr_per_gram_14k),
        float(inr_per_gram_9k),
        source,
        captured_at_ist,
      ),
    )
    conn.commit()
  finally:
    conn.close()
  return {
    "date": date,
    "inr_per_gram_24k": float(inr_per_gram_24k),
    "inr_per_gram_22k": float(inr_per_gram_22k),
    "inr_per_gram_18k": float(inr_per_gram_18k),
    "inr_per_gram_14k": float(inr_per_gram_14k),
    "inr_per_gram_9k": float(inr_per_gram_9k),
    "source": source,
    "captured_at_ist": captured_at_ist,
  }


def get_rate_by_date(date: str) -> Optional[Dict[str, Any]]:
  conn = sqlite3.connect(DB_PATH)
  conn.row_factory = sqlite3.Row
  try:
    row = conn.execute("SELECT * FROM daily_gold_rates WHERE date = ?", (date,)).fetchone()
    return dict(row) if row else None
  finally:
    conn.close()


def get_latest_rate() -> Optional[Dict[str, Any]]:
  conn = sqlite3.connect(DB_PATH)
  conn.row_factory = sqlite3.Row
  try:
    row = conn.execute("SELECT * FROM daily_gold_rates ORDER BY date DESC LIMIT 1").fetchone()
    return dict(row) if row else None
  finally:
    conn.close()


def get_or_fetch_today(fetch_fn) -> Dict[str, Any]:
  """Fetch function returns dict: date, inr_per_gram_{24k,22k,18k,14k,9k}, source, captured_at_ist."""
  today = dt.date.today().isoformat()
  existing = get_rate_by_date(today)
  if existing and existing.get("inr_per_gram_24k") is not None:
    return existing

  rates = fetch_fn()
  return upsert_daily_rate(
    rates["date"],
    rates["inr_per_gram_24k"],
    rates["inr_per_gram_22k"],
    rates["inr_per_gram_18k"],
    rates["inr_per_gram_14k"],
    rates["inr_per_gram_9k"],
    rates["source"],
    rates["captured_at_ist"],
  )


def get_all_rates_desc():
  """Return all daily rates in descending order by date."""
  conn = sqlite3.connect(DB_PATH)
  conn.row_factory = sqlite3.Row
  try:
    rows = conn.execute("SELECT * FROM daily_gold_rates ORDER BY date DESC").fetchall()
    return [dict(row) for row in rows]
  finally:
    conn.close()


init_rates_table()
