const LoveToken = artifacts.require('./LoveToken.sol');

const utils = require('web3-utils');

let token;
let owner;
let user1;
let user2;

const shareLoveSignature = '0xedc613d9'; //web3.sha3("shareLove(address,uint256)").substring(0,10)
const tenTokens = web3.toWei(10, "ether");

contract('LoveTokenTest', (accounts) => {

    beforeEach(async () => {
        owner = accounts[0];
        user1 = accounts[1];
        user2 = accounts[2];
        token = await LoveToken.new();
    });

    let getRSV = function(signedMsg) {
        const r = signedMsg.substr(0, 66);
        const s = '0x' + signedMsg.substr(66, 64);
        const v = '0x' + signedMsg.substr(130, 2);
        const v_decimal = web3.toDecimal(v) + 27;
        return [v_decimal, r, s];
    };

    let pad = function(n, width, z) {
        z = z || '0';
        n = n + '';
        return n.length >= width ? n : new Array(width - n.length + 1).join(z) + n;
    };

    let signAndExecute = async function(from, to, value, data, rewardType, rewardAmount) {
        let nonce = await token.nonces.call(from);
        let hash = utils.soliditySha3(token.address, from, to, value, data,
            rewardType, rewardAmount, nonce);
        let signedHash = await web3.eth.sign(from, hash);
        let [v, r, s] = getRSV(signedHash);
        await token.execute(v, r, s, from, to, value,
            data, rewardType, rewardAmount, {from: owner});
    };

    let getShareLoveData = function(to, amount){
        let convertedTo = pad(to.substring(2),64);
        let convertedAmount = pad(utils.toHex(amount).substring(2),64);
        let data = shareLoveSignature + convertedTo + convertedAmount;
        return data;
    };

    it("send some love using meta", async () => {
        let data = getShareLoveData(user2, tenTokens);
        await signAndExecute(user1, token.address, 0, data, token.address, 0);
        assert(tenTokens == (await token.balanceOf.call(user2)).toNumber(), "contract has sent the tokens");
    });

});
