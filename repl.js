const repl = require('repl');
const { loadExternalConfig, mergeConfig } = require('spock-etl/lib/core/utils/configUtils');
const { createServices } = require('spock-etl/lib/core/services');
const { withConnection } = require('spock-etl/lib/core/db/db');

async function main(connection) {
  const config = mergeConfig(loadExternalConfig('./config.js'));
  const services = await createServices(config);

  return withConnection(services.db, connection => {
    const r = repl.start();
  
    Object.assign(r.context, {
      services,
      config,
      mbt: config.transformers.find(x => x.name === 'MKR_BalanceTransformer')
    });
  
    r.on('exit', () => process.exit());
  })
}

main();