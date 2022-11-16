const {
  getExtractorName,
} = require('@makerdao-dux/spock-utils/dist/extractors/rawEventDataExtractor');
const {
  handleEvents,
} = require('@makerdao-dux/spock-utils/dist/transformers/common');
// @ts-ignore
const ESMAbi = require('../abis/esm_abi.json');
const {
  getTxByIdOrDie,
} = require('@makerdao-dux/spock-utils/dist/extractors/common');
const BigNumber = require('bignumber.js').BigNumber;

module.exports = (address) => ({
  name: 'ESMTransformer',
  dependencies: [getExtractorName(address)],
  transform: async (services, logs) => {
    await handleEvents(services, ESMAbi, logs[0], handlers);
  },
});

const handlers = {
  Join: async (services, { event, log }) => {
    const tx = await getTxByIdOrDie(services, log.tx_id);

    await insertJoin(services, {
      fromAddress: tx.from_address,
      immediateCaller: event.params.usr,
      joinAmount: new BigNumber(event.params.wad)
        .div(new BigNumber('1e18'))
        .toString(),
      contractAddress: event.address,
      txId: log.tx_id,
      blockId: log.block_id,
      logIndex: log.log_index,
    });
  },
};

const insertJoin = (s, values) => {
  return s.tx.none(
    `
INSERT INTO esm.mkr_joins(contract_address, from_address, immediate_caller, join_amount, log_index, tx_id, block_id) VALUES (\${contractAddress}, \${fromAddress}, \${immediateCaller}, \${joinAmount}, \${logIndex}, \${txId}, \${blockId})`,
    values
  );
};
