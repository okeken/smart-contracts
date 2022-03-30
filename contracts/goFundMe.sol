//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.0;
import "@openzeppelin/contracts/access/Ownable.sol";
import "@chainlink/contracts/src/v0.8/interfaces/AggregatorV3Interface.sol";
import "./utils/reEntrancy.sol";

contract GoFundMe is Ownable, ReEntrancy {
    AggregatorV3Interface internal priceFeed;
    uint256 public immutable minimumCampaignFund;
    uint256 public immutable maxCampaignFund;
    uint256 public constant MINUMUM_CAMPAIGN_PERIOD = 1 days;
    uint256 public constant MAXIMUM_CAMPAIGN_PERIOD = 30 days;
    uint256 public projectId;

    constructor(uint256 _minimumFund, uint256 _maxFund) {
        priceFeed = AggregatorV3Interface(
            0x8A753747A1Fa494EC906cE90E9f37563A8AF630e
        );
        minimumCampaignFund = bool(_minimumFund > 0) ? _minimumFund : 50;
        maxCampaignFund = bool(_maxFund > 0) ? _maxFund : 1000;
    }

    function getLatestPrice() public view returns (int256) {
        (
            ,
            /*uint80 roundID*/
            int256 price, /*uint startedAt*/ /*uint timeStamp*/ /*uint80 answeredInRound*/
            ,
            ,

        ) = priceFeed.latestRoundData();
        return price / 10**8;
    }

    enum Status {
        NotStarted,
        InProgress,
        Completed,
        Cancelled
    }

    struct Project {
        uint256 id;
        string name;
        uint256 daysToRun;
        Status status;
        uint256 balance;
        uint256 goal;
        UserDeposit[] userDeposits;
        uint256 projectStarts;
    }
    struct UserDeposit {
        address user;
        uint256 amount;
    }

    Project[] projectArray;
    UserDeposit[] public userDepositsArray;

    //Events
    event FundsDeposited(bool success, address sender, uint256 amount);
    event FundsWithdrawn(bool success, uint256 amount);
    event ClaimUserFund(bool success, address sender, uint256 amount);

    //Mappings
    mapping(uint256 => Project) public projects;
    mapping(address => uint256) public userDeposits;

    // Modifiers
    modifier fundAmtGreaterThanZero() {
        require(_fundAmt() > 0, "amount must be greater than 0");
        _;
    }

    modifier fundAmtLessThanMin() {
        require(_fundAmt() > minimumCampaignFund, "amount less than minimum");
        _;
    }

    modifier fundAmtGreaterThanMax() {
        require(_fundAmt() < maxCampaignFund, "amount greate than maximum");
        _;
    }

    modifier projectExpired(uint256 _id) {
        require(
            block.timestamp >
                projects[_id].projectStarts + projects[_id].daysToRun * 86400,
            "project expired"
        );
        _;
    }

    modifier projectCompleted(uint256 _id) {
        require(
            projects[_id].status == Status.Completed,
            "project not completed"
        );
        _;
    }

    modifier projectInProgress(uint256 _id) {
        require(
            projects[_id].status == Status.InProgress,
            "project not in progress"
        );
        _;
    }

    modifier projectAvailable(uint256 _id) {
        require(projects[_id].id == _id, "project not available");
        _;
    }

    modifier projectCancelled(uint256 _id) {
        require(
            projects[_id].status == Status.Cancelled,
            "project not cancelled"
        );
        _;
    }

    modifier projectNotStarted(uint256 _id) {
        require(
            projects[_id].status == Status.NotStarted,
            "project not started"
        );
        _;
    }

    modifier BalanceIsZero(uint256 _id) {
        require(_userDeposit(_id).amount != 0, "no funds to withdraw");
        _;
    }

    modifier withdrawalLimit(uint256 _id) {
        require(
            _userDeposit(_id).amount > msg.value,
            "cant withdraw more than you have"
        );
        _;
    }

    function _fundAmt() internal view returns (uint256) {
        return uint256(getLatestPrice()) * (uint256(msg.value) / 10**18);
    }

    function createProject(
        string memory _name,
        uint256 _days,
        uint256 _goal
    ) public onlyOwner {
        Project storage newProject = projects[projectId];
        newProject.id = projectId;
        newProject.name = _name;
        newProject.daysToRun = _days;
        newProject.goal = _goal;
        newProject.projectStarts = block.timestamp;
        projects[projectId] = newProject;
        projectArray.push(newProject);
        projectId++;
    }

    // starts the project

    function startProject(uint256 _id)
        public
        projectAvailable(_id)
        projectNotStarted(_id)
        projectExpired(_id)
    {
        projects[_id].projectStarts = block.timestamp;
        projects[_id].status = Status.InProgress;
    }

    function fundProject(uint256 _id)
        public
        payable
        projectAvailable(_id)
        projectExpired(_id)
        projectInProgress(_id)
        fundAmtGreaterThanZero
        fundAmtLessThanMin
        fundAmtGreaterThanMax
    {
        UserDeposit memory userDeposited = UserDeposit(msg.sender, _fundAmt());

        for (uint256 i = 0; i < userDepositsArray.length; i++) {
            if (userDepositsArray[i].user == msg.sender) {
                userDepositsArray[i].amount += _fundAmt();
            } else {
                userDepositsArray.push(userDeposited);
            }
        }

        for (uint256 i = 0; i < projects[_id].userDeposits.length; i++) {
            if (projects[_id].userDeposits[i].user == (msg.sender)) {
                projects[_id].userDeposits[i].amount += _fundAmt();
            } else {
                projects[_id].userDeposits.push(userDeposited);
            }
        }
        projects[_id].balance += _fundAmt();
        if (projects[_id].balance >= projects[_id].goal) {
            projects[_id].status = Status.Completed;
        }
        //   projects[_id] = project;
        emit FundsDeposited(true, msg.sender, _fundAmt());
    }

    // get all projects ids
    function getAllProjectsId() public view returns (uint256[] memory) {
        uint256[] memory projectIds = new uint256[](projectArray.length);
        for (uint256 i = 0; i < projectArray.length; i++) {
            projectIds[i] = projectArray[i].id;
        }
        return projectIds;
    }

    // get all projects details
    function getAllProjects() public view returns (Project[] memory) {
        return projectArray;
    }

    function getProjectBal(uint256 _id) public view returns (uint256) {
        return projects[_id].balance;
    }

    function getProjectGoal(uint256 _id) public view returns (uint256) {
        return projects[_id].goal;
    }

    function getProjectStatus(uint256 _id) public view returns (Status) {
        return projects[_id].status;
    }

    function closeProject(uint256 _id)
        public
        projectAvailable(_id)
        projectInProgress(_id)
    {
        if (projects[_id].balance >= projects[_id].goal) {
            projects[_id].status = Status.Completed;
        } else {
            projects[_id].status = Status.Cancelled;
        }
    }

    function withdrawProjectFunds(uint256 _id)
        public
        onlyOwner
        projectAvailable(_id)
        projectCompleted(_id)
    {
        uint256 amount = projects[_id].balance;
        projects[_id].balance = 0;
        (bool sent, ) = msg.sender.call{value: amount}("");
        if (sent) {
            emit FundsWithdrawn(true, amount);
        }
    }

    modifier userDepositInList(uint256 id) {
        for (uint256 i = 0; i < userDepositsArray.length; i++) {
            require(
                userDepositsArray[i].user == msg.sender,
                "user deposit doesnt exist"
            );
        }
        _;
    }

    function _userDeposit(uint256 _id)
        public
        view
        userDepositInList(_id)
        returns (UserDeposit memory data)
    {
        for (uint256 i = 0; i < projects[_id].userDeposits.length; i++) {
            if (projects[_id].userDeposits[i].user == msg.sender) {
                return projects[_id].userDeposits[i];
            }
        }
    }

    function claimFunds(uint256 _id)
        public
        payable
        projectAvailable(_id)
        projectCancelled(_id)
        userDepositInList(_id)
    {
        uint256 amount = projects[_id].balance;
        Project storage project = projects[_id];

        for (uint256 i = 0; i < project.userDeposits.length; i++) {
            if (project.userDeposits[i].user == msg.sender) {
                project.userDeposits[i].amount -= msg.value;
            }
        }
        projects[_id].balance -= msg.value;
        //
        (bool sent, ) = msg.sender.call{value: amount}("");
        if (sent) {
            emit ClaimUserFund(sent, msg.sender, msg.value);
        }
    }
}
