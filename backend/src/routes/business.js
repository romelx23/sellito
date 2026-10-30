const express = require('express');
const fs = require('fs');
const path = require('path');
const crypto = require('crypto');
const { db, UPLOAD_DIR } = require('../db');
const { requireAuth } = require('../auth');

const router = express.Router();
router.use(requireAuth);

function businessOf(req) {
  return db.prepare('SELECT * FROM businesses WHERE id = ?').get(req.user.businessId);
}

router.get('/', (req, res) => {
  const business = businessOf(req);
  if (!business) return res.status(404).json({ error: 'Negocio no encontrado' });

  const startOfDay = new Date();
  startOfDay.setHours(0, 0, 0, 0);

  const stats = {
    customers: db
      .prepare('SELECT COUNT(*) AS n FROM customers WHERE business_id = ?')
      .get(business.id).n,
    cards: db
      .prepare(
        `SELECT COUNT(*) AS n FROM cards c
         JOIN programs p ON p.id = c.program_id WHERE p.business_id = ?`,
      )
      .get(business.id).n,
    stampsToday: db
      .prepare(
        `SELECT COUNT(*) AS n FROM stamps s
         JOIN cards c ON c.id = s.card_id
         JOIN programs p ON p.id = c.program_id
         WHERE p.business_id = ? AND s.created_at >= ?`,
      )
      .get(business.id, startOfDay.toISOString()).n,
    rewardsReady: db
      .prepare(
        `SELECT COUNT(*) AS n FROM cards c
         JOIN programs p ON p.id = c.program_id
         WHERE p.business_id = ? AND c.status = 'reward_ready'`,
      )
      .get(business.id).n,
    rewardsRedeemed: db
      .prepare(
        `SELECT COUNT(*) AS n FROM reward_redemptions r
         JOIN cards c ON c.id = r.card_id
         JOIN programs p ON p.id = c.program_id
         WHERE p.business_id = ?`,
      )
      .get(business.id).n,
  };

  res.json({ business, stats });
});

router.patch('/', (req, res) => {
  const business = businessOf(req);
  if (!business) return res.status(404).json({ error: 'Negocio no encontrado' });

  const { name, brandColor } = req.body || {};
  const nextName = name && String(name).trim().length >= 2 ? String(name).trim() : business.name;
  const nextColor = /^#[0-9a-fA-F]{6}$/.test(brandColor || '')
    ? brandColor
    : business.brand_color;

  db.prepare('UPDATE businesses SET name = ?, brand_color = ? WHERE id = ?').run(
    nextName,
    nextColor,
    business.id,
  );

  res.json({ business: db.prepare('SELECT * FROM businesses WHERE id = ?').get(business.id) });
});

router.post('/logo', (req, res) => {
  const business = businessOf(req);
  if (!business) return res.status(404).json({ error: 'Negocio no encontrado' });

  const { dataUrl } = req.body || {};
  const match = /^data:(image\/(png|jpeg|jpg|webp|gif));base64,([A-Za-z0-9+/=]+)$/.exec(
    String(dataUrl || ''),
  );

  if (!match) return res.status(400).json({ error: 'Subí una imagen PNG, JPG o WEBP' });

  const ext = match[2] === 'jpeg' || match[2] === 'jpg' ? 'jpg' : match[2];
  const buffer = Buffer.from(match[3], 'base64');
  if (buffer.length > 2 * 1024 * 1024) {
    return res.status(413).json({ error: 'La imagen supera los 2 MB' });
  }

  fs.mkdirSync(UPLOAD_DIR, { recursive: true });
  const filename = `${crypto.randomUUID()}.${ext}`;
  fs.writeFileSync(path.join(UPLOAD_DIR, filename), buffer);

  const logoUrl = `/uploads/${filename}`;
  db.prepare('UPDATE businesses SET logo_url = ? WHERE id = ?').run(logoUrl, business.id);

  res.json({ logoUrl });
});

module.exports = { router, UPLOAD_DIR };
