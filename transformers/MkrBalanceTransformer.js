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

const amountColumnType = 'decimal(78,18)';

async function processRow(db, { from, to, value, tx_id, block_id }) {
  // update balances of both accounts involved in transfer

  const sql = `
    insert into mkr.balances (address, amount, tx_id, block_id)
    values(
      $(receiver), 
      $(amount)::${amountColumnType} + coalesce((
        select amount from mkr.balances
        where address = $(receiver)
        order by id desc limit 1
      ), 0), 
      $(tx_id), 
      $(block_id)
    );
    insert into mkr.balances (address, amount, tx_id, block_id)
    values(
      $(sender), 
      -1 * $(amount)::${amountColumnType} + coalesce((
        select amount from mkr.balances
        where address = $(sender)
        order by id desc limit 1
      ), 0), 
      $(tx_id), 
      $(block_id)
    )
  `;

  return db.none(sql, {
    sender: from.toLowerCase(),
    receiver: to.toLowerCase(),
    amount: new BigNumber(value).div(new BigNumber('1e18')).toString(),
    tx_id,
    block_id,
  });
}

const handlers = {
  Transfer: (
    services,
    {
      event: {
        params: { from, to, value },
      },
      log: { tx_id, block_id },
    }
  ) => processRow(services.tx, { from, to, value, tx_id, block_id }),
};

module.exports = (mkrAddress) => ({
  name: 'MKR_BalanceTransformer',
  dependencies: [getExtractorName(mkrAddress)],
  transform: async (services, logs) => {
    await handleEvents(services, abi, logs[0], handlers);
  },
  test: {
    processRow,
  },
});
