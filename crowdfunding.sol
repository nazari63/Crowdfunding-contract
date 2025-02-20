// Minor update: Comment added for GitHub contributions
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

contract Crowdfunding is Ownable {
    IERC20 public rewardToken;
    uint256 public targetAmount;
    uint256 public currentAmount;
    uint256 public deadline;

    mapping(address => uint256) public contributions;
    
    event ContributionReceived(address indexed contributor, uint256 amount);
    event FundsWithdrawn(address indexed projectOwner, uint256 amount);

    constructor(IERC20 _rewardToken, uint256 _targetAmount, uint256 _duration) {
        rewardToken = _rewardToken;
        targetAmount = _targetAmount;
        deadline = block.timestamp + _duration;
    }

    // Contribute to the crowdfunding project
    function contribute(uint256 amount) external {
        require(block.timestamp < deadline, "Crowdfunding period has ended");
        require(amount > 0, "Contribution must be greater than 0");
        
        contributions[msg.sender] += amount;
        currentAmount += amount;

        require(rewardToken.transferFrom(msg.sender, address(this), amount), "Token transfer failed");

        emit ContributionReceived(msg.sender, amount);
    }

    // Withdraw funds after goal is met
    function withdrawFunds() external onlyOwner {
        require(block.timestamp >= deadline, "Crowdfunding period has not ended yet");
        require(currentAmount >= targetAmount, "Target amount not reached");
        
        uint256 amountToWithdraw = currentAmount;
        currentAmount = 0;

        require(rewardToken.transfer(owner(), amountToWithdraw), "Withdrawal failed");
        emit FundsWithdrawn(owner(), amountToWithdraw);
    }

    // Refund contributors if target is not met
    function refund() external {
        require(block.timestamp >= deadline, "Crowdfunding period has not ended yet");
        require(currentAmount < targetAmount, "Target amount reached, no refund needed");

        uint256 contributionAmount = contributions[msg.sender];
        require(contributionAmount > 0, "No contributions to refund");

        contributions[msg.sender] = 0;

        require(rewardToken.transfer(msg.sender, contributionAmount), "Refund failed");
    }

    // Get the current status of the crowdfunding project
    function getStatus() external view returns (uint256, uint256, uint256) {
        return (currentAmount, targetAmount, deadline);
    }
}
