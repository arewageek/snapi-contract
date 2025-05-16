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
            if(roles[msg.sender][_roles[i]]) revert NotAuthorized();
            _;
        }
    }

    constructor () {
        roles[msg.sender][Role.ADMIN] = true;
    }


    //////////////////////////////////////////////////////////////////// @title A title that should describe the contract/interface
    /// Common Functions
    ////////////////////////////////////////////////////////////////////

    function createAccount(Role _role, address _account) external {
        if(roles[msg.sender][Role.ADMIN] && _role == Role.ADMIN) revert NotAuthorized();
        if(creators[_account].account == address(0)) revert DuplicateEntry();

        creators[_account] = Creator({
            account: _account,
            tasksCreated: 0,
            totalAmountPaid: 0,
            isFlagged: false
        });
        roles[_account][_role] = true;
    }

    ////////////////////////////////////////////////////////////////////
    /// Creator Functions
    ////////////////////////////////////////////////////////////////////

    function createTask(
        string memory _metadata,
        uint256 _deadline
    ) external payable returns (uint256 taskId){
        tasks[tasksCount] = Task({
            creator: msg.sender,
            metadata: _metadata,
            rewardPool: msg.value,
            deadline: _deadline,
            totalPoints: 0,
            totalRaiderCount: 0,
            isActive: false
        });
    }

    ////////////////////////////////////////////////////////////////////
    /// Raiders Functions
    ////////////////////////////////////////////////////////////////////

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

    ////////////////////////////////////////////////////////////////////
    /// Public Functions
    ////////////////////////////////////////////////////////////////////

    function getRaiderInfo(uint256 _taskId, address _raider) external returns (Raider memory){
        return raiders[_taskId][_raider];
    }

    function getCreatorProfile(address _creator) external returns (Creator memory){
        return creators[_creator];
    }

    function getAverageRewardPerPoint (uint256 _taskId) external returns (uint256){
        uint256 totalReward = tasks[_taskId].rewardPool;
        uint256 totalPointsEarned = tasks[_taskId].totalPoints;

        return totalReward / totalPointsEarned;
    }

    ////////////////////////////////////////////////////////////////////
    /// Internal Functions
    ////////////////////////////////////////////////////////////////////

    function _activateTask (uint256 _taskId) external {
        Task memory task = tasks[_taskId];
        require(!task.isActive, "TaskAlreadyActive");

        if(task.totalRaiderCount >= minimumParticipantsCount){
            task.isActive = true;
        }
    }
}