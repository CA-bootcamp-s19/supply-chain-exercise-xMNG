pragma solidity ^0.5.0;

import "truffle/Assert.sol";
import "truffle/DeployedAddresses.sol";
import "../contracts/SupplyChain.sol";

// sol tests allow contract to contract testing, vs just web3 to contract
// raw calls return bool but subcalls won't automatically bubble up

contract SupplyChainTest { // the syntax for tests is nameTest
    // Test for failing conditions in this contracts:
    // https://truffleframework.com/tutorials/testing-for-throws-in-solidity-tests
    SupplyChain supplyChainInstance;
    SupplyChainThrowProxy throwProxy;

    function beforeEach() public {
        // supplyChainInstance = SupplyChain(DeployedAddresses.SupplyChain()); // new deployed supplyChain contract every time
        supplyChainInstance = new SupplyChain(); // deploy new instance before every test
        supplyChainInstance.addItem("laptop", 5);

        throwProxy = new SupplyChainThrowProxy(address(supplyChainInstance)); // creates a new SupplyChainThrowProxy with the target addr

    }

    // buyItem
    function testBuyItem() public { // the syntax for test is testName
        bool result;
        bytes memory data;

    // test for purchasing an item that is not for Sale
        SupplyChain(address(throwProxy)).buyItem(1); // 1 doesn't exist
        (result, data) = throwProxy.execute.gas(200000)();
        Assert.isFalse(result, "Should be false since item not for sale");

    // test for failure if user does not send enough funds
        SupplyChain(address(throwProxy)).buyItem(0);
        (result, data) = throwProxy.execute.gas(200000)();
        Assert.isFalse(result, "Should be false since did not sent enough ether");
    }


    // shipItem
    function testShipItem() public {
    // test for calls that are made by not the seller
    // test for trying to ship an item that is not marked Sold

    }


    // receiveItem
    function testReceiveItem() public {
    // test calling the function from an address that is not the buyer
    // test calling the function on an item not marked Shipped

    }

}

contract SupplyChainThrowProxy {
    address public target;
    bytes public data;

    constructor(address _target) public {
        target = _target;
    }

    // fallback func for storing msg data
    function() external { // fallbacks must be external
        data = msg.data;
    }

    // will call the function of the target with payload
    function execute() public returns(bool, bytes memory) {
        return target.call(data);
    }
}