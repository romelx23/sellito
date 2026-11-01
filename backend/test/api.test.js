const { test, before, after } = require('node:test');
const assert = require('node:assert');
const os = require('node:os');
const path = require('node:path');
const fs = require('node:fs');
const crypto = require('node:crypto');

const dbPath = path.join(os.tmpdir(), `sella-test-${crypto.randomUUID()}.db`);
process.env.DB_PATH = dbPath;
process.env.JWT_SECRET = 'test-secret';
process.env.QR_PEPPER = 'test-pepper';
process.env.AUTO_SEED = 'false';

const { app } = require('../src/app');
const { ready, get } = require('../src/db');
const qr = require('../src/services/qr');

let server;
let base;
let token;
let programId;
let code;
let cardId;

async function api(route, { method = 'GET', body, auth } = {}) {
  const res = await fetch(base + route, {
    method,
    headers: {
      'Content-Type': 'application/json',
      ...(auth ? { Authorization: `Bearer ${auth}` } : {}),
    },
    body: body === undefined ? undefined : JSON.stringify(body),
  });
  const data = await res.json().catch(() => null);
  return { status: res.status, data };
}

before(async () => {
  await ready;
  await new Promise((resolve) => {
    server = app.listen(0, '127.0.0.1', resolve);
  });
  base = `http://127.0.0.1:${server.address().port}`;
});

after(async () => {
  await new Promise((resolve) => server.close(resolve));
  for (const suffix of ['', '-wal', '-shm']) {
    try {
      fs.rmSync(dbPath + suffix, { force: true });
    } catch {
      /* ignore */
    }
  }
});

test('registro crea negocio, usuario y programa por defecto', async () => {
  const { status, data } = await api('/api/auth/register', {
    method: 'POST',
    body: {
      businessName: 'Café Test',
      name: 'Ana',
      email: 'ana@test.com',
      password: 'secreto123',
    },
  });

  assert.equal(status, 201);
  assert.ok(data.token);
  assert.equal(data.business.name, 'Café Test');
  assert.equal(data.business.slug, 'cafe-test');
  assert.equal(data.programs.length, 1);

  token = data.token;
  programId = data.programs[0].id;
});

test('el mismo email no puede registrarse dos veces', async () => {
  const { status } = await api('/api/auth/register', {
    method: 'POST',
    body: { businessName: 'Otro', email: 'ana@test.com', password: 'secreto123' },
  });
  assert.equal(status, 409);
});

test('se puede ajustar el programa', async () => {
  const { status, data } = await api(`/api/programs/${programId}`, {
    method: 'PATCH',
    auth: token,
    body: { stampsRequired: 2, rewardText: 'Café gratis', name: 'Club Test' },
  });

  assert.equal(status, 200);
  assert.equal(data.program.stamps_required, 2);
  assert.equal(data.program.style.background.length, 7);
});

test('un cliente se inscribe y recibe un código', async () => {
  const { status, data } = await api('/api/public/programs/cafe-test/join', {
    method: 'POST',
    body: { name: 'Bruno Díaz', phone: '+54 11 4444 0000', consent: true },
  });

  assert.equal(status, 201);
  assert.equal(data.created, true);
  assert.match(data.code, /^[A-Z]{3,4}-[A-Z0-9]{6}$/);
  code = data.code;
});

test('inscribirse dos veces devuelve la misma tarjeta', async () => {
  const { status, data } = await api('/api/public/programs/cafe-test/join', {
    method: 'POST',
    body: { name: 'Bruno Díaz', phone: '+54 11 4444 0000', consent: true },
  });

  assert.equal(status, 200);
  assert.equal(data.created, false);
  assert.equal(data.code, code);
});

test('sin consentimiento no se crea la tarjeta', async () => {
  const { status } = await api('/api/public/programs/cafe-test/join', {
    method: 'POST',
    body: { name: 'Nadie', phone: '+54 11 4444 1111', consent: false },
  });
  assert.equal(status, 400);
});

