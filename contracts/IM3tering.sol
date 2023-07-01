// SPDX-License-Identifier: MIT
pragma solidity ^0.8.16;

interface IERC20 {
    function transferFrom(
        address _from,
        address _to,
        uint256 _value
    ) external returns (bool success);
}

interface IERC721 {
    function ownerOf(uint256 _tokenId) external view returns (address);
}

interface IM3tering {
    event Revenue(
        uint256 indexed id,
        uint256 indexed amount,
        uint256 indexed taffif,
        address from,
        uint256 timestamp
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

    function _setRegistry(address registryAddress) external;

    function _switch(uint256 id, bool state) external;

    function _setTariff(uint256 id, uint256 tariff) external;

    function pay(uint256 id, uint256 amount) external;

    function claim() external;

    function revenueOf(address owner) external view returns (uint256);

    function stateOf(uint256 id) external view returns (bool);

    function tariffOf(uint256 id) external view returns (uint256);
}
