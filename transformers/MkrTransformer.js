const {
  getExtractorName,
} = require('@makerdao-dux/spock-utils/dist/extractors/rawEventDataExtractor');
const {
  handleEvents,
} = require('@makerdao-dux/spock-utils/dist/transformers/common');
const { getLogger } = require('@makerdao-dux/spock-etl/dist/utils/logger');
const BigNumber = require('bignumber.js').BigNumber;

// @ts-ignore
const abi = require('../abis/mkr_abi.json');

const logger = getLogger('MKR');

module.exports = (mkrAddress) => ({
  name: 'MKR_Transformer',
  dependencies: [getExtractorName(mkrAddress)],
  transform: async (services, logs) => {
    await handleEvents(services, abi, logs[0], handlers);
  },
});

const handlers = {
  async Transfer(services, info) {
    const sql = `INSERT INTO mkr.transfer_event
    (sender,receiver,amount,log_index,tx_id,block_id) 
    VALUES(\${sender}, \${receiver}, \${value}, \${log_index}, \${tx_id}, \${block_id});`;

    await services.tx.none(sql, {
      sender: info.event.params.from.toLowerCase(),
      receiver: info.event.params.to.toLowerCase(),
      value: new BigNumber(info.event.params.value)
        .div(new BigNumber('1e18'))
        .toString(),

      log_index: info.log.log_index,
      tx_id: info.log.tx_id,
      block_id: info.log.block_id,
    });
  },
};
