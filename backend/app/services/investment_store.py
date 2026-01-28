import json
import os
import sqlite3
import uuid
import json
from datetime import date
from typing import Any, Dict, List, Optional


DB_DIR = os.path.abspath(os.path.join(os.path.dirname(__file__), "..", "db"))
DB_PATH = os.path.join(DB_DIR, "investments.db")


def _ensure_db() -> None:
  os.makedirs(DB_DIR, exist_ok=True)


def init_db() -> None:
  _ensure_db()
  conn = sqlite3.connect(DB_PATH)
  try:
    conn.execute(
      """
      CREATE TABLE IF NOT EXISTS investments (
        id TEXT PRIMARY KEY,
        bill_id TEXT,
        category TEXT,
        name TEXT,
        vendor TEXT,
        date TEXT,
        total_amount REAL NOT NULL,
        weight_grams REAL,
        purity_karat INTEGER,
        gold_rate_per_gram REAL,
        making_charges REAL,
        hallmark_charges REAL,
        metadata TEXT
      )
      """
    )
    # Add hallmark_charges column if it doesn't exist (backward compatibility)
    try:
      conn.execute("ALTER TABLE investments ADD COLUMN hallmark_charges REAL")
    except sqlite3.OperationalError:
      pass  # Column already exists
    conn.commit()
  finally:
    conn.close()


def _row_to_dict(row: sqlite3.Row) -> Dict[str, Any]:
  metadata_val = row["metadata"]
  try:
    metadata = json.loads(metadata_val) if metadata_val else None
  except json.JSONDecodeError:
    metadata = None

  date_val = row["date"]
  parsed_date: Optional[date] = None
  if date_val:
    try:
      parsed_date = date.fromisoformat(date_val)
    except ValueError:
      parsed_date = None

  return {
    "id": row["id"],
    "bill_id": row["bill_id"],
    "category": row["category"],
    "name": row["name"],
    "vendor": row["vendor"],
    "date": parsed_date,
    "total_amount": row["total_amount"],
    "weight_grams": row["weight_grams"],
    "purity_karat": row["purity_karat"],
    "gold_rate_per_gram": row["gold_rate_per_gram"],
    "making_charges": row["making_charges"],
    "hallmark_charges": row["hallmark_charges"] if "hallmark_charges" in row.keys() else None,
    "metadata": metadata,
  }


def list_investments() -> List[Dict[str, Any]]:
  conn = sqlite3.connect(DB_PATH)
  conn.row_factory = sqlite3.Row
  try:
    rows = conn.execute("SELECT * FROM investments ORDER BY rowid DESC").fetchall()
    return [_row_to_dict(r) for r in rows]
  finally:
    conn.close()


def get_investment(investment_id: str) -> Optional[Dict[str, Any]]:
  conn = sqlite3.connect(DB_PATH)
  conn.row_factory = sqlite3.Row
  try:
    row = conn.execute("SELECT * FROM investments WHERE id = ?", (investment_id,)).fetchone()
    return _row_to_dict(row) if row else None
  finally:
    conn.close()


def delete_investment(investment_id: str) -> bool:
  conn = sqlite3.connect(DB_PATH)
  try:
    cur = conn.execute("DELETE FROM investments WHERE id = ?", (investment_id,))
    conn.commit()
    return cur.rowcount > 0
  finally:
    conn.close()


def create_investment(payload: Dict[str, Any]) -> Dict[str, Any]:
  inv_id = str(uuid.uuid4())
  metadata_json = json.dumps(payload.get("metadata")) if payload.get("metadata") is not None else None
  date_val = payload.get("date")
  if isinstance(date_val, date):
    date_str = date_val.isoformat()
  else:
    date_str = date_val if date_val else None

  conn = sqlite3.connect(DB_PATH)
  try:
    conn.execute(
      """
      INSERT INTO investments (
        id, bill_id, category, name, vendor, date, total_amount,
        weight_grams, purity_karat, gold_rate_per_gram, making_charges, hallmark_charges, metadata
      ) VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?)
      """,
      (
        inv_id,
        payload.get("bill_id"),
        payload.get("category"),
        payload.get("name"),
        payload.get("vendor"),
        date_str,
        payload.get("total_amount"),
        payload.get("weight_grams"),
        payload.get("purity_karat"),
        payload.get("gold_rate_per_gram"),
        payload.get("making_charges"),
        payload.get("hallmark_charges"),
        metadata_json,
      ),
    )
    conn.commit()
  finally:
    conn.close()

  # Return freshly stored object
  stored = get_investment(inv_id)
  return stored if stored else {
    "id": inv_id,
    **payload,
  }


# Initialize DB on import
init_db()
