// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

import "@openzeppelin/contracts-upgradeable/security/PausableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/access/AccessControlUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/UUPSUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC721/IERC721Upgradeable.sol";

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
    mapping(uint256 => uint256) private TARIFF;
    mapping(address => uint256) private REVENUE;

    bytes32 public constant PAUSER_ROLE = keccak256("PAUSER_ROLE");
    bytes32 public constant UPGRADER_ROLE = keccak256("UPGRADER_ROLE");
    bytes32 public constant W3BSTREAM_ROLE = keccak256("W3BSTREAM_ROLE");

    address public M3terRegistry;
    address M3terdelegate;

    /// @custom:oz-upgrades-unsafe-allow constructor
    constructor() {
        _disableInitializers();
    }

    function initialize(address registry) public initializer {
        require(registry != address(0), "M3tering: can't register address(0)");
        __Pausable_init();
        __AccessControl_init();
        __UUPSUpgradeable_init();

        _grantRole(DEFAULT_ADMIN_ROLE, msg.sender);
        _grantRole(PAUSER_ROLE, msg.sender);
        _grantRole(UPGRADER_ROLE, msg.sender);
        _grantRole(W3BSTREAM_ROLE, msg.sender);

        M3terRegistry = registry;
        M3terdelegate = msg.sender;
    }

    function _setRegistry(address registry) external onlyRole(UPGRADER_ROLE) {
        require(registry != address(0), "M3tering: can't register address(0)");
        M3terRegistry = registry;
    }

    function _setDelegate(address delegate) external onlyRole(UPGRADER_ROLE) {
        require(delegate != address(0), "M3tering: can't delegate address(0)");
        M3terdelegate = delegate;
    }

    function _switch(uint256 id, bool state) external onlyRole(W3BSTREAM_ROLE) {
        STATE[id] = state;
        emit Switch(block.timestamp, id, STATE[id], msg.sender);
    }

    function _setTariff(uint256 id, uint256 tariff) external {
        require(msg.sender == M3terdelegate, "M3tering: not delegate address");
        require(tariff > uint256(0), "tariff can't be less than 1");
        TARIFF[id] = tariff;
    }

    function pay(uint256 id) external payable whenNotPaused {
        uint x = (msg.value * 8) / 10;
        uint y = msg.value - x;

        REVENUE[IERC721Upgradeable(M3terRegistry).ownerOf(id)] += x;
        REVENUE[M3terdelegate] += y;

        emit Revenue(id, msg.value, tariffOf(id), msg.sender, block.timestamp);
    }

    function claim() external whenNotPaused {
        uint256 amount = REVENUE[msg.sender];
        if (amount > uint256(0)) {
            REVENUE[msg.sender] = 0;
            (bool success, ) = payable(msg.sender).call{value: amount}("");
            require(success, "M3tering: revenue claim failed");
            emit Claim(msg.sender, amount, block.timestamp);
        }
    }

    function revenueOf(address owner) external view returns (uint256) {
        return REVENUE[owner];
    }

    function stateOf(uint256 id) external view returns (bool) {
        return STATE[id];
    }

    function tariffOf(uint256 id) public view returns (uint256) {
        if (TARIFF[id] < uint256(1)) {
            return uint256(1);
        } else {
            return TARIFF[id];
        }
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
