const {
  makeRawLogExtractors,
} = require('@makerdao-dux/spock-utils/dist/extractors/rawEventDataExtractor');
const mkrTransformer = require('./transformers/MkrTransformer');
const mkrBalanceTransformer = require('./transformers/MkrBalanceTransformer');
const chiefBalanceTransformer = require('./transformers/ChiefBalanceTransformer');
const pollingTransformerImport = require('./transformers/PollingTransformer');
const pollingTransformer = pollingTransformerImport.default;
const arbitrumPollingTransformer = require('./transformers/ArbitrumPollingTransformer');
const dsChiefTransformer = require('./transformers/DsChiefTransformer');
const voteProxyFactoryTransformer = require('./transformers/VoteProxyFactoryTransformer');
const esmTransformer = require('./transformers/EsmTransformer');
const esmV2Transformer = require('./transformers/EsmV2Transformer');
const voteDelegateFactoryTransformer = require('./transformers/VoteDelegateFactoryTransformer');
const v2VoteDelegateFactoryTransformer = require('./transformers/V2VoteDelegateFactoryTransformer');
const mkrCombinedTransformer = require('./transformers/MkrCombinedTransformer');
const mkrBalanceV2Transformer = require('./transformers/MkrBalanceV2Transformer');

//mainnet
const MKR_ADDRESS = '0x9f8f72aa9304c8b593d555f12ef6589cc3a579a2';
const VOTING_CONTRACT_ADDRESS =
  pollingTransformerImport.VOTING_CONTRACT_ADDRESS;
const SECOND_VOTING_CONTRACT_ADDRESS =
  '0xD3A9FE267852281a1e6307a1C37CDfD76d39b133';
const DSCHIEF_ADDRESS = '0x9eF05f7F6deB616fd37aC3c959a2dDD25A54E4F5';
const VOTE_PROXY_FACTORY_ADDRESS = '0x868ba9aeacA5B73c7C27F3B01588bf4F1339F2bC';
const ESM_ADDRESS = '0x29CfBd381043D00a98fD9904a431015Fef07af2f';
const ESM_V2_ADDRESS = '0x09e05fF6142F2f9de8B6B65855A1d56B6cfE4c58';
const DSCHIEF_12_ADDRESS = '0x0a3f6849f78076aefaDf113F5BED87720274dDC0';
const VOTE_PROXY_FACTORY_12_ADDRESS =
  '0x6FCD258af181B3221073A96dD90D1f7AE7eEc408';
const VOTE_DELEGATE_FACTORY_ADDRESS =
  '0xD897F108670903D1d6070fcf818f9db3615AF272';
const V2_VOTE_DELEGATE_FACTORY_ADDRESS =
  process.env.VL_CONFIG_NAME === 'multi_tenderly'
    ? '0x093d305366218d6d09ba10448922f10814b031dd'
    : '0xC3D809E87A2C9da4F6d98fECea9135d834d6F5A0';

//Arbitrum mainnet
const ARB_POLLING_ADDRESS = '0x4f4e551b4920a5417F8d4e7f8f099660dAdadcEC';

// arbitrum testnet (sepolia)
const ARB_TESTNET_POLLING_ADDRESS =
  '0xE63329692fA90B3efd5eB675c601abeDB2DF715a';

const CHAIN_HOST_L1 = process.env.VL_CHAIN_HOST;
const CHAIN_HOST_L2 = process.env.VL_CHAIN_HOST_L2;

