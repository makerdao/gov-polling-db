const { handleEvents } = require("spock-etl/lib/core/transformers/common");
const { getLogger } = require("spock-etl/lib/core/utils/logger");
const BigNumber = require("bignumber.js").BigNumber;

// @ts-ignore
const abi = require("../abis/polling_emitter.json");

const logger = getLogger("Polling");

module.exports = {
  name: "Polling_Transformer",
  dependencies: ["raw_log_0x500536350bb32b05210bcb412a720a0e7c8a36bc_extractor"],
  transform: async (services, logs) => {
    await handleEvents(services, abi, logs[0], handlers);
  },
};

const handlers = {
  async PollCreated(services, info) {
    const sql = `INSERT INTO polling.poll_created_event
    (creator,poll_id,start_block,end_block,multi_hash,log_index,tx_id,block_id) 
    VALUES(\${creator}, \${poll_id}, \${start_block}, \${end_block}, \${multi_hash}, \${log_index}, \${tx_id}, \${block_id});`;

    await services.tx.none(sql, {
      creator: info.event.args.creator,
      poll_id: info.event.args.pollId,
      start_block: info.event.args.startBlock,
      end_block: info.event.args.endBlock,
      multi_hash: info.event.args.multiHash,

      log_index: info.log.log_index,
      tx_id: info.log.tx_id,
      block_id: info.log.block_id,
    });
  },

  async PollWithdrawn(services, info) {
    const sql = `INSERT INTO polling.poll_withdrawn_event
    (creator,poll_id,log_index,tx_id,block_id) 
    VALUES(\${creator}, \${poll_id}, \${log_index}, \${tx_id}, \${block_id});`;

    await services.tx.none(sql, {
      creator: info.event.args.creator,
      poll_id: info.event.args.pollId,

      log_index: info.log.log_index,
      tx_id: info.log.tx_id,
      block_id: info.log.block_id,
    });
  },

  async Voted(services, info) {
    const sql = `INSERT INTO polling.voted_event
    (voter,poll_id,option_id,log_index,tx_id,block_id) 
    VALUES(\${voter}, \${poll_id}, \${option_id}, \${log_index}, \${tx_id}, \${block_id});`;

    await services.tx.none(sql, {
      voter: info.event.args.voter,
      poll_id: info.event.args.pollId,
      option_id: info.event.args.optionId,

      log_index: info.log.log_index,
      tx_id: info.log.tx_id,
      block_id: info.log.block_id,
    });
  },
};
