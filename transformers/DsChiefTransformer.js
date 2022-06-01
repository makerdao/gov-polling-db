const {
  getExtractorName,
} = require('@oasisdex/spock-utils/dist/extractors/rawEventDataExtractor');
const {
  handleDsNoteEvents,
} = require('@oasisdex/spock-utils/dist/transformers/common');
// @ts-ignore
const dsChiefAbi = require('../abis/ds_chief.json');
const {
  getTxByIdOrDie,
} = require('@oasisdex/spock-utils/dist/extractors/common');
const BigNumber = require('bignumber.js').BigNumber;

module.exports = (address, nameSuffix = '') => ({
  name: `DsChiefTransformer${nameSuffix}`,
  dependencies: [getExtractorName(address)],
  transform: async (services, logs) => {
    await handleDsNoteEvents(services, dsChiefAbi, logs[0], handlers);
  },
});

const handlers = {
  'free(uint256)': async (services, { log, note }) => {
    const tx = await getTxByIdOrDie(services, log.tx_id);

    await insertLock(services, {
      fromAddress: tx.from_address,
      immediateCaller: note.caller,
      lock: new BigNumber(note.params.wad)
        .div(new BigNumber('1e18'))
        .negated()
        .toString(),
      contractAddress: log.address,
      txId: log.tx_id,
      blockId: log.block_id,
      logIndex: log.log_index,
    });
  },
  'lock(uint256)': async (services, { log, note }) => {
    const tx = await getTxByIdOrDie(services, log.tx_id);

    await insertLock(services, {
      fromAddress: tx.from_address,
      immediateCaller: note.caller,
      lock: new BigNumber(note.params.wad)
        .div(new BigNumber('1e18'))
        .toString(),
      contractAddress: log.address,
      txId: log.tx_id,
      blockId: log.block_id,
      logIndex: log.log_index,
    });
  },
};

const insertLock = (s, values) => {
  return s.tx.none(
    `
INSERT INTO dschief.lock(contract_address, from_address, immediate_caller, lock, log_index, tx_id, block_id) VALUES (\${contractAddress}, \${fromAddress}, \${immediateCaller}, \${lock}, \${logIndex}, \${txId}, \${blockId})`,
    values
  );
};
