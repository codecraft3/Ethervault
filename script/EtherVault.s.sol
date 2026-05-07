// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import {Script} from "forge-std/Script.sol";
import {EtherVault} from "../src/EtherVault.sol";
import {ERC1967Proxy} from "@openzeppelin/contracts/proxy/ERC1967/ERC1967Proxy.sol";

contract EtherVaultScript is Script {


    function run() external returns(address) {
        address proxy = deployEtherVault();
        return proxy;
    }

    function deployEtherVault() public returns (address) {
        vm.startBroadcast();
        EtherVault vault = new EtherVault();
        ERC1967Proxy proxy = new ERC1967Proxy(
            address(vault),
            abi.encodeWithSelector(EtherVault.initialize.selector, 10)
        );
        vm.stopBroadcast();
        return address(proxy);
    }
}
