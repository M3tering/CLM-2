// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

import "https://github.com/OpenZeppelin/openzeppelin-contracts/blob/v4.9.3/contracts/token/ERC20/IERC20.sol";
import "./interfaces/IMimo.sol";

/// @custom:security-contact info@whynotswitch.com
contract Strategy_V2 {
    error Unauthorized();

    function claim(
        uint256 revenueAmount,
        address receiver,
        uint256 outputAmount,
        uint256 deadline
    ) public {
        IERC20 SLX = IERC20(0x147CdAe2BF7e809b9789aD0765899c06B361C5cE); // solaxy
        IMimo MIMO = IMimo(0x147CdAe2BF7e809b9789aD0765899c06B361C5cE); // router
        IERC20 DAI = IERC20(0x1CbAd85Aa66Ff3C12dc84C5881886EEB29C1bb9b); // ioDAI

        address[] memory path = new address[](2);
        path[0] = address(DAI);
        path[1] = address(SLX);

        if (!DAI.approve(address(MIMO), revenueAmount)) revert Unauthorized();
        MIMO.swapExactTokensForTokensSupportingFeeOnTransferTokens(
            revenueAmount,
            outputAmount,
            path,
            receiver,
            deadline
        );
    }
}
