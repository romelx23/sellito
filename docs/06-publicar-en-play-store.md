# Publicar la app Android en Google Play

Estado: la app está lista para generar el paquete de release (`.aab`). Falta lo que solo vos podés hacer: cuenta de Play Console, clave de firma y un servidor público con HTTPS.

## Lo que ya quedó preparado en el repo

- **Firma de release** en [app/android/app/build.gradle.kts](../app/android/app/build.gradle.kts). Lee `app/android/key.properties` si existe; si no, usa la clave debug (sirve para probar, no para Play). La clave de subida ya está generada en `C:\Users\romel\keys\sella-upload.jks` y sus contraseñas en `C:\Users\romel\keys\sella-upload-PASSWORD.txt`, fuera del repo.
- **Permiso de cámara** explícito en [AndroidManifest.xml](../app/android/app/src/main/AndroidManifest.xml) para el escaneo de QR.
- **Marca nueva**: un sello postal (disco ámbar con dentado y una S carbón). El ícono, la ficha de Play y el splash nativo salen de [scripts/generar-iconos.py](../scripts/generar-iconos.py). Los widgets de la app usan la misma forma.
- **Splash nativo** de marca (sello sobre carbón) y **onboarding** de tres pantallas la primera vez que se abre la app.
- **Páginas legales** servidas por el backend: `/privacidad`, `/terminos` y `/eliminar-datos`. El email de contacto sale de la variable `SELLA_CONTACT_EMAIL` del `.env`; si no está, queda un placeholder visible.
- **Material de ficha** en [docs/play-store/](play-store/): ícono 512, gráfico de funciones 1024×500 y 7 capturas en [docs/play-store/capturas/](play-store/capturas/).
- **Guardia de API**: un build de release sin `API_URL` falla en vez de apuntar a `localhost`.
- `flutter analyze` y tests de Flutter en verde, `npm test` del backend en verde, y `flutter build appbundle --release` firmado con la clave de subida.
- `targetSdk` 36, requerido por Play en 2026.

## Antes de subir: lo que tenés que hacer vos

### 1. Servidor público

Producción ya está desplegada en Vercel: `https://sella-api.vercel.app` (proyecto `sella-api`, base Turso `sella-prod`, `AUTO_SEED=false`).

Las páginas legales están en ese servidor: `https://sella-api.vercel.app/privacidad`, `/terminos` y `/eliminar-datos`. El contacto que muestran es `alexisdeveloper2722@gmail.com` (variable `SELLA_CONTACT_EMAIL` en Vercel).

Pendiente antes de publicar: los logos se guardan en disco y no persisten en Vercel. Hay que moverlos a la base o a un almacenamiento externo.

### 2. Cuenta de Google Play

- Cuenta de desarrollador: pago único de USD 25.
- Verificá en Play Console los requisitos vigentes de identidad y de pruebas para cuentas personales; Google los cambió varias veces.

### 3. Respaldar la clave de firma

La clave ya existe. Guardá una copia de `C:\Users\romel\keys\sella-upload.jks` y de sus contraseñas en un gestor de contraseñas o en un disco externo. Si la perdés, Google puede resetear la clave de subida, pero es un trámite.

Si hace falta regenerarla en otra máquina, usá `keytool -genkeypair` con alias `upload` y completá `app/android/key.properties` a partir de `key.properties.example`.

### 4. Generar el paquete

```bash
cd app
flutter build appbundle --release --dart-define=API_URL=https://sella-api.vercel.app
```

El resultado queda en `app/build/app/outputs/bundle/release/app-release.aab`. Ya verificado: firmado con la clave de subida (`CN=Sella`) y con la URL de producción compilada.

Cada vez que subas una versión nueva, subí el número de build en `app/pubspec.yaml`: la parte `+N` (`version: 1.0.0+1` → `1.0.0+2`). Play rechaza un número ya usado.

### 5. Ficha en Play Console

Campos y textos que Play pide:

- **Nombre:** Sella
- **Descripción corta** (hasta 80 caracteres): "Tarjetas de sellos digitales para tu negocio, sin comisiones."
- **Capturas:** al menos 2 de teléfono. Tomalas de la app real, no de mockups.
- **Gráfico de funciones:** [docs/play-store/grafico-funciones-1024x500.png](play-store/grafico-funciones-1024x500.png).
- **Capturas:** las de [docs/play-store/capturas/](play-store/capturas/) salen de la versión web de la app, no de Android. Antes de publicar, conviene reemplazarlas por capturas de un teléfono o emulador real.
- **Política de privacidad:** obligatoria, porque la app pide nombre, teléfono y email. Usá la URL `/privacidad` del servidor. Es un borrador: revisalo antes de publicar.
- **Formulario de seguridad de datos (Data safety):** declarar que se recogen nombre, teléfono y email; que se envían al servidor cifrados en tránsito; que el usuario puede pedir su eliminación en `/eliminar-datos`.
- **Eliminación de datos:** `/eliminar-datos` describe un pedido por email, no un botón. Hoy el backend no tiene endpoint de borrado, así que el borrado es manual. Google exige una vía de eliminación accesible; si la política la pide, conviene construir un borrado real antes de publicar.
- **Clasificación de contenido:** cuestionario de Play. No está dirigida a menores.
- **Cuenta de prueba para revisores:** producción no tiene datos demo. Creá un negocio de prueba dedicado para el revisor y poné esas credenciales en "Acceso a la app". La cuenta del dueño (`romelx23@gmail.com`) no conviene entregarla.

### 6. Pruebas y producción

Subí primero a **Prueba interna** o **Prueba cerrada**. Con cuentas personales nuevas, Google pide un grupo de testers durante un periodo antes de habilitar producción. Revisá el requisito vigente en el momento de subir.

## Notas

- El `applicationId` es `app.sella.sella_app`. Se puede cambiar mientras no haya una app publicada; después ya no.
- No se incluyó iOS ni App Store.
- Si `API_URL` no está definido, el build de release muestra "No pudimos conectar con el servidor" en vez del error real (el error de configuración queda oculto dentro de la capa de red).
