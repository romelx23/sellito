require('dotenv').config();

const { app } = require('./app');
const { ready, useTurso } = require('./db');
const { seed, hasData } = require('./seed');
const { config } = require('./services/google-wallet');

const PORT = Number(process.env.PORT) || 3000;

async function start() {
  await ready;
  console.log(`Base de datos: ${useTurso ? 'Turso' : 'SQLite local'}`);

  if (process.env.AUTO_SEED !== 'false' && !(await hasData())) {
    const summary = await seed();
    console.log(`[seed] Datos demo creados en ${summary.businesses} negocios`);
  }

  app.listen(PORT, '0.0.0.0', () => {
    console.log(`Sella escuchando en http://localhost:${PORT}`);
    console.log(`Google Wallet: ${config().enabled ? 'credenciales detectadas' : 'modo mock'}`);
  });
}

start().catch((error) => {
  console.error('No se pudo iniciar Sella:', error);
  process.exit(1);
});
