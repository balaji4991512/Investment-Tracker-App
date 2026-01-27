import os
from typing import Any, Dict

import httpx


class OpenAIClient:
  def __init__(self) -> None:
    api_key = os.getenv("OPENAI_API_KEY")
    if not api_key:
      raise RuntimeError("OPENAI_API_KEY is not set in environment")
    self._api_key = api_key
    self._base_url = "https://api.openai.com/v1"

  async def call_gpt4o_vision(self, prompt: str, image_data_url: str) -> Dict[str, Any]:
    """Call GPT-4o-mini in vision mode and return raw response + content string.

    The prompt MUST instruct the model to return only a single JSON object.
    """
    payload = {
      "model": "gpt-4o-mini",
      "messages": [
        {
          "role": "system",
          "content": (
            "You are a JSON extraction expert for Indian jewellery bills. "
            "You must respond with ONE JSON object only, no prose, no markdown, no backticks."
          ),
        },
        {
          "role": "user",
          "content": [
            {"type": "text", "text": prompt},
            {"type": "image_url", "image_url": {"url": image_data_url}},
          ],
        },
      ],
      "temperature": 0,
      "max_completion_tokens": 1200,
    }

    headers = {
      "Authorization": f"Bearer {self._api_key}",
      "Content-Type": "application/json",
    }

    async with httpx.AsyncClient(timeout=60) as client:
      resp = await client.post(f"{self._base_url}/chat/completions", json=payload, headers=headers)
      resp.raise_for_status()
      data = resp.json()
      content = data.get("choices", [{}])[0].get("message", {}).get("content", "")

      # Strip common markdown fences if the model still wrapped the JSON.
      text = content.strip()
      if text.startswith("```json"):
        text = text[len("```json"):]
      elif text.startswith("```"):
        text = text[3:]
      if text.endswith("```"):
        text = text[:-3]
      text = text.strip()

      return {"raw": data, "content": text}
