const { getExtractorName } = require("spock-etl/lib/core/processors/extractors/instances/rawEventDataExtractor");

const { handleEvents } = require("spock-etl/lib/core/processors/transformers/common");

// @ts-ignore
const abi = require("../abis/vote_proxy_factory.json");

module.exports = voteProxyFactoryAddress => ({
  name: "Vote_proxy_factory_transformer",
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
      cold: info.event.params.cold,
      hot: info.event.params.hot,
      vote_proxy: info.event.params.voteProxy,

      log_index: info.log.log_index,
      tx_id: info.log.tx_id,
      block_id: info.log.block_id,
    });
  },
};
