// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

contract CampaignManager {
    struct Campaign {
        address creator;
        uint256 poolAmount;
        bool exists;  // To track if the campaign is active
    }

    mapping(uint256 => Campaign) public campaigns;  // Mapping to store campaigns by ID
    uint256 public campaignCounter;  // Incremental counter for campaigns

    // Modifier to ensure valid campaign ID
    modifier validCampaign(uint256 campaignId) {
        require(campaigns[campaignId].exists, "Invalid campaign ID");
        _;
    }

    constructor() {
        campaignCounter = 0;
    }

    // Create a new campaign with a specified pool of ERC20 tokens
    function createCampaign(address tokenAddress, uint256 poolAmount) public {
        require(poolAmount > 0, "Pool amount must be greater than 0");

            
    
        IERC20 token = IERC20(tokenAddress);


        
        // Transfer tokens to this contract
        require(token.transferFrom(msg.sender, address(this), poolAmount), "Token transfer failed");

        campaigns[campaignCounter] = Campaign({
            creator: msg.sender,
            poolAmount: poolAmount,
            exists: true
        });

        campaignCounter++;
    }


    // Distribute rewards to users in a fixed-size batch
    function distributeRewardsBatch(
        address tokenAddress,
        uint256 campaignId,
        address[] memory userAddresses,
        uint256[] memory likes

    ) public validCampaign(campaignId) {
        require(userAddresses.length == likes.length, "Mismatched user and like arrays");
     

        Campaign storage campaign = campaigns[campaignId];
        uint256 totalLikes = 0;

        // Calculate total likes for the specified batch size
        for (uint256 i = 0; i < userAddresses.length; i++) {
            totalLikes += likes[i];
        }

        require(totalLikes > 0, "Total likes must be greater than zero");
        require(campaign.poolAmount > 0, "Insufficient pool amount");

        uint256 rewardPerLike = campaign.poolAmount / totalLikes;
        IERC20 token = IERC20(tokenAddress);

        // Distribute rewards to users in the specified batch size
        for (uint256 j = 0; j < userAddresses.length; j++) {
            uint256 reward = likes[j] * rewardPerLike;
            require(token.transfer(userAddresses[j], reward), "Reward transfer failed");
        }

        // Update the campaign pool after distribution
        campaign.poolAmount -= (rewardPerLike * totalLikes);

        // Mark the campaign as inactive if the pool is depleted
        if (campaign.poolAmount == 0) {
            campaign.exists = false;
        }
    }

    // Get details of a campaign
    function getCampaign(uint256 campaignId) public view validCampaign(campaignId) returns (address, uint256) {
        Campaign memory campaign = campaigns[campaignId];
        return (campaign.creator, campaign.poolAmount);
    }
}