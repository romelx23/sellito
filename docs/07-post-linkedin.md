# Post de LinkedIn

Borrador listo para publicar. Reemplazá los `[corchetes]` antes de postear.

---

Las tarjetas de sellos de cartón se pierden, no se miden y casi nunca reflejan la marca del negocio. Las plataformas grandes cobran comisión por cada canje y no dejan cambiar ni el color de la tarjeta.

Armé **Sella** para resolver eso: tarjetas de fidelidad digitales, personalizables y sin comisiones.

Cómo funciona:

🎨 El negocio diseña su tarjeta (colores, logo, ícono de sello, meta y recompensa) con vista previa en vivo.

📱 El cliente se une desde el navegador, sin instalar nada, y puede añadir la tarjeta a Google Wallet.

🔐 Cada sello se escanea con un QR que rota cada 30 segundos y se valida en el servidor. Una captura de pantalla no sirve dos veces.

Stack: Flutter (app y web), Node + Express y SQLite. Todo corre como un solo servicio, y hay Dockerfile listo.

Lo que me interesa remarcar: el proyecto es open source (MIT) y cualquiera puede levantarlo. Si tenés Claude Code, abrí la carpeta y pedile que lo levante: te va a preguntar a qué rubro se dedica tu negocio y arma la demo con esos datos.

Aclaro lo honesto: es una demo funcional, no un SaaS listo para cobrar. Todavía faltan rate limiting, recuperación de contraseña y Apple Wallet. Si te interesa sumarte, el roadmap está en el README.

🔗 Repo: [link al repo]

#Flutter #NodeJS #OpenSource #Emprendedores #Fidelidad #SaaS

---

## Checklist antes de publicar

- [ ] Reemplazar `[link al repo]`.
- [ ] Adjuntar una captura: `docs/img/landing.png` o `docs/img/card-web.png`.
- [ ] Crear el flujo de "preguntar el rubro" (ver nota abajo) o quitar esa frase del post.
- [ ] No decir que hay demo pública: en el README figura como _pendiente de desplegar_.
