require('dotenv').config();

const { app } = require('./app');
const { seed, hasData } = require('./seed');
const { config } = require('./services/google-wallet');

if (process.env.AUTO_SEED !== 'false' && !hasData()) {
  const summary = seed();
  console.log(`[seed] Datos demo creados en ${summary.businesses} negocios`);
}

const PORT = Number(process.env.PORT) || 3000;

app.listen(PORT, '0.0.0.0', () => {
  console.log(`Sella escuchando en http://localhost:${PORT}`);
  console.log(`Google Wallet: ${config().enabled ? 'credenciales detectadas' : 'modo mock'}`);
});
