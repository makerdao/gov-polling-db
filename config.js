const {
  makeRawLogExtractors,
} = require("spock-etl/lib/core/processors/extractors/instances/rawEventDataExtractor");

const mkrTransformer = require("./transformers/MkrTransformer");
const mkrBalanceTransformer = require("./transformers/MkrBalanceTransformer");
const chiefBalanceTransformer = require("./transformers/ChiefBalanceTransformer");
const pollingTransformerImport = require("./transformers/PollingTransformer");
const pollingTransformer = pollingTransformerImport.default;
const dsChiefTransformer = require("./transformers/DsChiefTransformer");
const voteProxyFactoryTransformer = require("./transformers/VoteProxyFactoryTransformer");
const esmTransformer = require("./transformers/EsmTransformer");

//mainnet
const MKR_ADDRESS = "0x9f8f72aa9304c8b593d555f12ef6589cc3a579a2";
const VOTING_CONTRACT_ADDRESS = pollingTransformerImport.VOTING_CONTRACT_ADDRESS;
const SECOND_VOTING_CONTRACT_ADDRESS = "0xD3A9FE267852281a1e6307a1C37CDfD76d39b133";
const DSCHIEF_ADDRESS = "0x9eF05f7F6deB616fd37aC3c959a2dDD25A54E4F5";
const VOTE_PROXY_FACTORY_ADDRESS = "0x868ba9aeacA5B73c7C27F3B01588bf4F1339F2bC";
const ESM_ADDRESS = "0x0581a0abe32aae9b5f0f68defab77c6759100085";
const DSCHIEF_12_ADDRESS = "0x0a3f6849f78076aefaDf113F5BED87720274dDC0";
const VOTE_PROXY_FACTORY_12_ADDRESS = "0x6FCD258af181B3221073A96dD90D1f7AE7eEc408";

//kovan
const MKR_KOVAN_ADDRESS = "0xaaf64bfcc32d0f15873a02163e7e500671a4ffcd";
const VOTING_CONTRACT_KOVAN_ADDRESS = pollingTransformerImport.VOTING_CONTRACT_KOVAN_ADDRESS;
const SECOND_VOTING_CONTRACT_KOVAN_ADDRESS = "0xD931E7c869618dB6FD30cfE4e89248CAA091Ea5f";
const DSCHIEF_KOVAN_ADDRESS = "0xbbffc76e94b34f72d96d054b31f6424249c1337d";
const VOTE_PROXY_FACTORY_KOVAN_ADDRESS = "0x3e08741a68c2d964d172793cd0ad14292f658cd8";
const ESM_ADDRESS_KOVAN = "0x0c376764f585828ffb52471c1c35f855e312a06c";
const DSCHIEF_12_KOVAN_ADDRESS = '0x27E0c9567729Ea6e3241DE74B3dE499b7ddd3fe6';
const VOTE_PROXY_FACTORY_12_KOVAN_ADDRESS = "0x1400798AA746457E467A1eb9b3F3f72C25314429";


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
    esmTransformer(ESM_ADDRESS_KOVAN)
  ],
  migrations: {
    mkr: "./migrations",
  },
  api: {
    whitelisting: {
      enabled: false,
    },
    responseCaching: {
      enabled: false,
      duration: "15 seconds"
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
    esmTransformer(ESM_ADDRESS)
  ],
  migrations: {
    mkr: "./migrations",
  },
  api: {
    whitelisting: {
      enabled: false,
    },
    responseCaching: {
      enabled: false,
      duration: "15 seconds"
    },
  },
};

let config;
if (process.env.VL_CHAIN_NAME === "mainnet") {
  console.log("Using mainnet config");
  config = mainnet;
} else {
  console.log("Using kovan config");
  config = kovan;
}

module.exports.default = config;
