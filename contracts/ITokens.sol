// SPDX-License-Identifier: MIT
pragma solidity ^0.8.16;

interface ERC20 {
    function transferFrom(
        address from,
        address to,
        uint256 value
    ) external returns (bool success);

    function approve(
        address spender,
        uint256 value
    ) external returns (bool success);
}

interface ERC721 {
    function ownerOf(uint256 tokenId) external view returns (address);
}
