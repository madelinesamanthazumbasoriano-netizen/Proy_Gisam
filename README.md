# GISAM · Flutter + Gemini

Base funcional de GISAM con Flutter, SQLite y el motor Gemini que ya existía en el proyecto original.

## Estructura
- `lib/`: aplicación Flutter.
- `lib/screens/`: Inicio, IA/Chat, Amigos/QR, Música, Comunidad, Videojuego, Tienda y Ajustes.
- `lib/services/database_service.dart`: SQLite para progreso/XP, misiones, amistades y memoria del chat.
- `lib/services/gemini_service.dart`: cliente HTTP hacia el backend Gemini.
- `backend/`: API Python que conserva Gemini como motor de conversación.
- `assets/themes/`: preparada para los JPG de temas.

## Ejecutar backend
```bash
cd backend
python -m venv .venv
# Windows PowerShell
.\.venv\Scripts\Activate.ps1
pip install -r requirements.txt
copy .env.example .env
# Edita .env y coloca GEMINI_API_KEY
python server.py
```

## Ejecutar Flutter
```bash
flutter pub get
flutter run
```

En Android Emulator, el backend local se alcanza mediante `10.0.2.2:5000`. En un teléfono físico cambia `baseUrl` de `GeminiService` por la IP local del PC, por ejemplo `http://192.168.1.10:5000`.

## Nota sobre los recursos visuales
El ZIP recibido en esta conversación no contiene los JPG mencionados en la documentación, por lo que `assets/themes/` queda preparado pero no incluye imágenes inventadas. Copia allí los archivos reales y ya están declarados en `pubspec.yaml`.
# Proy_Gisam
# Proy_Gisam
