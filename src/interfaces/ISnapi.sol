// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

interface ISnapi {

    // ----------- EVENTS -----------

    /// Emitted when a new task is created
    event TaskCreated(
        uint256 indexed taskId,
        address indexed creator,
        uint256 rewardPool,
        uint256 deadline,
        string contentLink
    );

    /// Emitted when a user submits points for a task
    event PointsSubmitted(
        uint256 indexed taskId,
        address indexed raider,
        uint256 points
    );

    /// Emitted when a raider is disqualified
    event RaiderFlagged(
        uint256 indexed taskId,
        address indexed raider,
        string reason
    );

    /// Emitted when rewards are claimed
    event RewardClaimed(
        uint256 indexed taskId,
        address indexed raider,
        uint256 amount
    );

    /// Emitted when a task is closed
    event TaskClosed(uint256 indexed taskId);

    // ----------- STRUCTS -----------

    /// A task posted by a creator
    struct Task {
        address creator;
        string contentLink;
        uint256 rewardPool;
        uint256 deadline;
        uint256 totalPoints;
        bool isActive;
    }

    /// Raider's engagement info
    struct Raider {
        uint256 points;
        bool disqualified;
        bool rewardClaimed;
    }

    // ----------- CORE FUNCTIONS -----------

    /// Create a new engagement task
    function createTask(
        string calldata contentLink,
        uint256 durationInSeconds
    ) external payable returns (uint256 taskId);

    /// Submit engagement points (from backend/oracle)
    function submitPoints(
        uint256 taskId,
        address raider,
        uint256 points
    ) external;

    /// Flag a raider for low-quality engagement or rule violation
    function flagRaider(
        uint256 taskId,
        address raider,
        string calldata reason
    ) external;

    /// Claim reward after task ends (if eligible)
    function claimReward(uint256 taskId) external;

    /// Close the task manually if past deadline
    function closeTask(uint256 taskId) external;

    /// Refund leftover funds to creator (if no participation)
    function refund(uint256 taskId) external;

    // ----------- VIEW FUNCTIONS -----------

    /// Get basic info about a task
    function getTask(uint256 taskId) external view returns (Task memory);

    /// Get raider’s performance for a task
    function getRaiderInfo(uint256 taskId, address raider) external view returns (Raider memory);

    /// Calculate reward share for a raider (before claiming)
    function calculateReward(uint256 taskId, address raider) external view returns (uint256);

    /// Get total number of tasks created
    function totalTasks() external view returns (uint256);
}



// ------------------ ERRORS ------------------

error NotTaskCreator();
error InvalidTask();
error TaskNotActive();
error TaskAlreadyClosed();
error TaskDeadlineNotReached();
error TaskDeadlinePassed();
error RewardAlreadyClaimed();
error RaiderDisqualified();
error NoPointsToClaim();
error NoParticipation();
error RewardPoolEmpty();
error InvalidETHDeposit();
error UnauthorizedSubmitter();
error ZeroPointsNotAllowed();
