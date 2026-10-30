const express = require('express');
const crypto = require('crypto');
const { db, id, now } = require('../db');
const { uniqueCode } = require('./cards');
const { cardByCode, activeProgramBySlug, businessBySlug } = require('../services/repo');
const { publicCard } = require('../services/util');
const { qrDataUrl } = require('../services/html');
const qr = require('../services/qr');

const router = express.Router();

router.get('/programs/:slug', (req, res) => {
  const business = businessBySlug(req.params.slug);
  const program = activeProgramBySlug(req.params.slug);
  if (!business || !program) return res.status(404).json({ error: 'Programa no encontrado' });

  res.json({
    business: {
      name: business.name,
      slug: business.slug,
      logoUrl: business.logo_url,
      brandColor: business.brand_color,
    },
    program: {
      name: program.name,
      description: program.description,
      rewardText: program.reward_text,
      stampsRequired: program.stamps_required,
      style: JSON.parse(program.style_json),
    },
  });
});

router.post('/programs/:slug/join', (req, res) => {
  const { name, phone, email, consent } = req.body || {};
  const business = businessBySlug(req.params.slug);
  const program = activeProgramBySlug(req.params.slug);

  if (!business || !program) return res.status(404).json({ error: 'Programa no encontrado' });
  if (!name || String(name).trim().length < 2) {
    return res.status(400).json({ error: 'Necesitamos tu nombre' });
  }
  if (!phone || String(phone).replace(/\D/g, '').length < 6) {
    return res.status(400).json({ error: 'Necesitamos un teléfono de contacto' });
  }
  if (consent !== true) {
    return res.status(400).json({ error: 'Necesitamos tu consentimiento para guardar los datos' });
  }

  const cleanPhone = String(phone).trim();
  const cleanName = String(name).trim();
  const ts = now();

  let customer = db
    .prepare('SELECT * FROM customers WHERE business_id = ? AND phone = ?')
    .get(business.id, cleanPhone);

  if (!customer) {
    const customerId = id();
    db.prepare(
      `INSERT INTO customers (id, business_id, name, phone, email, consent_at, created_at)
       VALUES (?, ?, ?, ?, ?, ?, ?)`,
    ).run(customerId, business.id, cleanName, cleanPhone, email || null, ts, ts);
    customer = db.prepare('SELECT * FROM customers WHERE id = ?').get(customerId);
  } else if (customer.name !== cleanName) {
    db.prepare('UPDATE customers SET name = ? WHERE id = ?').run(cleanName, customer.id);
    customer.name = cleanName;
  }

  const existing = db
    .prepare('SELECT * FROM cards WHERE program_id = ? AND customer_id = ?')
    .get(program.id, customer.id);

  if (existing) {
    return res.json({ code: existing.code, created: false });
  }

  const card = {
    id: id(),
    program_id: program.id,
    customer_id: customer.id,
    code: uniqueCode(business.slug),
    stamps: 0,
    status: 'active',
    secret: crypto.randomBytes(24).toString('base64url'),
    created_at: ts,
    updated_at: ts,
  };

  db.prepare(
    `INSERT INTO cards (id, program_id, customer_id, code, stamps, status, secret, created_at, updated_at)
     VALUES (@id, @program_id, @customer_id, @code, @stamps, @status, @secret, @created_at, @updated_at)`,
  ).run(card);

  res.status(201).json({ code: card.code, created: true });
});

router.get('/cards/:code', async (req, res) => {
  const bundle = cardByCode(req.params.code);
  if (!bundle) return res.status(404).json({ error: 'Tarjeta no encontrada' });

  const token = qr.sign(bundle.card.id, bundle.card.secret, 60);
  const dataUrl = await qrDataUrl(token);

  res.json({
    ...publicCard(bundle),
    qr: { token, expiresAt: Date.now() + 60000, dataUrl },
  });
});

router.get('/cards/:code/qr', (req, res) => {
  const bundle = cardByCode(req.params.code);
  if (!bundle) return res.status(404).json({ error: 'Tarjeta no encontrada' });

  res.json({
    token: qr.sign(bundle.card.id, bundle.card.secret, 60),
    expiresAt: Date.now() + 60000,
  });
});

module.exports = { router };
