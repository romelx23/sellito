const bcrypt = require('bcryptjs');
const crypto = require('crypto');
const { get, batch, id, now } = require('./db');

const PASSWORD = 'demo1234';

async function hasData() {
  return (await get('SELECT COUNT(*) AS n FROM businesses', [])).n > 0;
}

/** Cada helper devuelve sentencias SQL pendientes en `q`; seed() las ejecuta en una sola transacción. */
function insertBusiness(q, { name, slug, color, email, ownerName }) {
  const businessId = id();
  const userId = id();
  const ts = now();

  q.push([
    'INSERT INTO businesses (id, name, slug, brand_color, created_at) VALUES (?, ?, ?, ?, ?)',
    [businessId, name, slug, color, ts],
  ]);

  q.push([
    'INSERT INTO users (id, business_id, email, password_hash, name, role, created_at) VALUES (?, ?, ?, ?, ?, ?, ?)',
    [userId, businessId, email, bcrypt.hashSync(PASSWORD, 10), ownerName, 'owner', ts],
  ]);

  return { businessId, userId };
}

function insertProgram(q, { businessId, name, description, reward, stampsRequired, style, cooldown = 0 }) {
  const programId = id();
  q.push([
    `INSERT INTO programs
      (id, business_id, name, description, reward_text, stamps_required, cooldown_minutes, max_per_day, style_json, active, created_at)
     VALUES (?, ?, ?, ?, ?, ?, ?, 0, ?, 1, ?)`,
    [programId, businessId, name, description, reward, stampsRequired, cooldown, JSON.stringify(style), now()],
  ]);
  return programId;
}

function insertCard(q, { programId, businessId, name, phone, code, stamps, status, staffId, redeemed }) {
  const ts = now();
  const customerId = id();

  q.push([
    'INSERT INTO customers (id, business_id, name, phone, email, consent_at, created_at) VALUES (?, ?, ?, ?, ?, ?, ?)',
    [customerId, businessId, name, phone, null, ts, ts],
  ]);

  const cardId = id();
  q.push([
    `INSERT INTO cards (id, program_id, customer_id, code, stamps, status, secret, created_at, updated_at)
     VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?)`,
    [cardId, programId, customerId, code, stamps, status, crypto.randomBytes(24).toString('base64url'), ts, ts],
  ]);

  for (let i = 0; i < stamps; i += 1) {
    q.push([
      'INSERT INTO stamps (id, card_id, staff_id, source, idempotency_key, created_at) VALUES (?, ?, ?, ?, ?, ?)',
      [
        id(),
        cardId,
        staffId,
        i === 0 ? 'manual' : 'scan',
        `seed-${cardId}-${i}`,
        new Date(Date.now() - i * 36 * 60 * 1000).toISOString(),
      ],
    ]);
  }

  if (redeemed) {
    q.push([
      'INSERT INTO reward_redemptions (id, card_id, staff_id, reward_text, idempotency_key, redeemed_at) VALUES (?, ?, ?, ?, ?, ?)',
      [
        id(),
        cardId,
        staffId,
        redeemed,
        `seed-redeem-${cardId}`,
        new Date(Date.now() - 3 * 24 * 60 * 60 * 1000).toISOString(),
      ],
    ]);
  }

  return cardId;
}

