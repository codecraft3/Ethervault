// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import {Test} from "forge-std/Test.sol";
import {console2} from "forge-std/console2.sol";
import {EtherVault} from "../src/EtherVault.sol";
import {ERC1967Proxy} from "@openzeppelin/contracts/proxy/ERC1967/ERC1967Proxy.sol";

contract EtherVaultTest is Test {
    EtherVault public vault;

    address public alice = makeAddr("Alice");
    address public bob = makeAddr("Bob");

    function setUp() public {
        EtherVault vaultImpl = new EtherVault();
        ERC1967Proxy proxy = new ERC1967Proxy(
            address(vaultImpl),
            abi.encodeCall(EtherVault.initialize, 10)
        );
        vault = EtherVault(payable(address(proxy)));
        giveCash(alice, 20 ether);
        giveCash(bob, 20 ether);
    }

    function test_deposit() public {
        vm.startPrank(alice);
        vault.deposit{value: 2 ether}();

        (uint256 balance, uint256 timestamp, bool alreadyDeposited) = vault.userData(alice);
        assertEq(vault.vaultBalance(), 2 ether);
        assertEq(alice.balance, 18 ether);
        assertEq(balance, 1.8 ether);
        assertTrue(alreadyDeposited);
    }

    function test_withdraw() public {
        vm.startPrank(bob);
        vault.deposit{value: 7 ether}();

        (uint256 balance, uint256 timestamp, bool alreadyDeposited) = vault.userData(bob);

        assertEq(balance, 6.3 ether);
        assertEq(vault.vaultBalance(), 7 ether);
        assertEq(bob.balance, 13 ether);
        assertTrue(alreadyDeposited);

        vault.withdraw(3 ether);

        (uint256 balance2, uint256 timestamp2, bool alreadyDeposited2) = vault.userData(bob);
        assertEq(balance2, 3.3 ether);
        assertEq(vault.vaultBalance(), 4 ether);
        assertEq(bob.balance, 16 ether);
        assertEq(vault.feeBalance(), 0.7 ether);
        assertTrue(alreadyDeposited);

    }

    function test_withdrawFee() public {
        vm.startPrank(alice);

        vault.deposit{value: 1 ether}();

        vm.startPrank(address(this));
        uint256 adminBalance = address(this).balance;
        vault.withdrawFee(address(this));
        uint256 newAdminBalance = address(this).balance - adminBalance;

        assertEq(newAdminBalance, 0.1 ether);


    }

    function giveCash(address _user, uint256 _amount) private {
        deal(_user, _amount);
    }

    receive() external payable {}

}
 