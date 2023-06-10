// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

import "@openzeppelin/contracts-upgradeable/security/PausableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/access/AccessControlUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/UUPSUpgradeable.sol";

import "./IM3tering.sol";

/// @custom:security-contact info@whynotswitch.com
contract M3tering is
    IM3tering,
    Initializable,
    PausableUpgradeable,
    AccessControlUpgradeable,
    UUPSUpgradeable
{
    // map id -> metadata
    mapping(uint256 => bool) private STATE;
    mapping(uint256 => address) private PROVIDER;
    mapping(uint256 => uint256) private TARIFF;

    mapping(address => uint256) private REVENUE;

    bytes32 public constant PAUSER_ROLE = keccak256("PAUSER_ROLE");
    bytes32 public constant UPGRADER_ROLE = keccak256("UPGRADER_ROLE");
    bytes32 public constant W3BSTREAM_ROLE = keccak256("W3BSTREAM_ROLE");

    address public M3terRegistry;

    /// @custom:oz-upgrades-unsafe-allow constructor
    constructor() {
        _disableInitializers();
    }

    function initialize(address registryAddress) public initializer {
        __Pausable_init();
        __AccessControl_init();
        __UUPSUpgradeable_init();

        _grantRole(DEFAULT_ADMIN_ROLE, msg.sender);
        _grantRole(PAUSER_ROLE, msg.sender);
        _grantRole(UPGRADER_ROLE, msg.sender);
        _grantRole(W3BSTREAM_ROLE, msg.sender);

        M3terRegistry = registryAddress;
    }

    // TODO: allow w3bstream, provider & owner to call
    function _switch(uint256 id, bool state) external onlyRole(W3BSTREAM_ROLE) {
        STATE[id] = state;
        emit Switch(block.timestamp, id, STATE[id], msg.sender);
    }

    function _tariff(uint256 id, uint256 tariff) external {
        // TODO: allow w3bstream, provider & owner to call
        require(
            msg.sender == IM3ter(M3terRegistry).ownerOf(id),
            "M3tering: you aren't M3ter owner"
        );
        TARIFF[id] = tariff;
        emit Tariff(block.timestamp, id, TARIFF[id], msg.sender);
    }

    function _setRegistry(
        address registryAddress
    ) external onlyRole(UPGRADER_ROLE) {
        M3terRegistry = registryAddress;
    }

    function pay(uint256 id) external payable whenNotPaused {
        address provider = PROVIDER[id];
        address owner = IM3ter(M3terRegistry).ownerOf(id);
        require(provider != address(0), "M3tering: invalid token ID");

        uint x = (msg.value * 8) / 10;
        uint y = msg.value - x;

        REVENUE[owner] += x;
        REVENUE[provider] += y;

        emit Revenue(msg.sender, msg.value, id, block.timestamp);
    }

    function claim() external whenNotPaused {
        uint256 amount = REVENUE[msg.sender];
        require(amount <= uint256(0), "M3tering: no revenues to claim");

        REVENUE[msg.sender] = 0;
        (bool success, ) = payable(msg.sender).call{value: amount}("");
        require(success, "M3tering: revenue claim failed");

        emit Claim(msg.sender, amount, block.timestamp);
    }

    function stateOf(uint256 id) external view returns (bool) {
        return STATE[id];
    }

    function tariffOf(uint256 id) external view returns (uint256) {
        return TARIFF[id];
    }

    function revenueOf(address owner) external view returns (uint256) {
        return REVENUE[owner];
    }

    function pause() public onlyRole(PAUSER_ROLE) {
        _pause();
    }

    function unpause() public onlyRole(PAUSER_ROLE) {
        _unpause();
    }

    function _authorizeUpgrade(
        address newImplementation
    ) internal override onlyRole(UPGRADER_ROLE) {}
}
