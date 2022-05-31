const {
  makeRawLogExtractors,
} = require('spock-etl/lib/core/processors/extractors/instances/rawEventDataExtractor');

const mkrTransformer = require('./transformers/MkrTransformer');
const mkrBalanceTransformer = require('./transformers/MkrBalanceTransformer');
const chiefBalanceTransformer = require('./transformers/ChiefBalanceTransformer');
const pollingTransformerImport = require('./transformers/PollingTransformer');
const pollingTransformer = pollingTransformerImport.default;
const dsChiefTransformer = require('./transformers/DsChiefTransformer');
const voteProxyFactoryTransformer = require('./transformers/VoteProxyFactoryTransformer');
const esmTransformer = require('./transformers/EsmTransformer');
const esmV2Transformer = require('./transformers/EsmV2Transformer');
const voteDelegateFactoryTransformer = require('./transformers/VoteDelegateFactoryTransformer');

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

//kovan
const MKR_KOVAN_ADDRESS = '0xaaf64bfcc32d0f15873a02163e7e500671a4ffcd';
const VOTING_CONTRACT_KOVAN_ADDRESS =
  pollingTransformerImport.VOTING_CONTRACT_KOVAN_ADDRESS;
const SECOND_VOTING_CONTRACT_KOVAN_ADDRESS =
  '0xD931E7c869618dB6FD30cfE4e89248CAA091Ea5f';
const DSCHIEF_KOVAN_ADDRESS = '0xbbffc76e94b34f72d96d054b31f6424249c1337d';
const VOTE_PROXY_FACTORY_KOVAN_ADDRESS =
  '0x3e08741a68c2d964d172793cd0ad14292f658cd8';
const ESM_ADDRESS_KOVAN = '0xD5D728446275B0A12E4a4038527974b92353B4a9';
const DSCHIEF_12_KOVAN_ADDRESS = '0x27E0c9567729Ea6e3241DE74B3dE499b7ddd3fe6';
const VOTE_PROXY_FACTORY_12_KOVAN_ADDRESS =
  '0x1400798AA746457E467A1eb9b3F3f72C25314429';
const VOTE_DELEGATE_FACTORY_KOVAN_ADDRESS =
  '0x1740F3bD55b1900C816A0071F8972C201566e3a3';

//goerli
// note: VOTING_CONTRACT_KOVAN_ADDRESS and SECOND_VOTING_CONTRACT_KOVAN_ADDRESS are the same contract on goerli
// note: there is no v1 of DSCHIEF or VOTE_PROXY_FACTORY deployed to goerli, only the newer versions
const MKR_GOERLI_ADDRESS = '0xc5E4eaB513A7CD12b2335e8a0D57273e13D499f7';
const BATCH_VOTING_CONTRACT_GOERLI_ADDRESS =
  '0xdbE5d00b2D8C13a77Fb03Ee50C87317dbC1B15fb';
const ESM_ADDRESS_GOERLI = '0x105BF37e7D81917b6fEACd6171335B4838e53D5e';
const ESM_V2_ADDRESS_GOERLI = '0x023A960cb9BE7eDE35B433256f4AfE9013334b55';
const DSCHIEF_12_GOERLI_ADDRESS = '0x33Ed584fc655b08b2bca45E1C5b5f07c98053bC1';
const VOTE_PROXY_FACTORY_12_GOERLI_ADDRESS =
  '0x1a7c1ee5eE2A3B67778ff1eA8c719A3fA1b02b6f';
const VOTE_DELEGATE_FACTORY_GOERLI_ADDRESS =
  '0xE2d249AE3c156b132C40D07bd4d34e73c1712947';

const goerli = {
  startingBlock: 5273000,
  extractors: [
    ...makeRawLogExtractors([
      BATCH_VOTING_CONTRACT_GOERLI_ADDRESS,
      MKR_GOERLI_ADDRESS,
      ESM_ADDRESS_GOERLI,
      ESM_V2_ADDRESS_GOERLI,
      DSCHIEF_12_GOERLI_ADDRESS,
      VOTE_PROXY_FACTORY_12_GOERLI_ADDRESS,
      VOTE_DELEGATE_FACTORY_GOERLI_ADDRESS,
    ]),
  ],
  transformers: [
    pollingTransformer(BATCH_VOTING_CONTRACT_GOERLI_ADDRESS),
    mkrTransformer(MKR_GOERLI_ADDRESS),
    mkrBalanceTransformer(MKR_GOERLI_ADDRESS),
    esmTransformer(ESM_ADDRESS_GOERLI),
    esmV2Transformer(ESM_V2_ADDRESS_GOERLI),
    dsChiefTransformer(DSCHIEF_12_GOERLI_ADDRESS, '_v1.2'),
    chiefBalanceTransformer(DSCHIEF_12_GOERLI_ADDRESS, '_v1.2'),
    voteProxyFactoryTransformer(VOTE_PROXY_FACTORY_12_GOERLI_ADDRESS, '_v1.2'),
    voteDelegateFactoryTransformer(VOTE_DELEGATE_FACTORY_GOERLI_ADDRESS),
  ],
  migrations: {
    mkr: './migrations',
  },
  api: {
    whitelisting: {
      enabled: false,
    },
    responseCaching: {
      enabled: false,
      duration: '15 seconds',
    },
  },
};

