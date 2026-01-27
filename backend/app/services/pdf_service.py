from typing import Optional

import fitz  # PyMuPDF


def pdf_first_page_to_png_bytes(pdf_bytes: bytes) -> Optional[bytes]:
  """Render the first page of a PDF (from bytes) to PNG bytes.

  Returns None if the PDF has no pages or cannot be rendered.
  """
  try:
    with fitz.open(stream=pdf_bytes, filetype="pdf") as doc:
      if doc.page_count == 0:
        return None
      page = doc.load_page(0)
      pix = page.get_pixmap(dpi=200)
      return pix.tobytes("png")
  except Exception:
    return None
