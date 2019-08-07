const {
  makeRawLogExtractors,
} = require("spock-etl/lib/core/processors/extractors/instances/rawEventDataExtractor");

const mkrTransformer = require("./transformers/MkrTransformer");
const pollingTransformer = require("./transformers/PollingTransformer");
const dsChiefTransformer = require("./transformers/DsChiefTransformer");
const voteProxyFactoryTransformer = require("./transformers/VoteProxyFactoryTransformer");

//mainnet
const MKR_ADDRESS = "0x9f8f72aa9304c8b593d555f12ef6589cc3a579a2";
const VOTING_CONTRACT_ADDRESS = "0xF9be8F0945acDdeeDaA64DFCA5Fe9629D0CF8E5D";
const DSCHIEF_ADDRESS = "0x9eF05f7F6deB616fd37aC3c959a2dDD25A54E4F5";
const VOTE_PROXY_FACTORY_ADDRESS = "0x868ba9aeacA5B73c7C27F3B01588bf4F1339F2bC";

//kovan
const MKR_KOVAN_ADDRESS = "0xaaf64bfcc32d0f15873a02163e7e500671a4ffcd";
const VOTING_CONTRACT_KOVAN_ADDRESS = "0x518a0702701BF98b5242E73b2368ae07562BEEA3";
const DSCHIEF_KOVAN_ADDRESS = "0xbbffc76e94b34f72d96d054b31f6424249c1337d";
const VOTE_PROXY_FACTORY_KOVAN_ADDRESS = "0x3e08741a68c2d964d172793cd0ad14292f658cd8";

const kovan = {
  startingBlock: 5216304,
  extractors: [
    ...makeRawLogExtractors([
      VOTING_CONTRACT_KOVAN_ADDRESS,
      MKR_KOVAN_ADDRESS,
      DSCHIEF_KOVAN_ADDRESS,
      VOTE_PROXY_FACTORY_KOVAN_ADDRESS,
    ]),
  ],
  transformers: [
    pollingTransformer(VOTING_CONTRACT_KOVAN_ADDRESS),
    mkrTransformer(MKR_KOVAN_ADDRESS),
    dsChiefTransformer(DSCHIEF_KOVAN_ADDRESS),
    voteProxyFactoryTransformer(VOTE_PROXY_FACTORY_KOVAN_ADDRESS),
  ],
  migrations: {
    mkr: "./migrations",
  },
  api: {
    whitelisting: {
      enabled: false,
    },
  },
  responseCaching: {
    enabled: true,
    duration: "15 seconds"
  },
};

const mainnet = {
  startingBlock: 4620855,
  extractors: [
    ...makeRawLogExtractors([
      VOTING_CONTRACT_ADDRESS,
      MKR_ADDRESS,
      DSCHIEF_ADDRESS,
      VOTE_PROXY_FACTORY_ADDRESS,
    ]),
  ],
  transformers: [
    pollingTransformer(VOTING_CONTRACT_ADDRESS),
    mkrTransformer(MKR_ADDRESS),
    dsChiefTransformer(DSCHIEF_ADDRESS),
    voteProxyFactoryTransformer(VOTE_PROXY_FACTORY_ADDRESS),
  ],
  migrations: {
    mkr: "./migrations",
  },
  api: {
    whitelisting: {
      enabled: false,
    },
  },
  responseCaching: {
    enabled: true,
    duration: "15 seconds"
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
