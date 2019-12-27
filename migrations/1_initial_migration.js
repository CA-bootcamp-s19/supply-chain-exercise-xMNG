var Migrations = artifacts.require("../Contracts/Migrations.sol");

module.exports = function (deployer) {
  deployer.deploy(Migrations);
};
