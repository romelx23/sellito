const { db, id, now } = require('../db');
const { HttpError } = require('./util');

function getCardBundle(cardId) {
  return db
    .prepare(
      `SELECT c.*, cu.name AS customer_name, cu.phone AS customer_phone, cu.email AS customer_email
       FROM cards c JOIN customers cu ON cu.id = c.customer_id
       WHERE c.id = ?`,
    )
    .get(cardId);
}

function addStamp({ cardId, staffId, source = 'manual', idempotencyKey = null }) {
  const card = getCardBundle(cardId);
  if (!card) throw new HttpError(404, 'Tarjeta no encontrada');

  const program = db.prepare('SELECT * FROM programs WHERE id = ?').get(card.program_id);
  if (!program) throw new HttpError(404, 'Programa no encontrado');
  if (!program.active) throw new HttpError(409, 'Este programa está pausado');

  if (card.status === 'reward_ready') {
    throw new HttpError(409, 'Esta tarjeta ya tiene una recompensa pendiente de canje');
  }

  if (idempotencyKey) {
    const repeated = db
      .prepare('SELECT * FROM stamps WHERE idempotency_key = ?')
      .get(idempotencyKey);
    if (repeated) {
      return { cardId, duplicate: true, stamps: card.stamps, status: card.status };
    }
  }

  if (program.cooldown_minutes > 0) {
    const last = db
      .prepare('SELECT created_at FROM stamps WHERE card_id = ? ORDER BY created_at DESC LIMIT 1')
      .get(cardId);

    if (last) {
      const elapsed = (Date.now() - new Date(last.created_at).getTime()) / 60000;
      if (elapsed < program.cooldown_minutes) {
        const wait = Math.ceil(program.cooldown_minutes - elapsed);
        throw new HttpError(429, `Espera ${wait} min antes del próximo sello`);
      }
    }
  }

  if (program.max_per_day > 0) {
    const startOfDay = new Date();
    startOfDay.setHours(0, 0, 0, 0);
    const { total } = db
      .prepare('SELECT COUNT(*) AS total FROM stamps WHERE card_id = ? AND created_at >= ?')
      .get(cardId, startOfDay.toISOString());

    if (total >= program.max_per_day) {
      throw new HttpError(429, 'Se alcanzó el máximo de sellos por día para esta tarjeta');
    }
  }

  const next = card.stamps + 1;
  const status = next >= program.stamps_required ? 'reward_ready' : 'active';
  const ts = now();

  const run = db.transaction(() => {
    db.prepare('UPDATE cards SET stamps = ?, status = ?, updated_at = ? WHERE id = ?').run(
      next,
      status,
      ts,
      cardId,
    );
    db.prepare(
      'INSERT INTO stamps (id, card_id, staff_id, source, idempotency_key, created_at) VALUES (?, ?, ?, ?, ?, ?)',
    ).run(id(), cardId, staffId || null, source, idempotencyKey, ts);
  });
  run();

  return {
    cardId,
    duplicate: false,
    stamps: next,
    stampsRequired: program.stamps_required,
    status,
    completed: status === 'reward_ready',
    rewardText: program.reward_text,
  };
}

function redeemReward({ cardId, staffId, idempotencyKey = null }) {
  const card = getCardBundle(cardId);
  if (!card) throw new HttpError(404, 'Tarjeta no encontrada');
  if (card.status !== 'reward_ready') {
    throw new HttpError(409, 'Todavía no hay una recompensa lista en esta tarjeta');
  }

  if (idempotencyKey) {
    const repeated = db
      .prepare('SELECT * FROM reward_redemptions WHERE idempotency_key = ?')
      .get(idempotencyKey);
    if (repeated) return { cardId, duplicate: true, stamps: card.stamps };
  }

  const program = db.prepare('SELECT * FROM programs WHERE id = ?').get(card.program_id);
  const ts = now();

  db.transaction(() => {
    db.prepare('UPDATE cards SET stamps = 0, status = ?, updated_at = ? WHERE id = ?').run(
      'active',
      ts,
      cardId,
    );
    db.prepare(
      'INSERT INTO reward_redemptions (id, card_id, staff_id, reward_text, idempotency_key, redeemed_at) VALUES (?, ?, ?, ?, ?, ?)',
    ).run(id(), cardId, staffId || null, program?.reward_text || null, idempotencyKey, ts);
  })();

  return { cardId, duplicate: false, stamps: 0, status: 'active' };
}

module.exports = { addStamp, redeemReward, getCardBundle };
