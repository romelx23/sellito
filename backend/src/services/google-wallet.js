const jwt = require('jsonwebtoken');

const SCOPE = 'https://www.googleapis.com/auth/wallet_object.issuer';
const API = 'https://walletobjects.googleapis.com/walletobjects/v1';

function config() {
  const issuerId = process.env.GOOGLE_WALLET_ISSUER_ID;
  const clientEmail = process.env.GOOGLE_WALLET_CLIENT_EMAIL;
  const privateKey = (process.env.GOOGLE_WALLET_PRIVATE_KEY || '').replace(/\\n/g, '\n');
  const classSuffix = process.env.GOOGLE_WALLET_CLASS_SUFFIX || 'sella_loyalty_v1';

  return {
    issuerId,
    clientEmail,
    privateKey,
    classSuffix,
    enabled: Boolean(issuerId && clientEmail && privateKey),
  };
}

const appUrl = () => (process.env.APP_URL || 'http://localhost:3000').replace(/\/$/, '');

function absolute(url) {
  if (!url) return null;
  return /^https?:\/\//.test(url) ? url : `${appUrl()}${url}`;
}

async function getAccessToken({ clientEmail, privateKey }) {
  const iat = Math.floor(Date.now() / 1000);
  const assertion = jwt.sign(
    {
      iss: clientEmail,
      scope: SCOPE,
      aud: 'https://oauth2.googleapis.com/token',
      iat,
      exp: iat + 3600,
    },
    privateKey,
    { algorithm: 'RS256' },
  );

  const res = await fetch('https://oauth2.googleapis.com/token', {
    method: 'POST',
    headers: { 'Content-Type': 'application/x-www-form-urlencoded' },
    body: new URLSearchParams({
      grant_type: 'urn:ietf:params:oauth:grant-type:jwt-bearer',
      assertion,
    }),
  });

  if (!res.ok) {
    throw new Error(`No se pudo autenticar con Google: ${res.status} ${await res.text()}`);
  }

  const data = await res.json();
  return data.access_token;
}

let classReady = false;

async function ensureClass({ issuerId, classSuffix, clientEmail, privateKey }, business, program) {
  if (classReady) return `${issuerId}.${classSuffix}`;

  const classId = `${issuerId}.${classSuffix}`;
  const token = await getAccessToken({ clientEmail, privateKey });
  const headers = { Authorization: `Bearer ${token}` };

  const existing = await fetch(`${API}/loyaltyClass/${encodeURIComponent(classId)}`, { headers });
  if (existing.ok) {
    classReady = true;
    return classId;
  }
  if (existing.status !== 404) {
    throw new Error(`No se pudo consultar la clase: ${existing.status} ${await existing.text()}`);
  }

  const body = {
    id: classId,
    issuerName: business.name,
    programName: program.name,
    reviewStatus: 'UNDER_REVIEW',
    hexBackgroundColor: business.brand_color,
    rewardsTierLabel: 'Recompensa',
    rewardsTier: program.reward_text,
    accountNameLabel: 'Cliente',
    accountIdLabel: 'Tarjeta',
    programLogo: absolute(business.logo_url)
      ? { sourceUri: { uri: absolute(business.logo_url) } }
      : undefined,
  };

  const created = await fetch(`${API}/loyaltyClass`, {
    method: 'POST',
    headers: { ...headers, 'Content-Type': 'application/json' },
    body: JSON.stringify(body),
  });

  if (!created.ok && created.status !== 409) {
    throw new Error(`No se pudo crear la clase: ${created.status} ${await created.text()}`);
  }

  classReady = true;
  return classId;
}

/**
 * Devuelve { mode: 'google', url } si hay credenciales,
 * o { mode: 'mock', url: '/wallet/mock/CODE' } si no.
 */
async function walletLink({ card, customer, program, business }) {
  const cfg = config();
  if (!cfg.enabled) {
    return { mode: 'mock', url: `/wallet/mock/${card.code}` };
  }

  const classId = await ensureClass(cfg, business, program);
  const objectId = `${cfg.issuerId}.${card.code}`;

  const claims = {
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
          accountName: customer.name || 'Cliente',
          accountId: card.code,
          hexBackgroundColor: business.brand_color,
          loyaltyPoints: {
            label: 'Sellos',
            balance: { string: `${card.stamps}/${program.stamps_required}` },
          },
          barcode: {
            type: 'QR_CODE',
            value: `${appUrl()}/c/${card.code}`,
            alternateText: card.code,
          },
          textModulesData: [
            { id: 'reward', header: 'Recompensa', body: program.reward_text },
          ],
        },
      ],
    },
  };

  const token = jwt.sign(claims, cfg.privateKey, { algorithm: 'RS256' });
  return {
    mode: 'google',
    url: `https://pay.google.com/gp/v/save/${token}`,
    classId,
    objectId,
  };
}

module.exports = { walletLink, config };
