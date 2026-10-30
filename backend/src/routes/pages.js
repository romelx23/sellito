const express = require('express');
const { cardByCode, activeProgramBySlug, businessBySlug } = require('../services/repo');
const { walletLink } = require('../services/google-wallet');
const html = require('../services/html');
const qr = require('../services/qr');

const router = express.Router();

function notFound(res, message) {
  return res.status(404).send(
    html.layout({
      title: 'No encontrado · Sella',
      body: `<div class="brandbar"><div class="mark">S</div><div><h1>Sella</h1><p>Tarjetas de fidelidad</p></div></div>
        <section class="panel"><h3>${message}</h3>
        <p class="help">Revisá el link o pedile uno nuevo al negocio.</p></section>`,
    }),
  );
}

router.get('/j/:slug', (req, res) => {
  const business = businessBySlug(req.params.slug);
  const program = activeProgramBySlug(req.params.slug);
  if (!business || !program) return notFound(res, 'Este programa no existe');

  res.type('html').send(html.renderJoinPage({ business, program }));
});

router.get('/c/:code', async (req, res) => {
  const bundle = cardByCode(req.params.code);
  if (!bundle) return notFound(res, 'Esa tarjeta no existe');

  const token = qr.sign(bundle.card.id, bundle.card.secret, 60);
  const dataUrl = await html.qrDataUrl(token);
  const wallet = await walletLink(bundle).catch(() => ({
    mode: 'mock',
    url: `/wallet/mock/${bundle.card.code}`,
  }));

  res.type('html').send(
    html.renderCardPage({
      ...bundle,
      qr: { token, dataUrl },
      wallet,
    }),
  );
});

router.get('/wallet/mock/:code', async (req, res) => {
  const bundle = cardByCode(req.params.code);
  if (!bundle) return notFound(res, 'Esa tarjeta no existe');

  const token = qr.sign(bundle.card.id, bundle.card.secret, 60);
  const dataUrl = await html.qrDataUrl(token);

  res.type('html').send(html.renderMockPass({ ...bundle, qrDataUrl: dataUrl }));
});

module.exports = { router };
