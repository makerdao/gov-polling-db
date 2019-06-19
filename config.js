const {
  makeRawLogExtractors,
} = require("spock-etl/lib/core/extractors/instances/rawEventDataExtractor");

const mkrTransformer = require("./transformers/MkrTransformer");

const MKR_ADDRESS = "0x9f8f72aa9304c8b593d555f12ef6589cc3a579a2";

module.exports.default = {
  startingBlock: 4620855,
  extractors: [...makeRawLogExtractors([MKR_ADDRESS])],
  transformers: [mkrTransformer],
  migrations: {
    mkr: "./migrations",
  },
};
