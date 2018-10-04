pragma solidity ^0.4.24;

import "./ERC20.sol";

/**
 * @title Tenzorum Love Token
 *
 * @dev ERC20 token with a minting function executed by gasless/meta transaction - 'shareLove'
 *
 * @author Radek Ostrowski - radek@startonchain.com - https://tenzorum.org
 */
contract LoveToken is ERC20 {

    string public constant name = "❤️🌀 Love Token";
    string public constant symbol = "LUV";
    uint8 public constant decimals = 18;

    mapping (address => uint) public nonces;

    function shareLove(address _to, uint256 _amount) public {
        require(msg.sender == address(this));
        _mint(_to, _amount);
    }

    function execute(
        uint8 _v, bytes32 _r, bytes32 _s,
        address _from, address _to,
        uint _value, bytes _data,
        address _rewardType, uint _rewardAmount) public {

        bytes32 hash = keccak256(abi.encodePacked(address(this), _from, _to, _value, _data,
            _rewardType, _rewardAmount, nonces[_from]++));

        require(ecrecover(
            keccak256(abi.encodePacked("\x19Ethereum Signed Message:\n32", hash)), _v, _r, _s) == _from);

        // Below is not used. Love should be free!
        // ---------------------------------------
        // if(_rewardAmount > 0) {
        //     if(_rewardType == address(0)){
        //         //pay fee with ether
        //         require(msg.sender.call.value(_rewardAmount)());
        //     } else {
        //         //pay fee with tokens
        //         require((ERC20(_rewardType)).transfer(msg.sender, _rewardAmount));
        //     }
        // }

        require(_to.call.value(_value)(_data));
    }
}
