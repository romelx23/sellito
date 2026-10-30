# API

Base: `http://localhost:3000/api` (o tu URL pública).

- Todas las respuestas son JSON, salvo las páginas HTML (`/j`, `/c`, `/wallet/mock`).
- Las rutas marcadas **Auth** requieren `Authorization: Bearer <token>`.
- Los errores siempre tienen la forma `{ "error": "mensaje en español" }`.

## Autenticación

### `POST /auth/register`

Crea negocio, usuario y un programa por defecto.

```bash
curl -X POST http://localhost:3000/api/auth/register \
  -H 'Content-Type: application/json' \
  -d '{
    "businessName": "Café Aurora",
    "name": "Lucía",
    "email": "hola@cafeaurora.com",
    "password": "secreto123",
    "brandColor": "#A24B2A"
  }'
```

`201`

```json
{
  "token": "eyJhbGciOi...",
  "user": { "id": "uuid", "name": "Lucía", "email": "hola@cafeaurora.com", "role": "owner" },
  "business": {
    "id": "uuid",
    "name": "Café Aurora",
    "slug": "cafe-aurora",
    "logo_url": null,
    "brand_color": "#A24B2A",
    "created_at": "2026-10-28T12:00:00.000Z"
  },
  "programs": [
    {
      "id": "uuid",
      "name": "Tarjeta de fidelidad",
      "reward_text": "Una recompensa gratis",
      "stamps_required": 8,
      "cooldown_minutes": 0,
      "max_per_day": 0,
      "active": true,
      "style": { "template": "ticket", "background": "#A24B2A", "...": "..." }
    }
  ]
}
```

Errores: `400` datos faltantes, `409` email ya registrado.

### `POST /auth/login`

```bash
curl -X POST http://localhost:3000/api/auth/login \
  -H 'Content-Type: application/json' \
  -d '{ "email": "demo@sella.app", "password": "demo1234" }'
```

Devuelve la misma forma que el registro. `401` si las credenciales no coinciden.

### `GET /auth/me` · Auth

Devuelve `{ user, business, programs }` actualizados. La app lo usa para restaurar la sesión.

## Negocio

### `GET /business` · Auth

```json
{
  "business": { "id": "...", "name": "Café Aurora", "slug": "cafe-aurora" },
  "stats": {
    "customers": 4,
    "cards": 4,
    "stampsToday": 9,
    "rewardsReady": 1,
    "rewardsRedeemed": 1
  }
}
```

### `PATCH /business` · Auth

```bash
curl -X PATCH http://localhost:3000/api/business \
  -H "Authorization: Bearer $TOKEN" \
  -H 'Content-Type: application/json' \
  -d '{ "name": "Café Aurora", "brandColor": "#0F766E" }'
```

### `POST /business/logo` · Auth

Acepta JSON con una imagen en base64 (máximo 2 MB):

```json
{ "dataUrl": "data:image/png;base64,iVBORw0KGgo..." }
```

Responde `{ "logoUrl": "/uploads/7f3a....png" }`. Guardá la ruta relativa: la app la resuelve contra el host de la API.

## Programas

### `GET /programs` · Auth

`{ "programs": [ ... ] }`

### `POST /programs` · Auth

```json
{
  "name": "Club Aurora",
  "description": "Cada visita suma.",
  "rewardText": "Un flat white gratis",
  "stampsRequired": 8,
  "cooldownMinutes": 0,
  "maxPerDay": 0,
  "style": {
    "template": "ticket",
    "background": "#A24B2A",
    "foreground": "#FFF7ED",
    "accent": "#F2C14E",
    "stampIcon": "coffee",
    "pattern": "dots",
    "cornerRadius": 26,
    "showLogo": true
  }
}
```

`stampsRequired` se recorta entre 2 y 30. `style` se normaliza con valores por defecto.

### `PATCH /programs/:id` · Auth

Acepta cualquier subconjunto de los campos anteriores más `active: false` para pausar.

### `DELETE /programs/:id` · Auth

Solo si el programa no tiene tarjetas. Si las tiene:

```json
{ "error": "Este programa tiene 4 tarjetas activas. Pausalo en vez de borrarlo." }
```

## Clientes y tarjetas (negocio)

### `GET /business/cards?q=` · Auth

Busca por nombre, teléfono o código. Devuelve hasta 100 tarjetas ordenadas por actividad.

```json
{
  "cards": [
    {
      "id": "uuid",
      "code": "CAFE-DEMO",
      "stamps": 3,
      "stampsRequired": 8,
      "status": "active",
      "rewardText": "Un flat white de especialidad gratis",
      "updatedAt": "2026-10-28T12:00:00.000Z",
      "programId": "uuid",
      "programName": "Club Aurora",
      "customer": { "id": "uuid", "name": "Ana Pérez", "phone": "+54 11 5555 0101", "email": null }
    }
  ]
}
```

### `POST /business/cards` · Auth

Alta manual desde el mostrador.

```json
{ "programId": "uuid", "name": "Carla Ruiz", "phone": "+54 11 5555 0103" }
```

`201` → `{ "id": "uuid", "code": "CAFE-L2QX" }`. Si el teléfono ya tiene tarjeta en ese programa: `409`.

### `POST /cards/:id/stamps` · Auth

Suma un sello sin QR (respaldo del mostrador). Acepta `idempotencyKey` opcional.

