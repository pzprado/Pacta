// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

// Copied from [chronicle-std](https://github.com/chronicleprotocol/chronicle-std/blob/main/src/IChronicle.sol).
interface IChronicle {
    /**
     * @notice Returns the oracle's current value.
     * @dev Reverts if no value set.
     * @return value The oracle's current value.
     */
    function read() external view returns (uint256 value);

    /**
     * @notice Returns the oracle's current value and its age.
     * @dev Reverts if no value set.
     * @return value The oracle's current value using 18 decimals places.
     * @return age The value's age as a Unix Timestamp .
     *
     */
    function readWithAge() external view returns (uint256 value, uint256 age);
}

// Copied from [self-kisser](https://github.com/chronicleprotocol/self-kisser/blob/main/src/ISelfKisser.sol).
interface ISelfKisser {
    // -- User Functionality --

    /// @notice Kisses caller on oracle `oracle`.
    ///
    /// @dev Reverts if oracle `oracle` not supported.
    /// @dev Reverts if SelfKisser dead.
    ///
    /// @param oracle The oracle to kiss the caller on.
    function selfKiss(address oracle) external;

    /// @notice Kisses address `who` on oracle `oracle`.
    ///
    /// @dev Reverts if oracle `oracle` not supported.
    /// @dev Reverts if SelfKisser dead.
    ///
    /// @param oracle The oracle to kiss address `who` on.
    /// @param who The address to kiss on oracle `oracle`.
    function selfKiss(address oracle, address who) external;
}
