// SPDX-License-Identifier: MIT
pragma solidity ^0.8.16;

interface IERC20 {
    function transferFrom(
        address _from,
        address _to,
        uint256 _value
    ) external returns (bool success);

    function approve(
        address _spender,
        uint256 _value
    ) external returns (bool success);
}

interface IERC721 {
    function ownerOf(uint256 _tokenId) external view returns (address);
}
