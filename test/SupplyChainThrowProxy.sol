pragma solidity ^0.5.0;

contract SupplyChainThrowProxy {

    address public target;
    bytes public data;

    constructor(address _target) public {
        target = _target;
    }

    // fallback func for storing msg data
    function() payable external{ // fallbacks must be external
        data = msg.data;
    }

    // will call the function of the target with payload
    function execute() public returns(bool, bytes memory) {
        return target.call(data);
    }
}