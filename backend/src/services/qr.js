const crypto = require('crypto');

const PEPPER = process.env.QR_PEPPER || 'dev-pepper';

/**
 * Token de un solo uso con caducidad corta.
 * Formato: S1.<base64url(cardId.exp)>.<hmac>
 */
function sign(cardId, secret, ttlSeconds = 60) {
  const exp = Math.floor(Date.now() / 1000) + ttlSeconds;
  const nonce = crypto.randomBytes(4).toString('base64url');
  const payload = `${cardId}.${exp}.${nonce}`;
  const sig = crypto
    .createHmac('sha256', `${secret}:${PEPPER}`)
    .update(payload)
    .digest('base64url');

  return `S1.${Buffer.from(payload).toString('base64url')}.${sig}`;
}

function parse(token) {
  const parts = String(token || '').trim().split('.');
  if (parts.length !== 3 || parts[0] !== 'S1') {
    throw new Error('Ese código no es un QR de Sella');
  }

  const payload = Buffer.from(parts[1], 'base64url').toString('utf8');
  const [cardId, expRaw] = payload.split('.');
  const exp = Number(expRaw);

  if (!cardId || !Number.isFinite(exp)) {
    throw new Error('QR con formato inválido');
  }

  if (Math.floor(Date.now() / 1000) > exp) {
    throw new Error('El QR expiró, pide que lo actualicen');
  }

  return { cardId, exp, signature: parts[2] };
}

function verifySignature(token, secret) {
  const { cardId, signature } = parse(token);
  const payload = String(token).split('.')[1];
  const decoded = Buffer.from(payload, 'base64url').toString('utf8');
  const expected = crypto
    .createHmac('sha256', `${secret}:${PEPPER}`)
    .update(decoded)
    .digest('base64url');

  const a = Buffer.from(signature);
  const b = Buffer.from(expected);
  if (a.length !== b.length || !crypto.timingSafeEqual(a, b)) {
    throw new Error('La firma del QR no es válida');
  }

  return { cardId };
}

const hashToken = (token) => crypto.createHash('sha256').update(String(token)).digest('hex');

module.exports = { sign, parse, verifySignature, hashToken };
