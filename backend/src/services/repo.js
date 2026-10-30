const { db } = require('../db');

function hydrate(card) {
  if (!card) return null;
  const customer = db.prepare('SELECT * FROM customers WHERE id = ?').get(card.customer_id);
  const program = db.prepare('SELECT * FROM programs WHERE id = ?').get(card.program_id);
  const business = program
    ? db.prepare('SELECT * FROM businesses WHERE id = ?').get(program.business_id)
    : null;
  if (!customer || !program || !business) return null;
  return { card, customer, program, business };
}

function cardByCode(code) {
  const card = db.prepare('SELECT * FROM cards WHERE code = ?').get(code);
  return hydrate(card);
}

function cardById(cardId) {
  const card = db.prepare('SELECT * FROM cards WHERE id = ?').get(cardId);
  return hydrate(card);
}

function activeProgramBySlug(slug) {
  return db
    .prepare(
      `SELECT p.* FROM programs p
       JOIN businesses b ON b.id = p.business_id
       WHERE b.slug = ? AND p.active = 1
       ORDER BY p.created_at ASC LIMIT 1`,
    )
    .get(slug);
}

function businessBySlug(slug) {
  return db.prepare('SELECT * FROM businesses WHERE slug = ?').get(slug);
}

module.exports = { hydrate, cardByCode, cardById, activeProgramBySlug, businessBySlug };
