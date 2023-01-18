const {
  getExtractorName,
} = require('@makerdao-dux/spock-utils/dist/extractors/rawEventDataExtractor');
const {
  handleDsNoteEvents,
} = require('@makerdao-dux/spock-utils/dist/transformers/common');
const { getLogger } = require('@makerdao-dux/spock-etl/dist/utils/logger');
const BigNumber = require('bignumber.js').BigNumber;
// @ts-ignore
const dsChiefAbi = require('../abis/ds_chief.json');

const amountColumnType = 'decimal(78,18)';

async function processRow(db, { caller, wad, tx_id, block_id }) {
  const sql = `
    insert into dschief.balances (address, amount, tx_id, block_id)
    values(
      $(address), 
      $(amount)::${amountColumnType} + coalesce((
        select amount from dschief.balances
        where address = $(address)
        order by id desc limit 1
      ), 0), 
      $(tx_id), 
      $(block_id)
    );
  `;

  return db.none(sql, {
    address: caller,
    amount: new BigNumber(wad).div(new BigNumber('1e18')).toString(),
    tx_id,
    block_id,
  });
}

const handlers = {
  'free(uint256)': (
    services,
    {
      note: {
        caller,
        params: { wad },
      },
      log: { tx_id, block_id },
    }
  ) => processRow(services.tx, { caller, wad: `-${wad}`, tx_id, block_id }),
  'lock(uint256)': (
    services,
    {
      note: {
        caller,
        params: { wad },
      },
      log: { tx_id, block_id },
    }
  ) => processRow(services.tx, { caller, wad, tx_id, block_id }),
};

module.exports = (mkrAddress, nameSuffix = '') => ({
  name: `ChiefBalanceTransformer${nameSuffix}`,
  dependencies: [getExtractorName(mkrAddress)],
  transform: async (services, logs) => {
    await handleDsNoteEvents(services, dsChiefAbi, logs[0], handlers);
  },
  test: {
    processRow,
  },
});
