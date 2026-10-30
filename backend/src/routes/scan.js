const express = require('express');
const { db, now, cleanupQrUses } = require('../db');
const { requireAuth } = require('../auth');
const { cardById } = require('../services/repo');
const { addStamp } = require('../services/stamps');
const { merchantCard } = require('../services/util');
const qr = require('../services/qr');

const router = express.Router();

router.post('/', requireAuth, (req, res, next) => {
  try {
    const { token, idempotencyKey } = req.body || {};
    if (!token) return res.status(400).json({ error: 'No se recibió ningún QR' });

    let parsed;
    try {
      parsed = qr.parse(token);
    } catch (error) {
      return res.status(400).json({ error: error.message });
    }

    const bundle = cardById(parsed.cardId);
    if (!bundle) return res.status(404).json({ error: 'La tarjeta no existe' });

    if (bundle.program.business_id !== req.user.businessId) {
      return res.status(403).json({ error: 'Esa tarjeta pertenece a otro negocio' });
    }

    try {
      qr.verifySignature(token, bundle.card.secret);
    } catch (error) {
      return res.status(400).json({ error: error.message });
    }

    const tokenHash = qr.hashToken(token);

    let result;
    try {
      result = db.transaction(() => {
        db.prepare('INSERT INTO qr_uses (token_hash, card_id, used_at) VALUES (?, ?, ?)').run(
          tokenHash,
          bundle.card.id,
          now(),
        );
        return addStamp({
          cardId: bundle.card.id,
          staffId: req.user.sub,
          source: 'scan',
          idempotencyKey: idempotencyKey || `qr-${tokenHash}`,
        });
      })();
    } catch (error) {
      if (String(error.message).includes('UNIQUE constraint failed: qr_uses.token_hash')) {
        return res.status(409).json({ error: 'Ese QR ya se usó. Pedile que lo actualice.' });
      }
      throw error;
    }

    cleanupQrUses();

    const fresh = cardById(bundle.card.id);
    res.json({
      ...result,
      card: merchantCard(fresh),
      alreadyStamped: result.duplicate,
    });
  } catch (error) {
    next(error);
  }
});

module.exports = { router };
