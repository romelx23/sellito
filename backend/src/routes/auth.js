const express = require('express');
const bcrypt = require('bcryptjs');
const { get, all, batch, id, now } = require('../db');
const { sign, requireAuth } = require('../auth');
const { slugify, normalizeStyle } = require('../services/util');

const router = express.Router();

async function uniqueSlug(base) {
  const root = slugify(base);
  let slug = root;
  let n = 1;
  while (await get('SELECT 1 FROM businesses WHERE slug = ?', [slug])) {
    n += 1;
    slug = `${root}-${n}`;
  }
  return slug;
}

async function sessionPayload(userId) {
  const user = await get('SELECT * FROM users WHERE id = ?', [userId]);
  const business = await get('SELECT * FROM businesses WHERE id = ?', [user.business_id]);
  const programs = (
    await all('SELECT * FROM programs WHERE business_id = ? ORDER BY created_at ASC', [business.id])
  ).map((p) => ({ ...p, style: JSON.parse(p.style_json), active: Boolean(p.active) }));

  return {
    user: { id: user.id, name: user.name, email: user.email, role: user.role },
    business,
    programs,
  };
}

router.post('/register', async (req, res, next) => {
  try {
    const { businessName, name, email, password, brandColor } = req.body || {};

    if (!businessName || String(businessName).trim().length < 2) {
      return res.status(400).json({ error: 'Poné el nombre de tu negocio' });
    }
    if (!email || !String(email).includes('@')) {
      return res.status(400).json({ error: 'Email inválido' });
    }
    if (!password || String(password).length < 6) {
      return res.status(400).json({ error: 'La contraseña necesita al menos 6 caracteres' });
    }

    const normalizedEmail = String(email).toLowerCase().trim();
    if (await get('SELECT 1 FROM users WHERE email = ?', [normalizedEmail])) {
      return res.status(409).json({ error: 'Ese email ya tiene una cuenta' });
    }

    const businessId = id();
    const userId = id();
    const ts = now();
    const slug = await uniqueSlug(businessName);
    const color = /^#[0-9a-fA-F]{6}$/.test(brandColor || '') ? brandColor : '#0F766E';

    await batch([
      [
        'INSERT INTO businesses (id, name, slug, brand_color, created_at) VALUES (?, ?, ?, ?, ?)',
        [businessId, String(businessName).trim(), slug, color, ts],
      ],
      [
        'INSERT INTO users (id, business_id, email, password_hash, name, role, created_at) VALUES (?, ?, ?, ?, ?, ?, ?)',
        [
          userId,
          businessId,
          normalizedEmail,
          bcrypt.hashSync(String(password), 10),
          String(name || businessName).trim(),
          'owner',
          ts,
        ],
      ],
      [
        `INSERT INTO programs
          (id, business_id, name, description, reward_text, stamps_required, cooldown_minutes, max_per_day, style_json, active, created_at)
         VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, 1, ?)`,
        [
          id(),
          businessId,
          'Tarjeta de fidelidad',
          'Junta sellos en cada visita y llevate una recompensa.',
          'Una recompensa gratis',
          8,
          0,
          0,
          JSON.stringify(
            normalizeStyle({
              background: color,
              accent: '#F5C451',
              stampIcon: 'circle',
            }),
          ),
          ts,
        ],
      ],
    ]);

    const user = await get('SELECT * FROM users WHERE id = ?', [userId]);
    res.status(201).json({ token: sign(user), ...(await sessionPayload(userId)) });
  } catch (error) {
    next(error);
  }
});

router.post('/login', async (req, res, next) => {
  try {
    const { email, password } = req.body || {};
    const user = await get('SELECT * FROM users WHERE email = ?', [
      String(email || '').toLowerCase().trim(),
    ]);

    if (!user || !bcrypt.compareSync(String(password || ''), user.password_hash)) {
      return res.status(401).json({ error: 'Email o contraseña incorrectos' });
    }

    res.json({ token: sign(user), ...(await sessionPayload(user.id)) });
  } catch (error) {
    next(error);
  }
});

router.get('/me', requireAuth, async (req, res, next) => {
  try {
    res.json(await sessionPayload(req.user.sub));
  } catch (error) {
    next(error);
  }
});

module.exports = { router, sessionPayload };
