const express = require('express');
const { get, now, cleanupQrUses } = require('../db');
const { requireAuth } = require('../auth');
const { cardById } = require('../services/repo');
const { addStamp } = require('../services/stamps');
const { merchantCard } = require('../services/util');
const qr = require('../services/qr');

const router = express.Router();

router.post('/', requireAuth, async (req, res, next) => {
  try {
    const { token, idempotencyKey } = req.body || {};
    if (!token) return res.status(400).json({ error: 'No se recibió ningún QR' });

    let parsed;
    try {
      parsed = qr.parse(token);
    } catch (error) {
      return res.status(400).json({ error: error.message });
    }

    const bundle = await cardById(parsed.cardId);
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

    if (await get('SELECT 1 FROM qr_uses WHERE token_hash = ?', [tokenHash])) {
      return res.status(409).json({ error: 'Ese QR ya se usó. Pedile que lo actualice.' });
    }

    let result;
    try {
      // El registro del QR va en la misma transacción que el sello: si falla uno, fallan los dos.
      result = await addStamp({
        cardId: bundle.card.id,
        staffId: req.user.sub,
        source: 'scan',
        idempotencyKey: idempotencyKey || `qr-${tokenHash}`,
        extra: [
          [
            'INSERT INTO qr_uses (token_hash, card_id, used_at) VALUES (?, ?, ?)',
            [tokenHash, bundle.card.id, now()],
          ],
        ],
      });
    } catch (error) {
      if (String(error.message).includes('UNIQUE constraint failed: qr_uses.token_hash')) {
        return res.status(409).json({ error: 'Ese QR ya se usó. Pedile que lo actualice.' });
      }
      throw error;
    }

    await cleanupQrUses();

    const fresh = await cardById(bundle.card.id);
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
