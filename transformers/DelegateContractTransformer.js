const { getExtractorName } = require("spock-etl/lib/core/processors/extractors/instances/rawEventBasedOnTopicExtractor");
const { handleEvents } = require("spock-etl/lib/core/processors/transformers/common");
const { getTxByIdOrDie } = require("spock-etl/lib/core/processors/extractors/common");
const BigNumber = require("bignumber.js").BigNumber;
// @ts-ignore
const abi = require("../abis/vote_delegate_contract.json");

const extractor_name = 'delegate';
module.exports.DELEGATE_EXTRACTOR_NAME = extractor_name;

module.exports.default = () => ({
  name: `DelegateContractTransformer`,
  dependencies: [getExtractorName(extractor_name)],
  transform: async (services, logs) => {
    await handleEvents(services, abi, logs[0], handlers);
  },
});

const handlers = {
  async Lock(services, info) {
    console.log('inside the Lock handler!!', info);
    const tx = await getTxByIdOrDie(services, info.log.tx_id);

    await insertLock(services, {
      fromAddress: tx.from_address,
      immediateCaller: info.event.params.usr,
      lock: new BigNumber(info.event.params.wad).div(new BigNumber("1e18")).toString(),
      contractAddress: info.event.address,
      txId: info.log.tx_id,
      blockId: info.log.block_id,
      logIndex: info.log.log_index,
    });
  },
  async Free(services, info) {
    console.log('inside the Free handler!!');
    const tx = await getTxByIdOrDie(services, info.log.tx_id);

    await insertLock(services, {
      fromAddress: tx.from_address,
      immediateCaller: info.event.params.usr,
      lock: new BigNumber(info.event.params.wad).div(new BigNumber("1e18")).negated().toString(),
      contractAddress: info.event.address,
      txId: info.log.tx_id,
      blockId: info.log.block_id,
      logIndex: info.log.log_index,
    });

  },
};

const insertLock = (s, values) => {
  //idea: maybe check to see if address is a delegate contract, before inserting the event into the table
  return s.tx.none(
    `
INSERT INTO dschief.delegate_lock(contract_address, from_address, immediate_caller, lock, log_index, tx_id, block_id) VALUES (\${contractAddress}, \${fromAddress}, \${immediateCaller}, \${lock}, \${logIndex}, \${txId}, \${blockId})`,
    values,
  );
};