const kovan = {
  startingBlock: 5216304,
  extractors: [
    ...makeRawLogExtractors([
      VOTING_CONTRACT_KOVAN_ADDRESS,
      SECOND_VOTING_CONTRACT_KOVAN_ADDRESS,
      MKR_KOVAN_ADDRESS,
      DSCHIEF_KOVAN_ADDRESS,
      VOTE_PROXY_FACTORY_KOVAN_ADDRESS,
      DSCHIEF_12_KOVAN_ADDRESS,
      VOTE_PROXY_FACTORY_12_KOVAN_ADDRESS,
      ESM_ADDRESS_KOVAN,
      VOTE_DELEGATE_FACTORY_KOVAN_ADDRESS,
    ]),
  ],
  transformers: [
    pollingTransformer(VOTING_CONTRACT_KOVAN_ADDRESS),
    pollingTransformer(SECOND_VOTING_CONTRACT_KOVAN_ADDRESS),
    mkrTransformer(MKR_KOVAN_ADDRESS),
    mkrBalanceTransformer(MKR_KOVAN_ADDRESS),
    dsChiefTransformer(DSCHIEF_KOVAN_ADDRESS),
    chiefBalanceTransformer(DSCHIEF_KOVAN_ADDRESS),
    voteProxyFactoryTransformer(VOTE_PROXY_FACTORY_KOVAN_ADDRESS),
    dsChiefTransformer(DSCHIEF_12_KOVAN_ADDRESS, '_v1.2'),
    chiefBalanceTransformer(DSCHIEF_12_KOVAN_ADDRESS, '_v1.2'),
    voteProxyFactoryTransformer(VOTE_PROXY_FACTORY_12_KOVAN_ADDRESS, '_v1.2'),
    esmTransformer(ESM_ADDRESS_KOVAN),
    voteDelegateFactoryTransformer(VOTE_DELEGATE_FACTORY_KOVAN_ADDRESS),
  ],
  migrations: {
    mkr: './migrations',
  },
  api: {
    whitelisting: {
      enabled: false,
    },
    responseCaching: {
      enabled: false,
      duration: '15 seconds',
    },
  },
};

const mainnet = {
  startingBlock: 4620855,
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
    ]),
  ],
  transformers: [
    pollingTransformer(VOTING_CONTRACT_ADDRESS),
    pollingTransformer(SECOND_VOTING_CONTRACT_ADDRESS),
    mkrTransformer(MKR_ADDRESS),
    mkrBalanceTransformer(MKR_ADDRESS),
    dsChiefTransformer(DSCHIEF_ADDRESS),
    chiefBalanceTransformer(DSCHIEF_ADDRESS),
    voteProxyFactoryTransformer(VOTE_PROXY_FACTORY_ADDRESS),
    dsChiefTransformer(DSCHIEF_12_ADDRESS, '_v1.2'),
    chiefBalanceTransformer(DSCHIEF_12_ADDRESS, '_v1.2'),
    voteProxyFactoryTransformer(VOTE_PROXY_FACTORY_12_ADDRESS, '_v1.2'),
    esmTransformer(ESM_ADDRESS),
    esmV2Transformer(ESM_V2_ADDRESS),
    voteDelegateFactoryTransformer(VOTE_DELEGATE_FACTORY_ADDRESS),
  ],
  migrations: {
    mkr: './migrations',
  },
  api: {
    whitelisting: {
      enabled: false,
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
if (process.env.VL_CHAIN_NAME === 'mainnet') {
  console.log('Using mainnet config');
  config = mainnet;
} else if (process.env.VL_CHAIN_NAME === 'kovan') {
  console.log('Using kovan config');
  config = kovan;
} else {
  console.log('Using goerli config');
  config = goerli;
}

module.exports.default = config;
