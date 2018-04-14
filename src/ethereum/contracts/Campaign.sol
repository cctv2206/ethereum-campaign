pragma solidity ^0.4.17;

contract CampaignFactory {
  address[] public deployedCampaigns;

  function createCampaign(uint minimum) public {
    address newCampaign = new Campaign(minimum, msg.sender);
    deployedCampaigns.push(newCampaign);
  }

  function getDeployedCampaigns() public view returns (address[]) {
    return deployedCampaigns;
  }
}

contract Campaign {
  struct Request {
    string description;
    uint value;
    address recipient;
    bool complete;
    uint approvalCount;
    mapping(address => bool) approvals;
  }

  address public manager;
  uint public minContribution;
  mapping(address => bool) public approvers;
  uint public approversCount;
  Request[] public requests;

  modifier managerOnly() {
    require(msg.sender == manager);
    _;
  }

  function Campaign(uint minimum, address creator) public {
    manager = creator;
    minContribution = minimum;
  }

  function contribute() public payable {
    // todo: re contribute??
    require(msg.value >= minContribution);
    approvers[msg.sender] = true;
    approversCount++;
  }

  function createRequest(string description, uint value, address recipient)
    public managerOnly
  {
    Request memory newRequest = Request({
      description: description,
      value: value,
      recipient: recipient,
      complete: false,
      approvalCount: 0
    });

    requests.push(newRequest);
  }

  function approveRequest(uint index) public {
    Request storage request = requests[index];

    require(approvers[msg.sender]);
    require(!request.approvals[msg.sender]);

    request.approvals[msg.sender] = true;
    request.approvalCount++;
  }

  function finalizeRequest(uint index) public managerOnly {
    Request storage request = requests[index];
    require(!request.complete);
    require(request.approvalCount > (approversCount / 2));

    request.recipient.transfer(request.value);

    request.complete = true;
  }

  function getSummary() public view returns (
    uint, uint, uint, uint, address
  ) {
    return (
      minContribution,
      this.balance,
      requests.length,
      approversCount,
      manager
    );
  }

  function getRequestsCount() public view returns (uint) {
    return requests.length;
  }
}
