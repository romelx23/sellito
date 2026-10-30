const express = require('express');
const { db, id, now } = require('../db');
const { requireAuth } = require('../auth');
const { addStamp, redeemReward } = require('../services/stamps');
const { randomCode } = require('../services/util');

const router = express.Router();
function uniqueCode(slug) {
  for (let attempt = 0; attempt < 8; attempt += 1) {
    const code = randomCode(slug);
    if (!db.prepare('SELECT 1 FROM cards WHERE code = ?').get(code)) return code;
  }
  throw new Error('No se pudo generar un código único');
}

router.get('/business/cards', requireAuth, (req, res) => {
  const q = String(req.query.q || '').trim();
  const like = `%${q}%`;

  const rows = db
    .prepare(
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
    )
    .all(req.user.businessId, q, like, like, like);

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
});

/** Alta manual desde el mostrador (sin que el cliente escanee nada). */
router.post('/business/cards', requireAuth, (req, res) => {
  const { programId, name, phone } = req.body || {};
  const program = db
    .prepare('SELECT * FROM programs WHERE id = ? AND business_id = ?')
    .get(programId, req.user.businessId);

  if (!program) return res.status(404).json({ error: 'Programa no encontrado' });
  if (!name || String(name).trim().length < 2) {
    return res.status(400).json({ error: 'Poné el nombre del cliente' });
  }

  const ts = now();
  const business = db.prepare('SELECT * FROM businesses WHERE id = ?').get(req.user.businessId);

  let customer = phone
    ? db
        .prepare('SELECT * FROM customers WHERE business_id = ? AND phone = ?')
        .get(req.user.businessId, String(phone).trim())
    : null;

  if (!customer) {
    const customerId = id();
    db.prepare(
      'INSERT INTO customers (id, business_id, name, phone, email, consent_at, created_at) VALUES (?, ?, ?, ?, ?, ?, ?)',
    ).run(
      customerId,
      req.user.businessId,
      String(name).trim(),
      phone ? String(phone).trim() : null,
      null,
      ts,
      ts,
    );
    customer = db.prepare('SELECT * FROM customers WHERE id = ?').get(customerId);
  }

  const existing = db
    .prepare('SELECT * FROM cards WHERE program_id = ? AND customer_id = ?')
    .get(program.id, customer.id);

  if (existing) {
    return res.status(409).json({ error: 'Ese cliente ya tiene una tarjeta en este programa' });
  }

  const card = {
    id: id(),
    program_id: program.id,
    customer_id: customer.id,
    code: uniqueCode(business.slug),
    stamps: 0,
    status: 'active',
    secret: require('crypto').randomBytes(24).toString('base64url'),
    created_at: ts,
    updated_at: ts,
  };

  db.prepare(
    `INSERT INTO cards (id, program_id, customer_id, code, stamps, status, secret, created_at, updated_at)
     VALUES (@id, @program_id, @customer_id, @code, @stamps, @status, @secret, @created_at, @updated_at)`,
  ).run(card);

  res.status(201).json({ id: card.id, code: card.code });
});

router.post('/cards/:id/stamps', requireAuth, (req, res) => {
  const card = db
    .prepare(
      `SELECT c.* FROM cards c JOIN programs p ON p.id = c.program_id
       WHERE c.id = ? AND p.business_id = ?`,
    )
    .get(req.params.id, req.user.businessId);

  if (!card) return res.status(404).json({ error: 'Tarjeta no encontrada' });

  const result = addStamp({
    cardId: card.id,
    staffId: req.user.sub,
    source: 'manual',
    idempotencyKey: req.body?.idempotencyKey || `manual-${req.user.sub}-${card.id}-${Date.now()}`,
  });

  res.json(result);
});

router.post('/cards/:id/redeem', requireAuth, (req, res) => {
  const card = db
    .prepare(
      `SELECT c.* FROM cards c JOIN programs p ON p.id = c.program_id
       WHERE c.id = ? AND p.business_id = ?`,
    )
    .get(req.params.id, req.user.businessId);

  if (!card) return res.status(404).json({ error: 'Tarjeta no encontrada' });

  const result = redeemReward({
    cardId: card.id,
    staffId: req.user.sub,
    idempotencyKey: req.body?.idempotencyKey || null,
  });

  res.json(result);
});

module.exports = { router, uniqueCode };
