const express = require('express');
const { cardByCode } = require('../services/repo');
const { walletLink } = require('../services/google-wallet');

const router = express.Router();

router.get('/:code', async (req, res, next) => {
  try {
    const bundle = await cardByCode(req.params.code);
    if (!bundle) return res.status(404).json({ error: 'Tarjeta no encontrada' });

    try {
      const link = await walletLink(bundle);
      return res.json(link);
    } catch (error) {
      console.error('[wallet] Fallback a mock:', error.message);
      return res.json({
        mode: 'mock',
        url: `/wallet/mock/${bundle.card.code}`,
        warning: 'No se pudo firmar el pase de Google. Revisá las credenciales.',
      });
    }
  } catch (error) {
    return next(error);
  }
});

module.exports = { router };
