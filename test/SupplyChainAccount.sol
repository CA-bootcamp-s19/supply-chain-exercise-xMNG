pragma solidity ^0.5.0;

import "./AccountProxy.sol";
import "../contracts/SupplyChain.sol";

contract SupplyChainAccount is AccountProxy {
    // this function allows a proxyAccount to deploy a SupplyChain contract
    function deploySupplyChainContract() external returns (address) {
        return address(new SupplyChain());
    }
}