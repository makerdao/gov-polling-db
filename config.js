const {
  makeRawLogExtractors,
} = require("spock-etl/lib/core/extractors/instances/rawEventDataExtractor");

const mkrTransformer = require("./transformers/MkrTransformer");
const pollingTransformer = require("./transformers/PollingTransformer");
const dsChiefTransformer = require("./transformers/DsChiefTransformer");
const voteProxyFactoryTransformer = require("./transformers/VoteProxyFactoryTransformer");

//mainnet
const MKR_ADDRESS = "0x9f8f72aa9304c8b593d555f12ef6589cc3a579a2";
const VOTING_CONTRACT_ADDRESS = "0x0fe6c2Fab0776f91540a734117B04e4F41D82212";
const DSCHIEF_ADDRESS = "0x9eF05f7F6deB616fd37aC3c959a2dDD25A54E4F5";
const VOTE_PROXY_FACTORY_KOVAN_ADDRESS = "0x868ba9aeacA5B73c7C27F3B01588bf4F1339F2bC";

//kovan
const MKR_KOVAN_ADDRESS = "0xaaf64bfcc32d0f15873a02163e7e500671a4ffcd";
const VOTING_CONTRACT_KOVAN_ADDRESS = "0x150e1aCAa2260dbf7d915C8eee0cdc895973a7c0";
const DSCHIEF_KOVAN_ADDRESS = "0xbbffc76e94b34f72d96d054b31f6424249c1337d";
const VOTE_PROXY_FACTORY_KOVAN_ADDRESS = "0x3e08741a68c2d964d172793cd0ad14292f658cd8";

const kovan = {
  startingBlock: 11956767,
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
};

const mainnet = {
  startingBlock: 4620855,
  extractors: [
    ...makeRawLogExtractors([
      VOTING_CONTRACT_ADDRESS,
      MKR_ADDRESS,
      DSCHIEF_KOVAN_ADDRESS,
      VOTE_PROXY_FACTORY_ADDRESS
    ])],
  transformers: [mkrTransformer(MKR_ADDRESS)],
  migrations: {
    mkr: "./migrations",
  },
};

module.exports.default = mainnet;
