// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

import "https://github.com/OpenZeppelin/openzeppelin-contracts/blob/v4.9.3/contracts/token/ERC20/IERC20.sol";
import "./interfaces/IStrategy.sol";
import "./interfaces/IMimo.sol";

/// @custom:security-contact info@whynotswitch.com
contract Strategy2 is IStrategy {
    error Unauthorized();
    error TransferError();

    IERC20 public constant SLX =
        IERC20(0x147CdAe2BF7e809b9789aD0765899c06B361C5cE); // solaxy
    IMimo public constant MIMO =
        IMimo(0x147CdAe2BF7e809b9789aD0765899c06B361C5cE); // router
    IERC20 public constant DAI =
        IERC20(0x1CbAd85Aa66Ff3C12dc84C5881886EEB29C1bb9b); // ioDAI

    function claim(uint256 amountIn, bytes calldata data) public {
        (uint256 amountOutMin, address receiver, uint256 deadline) = abi.decode(
            data,
            (uint256, address, uint256)
        );

        if (!DAI.transferFrom(msg.sender, address(this), amountIn))
            revert TransferError();
        if (!DAI.approve(address(MIMO), amountIn)) revert Unauthorized();

        address[] memory path = new address[](2);
        path[0] = address(DAI);
        path[1] = address(SLX);

        MIMO.swapExactTokensForTokensSupportingFeeOnTransferTokens(
            amountIn,
            amountOutMin,
            path,
            receiver,
            deadline
        );
    }
}
