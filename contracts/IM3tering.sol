// SPDX-License-Identifier: MIT
pragma solidity ^0.8.16;

interface IM3tering {
    error InputIsZero();
    error TransferError();
    error ApprovalFailed();

    event Revenue(
        uint256 indexed tokenId,
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
        uint256 indexed tokenId,
        bool indexed state,
        uint256 indexed timestamp,
        address from
    );

    struct State {
        // int:tariff = float:$$ *10^3
        uint248 tariff;
        bool state;
    }

    function _switch(uint256 tokenId, bool state) external;

    function _setFeeAddress(address otherAddress) external;

    function _setTariff(uint256 tokenId, uint256 tariff) external;

    function pay(uint256 tokenId, uint256 amount) external;

    function claim(uint256 amountOutMin, uint256 deadline) external;

    function revenueOf(address owner) external view returns (uint256[] memory);

    function stateOf(uint256 tokenId) external view returns (bool);

    function tariffOf(uint256 tokenId) external view returns (uint);
}
