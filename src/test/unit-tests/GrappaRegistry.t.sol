// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

// import test base and helpers.
import "forge-std/Test.sol";

import {Grappa} from "../../core/Grappa.sol";
import {MockERC20} from "../mocks/MockERC20.sol";

import "../../config/errors.sol";
import "../../config/enums.sol";
import "../../config/constants.sol";

/**
 * @dev test grappa register related functions
 */
contract GrappaRegistry is Test {
    Grappa public grappa;
    MockERC20 private weth;

    constructor() {
        weth = new MockERC20("WETH", "WETH", 18);
        grappa = new Grappa(address(0));
    }

    function testCannotRegisterFromNonOwner() public {
        vm.expectRevert("Ownable: caller is not the owner");
        vm.prank(address(0xaacc));
        grappa.registerAsset(address(weth));
    }

    function testRegisterAssetFromId1() public {
        uint8 id = grappa.registerAsset(address(weth));
        assertEq(id, 1);

        assertEq(grappa.assetIds(address(weth)), id);
    }

    function testRegisterAssetRecordDecimals() public {
        uint8 id = grappa.registerAsset(address(weth));

        (address addr, uint8 decimals) = grappa.assets(id);

        assertEq(addr, address(weth));
        assertEq(decimals, 18);
    }

    function testCannotRegistrySameAssetTwice() public {
        grappa.registerAsset(address(weth));
        vm.expectRevert(GP_AssetAlreadyRegistered.selector);
        grappa.registerAsset(address(weth));
    }

    function testReturnAssetsFromProductId() public {
        grappa.registerAsset(address(weth));

        uint40 product = grappa.getProductId(address(0), address(0), address(weth), address(0), address(weth));

        (, , address underlying, address strike, address collateral, uint8 collatDecimals) = grappa
            .getDetailFromProductId(product);

        assertEq(underlying, address(weth));

        // strike is empty
        assertEq(strike, address(0));
        assertEq(underlying, address(weth));
        assertEq(collateral, address(weth));
        assertEq(collatDecimals, 18);
    }

    function testReturnOptionDetailsFromTokenId() public {
        uint256 expiryTimestamp = block.timestamp + 14 days;
        uint256 strikePrice = 4000 * UNIT;

        grappa.registerAsset(address(weth));

        uint40 product = grappa.getProductId(address(0), address(0), address(weth), address(0), address(weth));
        uint256 token = grappa.getTokenId(TokenType.CALL, product, expiryTimestamp, strikePrice, 0);

        (TokenType tokenType, uint40 productId, uint256 expiry, uint256 longStrike, uint256 shortStrike) = grappa
            .getDetailFromTokenId(token);

        assertEq(uint8(tokenType), uint8(TokenType.CALL));
        assertEq(productId, product);

        // strike is empty
        assertEq(expiry, expiryTimestamp);
        assertEq(longStrike, strikePrice);
        assertEq(shortStrike, 0);
    }
}

/**
 * @dev test grappa functions around registering engines
 */
contract RegisterEngineTest is Test {
    Grappa public grappa;
    address private engine1;

    constructor() {
        engine1 = address(1);
        grappa = new Grappa(address(0));
    }

    function testCannotRegisterFromNonOwner() public {
        vm.expectRevert("Ownable: caller is not the owner");
        vm.prank(address(0xaacc));
        grappa.registerEngine(engine1);
    }

    function testRegisterEngineFromId1() public {
        uint8 id = grappa.registerEngine(engine1);
        assertEq(id, 1);

        assertEq(grappa.engineIds(engine1), id);
    }

    function testCannotRegistrySameEngineTwice() public {
        grappa.registerEngine(engine1);
        vm.expectRevert(GP_EngineAlreadyRegistered.selector);
        grappa.registerEngine(engine1);
    }

    function testReturnEngineFromProductId() public {
        grappa.registerEngine(engine1);

        uint40 product = grappa.getProductId(address(0), address(engine1), address(0), address(0), address(0));

        (, address engine, , , , ) = grappa.getDetailFromProductId(product);

        assertEq(engine, engine1);
    }
}

/**
 * @dev test grappa functions around registering engines
 */
contract RegisterOracleTest is Test {
    Grappa public grappa;
    address private oracle1;

    constructor() {
        oracle1 = address(1);
        grappa = new Grappa(address(0));
    }

    function testCannotRegisterFromNonOwner() public {
        vm.expectRevert("Ownable: caller is not the owner");
        vm.prank(address(0xaacc));
        grappa.registerOracle(oracle1);
    }

    function testRegisterOracleFromId1() public {
        uint8 id = grappa.registerOracle(oracle1);
        assertEq(id, 1);

        assertEq(grappa.oracleIds(oracle1), id);
    }

    function testCannotRegistrySameOracleTwice() public {
        grappa.registerOracle(oracle1);
        vm.expectRevert(GP_OracleAlreadyRegistered.selector);
        grappa.registerOracle(oracle1);
    }

    function testReturnEngineFromProductId() public {
        grappa.registerOracle(oracle1);

        uint40 product = grappa.getProductId(address(oracle1), address(0), address(0), address(0), address(0));

        (address oracle, , , , , ) = grappa.getDetailFromProductId(product);

        assertEq(oracle1, oracle);
    }
}