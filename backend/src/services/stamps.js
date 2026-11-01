const { get, batch, id, now } = require('../db');
const { HttpError } = require('./util');

function getCardBundle(cardId) {
  return get(
    `SELECT c.*, cu.name AS customer_name, cu.phone AS customer_phone, cu.email AS customer_email
     FROM cards c JOIN customers cu ON cu.id = c.customer_id
     WHERE c.id = ?`,
    [cardId],
  );
}

/**
 * `extra` son escrituras que deben quedar atómicas con el sello (por ejemplo, el registro del QR usado).
 */
async function addStamp({ cardId, staffId, source = 'manual', idempotencyKey = null, extra = [] }) {
  const card = await getCardBundle(cardId);
  if (!card) throw new HttpError(404, 'Tarjeta no encontrada');

  const program = await get('SELECT * FROM programs WHERE id = ?', [card.program_id]);
  if (!program) throw new HttpError(404, 'Programa no encontrado');
  if (!program.active) throw new HttpError(409, 'Este programa está pausado');

  if (card.status === 'reward_ready') {
    throw new HttpError(409, 'Esta tarjeta ya tiene una recompensa pendiente de canje');
  }

  if (idempotencyKey) {
    const repeated = await get('SELECT * FROM stamps WHERE idempotency_key = ?', [idempotencyKey]);
    if (repeated) {
      return { cardId, duplicate: true, stamps: card.stamps, status: card.status };
    }
  }

  if (program.cooldown_minutes > 0) {
    const last = await get(
      'SELECT created_at FROM stamps WHERE card_id = ? ORDER BY created_at DESC LIMIT 1',
      [cardId],
    );

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
    const { total } = await get(
      'SELECT COUNT(*) AS total FROM stamps WHERE card_id = ? AND created_at >= ?',
      [cardId, startOfDay.toISOString()],
    );

    if (total >= program.max_per_day) {
      throw new HttpError(429, 'Se alcanzó el máximo de sellos por día para esta tarjeta');
    }
  }

  const next = card.stamps + 1;
  const status = next >= program.stamps_required ? 'reward_ready' : 'active';
  const ts = now();

  await batch([
    ...extra,
    [
      'UPDATE cards SET stamps = ?, status = ?, updated_at = ? WHERE id = ?',
      [next, status, ts, cardId],
    ],
    [
      'INSERT INTO stamps (id, card_id, staff_id, source, idempotency_key, created_at) VALUES (?, ?, ?, ?, ?, ?)',
      [id(), cardId, staffId || null, source, idempotencyKey, ts],
    ],
  ]);

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

async function redeemReward({ cardId, staffId, idempotencyKey = null }) {
  const card = await getCardBundle(cardId);
  if (!card) throw new HttpError(404, 'Tarjeta no encontrada');
  if (card.status !== 'reward_ready') {
    throw new HttpError(409, 'Todavía no hay una recompensa lista en esta tarjeta');
  }

  if (idempotencyKey) {
    const repeated = await get(
      'SELECT * FROM reward_redemptions WHERE idempotency_key = ?',
      [idempotencyKey],
    );
    if (repeated) return { cardId, duplicate: true, stamps: card.stamps };
  }

  const program = await get('SELECT * FROM programs WHERE id = ?', [card.program_id]);
  const ts = now();

  await batch([
    [
      'UPDATE cards SET stamps = 0, status = ?, updated_at = ? WHERE id = ?',
      ['active', ts, cardId],
    ],
    [
      'INSERT INTO reward_redemptions (id, card_id, staff_id, reward_text, idempotency_key, redeemed_at) VALUES (?, ?, ?, ?, ?, ?)',
      [id(), cardId, staffId || null, program?.reward_text || null, idempotencyKey, ts],
    ],
  ]);

  return { cardId, duplicate: false, stamps: 0, status: 'active' };
}

module.exports = { addStamp, redeemReward, getCardBundle };
