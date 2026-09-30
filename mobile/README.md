# GISAM App

MVP Flutter de la aplicación móvil de GISAM.

## Incluye

- Inicio con árbol, estados, nivel, XP y misiones.
- Amigos mediante generación y escaneo de QR.
- Música.
- Comunidad.
- Chatbot conectado a un backend FastAPI.
- Videojuego.
- Tienda.
- Ajustes.
- Arquitectura por features, separando interfaz y servicios.

## Ejecutar

```bash
flutter pub get
flutter run
```

## Backend

En `lib/core/services/api_service.dart` está:

`http://10.0.2.2:8000`

Para un teléfono físico, reemplaza `10.0.2.2` por la IP local del PC donde corre FastAPI.

El endpoint esperado por ahora es:

`POST /chat`

La app no guarda claves de modelos. El backend configura NVIDIA Nemotron con
`NVIDIA_API_KEY` en `backend/.env`.

## Recursos visuales y música

- Fondos por pantalla: `assets/themes/` (Inicio, Perfil, Música, Comunidad,
  Tienda, Ajustes e IA).
- Pistas autorizadas: `assets/music/`.

No se incluyen audios de terceros; para reproducción real añade pistas con
licencia o conecta un proveedor mediante OAuth.

Body:

```json
{"message":"Hola GISAM"}
```

Respuesta:

```json
{"response":"Hola, ¿cómo te sientes hoy?"}
```

## Próxima integración

1. Conectar progreso a SQLite/API.
2. Conectar el árbol a estados reales.
3. Conectar DL/ML/LLM del backend.
4. Añadir voz.
5. Añadir autenticación.
6. Implementar comunidad y amigos en backend.
7. Implementar almacenamiento seguro y consentimiento.

GISAM debe presentarse como apoyo y acompañamiento, no como sustituto de un profesional de salud mental ni como sistema de diagnóstico.