async function seed() {
  if (await hasData()) return { skipped: true, businesses: 0 };

  let businesses = 0;
  const q = [];

  {
    const cafe = insertBusiness(q, {
      name: 'Café Aurora',
      slug: 'cafe-aurora',
      color: '#A24B2A',
      email: 'demo@sella.app',
      ownerName: 'Lucía',
    });

    const cafeProgram = insertProgram(q, {
      businessId: cafe.businessId,
      name: 'Club Aurora',
      description: 'Cada visita suma. Cada 8 sellos, un premio.',
      reward: 'Un flat white de especialidad gratis',
      stampsRequired: 8,
      style: {
        template: 'ticket',
        background: '#A24B2A',
        foreground: '#FFF7ED',
        accent: '#F2C14E',
        stampIcon: 'coffee',
        pattern: 'dots',
        cornerRadius: 26,
        showLogo: true,
      },
    });

    insertCard(q, {
      programId: cafeProgram,
      businessId: cafe.businessId,
      name: 'Ana Pérez',
      phone: '+54 11 5555 0101',
      code: 'CAFE-DEMO',
      stamps: 3,
      status: 'active',
      staffId: cafe.userId,
    });

    insertCard(q, {
      programId: cafeProgram,
      businessId: cafe.businessId,
      name: 'Bruno Díaz',
      phone: '+54 11 5555 0102',
      code: 'CAFE-8F3K',
      stamps: 8,
      status: 'reward_ready',
      staffId: cafe.userId,
    });

    insertCard(q, {
      programId: cafeProgram,
      businessId: cafe.businessId,
      name: 'Carla Ruiz',
      phone: '+54 11 5555 0103',
      code: 'CAFE-L2QX',
      stamps: 0,
      status: 'active',
      staffId: cafe.userId,
    });

    insertCard(q, {
      programId: cafeProgram,
      businessId: cafe.businessId,
      name: 'Elena Gómez',
      phone: '+54 11 5555 0104',
      code: 'CAFE-R3ED',
      stamps: 2,
      status: 'active',
      staffId: cafe.userId,
      redeemed: 'Un flat white de especialidad gratis',
    });

    const barber = insertBusiness(q, {
      name: 'Barbería Norte',
      slug: 'barberia-norte',
      color: '#1E3A5F',
      email: 'barber@sella.app',
      ownerName: 'Martín',
    });

    const barberProgram = insertProgram(q, {
      businessId: barber.businessId,
      name: 'Corte Club',
      description: 'Diez cortes, uno gratis.',
      reward: 'Un corte de pelo gratis',
      stampsRequired: 10,
      style: {
        template: 'bold',
        background: '#1E3A5F',
        foreground: '#F8FAFC',
        accent: '#E8B04B',
        stampIcon: 'star',
        pattern: 'grid',
        cornerRadius: 18,
        showLogo: true,
      },
    });

    insertCard(q, {
      programId: barberProgram,
      businessId: barber.businessId,
      name: 'Diego Sosa',
      phone: '+54 11 5555 0201',
      code: 'NORT-DEMO',
      stamps: 4,
      status: 'active',
      staffId: barber.userId,
    });

    const tomillo = insertBusiness(q, {
      name: 'Cafetería Tomillo',
      slug: 'cafeteria-tomillo',
      color: '#3F2D5C',
      email: 'cafe@sella.app',
      ownerName: 'Sofía',
    });

    const tomilloProgram = insertProgram(q, {
      businessId: tomillo.businessId,
      name: 'Tomillo Club',
      description: 'Cada café suma. Cada 10 sellos, una medialuna.',
      reward: 'Una medialuna gratis',
      stampsRequired: 10,
      style: {
        template: 'retro',
        background: '#3F2D5C',
        foreground: '#FFF4EC',
        accent: '#F0B7A4',
        stampIcon: 'circle',
        pattern: 'waves',
        cornerRadius: 30,
        showLogo: true,
      },
    });

    insertCard(q, {
      programId: tomilloProgram,
      businessId: tomillo.businessId,
      name: 'Julieta Motta',
      phone: '+54 11 5555 0301',
      code: 'TOMI-DEMO',
      stamps: 6,
      status: 'active',
      staffId: tomillo.userId,
    });

    insertCard(q, {
      programId: tomilloProgram,
      businessId: tomillo.businessId,
      name: 'Tomás Vega',
      phone: '+54 11 5555 0302',
      code: 'TOMI-7QWN',
      stamps: 10,
      status: 'reward_ready',
      staffId: tomillo.userId,
    });

    businesses = 3;
  }

  await batch(q);

  return { skipped: false, businesses };
}

if (require.main === module) {
  seed()
    .then((result) => {
      console.log(result.skipped ? 'Ya había datos, no se tocó nada.' : 'Datos demo creados.');
      console.log('Negocio: demo@sella.app / demo1234');
      console.log('Cliente: CAFE-DEMO');
    })
    .catch((error) => {
      console.error(error);
      process.exitCode = 1;
    });
}

module.exports = { seed, hasData, PASSWORD };
