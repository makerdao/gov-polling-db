const {
  getExtractorName,
} = require('@makerdao-dux/spock-utils/dist/extractors/rawEventDataExtractor');

const {
  handleEvents,
} = require('@makerdao-dux/spock-utils/dist/transformers/common');

// @ts-ignore
const abi = require('../abis/vote_proxy_factory.json');

module.exports = (voteProxyFactoryAddress, nameSuffix = '') => ({
  name: `Vote_proxy_factory_transformer${nameSuffix}`,
  dependencies: [getExtractorName(voteProxyFactoryAddress)],
  transform: async (services, logs) => {
    await handleEvents(services, abi, logs[0], handlers);
  },
});

const handlers = {
  async LinkConfirmed(services, info) {
    const sql = `INSERT INTO dschief.vote_proxy_created_event
    (cold,hot,vote_proxy,log_index,tx_id,block_id) 
    VALUES(\${cold}, \${hot}, \${vote_proxy}, \${log_index}, \${tx_id}, \${block_id});`;

    await services.tx.none(sql, {
      cold: info.event.params.cold.toLowerCase(),
      hot: info.event.params.hot.toLowerCase(),
      vote_proxy: info.event.params.voteProxy.toLowerCase(),

      log_index: info.log.log_index,
      tx_id: info.log.tx_id,
      block_id: info.log.block_id,
    });
  },
};
