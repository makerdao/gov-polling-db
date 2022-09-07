const {
  handleEvents,
} = require('@makerdao-dux/spock-utils/dist/transformers/common');
const {
  getExtractorName,
} = require('@makerdao-dux/spock-utils/dist/extractors/rawEventDataExtractor');
const { getLogger } = require('@makerdao-dux/spock-etl/dist/utils/logger');
const BigNumber = require('bignumber.js').BigNumber;
const ethers = require('ethers');

// @ts-ignore
const abi = require('../abis/polling_emitter_arbitrum.json');
const vdfAbi = require('../abis/vote_delegate_factory.json');

const logger = getLogger('Polling');

const ARBITRUM_TESTNET_CHAIN_ID = 421611;
const ZERO_ADDRESS = '0x0000000000000000000000000000000000000000';
const VOTE_DELEGATE_FACTORY_ADDRESS =
  '0xD897F108670903D1d6070fcf818f9db3615AF272';
const VOTE_DELEGATE_FACTORY_GOERLI_ADDRESS =
  '0xE2d249AE3c156b132C40D07bd4d34e73c1712947';

const layer2ChainMap = {
  // Arbitrum One
  42161: VOTE_DELEGATE_FACTORY_ADDRESS,
  // Goerli Arbitrum Testnet
  421613: VOTE_DELEGATE_FACTORY_GOERLI_ADDRESS,
};

module.exports = (address) => ({
  name: 'Arbitrum_Polling_Transformer',
  dependencies: [getExtractorName(address)],
  transform: async (services, logs) => {
    await handleEvents(services, abi, logs[0], handlers);
  },
});

const handlers = {
  async Voted(services, info) {
    if (!isValidPositivePostgresIntegerValue(info.event.params.pollId)) {
      logger.warn(
        `Ignoring Votes event from ${info.event.params.voter.toLowerCase()} because of failing validation. ${
          info.event.params.pollId
        } is not a valid positive integer.`
      );
      return;
    }

    let optionIdInt = null;
    if (
      info.event.params.optionId &&
      isValidPositivePostgresIntegerValue(info.event.params.optionId)
    ) {
      optionIdInt = info.event.params.optionId.toNumber();
    }

    let delegateContractAddress;

    try {
      // If we are on the L2 testnet, use the Goerli deployment of Vote Delegate Factory.
      const vdfAddress =
        layer2ChainMap[services.networkState.networkName.chainId];

      // The provider needs to be connected to the same L1 network where the delegate contract was created.
      const provider = new ethers.providers.JsonRpcProvider(
        process.env.VL_CHAIN_HOST
      );
      const delegateFactoryContract = new ethers.Contract(
        vdfAddress,
        vdfAbi,
        provider
      );
      delegateContractAddress = await delegateFactoryContract.delegates(
        info.event.params.voter
      );
      logger.warn(`Got delegate contract address: ${delegateContractAddress}`);
    } catch (e) {
      logger.error(
        `There was an error trying to find the delegate contract address for ${info.event.params.voter.toLowerCase()}, not Inserting 'Voted' event. ${e}`
      );
      return;
    }
    const voter =
      delegateContractAddress === ZERO_ADDRESS
        ? info.event.params.voter.toLowerCase()
        : delegateContractAddress.toLowerCase();

    logger.warn(`Inserting ${optionIdInt} into polling.voted_event_arbitrum`);

    const sql = `INSERT INTO polling.voted_event_arbitrum
    (voter,poll_id,option_id,option_id_raw,log_index,tx_id,block_id,chain_id) 
    VALUES(\${voter}, \${poll_id}, \${option_id}, \${option_id_raw}, \${log_index}, \${tx_id}, \${block_id}, \${chain_id});`;
    await services.tx.none(sql, {
      voter,
      poll_id: info.event.params.pollId.toNumber(),
      option_id: optionIdInt,
      option_id_raw: info.event.params.optionId.toString(),

      log_index: info.log.log_index,
      tx_id: info.log.tx_id,
      block_id: info.log.block_id,
      chain_id: ARBITRUM_TESTNET_CHAIN_ID,
    });
  },
};

function isValidPositivePostgresIntegerValue(_input) {
  const maxInt = new BigNumber('2147483647');
  const input = new BigNumber(_input);

  return input.lt(maxInt) && input.gte(0);
}
