// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

import "@openzeppelin/contracts-upgradeable/security/PausableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/access/AccessControlUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/UUPSUpgradeable.sol";

import "./IERCtokens.sol";
import "./IM3tering.sol";
import "./IMimo.sol";

/// @custom:security-contact info@whynotswitch.com
contract M3tering is
    IM3tering,
    Initializable,
    PausableUpgradeable,
    AccessControlUpgradeable,
    UUPSUpgradeable
{
    // map id -> metadata
    struct State {
        bool state;
        uint248 tariff; 
    /* tariff is a USD denominated floating point number
        where the last 3 digits repressent decimal values
        -------------------------------------------------
        ie   #1240 -->  1240 / 10 ** 3  -->  $1.240
    */
    }

    mapping(bytes32 => State) STATES;
    mapping(address => uint) REVENUE;

    bytes32 public constant PAUSER_ROLE = keccak256("PAUSER_ROLE");
    bytes32 public constant UPGRADER_ROLE = keccak256("UPGRADER_ROLE");
    bytes32 public constant W3BSTREAM_ROLE = keccak256("W3BSTREAM_ROLE");

    uint public constant DAI_BASE_UNITS = 10 ** 18;
    ERC721 public constant M3terRegistry = ERC721(address(0)); // TODO: set address
    ERC20 public constant DAI = ERC20(0x1CbAd85Aa66Ff3C12dc84C5881886EEB29C1bb9b); // ioDAI
    IMimo public constant MIMO = IMimo(0x147CdAe2BF7e809b9789aD0765899c06B361C5cE); // router
    address public constant CELL = address(0); // TODO: set address

    /// @custom:oz-upgrades-unsafe-allow constructor
    constructor() {
        _disableInitializers();
    }

    function initialize() public initializer {
        __Pausable_init();
        __AccessControl_init();
        __UUPSUpgradeable_init();

        _grantRole(DEFAULT_ADMIN_ROLE, msg.sender);
        _grantRole(PAUSER_ROLE, msg.sender);
        _grantRole(UPGRADER_ROLE, msg.sender);
        _grantRole(W3BSTREAM_ROLE, msg.sender);
    }

    function _M3terOwner(bytes32 id) internal view returns (address) {
        return M3terRegistry.ownerOf(uint(id));
    }

    function _swapPath() internal pure returns (address[] memory) {
        address[] memory path = new address[](2);
        path[0] = address(DAI);
        path[1] = address(CELL);
        return path;
    }

    function _switch(bytes32 id, bool state) external onlyRole(W3BSTREAM_ROLE) {
        STATES[id].state = state;
        emit Switch(id, state, block.timestamp, msg.sender);
    }

    function _setTariff(bytes32 id, uint tariff) external {
        require(msg.sender == _M3terOwner(id), "M3tering: not owner");
        require(tariff > 0, "M3tering: tariff can't be less than 1");
        STATES[id].tariff = uint248(tariff);
    }

    function pay(bytes32 id, uint amount) external whenNotPaused {
        require(
            DAI.transferFrom(
                msg.sender,
                address(this),
                amount * DAI_BASE_UNITS
            ),
            "M3tering: payment failed"
        );
        REVENUE[_M3terOwner(id)] = amount;
        emit Revenue(id, amount, tariffOf(id), msg.sender, block.timestamp);
    }

    function claim(uint amountOutMin) external whenNotPaused {
        uint amountIn = REVENUE[msg.sender] * DAI_BASE_UNITS;
        require(amountIn > uint(0), "M3tering: no revenue to claim");
        require(
            DAI.approve(address(MIMO), amountIn),
            "M3tering: failed to approve Mimo"
        );

        MIMO.swapExactTokensForTokensSupportingFeeOnTransferTokens(
            amountIn,
            amountOutMin,
            _swapPath(),
            msg.sender,
            block.timestamp
        );

        REVENUE[msg.sender] = 0;
        emit Claim(msg.sender, amountIn, block.timestamp);
    }

    function revenueOf(
        address owner
    ) external view returns (uint, uint[] memory) {
        uint revenue = REVENUE[owner];
        return (
            revenue,
            MIMO.getAmountsOut(revenue * DAI_BASE_UNITS, _swapPath())
        );
    }

    function stateOf(bytes32 id) external view returns (bool) {
        return STATES[id].state;
    }

    function tariffOf(bytes32 id) public view returns (uint) {
        if (STATES[id].tariff < uint(1)) {
            return uint(1);
        } else {
            return STATES[id].tariff;
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
