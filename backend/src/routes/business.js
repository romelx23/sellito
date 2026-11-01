const express = require('express');
const fs = require('fs');
const path = require('path');
const crypto = require('crypto');
const { get, run, UPLOAD_DIR } = require('../db');
const { requireAuth } = require('../auth');

const router = express.Router();
router.use(requireAuth);

function businessOf(req) {
  return get('SELECT * FROM businesses WHERE id = ?', [req.user.businessId]);
}

const count = async (sql, args) => (await get(sql, args)).n;

router.get('/', async (req, res, next) => {
  try {
    const business = await businessOf(req);
    if (!business) return res.status(404).json({ error: 'Negocio no encontrado' });

    const startOfDay = new Date();
    startOfDay.setHours(0, 0, 0, 0);

    const stats = {
      customers: await count('SELECT COUNT(*) AS n FROM customers WHERE business_id = ?', [
        business.id,
      ]),
      cards: await count(
        `SELECT COUNT(*) AS n FROM cards c
         JOIN programs p ON p.id = c.program_id WHERE p.business_id = ?`,
        [business.id],
      ),
      stampsToday: await count(
        `SELECT COUNT(*) AS n FROM stamps s
         JOIN cards c ON c.id = s.card_id
         JOIN programs p ON p.id = c.program_id
         WHERE p.business_id = ? AND s.created_at >= ?`,
        [business.id, startOfDay.toISOString()],
      ),
      rewardsReady: await count(
        `SELECT COUNT(*) AS n FROM cards c
         JOIN programs p ON p.id = c.program_id
         WHERE p.business_id = ? AND c.status = 'reward_ready'`,
        [business.id],
      ),
      rewardsRedeemed: await count(
        `SELECT COUNT(*) AS n FROM reward_redemptions r
         JOIN cards c ON c.id = r.card_id
         JOIN programs p ON p.id = c.program_id
         WHERE p.business_id = ?`,
        [business.id],
      ),
    };

    res.json({ business, stats });
  } catch (error) {
    next(error);
  }
});

router.patch('/', async (req, res, next) => {
  try {
    const business = await businessOf(req);
    if (!business) return res.status(404).json({ error: 'Negocio no encontrado' });

    const { name, brandColor } = req.body || {};
    const nextName = name && String(name).trim().length >= 2 ? String(name).trim() : business.name;
    const nextColor = /^#[0-9a-fA-F]{6}$/.test(brandColor || '')
      ? brandColor
      : business.brand_color;

    await run('UPDATE businesses SET name = ?, brand_color = ? WHERE id = ?', [
      nextName,
      nextColor,
      business.id,
    ]);

    res.json({ business: await get('SELECT * FROM businesses WHERE id = ?', [business.id]) });
  } catch (error) {
    next(error);
  }
});

router.post('/logo', async (req, res, next) => {
  try {
    const business = await businessOf(req);
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
    await run('UPDATE businesses SET logo_url = ? WHERE id = ?', [logoUrl, business.id]);

    res.json({ logoUrl });
  } catch (error) {
    next(error);
  }
});

module.exports = { router, UPLOAD_DIR };
