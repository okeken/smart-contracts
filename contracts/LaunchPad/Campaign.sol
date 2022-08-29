// SPDX-License-Identifier: MIT
pragma solidity ^0.8.7;
import "@openzeppelin/contracts/utils/Strings.sol";
import "./CampaignToken.sol";

contract Campaign {
    receive() external payable {}

    constructor() {
        superAdmin = msg.sender;
    }

    address public superAdmin;
    bool private progress;
    uint256 public currentId;

    CampaignStruct[] public campaignArr;

    event donate(uint256 time, address donor, uint256 amount);

    modifier noReentrancy() {
        require(!progress, "no re-entrancy");
        progress = true;
        _;
        progress = false;
    }
    modifier onlyOwner(uint256 _currentId) {
        CampaignStruct memory campaignDetails = getCurrentCampaign(_currentId);
        require(campaignDetails.owner == msg.sender, "only owner");
        _;
    }
    modifier campaignExists(uint256 _currentId) {
        CampaignStruct memory campaignDetails = getCurrentCampaign(_currentId);
        require(campaignDetails.exists, "campaign do not exists");
        _;
    }

    modifier campaignEnded(uint256 _currentId) {
        CampaignStruct memory campaignDetails = getCurrentCampaign(_currentId);
        require(
            campaignDetails.currentStatus == Status.ended,
            "campaign not ended"
        );
        _;
    }

    modifier campaignOpened(uint256 _currentId) {
        CampaignStruct memory campaignDetails = getCurrentCampaign(_currentId);
        require(
            campaignDetails.currentStatus == Status.inProgress,
            "campaign is in progress"
        );
        _;
    }

    function createCampaign(
        uint256 _duration,
        uint256 _targetAmt,
        address _tokenAddress,
        uint256 _tokenRate
    ) public {
        CampaignOther storage campaignInfo = CampaignDetails[currentId];
        campaignInfo.details.owner = msg.sender;
        campaignInfo.details.duration = _duration;
        campaignInfo.details.targetAmt = _targetAmt;
        campaignInfo.details.token = ERC20Token(_tokenAddress);
        campaignInfo.details.tokenRate = _tokenRate;
        campaignInfo.details.exists = true;
        CampaignStruct storage camp = campaignInfo.details;
        campaignArr.push(camp);
        currentId++;
    }

    function getCurrentCampaign(uint256 _currentId)
        public
        view
        returns (CampaignStruct memory)
    {
        return CampaignDetails[_currentId].details;
    }

    struct Donors {
        address donor;
        uint256 lastTimeDonated;
        uint256 totalDonated;
    }

    struct CampaignStruct {
        address owner;
        Status currentStatus;
        uint256 duration;
        uint256 currentAmtRaised;
        uint256 targetAmt;
        uint256 timeEnded;
        ERC20Token token;
        uint256 tokenRate;
        Donors[] donors;
        bool exists;
    }

    struct CampaignOther {
        uint256 currentId;
        CampaignStruct details;
        address addressOfDonor;
        mapping(address => Donors) donorsMap;
    }

    enum Status {
        upcoming,
        inProgress,
        ended
    }

    mapping(uint256 => CampaignOther) public CampaignDetails;

    function setCampaign(Status _state, uint256 _currentId)
        public
        campaignExists(_currentId)
        onlyOwner(_currentId)
        returns (Status)
    {
        CampaignOther storage campaignInfo = CampaignDetails[_currentId];
        campaignInfo.details.currentStatus = _state;
        return campaignInfo.details.currentStatus;
    }

    function getCampaignStatus(uint256 _currentId)
        public
        view
        campaignExists(_currentId)
        returns (Status)
    {
        CampaignStruct memory campaignDetails = getCurrentCampaign(_currentId);
        return campaignDetails.currentStatus;
    }

    function ClaimToken(uint256 _currentId)
        public
        campaignExists(_currentId)
        campaignEnded(_currentId)
    {
        CampaignStruct memory campaignInfo = getCurrentCampaign(_currentId);
        Donors memory donor = CampaignDetails[_currentId].donorsMap[msg.sender];
        require(donor.totalDonated > 0, "no donation");
        campaignInfo.token.transfer(
            msg.sender,
            donor.totalDonated *
                campaignInfo.tokenRate *
                10**campaignInfo.token.decimals()
        );
    }

    function withdrawAllFunds(uint256 _currentId)
        public
        campaignEnded(_currentId)
        onlyOwner(_currentId)
        returns (bool)
    {
        CampaignOther storage campaignTemp = CampaignDetails[_currentId];
        uint256 currentAmtRaised = campaignTemp.details.currentAmtRaised;
        (bool sent, ) = (msg.sender).call{value: currentAmtRaised}("");
        require(sent, "unable to withdraw");
        currentAmtRaised = 0;
        return true;
    }

    function withdrawFunds(uint256 _currentId, uint256 _amt)
        public
        campaignEnded(_currentId)
        onlyOwner(_currentId)
        returns (bool)
    {
        CampaignOther storage campaignTemp = CampaignDetails[_currentId];
        uint256 currentAmtRaised = campaignTemp.details.currentAmtRaised;
        (bool sent, ) = (msg.sender).call{value: _amt}("");
        require(sent, "unable to withdraw");
        currentAmtRaised -= _amt;
        return true;
    }

    function depositFunds(uint256 _currentId, uint256 _amt)
        public
        payable
        campaignExists(_currentId)
        noReentrancy
        campaignOpened(_currentId)
        returns (bool)
    {
        require(_amt == msg.value, "amt less than value received");
        CampaignOther storage campaignTemp = CampaignDetails[_currentId];
        uint256 currentAmtRaised = campaignTemp.details.currentAmtRaised;
        uint256 targetAmt = campaignTemp.details.targetAmt;
        uint256 duration = campaignTemp.details.duration;
        require(
            campaignTemp.details.currentStatus == Status.inProgress,
            "campaign not opened"
        );
        bytes memory info = abi.encodePacked(
            Strings.toString(targetAmt - currentAmtRaised),
            " left to donate"
        );
        require(currentAmtRaised + _amt <= targetAmt, string(info));
        (bool sent, ) = address(this).call{value: msg.value}("");
        require(sent, Strings.toString(msg.value));
        campaignTemp.details.currentAmtRaised += _amt;
        CampaignDetails[_currentId].donorsMap[msg.sender];
        Donors storage donor = CampaignDetails[_currentId].donorsMap[
            msg.sender
        ];

        if (donor.totalDonated <= 0) {
            donor.donor = msg.sender;
        }

        if (donor.totalDonated <= 0) {
            campaignTemp.details.donors.push(donor);
        }

        donor.totalDonated += msg.value;
        if (currentAmtRaised >= targetAmt) {
            campaignTemp.details.timeEnded = block.timestamp;
            campaignTemp.details.currentStatus = Status.ended;
        }

        donor.lastTimeDonated = block.timestamp;
        if (block.timestamp > duration) {
            campaignTemp.details.currentStatus = Status.ended;
        }
        emit donate(block.timestamp, msg.sender, msg.value);
        return true;
    }

    function getBalance(uint256 _currentId) public view returns (uint256) {
        return getCurrentCampaign(_currentId).currentAmtRaised;
    }
}
