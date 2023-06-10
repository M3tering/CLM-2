// SPDX-License-Identifier: MIT
pragma solidity ^0.8.16;

interface IM3ter {
    function ownerOf(uint256 tokenId) external view returns (address);
}

interface IM3tering {
    event Revenue(
        address from,
        uint256 indexed amount,
        uint256 indexed id,
        uint256 indexed timestamp
    );

    event Claim(
        address indexed to,
        uint256 indexed amount,
        uint256 indexed timestamp
    );

    event Switch(
        uint256 indexed timestamp,
        uint256 indexed id,
        bool indexed state,
        address from
    );

    event Setup(
        uint256 indexed timestamp,
        uint256 indexed id,
        uint256 indexed tariff,
        address delegate,
        address from
    );

    function _switch(uint256 id, bool state) external;

    function _setup(uint256 id, uint256 tariff, address delegate) external;

    function _setRegistry(address registryAddress) external;

    function pay(uint256 id) external payable;

    function claim() external;

    function revenueOf(address owner) external view returns (uint256);

    function stateOf(uint256 id) external view returns (bool);

    function tariffOf(uint256 id) external view returns (uint256);
}
