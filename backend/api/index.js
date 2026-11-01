// Punto de entrada para Vercel: exporta la app Express como función serverless.
const { app } = require('../src/app');
const { ready } = require('../src/db');
const { seed, hasData } = require('../src/seed');

let booted;

// Vercel reinicia la función con frecuencia: la inicialización se hace una vez por instancia.
function boot() {
  if (!booted) {
    booted = (async () => {
      await ready;
      if (process.env.AUTO_SEED !== 'false' && !(await hasData())) await seed();
    })();
  }
  return booted;
}

module.exports = async (req, res) => {
  await boot();
  return app(req, res);
};
