// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/security/Pausable.sol";
import "@openzeppelin/contracts/access/AccessControl.sol";
import "@openzeppelin/contracts/token/ERC721/IERC721.sol";

import "./DEX/DAI2SLX.sol";
import "./IM3tering.sol";

/// @custom:security-contact info@whynotswitch.com
contract M3tering_V2 is IM3tering, Pausable, AccessControl {
    mapping(uint256 => State) public states;
    mapping(address => uint256) public revenues;

    IERC721 public constant M3ter = IERC721(0x1CbAd85Aa66Ff3C12dc84C5881886EEB29C1bb9b); // TODO: add M3ter address

    bytes32 public constant PAUSER_ROLE = keccak256("PAUSER_ROLE");
    bytes32 public constant UPGRADER_ROLE = keccak256("UPGRADER_ROLE");
    bytes32 public constant W3BSTREAM_ROLE = keccak256("W3BSTREAM_ROLE");
    address public feeAddress;

    constructor() {
        if (address(DAI2SLX.MIMO) == address(0)) revert ZeroAddress();
        if (address(DAI2SLX.DAI) == address(0)) revert ZeroAddress();
        if (address(DAI2SLX.SLX) == address(0)) revert ZeroAddress();
        if (address(M3ter) == address(0)) revert ZeroAddress();

        _grantRole(DEFAULT_ADMIN_ROLE, msg.sender);
        _grantRole(W3BSTREAM_ROLE, msg.sender);
        _grantRole(PAUSER_ROLE, msg.sender);
        feeAddress = msg.sender;
    }

    function _switch(uint256 tokenId, bool state) external onlyRole(W3BSTREAM_ROLE) {
        states[tokenId].state = state;
        emit Switch(tokenId, state, block.timestamp, msg.sender);
    }

    function _setFeeAddress(address otherAddress) external onlyRole(DEFAULT_ADMIN_ROLE) {
        feeAddress = otherAddress;
    }

    function _setTariff(uint256 tokenId, uint256 tariff) external {
        if (msg.sender != _ownerOf(tokenId)) revert Unauthorized();
        if (tariff < 1) revert InputIsZero();
        states[tokenId].tariff = uint248(tariff);
    }

    function pay(uint256 tokenId, uint256 amount) external whenNotPaused {
        uint256 fee = (amount * 3) / 1000;
        revenues[feeAddress] += fee;
        revenues[_ownerOf(tokenId)] += amount - fee;

        DAI2SLX.depositDAI(amount);
        emit Revenue(tokenId, amount, tariffOf(tokenId), msg.sender, block.timestamp);
    }

    function claim(uint256 amountOutMin, uint256 deadline) external whenNotPaused {
        revenues[msg.sender] = 0;
        DAI2SLX.claimSLX(revenues[msg.sender], amountOutMin, deadline);
    }

    function stateOf(uint256 tokenId) external view returns (bool) {
        return states[tokenId].state;
    }

    function pause() public onlyRole(PAUSER_ROLE) {
        _pause();
    }

    function unpause() public onlyRole(PAUSER_ROLE) {
        _unpause();
    }

    function tariffOf(uint256 tokenId) public view returns (uint256) {
        uint256 tariff = states[tokenId].tariff;
        return tariff > 0 ? tariff : 1;
    }

    function _ownerOf(uint256 tokenId) internal view returns (address) {
        return M3ter.ownerOf(tokenId);
    }
}
