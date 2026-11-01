# Sella — instrucciones para Claude

Sella es una app de tarjetas de fidelidad (backend Node + SQLite, app Flutter Web/Android/iOS). Ver [README.md](README.md) para la descripción general.

## Cuando te pidan levantar el proyecto

Si el usuario dice algo como "levantalo", "corré el proyecto", "quiero probarlo" o "ponelo en cloud", **antes de arrancar nada preguntá a qué rubro se dedica su negocio**. Es una sola pregunta, con ejemplos (cafetería, barbería, gimnasio, veterinaria, librería, panadería, otro).

Con la respuesta:

1. Cargá una demo con ese rubro, sin tocar los datos demo existentes:
   - En [backend/src/seed.js](backend/src/seed.js), agregá un tercer negocio después de `barberia-norte`, con `insertBusiness` + `insertProgram` + algunas `insertCard`, igual que los dos actuales.
   - Nombre, slug y color de marca propios del rubro. Usá nombres ficticios, nunca marcas reales.
   - `reward` y `description` acordes al rubro (por ejemplo, en una panadería, "Una medialuna gratis" cada 10 compras).
   - `style` con `template`, `background`, `foreground`, `accent`, `stampIcon`, `pattern` y `cornerRadius`. Para los valores válidos, mirá `editor_tab.dart` (`template` y `pattern`) y la lista de íconos de sello en el mismo archivo. No inventes valores.
   - Credenciales: mismo esquema que el resto (`demo@sella.app` / `demo1234`), con un email nuevo para el negocio nuevo.
2. Si la base ya tiene datos, `seed()` no hace nada (`hasData()`). Para que aparezca el negocio nuevo, hay que borrar `backend/data/sella.db` antes de arrancar. Avisale al usuario antes de borrarla.
3. Arrancá el proyecto:
   - **Con Docker** (la forma más simple, y la que sirve para cloud): `docker compose up --build`. Queda en `http://localhost:3000`.
   - **Sin Docker**: `cd backend && npm install && npm start` (en Windows, `copy .env.example .env` antes). Para la app Flutter, ver el README. El backend ya sirve la web si se compila con `scripts/build-web.sh` o `build-web.ps1`.
4. Al terminar, decile al usuario:
   - La URL local y las páginas para probar: `/j/<slug-nuevo>` (inscripción) y `/c/<codigo-demo>` (tarjeta).
   - Las credenciales del negocio nuevo.
   - Que la demo es local y que los datos son ficticios.

## Reglas del repo

- Es una demo funcional, no un SaaS. No agregues secretos reales ni claves de Google Wallet al repo.
- Los tests del backend (`cd backend && npm test`) no tocan `backend/data/sella.db`. Corrélos después de cambiar `seed.js`.
- No hagas commit salvo que el usuario lo pida.
