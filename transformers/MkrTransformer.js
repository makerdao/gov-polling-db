const { handleEvents } = require("spock-etl/lib/core/transformers/common");
const { getLogger } = require("spock-etl/lib/core/utils/logger");
const BigNumber = require("bignumber.js").BigNumber;

// @ts-ignore
const abi = require("../abis/mkr_abi.json");

const logger = getLogger("MKR");

module.exports = mkrAddress => ({
  name: "MKR_Transformer",
  dependencies: [`raw_log_${mkrAddress}_extractor`],
  transform: async (services, logs) => {
    await handleEvents(services, abi, logs[0], handlers);
  },
});

const handlers = {
  async Transfer(services, info) {
    logger.warn(info);

    const sql = `INSERT INTO mkr.transfer_event
    (sender,receiver,amount,log_index,tx_id,block_id) 
    VALUES(\${sender}, \${receiver}, \${value}, \${log_index}, \${tx_id}, \${block_id});`;

    await services.tx.none(sql, {
      sender: info.event.args.from,
      receiver: info.event.args.to,
      value: new BigNumber(info.event.args.value).div(new BigNumber("1e18")).toString(),

      log_index: info.log.log_index,
      tx_id: info.log.tx_id,
      block_id: info.log.block_id,
    });
  },
};
