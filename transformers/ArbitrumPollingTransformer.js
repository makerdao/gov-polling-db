const {
  handleEvents,
} = require('@makerdao-dux/spock-utils/dist/transformers/common');
const {
  getExtractorName,
} = require('@makerdao-dux/spock-utils/dist/extractors/rawEventDataExtractor');
const { getLogger } = require('@makerdao-dux/spock-etl/dist/utils/logger');
const BigNumber = require('bignumber.js').BigNumber;

// @ts-ignore
const abi = require('../abis/polling_emitter_arbitrum.json');

const logger = getLogger('Polling');

const authorizedCreators = process.env.AUTHORIZED_CREATORS
  ? process.env.AUTHORIZED_CREATORS.split(',').map((creator) =>
      creator.toLowerCase()
    )
  : [];

const ARBITRUM_TESTNET_CHAIN_ID = 421611;

module.exports = (address) => ({
  name: 'Arbitrum_Polling_Transformer',
  dependencies: [getExtractorName(address)],
  transform: async (services, logs) => {
    await handleEvents(services, abi, logs[0], handlers);
  },
});

const handlers = {
  async Voted(services, info) {
    if (!isValidPositivePostgresIntegerValue(info.event.params.pollId)) {
      logger.warn(
        `Ignoring Votes event from ${info.event.params.voter.toLowerCase()} because of failing validation. ${
          info.event.params.pollId
        } is not a valid positive integer.`
      );
      return;
    }

    let optionIdInt = null;
    if (
      info.event.params.optionId &&
      isValidPositivePostgresIntegerValue(info.event.params.optionId)
    ) {
      optionIdInt = info.event.params.optionId.toNumber();
    }

    logger.warn(`Inserting ${optionIdInt} into polling.voted_event`);

    const sql = `INSERT INTO polling.voted_event_arbitrum
    (voter,poll_id,option_id,option_id_raw,log_index,tx_id,block_id,chain_id) 
    VALUES(\${voter}, \${poll_id}, \${option_id}, \${option_id_raw}, \${log_index}, \${tx_id}, \${block_id}, \${chain_id});`;
    await services.tx.none(sql, {
      voter: info.event.params.voter.toLowerCase(),
      poll_id: info.event.params.pollId.toNumber(),
      option_id: optionIdInt,
      option_id_raw: info.event.params.optionId.toString(),

      log_index: info.log.log_index,
      tx_id: info.log.tx_id,
      block_id: info.log.block_id,
      chain_id: ARBITRUM_TESTNET_CHAIN_ID,
    });
  },
};

function isValidPositivePostgresIntegerValue(_input) {
  const maxInt = new BigNumber('2147483647');
  const input = new BigNumber(_input);

  return input.lt(maxInt) && input.gte(0);
}
