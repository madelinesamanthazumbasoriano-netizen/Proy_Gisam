from google import genai
from google.genai import types
from config import GEMINI_API_KEY, GEMINI_MODEL, contruir_prompt

class GisamChat:
    
    def __init__(self):
        if not GEMINI_API_KEY: raise ValueError('Falta GEMINI_API_KEY en .env')
        self.client=genai.Client(api_key=GEMINI_API_KEY)
        self.new_chat()
    def new_chat(self):
        self.chat=self.client.chats.create(model=GEMINI_MODEL, config=types.GenerateContentConfig(system_instruction=contruir_prompt(texto="", emocion="", contexto=[]), temperature=0.7, max_output_tokens=500))
    def responder(self,mensaje):
        r=self.chat.send_message(message=mensaje)
        return (r.text or 'No pude generar una respuesta.').strip()
