const { handleEvents } = require("spock-etl/lib/core/processors/transformers/common");
const {
  getExtractorName,
} = require("spock-etl/lib/core/processors/extractors/instances/rawEventDataExtractor");
const { getLogger } = require("spock-etl/lib/core/utils/logger");
const BigNumber = require("bignumber.js").BigNumber;

// @ts-ignore
const abi = require("../abis/polling_emitter.json");

const logger = getLogger("Polling");

const authorizedCreators = process.env.AUTHORIZED_CREATORS
  ? process.env.AUTHORIZED_CREATORS.split(",").map(creator => creator.toLowerCase())
  : [];

module.exports = address => ({
  name: "Polling_Transformer",
  dependencies: [getExtractorName(address)],
  transform: async (services, logs) => {
    await handleEvents(services, abi, logs[0], handlers);
  },
});

const handlers = {
  async PollCreated(services, info) {
    const creator = info.event.params.creator.toLowerCase();
    if (authorizedCreators.length > 0 && !authorizedCreators.includes(creator.toLowerCase())) {
      logger.info(
        `Ignoring PollCreated event because ${creator} is not in the whitelist ${authorizedCreators}`,
      );
      return;
    }

    if (
      !isValidPositivePostgresIntegerValue(info.event.params.startDate) ||
      !isValidPositivePostgresIntegerValue(info.event.params.endDate) ||
      !isValidPositivePostgresIntegerValue(info.event.params.blockCreated) ||
      !isValidPositivePostgresIntegerValue(info.event.params.pollId)
    ) {
      logger.warn(
        `Ignoring PollCreated event from ${creator} because of failing validation.`,
      );
      return;
    }

    const sql = `INSERT INTO polling.poll_created_event
    (creator,block_created,poll_id,start_date,end_date,multi_hash,url,log_index,tx_id,block_id) 
    VALUES(\${creator}, \${block_created}, \${poll_id}, \${start_date}, \${end_date}, \${multi_hash}, \${url}, \${log_index}, \${tx_id}, \${block_id});`;
    await services.tx.none(sql, {
      creator,
      block_created: info.event.params.blockCreated.toNumber(),
      poll_id: info.event.params.pollId.toNumber(),
      start_date: info.event.params.startDate.toNumber(),
      end_date: info.event.params.endDate.toNumber(),
      multi_hash: info.event.params.multiHash,
      url: info.event.params.url,

      log_index: info.log.log_index,
      tx_id: info.log.tx_id,
      block_id: info.log.block_id,
    });
  },

  async PollWithdrawn(services, info) {
    const creator = info.event.params.creator.toLowerCase();
    if (authorizedCreators.length > 0 && !authorizedCreators.includes(creator))
      return;

    if (
      !isValidPositivePostgresIntegerValue(info.event.params.blockWithdrawn) ||
      !isValidPositivePostgresIntegerValue(info.event.params.pollId)
    ) {
      logger.warn(
        // prettier-ignore
        `Ignoring PollWithdrawn event from ${creator} because of failing validation.`,
      );
      return;
    }

    const sql = `INSERT INTO polling.poll_withdrawn_event
    (creator,block_withdrawn,poll_id,log_index,tx_id,block_id) 
    VALUES(\${creator}, \${block_withdrawn}, \${poll_id}, \${log_index}, \${tx_id}, \${block_id});`;
    await services.tx.none(sql, {
      creator,
      block_withdrawn: info.event.params.blockWithdrawn.toNumber(),
      poll_id: info.event.params.pollId.toNumber(),

      log_index: info.log.log_index,
      tx_id: info.log.tx_id,
      block_id: info.log.block_id,
    });
  },

  async Voted(services, info) {
    if (
      !isValidPositivePostgresIntegerValue(info.event.params.pollId)
    ) {
      logger.warn(
        `Ignoring Voted event from ${info.event.params.voter.toLowerCase()} because of failing validation.`,
      );
      return;
    }

    let optionIdInt = null;
    if(info.event.params.optionId && isValidPositivePostgresIntegerValue(info.event.params.optionId)){
      optionIdInt = info.event.params.optionId.toNumber();
    }

    const sql = `INSERT INTO polling.voted_event
    (voter,poll_id,option_id,option_id_raw,log_index,tx_id,block_id) 
    VALUES(\${voter}, \${poll_id}, \${option_id}, \${option_id_raw}, \${log_index}, \${tx_id}, \${block_id});`;
    console.log('info.event.params.optionId', info.event.params.optionId);
    await services.tx.none(sql, {
      voter: info.event.params.voter.toLowerCase(),
      poll_id: info.event.params.pollId.toNumber(),
      option_id: optionIdInt,
      option_id_raw: info.event.params.optionId.toString(),

      log_index: info.log.log_index,
      tx_id: info.log.tx_id,
      block_id: info.log.block_id,
    });
  },
};

function isValidPositivePostgresIntegerValue(_input) {
  const maxInt = new BigNumber("2147483647");
  const input = new BigNumber(_input);

  return input.lt(maxInt) && input.gte(0);
}
