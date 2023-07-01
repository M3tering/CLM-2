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
    mapping(uint256 => uint256) private TARIFF;
    mapping(address => uint256) private REVENUE;

    bytes32 public constant PAUSER_ROLE = keccak256("PAUSER_ROLE");
    bytes32 public constant UPGRADER_ROLE = keccak256("UPGRADER_ROLE");
    bytes32 public constant W3BSTREAM_ROLE = keccak256("W3BSTREAM_ROLE");

    uint8 public ioUSDTdecimals = 6;
    IERC20 public ioUSDT = IERC20(0x6fbCdc1169B5130C59E72E51Ed68A84841C98cd1);
    IERC721 public M3terRegistry;

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

        M3terRegistry = IERC721(registry);
    }

    function _setRegistry(address registry) external onlyRole(UPGRADER_ROLE) {
        require(registry != address(0), "M3tering: can't register address(0)");
        M3terRegistry = IERC721(registry);
    }

    function _switch(uint256 id, bool state) external onlyRole(W3BSTREAM_ROLE) {
        STATE[id] = state;
        emit Switch(block.timestamp, id, STATE[id], msg.sender);
    }

    function _setTariff(uint256 id, uint256 tariff) external {
        require(msg.sender == M3terRegistry.ownerOf(id), "M3tering: not owner");
        require(tariff > uint256(0), "tariff can't be less than 1");
        TARIFF[id] = tariff;
    }

    function pay(uint256 id, uint256 amount) external whenNotPaused {
        uint256 value = amount * 10 ** ioUSDTdecimals;
        REVENUE[M3terRegistry.ownerOf(id)] = value;
        require(
            ioUSDT.transferFrom(msg.sender, address(this), value),
            "M3tering: payment failed."
        );
        emit Revenue(id, value, tariffOf(id), msg.sender, block.timestamp);
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
