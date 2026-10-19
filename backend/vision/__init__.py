
"""Análisis facial opcional con ONNX Runtime y suavizado temporal."""
from __future__ import annotations

from collections import deque
from pathlib import Path
from typing import Any

import numpy as np
import config


MAPA_EMOCIONES = {
    "angry": "enojo",
    "disgust": "enojo",
    "fear": "ansiedad",
    "happy": "felicidad",
    "sad": "tristeza",
    "surprise": "neutral",
    "neutral": "neutral",
}

ETIQUETAS_EMOCIONES = (
    "angry",
    "disgust",
    "fear",
    "happy",
    "sad",
    "surprise",
    "neutral",
)


class AnalizadorRostro:
    def __init__(self, historial: int = 5, umbral: float = 0.65):
        self.historial: deque[tuple[str, float]] = deque(
            maxlen=historial
        )
        self.umbral = umbral
        self._clasificador: Any = None
        self._modelo_emocion: Any = None
        self._nombre_entrada: str | None = None

    def _cargar_modelo(self) -> None:
        """Carga ONNX Runtime y el detector facial de OpenCV."""
        import cv2
        import onnxruntime as ort

        ruta_cascade = (
            Path(cv2.__file__).parent
            / "data"
            / "haarcascade_frontalface_default.xml"
        )
        clasificador = cv2.CascadeClassifier(str(ruta_cascade))

        if clasificador.empty():
            raise RuntimeError("No se pudo cargar el detector facial Haar.")

        ruta_modelo = config.FACE_EMOTION_MODEL_PATH
        if not ruta_modelo.is_file():
            raise FileNotFoundError(
                f"No se encontró el modelo facial: {ruta_modelo}"
            )

        sesion = ort.InferenceSession(
            str(ruta_modelo),
            providers=["CPUExecutionProvider"],
        )
        entradas = sesion.get_inputs()
        salidas = sesion.get_outputs()

        if len(entradas) != 1 or len(salidas) != 1:
            raise RuntimeError("El modelo ONNX tiene entradas o salidas inesperadas.")

        self._clasificador = clasificador
        self._modelo_emocion = sesion
        self._nombre_entrada = entradas[0].name

    def analizar(self, frame: Any) -> dict[str, object]:
        salida: dict[str, object] = {
            "emocion": "neutral",
            "confianza": 0.0,
            "valida": False,
            "rostro_detectado": False,
            "fuente": "no_disponible",
        }

        if frame is None:
            return salida

        try:
            import cv2

            if self._clasificador is None or self._modelo_emocion is None:
                self._cargar_modelo()

            gris = cv2.cvtColor(frame, cv2.COLOR_BGR2GRAY)
            rostros = self._clasificador.detectMultiScale(
                gris,
                scaleFactor=1.1,
                minNeighbors=6,
                minSize=(80, 80),
            )
        except Exception:
            salida["fuente"] = "error_inicializacion_o_detector"
            return salida

        if len(rostros) != 1:
            salida["fuente"] = "sin_rostro_unico"
            return salida

        salida["rostro_detectado"] = True

        try:
            x, y, ancho, alto = rostros[0]
            cara = gris[y:y + alto, x:x + ancho]

            cara = cv2.resize(
                cara,
                (48, 48),
                interpolation=cv2.INTER_AREA,
            )

            # Entrada del modelo: (batch, canal, alto, ancho), valores [0, 1].
            tensor = cara.astype(np.float32) / 255.0
            tensor = tensor[np.newaxis, np.newaxis, :, :]

            resultados = self._modelo_emocion.run(
                None,
                {self._nombre_entrada: tensor},
            )
            puntuaciones = np.asarray(resultados[0]).reshape(-1)

            if puntuaciones.size != len(ETIQUETAS_EMOCIONES):
                salida["fuente"] = "modelo_onnx_incompatible"
                return salida

            if not np.all(np.isfinite(puntuaciones)):
                salida["fuente"] = "prediccion_no_finita"
                return salida

            # Softmax estable.
            puntuaciones = puntuaciones - np.max(puntuaciones)
            probabilidades = np.exp(puntuaciones)
            probabilidades /= probabilidades.sum()

            indice = int(np.argmax(probabilidades))
            dominante = ETIQUETAS_EMOCIONES[indice]
            confianza = float(probabilidades[indice])
            emocion = MAPA_EMOCIONES[dominante]

            salida["fuente"] = "onnx_runtime_local"

            if confianza < self.umbral:
                salida["confianza"] = round(confianza, 3)
                return salida

            self.historial.append((emocion, confianza))

            if not self.historial:
                return salida

            puntajes: dict[str, float] = {}
            for etiqueta, valor in self.historial:
                puntajes[etiqueta] = puntajes.get(etiqueta, 0.0) + valor

            emocion_suave = max(puntajes, key=lambda clave: puntajes[clave])
            confianza_suave = puntajes[emocion_suave] / len(self.historial)

            salida.update({
                "emocion": emocion_suave,
                "confianza": round(confianza_suave, 3),
                "valida": len(self.historial) >= 3,
            })

        except Exception:
            salida["fuente"] = "error_inferencia_onnx_runtime"

        return salida


_analizador = AnalizadorRostro()


def analizar_rostro(frame: Any) -> dict[str, object]:
    return _analizador.analizar(frame)


def detectar_emocion(frame: Any) -> str:
    return str(analizar_rostro(frame)["emocion"])