const mainnet = {
  name: 'mainnet',
  processorSchema: 'vulcan2x',
  extractedSchema: 'extracted',
  startingBlock: 4620855,
  chain: {
    name: 'mainnet',
    host: CHAIN_HOST_L1,
    retries: 15,
  },
  extractors: [
    ...makeRawLogExtractors([
      VOTING_CONTRACT_ADDRESS,
      SECOND_VOTING_CONTRACT_ADDRESS,
      MKR_ADDRESS,
      DSCHIEF_ADDRESS,
      VOTE_PROXY_FACTORY_ADDRESS,
      DSCHIEF_12_ADDRESS,
      VOTE_PROXY_FACTORY_12_ADDRESS,
      ESM_ADDRESS,
      ESM_V2_ADDRESS,
      VOTE_DELEGATE_FACTORY_ADDRESS,
      V2_VOTE_DELEGATE_FACTORY_ADDRESS,
    ]),
  ],
  transformers: [
    pollingTransformer(VOTING_CONTRACT_ADDRESS),
    pollingTransformer(SECOND_VOTING_CONTRACT_ADDRESS),
    mkrTransformer(MKR_ADDRESS),
    mkrBalanceTransformer(MKR_ADDRESS),
    mkrCombinedTransformer(MKR_ADDRESS),
    mkrBalanceV2Transformer(MKR_ADDRESS),
    dsChiefTransformer(DSCHIEF_ADDRESS),
    chiefBalanceTransformer(DSCHIEF_ADDRESS),
    voteProxyFactoryTransformer(VOTE_PROXY_FACTORY_ADDRESS),
    dsChiefTransformer(DSCHIEF_12_ADDRESS, '_v1.2'),
    chiefBalanceTransformer(DSCHIEF_12_ADDRESS, '_v1.2'),
    voteProxyFactoryTransformer(VOTE_PROXY_FACTORY_12_ADDRESS, '_v1.2'),
    esmTransformer(ESM_ADDRESS),
    esmV2Transformer(ESM_V2_ADDRESS),
    voteDelegateFactoryTransformer(VOTE_DELEGATE_FACTORY_ADDRESS),
    v2VoteDelegateFactoryTransformer(V2_VOTE_DELEGATE_FACTORY_ADDRESS),
  ],
  migrations: {
    mkr: './migrations',
  },
  api: {
    whitelisting: {
      enabled: true,
      whitelistedQueriesDir: './queries',
      bypassSecret: process.env.BYPASS_SECRET,
    },
    responseCaching: {
      enabled: false,
      duration: '15 seconds',
    },
  },
  onStart: (services) =>
    console.log(
      `Starting Mainnet config with these services: ${Object.keys(services)}`,
    ),
};

const arbitrum = {
  name: 'arbitrum',
  processorSchema: 'vulcan2xarbitrum',
  extractedSchema: 'extractedarbitrum',

  chain: {
    name: 'arbitrum',
    host: CHAIN_HOST_L2,
    retries: 15,
  },
  startingBlock: 24755800,
  extractors: [...makeRawLogExtractors([ARB_POLLING_ADDRESS])],
  transformers: [arbitrumPollingTransformer(ARB_POLLING_ADDRESS)],
  migrations: {
    mkr: './migrations',
  },
  api: {
    whitelisting: {
      enabled: true,
      whitelistedQueriesDir: './queries',
      bypassSecret: process.env.BYPASS_SECRET,
    },
    responseCaching: {
      enabled: false,
      duration: '15 seconds',
    },
  },
  onStart: (services) =>
    console.log(`Starting with these services: ${Object.keys(services)}`),
};

const arbitrumTestnet = {
  name: 'arbitrumTestnet',
  processorSchema: 'vulcan2xarbitrum',
  extractedSchema: 'extractedarbitrum',

  chain: {
    name: 'arbitrumTestnet',
    host: CHAIN_HOST_L2,
    retries: 15,
  },
  startingBlock: 37261050,
  extractors: [...makeRawLogExtractors([ARB_TESTNET_POLLING_ADDRESS])],
  transformers: [arbitrumPollingTransformer(ARB_TESTNET_POLLING_ADDRESS)],
  migrations: {
    mkr: './migrations',
  },
  api: {
    whitelisting: {
      enabled: true,
      whitelistedQueriesDir: './queries',
      bypassSecret: process.env.BYPASS_SECRET,
    },
    responseCaching: {
      enabled: false,
      duration: '15 seconds',
    },
  },
  onStart: (services) =>
    console.log(`Starting with these services: ${Object.keys(services)}`),
};

let config;
if (process.env.VL_CONFIG_NAME === 'multi') {
  console.log('Using Mainnet multi-chain config');
  config = [mainnet, arbitrum];
} else if (process.env.VL_CONFIG_NAME === 'multi_tenderly') {
  console.log('Using Tenderly multi-chain config');
  config = [mainnet, arbitrumTestnet];
}

module.exports.default = config;
