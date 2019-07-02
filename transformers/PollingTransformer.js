const { handleEvents } = require("spock-etl/lib/core/transformers/common");
const { getLogger } = require("spock-etl/lib/core/utils/logger");
const BigNumber = require("bignumber.js").BigNumber;

// @ts-ignore
const abi = require("../abis/polling_emitter.json");

const logger = getLogger("Polling");

module.exports = {
  name: "Polling_Transformer",
  dependencies: ["raw_log_0x150e1acaa2260dbf7d915c8eee0cdc895973a7c0_extractor"],
  transform: async (services, logs) => {
    console.log("logs in transform", logs);
    await handleEvents(services, abi, logs[0], handlers);
  },
};

const handlers = {
  async PollCreated(services, info) {
    const sql = `INSERT INTO polling.poll_created_event
    (creator,block_created,poll_id,start_date,end_date,multi_hash,log_index,tx_id,block_id) 
    VALUES(\${creator}, \${block_created}, \${poll_id}, \${start_date}, \${end_date}, \${multi_hash}, \${log_index}, \${tx_id}, \${block_id});`;
    console.log('INFO!!!!', info);
    await services.tx.none(sql, {
      creator: info.event.args.creator,
      block_created: info.event.args.blockCreated,
      poll_id: info.event.args.pollId,
      start_date: info.event.args.startDate,
      end_date: info.event.args.endDate,
      multi_hash: info.event.args.multiHash,

      log_index: info.log.log_index,
      tx_id: info.log.tx_id,
      block_id: info.log.block_id,
    });
  },

  async PollWithdrawn(services, info) {
    const sql = `INSERT INTO polling.poll_withdrawn_event
    (creator,block_withdrawn,poll_id,log_index,tx_id,block_id) 
    VALUES(\${creator}, \${block_withdrawn}, \${poll_id}, \${log_index}, \${tx_id}, \${block_id});`;
    await services.tx.none(sql, {
      creator: info.event.args.creator,
      block_withdrawn: info.event.args.blockWithdrawn,
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
