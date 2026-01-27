from fastapi import FastAPI
from fastapi.middleware.cors import CORSMiddleware

from .routes import health, bills, investments


def create_app() -> FastAPI:
  app = FastAPI(title="Investment Tracker API", version="0.1.0")

  # Allow local frontend (Vite) to call this API during development
  app.add_middleware(
    CORSMiddleware,
    allow_origins=[
      "http://localhost:5173",
      "http://127.0.0.1:5173",
    ],
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
  )

  app.include_router(health.router, prefix="/health", tags=["health"])
  app.include_router(bills.router, prefix="/bills", tags=["bills"])
  app.include_router(investments.router, prefix="/investments", tags=["investments"])

  return app


app = create_app()
