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

    event TaskEnded(
        uint256 indexed taskId,
        uint256 endedAt
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

    /// emitted when task is completed
    event TaskCompleted(uint256 indexed taskId);

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
        Completion status;
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
        SYSTEM,
        CREATOR
    }

    enum Completion {
        INACTIVE,
        ACTIVE,
        COMPLETED,
        CLOSED
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
    function registerCreator() external;

    /// -------------------------
    /// Creator Functions
    /// -------------------------

    /// Create a new engagement task
    function createTask(
        string memory _metadata,
        uint256 _deadline
    ) external payable returns (uint256 _taskId);

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
    function getRaiderInfo(uint256 _taskId, address raider) external view returns (Raider memory);



    /// Submit engagement points (from backend/oracle)
    function submitPoints(
        uint256 _taskId,
        address _raider,
        uint256 _points
    ) external;

    /// Flag a raider for low-quality engagement or rule violation
    function flagRaider(
        uint256 _taskId,
        address _raider
    ) external;

    /// Claim reward after task ends (if eligible)
    function claimReward(uint256 _taskId) external;

    /// Close the task manually (for completed task)
    function endTask(uint256 _taskId) external;

    /// Close the task manually (only when not active yet)
    function deleteTask(uint256 _taskId) external;

    // ----------- VIEW FUNCTIONS -----------

    /// Get basic info about a task
    function getTask(uint256 _taskId) external view returns (Task memory);

    /// Calculate reward share for a raider (before claiming)
    function calculateReward(uint256 _taskId, address raider) external view returns (uint256);

    /// Get total number of tasks created
    function totalTasks() external view returns (uint256);
}



// ------------------ ERRORS ------------------

error InvalidTask();
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
error TaskAlreadyActivated();

