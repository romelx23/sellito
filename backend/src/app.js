require('dotenv').config();

const express = require('express');
const cors = require('cors');
const path = require('path');
const fs = require('fs');

const { migrate, UPLOAD_DIR } = require('./db');

migrate();

const { router: authRouter } = require('./routes/auth');
const { router: businessRouter } = require('./routes/business');
const { router: programsRouter } = require('./routes/programs');
const { router: cardsRouter } = require('./routes/cards');
const { router: publicRouter } = require('./routes/public');
const { router: scanRouter } = require('./routes/scan');
const { router: walletRouter } = require('./routes/wallet');
const { router: pagesRouter } = require('./routes/pages');
const html = require('./services/html');

const app = express();
app.set('trust proxy', 1);
app.use(cors());
app.use(express.json({ limit: '4mb' }));

app.get('/api/health', (req, res) =>
  res.json({ ok: true, app: 'sella', at: new Date().toISOString() }),
);

app.use('/api/auth', authRouter);
app.use('/api/business', businessRouter);
app.use('/api/programs', programsRouter);
app.use('/api', cardsRouter);
app.use('/api/public', publicRouter);
app.use('/api/scan', scanRouter);
app.use('/api/wallet', walletRouter);

app.use(
  '/uploads',
  express.static(UPLOAD_DIR, { maxAge: '7d' }),
);
app.use(pagesRouter);

app.use('/api', (req, res) => res.status(404).json({ error: 'Ruta no encontrada' }));

const WEB_DIR = path.join(__dirname, '..', 'public', 'app');
const hasWebBuild = fs.existsSync(path.join(WEB_DIR, 'index.html'));

if (hasWebBuild) {
  app.use(express.static(WEB_DIR, { maxAge: '1h' }));
  app.get('*', (req, res) => res.sendFile(path.join(WEB_DIR, 'index.html')));
} else {
  app.get('*', (req, res) => {
    res.type('html').send(
      html.layout({
        title: 'Sella API',
        body: `<div class="brandbar">
            <div class="mark">S</div>
            <div><h1>Sella</h1><p>API en marcha</p></div>
          </div>
          <section class="panel">
            <h3>El backend está funcionando</h3>
            <p class="help">Todavía no hay build de la app Flutter en <code>backend/public/app</code>.</p>
            <p class="help">Probá estas rutas:</p>
            <ul style="font-size:13px;line-height:1.9;padding-left:18px">
              <li><a href="/j/cafe-aurora">/j/cafe-aurora</a> — inscripción de cliente</li>
              <li><a href="/c/CAFE-DEMO">/c/CAFE-DEMO</a> — tarjeta de ejemplo</li>
              <li><a href="/api/health">/api/health</a> — estado</li>
            </ul>
            <p class="help" style="margin-top:16px">Para la app: <code>cd app &amp;&amp; flutter run -d chrome</code></p>
          </section>`,
      }),
    );
  });
}

app.use((error, req, res, next) => {
  const status = error.status || 500;
  if (status >= 500) console.error('[error]', error);

  if (req.path.startsWith('/api')) {
    return res.status(status).json({ error: error.message || 'Error interno' });
  }

  return res
    .status(status)
    .type('html')
    .send(
      html.layout({
        title: 'Error',
        body: `<section class="panel"><h3>Algo salió mal</h3><p class="help">${error.message}</p></section>`,
      }),
    );
});

module.exports = { app };
