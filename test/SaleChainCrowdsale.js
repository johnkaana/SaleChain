const TRXMessages = artifacts.require("TRXMessages.sol");
const Web3 = require('web3');
const BigNumber = require('big-number');
const maxGasPerBlock = 6700000;

var wait = require('./helpers/wait')
var chalk = require('chalk')
var SaleChainToken = artifacts.require("./SaleChainToken.sol");
var SaleChainStakes = artifacts.require("./SaleChainStakes.sol");
var SaleChainCrowdsale = artifacts.require("./SaleChainCrowdsale.sol");
const tokenRate = 10;

// The following tests require TronBox >= 2.1.x
// and Tron Quickstart (https://github.com/tronprotocol/docker-tron-quickstart)

contract('SaleChainCrowdsale', function (accounts) {
  const new_web3 = new Web3(web3.currentProvider);
let saleChainTokenInstance
let saleChainStakesInstance
let saleChainCrowdsaleInstance
  const [
    WALLET_ADDRESS,
    owner,
    STAKING_FUND_WALLET_ADDRESS,
  ] = accounts;

  before(async function () {
    saleChainTokenInstance = await SaleChainToken.new('Sale Chain','SCH', 8, 1000000000);
    saleChainTokenContract = new new_web3.eth.Contract(saleChainTokenInstance.abi, saleChainTokenInstance.address);
    saleChainStakesInstance = await SaleChainStakes.new(saleChainTokenInstance.address);
    saleChainCrowdsaleInstance = await SaleChainCrowdsale.new(tokenRate, WALLET_ADDRESS, STAKING_FUND_WALLET_ADDRESS, saleChainTokenInstance.address, saleChainTokenInstance.address);
  });


  
  describe('like a Attack Place', function () {
    it("should verify that there are at least three available accounts", async function () {
      if(accounts.length < 3) {
        console.log(chalk.blue('\nYOUR ATTENTION, PLEASE.]\nTo test MetaCoin you should use Tron Quickstart (https://github.com/tronprotocol/docker-tron-quickstart) as your private network.\nAlternatively, you must set your own accounts in the "before" statement in "test/metacoin.js".\n'))
      }
      assert.isTrue(accounts.length >= 3)
    })

    it("should put 10000 MetaCoin in the first account", async function () {
      var saleChainToken2 = await SaleChainToken.deployed('Sale Chain','SCH', 8, 1000000000)
      const balance = await saleChainToken2.balanceOf(accounts[0], {from: accounts[0]});
      assert.equal(balance, 0, "10000 wasn't in the first account");
    });


  });
});
