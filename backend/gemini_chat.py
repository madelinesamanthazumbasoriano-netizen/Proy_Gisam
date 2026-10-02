from google import genai
from google.genai import types
from config import GEMINI_API_KEY, GEMINI_MODEL, contruir_prompt

DEFAULT_MODELS = (
    'gemini-3.5-flash-lite',
    'gemini-3.5-flash',
    'gemini-2.5-flash-lite',
    'gemini-2.0-flash',
    'gemini-1.5-flash',
)


class GisamChat:
    def __init__(self):
        if not GEMINI_API_KEY:
            raise ValueError('Falta GEMINI_API_KEY en .env')
        self.client = genai.Client(api_key=GEMINI_API_KEY)
        self.model = self._select_model()
        self.new_chat()

    def _select_model(self):
        configured = (GEMINI_MODEL or '').strip()
        candidates = [configured, *DEFAULT_MODELS]
        seen = set()
        for model_name in candidates:
            if model_name and model_name not in seen:
                seen.add(model_name)
                return model_name
        return 'gemini-2.5-flash-lite'

    def new_chat(self):
        for model_name in [self.model, *[name for name in DEFAULT_MODELS if name != self.model]]:
            try:
                self.model = model_name
                self.chat = self.client.chats.create(
                    model=model_name,
                    config=types.GenerateContentConfig(
                        system_instruction=contruir_prompt(texto='', emocion='', contexto=[]),
                        temperature=0.7,
                        max_output_tokens=500,
                    ),
                )
                return
            except Exception:
                continue
        raise RuntimeError('No pude crear un chat con ningún modelo compatible de Gemini.')

    def responder(self, mensaje):
        r = self.chat.send_message(message=mensaje)
        return (r.text or 'No pude generar una respuesta.').strip()
