const {
  getExtractorName,
} = require('@makerdao-dux/spock-utils/dist/extractors/rawEventDataExtractor');
const {
  handleDsNoteEvents,
} = require('@makerdao-dux/spock-utils/dist/transformers/common');
// @ts-ignore
const dsChiefAbi = require('../abis/ds_chief.json');
const {
  getTxByIdOrDie,
} = require('@makerdao-dux/spock-utils/dist/extractors/common');
const BigNumber = require('bignumber.js').BigNumber;

const LockTopic = `0x625fed9875dada8643f2418b838ae0bc78d9a148a18eee4ee1979ff0f3f5d427`;
const FreeTopic = `0xce6c5af8fd109993cb40da4d5dc9e4dd8e61bc2e48f1e3901472141e4f56f293`;

module.exports = (address, nameSuffix = '') => ({
  name: `DsChiefTransformer${nameSuffix}`,
  dependencies: [getExtractorName(address)],
  transform: async (services, logs) => {
    await handleDsNoteEvents(services, dsChiefAbi, logs[0], handlers);
  },
});

const vdQuery = `SELECT *
    FROM dschief.lock
    WHERE tx_id = $1
    AND log_index = $2`;

const handlers = {
  'free(uint256)': async (services, { log, note }) => {
    const tx = await getTxByIdOrDie(services, log.tx_id);

    //get delegate event
    try {
      const transaction = await services.provider.getTransaction(tx.hash);
      //get transaction receipt
      const { logs } = await transaction.wait();
      //get event(s) from Delegate contract. Usually only one per transaction
      const delegateLogArray = logs.filter(l => l.topics[0] === FreeTopic);
      delegateLogArray.forEach(async delegateLog => {
        await insertDelegateLock(services, {
          fromAddress: tx.from_address,
          immediateCaller: '0x' + delegateLog.topics[1].slice(-40),
          lock: new BigNumber(delegateLog.data).div(new BigNumber("1e18")).negated().toString(),
          contractAddress: delegateLog.address.toLowerCase(),
          txId: log.tx_id,
          blockId: log.block_id,
          logIndex: delegateLog.logIndex,
        });
      });
    } catch (e) {
      console.log('error trying to find delegate free event', e);
    }

    const row = await services.db.oneOrNone(vdQuery, [log.tx_id, log.log_index]);
    if (row) {
      console.log('skipping chief.free event since it\'s already in the DB', row);
      return;
    }

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

    //get delegate event
    try {
      const transaction = await services.provider.getTransaction(tx.hash);
      //get transaction receipt
      const { logs } = await transaction.wait();
      //get event(s) from Delegate contract. Usually only one per transaction
      const delegateLogArray = logs.filter(l => l.topics[0] === LockTopic);
      delegateLogArray.forEach(async delegateLog => {
        await insertDelegateLock(services, {
          fromAddress: tx.from_address,
          immediateCaller: '0x' + delegateLog.topics[1].slice(-40),
          lock: new BigNumber(delegateLog.data).div(new BigNumber("1e18")).toString(),
          contractAddress: delegateLog.address.toLowerCase(),
          txId: log.tx_id,
          blockId: log.block_id,
          logIndex: delegateLog.logIndex,
        });
      });
    } catch (e) {
      console.log('error trying to find delegate lock event', e);
    }

    const row = await services.db.oneOrNone(vdQuery, [log.tx_id, log.log_index]);
    if (row) {
      console.log('skipping chief.lock event since it\'s already in the DB', row);
      return;
    }

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

const insertDelegateLock = (s, values) => {
  return s.tx.none(
    `
INSERT INTO dschief.delegate_lock(contract_address, from_address, immediate_caller, lock, log_index, tx_id, block_id) VALUES (\${contractAddress}, \${fromAddress}, \${immediateCaller}, \${lock}, \${logIndex}, \${txId}, \${blockId})`,
    values,
  );
};
