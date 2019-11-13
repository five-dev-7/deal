const ConvertLib = artifacts.require("StorageLib");
const Deal = artifacts.require("Deal");

module.exports = function(deployer) {
  deployer.deploy(ConvertLib);
  deployer.link(ConvertLib, Deal);
  deployer.deploy(Deal);
};
