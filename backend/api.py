"""API móvil de GISAM.

Expone el motor híbrido a Flutter sin mezclar la lógica de UI con el motor de IA.
"""
from __future__ import annotations

import os
import sqlite3
from pathlib import Path
from typing import Any

from fastapi import FastAPI, HTTPException, Header
from fastapi.middleware.cors import CORSMiddleware
from pydantic import BaseModel, Field

import config
from security_stage11 import SecurityMiddleware, validate_runtime_security, authorize_subject
from core.pipeline import ejecutar_hibrido
from models.dl_modelo import cargar_modelo_dl
from models.ml_modelo import cargar_modelo_ml
from services.memoria import guardar, obtener_historial
from db.health import database_health
from Interaccion.personalidad import actualizar_personalidad, modular_respuesta
from Conocimiento_Datos.aprendizaje_social import registrar_respuesta, mejor_estrategia
from api_llm import generar_con_llm, llm_configuracion, llm_disponible
from Conocimiento_Datos.aprendizaje_autonomo import (
    detener_aprendizaje_autonomo,
    estado_automatizacion,
    iniciar_aprendizaje_autonomo,
)

APP_VERSION = "0.2.0"

validate_runtime_security()
app = FastAPI(title="GISAM API", version=APP_VERSION)
app.add_middleware(SecurityMiddleware)

app.add_middleware(
    CORSMiddleware,
    allow_origins=[o.strip() for o in os.getenv("GISAM_ALLOWED_ORIGINS", "http://localhost:3000").split(",") if o.strip()],
    allow_credentials=False,
    allow_methods=["*"],
    allow_headers=["*"],
)

modelo_dl = cargar_modelo_dl()
modelo_ml = cargar_modelo_ml()


class ChatRequest(BaseModel):
    user_id: str = Field(default="usuario_1", min_length=1, max_length=128)
    message: str = Field(min_length=1, max_length=8000)


class FeedbackRequest(BaseModel):
    user_id: str = Field(default="usuario_1", min_length=1, max_length=128)
    useful: bool


class MissionRequest(BaseModel):
    user_id: str = Field(default="usuario_1", min_length=1, max_length=128)
    mission_id: str = Field(min_length=1, max_length=64)


class FriendLinkRequest(BaseModel):
    user_id: str = Field(min_length=1, max_length=128)
    friend_id: str = Field(min_length=1, max_length=128)


def _db() -> sqlite3.Connection:
    db = sqlite3.connect(config.DB_PATH, timeout=10)
    db.execute("PRAGMA busy_timeout = 10000")
    return db


def inicializar_api_db() -> None:
    config.DB_PATH.parent.mkdir(parents=True, exist_ok=True)
    with _db() as db:
        db.execute("""
            CREATE TABLE IF NOT EXISTS progreso_usuario (
                usuario_id TEXT PRIMARY KEY,
                nivel INTEGER NOT NULL DEFAULT 1,
                xp INTEGER NOT NULL DEFAULT 0,
                xp_requerida INTEGER NOT NULL DEFAULT 1000,
                agua INTEGER NOT NULL DEFAULT 50,
                salud INTEGER NOT NULL DEFAULT 50,
                felicidad INTEGER NOT NULL DEFAULT 50,
                actualizado_en TEXT NOT NULL DEFAULT CURRENT_TIMESTAMP
            )
        """)
        db.execute("""
            CREATE TABLE IF NOT EXISTS misiones_usuario (
                usuario_id TEXT NOT NULL,
                mision_id TEXT NOT NULL,
                completada INTEGER NOT NULL DEFAULT 0,
                PRIMARY KEY (usuario_id, mision_id)
            )
        """)
        db.execute("""
            CREATE TABLE IF NOT EXISTS amistades (
                usuario_id TEXT NOT NULL,
                amigo_id TEXT NOT NULL,
                creado_en TEXT NOT NULL DEFAULT CURRENT_TIMESTAMP,
                PRIMARY KEY (usuario_id, amigo_id)
            )
        """)


@app.on_event("startup")
def startup() -> None:
    inicializar_api_db()
    iniciar_aprendizaje_autonomo()


@app.on_event("shutdown")
def shutdown() -> None:
    detener_aprendizaje_autonomo()


@app.get("/health/db")
def health_db() -> dict[str, Any]:
    return database_health()