test('la tarjeta pública incluye QR y progreso', async () => {
  const { status, data } = await api(`/api/public/cards/${code}`);

  assert.equal(status, 200);
  assert.equal(data.stamps, 0);
  assert.equal(data.stampsRequired, 2);
  assert.equal(data.customer.name, 'Bruno D.');
  assert.ok(data.qr.token.startsWith('S1.'));
  assert.ok(data.qr.dataUrl.startsWith('data:image/png;base64,'));
});

test('el negocio suma un sello escaneando el QR', async () => {
  const fresh = await api(`/api/public/cards/${code}`);
  const { status, data } = await api('/api/scan', {
    method: 'POST',
    auth: token,
    body: { token: fresh.data.qr.token },
  });

  assert.equal(status, 200);
  assert.equal(data.stamps, 1);
  assert.equal(data.completed, false);
  cardId = data.card.id;
});

test('el mismo QR no se puede reutilizar', async () => {
  const fresh = await api(`/api/public/cards/${code}`);
  const first = await api('/api/scan', {
    method: 'POST',
    auth: token,
    body: { token: fresh.data.qr.token },
  });
  assert.equal(first.status, 200);

  const replay = await api('/api/scan', {
    method: 'POST',
    auth: token,
    body: { token: fresh.data.qr.token },
  });
  assert.equal(replay.status, 409);
});

test('al llegar a la meta la recompensa queda lista', async () => {
  const { data } = await api(`/api/public/cards/${code}`);
  assert.equal(data.stamps, 2);
  assert.equal(data.status, 'reward_ready');

  const extra = await api('/api/scan', {
    method: 'POST',
    auth: token,
    body: { token: data.qr.token },
  });
  assert.equal(extra.status, 409);
});

test('el canje reinicia la tarjeta', async () => {
  const { status, data } = await api(`/api/cards/${cardId}/redeem`, {
    method: 'POST',
    auth: token,
    body: {},
  });

  assert.equal(status, 200);
  assert.equal(data.stamps, 0);

  const card = await api(`/api/public/cards/${code}`);
  assert.equal(card.data.stamps, 0);
  assert.equal(card.data.status, 'active');
});

test('el cooldown bloquea sellos seguidos', async () => {
  await api(`/api/programs/${programId}`, {
    method: 'PATCH',
    auth: token,
    body: { cooldownMinutes: 60 },
  });

  const fresh = await api(`/api/public/cards/${code}`);
  const { status, data } = await api('/api/scan', {
    method: 'POST',
    auth: token,
    body: { token: fresh.data.qr.token },
  });

  assert.equal(status, 429);
  assert.match(data.error, /Espera/);
});

test('otro negocio no puede sellar una tarjeta ajena', async () => {
  const other = await api('/api/auth/register', {
    method: 'POST',
    body: { businessName: 'Otro Local', email: 'otro@test.com', password: 'secreto123' },
  });

  const fresh = await api(`/api/public/cards/${code}`);
  const { status } = await api('/api/scan', {
    method: 'POST',
    auth: other.data.token,
    body: { token: fresh.data.qr.token },
  });

  assert.equal(status, 403);
});

test('un QR expirado no es válido', async () => {
  const card = await get('SELECT * FROM cards WHERE code = ?', [code]);
  const expired = qr.sign(card.id, card.secret, -10);

  assert.throws(() => qr.parse(expired), /expiró/);
});

test('una firma alterada no es válida', async () => {
  const card = await get('SELECT * FROM cards WHERE code = ?', [code]);
  const forged = qr.sign(card.id, 'secreto-inventado', 60);

  assert.throws(() => qr.verifySignature(forged, card.secret), /firma/);
});

test('las páginas web de inscripción y tarjeta responden', async () => {
  const join = await fetch(`${base}/j/cafe-test`);
  const joinHtml = await join.text();
  assert.equal(join.status, 200);
  assert.match(joinHtml, /Únete en 20 segundos/);

  const card = await fetch(`${base}/c/${code}`);
  const cardHtml = await card.text();
  assert.equal(card.status, 200);
  assert.match(cardHtml, /Tu tarjeta/);
});

test('el pase de wallet cae en modo mock sin credenciales', async () => {
  const { status, data } = await api(`/api/wallet/${code}`);
  assert.equal(status, 200);
  assert.equal(data.mode, 'mock');
  assert.equal(data.url, `/wallet/mock/${code}`);
});
