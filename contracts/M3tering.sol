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
    mapping(uint256 => State) STATES;
    mapping(address => uint256) REVENUE;

    bytes32 public constant PAUSER_ROLE = keccak256("PAUSER_ROLE");
    bytes32 public constant UPGRADER_ROLE = keccak256("UPGRADER_ROLE");
    bytes32 public constant W3BSTREAM_ROLE = keccak256("W3BSTREAM_ROLE");

    ERC721 public constant M3terRegistry = ERC721(address(0)); // TODO: set address
    ERC20 public constant DAI =
        ERC20(0x1CbAd85Aa66Ff3C12dc84C5881886EEB29C1bb9b); // ioDAI
    IMimo public constant MIMO =
        IMimo(0x147CdAe2BF7e809b9789aD0765899c06B361C5cE); // router
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

    function _M3terOwner(uint256 tokenId) internal view returns (address) {
        return M3terRegistry.ownerOf(uint256(tokenId));
    }

    function _swapPath() internal pure returns (address[] memory) {
        address[] memory path = new address[](2);
        path[0] = address(DAI);
        path[1] = address(CELL);
        return path;
    }

    function _switch(
        uint256 tokenId,
        bool state
    ) external onlyRole(W3BSTREAM_ROLE) {
        STATES[tokenId].state = state;
        emit Switch(tokenId, state, block.timestamp, msg.sender);
    }

    function _setTariff(uint256 tokenId, uint256 tariff) external {
        require(msg.sender == _M3terOwner(tokenId), "M3tering: not owner");
        require(tariff > 0, "M3tering: tariff can't be less than 1");
        STATES[tokenId].tariff = uint248(tariff);
    }

    function pay(uint256 tokenId, uint256 amount) external whenNotPaused {
        require(
            DAI.transferFrom(msg.sender, address(this), amount),
            "M3tering: payment failed"
        );
        REVENUE[_M3terOwner(tokenId)] = amount;
        emit Revenue(
            tokenId,
            amount,
            tariffOf(tokenId),
            msg.sender,
            block.timestamp
        );
    }

    function claim(
        uint256 amountOutMin,
        uint256 deadline
    ) external whenNotPaused {
        uint256 amountIn = REVENUE[msg.sender];
        require(amountIn > 0, "M3tering: no revenue to claim");
        require(
            DAI.approve(address(MIMO), amountIn),
            "M3tering: failed to approve Mimo"
        );

        MIMO.swapExactTokensForTokensSupportingFeeOnTransferTokens(
            amountIn,
            amountOutMin,
            _swapPath(),
            msg.sender,
            deadline
        );

        REVENUE[msg.sender] = 0;
        emit Claim(msg.sender, amountIn, block.timestamp);
    }

    function revenueOf(address owner) external view returns (uint256[] memory) {
        return (MIMO.getAmountsOut(REVENUE[owner], _swapPath()));
    }

    function stateOf(uint256 tokenId) external view returns (bool) {
        return STATES[tokenId].state;
    }

    function tariffOf(uint256 tokenId) public view returns (uint256) {
        if (STATES[tokenId].tariff < 1) {
            return 1;
        } else {
            return STATES[tokenId].tariff;
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
