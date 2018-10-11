pragma solidity ^0.4.24;

import "./ERC20.sol";
import "./EnsSubdomainFactory.sol";

/**
 * @title Tenzorum Love Token
 *
 * @dev ERC20 token with a minting function executed by meta transaction - 'shareLove'
 *      and a proxy function for easy subdomain registrations - 'newSubdomain'.
 *
 * @author Radek Ostrowski - radek@startonchain.com - https://tenzorum.org
 */
contract LoveToken is ERC20 {

    string public constant name = "❤️🌀 Love Token";
    string public constant symbol = "LUV";
    uint8 public constant decimals = 18;

    mapping (address => uint) public nonces;

    EnsSubdomainFactory public factory;
    address public owner;

    event SharedLove(address indexed who, address indexed with, uint256 amount);

    //can only be invoked via execute function (as a meta-tx)
    modifier onlyMetaTx() {
        require(msg.sender == address(this));
        _;
    }

    modifier onlyOwner() {
        require(msg.sender == owner);
        _;
    }

    constructor(EnsSubdomainFactory _factory) {
        factory = _factory;
        owner = msg.sender;
    }

    function shareLove(address _who, address _with, uint256 _amount) public onlyMetaTx {
        _mint(_who, _amount);
        _mint(_with, _amount);
        emit SharedLove(_who, _with, _amount);
    }

    //proxy to EnsSubdomainFactory allowing to create tenz-id as a meta-tx
    function newSubdomain(string _subdomain, string _domain, string _topdomain, address _owner, address _target) public onlyMetaTx {
        factory.newSubdomain(_subdomain, _domain, _topdomain, _owner, _target);
    }

    function updateSubdomainFactory(EnsSubdomainFactory _newFactory) public onlyOwner {
        require(address(factory) != address(_newFactory), "factories must be different");
        factory = _newFactory;
    }

    function transferContractOwnership(address _newOwner) public onlyOwner {
        require(_newOwner != address(0), "cannot transfer to address(0)");
        owner = _newOwner;
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
