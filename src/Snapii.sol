/// SPDX-License-Identifier: MIT

pragma solidity ^0.8.19;

import "./interfaces/ISnapii.sol";

contract Snapii is ISnapii{
    uint256 public minimumParticipantsCount = 100;

    uint256 tasksCount = 1;

    mapping (address => Creator) public creators;
    mapping (uint256 => mapping (address => Raider)) public raiders; /// mapping (task => raider => profile)
    mapping (address => mapping (Role => bool)) public roles; /// allow creation of multiple roles per user
    mapping (uint256 => Task) public tasks;
    mapping (address => bool) public flaggedAccounts;


    ////////////////////////////////////////////////////////////////////
    /// Modifiers
    ////////////////////////////////////////////////////////////////////

    modifier onlyRole (Role _role) {
        if (roles[msg.sender][_role]) revert NotAuthorized();
        _;
    }

    modifier onlyRoles (Role[] memory _roles) {
        for(uint8 i = 0; i < _roles.length; i ++){
            if(! roles[msg.sender][_roles[i]]) revert NotAuthorized();
            _;
        }
    }

    constructor () {
        roles[msg.sender][Role.ADMIN] = true;
    }


    //////////////////////////////////////////////////////////////////// @title A title that should describe the contract/interface
    /// Common Functions
    ////////////////////////////////////////////////////////////////////


    ////////////////////////////////////////////////////////////////////
    /// Creator Functions
    ////////////////////////////////////////////////////////////////////

    /// @notice Register a new creator account
    /// @dev fails if creator already exists
    function registerCreator() external {
        if(creators[msg.sender].account != address(0)) revert DuplicateEntry();

        creators[msg.sender] = Creator({
            account: msg.sender,
            tasksCreated: 0,
            successfulTasks: 0,
            totalAmountPaid: 0,
            isFlagged: false
        });
        roles[msg.sender][Role.CREATOR] = true;

        emit CreatorRegistered(msg.sender);
    }

    function createTask(
        string memory _metadata,
        uint256 _deadline
    ) external payable returns (uint256 taskId){
        tasks[tasksCount] = Task({
            creator: msg.sender,
            metadata: _metadata,
            rewardPool: msg.value,
            createdAt: block.timestamp,
            closedAt: 0,
            deadline: _deadline,
            totalPoints: 0,
            totalRaiderCount: 0,
            isActive: false
        });

        tasksCount ++;

        emit TaskCreated(
            tasksCount,
            msg.sender,
            msg.value,
            block.timestamp,
            _deadline
        );
    }

    function endTask(uint256 _taskId) external onlyRole(Role.CREATOR){
        Task storage task = tasks[_taskId];

        task.closedAt = block.timestamp;
        task.status = Completion.COMPLETED;

        emit TaskEnded(_taskId, block.timestamp);
    }

    function deleteTask(uint256 _taskId) external onlyRoles([Role.CREATOR, Role.SYSTEM, Role.ADMIN]) {
        Task storage task = tasks[_taskId];

        if(task.status == Completion.ACTIVE) revert TaskAlreadyActivated();
        task.closedAt = block.timestamp;
        
        emit TaskClosed(_taskId);
    }

    ////////////////////////////////////////////////////////////////////
    /// Raiders Functions
    ////////////////////////////////////////////////////////////////////

    function claimRewards (uint256 _taskId) external {
        Task memory task = tasks[_taskId];
        
        if(raiders[_taskId][msg.sender].isFlagged) revert RaiderDisqualified();
        if(block.timestamp < task.deadline) revert TaskNotEnded();
        if(task.status != Completion.COMPLETED) revert TaskNotActive();
        
        uint256 rewardPerPoint = _calculateRewardPerPoint(_taskId);
        uint256 ponitsEarned = raiders[_taskId][msg.sender].points;
        uint256 amount = ponitsEarned * rewardPerPoint;

        if(ponitsEarned <= 0) revert NoPointsToClaim();
        (bool success,) = payable(msg.sender).call{value: amount}("");
        if(!success) revert PaymentFailed();

        emit RewardClaimed(_taskId, msg.sender, amount);
    }

    function completeTask (uint256 _taskId, uint256 _pointsEarned) external onlyRole(Role.SYSTEM) {
        Raider storage taskRaider = raiders[_taskId][msg.sender];
        
        if(taskRaider.isFlagged) revert RaiderDisqualified();
        taskRaider.points +=  _pointsEarned;
    }

    ////////////////////////////////////////////////////////////////////
    /// System Level
    ////////////////////////////////////////////////////////////////////

    /// @notice Allow system admin update minimum raiders required to activate a task
    /// @param _count uint256
    function updateMinimumTaskParticipants (uint256 _count) external onlyRole(Role.ADMIN){
        minimumParticipantsCount = _count;
    }

    function flagAccount (address _account) external onlyRole(Role.ADMIN){
        if(roles[_account][Role.CREATOR]){
            creators[_account].isFlagged = true;
            roles[_account][Role.CREATOR] = false;
        }
        else{
            flaggedAccounts[_account] = true;
        }
    }

    function reactivateAccount (address _account) external onlyRole(Role.ADMIN){
        if(creators[_account].isFlagged){
            creators[_account].isFlagged = false;
        }
        else{
            flaggedAccounts[_account] = false;
        }
    }

    /// @notice Refund task creator when task requirement is not met
    /// @dev Fails if deadline is not reached and task is not yet active
    /// @param _taskId uint256
    function refundCreator(uint256 _taskId) external {
        Task memory task = tasks[_taskId];

        if(task.deadline > block.timestamp) revert TaskNotEnded();
        if(task.status != Completion.CLOSED) revert TaskNotEnded();

        (bool success,) = payable(task.creator).call{value: task.rewardPool}("");
        if(!success) revert PaymentFailed();
    }

    ////////////////////////////////////////////////////////////////////
    /// Public Functions
    ////////////////////////////////////////////////////////////////////

    function getRaiderInfo(uint256 _taskId, address _raider) external view returns (Raider memory){
        return raiders[_taskId][_raider];
    }

    function getCreatorProfile(address _creator) external returns (Creator memory){
        return creators[_creator];
    }

    function getAverageRewardPerPoint (uint256 _taskId) external returns (uint256){
        uint rewardPerPoint = _calculateRewardPerPoint(_taskId);
    }

    ////////////////////////////////////////////////////////////////////
    /// Internal Functions
    ////////////////////////////////////////////////////////////////////

    function _activateTask (uint256 _taskId) internal {
        Task memory task = tasks[_taskId];
        if(task.status == Completion.ACTIVE) revert TaskAlreadyActivated();

        if(task.totalRaiderCount >= minimumParticipantsCount){
            task.status == Completion.ACTIVE;
        }
    }

    function _calculateRewardPerPoint (uint256 _taskId) internal returns (uint256){
        uint256 totalReward = tasks[_taskId].rewardPool;
        uint256 totalPointsEarned = tasks[_taskId].totalPoints;

        return totalReward / totalPointsEarned;
    }
}