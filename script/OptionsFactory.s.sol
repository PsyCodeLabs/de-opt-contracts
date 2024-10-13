// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "forge-std/Script.sol";
import "forge-std/console.sol";
import "../src/primary/Factory.sol";

/**
 * @title NewFactory Script
 * @author PsyCode Labs
 *
 * This is a deploy script which is used to create a new factory contract
 */
contract NewFactory is Script {
    function setUp() public {}

    function run() public {
        // setting up wallet
        uint256 privateKey = vm.envUint("DEV_PRIVATE_KEY");

        vm.startBroadcast(privateKey);

        // creating a new OptionsFactory contract with address of NOTE token as parameter
        OptionsFactory factory = new OptionsFactory(0x03F734Bd9847575fDbE9bEaDDf9C166F880B5E5f);

        // setting price oracles for assets
        factory.setPriceOracle(0x04a72466De69109889Db059Cb1A4460Ca0648d9D, 0x3b5dAAE6d0a1B98EF8B2E6B65206c93c8cE55841);
        factory.setPriceOracle(0xCa03230E7FB13456326a234443aAd111AC96410A, 0xc302BD52985e75C1f563a47f2b5dfC4e2b5C6C7E);

        vm.stopBroadcast();
    }
}

/**
 * @title SetFactoryOracles Script
 * @author PsyCode Labs
 *
 * This is an interaction script which is used to set/update oracles for assets
 */
contract SetFactoryOracles is Script {
    OptionsFactory factory;

    function setUp() public {
        // initing factory from deployed address
        factory = OptionsFactory(0xd42FdE6daCDCC075c44C1977b57d1a3Fcd0fe8c6);
    }

    function run() public {
        // setting up wallet
        uint256 privateKey = vm.envUint("DEV_PRIVATE_KEY");

        vm.startBroadcast(privateKey);

        // calling setPriceOracle to set/update price oracles for assets
        factory.setPriceOracle(0x04a72466De69109889Db059Cb1A4460Ca0648d9D, 0x3b5dAAE6d0a1B98EF8B2E6B65206c93c8cE55841);
        factory.setPriceOracle(0xCa03230E7FB13456326a234443aAd111AC96410A, 0xc302BD52985e75C1f563a47f2b5dfC4e2b5C6C7E);
        factory.setPriceOracle(0x40E41DC5845619E7Ba73957449b31DFbfB9678b2, 0x31D8eFBeD8F097365D49010CA45D6c7C47A0714b);

        vm.stopBroadcast();
    }
}
