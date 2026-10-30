const QRCode = require('qrcode');

const esc = (value) =>
  String(value ?? '')
    .replace(/&/g, '&amp;')
    .replace(/</g, '&lt;')
    .replace(/>/g, '&gt;')
    .replace(/"/g, '&quot;')
    .replace(/'/g, '&#39;');

const safeColor = (value, fallback = '#0F766E') =>
  /^#[0-9a-fA-F]{6}$/.test(String(value)) ? value : fallback;

async function qrDataUrl(text, color = '#14161B') {
  return QRCode.toDataURL(text, {
    margin: 1,
    width: 360,
    errorCorrectionLevel: 'M',
    color: { dark: safeColor(color, '#14161B'), light: '#FFFFFF' },
  });
}

function layout({ title, body, brand = '#0F766E', script = '' }) {
  return `<!doctype html>
<html lang="es">
<head>
<meta charset="utf-8">
<meta name="viewport" content="width=device-width, initial-scale=1, viewport-fit=cover">
<title>${esc(title)}</title>
<meta name="theme-color" content="${safeColor(brand)}">
<style>
  :root {
    --ink: #14161B;
    --muted: #6B7280;
    --paper: #F4F1EA;
    --line: #E6E1D6;
    --brand: ${safeColor(brand)};
    --radius: 24px;
  }
  * { box-sizing: border-box; -webkit-tap-highlight-color: transparent; }
  body {
    margin: 0; background: var(--paper); color: var(--ink);
    font-family: -apple-system, BlinkMacSystemFont, "Segoe UI", Roboto, Helvetica, Arial, sans-serif;
    line-height: 1.45;
  }
  .shell { max-width: 460px; margin: 0 auto; padding: 26px 18px 54px; }
  .brandbar { display: flex; align-items: center; gap: 12px; margin-bottom: 22px; }
  .mark {
    width: 44px; height: 44px; border-radius: 14px; background: var(--brand); color: #fff;
    display: grid; place-items: center; font-weight: 700; font-size: 18px; overflow: hidden;
    box-shadow: 0 6px 18px rgba(20,22,27,.18);
  }
  .mark img { width: 100%; height: 100%; object-fit: cover; }
  .brandbar h1 { font-size: 17px; margin: 0; letter-spacing: -.2px; }
  .brandbar p { margin: 2px 0 0; font-size: 12px; color: var(--muted); text-transform: uppercase; letter-spacing: .08em; }

  .card {
    position: relative; overflow: hidden; border-radius: var(--radius);
    background: var(--brand); color: #fff; padding: 22px;
    box-shadow: 0 18px 40px rgba(20,22,27,.22);
  }
  .card::after {
    content: ""; position: absolute; inset: 0; pointer-events: none;
    background-image: radial-gradient(rgba(255,255,255,.18) 1px, transparent 1px);
    background-size: 16px 16px; opacity: .55;
  }
  .card > * { position: relative; z-index: 1; }
  .card .kicker { font-size: 11px; letter-spacing: .14em; text-transform: uppercase; opacity: .8; }
  .card h2 { margin: 6px 0 0; font-size: 24px; letter-spacing: -.6px; }
  .stamps { display: grid; grid-template-columns: repeat(4, 1fr); gap: 10px; margin: 22px 0 14px; }
  .stamp {
    aspect-ratio: 1; border-radius: 999px; display: grid; place-items: center;
    border: 1.5px dashed rgba(255,255,255,.45); font-size: 18px; font-weight: 700;
    background: rgba(255,255,255,.06);
  }
  .stamp.on { border-style: solid; border-color: rgba(255,255,255,.9); background: rgba(255,255,255,.92); color: var(--brand); }
  .progress { display: flex; justify-content: space-between; align-items: baseline; font-size: 13px; }
  .progress strong { font-size: 20px; letter-spacing: -.4px; }
  .reward { margin-top: 18px; padding: 12px 14px; border-radius: 14px; background: rgba(255,255,255,.14); font-size: 13px; }
  .reward span { display: block; opacity: .75; font-size: 11px; text-transform: uppercase; letter-spacing: .1em; margin-bottom: 3px; }

  .panel { background: #fff; border: 1px solid var(--line); border-radius: var(--radius); padding: 20px; margin-top: 18px; }
  .panel h3 { margin: 0 0 4px; font-size: 15px; }
  .panel p.help { margin: 0 0 16px; font-size: 13px; color: var(--muted); }

  label { display: block; font-size: 12px; font-weight: 600; margin: 14px 0 6px; }
  input[type=text], input[type=tel], input[type=email] {
    width: 100%; padding: 13px 14px; border-radius: 14px; border: 1px solid var(--line);
    background: #FBF9F5; font-size: 15px; color: var(--ink); outline: none;
  }
  input:focus { border-color: var(--brand); box-shadow: 0 0 0 3px rgba(15,118,110,.12); }
  .consent { display: flex; gap: 10px; align-items: flex-start; margin-top: 16px; font-size: 12px; color: var(--muted); }
  .consent input { margin-top: 2px; }

  .btn {
    display: flex; align-items: center; justify-content: center; gap: 8px; width: 100%;
    padding: 15px 18px; border-radius: 999px; border: 0; cursor: pointer;
    background: var(--ink); color: #fff; font-size: 15px; font-weight: 650; text-decoration: none;
    margin-top: 18px;
  }
  .btn.brand { background: var(--brand); }
  .btn.ghost { background: transparent; color: var(--ink); border: 1px solid var(--line); }
  .btn:active { transform: translateY(1px); }

  .qrslot { display: grid; place-items: center; padding: 12px; }
  .qrslot img { width: 230px; height: 230px; display: block; }
  .code { font-family: ui-monospace, SFMono-Regular, Menlo, monospace; letter-spacing: .12em; font-size: 13px; color: var(--muted); text-align: center; margin-top: 2px; }
  .hint { font-size: 12px; color: var(--muted); text-align: center; margin: 10px 0 0; }

  .error { display: none; margin-top: 14px; padding: 11px 13px; border-radius: 12px; background: #FDECEC; color: #9B1C1C; font-size: 13px; }
  .error.show { display: block; }

  .badge { display: inline-block; padding: 4px 9px; border-radius: 999px; background: #FFF4D6; color: #7A5200; font-size: 10px; font-weight: 700; letter-spacing: .08em; text-transform: uppercase; }

  footer { margin-top: 26px; text-align: center; font-size: 11px; color: #9A958A; }
  footer a { color: inherit; }

  @media (prefers-color-scheme: dark) {
    /* La demo mantiene fondo claro a propósito: se ve igual en cualquier móvil. */
  }
</style>
</head>
<body>
  <main class="shell">${body}</main>
  ${script ? `<script>${script}</script>` : ''}
</body>
</html>`;
}

function brandBar(business, subtitle) {
  const initial = esc((business.name || 'S').charAt(0).toUpperCase());
  const logo = business.logo_url
    ? `<img src="${esc(business.logo_url)}" alt="">`
    : initial;
  return `<div class="brandbar">
    <div class="mark">${logo}</div>
    <div>
      <h1>${esc(business.name)}</h1>
      <p>${esc(subtitle)}</p>
    </div>
  </div>`;
}

function stampGrid(stamps, required) {
  let html = '';
  for (let i = 0; i < required; i += 1) {
    html += `<div class="stamp ${i < stamps ? 'on' : ''}">${i < stamps ? '✓' : ''}</div>`;
  }
  return html;
}

function cardBlock({ program, business, stamps }) {
  return `<section class="card">
    <div class="kicker">Tarjeta de fidelidad</div>
    <h2>${esc(program.name)}</h2>
    <div class="stamps" style="grid-template-columns: repeat(${Math.min(required(program), 4)}, 1fr)">
      ${stampGrid(stamps, required(program))}
    </div>
    <div class="progress">
      <span>Llevas</span>
      <strong>${stamps} / ${required(program)}</strong>
    </div>
    <div class="reward"><span>Recompensa</span>${esc(program.reward_text)}</div>
  </section>`;
}

const required = (program) => Number(program.stamps_required) || 8;

function renderJoinPage({ business, program }) {
  const body = `
    ${brandBar(business, 'Tarjeta de fidelidad')}
    ${cardBlock({ program, business, stamps: 0 })}

    <section class="panel">
      <h3>Únete en 20 segundos</h3>
      <p class="help">Sin app y sin contraseña. Tu tarjeta queda guardada en este navegador y puedes añadirla a Google Wallet.</p>

      <form id="join">
        <label for="name">Tu nombre</label>
        <input id="name" name="name" type="text" placeholder="Ana Pérez" autocomplete="name" required>

        <label for="phone">WhatsApp o teléfono</label>
        <input id="phone" name="phone" type="tel" placeholder="11 5555 5555" autocomplete="tel" required>

        <div class="consent">
          <input id="consent" type="checkbox" required>
          <label for="consent" style="margin:0;font-weight:400">
            Acepto que ${esc(business.name)} guarde mi nombre y teléfono para gestionar esta tarjeta.
            No se comparten con terceros.
          </label>
        </div>

        <button class="btn brand" type="submit">Crear mi tarjeta</button>
        <div class="error" id="err"></div>
      </form>
    </section>

    <footer>Hecho con <strong>Sella</strong> · demo de código abierto</footer>
  `;

  const script = `
    const form = document.getElementById('join');
    const err = document.getElementById('err');
    form.addEventListener('submit', async (event) => {
      event.preventDefault();
      err.className = 'error';
      const btn = form.querySelector('button');
      btn.disabled = true;
      btn.textContent = 'Creando...';
      try {
        const res = await fetch('/api/public/programs/${esc(business.slug)}/join', {
          method: 'POST',
          headers: { 'Content-Type': 'application/json' },
          body: JSON.stringify({
            name: document.getElementById('name').value,
            phone: document.getElementById('phone').value,
            consent: document.getElementById('consent').checked
          })
        });
        const data = await res.json();
        if (!res.ok) throw new Error(data.error || 'No se pudo crear la tarjeta');
        window.location.href = '/c/' + data.code;
      } catch (e) {
        err.textContent = e.message;
        err.className = 'error show';
        btn.disabled = false;
        btn.textContent = 'Crear mi tarjeta';
      }
    });
  `;

  return layout({
    title: `${business.name} · Tarjeta de fidelidad`,
    brand: business.brand_color,
    body,
    script,
  });
}

function renderCardPage({ card, customer, program, business, qr, wallet }) {
  const walletLabel =
    wallet.mode === 'google' ? 'Añadir a Google Wallet' : 'Ver pase de Wallet (demo)';

  const body = `
    ${brandBar(business, 'Tu tarjeta')}
    <section class="card">
      <div class="kicker">${esc(program.name)}</div>
      <h2>${esc(customer.name || 'Cliente')}</h2>
      <div class="stamps" style="grid-template-columns: repeat(${Math.min(required(program), 4)}, 1fr)">
        ${stampGrid(card.stamps, required(program))}
      </div>
      <div class="progress">
        <span>${card.status === 'reward_ready' ? '¡Recompensa lista!' : 'Progreso'}</span>
        <strong>${card.stamps} / ${required(program)}</strong>
      </div>
      <div class="reward"><span>Recompensa</span>${esc(program.reward_text)}</div>
    </section>

    <section class="panel">
      <div class="qrslot"><img id="qr" src="${qr.dataUrl}" alt="Código QR de la tarjeta"></div>
      <div class="code">${esc(card.code)}</div>
      <p class="hint">Muéstralo en el mostrador. Se renueva solo cada 30 segundos.</p>
      <a class="btn brand" href="${esc(wallet.url)}" target="_blank" rel="noopener">${walletLabel}</a>
      ${wallet.mode === 'mock' ? '<p class="hint">Modo demo: falta configurar las credenciales de Google Wallet.</p>' : ''}
    </section>

    <footer>Hecho con <strong>Sella</strong> · demo de código abierto</footer>
  `;

  const script = `
    const code = ${JSON.stringify(card.code)};
    async function refresh() {
      try {
        const res = await fetch('/api/public/cards/' + code);
        if (!res.ok) return;
        const data = await res.json();
        document.getElementById('qr').src = data.qr.dataUrl;
      } catch (_) {}
    }
    setInterval(refresh, 30000);
    document.addEventListener('visibilitychange', () => { if (!document.hidden) refresh(); });
  `;

  return layout({
    title: `${business.name} · ${card.code}`,
    brand: business.brand_color,
    body,
    script,
  });
}

function renderMockPass({ card, customer, program, business, qrDataUrl: dataUrl }) {
  const body = `
    <div class="brandbar">
      <div class="mark" style="background:#14161B">G</div>
      <div>
        <h1>Google Wallet</h1>
        <p>Vista previa del pase</p>
      </div>
      <span class="badge" style="margin-left:auto">Modo demo</span>
    </div>

    <section class="card" style="background:${safeColor(business.brand_color)}">
      <div class="kicker">${esc(business.name)}</div>
      <h2>${esc(program.name)}</h2>
      <div style="display:flex;align-items:baseline;gap:8px;margin-top:20px">
        <span style="font-size:44px;font-weight:750;letter-spacing:-2px;line-height:1">${card.stamps}</span>
        <span style="opacity:.8">/ ${required(program)} sellos</span>
      </div>
      <div class="reward" style="margin-top:16px"><span>Recompensa</span>${esc(program.reward_text)}</div>
    </section>

    <section class="panel" style="text-align:center">
      <img src="${dataUrl}" alt="QR" style="width:210px;height:210px">
      <div class="code">${esc(card.code)}</div>
      <p class="hint">Así se vería el pase en Android una vez configuradas las credenciales de Google Wallet.</p>
      <a class="btn ghost" href="/c/${esc(card.code)}">Volver a mi tarjeta</a>
    </section>

    <footer>Pase simulado · Sella</footer>
  `;

  return layout({
    title: `Pase demo · ${business.name}`,
    brand: business.brand_color,
    body,
  });
}

module.exports = { renderJoinPage, renderCardPage, renderMockPass, qrDataUrl, layout, esc };
