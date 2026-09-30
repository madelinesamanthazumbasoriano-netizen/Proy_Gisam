"""Análisis facial opcional con verificación de cara y suavizado temporal."""
from __future__ import annotations

from collections import deque
from typing import Any
import numpy as np
import config
from pathlib import Path
import cv2
MAPA_EMOCIONES = {
    "angry": "enojo", "disgust": "enojo", "fear": "ansiedad",
    "sad": "tristeza", "happy": "felicidad", "neutral": "neutral",
    # La sorpresa no basta para inferir ansiedad.
    "surprise": "neutral",
}

class AnalizadorRostro:
    def __init__(self, historial: int = 5, umbral: float = 0.65):
        self.historial: deque[tuple[str, float]] = deque(maxlen=historial)
        self.umbral = umbral
        self._clasificador = None
        self._modelo_emocion = None
        
    def analizar(self, frame: Any) -> dict[str, object]:
        salida: dict[str, object] = {
            "emocion": "neutral", "confianza": 0.0, "valida": False,
            "rostro_detectado": False, "fuente": "no_disponible",
        }
        if frame is None:
            return salida
        try:
            import cv2
            gris = cv2.cvtColor(frame, cv2.COLOR_BGR2GRAY)
            if self._clasificador is None:
                ruta_cascade = Path(cv2.__file__).parent / "data" / "haarcascade_frontalface_default.xml"
                self._clasificador = cv2.CascadeClassifier(str(ruta_cascade))
            rostros = self._clasificador.detectMultiScale(gris, scaleFactor=1.1, minNeighbors=6, minSize=(80, 80))
        except Exception:
            return salida
        if len(rostros) != 1:
            salida["fuente"] = "sin_rostro_unico"
            return salida
        salida["rostro_detectado"] = True
        if not config.FACE_EMOTION_MODEL_PATH.is_file():
            salida["fuente"] = "modelo_onnx_local_ausente"
            return salida
        try:
            import cv2
            if self._modelo_emocion is None:
                self._modelo_emocion = cv2.dnn.readNetFromONNX(str(config.FACE_EMOTION_MODEL_PATH))
            x, y, ancho, alto = rostros[0]
            cara = gris[y:y + alto, x:x + ancho]
            blob = cv2.dnn.blobFromImage(cara, scalefactor=1 / 255.0, size=(48, 48), swapRB=False)
            self._modelo_emocion.setInput(blob)
            probabilidades = self._modelo_emocion.forward().reshape(-1)
            probabilidades = np.exp(probabilidades - np.max(probabilidades))
            probabilidades /= probabilidades.sum()
            etiquetas = ("angry", "disgust", "fear", "happy", "sad", "surprise", "neutral")
            indice = int(np.argmax(probabilidades))
            if len(probabilidades) != len(etiquetas):
                salida["fuente"] = "modelo_onnx_incompatible"
                return salida
            dominante, confianza = etiquetas[indice], float(probabilidades[indice])
            emocion = MAPA_EMOCIONES[dominante]
            salida["fuente"] = "onnx_local"
            if confianza >= self.umbral:
                self.historial.append((emocion, confianza))
            if not self.historial:
                return salida
            # Se publica solo la lectura dominante de varias imágenes consecutivas.
            puntajes: dict[str, float] = {}
            for etiqueta, valor in self.historial:
                puntajes[etiqueta] = puntajes.get(etiqueta, 0.0) + valor
            emocion_suave = max(puntajes, key=lambda k: puntajes[k])
            confianza_suave = puntajes[emocion_suave] / len(self.historial)
            salida.update({"emocion": emocion_suave, "confianza": round(confianza_suave, 3), "valida": len(self.historial) >= 3})
        except Exception:
            salida["fuente"] = "modelo_onnx_no_utilizable"
        return salida

_analizador = AnalizadorRostro()

def analizar_rostro(frame: Any) -> dict[str, object]:
    return _analizador.analizar(frame)

def detectar_emocion(frame: Any) -> str:
    return str(analizar_rostro(frame)["emocion"])
