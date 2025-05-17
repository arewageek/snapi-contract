/// SPDX-License-Identifier: MIT

pragma solidity ^0.8.24;

import "./interfaces/ISnapii.sol";
import "lib/openzeppelin-contracts/contracts/security/ReentrancyGuard.sol";

contract Snapii is ISnapii, ReentrancyGuard{
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

    modifier onlyCreator (uint256 _taskId){
        if(msg.sender != tasks[_taskId].creator ||
            roles[msg.sender][Role.ADMIN] ||
            roles[msg.sender][Role.SYSTEM]
        ) revert NotAuthorized();
        _;
    }

    constructor () {
        roles[msg.sender][Role.ADMIN] = true;
    }


    //////////////////////////////////////////////////////////////////// 
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
    ) external payable returns (uint256 _taskId){
        tasksCount ++;

        tasks[tasksCount] = Task({
            creator: msg.sender,
            metadata: _metadata,
            rewardPool: msg.value,
            createdAt: block.timestamp,
            closedAt: 0,
            deadline: _deadline,
            totalPoints: 0,
            totalRaiderCount: 0,
            status: Completion.INACTIVE
        });

        emit TaskCreated(
            tasksCount,
            msg.sender,
            msg.value,
            block.timestamp,
            _deadline
        );

        return _taskId;
    }

    function endTask(uint256 _taskId) external onlyRole(Role.CREATOR){
        Task storage task = tasks[_taskId];

        task.closedAt = block.timestamp;
        task.status = Completion.COMPLETED;

        emit TaskEnded(_taskId, block.timestamp);
    }

    function deleteTask(uint256 _taskId) external onlyCreator(_taskId) nonReentrant() {
        Task storage task = tasks[_taskId];

        if(task.status == Completion.ACTIVE) revert TaskAlreadyActivated();
        task.closedAt = block.timestamp;

        _refundCreator(task.creator, task.rewardPool);
        
        emit TaskClosed(_taskId);
    }

    function flagRaider(
        uint256 _taskId,
        address _raider
    ) external onlyCreator(_taskId) {
        Raider storage raider = raiders[_taskId][_raider];

        if(raider.isFlagged) revert DuplicateEntry();
        raider.isFlagged = true;
    }

    ////////////////////////////////////////////////////////////////////
    /// Raiders Functions
    ////////////////////////////////////////////////////////////////////

    function claimReward(uint256 _taskId) external nonReentrant() {
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

    function submitPoints(
        uint256 _taskId,
        address _raider,
        uint256 _points
    ) external {
        raiders[_taskId][_raider].points += _points;
    }

    ////////////////////////////////////////////////////////////////////
    /// Public Functions
    ////////////////////////////////////////////////////////////////////

    function getRaiderInfo(uint256 _taskId, address _raider) external view returns (Raider memory){
        return raiders[_taskId][_raider];
    }

    function getCreatorProfile(address _creator) external view returns (Creator memory){
        return creators[_creator];
    }

    function calculateReward (uint256 _taskId, address _raider) external view returns (uint256){
        uint256 rewardPerPoint = _calculateRewardPerPoint(_taskId);
        uint256 raiderPoints = raiders[_taskId][_raider].points;
        uint256 expectedRewards = rewardPerPoint * raiderPoints;
        return expectedRewards;
    }

    function getTask(uint256 _taskId) external view returns (Task memory){
        return tasks[_taskId];
    }

    function totalTasks() external view returns (uint256){
        return tasksCount;
    }

    ////////////////////////////////////////////////////////////////////
    /// Internal Functions
    ////////////////////////////////////////////////////////////////////

    function _activateTask (uint256 _taskId) internal view {
        Task memory task = tasks[_taskId];
        if(task.status == Completion.ACTIVE) revert TaskAlreadyActivated();

        if(task.totalRaiderCount >= minimumParticipantsCount){
            task.status == Completion.ACTIVE;
        }
    }

    function _calculateRewardPerPoint (uint256 _taskId) internal view returns (uint256){
        uint256 totalReward = tasks[_taskId].rewardPool;
        uint256 totalPointsEarned = tasks[_taskId].totalPoints;

        return totalReward / totalPointsEarned;
    }

    /// @notice Refund task creator when task requirement is not met
    /// @dev Fails if deadline is not reached and task is not yet active
    /// @param _creator address
    /// @param _amount uint256
    function _refundCreator(address _creator, uint256 _amount) internal {
        (bool success,) = payable(_creator).call{value: _amount}("");
        if(!success) revert PaymentFailed();
    }
}