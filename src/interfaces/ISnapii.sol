// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

interface ISnapii {

    // ----------- EVENTS -----------

    /// Emitted when a new task is created
    event TaskCreated(
        uint256 indexed taskId,
        address indexed creator,
        uint256 rewardPool,
        uint256 createdAt,
        uint256 deadline
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

    /// Emitted when new creator is registered
    event CreatorRegistered(address indexed creator);

    /// Emitted when a task is closed
    event TaskClosed(uint256 indexed taskId);

    // ----------- STRUCTS -----------

    /// A task posted by a creator
    struct Task {
        address creator;
        string metadata;
        uint256 rewardPool;
        uint256 createdAt;
        uint256 closedAt;
        uint256 deadline;
        uint256 totalPoints;
        uint256 totalRaiderCount;
        bool isActive;
    }

    /// Raider's engagement info
    struct Raider {
        uint256 points;
        bool rewardClaimed;
        bool isFlagged;
    }

    // ------------------ ENUMS -----------
    enum Role {
        ADMIN,
        MODERATOR,
        CREATOR
    }

    /// Creator profile info
    struct Creator {
        address account;
        uint8 tasksCreated;
        uint8 successfulTasks;
        uint256 totalAmountPaid;
        bool isFlagged;
    }

    // ----------- CORE FUNCTIONS -----------

    /// -------------------------
    /// Common Functions
    /// -------------------------

    /// Create new account
    function createAccount(Role _role, address _account) external;

    /// -------------------------
    /// Creator Functions
    /// -------------------------

    /// Create a new engagement task
    function createTask(
        string memory _taskMetadata
    ) external payable returns (uint256 taskId);

    /// -------------------------
    /// Raider Functions
    /// -------------------------
    
    

    /// -------------------------
    /// System Level Functions
    /// -------------------------

    /// -------------------------
    /// Public Level Functions
    /// -------------------------

    /// Get raider info for specific task
    function getRaiderInfo(uint256 taskId, address raider) external view returns (Raider memory);



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

    /// Close the task manually (only when not active yet)
    function closeTask(uint256 taskId) external;

    /// Refund leftover funds to creator (if participants don't cross a treshhold)
    function refund(uint256 taskId) external;

    // ----------- VIEW FUNCTIONS -----------

    /// Get basic info about a task
    function getTask(uint256 taskId) external view returns (Task memory);

    /// Calculate reward share for a raider (before claiming)
    function calculateReward(uint256 taskId, address raider) external view returns (uint256);

    /// Get total number of tasks created
    function totalTasks() external view returns (uint256);
}



// ------------------ ERRORS ------------------

error InvalidTask();
error TaskAlreadyActivated();
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

// authorization errors
error NotAuthorized();
error NotTaskCreator();
// duplicate entry errors
error DuplicateEntry();
// transaction errors
error PaymentFailed();
// task errors
error TaskNotActive();
error TaskNotEnded();

