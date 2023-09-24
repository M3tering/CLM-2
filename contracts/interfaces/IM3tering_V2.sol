// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

import "./IM3tering.sol";

interface IVersion_2 is IM3tering {
    function claim(uint256 amountOutMin, uint256 deadline) external;
}