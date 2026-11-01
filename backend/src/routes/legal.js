const express = require('express');
const html = require('../services/html');

const router = express.Router();

// Datos de contacto del responsable. Completar con SELLA_CONTACT_EMAIL en el .env antes de publicar.
const CONTACT = process.env.SELLA_CONTACT_EMAIL || '[completar: email de contacto]';
const UPDATED = '31 de octubre de 2026';

const prose = `<style>
  .legal h2 { font-size: 17px; margin: 26px 0 6px; letter-spacing: -.2px; }
  .legal p, .legal li { font-size: 14px; color: #374151; }
  .legal ul { padding-left: 20px; }
  .legal .updated { font-size: 12px; color: #6B7280; }
</style>`;

function page({ title, path, body }) {
  return html.layout({
    title: `${title} · Sella`,
    body: `${prose}
      <div class="brandbar"><div class="mark">S</div><div><h1>Sella</h1><p>${html.esc(title)}</p></div></div>
      <section class="panel legal">${body}
        <p class="updated">Última actualización: ${UPDATED}. Ruta: ${path}</p>
      </section>`,
  });
}

router.get('/privacidad', (req, res) => {
  res.type('html').send(
    page({
      title: 'Política de privacidad',
      path: '/privacidad',
      body: `
        <p>Sella es una app de tarjetas de fidelidad. Esta política explica qué datos tratamos, para qué y cómo podés pedir que los borremos.</p>

        <h2>Quién trata los datos</h2>
        <p>Los datos de cada negocio que usa Sella los trata Sella como proveedor del servicio, por cuenta del negocio. Para consultas: ${html.esc(CONTACT)}.</p>

        <h2>Qué datos recogemos</h2>
        <ul>
          <li><strong>Negocios (cuenta):</strong> nombre de la persona responsable, email, contraseña (guardada solo como hash) y nombre del negocio.</li>
          <li><strong>Clientes (tarjeta):</strong> nombre, teléfono y, si lo das, email. Registramos el consentimiento que diste al unirte al programa.</li>
          <li><strong>Uso de la tarjeta:</strong> sellos sumados, recompensas canjeadas y fecha y hora de cada movimiento.</li>
          <li><strong>Técnicos:</strong> datos mínimos del servidor para funcionar y proteger el servicio.</li>
        </ul>

        <h2>Para qué los usamos</h2>
        <ul>
          <li>Mostrarte tu tarjeta, tu progreso y el código QR para sumar sellos.</li>
          <li>Permitir que el negocio sume sellos, entregue recompensas y vea sus métricas.</li>
          <li>Evitar sellos falsos: los códigos QR son firmados y de un solo uso.</li>
        </ul>
        <p>No vendemos datos ni los usamos para publicidad.</p>

        <h2>Con quién los compartimos</h2>
        <p>Si añadís tu tarjeta a Google Wallet, Google recibe los datos necesarios para mostrar el pase (nombre del programa, progreso y código de la tarjeta). El resto no se comparte con terceros salvo obligación legal.</p>

        <h2>Dónde y cómo se guardan</h2>
        <p>Los datos se transmiten cifrados (HTTPS) y se guardan en el servidor donde corre Sella. Las contraseñas se guardan con hash.</p>

        <h2>Cuánto tiempo</h2>
        <p>Mientras la cuenta del negocio o la tarjeta del cliente estén activas. Después, se borran a pedido.</p>

        <h2>Tus derechos y cómo borrar tus datos</h2>
        <p>Podés pedir acceso, corrección o eliminación de tus datos. Para eliminarlos, seguí las instrucciones de <a href="/eliminar-datos">Eliminar mis datos</a>.</p>

        <h2>Menores</h2>
        <p>Sella no está dirigida a menores de 13 años y no recogemos datos a sabiendas de niños.</p>

        <h2>Cambios</h2>
        <p>Si cambiamos esta política, actualizamos la fecha de arriba.</p>
      `,
    }),
  );
});

router.get('/terminos', (req, res) => {
  res.type('html').send(
    page({
      title: 'Términos de uso',
      path: '/terminos',
      body: `
        <p>Al usar Sella aceptás estos términos. Si no estás de acuerdo, no uses el servicio.</p>

        <h2>El servicio</h2>
        <p>Sella permite a un negocio crear un programa de sellos digitales y a sus clientes llevar la tarjeta en el teléfono o en el navegador. Sella es un servicio de software: el programa de recompensas lo define cada negocio, y la recompensa la entrega el negocio, no Sella.</p>

        <h2>Cuentas</h2>
        <ul>
          <li>Sos responsable de la información de tu cuenta y de tu contraseña.</li>
          <li>Un negocio solo puede gestionar sus propios programas y tarjetas.</li>
        </ul>

        <h2>Uso permitido</h2>
        <p>No podés usar Sella para generar sellos falsos, intentar acceder a tarjetas de otros negocios ni interferir con el servicio.</p>

        <h2>Disponibilidad</h2>
        <p>Trabajamos para que el servicio esté disponible, pero puede haber interrupciones, cambios o mejoras. No garantizamos que el servicio esté libre de errores.</p>

        <h2>Limitación de responsabilidad</h2>
        <p>En la medida que la ley lo permita, Sella no responde por pérdidas indirectas ni por las recompensas, precios o condiciones que cada negocio ofrezca.</p>

        <h2>Contacto</h2>
        <p>${html.esc(CONTACT)}</p>
      `,
    }),
  );
});

router.get('/eliminar-datos', (req, res) => {
  res.type('html').send(
    page({
      title: 'Eliminar mis datos',
      path: '/eliminar-datos',
      body: `
        <p>Podés pedir que borremos tus datos de Sella en cualquier momento.</p>

        <h2>Si sos cliente (tarjeta de sellos)</h2>
        <ul>
          <li>Escribí a ${html.esc(CONTACT)} desde el email de contacto que diste o indicá el código de tu tarjeta.</li>
          <li>Borramos tu nombre, teléfono, email y el historial de sellos asociado a tu tarjeta.</li>
        </ul>

        <h2>Si sos negocio (cuenta)</h2>
        <ul>
          <li>Escribí a ${html.esc(CONTACT)} desde el email de la cuenta.</li>
          <li>Borramos la cuenta, el programa, las tarjetas y los datos de tus clientes asociados a ese negocio.</li>
        </ul>

        <h2>Plazo</h2>
        <p>Respondemos y completamos el borrado dentro de los 30 días. Algunos registros pueden conservarse si la ley nos obliga.</p>
      `,
    }),
  );
});

module.exports = { router };
