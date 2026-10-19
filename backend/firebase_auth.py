"""Firebase ID-token verification for authenticated mobile API requests."""

from __future__ import annotations

import logging
import os

from fastapi import Depends, HTTPException
from fastapi.security import HTTPAuthorizationCredentials, HTTPBearer

logger = logging.getLogger(__name__)
bearer = HTTPBearer(auto_error=False)


def authenticated_uid(
    credentials: HTTPAuthorizationCredentials | None = Depends(bearer),
) -> str:
    if credentials is None or credentials.scheme.lower() != "bearer":
        raise HTTPException(status_code=401, detail="Se requiere autenticación")

    try:
        import firebase_admin
        from firebase_admin import auth
    except ImportError as error:
        logger.exception("firebase-admin no está instalado")
        raise HTTPException(
            status_code=503,
            detail="La verificación de Firebase no está disponible",
        ) from error

    try:
        try:
            firebase_admin.get_app()
        except ValueError:
            options = {}
            project_id = os.getenv("FIREBASE_PROJECT_ID")
            if project_id:
                options["projectId"] = project_id
            firebase_admin.initialize_app(options=options or None)
    except Exception as error:
        logger.exception("No se pudo inicializar Firebase Admin")
        raise HTTPException(
            status_code=503,
            detail="Configura credenciales de Firebase Admin en el servidor",
        ) from error

    try:
        decoded = auth.verify_id_token(credentials.credentials)
    except Exception as error:
        raise HTTPException(status_code=401, detail="Token de Firebase inválido") from error

    uid = decoded.get("uid")
    if not isinstance(uid, str) or not uid:
        raise HTTPException(status_code=401, detail="Token sin identificador válido")
    return uid


def require_owner(requested_uid: str, authenticated_user: str) -> None:
    if requested_uid != authenticated_user:
        raise HTTPException(status_code=403, detail="No puedes acceder a otra cuenta")
