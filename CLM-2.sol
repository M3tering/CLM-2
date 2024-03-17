// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

import "https://github.com/OpenZeppelin/openzeppelin-contracts/blob/v4.9.3/contracts/token/ERC20/IERC20.sol";
import "./interfaces/ICLM.sol";

/// @custom:security-contact info@whynotswitch.com
contract CLM2 is ICLM {
    error Unauthorized();
    error TransferError();

    IERC20 public constant SLX =
        IERC20(0x147CdAe2BF7e809b9789aD0765899c06B361C5cE); // ToDo: solaxy
    IERC20 public constant WXDAI =
        IERC20(0xe91d153e0b41518a2ce8dd3d7944fa863463a97d);

    function claim(bytes calldata data) public {
        (uint256 amountOutMin, address receiver, uint256 deadline) = abi.decode(
            data,
            (uint256, address, uint256)
        );

        // ToDo: finish swap code
    }
}
