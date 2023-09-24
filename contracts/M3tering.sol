// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

import "@openzeppelin/contracts/security/Pausable.sol";
import "@openzeppelin/contracts/access/AccessControl.sol";
import "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

import "./interfaces/IVersion_2.sol";
import "./IM3tering.sol";
import "./IMimo.sol";

/// @custom:security-contact info@whynotswitch.com
contract M3tering is IM3tering, Pausable, AccessControl {
    mapping(uint256 => State) public states;
    mapping(address => uint256) public revenues;

    bytes32 public constant PAUSER_ROLE = keccak256("PAUSER_ROLE");
    bytes32 public constant UPGRADER_ROLE = keccak256("UPGRADER_ROLE");
    bytes32 public constant W3BSTREAM_ROLE = keccak256("W3BSTREAM_ROLE");

    IMimo public constant MIMO = IMimo(0x147CdAe2BF7e809b9789aD0765899c06B361C5cE); // router
    IERC20 public constant DAI = IERC20(0x1CbAd85Aa66Ff3C12dc84C5881886EEB29C1bb9b); // ioDAI
    IERC20 public constant SLX = IERC20(0x147CdAe2BF7e809b9789aD0765899c06B361C5cE); // solaxy
    address public feeAddress;

    constructor() {
        if (address(MIMO) == address(0)) revert ZeroAddress();
        if (address(DAI) == address(0)) revert ZeroAddress();
        if (address(SLX) == address(0)) revert ZeroAddress();
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
        if (msg.sender != _ownerOf(tokenId)) revert ApprovalFailed();
        if (tariff < 1) revert InputIsZero();
        states[tokenId].tariff = uint248(tariff);
    }

    function pay(uint256 tokenId, uint256 amount) external whenNotPaused {
        if (!DAI.transferFrom(msg.sender, address(this), amount)) revert TransferError();
        uint256 fee = (amount * 3) / 1000;
        revenues[_ownerOf(tokenId)] = amount - fee;
        revenues[feeAddress] = fee;
        emit Revenue(tokenId, amount, tariffOf(tokenId), msg.sender, block.timestamp);
    }

    function claim(uint256 amountOutMin, uint256 deadline) external whenNotPaused {
        uint256 amountIn = revenues[msg.sender];
        if (amountIn < 1) revert InputIsZero();
        if (!DAI.approve(address(MIMO), amountIn)) revert ApprovalFailed();
        MIMO.swapExactTokensForTokensSupportingFeeOnTransferTokens(
            amountIn,
            amountOutMin,
            _swapPath(),
            msg.sender,
            deadline
        );
        revenues[msg.sender] = 0;
        emit Claim(msg.sender, amountIn, block.timestamp);
    }

    function revenueOf(address owner) external view returns (uint256[] memory) {
        return (MIMO.getAmountsOut(revenues[owner], _swapPath()));
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
        return IERC721(0x1CbAd85Aa66Ff3C12dc84C5881886EEB29C1bb9b).ownerOf(tokenId); // TODO: add M3ter address
    }

    function _swapPath() internal pure returns (address[] memory) {
        address[] memory path = new address[](2);
        path[0] = address(DAI);
        path[1] = 0x1CbAd85Aa66Ff3C12dc84C5881886EEB29C1bb9b; // TODO: added DePIN token address
        return path;
    }
}