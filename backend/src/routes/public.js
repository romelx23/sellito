const express = require('express');
const crypto = require('crypto');
const { get, run, id, now } = require('../db');
const { uniqueCode } = require('./cards');
const { cardByCode, activeProgramBySlug, businessBySlug } = require('../services/repo');
const { publicCard } = require('../services/util');
const { qrDataUrl } = require('../services/html');
const qr = require('../services/qr');

const router = express.Router();

router.get('/programs/:slug', async (req, res, next) => {
  try {
    const business = await businessBySlug(req.params.slug);
    const program = await activeProgramBySlug(req.params.slug);
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
  } catch (error) {
    next(error);
  }
});

router.post('/programs/:slug/join', async (req, res, next) => {
  try {
    const { name, phone, email, consent } = req.body || {};
    const business = await businessBySlug(req.params.slug);
    const program = await activeProgramBySlug(req.params.slug);

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

    let customer = await get('SELECT * FROM customers WHERE business_id = ? AND phone = ?', [
      business.id,
      cleanPhone,
    ]);

    if (!customer) {
      const customerId = id();
      await run(
        `INSERT INTO customers (id, business_id, name, phone, email, consent_at, created_at)
         VALUES (?, ?, ?, ?, ?, ?, ?)`,
        [customerId, business.id, cleanName, cleanPhone, email || null, ts, ts],
      );
      customer = await get('SELECT * FROM customers WHERE id = ?', [customerId]);
    } else if (customer.name !== cleanName) {
      await run('UPDATE customers SET name = ? WHERE id = ?', [cleanName, customer.id]);
      customer.name = cleanName;
    }

    const existing = await get('SELECT * FROM cards WHERE program_id = ? AND customer_id = ?', [
      program.id,
      customer.id,
    ]);

    if (existing) {
      return res.json({ code: existing.code, created: false });
    }

    const card = {
      id: id(),
      program_id: program.id,
      customer_id: customer.id,
      code: await uniqueCode(business.slug),
      stamps: 0,
      status: 'active',
      secret: crypto.randomBytes(24).toString('base64url'),
      created_at: ts,
      updated_at: ts,
    };

    await run(
      `INSERT INTO cards (id, program_id, customer_id, code, stamps, status, secret, created_at, updated_at)
       VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?)`,
      [
        card.id,
        card.program_id,
        card.customer_id,
        card.code,
        card.stamps,
        card.status,
        card.secret,
        card.created_at,
        card.updated_at,
      ],
    );

    res.status(201).json({ code: card.code, created: true });
  } catch (error) {
    next(error);
  }
});

router.get('/cards/:code', async (req, res, next) => {
  try {
    const bundle = await cardByCode(req.params.code);
    if (!bundle) return res.status(404).json({ error: 'Tarjeta no encontrada' });

    const token = qr.sign(bundle.card.id, bundle.card.secret, 60);
    const dataUrl = await qrDataUrl(token);

    res.json({
      ...publicCard(bundle),
      qr: { token, expiresAt: Date.now() + 60000, dataUrl },
    });
  } catch (error) {
    next(error);
  }
});

router.get('/cards/:code/qr', async (req, res, next) => {
  try {
    const bundle = await cardByCode(req.params.code);
    if (!bundle) return res.status(404).json({ error: 'Tarjeta no encontrada' });

    res.json({
      token: qr.sign(bundle.card.id, bundle.card.secret, 60),
      expiresAt: Date.now() + 60000,
    });
  } catch (error) {
    next(error);
  }
});

module.exports = { router };
