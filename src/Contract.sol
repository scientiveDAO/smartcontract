// SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;

contract ScientiveDAO {
    struct ProjectProposal {
        string title;
        string description;
        string ipfsHash;
        address payable scientist;
        uint amountRequested;
        uint votes;
        bool funded;
        mapping(address => bool) voters;
    }

    address public founder;
    uint public quorum;
    uint public proposalCount;
    mapping(address => bool) public members;
    mapping(uint => ProjectProposal) public proposals;

    modifier onlyMembers() {
        require(members[msg.sender], "Not a DAO member");
        _;
    }

    constructor(uint _quorum) {
        founder = msg.sender;
        members[msg.sender] = true;
        quorum = _quorum;
    }

    function joinDAO() external {
        members[msg.sender] = true;
    }

    function contributeFunds() external payable onlyMembers {
        // TODO: add a function to contribute funds to the DAO
    }

    function submitProject(
        string memory _title,
        string memory _description,
        uint _amountRequested,
        string memory _ipfsHash
    ) external onlyMembers {
        ProjectProposal storage p = proposals[proposalCount++];
        p.title = _title;
        p.description = _description;
        p.scientist = payable(msg.sender);
        p.amountRequested = _amountRequested;
        p.ipfsHash = _ipfsHash;
        p.funded = false;
    }

    function getProposals(
        uint256 _startId,
        uint256 _qtd
    ) external view returns (ProjectProposal[] memory) {
        ProjectProposal[] memory _projectProposal = new ProjectProposal[](_qtd);
        uint256 _id = _startId;
        uint256 count = 0;

        do {
            if (proposals[_id].funded == false) {
                _projectProposal[count] = proposals[_id];
                count++;
            }

            _id++;
        } while (count < _qtd && _id <= proposalCount);

        return _projectProposal;
    }

    function voteProject(uint proposalId) external onlyMembers {
        ProjectProposal storage p = proposals[proposalId];
        require(!p.voters[msg.sender], "Already voted");
        require(!p.funded, "Already funded");
        p.voters[msg.sender] = true;
        p.votes++;
    }

    function fundProject(uint proposalId) external onlyMembers {
        ProjectProposal storage p = proposals[proposalId];
        require(!p.funded, "Already funded");
        require(p.votes >= quorum, "Not enough votes");
        require(
            address(this).balance >= p.amountRequested,
            "Insufficient DAO funds"
        );

        p.funded = true;
        p.scientist.transfer(p.amountRequested);
    }

    function getBalance() external view returns (uint) {
        return address(this).balance;
    }

    function isMember(address addr) external view returns (bool) {
        return members[addr];
    }
}
