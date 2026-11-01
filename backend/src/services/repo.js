const { get } = require('../db');

async function hydrate(card) {
  if (!card) return null;
  const customer = await get('SELECT * FROM customers WHERE id = ?', [card.customer_id]);
  const program = await get('SELECT * FROM programs WHERE id = ?', [card.program_id]);
  const business = program
    ? await get('SELECT * FROM businesses WHERE id = ?', [program.business_id])
    : null;
  if (!customer || !program || !business) return null;
  return { card, customer, program, business };
}

async function cardByCode(code) {
  const card = await get('SELECT * FROM cards WHERE code = ?', [code]);
  return hydrate(card);
}

async function cardById(cardId) {
  const card = await get('SELECT * FROM cards WHERE id = ?', [cardId]);
  return hydrate(card);
}

function activeProgramBySlug(slug) {
  return get(
    `SELECT p.* FROM programs p
     JOIN businesses b ON b.id = p.business_id
     WHERE b.slug = ? AND p.active = 1
     ORDER BY p.created_at ASC LIMIT 1`,
    [slug],
  );
}

function businessBySlug(slug) {
  return get('SELECT * FROM businesses WHERE slug = ?', [slug]);
}

module.exports = { hydrate, cardByCode, cardById, activeProgramBySlug, businessBySlug };
