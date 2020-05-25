var SaleChainToken = artifacts.require("./SaleChainToken.sol");
var SaleChainStaking = artifacts.require("./SaleChainStaking.sol");
var SaleChainCrowdsale = artifacts.require("./SaleChainCrowdsale.sol");

module.exports = async function(deployer) {
  const tokenRate = 10;
  const Fund_WALLET_ADDRESS = "TKK5mC3cMxHcaJ5jF2yH8a4stFusjRuFYs";
  const Token_WALLET_ADDRESS = "TGSxch2Um4XVEQcPpNBokJPhrPEXrxrfR1";
  const STAKING_FUND_WALLET_ADDRESS = "TNLYsbVXUwSETzsfgVARsb58Jem3JYkjZ4";
  const LEVEL2_WALLET_ADDRESS = "TFN6RXgNXzM7gqyEWf1pXwSuqEV2HvvkiH";
  
 deployer.deploy(SaleChainToken,"SaleChainToken", "SCH", 6, 1000000000000000)
        .then(() => SaleChainToken.deployed())
        .then(() => deployer.deploy(SaleChainStaking, SaleChainToken.address))
        .then(() => SaleChainStaking.deployed())
        .then(() => deployer.deploy(SaleChainCrowdsale, tokenRate, Fund_WALLET_ADDRESS, Token_WALLET_ADDRESS, STAKING_FUND_WALLET_ADDRESS, LEVEL2_WALLET_ADDRESS, SaleChainToken.address, SaleChainToken.address))
        .then(() => SaleChainCrowdsale.deployed())
        .then(() => SaleChainToken.addMinter(SaleChainCrowdsale.address))
 
};


