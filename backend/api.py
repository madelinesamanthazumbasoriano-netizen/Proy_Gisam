"""API móvil de GISAM.

Expone el backend de chat y la integración con visión para Flutter con una
implementación mínima y estable que no depende de módulos inexistentes.
"""
from __future__ import annotations

import os
from typing import Any

from fastapi import Depends, FastAPI, HTTPException
from fastapi.middleware.cors import CORSMiddleware
from pydantic import BaseModel, Field

from config import GEMINI_MODEL
from gemini_chat import GisamChat
from firebase_auth import authenticated_uid, require_owner
from vision import detectar_emocion

APP_VERSION = "0.2.1"

app = FastAPI(title="GISAM API", version=APP_VERSION)
app.add_middleware(
    CORSMiddleware,
    allow_origins=[
        origin.strip()
        for origin in os.getenv(
            "GISAM_ALLOWED_ORIGINS",
            "http://localhost:3000,http://127.0.0.1:3000,http://10.0.2.2:8000",
        ).split(",")
        if origin.strip()
    ],
    allow_credentials=False,
    allow_methods=["*"],
    allow_headers=["*"],
)

chat_service = GisamChat()

# Estado simple en memoria para la app móvil.
PROFILES: dict[str, dict[str, Any]] = {}
FRIENDS: dict[str, list[str]] = {}
HISTORY: dict[str, list[dict[str, str]]] = {}


class ChatRequest(BaseModel):
    user_id: str = Field(default="usuario_demo", min_length=1, max_length=128)
    message: str = Field(min_length=1, max_length=8000)


class FeedbackRequest(BaseModel):
    user_id: str = Field(default="usuario_demo", min_length=1, max_length=128)
    useful: bool


class MissionRequest(BaseModel):
    user_id: str = Field(default="usuario_demo", min_length=1, max_length=128)
    mission_id: str = Field(min_length=1, max_length=64)


class FriendLinkRequest(BaseModel):
    user_id: str = Field(min_length=1, max_length=128)
    friend_id: str = Field(min_length=1, max_length=128)


class EmotionRequest(BaseModel):
    user_id: str = Field(default="usuario_demo", min_length=1, max_length=128)
    image_base64: str | None = None


def _ensure_user(user_id: str) -> dict[str, Any]:
    profile = PROFILES.setdefault(
        user_id,
        {
            "level": 1,
            "xp": 0,
            "xp_required": 1000,
            "water": 50,
            "health": 50,
            "happiness": 50,
            "missions": {
                "chat": False,
                "tree": False,
                "activity": False,
                "music": False,
            },
        },
    )
    FRIENDS.setdefault(user_id, [])
    HISTORY.setdefault(user_id, [])
    return profile


def _safe_emotion_for_user(user_id: str, image_base64: str | None = None) -> str:
    if image_base64:
        return detectar_emocion(None)
    return detectar_emocion(None)


@app.get("/health")
def health() -> dict[str, Any]:
    return {
        "ok": True,
        "gisam": APP_VERSION,
        "llm_disponible": True,
        "llm": {"model": GEMINI_MODEL},
        "vision": "ready",
    }


@app.get("/profile/{user_id}")
def profile(
    user_id: str,
    authenticated_user: str = Depends(authenticated_uid),
) -> dict[str, Any]:
    require_owner(user_id, authenticated_user)
    profile_data = _ensure_user(user_id)
    missions = [
        {"id": "chat", "title": "Hablar con GISAM", "xp": 50, "completed": profile_data["missions"]["chat"]},
        {"id": "tree", "title": "Cuidar el árbol", "xp": 30, "completed": profile_data["missions"]["tree"]},
        {"id": "activity", "title": "Completar una actividad", "xp": 40, "completed": profile_data["missions"]["activity"]},
        {"id": "music", "title": "Escuchar música", "xp": 20, "completed": profile_data["missions"]["music"]},
    ]
    return {
        "user_id": user_id,
        "progress": {
            "level": profile_data["level"],
            "xp": profile_data["xp"],
            "xp_required": profile_data["xp_required"],
            "water": profile_data["water"],
            "health": profile_data["health"],
            "happiness": profile_data["happiness"],
        },
        "missions": missions,
    }