@app.get("/health")
def health() -> dict[str, Any]:
    return {
        "ok": True,
        "gisam": APP_VERSION,
        "llm_disponible": llm_disponible(),
        "llm": llm_configuracion(),
        "automation": estado_automatizacion(),
        "ml_entrenado": bool(getattr(modelo_ml, "entrenado", False)),
        "dl_entrenado": bool(getattr(modelo_dl, "entrenado", False)),
    }


@app.get("/profile/{user_id}")
def profile(user_id: str, authorization: str | None = Header(default=None)) -> dict[str, Any]:
    authorize_subject(user_id, authorization)
    with _db() as db:
        row = db.execute(
            """SELECT nivel, xp, xp_requerida, agua, salud, felicidad
               FROM progreso_usuario WHERE usuario_id=?""",
            (user_id,),
        ).fetchone()
        if row is None:
            db.execute(
                "INSERT INTO progreso_usuario(usuario_id) VALUES (?)",
                (user_id,),
            )
            row = (1, 0, 1000, 50, 50, 50)

    missions = [
        {"id": "chat", "title": "Hablar con GISAM", "xp": 50},
        {"id": "tree", "title": "Cuidar el árbol", "xp": 30},
        {"id": "activity", "title": "Completar una actividad", "xp": 40},
        {"id": "music", "title": "Escuchar música", "xp": 20},
    ]
    with _db() as db:
        done = {
            r[0] for r in db.execute(
                "SELECT mision_id FROM misiones_usuario WHERE usuario_id=? AND completada=1",
                (user_id,),
            ).fetchall()
        }
    for mission in missions:
        mission["completed"] = mission["id"] in done

    return {
        "user_id": user_id,
        "progress": {
            "level": row[0],
            "xp": row[1],
            "xp_required": row[2],
            "water": row[3],
            "health": row[4],
            "happiness": row[5],
        },
        "missions": missions,
    }


@app.post("/missions/complete")
def complete_mission(request: MissionRequest, authorization: str | None = Header(default=None)) -> dict[str, Any]:
    authorize_subject(request.user_id, authorization)
    valid = {
        "chat": ("Hablar con GISAM", 50),
        "tree": ("Cuidar el árbol", 30),
        "activity": ("Completar una actividad", 40),
        "music": ("Escuchar música", 20),
    }
    if request.mission_id not in valid:
        raise HTTPException(status_code=404, detail="Misión no encontrada")

    with _db() as db:
        db.execute("INSERT OR IGNORE INTO progreso_usuario(usuario_id) VALUES (?)", (request.user_id,))
        already = db.execute(
            "SELECT completada FROM misiones_usuario WHERE usuario_id=? AND mision_id=?",
            (request.user_id, request.mission_id),
        ).fetchone()
        if already and already[0]:
            return profile(request.user_id)

        db.execute(
            """INSERT INTO misiones_usuario(usuario_id, mision_id, completada)
               VALUES (?, ?, 1)
               ON CONFLICT(usuario_id, mision_id) DO UPDATE SET completada=1""",
            (request.user_id, request.mission_id),
        )

        nivel, xp, req, agua, salud, felicidad = db.execute(
            """SELECT nivel, xp, xp_requerida, agua, salud, felicidad
               FROM progreso_usuario WHERE usuario_id=?""",
            (request.user_id,),
        ).fetchone()

        xp += valid[request.mission_id][1]
        while xp >= req:
            xp -= req
            nivel += 1
            req = 1000 + (nivel - 1) * 250

        if request.mission_id == "tree":
            agua = min(100, agua + 10)
            salud = min(100, salud + 3)
        elif request.mission_id == "chat":
            felicidad = min(100, felicidad + 4)
        elif request.mission_id == "music":
            felicidad = min(100, felicidad + 2)

        db.execute(
            """UPDATE progreso_usuario
               SET nivel=?, xp=?, xp_requerida=?, agua=?, salud=?, felicidad=?,
                   actualizado_en=CURRENT_TIMESTAMP
               WHERE usuario_id=?""",
            (nivel, xp, req, agua, salud, felicidad, request.user_id),
        )

    return profile(request.user_id)


