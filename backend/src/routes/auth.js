const express = require('express');
const bcrypt = require('bcryptjs');
const { db, id, now } = require('../db');
const { sign, requireAuth } = require('../auth');
const { slugify, normalizeStyle } = require('../services/util');

const router = express.Router();

function uniqueSlug(base) {
  const root = slugify(base);
  let slug = root;
  let n = 1;
  while (db.prepare('SELECT 1 FROM businesses WHERE slug = ?').get(slug)) {
    n += 1;
    slug = `${root}-${n}`;
  }
  return slug;
}

function sessionPayload(userId) {
  const user = db.prepare('SELECT * FROM users WHERE id = ?').get(userId);
  const business = db.prepare('SELECT * FROM businesses WHERE id = ?').get(user.business_id);
  const programs = db
    .prepare('SELECT * FROM programs WHERE business_id = ? ORDER BY created_at ASC')
    .all(business.id)
    .map((p) => ({ ...p, style: JSON.parse(p.style_json), active: Boolean(p.active) }));

  return {
    user: { id: user.id, name: user.name, email: user.email, role: user.role },
    business,
    programs,
  };
}

router.post('/register', (req, res) => {
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
  if (db.prepare('SELECT 1 FROM users WHERE email = ?').get(normalizedEmail)) {
    return res.status(409).json({ error: 'Ese email ya tiene una cuenta' });
  }

  const businessId = id();
  const userId = id();
  const ts = now();
  const slug = uniqueSlug(businessName);
  const color = /^#[0-9a-fA-F]{6}$/.test(brandColor || '') ? brandColor : '#0F766E';

  const create = db.transaction(() => {
    db.prepare(
      'INSERT INTO businesses (id, name, slug, brand_color, created_at) VALUES (?, ?, ?, ?, ?)',
    ).run(businessId, String(businessName).trim(), slug, color, ts);

    db.prepare(
      'INSERT INTO users (id, business_id, email, password_hash, name, role, created_at) VALUES (?, ?, ?, ?, ?, ?, ?)',
    ).run(
      userId,
      businessId,
      normalizedEmail,
      bcrypt.hashSync(String(password), 10),
      String(name || businessName).trim(),
      'owner',
      ts,
    );

    db.prepare(
      `INSERT INTO programs
        (id, business_id, name, description, reward_text, stamps_required, cooldown_minutes, max_per_day, style_json, active, created_at)
       VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, 1, ?)`,
    ).run(
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
    );
  });
  create();

  const user = db.prepare('SELECT * FROM users WHERE id = ?').get(userId);
  res.status(201).json({ token: sign(user), ...sessionPayload(userId) });
});

router.post('/login', (req, res) => {
  const { email, password } = req.body || {};
  const user = db
    .prepare('SELECT * FROM users WHERE email = ?')
    .get(String(email || '').toLowerCase().trim());

  if (!user || !bcrypt.compareSync(String(password || ''), user.password_hash)) {
    return res.status(401).json({ error: 'Email o contraseña incorrectos' });
  }

  res.json({ token: sign(user), ...sessionPayload(user.id) });
});

router.get('/me', requireAuth, (req, res) => {
  res.json(sessionPayload(req.user.sub));
});

module.exports = { router, sessionPayload };
