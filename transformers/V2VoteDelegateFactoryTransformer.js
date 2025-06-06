const {
  getExtractorName,
} = require('@makerdao-dux/spock-utils/dist/extractors/rawEventDataExtractor');

const {
  handleEvents,
} = require('@makerdao-dux/spock-utils/dist/transformers/common');

// @ts-ignore
const abi = require('../abis/vote_delegate_factory.json');

module.exports = (voteDelegateFactoryAddress, nameSuffix = '') => ({
  name: `V2_vote_delegate_factory_transformer${nameSuffix}`,
  dependencies: [getExtractorName(voteDelegateFactoryAddress)],
  transform: async (services, logs) => {
    await handleEvents(services, abi, logs[0], handlers);
  },
});

const handlers = {
  async CreateVoteDelegate(services, info) {
    const sql = `INSERT INTO dschief.vote_delegate_created_event
    (delegate, vote_delegate, log_index, tx_id, block_id, delegate_version) 
    VALUES(\${delegate}, \${vote_delegate}, \${log_index}, \${tx_id}, \${block_id}, \${delegate_version});`;

    const delegate = info.event.params.usr || info.event.params.delegate; //TODO: why isn't it just usr?

    await services.tx.none(sql, {
      delegate: delegate.toLowerCase(),
      vote_delegate: info.event.params.voteDelegate.toLowerCase(),
      log_index: info.log.log_index,
      tx_id: info.log.tx_id,
      block_id: info.log.block_id,
      delegate_version: 2,
    });
  },
};
