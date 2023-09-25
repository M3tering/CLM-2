// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

import "./protocol-abc/Protocol.sol";
import "./interfaces/IM3tering_V2.sol";
import "./interfaces/IMimo.sol";

/// @custom:security-contact info@whynotswitch.com
contract M3tering_V2 is IM3tering_V2, Protocol {
    IERC20 public constant SLX =
        IERC20(0x147CdAe2BF7e809b9789aD0765899c06B361C5cE); // solaxy
    IMimo public constant MIMO =
        IMimo(0x147CdAe2BF7e809b9789aD0765899c06B361C5cE); // router

    constructor() {
        if (address(SLX) == address(0)) revert ZeroAddress();
        if (address(MIMO) == address(0)) revert ZeroAddress();
    }

    function claim(
        uint256 amountOutMin,
        uint256 deadline
    ) external whenNotPaused {
        uint256 amountIn = revenues[msg.sender];
        if (amountIn < 1) revert InputIsZero();
        if (!DAI.approve(address(MIMO), amountIn)) revert Unauthorized();
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

    function estimateReward(address owner) external view returns (uint256) {
        uint256[] memory estimates = MIMO.getAmountsOut(revenues[owner], _swapPath());
        return (estimates[1]);
    }

    function _swapPath() internal pure returns (address[] memory) {
        address[] memory path = new address[](2);
        path[0] = address(DAI);
        path[1] = address(SLX);
        return path;
    }
}