```json
{
  "cardId": "uuid",
  "duplicate": false,
  "stamps": 4,
  "stampsRequired": 8,
  "status": "active",
  "completed": false,
  "rewardText": "Un flat white de especialidad gratis"
}
```

Errores: `409` recompensa pendiente o programa pausado, `429` cooldown o tope diario.

### `POST /cards/:id/redeem` · Auth

Solo si `status = "reward_ready"`. Reinicia el contador y registra el canje.

```json
{ "cardId": "uuid", "duplicate": false, "stamps": 0, "status": "active" }
```

## Escaneo

### `POST /scan` · Auth

```bash
curl -X POST http://localhost:3000/api/scan \
  -H "Authorization: Bearer $TOKEN" \
  -H 'Content-Type: application/json' \
  -d '{ "token": "S1.M2FiYy4xNzY...abc" }'
```

```json
{
  "cardId": "uuid",
  "duplicate": false,
  "stamps": 4,
  "stampsRequired": 8,
  "status": "active",
  "completed": false,
  "rewardText": "Un flat white de especialidad gratis",
  "alreadyStamped": false,
  "card": {
    "id": "uuid",
    "code": "CAFE-DEMO",
    "stamps": 4,
    "stampsRequired": 8,
    "status": "active",
    "rewardText": "...",
    "updatedAt": "...",
    "customer": { "id": "uuid", "name": "Ana Pérez", "phone": "+54 11 5555 0101", "email": null },
    "programId": "uuid",
    "programName": "Club Aurora"
  }
}
```

Errores típicos:

| Código | Cuándo | Mensaje |
| --- | --- | --- |
| `400` | Token mal formado o expirado | `El QR expiró, pide que lo actualicen` |
| `400` | Firma inválida | `La firma del QR no es válida` |
| `403` | El QR es de otro negocio | `Esa tarjeta pertenece a otro negocio` |
| `409` | Token ya usado | `Ese QR ya se usó. Pedile que lo actualice.` |
| `409` | Recompensa pendiente | `Esta tarjeta ya tiene una recompensa pendiente de canje` |
| `429` | Cooldown | `Espera 12 min antes del próximo sello` |

## Público (sin sesión)

### `GET /public/programs/:slug`

`:slug` es el del negocio (no el del programa).

```json
{
  "business": { "name": "Café Aurora", "slug": "cafe-aurora", "logoUrl": null, "brandColor": "#A24B2A" },
  "program": {
    "name": "Club Aurora",
    "description": "Cada visita suma. Cada 8 sellos, un premio.",
    "rewardText": "Un flat white de especialidad gratis",
    "stampsRequired": 8,
    "style": { "...": "..." }
  }
}
```

### `POST /public/programs/:slug/join`

```json
{ "name": "Ana Pérez", "phone": "+54 11 5555 0101", "email": null, "consent": true }
```

`201` la primera vez, `200` si el teléfono ya tenía tarjeta (devuelve la misma):

```json
{ "code": "CAFE-38P7DK", "created": true }
```

Sin `consent: true` responde `400`. El nombre y el teléfono son obligatorios.

### `GET /public/cards/:code`

```json
{
  "code": "CAFE-DEMO",
  "stamps": 3,
  "stampsRequired": 8,
  "status": "active",
  "rewardText": "Un flat white de especialidad gratis",
  "customer": { "name": "Ana P." },
  "program": { "id": "uuid", "name": "Club Aurora", "style": { "...": "..." } },
  "business": { "name": "Café Aurora", "logoUrl": null, "brandColor": "#A24B2A" },
  "qr": {
    "token": "S1.M2FiYy4xNzY0...",
    "expiresAt": 1767000060000,
    "dataUrl": "data:image/png;base64,iVBORw0KGgo..."
  }
}
```

El nombre se enmascara (`Ana P.`). El teléfono nunca se expone en esta ruta.

### `GET /public/cards/:code/qr`

Solo el token, sin datos del cliente. Útil para refrescar el QR sin re-renderizar la tarjeta.

```json
{ "token": "S1....", "expiresAt": 1767000060000 }
```

## Wallet

### `GET /wallet/:code`

```json
{ "mode": "google", "url": "https://pay.google.com/gp/v/save/eyJhbGciOi..." }
```

Sin credenciales configuradas:

```json
{ "mode": "mock", "url": "/wallet/mock/CAFE-DEMO" }
```

`url` puede ser relativa: la app la resuelve contra el host de la API.

## Páginas HTML

| Ruta | Descripción |
| --- | --- |
| `GET /j/:slug` | Formulario de inscripción del cliente |
| `GET /c/:code` | Tarjeta con QR autorrenovable y botón de Wallet |
| `GET /wallet/mock/:code` | Pase simulado de Google Wallet |
| `GET /uploads/:file` | Logos |
| `GET /` | App Flutter Web (si existe el build) |
| `GET /api/health` | Estado del servicio |

## Idempotencia

`POST /scan` y los endpoints de sello aceptan `idempotencyKey` en el cuerpo. Si la clave ya existe,
la respuesta repite el resultado anterior con `duplicate: true` en vez de sumar otro sello.

El QR ya incluye su propio hash como clave: reenviar el mismo token devuelve `409`.

## Rate limiting

No implementado en la demo. Para producción: `express-rate-limit` en `/api/public/*` y `/api/scan`,
con límites por IP y por negocio. Está anotado en el roadmap del README.

