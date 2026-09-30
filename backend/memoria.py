import sqlite3
from numpy.typing import NDArray
from typing import Any, cast
import config
import numpy as np
import json
import hashlib
from numpy.linalg import norm

# ======================
# MODELO (se carga una vez)
# ======================
_modelo_embed = None

def get_modelo():
    global _modelo_embed
    if _modelo_embed is None:
        if not config.EMBEDDING_MODEL_PATH.is_dir():
            return None
        try:
            from sentence_transformers import SentenceTransformer
        except ImportError:
            return None
        _modelo_embed = SentenceTransformer(str(config.EMBEDDING_MODEL_PATH), local_files_only=True)
    return _modelo_embed

def obtener_embedding(texto: str) -> NDArray[np.float32]:
    modelo = get_modelo()

    if modelo is not None:
        modelo: Any = get_modelo()
        embedding = np.asarray(
            modelo.encode(
                texto,
                convert_to_numpy=True,
                convert_to_tensor=False,
            ),
            dtype=np.float32,
        )
        return embedding

    vector: NDArray[np.float32] = np.zeros(
        128,
        dtype=np.float32,
    )

    for palabra in texto.lower().split():
        indice = (
            int(hashlib.sha256(palabra.encode("utf-8")).hexdigest(), 16)
            % len(vector)
        )
        vector[indice] += 1.0

    return vector


# ======================
# UTILIDADES
# ======================
def similitud(a: NDArray[np.float32], b: NDArray[np.float32]) -> float:
    denom = (norm(a) * norm(b))
    if denom == 0:
        return 0
    return np.dot(a, b) / denom





def conectar():
    crear_directorio = config.DB_PATH.parent
    crear_directorio.mkdir(parents=True, exist_ok=True)
    db = sqlite3.connect(config.DB_PATH, timeout=10)
    db.execute("PRAGMA busy_timeout = 10000")
    return db


# ======================
# CREAR TABLA
# ======================
def crear_tabla():
    db = conectar()
    cursor = db.cursor()

    cursor.execute("""
    CREATE TABLE IF NOT EXISTS memoria (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        texto_usuario TEXT,
        usuario_id TEXT DEFAULT 'default',
        emocion TEXT,
        cognicion TEXT,
        tipo_respuesta INTEGER,
        respuesta TEXT,
        confianza REAL DEFAULT 0.5,
        veces_usado INTEGER DEFAULT 0,
        embedding TEXT
    )
    """)

    columnas = {fila[1] for fila in cursor.execute("PRAGMA table_info(memoria)")}
    if "usuario_id" not in columnas:
        cursor.execute("ALTER TABLE memoria ADD COLUMN usuario_id TEXT DEFAULT 'default'")

    db.commit()
    db.close()


# ======================
# GUARDAR MEMORIA
# ======================
def guardar(
    texto: str,
    emocion: str,
    cognicion: str,
    tipo: int,
    respuesta: str,
    usuario: str = "default",
) -> None:
    crear_tabla()

    db = conectar()
    cursor = db.cursor()

    embedding = obtener_embedding(texto).tolist()

    parametros: tuple[
        str,
        str,
        str,
        str,
        int,
        str,
        str,
    ] = (
        texto,
        usuario,
        emocion,
        cognicion,
        tipo,
        respuesta,
        json.dumps(embedding),
    )

    cursor.execute(
        """
        INSERT INTO memoria
        (
            texto_usuario,
            usuario_id,
            emocion,
            cognicion,
            tipo_respuesta,
            respuesta,
            embedding
        )
        VALUES (?, ?, ?, ?, ?, ?, ?)
        """,
        parametros,
    )

    db.commit()
    db.close()


# ======================
# BÚSQUEDA SEMÁNTICA
# ======================
def buscar_similar(texto: str, umbral: float = 0.7):
    crear_tabla()
    db = conectar()
    cursor = db.cursor()

    emb_nuevo = obtener_embedding(texto)

    cursor.execute("""
    SELECT respuesta, embedding, veces_usado
    FROM memoria
    ORDER BY id DESC
    LIMIT 100
    """)

    datos = cursor.fetchall()

    mejor_score = 0
    mejor_respuesta = None

    for respuesta, emb_str, uso in datos:
        try:
            emb_guardado = np.asarray(json.loads(emb_str), dtype=float)
        except (TypeError, ValueError, json.JSONDecodeError):
            continue
        # Un cambio de modelo puede producir embeddings de otra dimensión.
        if emb_guardado.shape != np.asarray(emb_nuevo).shape:
            continue

        score = similitud(emb_nuevo, emb_guardado)

        # memoria reforzada
        score += uso * 0.01

        if score > mejor_score and score > umbral:
            mejor_score = score
            mejor_respuesta = respuesta

    db.close()
    return mejor_respuesta


# ======================
# MEMORIA POR EMOCIÓN
# ======================
def buscar_por_emocion(emocion: str):
    crear_tabla()
    db = conectar()
    cursor = db.cursor()

    cursor.execute("""
    SELECT respuesta FROM memoria
    WHERE emocion = ?
    ORDER BY veces_usado DESC
    LIMIT 1
    """, (emocion,))

    r = cursor.fetchone()
    db.close()
    return r[0] if r else None


# ======================
# REFUERZO (aprendizaje)
# ======================
def incrementar_uso(respuesta: str):
    crear_tabla()
    db = conectar()
    cursor = db.cursor()

    cursor.execute("""
    UPDATE memoria
    SET veces_usado = veces_usado + 1
    WHERE respuesta = ?
    """, (respuesta,))

    db.commit()
    db.close()


# ======================
# DATASET PARA ML
# ======================
def cargar_datos():
    crear_tabla()
    db = conectar()
    cursor = db.cursor()

    cursor.execute("""
    SELECT texto_usuario, emocion, cognicion, tipo_respuesta
    FROM memoria
    """)

    datos = cursor.fetchall()
    db.close()
    return datos
def obtener_historial(
    usuario: str | None = None,
    limite: int = 20,
) -> list[tuple[str, str, str]]:
    crear_tabla()

    db = conectar()
    cursor = db.cursor()

    if usuario is not None:
        parametros: tuple[str, int] = (usuario, limite)

        cursor.execute(
            """
            SELECT texto_usuario, emocion, respuesta
            FROM memoria
            WHERE usuario_id = ?
            ORDER BY id DESC
            LIMIT ?
            """,
            parametros,
        )
    else:
        parametros2: tuple[int] = (limite,)

        cursor.execute(
            """
            SELECT texto_usuario, emocion, respuesta
            FROM memoria
            ORDER BY id DESC
            LIMIT ?
            """,
            parametros2,
        )

    datos = cast(
        list[tuple[str, str, str]],
        cursor.fetchall(),
    )

    db.close()

    return datos