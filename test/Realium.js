// test/Airdrop.js
// Load dependencies
const { expect } = require('chai');
const { BigNumber } = require('ethers');
const { ethers } = require('hardhat');
const Web3 = require('web3');

const OWNER_ADDRESS = ethers.utils.getAddress("0x159A749dF54314005c9E38688c3EFcFb99dBcEA6");

const DECIMALS = 0;

const AMT = 10

///////////////////////////////////////////////////////////
// SEE https://hardhat.org/tutorial/testing-contracts.html
// FOR HELP WRITING TESTS
// USE https://github.com/gnosis/mock-contract FOR HELP
// WITH MOCK CONTRACT
///////////////////////////////////////////////////////////

// Start test block
describe('Token', function () {
    before(async function () {
        this.Token = await ethers.getContractFactory("TestToken");
    });

    beforeEach(async function () {
        this.token = await this.Token.deploy()
        await this.token.deployed()
    });

    // Test cases

    //////////////////////////////
    //       Constructor 
    //////////////////////////////
    describe("Constructor", function () {
        it('mock test', async function () {
            // If another contract calls balanceOf on the mock contract, return AMT
            const balanceOf = Web3.utils.sha3('balanceOf(address)').slice(0,10);
            console.log(balanceOf)
            var totalSupply = await this.token.totalSupply();
            console.log(totalSupply)
            console.log(totalSupply.toNumber())
            var total = .0001
            var amount = ethers.utils.parseEther(total.toString())
            console.log(amount.toNumber())
        });
    });

    //////////////////////////////
    //  setRemainderDestination 
    //////////////////////////////
    describe("otherMethod", function () {

    });
});