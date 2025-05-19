// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import "./KingImplementationV1.sol";

/**
 * @title KingImplementationV2
 * @dev Extension of KingImplementationV1 that adds a fee mechanism and claim tracking.
 * The owner receives a fee from each throne claim, and the system tracks total claims and claims per user.
 * @custom:oz-upgrades-from KingImplementationV1
 */
contract KingImplementationV2 is KingImplementationV1 {
    /// @dev Total number of throne claims
    uint256 public totalClaims;

    /// @dev Mapping of addresses to their claim counts
    mapping(address => uint256) public claimCount;

    /// @dev Fee percentage in basis points (1 basis point = 0.01%)
    uint256 public feePercentage;

    /// @dev Event emitted when the fee percentage is updated
    event FeePercentageUpdated(uint256 oldFee, uint256 newFee);

    /**
     * @dev Disables initializers to prevent direct initialization of implementation
     * @custom:oz-upgrades-unsafe-allow constructor
     */
    constructor() {
        _disableInitializers();
    }

    /**
     * @dev Initializes the V2 specific variables
     * @notice This function is called only once during the upgrade from V1 to V2
     */
    function initializeV2() public reinitializer(2) {
        // Initialize V2 specific variables
        feePercentage = 500; // 5% fee (500/10000)
        totalClaims = 0;
    }

    /**
     * @dev Updates the fee percentage
     * @param newFeePercentage New fee percentage in basis points
     * @notice Only the owner can call this function
     */
    function setFeePercentage(uint256 newFeePercentage) external onlyOwner {
        require(newFeePercentage <= 1000, "Fee cannot exceed 10%");
        uint256 oldFee = feePercentage;
        feePercentage = newFeePercentage;
        emit FeePercentageUpdated(oldFee, newFeePercentage);
    }

    /**
     * @dev Allows a user to claim the throne by sending more ETH than the current prize plus fee
     * @notice The owner receives a fee, and the previous king receives the remaining funds
     */
    function claimThrone() external payable override {
        require(msg.value > 0, "Must send some ETH");

        // Calculate minimum new prize with fee
        uint256 minNewPrize = currentPrize + (currentPrize * feePercentage) / 10000;
        require(msg.value > minNewPrize, "Need to pay more than current prize plus fee");

        // Calculate and distribute fee
        uint256 fee = (msg.value * feePercentage) / 10000;
        pendingWithdrawals[owner()] += fee;
        pendingWithdrawals[king] += msg.value - fee;

        // Update throne state and tracking variables
        address previousKing = king;
        king = msg.sender;
        currentPrize = msg.value;
        totalClaims++;
        claimCount[msg.sender]++;

        emit ThroneClaimed(previousKing, msg.sender, msg.value);
    }
}
