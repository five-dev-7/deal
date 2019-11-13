const Migrations = artifacts.require("Deal");

module.exports = function(deployer) {
  deployer.deploy(Migrations);
};
