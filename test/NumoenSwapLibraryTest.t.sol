// SPDX-License-Identifier: GPL-3.0-only
pragma solidity ^0.8.0;

import { Test } from "forge-std/Test.sol";
import { NumoenSwapLibrary } from "src/NumoenSwapLibrary.sol";

import { Factory } from "numoen/core/Factory.sol";
import { Pair } from "numoen/core/Pair.sol";

contract NumoenSwapLibraryTest is Test {
    Pair internal pair;

    function setUp() external {
        Factory factory = new Factory();

        pair = Pair(factory.createLendgine(address(1), address(2), 18, 18, 5e18));
    }

    /// @notice Test amount0 in under normal conditions
    function testToken0In() external {
        uint256 amount0 = NumoenSwapLibrary.getToken0In(1e18, 1e18, 8e18, 1e18, 1, 1, 5e18);

        assertEq(amount0, 1.25e18 + 1);
    }

    /// @notice Test amount0 in with an unusual token0Scale
    function testToken0InScale0() external {
        uint256 amount0 = NumoenSwapLibrary.getToken0In(1e18, 1e6, 8e18, 1e18, 1e12, 1, 5e18);

        assertEq(amount0, 1.25e6 + 1);
    }

    /// @notice Test amount0 in with an unusual token1Scale
    function testToken0InScale1() external {
        uint256 amount0 = NumoenSwapLibrary.getToken0In(1e6, 1e18, 8e6, 1e18, 1, 1e12, 5e18);

        assertEq(amount0, 1.25e18 + 1);
    }

    /// @notice Test amount0 out under normal conditions
    function testToken0Out() external {
        uint256 amount0 = NumoenSwapLibrary.getToken0Out(1e18, 1e18, 8e18, 1e18, 1, 1, 5e18);

        assertEq(amount0, 0.75e18 - 1);
    }

    /// @notice Test amount0 with an unusual token0Scale
    function testToken0OutScale0() external {
        uint256 amount0 = NumoenSwapLibrary.getToken0Out(1e18, 1e6, 8e18, 1e18, 1e12, 1, 5e18);

        assertEq(amount0, 0.75e6 - 1);
    }

    /// @notice Test amount0 with an unusual token1Scale
    function testToken0OutScale1() external {
        uint256 amount0 = NumoenSwapLibrary.getToken0Out(1e6, 1e18, 8e6, 1e18, 1, 1e12, 5e18);

        assertEq(amount0, 0.75e18 - 1);
    }

    /// @notice test amount0In against the pair invariant
    function testToken0InAgainstInvariant() external {
        uint256 reserve0Before = 1e18;
        uint256 reserve1Before = 8e18;
        uint256 liquidity = 1e18;

        assertEq(pair.invariant(reserve0Before, reserve1Before, liquidity), true);

        uint256 amount1Out = 1e18;
        uint256 amount0In =
            NumoenSwapLibrary.getToken0In(amount1Out, reserve0Before, reserve1Before, liquidity, 1, 1, 5e18);

        assertEq(
            pair.invariant(reserve0Before + amount0In, reserve1Before - amount1Out, liquidity), true, "Passes invariant"
        );
        assertEq(
            pair.invariant(reserve0Before + amount0In - 5, reserve1Before - amount1Out, liquidity),
            false,
            "Fails invariant when sending less"
        );
        assertEq(
            pair.invariant(reserve0Before + amount0In + 1, reserve1Before - amount1Out, liquidity),
            true,
            "Passes invariant when sending more"
        );
    }

    /// @notice Test amount0Out against the pair invariant
    function testToken0OutAgainstInvariant() external {
        uint256 reserve0Before = 1e18;
        uint256 reserve1Before = 8e18;
        uint256 liquidity = 1e18;

        assertEq(pair.invariant(reserve0Before, reserve1Before, liquidity), true);

        uint256 amount1In = 1e18;
        uint256 amount0Out =
            NumoenSwapLibrary.getToken0Out(amount1In, reserve0Before, reserve1Before, liquidity, 1, 1, 5e18);

        assertEq(
            pair.invariant(reserve0Before - amount0Out, reserve1Before + amount1In, liquidity), true, "Passes invariant"
        );
        assertEq(
            pair.invariant(reserve0Before - amount0Out - 5, reserve1Before + amount1In, liquidity),
            false,
            "Fails invariant when sending less"
        );
        assertEq(
            pair.invariant(reserve0Before - amount0Out + 1, reserve1Before + amount1In, liquidity),
            true,
            "Passes invariant when sending more"
        );
    }

    /// @notice Test amount0 in edge cases
    function testToken0InRounding() external {
        uint256 reserve0Before = 1e18 - 1;
        uint256 reserve1Before = 8e18 - 8;
        uint256 liquidity = 1e18 - 1;

        assertEq(pair.invariant(reserve0Before, reserve1Before, liquidity), true);

        uint256 amount1Out = 1e18;
        uint256 amount0In =
            NumoenSwapLibrary.getToken0In(amount1Out, reserve0Before, reserve1Before, liquidity, 1, 1, 5e18);

        assertEq(amount0In, 1.25 ether + 3);

        assertEq(
            pair.invariant(reserve0Before + amount0In, reserve1Before - amount1Out, liquidity), true, "Passes invariant"
        );
        assertEq(
            pair.invariant(reserve0Before + amount0In - 1, reserve1Before - amount1Out, liquidity),
            false,
            "Fails invariant when sending less"
        );
        assertEq(
            pair.invariant(reserve0Before + amount0In + 1, reserve1Before - amount1Out, liquidity),
            true,
            "Passes invariant when sending more"
        );
    }

    /// @notice Test amount0 out edge cases
    function testToken0OutRounding() external {
        uint256 reserve0Before = 1e18 - 1;
        uint256 reserve1Before = 8e18 - 8;
        uint256 liquidity = 1e18 - 1;

        assertEq(pair.invariant(reserve0Before, reserve1Before, liquidity), true);

        uint256 amount1In = 1e18;
        uint256 amount0Out =
            NumoenSwapLibrary.getToken0Out(amount1In, reserve0Before, reserve1Before, liquidity, 1, 1, 5e18);
        assertEq(amount0Out, 0.75e18 - 2);

        assertEq(
            pair.invariant(reserve0Before - amount0Out, reserve1Before + amount1In, liquidity), true, "Passes invariant"
        );
        assertEq(
            pair.invariant(reserve0Before - amount0Out - 5, reserve1Before + amount1In, liquidity),
            false,
            "Fails invariant when sending less"
        );
        assertEq(
            pair.invariant(reserve0Before - amount0Out + 1, reserve1Before + amount1In, liquidity),
            true,
            "Passes invariant when sending more"
        );
    }
}
