import os
import threading
import time

from flask import Flask, jsonify, request
from flask_cors import CORS
from gemini_chat import GisamChat
import cv2
from vision import analizar_rostro

app = Flask(__name__)
CORS(app)
chat = None
USAR_CAMARA = os.getenv('USAR_CAMARA', 'false').lower() in {'1', 'true', 'si', 'sí'}

def iniciar_camara():
    if not USAR_CAMARA or cv2 is None or analizar_rostro is None:
        return None
    camara = cv2.VideoCapture(0)
    if not camara.isOpened():
        print("Cámara no disponible; se continuará sin análisis facial.")
        camara.release()
        return None
    return camara
def analisis() -> None:
    camara = iniciar_camara()
    try:
        while True:
            rostro = None
            if camara is not None and analizar_rostro is not None:
                recibido, frame = camara.read()
                if recibido:
                    rostro = analizar_rostro(frame)
            if rostro is not None:
                print(f"Análisis facial: {rostro}")
            time.sleep(0.2)
    finally:
        if camara is not None:
            camara.release()
    
@app.get('/health')
def health(): return jsonify({'ok':True,'service':'GISAM','gemini':chat is not None})
@app.post('/chat')
def chat_route():
    global chat
    if chat is None: chat=GisamChat()
    data=request.get_json(silent=True) or {}
    msg=str(data.get('message','')).strip()
    if not msg:return jsonify({'error':'message requerido'}),400
    try:return jsonify({'answer':chat.responder(msg)})
    except Exception as e:return jsonify({'error':str(e)}),500
if __name__=='__main__': 
    if USAR_CAMARA:
        threading.Thread(target=analisis, daemon=True).start()
    app.run(host='0.0.0.0',port=5000,debug=False)
