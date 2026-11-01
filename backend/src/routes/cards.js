const express = require('express');
const crypto = require('crypto');
const { get, all, run, id, now } = require('../db');
const { requireAuth } = require('../auth');
const { addStamp, redeemReward } = require('../services/stamps');
const { randomCode } = require('../services/util');

const router = express.Router();

async function uniqueCode(slug) {
  for (let attempt = 0; attempt < 8; attempt += 1) {
    const code = randomCode(slug);
    if (!(await get('SELECT 1 FROM cards WHERE code = ?', [code]))) return code;
  }
  throw new Error('No se pudo generar un código único');
}

router.get('/business/cards', requireAuth, async (req, res, next) => {
  try {
    const q = String(req.query.q || '').trim();
    const like = `%${q}%`;

    const rows = await all(
      `SELECT c.id, c.code, c.stamps, c.status, c.updated_at,
              cu.id AS customer_id, cu.name AS customer_name, cu.phone AS customer_phone,
              cu.email AS customer_email,
              p.id AS program_id, p.name AS program_name, p.stamps_required, p.reward_text
       FROM cards c
       JOIN customers cu ON cu.id = c.customer_id
       JOIN programs p ON p.id = c.program_id
       WHERE p.business_id = ?
         AND (? = '' OR cu.name LIKE ? OR cu.phone LIKE ? OR c.code LIKE ?)
       ORDER BY c.updated_at DESC
       LIMIT 100`,
      [req.user.businessId, q, like, like, like],
    );

    res.json({
      cards: rows.map((row) => ({
        id: row.id,
        code: row.code,
        stamps: row.stamps,
        stampsRequired: row.stamps_required,
        status: row.status,
        rewardText: row.reward_text,
        updatedAt: row.updated_at,
        programId: row.program_id,
        programName: row.program_name,
        customer: {
          id: row.customer_id,
          name: row.customer_name,
          phone: row.customer_phone,
          email: row.customer_email,
        },
      })),
    });
  } catch (error) {
    next(error);
  }
});

/** Alta manual desde el mostrador (sin que el cliente escanee nada). */
router.post('/business/cards', requireAuth, async (req, res, next) => {
  try {
    const { programId, name, phone } = req.body || {};
    const program = await get('SELECT * FROM programs WHERE id = ? AND business_id = ?', [
      programId,
      req.user.businessId,
    ]);

    if (!program) return res.status(404).json({ error: 'Programa no encontrado' });
    if (!name || String(name).trim().length < 2) {
      return res.status(400).json({ error: 'Poné el nombre del cliente' });
    }

    const ts = now();
    const business = await get('SELECT * FROM businesses WHERE id = ?', [req.user.businessId]);

    let customer = phone
      ? await get('SELECT * FROM customers WHERE business_id = ? AND phone = ?', [
          req.user.businessId,
          String(phone).trim(),
        ])
      : null;

    if (!customer) {
      const customerId = id();
      await run(
        'INSERT INTO customers (id, business_id, name, phone, email, consent_at, created_at) VALUES (?, ?, ?, ?, ?, ?, ?)',
        [
          customerId,
          req.user.businessId,
          String(name).trim(),
          phone ? String(phone).trim() : null,
          null,
          ts,
          ts,
        ],
      );
      customer = await get('SELECT * FROM customers WHERE id = ?', [customerId]);
    }

    const existing = await get('SELECT * FROM cards WHERE program_id = ? AND customer_id = ?', [
      program.id,
      customer.id,
    ]);

    if (existing) {
      return res.status(409).json({ error: 'Ese cliente ya tiene una tarjeta en este programa' });
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

    res.status(201).json({ id: card.id, code: card.code });
  } catch (error) {
    next(error);
  }
});

async function ownCard(cardId, businessId) {
  return get(
    `SELECT c.* FROM cards c JOIN programs p ON p.id = c.program_id
     WHERE c.id = ? AND p.business_id = ?`,
    [cardId, businessId],
  );
}

router.post('/cards/:id/stamps', requireAuth, async (req, res, next) => {
  try {
    const card = await ownCard(req.params.id, req.user.businessId);
    if (!card) return res.status(404).json({ error: 'Tarjeta no encontrada' });

    const result = await addStamp({
      cardId: card.id,
      staffId: req.user.sub,
      source: 'manual',
      idempotencyKey: req.body?.idempotencyKey || `manual-${req.user.sub}-${card.id}-${Date.now()}`,
    });

    res.json(result);
  } catch (error) {
    next(error);
  }
});

router.post('/cards/:id/redeem', requireAuth, async (req, res, next) => {
  try {
    const card = await ownCard(req.params.id, req.user.businessId);
    if (!card) return res.status(404).json({ error: 'Tarjeta no encontrada' });

    const result = await redeemReward({
      cardId: card.id,
      staffId: req.user.sub,
      idempotencyKey: req.body?.idempotencyKey || null,
    });

    res.json(result);
  } catch (error) {
    next(error);
  }
});

module.exports = { router, uniqueCode };
