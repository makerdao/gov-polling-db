const repl = require('repl');
const {
  loadConfig,
  mergeConfig,
} = require('@makerdao-dux/spock-etl/dist/services/configUtils');
const {
  createServices,
} = require('@makerdao-dux/spock-etl/dist/services/services');
const { withConnection } = require('@makerdao-dux/spock-etl/dist/db/db');

async function main(connection) {
  const config = mergeConfig(loadConfig('./config.js'));
  const services = await createServices(config);

  return withConnection(services.db, (connection) => {
    const r = repl.start();

    Object.assign(r.context, {
      services,
      config,
      mbt: config.transformers.find((x) => x.name === 'MKR_BalanceTransformer'),
      cbt: config.transformers.find(
        (x) => x.name === 'ChiefBalanceTransformer'
      ),
    });

    r.on('exit', () => process.exit());
  });
}

main();
