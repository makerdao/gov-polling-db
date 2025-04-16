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

async function processRow(db, { event_type, sender, receiver, value, tx_id, block_id }) {
  // For transfers, update both sender and receiver balances
  if (event_type === 'transfer') {
    const sql = `
      insert into mkr.balances_v2 (address, amount, tx_id, block_id)
      values(
        $(receiver), 
        $(amount)::${amountColumnType} + coalesce((
          select amount from mkr.balances_v2
          where address = $(receiver)
          order by block_id desc, tx_id desc limit 1
        ), 0), 
        $(tx_id), 
        $(block_id)
      );
      insert into mkr.balances_v2 (address, amount, tx_id, block_id)
      values(
        $(sender), 
        -1 * $(amount)::${amountColumnType} + coalesce((
          select amount from mkr.balances_v2
          where address = $(sender)
          order by block_id desc, tx_id desc limit 1
        ), 0), 
        $(tx_id), 
        $(block_id)
      )
    `;

    return db.none(sql, {
      sender: sender.toLowerCase(),
      receiver: receiver.toLowerCase(),
      amount: new BigNumber(value).div(new BigNumber('1e18')).toString(),
      tx_id,
      block_id,
    });
  }
  // For mints, only update receiver balance
  else if (event_type === 'mint') {
    const sql = `
      insert into mkr.balances_v2 (address, amount, tx_id, block_id)
      values(
        $(receiver), 
        $(amount)::${amountColumnType} + coalesce((
          select amount from mkr.balances_v2
          where address = $(receiver)
          order by block_id desc, tx_id desc limit 1
        ), 0), 
        $(tx_id), 
        $(block_id)
      )
    `;

    return db.none(sql, {
      receiver: receiver.toLowerCase(),
      amount: new BigNumber(value).div(new BigNumber('1e18')).toString(),
      tx_id,
      block_id,
    });
  }
  // For burns, only update sender balance
  else if (event_type === 'burn') {
    const sql = `
      insert into mkr.balances_v2 (address, amount, tx_id, block_id)
      values(
        $(sender), 
        -1 * $(amount)::${amountColumnType} + coalesce((
          select amount from mkr.balances_v2
          where address = $(sender)
          order by id desc limit 1
        ), 0), 
        $(tx_id), 
        $(block_id)
      )
    `;

    return db.none(sql, {
      sender: sender.toLowerCase(),
      amount: new BigNumber(value).div(new BigNumber('1e18')).toString(),
      tx_id,
      block_id,
    });
  }
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
  ) => processRow(services.tx, { 
    event_type: 'transfer',
    sender: from,
    receiver: to,
    value,
    tx_id,
    block_id
  }),
  Mint: (
    services,
    {
      event: {
        params: { guy, wad },
      },
      log: { tx_id, block_id },
    }
  ) => processRow(services.tx, {
    event_type: 'mint',
    sender: null,
    receiver: guy,
    value: wad,
    tx_id,
    block_id
  }),
  Burn: (
    services,
    {
      event: {
        params: { guy, wad },
      },
      log: { tx_id, block_id },
    }
  ) => processRow(services.tx, {
    event_type: 'burn',
    sender: guy,
    receiver: null,
    value: wad,
    tx_id,
    block_id
  })
};

module.exports = (mkrAddress) => ({
  name: 'MKR_BalanceV2Transformer',
  dependencies: [getExtractorName(mkrAddress)],
  transform: async (services, logs) => {
    await handleEvents(services, abi, logs[0], handlers);
  },
  test: {
    processRow,
  },
});