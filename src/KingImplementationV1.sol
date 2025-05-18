// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";

/**
 * @title KingImplementationV1
 * @dev Implementation of the King game where users can claim the throne by sending more ETH than the current prize.
 * The previous king receives the funds sent by the new king.
 */
contract KingImplementationV1 is Initializable, OwnableUpgradeable {
    /// @dev Address of the current king
    address public king;

    /// @dev Current prize amount in wei
    uint256 public currentPrize;

    /// @dev Mapping of addresses to their pending withdrawal amounts
    mapping(address => uint256) public pendingWithdrawals;

    /// @dev Event emitted when the throne is claimed
    event ThroneClaimed(address indexed previousKing, address indexed newKing, uint256 amount);

    /// @dev Event emitted when funds are withdrawn
    event FundsWithdrawn(address indexed recipient, uint256 amount);

    /**
     * @dev Disables initializers to prevent direct initialization of implementation
     * @custom:oz-upgrades-unsafe-allow constructor
     */
    constructor() {
        _disableInitializers();
    }

    /**
     * @dev Initializes the contract, setting the deployer as the initial king and owner
     */
    function initialize() public initializer {
        __Ownable_init(msg.sender);
        king = msg.sender;
        currentPrize = 0;
    }

    /**
     * @dev Allows a user to claim the throne by sending more ETH than the current prize
     * @notice The previous king receives the funds sent by the new king
     */
    function claimThrone() external payable virtual {
        require(msg.value > 0, "Must send some ETH");
        require(msg.value > currentPrize, "Need to pay more than current prize");

        // Add funds for the previous king
        pendingWithdrawals[king] += msg.value;

        // Update king and prize
        address previousKing = king;
        king = msg.sender;
        currentPrize = msg.value;

        emit ThroneClaimed(previousKing, msg.sender, msg.value);
    }

    /**
     * @dev Allows a user to withdraw their pending funds
     * @notice The funds are sent to the caller's address
     */
    function withdraw() external {
        uint256 amount = pendingWithdrawals[msg.sender];
        require(amount > 0, "No funds to withdraw");

        pendingWithdrawals[msg.sender] = 0;
        (bool success,) = msg.sender.call{value: amount}("");
        require(success, "Failed to send funds");

        emit FundsWithdrawn(msg.sender, amount);
    }
}
