// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;
interface ISolaxy {
    function safeDeposit(uint256 assets, address receiver, uint256 minSharesOut) external returns (uint256 shares);
}
