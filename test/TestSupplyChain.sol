pragma solidity ^0.5.0;

import "truffle/Assert.sol";
import "truffle/DeployedAddresses.sol";
import "../contracts/SupplyChain.sol";
import "./SupplyChainAccount.sol";

// TODO: try catch

// NOTES
// sol tests allow contract to contract testing, vs just web3 to contract in js tests
// Regular function invocations will bubble up to the caller and end the tx, but low-level call function returns false/true, so we can test for certain conditions/throws without breaking the test!
// Proxy contract can wrap each call so .call(abi.encodeWithSignature(signatureString, arg); doesn't need to we written out each time. We just call .execute();
// Also need proxies if we want to switch addresses.

contract SupplyChainTest { // the syntax for tests is nameTest
    // Test for failing conditions in this contracts:
    // https://truffleframework.com/tutorials/testing-for-throws-in-solidity-tests

    uint public initialBalance = 0.1 ether; // low so not to use up all test ether
    // Truffle will send the TestContract one Ether after deploying the contract.
    // The accounts won't have a balance until sending a tx?

    SupplyChain supplyChainInstance; // the instance
    SupplyChainAccount owner;
    SupplyChainAccount seller;
    SupplyChainAccount buyer;
    SupplyChainAccount other;


    function beforeEach() public {
        // TODO: why does the below throw an error?
        // supplyChainInstance = new SupplyChain(); // deploy new instance before every test
        owner = new SupplyChainAccount();
        seller = new SupplyChainAccount();
        buyer = new SupplyChainAccount();
        other = new SupplyChainAccount();

        supplyChainInstance = SupplyChain(owner.deploySupplyChainContract());

        owner.setCallee(address(supplyChainInstance));
        seller.setCallee(address(supplyChainInstance));
        buyer.setCallee(address(supplyChainInstance));
        other.setCallee(address(supplyChainInstance));
    }

    // test adding items
    function testAddItem() public {
        uint initial = supplyChainInstance.skuCount();
        Assert.equal(initial, 0, "should be 0 items");

        SupplyChain(address(seller)).addItem("laptop", 5 wei); // add an item
        (bool result, ) = SupplyChainAccount(address(seller)).execute.gas(200000)();
    //     // we cap the gas because otherwise the call would eat all the gas.
    //     // we want enough gas so we avoid OOG and trigger the actual condition
        Assert.isTrue(result, "should be able to purchase");

        uint oneSku = supplyChainInstance.skuCount();
        Assert.equal(oneSku, 1, "should be 1 item");

        address ownerAddr = supplyChainInstance.owner();
        Assert.equal(ownerAddr, address(owner), "owner should match address");

        (string memory name, uint sku, uint price, SupplyChain.State state, address sellerAddr, address buyerAddr) = supplyChainInstance.items(0);

        Assert.equal(name, 'laptop', "should be laptop");
        Assert.equal(sku, 0, "should be sku 0");
        Assert.equal(price, 5 wei, "should be 5 wei");
        /* If state is not casted to uint, then this error is thrown:
        TypeError: Member "equal" not found or not visible after argument-dependent lookup in type(library Assert).
        Assert.equal(state, SupplyChain.State.ForSale, "should be State.ForSale");
        ^----------^
        */
        Assert.equal(uint(state), 0, "should be State.ForSale");
        Assert.equal(sellerAddr, address(seller), "should be address(this)");
        Assert.equal(buyerAddr, address(0), "should be address(0)");
    }

    /*
        buyItem tests
    */

    // test purchase of item
    function testBuyItem() public { // the syntax for test is testName

        SupplyChain(address(seller)).addItem("CITC", 5 wei); // add an item
        SupplyChain(address(buyer)).buyItem.value(10 wei)(0);
        Assert.equal(address(buyer).balance, 10 wei, "this is the current wei balance"); // test to see if this address has the truffle initialBalance

        (bool result, ) = SupplyChainAccount(address(buyer)).execute.gas(300000)();
        Assert.isTrue(result, "should have executed");

        (,,,SupplyChain.State state,,address buyerAddr) = supplyChainInstance.items(0);
        Assert.equal(uint(state), 1, "should be State.Sold");
        Assert.equal(buyerAddr, address(buyer), "should be bought by seller");
        Assert.equal(buyerAddr.balance, 5 wei, "should be refunded excess");
    }

    // test for failure if buyer does not send enough funds
    // function testBuyFailsIfNotEnoughEth() public {
    //     SupplyChain(address(seller)).addItem("CITC", 5 wei); // add an item

    //     // why doesn't this need to be wrapped with SupplyChain()?
    //     (bool result, ) = address(buyer).call.value(4 wei)(abi.encodeWithSignature("buyItem(uint256)", 0));

    //     Assert.isFalse(result, "should be false since only 4 wei sent and 5 wei required");
    // }

    // test for purchasing an item that is not for Sale
    // function testBuyFailIfItemNotForSale() public {
    //     uint skuCount = supplyChainInstance.skuCount();
    //     (,,uint price,,,) = supplyChainInstance.items(0);

    //     Assert.equal(skuCount, 0, "skuCount should be zero");
    //     Assert.equal(price, 0, "price should be zero because index 0 item is not for sale");
        
    //     (bool result, ) = address(buyer).call.value(10 wei)(abi.encodeWithSignature("buyItem(uint256)", 1));
    //     Assert.isFalse(result, "should be false since item 0 is not for sale");
    // }

    // /*
    //     shipItem tests
    // */
    
    // // test shipItem
    // function testShipItem() public {
    //     SupplyChain(address(seller)).addItem("laptop", 5 wei);
    //     SupplyChain(address(buyer)).buyItem.value(5 wei)(0);
    //     SupplyChain(address(seller)).shipItem(0);

    //     (,,, SupplyChain.State state,,) = supplyChainInstance.items(0);
    //     Assert.equal(uint(state), 2, "should be state 2 for State.Shipped");
    // }

    // // test for trying to ship an item that is not marked Sold
    // function testShipItemFailIfNotYetSold() public {
    //     SupplyChain(address(seller)).addItem("laptop", 5 wei);
    //     (bool result,) = address(seller).call(abi.encodeWithSignature("shipItem(uint256)", 0));
    //     Assert.isFalse(result, "seller cannot ship an item not marked as Sold");
    // }

    // // test for calls that are made by not the seller
    // function testShipItemFailIfNotSeller() public {
    //     SupplyChain(address(seller)).addItem("laptop", 5 wei);
    //     SupplyChain(address(buyer)).buyItem.value(5 wei)(0);

    //     (bool result,) = address(other).call(abi.encodeWithSignature("shipItem(uint256", 0));
    //     Assert.isFalse(result, "non-seller cannot ship items");
    // }

    // /*
    //     receiveItem tests
    // */

    // function testReceiveItem() public {
    //     SupplyChain(address(seller)).addItem("laptop", 5 wei);
    //     SupplyChain(address(buyer)).buyItem.value(5 wei)(0);
    //     SupplyChain(address(seller)).shipItem(0);
    //     SupplyChain(address(buyer)).receiveItem(0);

    //     (,,, SupplyChain.State state,,) = supplyChainInstance.items(0);
    //     Assert.equal(uint(state), 3, "should be state 3 for Received");
    // }

    // // test calling the function on an item not marked Shipped
    // function testReceiveItemFailIfItemNotMarkedAsShipped() public {
    //     SupplyChain(address(seller)).addItem("laptop", 5 wei);
    //     SupplyChain(address(buyer)).buyItem.value(5 wei)(0);

    //     (bool result,) = address(buyer).call(abi.encodeWithSignature("receiveItem(uint256)", 0));
    //     Assert.isFalse(result, "cannot call receivedItem on item not shipped");
    // }

    // // test calling the function from an address that is not the buyer
    // function testReceiveItemFailIfNotFromBuyer() public {
    //     SupplyChain(address(seller)).addItem("laptop", 5 wei);
    //     SupplyChain(address(buyer)).buyItem.value(5 wei)(0);
    //     SupplyChain(address(seller)).shipItem(0);

    //     (bool result,) = address(other).call(abi.encodeWithSignature("receiveItem(uint256)", 0));
    //     Assert.isFalse(result, "cannot call receiveItem if not buyer");
    // }
}