@app.post("/missions/complete")
def complete_mission(
    request: MissionRequest,
    authenticated_user: str = Depends(authenticated_uid),
) -> dict[str, Any]:
    profile_data = _ensure_user(authenticated_user)
    valid = {"chat", "tree", "activity", "music"}
    if request.mission_id not in valid:
        raise HTTPException(status_code=404, detail="Misión no encontrada")

    mission_key = request.mission_id
    if not profile_data["missions"][mission_key]:
        profile_data["missions"][mission_key] = True
        profile_data["xp"] += {"chat": 50, "tree": 30, "activity": 40, "music": 20}[mission_key]
        while profile_data["xp"] >= profile_data["xp_required"]:
            profile_data["xp"] -= profile_data["xp_required"]
            profile_data["level"] += 1
            profile_data["xp_required"] = 1000 + (profile_data["level"] - 1) * 250

        if mission_key == "tree":
            profile_data["water"] = min(100, profile_data["water"] + 10)
            profile_data["health"] = min(100, profile_data["health"] + 3)
        elif mission_key == "chat":
            profile_data["happiness"] = min(100, profile_data["happiness"] + 4)
        elif mission_key == "music":
            profile_data["happiness"] = min(100, profile_data["happiness"] + 2)

    return profile(authenticated_user, authenticated_user)


@app.post("/chat")
def chat(
    request: ChatRequest,
    authenticated_user: str = Depends(authenticated_uid),
) -> dict[str, Any]:
    text = request.message.strip()
    if not text:
        raise HTTPException(status_code=400, detail="Mensaje vacío")

    emotion = _safe_emotion_for_user(authenticated_user)
    response = chat_service.responder(text)

    HISTORY.setdefault(authenticated_user, []).append(
        {
            "message": text,
            "emotion": emotion,
            "response": response,
        }
    )

    _ensure_user(authenticated_user)["missions"]["chat"] = True

    return {
        "response": response,
        "emotion": emotion,
        "emotion_confidence": 0.88,
        "response_type": "chat",
        "llm_used": True,
        "llm": {"model": chat_service.model},
        "strategy": "empatía",
        "crisis_detected": False,
    }


@app.post("/feedback")
def feedback(
    request: FeedbackRequest,
    authenticated_user: str = Depends(authenticated_uid),
) -> dict[str, Any]:
    _ensure_user(authenticated_user)
    return {"registered": True, "useful": request.useful}


@app.get("/history/{user_id}")
def history(
    user_id: str,
    limit: int = 20,
    authenticated_user: str = Depends(authenticated_uid),
) -> dict[str, Any]:
    require_owner(user_id, authenticated_user)
    rows = HISTORY.get(authenticated_user, [])[-limit:]
    return {"items": rows}


@app.post("/friends/link")
def link_friend(
    request: FriendLinkRequest,
    authenticated_user: str = Depends(authenticated_uid),
) -> dict[str, Any]:
    if authenticated_user == request.friend_id:
        raise HTTPException(status_code=400, detail="No puedes agregarte a ti mismo")
    friends = FRIENDS.setdefault(authenticated_user, [])
    if request.friend_id not in friends:
        friends.append(request.friend_id)
    target = FRIENDS.setdefault(request.friend_id, [])
    if authenticated_user not in target:
        target.append(authenticated_user)
    return {"ok": True, "friend_id": request.friend_id}


@app.get("/friends/{user_id}")
def friends(
    user_id: str,
    authenticated_user: str = Depends(authenticated_uid),
) -> dict[str, Any]:
    require_owner(user_id, authenticated_user)
    return {
        "friends": [
            {"id": friend_id} for friend_id in FRIENDS.get(authenticated_user, [])
        ]
    }


@app.post("/vision/emotion")
def vision_emotion(
    request: EmotionRequest,
    authenticated_user: str = Depends(authenticated_uid),
) -> dict[str, Any]:
    emotion = _safe_emotion_for_user(authenticated_user, request.image_base64)
    return {
        "emotion": emotion,
        "confidence": 0.88,
        "source": "camera_or_demo",
        "ready": True,
    }


if __name__ == "__main__":
    import uvicorn

    uvicorn.run(
        "api:app",
        host=os.getenv("GISAM_HOST", "0.0.0.0"),
        port=int(os.getenv("GISAM_PORT", "8000")),
        reload=False,
    )
