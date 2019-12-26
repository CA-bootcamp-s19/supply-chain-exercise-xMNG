pragma solidity ^0.5.0;

// Proxy contract for testing throws
contract AccountProxy {
  address public target;
  bytes data;

  constructor() public {}

  //prime the data using the fallback function.
  function() external payable {
    data = msg.data;
  }

  function setCallee(address _target) public {
    target = _target;
  }

  // this function does not allow for any return values from the original function call!
  function execute() public returns (bool, bytes memory) {
    return target.call(data);
  }
}
