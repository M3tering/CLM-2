// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

import "@openzeppelin/contracts-upgradeable/security/ReentrancyGuardUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/security/PausableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/access/AccessControlUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/UUPSUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC721/IERC721Upgradeable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC721/utils/ERC721HolderUpgradeable.sol";

import "./IM3tering.sol";

/**
 * --- Max Credit ---
 * This is the maximum amount of credit that can be acceptable
 * for a given asset. This is calculated based on the value of the asset
 * and the internal rate of return (IRR) of the underling asset.
 *
 * --- Health ---
 * This is a weekly metric tracking the IRR of a collatrised loan
 * position. It is calculated based on the value of the asset, it's IRR
 * and the open loan position
 */

contract Depot is
    Initializable,
    PausableUpgradeable,
    AccessControlUpgradeable,
    ReentrancyGuardUpgradeable,
    ERC721HolderUpgradeable,
    UUPSUpgradeable
{
    bytes32 public constant MANAGER_ROLE = keccak256("MANAGER_ROLE");
    bytes32 public constant PAUSER_ROLE = keccak256("PAUSER_ROLE");
    bytes32 public constant UPGRADER_ROLE = keccak256("UPGRADER_ROLE");
    bytes32 public constant W3BSTREAM_ROLE = keccak256("W3BSTREAM_ROLE");

    IM3tering Protocol;
    IERC721Upgradeable M3terRegistry;

    /**
     * Storage block
     *
     * Loan position:: [collateral id, IRR, health score, max loan, active, requested loan, loan repayment]
     */

    modifier notZeroAddress(address protocol, address registry) {
        require(protocol != address(0), "Depot: protocol can't be address(0)");
        require(registry != address(0), "Depot: registry can't be address(0)");
        _;
    }

    /// @custom:oz-upgrades-unsafe-allow constructor
    constructor() {
        _disableInitializers();
    }

    function initialize(
        address protocol,
        address registry
    ) public notZeroAddress(protocol, registry) initializer {
        __Pausable_init();
        __AccessControl_init();
        __UUPSUpgradeable_init();

        _grantRole(DEFAULT_ADMIN_ROLE, msg.sender);
        _grantRole(PAUSER_ROLE, msg.sender);
        _grantRole(UPGRADER_ROLE, msg.sender);
        _grantRole(MANAGER_ROLE, msg.sender);
        _grantRole(W3BSTREAM_ROLE, msg.sender);

        Protocol = IM3tering(protocol);
        M3terRegistry = IERC721Upgradeable(registry);
    }

    function _setAddresses(
        address protocol,
        address registry
    )
        external
        notZeroAddress(protocol, registry)
        onlyRole(MANAGER_ROLE)
        whenNotPaused
    {
        Protocol = IM3tering(protocol);
        M3terRegistry = IERC721Upgradeable(registry);
    }

    function requestLoan(uint256 id, uint256 amount) external payable {
        /**
         * triggers an evaluation of the IRR of an asset denoted by id
         * evaluation is returned by W3bstream after catching request event
         * aproval status can be set to approved or not based
         * 
         */
    }

    function evaluateApproval(uint256 id, uint256 irr) external onlyRole(W3BSTREAM_ROLE) {}

    function collateralizeM3ter(
        uint256 id,
        uint256 amount
    ) external nonReentrant whenNotPaused {
        /** 
         * require asset meets collateralization requirement
         * the evaluation of the IRR
        */
        M3terRegistry.safeTransferFrom(msg.sender, address(this), id);
        (bool success, ) = payable(msg.sender).call{value: amount}("");
        require(success, "Depot: loan transfer failed");

        //emit Collateralized(id, owner);
    }

    function redeem(uint256 id) external payable whenNotPaused {
        //require(msg.value >= loan amount + interest);
        M3terRegistry.safeTransferFrom(address(this), msg.sender, id);
    }

    function liqidate() external whenNotPaused {}

    function HarvestYield() external whenNotPaused {
        Protocol.claim();
    }

    function deposit() external payable whenNotPaused {
        //set user share of pool
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
