// @ts-ignore
const dsChiefAbi = require("../abis/ds_chief.json");

const { handleDsNoteEvents } = require("spock-etl/lib/core/transformers/common");
const { getTxByIdOrDie, getBlockByIdOrDie } = require("spock-etl/lib/core/extractors/common");
const BigNumber = require("bignumber.js").BigNumber;

module.exports = address => ({
  name: "DsChiefTransformer",
  dependencies: [`raw_log_${address}_extractor`],
  transform: async (services, logs) => {
    await handleDsNoteEvents(services, dsChiefAbi, logs[0], handlers);
  },
});

const handlers = {
  "free(uint256)": async (services, { log, note }) => {
    const block = await getBlockByIdOrDie(services, log.block_id);
    const tx = await getTxByIdOrDie(services, log.tx_id);

    await insertLock(services, {
      fromAddress: tx.from_address,
      immediateCaller: note.caller,
      lock: new BigNumber(note.params.wad)
        .div(new BigNumber("1e18"))
        .negated()
        .toString(),
      contractAddress: log.address,
      txId: log.tx_id,
      blockId: log.block_id,
      logIndex: log.log_index,
      timestamp: block.timestamp,
    });
  },
  "lock(uint256)": async (services, { log, note }) => {
    const block = await getBlockByIdOrDie(services, log.block_id);
    const tx = await getTxByIdOrDie(services, log.tx_id);

    await insertLock(services, {
      fromAddress: tx.from_address,
      immediateCaller: note.caller,
      lock: new BigNumber(note.params.wad).div(new BigNumber("1e18")).toString(),
      contractAddress: log.address,
      txId: log.tx_id,
      blockId: log.block_id,
      logIndex: log.log_index,
      timestamp: block.timestamp,
    });
  },
};

const insertLock = (s, values) => {
  return s.tx.none(
    `
INSERT INTO dschief.lock(contract_address, from_address, immediate_caller, lock, timestamp, log_index, tx_id, block_id) VALUES (\${contractAddress}, \${fromAddress}, \${immediateCaller}, \${lock}, \${timestamp}, \${logIndex}, \${txId}, \${blockId})`,
    values,
  );
};
