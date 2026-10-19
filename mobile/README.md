# GISAM App

Aplicación móvil Flutter de GISAM.

## Funciones

- Inicio con árbol, progreso, misiones y mascota activa.
- Perfiles independientes por cuenta de Google con Firebase Authentication.
- Firestore para perfil, progreso, amistades, historial de chat y estado del juego.
- Fondos desbloqueables y mascotas; las monedas se obtienen jugando.
- Catálogo personal de playlists de Spotify. La reproducción se abre en Spotify.
- Amigos, comunidad, chatbot, ajustes y modo oscuro.

## Firebase

1. Crea un proyecto Firebase, habilita Google en Authentication y crea Firestore.
2. Publica las reglas y las funciones:

   ```powershell
   firebase deploy --project <PROJECT_ID> --only firestore:rules,functions
   ```

   Las funciones inicializan el estado del juego, conceden XP, validan las
   compras y limitan las recompensas de minijuegos a 75 monedas por día. Activa
   la expiración TTL del campo `expiresAt` de `gameSessions` para retirar rondas
   antiguas.
3. Ejecuta Flutter con los valores públicos de configuración del proyecto:

   ```powershell
   flutter run `
     --dart-define=FIREBASE_API_KEY=<API_KEY> `
     --dart-define=FIREBASE_APP_ID=<APP_ID> `
     --dart-define=FIREBASE_MESSAGING_SENDER_ID=<SENDER_ID> `
     --dart-define=FIREBASE_PROJECT_ID=<PROJECT_ID> `
     --dart-define=FIREBASE_AUTH_DOMAIN=<PROJECT_ID>.firebaseapp.com `
     --dart-define=GOOGLE_IOS_CLIENT_ID=<IOS_OAUTH_CLIENT_ID> `
     --dart-define=GOOGLE_WEB_CLIENT_ID=<WEB_OAUTH_CLIENT_ID> `
     --dart-define=GOOGLE_SERVER_CLIENT_ID=<WEB_OAUTH_CLIENT_ID>
   ```

4. Configura el servidor FastAPI con Firebase Admin. Usa una cuenta de servicio
   fuera del repositorio o Application Default Credentials:

   ```powershell
   $env:FIREBASE_PROJECT_ID = "<PROJECT_ID>"
   $env:GOOGLE_APPLICATION_CREDENTIALS = "<RUTA_PRIVADA_A_CREDENCIALES_JSON>"
   ```

   No subas la cuenta de servicio al repositorio. El backend verifica los ID
   tokens de Firebase y obtiene el UID del token, no del `user_id` enviado por
   el cliente.

Las variables `FIREBASE_*` y los OAuth Client IDs son configuración pública de
cliente, no claves privadas. Firebase Authentication administra el inicio con
Google; bcrypt no se aplica a tokens de Google. No se guardan contraseñas en la
app. Las reglas de Firestore aíslan los datos por UID y las operaciones de
monedas/progreso se ejecutan en Cloud Functions.

Para Android, registra la huella SHA-1/SHA-256 de la app en Firebase y usa el
Client ID web como `GOOGLE_SERVER_CLIENT_ID`. En iOS, agrega el esquema
`REVERSED_CLIENT_ID` de GoogleService-Info.plist a `CFBundleURLSchemes`.

Sin estos valores la app sigue abriendo en modo invitado local; las funciones
de cuenta y sincronización requieren completar la configuración y desplegar
Cloud Functions.

## Spotify

1. Crea una aplicación en Spotify Developer Dashboard y registra como redirect
   URI `com.example.gisam_app://oauth` (o el valor que uses en la compilación).
2. Ejecuta con:

   ```powershell
   flutter run `
     --dart-define=SPOTIFY_CLIENT_ID=<SPOTIFY_CLIENT_ID> `
     --dart-define=SPOTIFY_REDIRECT_URI=com.example.gisam_app://oauth
   ```

3. Si cambias el esquema de redirección, actualízalo también en
   `android/app/build.gradle.kts` y `ios/Runner/Info.plist`.

GISAM solicita acceso de lectura a playlists privadas y guardadas; no guarda el
token de Spotify y abre cada playlist en la aplicación de Spotify.

## Backend

La URL por defecto es `http://10.0.2.2:8000` para el emulador Android. En un
teléfono físico, usa la IP local del PC con `--dart-define=GISAM_API_URL=...`.
Los endpoints de cuenta requieren un ID token de Firebase válido y Firebase
Admin configurado en FastAPI. `/health` permanece público.

GISAM es una herramienta de acompañamiento y bienestar; no sustituye atención
profesional ni realiza diagnósticos.