@app.post("/chat")
def chat(request: ChatRequest, authorization: str | None = Header(default=None)) -> dict[str, Any]:
    authorize_subject(request.user_id, authorization)
    global modelo_dl, modelo_ml

    texto = request.message.strip()
    if not texto:
        raise HTTPException(status_code=400, detail="Mensaje vacío")

    historial_raw = obtener_historial(request.user_id, limite=8)
    historial = [
        {"texto": mensaje, "emocion": emocion, "respuesta": respuesta}
        for mensaje, emocion, respuesta in reversed(historial_raw)
    ]

    resultado = ejecutar_hibrido(
        texto,
        modelo_dl,
        modelo_ml,
        logger=None,
    )

    actualizar_personalidad(resultado.emocion)

    # Primero se conserva la barrera de seguridad del sistema base.
    respuesta = resultado.respuesta
    crisis = any(
        phrase in texto.casefold()
        for phrase in (
            "me voy a matar",
            "quiero suicidarme",
            "quitarme la vida",
            "voy a hacerme daño",
            "quiero morir",
            "no quiero vivir",
        )
    )

    if not crisis:
        generada = generar_con_llm(
            texto=texto,
            emocion=resultado.emocion,
            contexto=historial,
        )
        if generada:
            respuesta = generada

    respuesta = modular_respuesta(respuesta)
    estrategia = mejor_estrategia(resultado.emocion)
    registrar_respuesta(resultado.emocion, estrategia)

    guardar(
        texto=texto,
        emocion=resultado.emocion,
        cognicion="interaccion_movil",
        tipo=resultado.tipo_respuesta,
        respuesta=respuesta,
        usuario=request.user_id,
    )

    # Hablar con GISAM es una misión de progreso. La API evita duplicarla.
    complete_mission(
        MissionRequest(user_id=request.user_id, mission_id="chat")
    )

    return {
        "response": respuesta,
        "emotion": resultado.emocion,
        "emotion_confidence": resultado.confianza_emocion,
        "response_type": resultado.tipo_respuesta,
        "ml": resultado.prediccion_ml.tolist(),
        "dl": resultado.prediccion_dl.tolist(),
        "final": resultado.prediccion_final.tolist(),
        "llm_used": bool(generada) if not crisis else False,
        "llm": llm_configuracion(),
        "strategy": estrategia,
        "crisis_detected": crisis,
    }


@app.post("/feedback")
def feedback(request: FeedbackRequest, authorization: str | None = Header(default=None)) -> dict[str, Any]:
    authorize_subject(request.user_id, authorization)
    from Conocimiento_Datos.aprendizaje_social import registrar_feedback
    ok = registrar_feedback(request.useful)
    return {"registered": ok}


@app.get("/history/{user_id}")
def history(user_id: str, limit: int = 20, authorization: str | None = Header(default=None)) -> dict[str, Any]:
    authorize_subject(user_id, authorization)
    limit = max(1, min(50, limit))
    rows = obtener_historial(user_id, limite=limit)
    return {
        "items": [
            {"message": m, "emotion": e, "response": r}
            for m, e, r in reversed(rows)
        ]
    }


@app.post("/friends/link")
def link_friend(request: FriendLinkRequest, authorization: str | None = Header(default=None)) -> dict[str, Any]:
    authorize_subject(request.user_id, authorization)
    if request.user_id == request.friend_id:
        raise HTTPException(status_code=400, detail="No puedes agregarte a ti mismo")

    with _db() as db:
        db.execute(
            "INSERT OR IGNORE INTO amistades(usuario_id, amigo_id) VALUES (?, ?)",
            (request.user_id, request.friend_id),
        )
        db.execute(
            "INSERT OR IGNORE INTO amistades(usuario_id, amigo_id) VALUES (?, ?)",
            (request.friend_id, request.user_id),
        )
    return {"ok": True, "friend_id": request.friend_id}


@app.get("/friends/{user_id}")
def friends(user_id: str, authorization: str | None = Header(default=None)) -> dict[str, Any]:
    authorize_subject(user_id, authorization)
    with _db() as db:
        rows = db.execute(
            "SELECT amigo_id, creado_en FROM amistades WHERE usuario_id=? ORDER BY creado_en DESC",
            (user_id,),
        ).fetchall()
    return {"friends": [{"id": r[0], "created_at": r[1]} for r in rows]}


if __name__ == "__main__":
    import uvicorn
    uvicorn.run("api:app", host=os.getenv("GISAM_HOST", "0.0.0.0"),
                port=int(os.getenv("GISAM_PORT", "8000")), reload=False)
