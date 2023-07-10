// SPDX-License-Identifier: MIT
pragma solidity ^0.8.16;

interface IM3tering {
    event Revenue(
        bytes32 indexed id,
        uint indexed amount,
        uint indexed taffif,
        address from,
        uint timestamp
    );

    event Claim(
        address indexed to,
        uint indexed amount,
        uint indexed timestamp
    );

    event Switch(
        bytes32 indexed id,
        bool indexed state,
        uint indexed timestamp,
        address from
    );

    function _switch(bytes32 id, bool state) external;

    function _setTariff(bytes32 id, uint tariff) external;

    function pay(bytes32 id, uint amount) external;

    function claim(uint amountOutMin) external;

    function revenueOf(
        address owner
    ) external view returns (uint, uint[] memory);

    function stateOf(bytes32 id) external view returns (bool);

    function tariffOf(bytes32 id) external view returns (uint);
}
