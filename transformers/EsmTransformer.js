const { getExtractorName } = require("spock-etl/lib/core/processors/extractors/instances/rawEventDataExtractor");
const { handleDsNoteEvents } = require("spock-etl/lib/core/processors/transformers/common");
// @ts-ignore
const ESMAbi = require("../abis/esm_abi.json");
const { getTxByIdOrDie } = require("spock-etl/lib/core/processors/extractors/common");
const BigNumber = require("bignumber.js").BigNumber;

module.exports = address => ({
  name: "ESMTransformer",
  dependencies: [getExtractorName(address)],
  transform: async (services, logs) => {
    await handleDsNoteEvents(services, ESMAbi, logs[0], handlers, 2);
  },
});

const handlers = {
  "join(uint256)": async (services, { log, note }) => {
    const tx = await getTxByIdOrDie(services, log.tx_id);

    await insertJoin(services, {
      fromAddress: tx.from_address,
      immediateCaller: note.caller,
      joinAmount: new BigNumber(note.params.wad)
        .div(new BigNumber("1e18"))
        .toString(),
      contractAddress: log.address,
      txId: log.tx_id,
      blockId: log.block_id,
      logIndex: log.log_index
    });
  },
};

const insertJoin = (s, values) => {
  return s.tx.none(
    `
INSERT INTO esm.mkr_joins(contract_address, from_address, immediate_caller, join_amount, log_index, tx_id, block_id) VALUES (\${contractAddress}, \${fromAddress}, \${immediateCaller}, \${joinAmount}, \${logIndex}, \${txId}, \${blockId})`,
    values,
  );
};