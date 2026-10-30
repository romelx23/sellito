# Google Wallet

Sella ya genera pases de fidelidad reales. Mientras no existan credenciales, el botón abre un
**pase simulado** (`/wallet/mock/:code`) que sirve para mostrar el producto sin trámites.

Esta guía cubre el trámite completo, lo que cuesta, los límites de las cuentas nuevas y los errores
que suelen aparecer.

## Lo que vas a obtener

Una tarjeta de fidelidad que el cliente guarda en Google Wallet desde el navegador o desde la app.
Se actualiza cuando el negocio suma un sello y muestra el QR de la tarjeta.

| Concepto | Costo |
| --- | --- |
| Cuenta de emisor de Google Wallet | 0 USD |
| Google Cloud (API de Wallet) | 0 USD dentro del uso normal |
| Publicación para todos los usuarios | 0 USD, requiere aprobación |
| Apple Wallet (opcional) | 99 USD/año (Apple Developer Program) |

Tiempo realista: **30 a 45 minutos** para el modo demo; **2 a 10 días hábiles** para la aprobación
de publicación si querés emitir a cualquier usuario.

## Antes de empezar

- Una cuenta de Google (idealmente la del negocio, no la personal de prueba).
- Un proyecto en [Google Cloud Console](https://console.cloud.google.com/).
- Acceso a [Google Pay & Wallet Console](https://pay.google.com/business/console/).
- La app desplegada con HTTPS: Google necesita URLs públicas para el logo y el QR.
- Un logo cuadrado en PNG/JPG, idealmente 512×512, alojado en tu dominio.

> El orden importa. Si creás la cuenta de servicio antes de tener la cuenta de emisor, después hay
> que vincularlas igual. Ambos caminos funcionan; acá va el orden más directo.

## Paso 1 · Cuenta de emisor

1. Entrá a [pay.google.com/business/console](https://pay.google.com/business/console/) con la cuenta
   del negocio.
2. Aceptá los términos de Google Wallet API.
3. Completá el perfil del negocio: nombre legal, país, sitio web y datos de contacto.
   - El **perfil de negocio** y el **perfil de pagos** deben estar completos para pedir publicación
     más adelante. Para el modo demo alcanza con lo mínimo.
4. Creá una cuenta de emisor (*Issuer account*). Google te asigna un **Issuer ID** numérico, del
   estilo `3388000000012345678`. Guardalo: va en `GOOGLE_WALLET_ISSUER_ID`.

Las cuentas nuevas quedan en **modo demo**. Eso significa que los pases solo se pueden emitir a:

- usuarios con rol **Admin** o **Developer** en la cuenta de emisor;
- cuentas de prueba que agregues explícitamente.

Para el resto de los usuarios, el pase no se guarda. Es el comportamiento esperado, no un bug.

## Paso 2 · Proyecto de Google Cloud y cuenta de servicio

1. En [Google Cloud Console](https://console.cloud.google.com/) creá un proyecto (o reutilizá uno).
2. Andá a **APIs y servicios → Biblioteca**, buscá **Google Wallet API** y habilitala.
3. Andá a **IAM y administración → Cuentas de servicio → Crear cuenta de servicio**.
   - Nombre: `sella-wallet`.
   - Rol: no hace falta asignar roles de proyecto; el acceso se da en la consola de Wallet.
4. Abrí la cuenta de servicio → **Claves → Agregar clave → Crear clave nueva → JSON**.
5. Se descarga un archivo `.json` con tres datos que necesitás:

```json
{
  "type": "service_account",
  "project_id": "mi-proyecto",
  "private_key_id": "...",
  "private_key": "-----BEGIN PRIVATE KEY-----\nMIIE...\n-----END PRIVATE KEY-----\n",
  "client_email": "sella-wallet@mi-proyecto.iam.gserviceaccount.com",
  "client_id": "..."
}
```

- `client_email` → `GOOGLE_WALLET_CLIENT_EMAIL`
- `private_key` → `GOOGLE_WALLET_PRIVATE_KEY`

**No subas ese JSON al repositorio.** Está cubierto por `.gitignore` si lo dejás como `*.json` en la
raíz, pero lo más seguro es guardarlo fuera del proyecto.

## Paso 3 · Vincular la cuenta de servicio al emisor

1. En [Pay & Wallet Console](https://pay.google.com/business/console/), entrá a tu cuenta de emisor.
2. Abrí **Users** (Usuarios) → **Invite a user**.
3. Pegá el `client_email` de la cuenta de servicio.
4. Asignale rol **Developer** (o **Admin**). Sin este paso, la API responde `403`.

## Paso 4 · Conectar Sella

En `backend/.env` (o en las variables de entorno del hosting):

```bash
GOOGLE_WALLET_ISSUER_ID=3388000000012345678
GOOGLE_WALLET_CLIENT_EMAIL=sella-wallet@mi-proyecto.iam.gserviceaccount.com
GOOGLE_WALLET_PRIVATE_KEY="-----BEGIN PRIVATE KEY-----\nMIIE...\n-----END PRIVATE KEY-----\n"
GOOGLE_WALLET_CLASS_SUFFIX=sella_loyalty_v1
APP_URL=https://tu-dominio.com
```

Detalles que suelen romper:

- **Saltos de línea**: si copiás la clave en una sola línea, reemplazá cada salto real por `\n`
  literal. Sella hace `.replace(/\\n/g, '\n')` al leerla.
- **Comillas**: en `.env`, la clave va entre comillas dobles.
- **`APP_URL`**: sin barra final. Se usa en `origins` del JWT y en la URL del código de barras.
- **`GOOGLE_WALLET_CLASS_SUFFIX`**: solo letras, números, `.`, `_` y `-`.

Reiniciá el backend. El log debe decir:

```
Google Wallet: credenciales detectadas
```

Si dice `modo mock`, falta alguna de las tres variables o la clave no se pudo parsear.

## Cómo funciona el pase

Google Wallet no guarda "una imagen": guarda un **objeto** que referencia una **clase**.

```mermaid
flowchart LR
    A[Service Account] -->|OAuth RS256| B[walletobjects.googleapis.com]
    B -->|crea si falta| C[LoyaltyClass<br/>issuerId.sella_loyalty_v1]
    B -->|crea al guardar| D[LoyaltyObject<br/>issuerId.CAFE-DEMO]
    D --> E[Pase en el teléfono]
    F[Sella] -->|JWT firmado<br/>typ=savetowallet| G[pay.google.com/gp/v/save/...]
```

- **Clase** (`loyaltyClass`): configuración compartida. Nombre del programa, logo, color,
  textos de la etiqueta. Se crea una sola vez; el código la reutiliza con caché en memoria.
- **Objeto** (`loyaltyObject`): la tarjeta de un cliente. Lleva `accountName`, `loyaltyPoints`
  (sellos), el código de barras y los textos.
- **JWT**: se firma con la clave privada en RS256 y se entrega como link
  `https://pay.google.com/gp/v/save/<jwt>`. Al abrirlo, Google valida la firma y ofrece guardar el pase.

El código está en `backend/src/services/google-wallet.js`:

```js
const classId = await ensureClass(cfg, business, program);
const objectId = `${cfg.issuerId}.${card.code}`;

const token = jwt.sign(
  {
    iss: cfg.clientEmail,
    aud: 'google',
    typ: 'savetowallet',
    iat: Math.floor(Date.now() / 1000),
    origins: [appUrl()],
    payload: {
      loyaltyObjects: [
        {
          id: objectId,
          classId,
          state: 'ACTIVE',
          accountName: customer.name,
          loyaltyPoints: { label: 'Sellos', balance: { string: `${card.stamps}/${program.stamps_required}` } },
          barcode: { type: 'QR_CODE', value: `${appUrl()}/c/${card.code}` },
        },
      ],
    },
  },
  cfg.privateKey,
  { algorithm: 'RS256' },
);
```

Cosas a tener en cuenta:

- El pase se **genera al vuelo** cada vez que el cliente toca el botón. Los sellos reflejan el estado
  actual, no el momento en que se guardó.
- Si el cliente ya guardó el pase, Google no actualiza automáticamente los puntos. Para eso hay que
  llamar a `loyaltyObject` con `PATCH` después de cada sello. Es la mejora natural siguiente
  (ver roadmap).
- El código de barras del pase apunta a `/c/:code`, la tarjeta web. Así el negocio escanea el QR
  del pase y Sella valida el token, igual que con la app.
- `reviewStatus: UNDER_REVIEW` en la clase es lo normal al crear. No impide probar en modo demo.

### Alternativa más avanzada: QR rotativo nativo

Google Wallet soporta `rotatingBarcode` con TOTP. Eso permite que el pase muestre un QR que cambia
solo, sin abrir la web. Requiere compartir el secreto TOTP con Google y validarlo en el servidor.
Sella hoy usa su propio token de 60 segundos; migrar a `rotatingBarcode` está en el roadmap.

## Modo demo vs. producción

| | Modo demo | Producción |
| --- | --- | --- |
| Pases para Admin/Developer | Sí | Sí |
| Pases para cuentas de prueba | Sí | Sí |
| Pases para cualquier usuario | **No** | Sí |
| Prefijo "[TEST ONLY]" | Sí | No |
| Requisito | Cuenta de emisor | Solicitar acceso de publicación |

### Pedir acceso de publicación

1. Completá el perfil de negocio y el perfil de pagos en Pay & Wallet Console.
2. Creá al menos una clase (Sella la crea sola la primera vez que alguien pide el pase).
3. En la consola, buscá la opción de **solicitar acceso de publicación** (*Request publishing access*).
4. Google revisa el caso de uso: marca, programa de fidelidad, coherencia del logo y los textos.
5. Al aprobarlo, desaparece el prefijo "[TEST ONLY]" y podés emitir a cualquier usuario.

Mientras esperás, la demo funciona perfecto: agregás tu cuenta como Developer y probás el pase real
en tu propio teléfono.

## Probar

1. Configurá las variables y reiniciá.
2. Abrí `/c/CAFE-DEMO`.
3. Tocá **Añadir a Google Wallet**.
4. Google muestra una vista previa con el nombre del negocio, los sellos y el QR.
5. Guardá el pase y abrilo desde la app de Wallet en Android.

En iPhone, Google Wallet no muestra pases de fidelidad de terceros igual que en Android. El botón
lleva a una página de Google que puede no ofrecer guardar el pase. En ese caso, la tarjeta web
(`/c/:code`) es el respaldo oficial: funciona en cualquier navegador.

## Errores típicos

| Síntoma | Causa probable | Solución |
| --- | --- | --- |
| `403` al crear la clase | Cuenta de servicio sin rol en el emisor | Invitarla como Developer en Wallet Console |
| `401 invalid_grant` | Clave privada mal escapada | Revisar `\n` y comillas en `GOOGLE_WALLET_PRIVATE_KEY` |
| `Unable to parse private key` | Clave truncada al pegarla | Volver a copiar el JSON completo |
| El pase no se guarda | Modo demo con cuenta no autorizada | Usar la cuenta Admin/Developer o pedir publicación |
| "Class not found" | `GOOGLE_WALLET_CLASS_SUFFIX` distinto entre entornos | Mantener el mismo sufijo |
| Logo roto en el pase | `APP_URL` no es pública o el logo no es cuadrado | URL HTTPS accesible sin login |
| `Error 400: invalid object id` | El código de tarjeta tiene caracteres no permitidos | Sella usa base32 + guion, es válido; revisar copias manuales |

## Apple Wallet

No es parte de esta demo, pero conviene saber el costo antes de prometerlo:

| | Google Wallet | Apple Wallet |
| --- | --- | --- |
| Costo | 0 USD | 99 USD/año (Apple Developer Program) |
| Requisito | Cuenta de emisor | Pass Type ID + certificado |
| Formato | Objeto JSON + JWT | Archivo `.pkpass` firmado |
| Actualización | API REST | Push + web service propio |
| Dificultad | Media | Alta |

Sin Apple Developer, en iPhone se usa la tarjeta web. Es una decisión de producto válida para un MVP.

## Checklist

- [ ] Cuenta de emisor creada y `GOOGLE_WALLET_ISSUER_ID` anotado.
- [ ] Google Wallet API habilitada en Google Cloud.
- [ ] Cuenta de servicio con clave JSON descargada.
- [ ] Cuenta de servicio invitada como Developer en Wallet Console.
- [ ] Variables `GOOGLE_WALLET_*` y `APP_URL` configuradas en el hosting.
- [ ] Log del backend dice `credenciales detectadas`.
- [ ] Pase probado en un Android con la cuenta autorizada.
- [ ] Logo cuadrado y público.
- [ ] (Para producción) Acceso de publicación solicitado y aprobado.
