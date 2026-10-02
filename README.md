# GISAM Flutter + Gemini

Aplicación Flutter conectada a una API FastAPI que utiliza Gemini.

## Requisitos

- Flutter instalado y disponible en `PATH`.
- Python 3.10 o posterior.
- Una clave válida de Gemini configurada en `backend/.env` como `GEMINI_API_KEY`.

## Instalar dependencias del backend

En PowerShell, desde la raíz del repositorio:

```powershell
cd backend
python -m pip install -r requirements.txt
```

No compartas ni subas `backend/.env` al repositorio.

## Iniciar la API

Desde la carpeta `backend`:

```powershell
python -m uvicorn api:app --host 0.0.0.0 --port 8000
```

Comprueba que el backend esté disponible en `http://127.0.0.1:8000/health`.
La app usa esta API FastAPI en el puerto `8000`. `backend/server.py` es un
servidor Flask antiguo de pruebas en el puerto `5000`; no es el servidor que
consume la app móvil.

## Iniciar Flutter

En otra terminal, desde la raíz del repositorio:

```powershell
cd mobile
flutter pub get
flutter run
```

En el emulador Android, Flutter usa por defecto `http://10.0.2.2:8000`, que
redirige al PC anfitrión. En un teléfono físico, conecta ambos dispositivos a
la misma red y pasa la IP local del PC:

```powershell
flutter run --dart-define=GISAM_API_URL=http://192.168.1.10:8000
```

Sustituye `192.168.1.10` por la dirección IPv4 del PC (`ipconfig`). Permite
el puerto `8000` en el Firewall de Windows para redes privadas si el teléfono
no logra acceder. El tráfico HTTP está habilitado para desarrollo local; usa
HTTPS antes de publicar la aplicación.

Si el teléfono está conectado por USB, puedes evitar la configuración Wi-Fi
con el túnel de ADB:

```powershell
adb devices
adb -s <serial-del-telefono> reverse tcp:8000 tcp:8000
flutter run -d <serial-del-telefono> --dart-define=GISAM_API_URL=http://127.0.0.1:8000
```

## Diagnóstico

- Si `/health` no responde en el PC, revisa la terminal donde ejecutaste Uvicorn.
- Si `/health` responde en el PC pero no en Android, revisa la URL, el Firewall
  y que el emulador/teléfono pueda alcanzar el PC.
- Si `/chat` responde con error `500`, revisa la terminal del backend y valida
  la clave y el modelo configurados para Gemini en `backend/.env`.