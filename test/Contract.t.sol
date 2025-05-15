// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import "forge-std/Test.sol";
import "../src/Contract.sol";

contract ScientiveDAOTest is Test {
    ScientiveDAO dao;
    address founder;
    address member1;
    address member2;
    address scientist;
    uint quorum = 2;

    function setUp() public {
        founder = address(this);
        member1 = makeAddr("member1");
        member2 = makeAddr("member2");
        scientist = makeAddr("scientist");

        vm.deal(founder, 10 ether);
        vm.deal(member1, 10 ether);
        vm.deal(member2, 10 ether);

        dao = new ScientiveDAO(quorum);
    }

    function testConstructor() public {
        assertEq(dao.founder(), founder);
        assertEq(dao.quorum(), quorum);
        assertTrue(dao.members(founder));
    }

    function testJoinDAO() public {
        vm.prank(member1);
        dao.joinDAO();

        assertTrue(dao.members(member1));
    }

    function testContributeFunds() public {
        vm.prank(member1);
        dao.joinDAO();

        vm.prank(member1);
        dao.contributeFunds{value: 1 ether}();

        assertEq(dao.getBalance(), 1 ether);
    }

    function testContributeFundsOnlyMembers() public {
        vm.prank(member1);
        vm.expectRevert("Not a DAO member");
        dao.contributeFunds{value: 1 ether}();
    }

    function testSubmitProject() public {
        vm.prank(scientist);
        dao.joinDAO();

        vm.prank(scientist);
        dao.submitProject(
            "Research Project",
            "Conducting scientific research",
            1 ether,
            "ipfs://hash"
        );

        assertEq(dao.proposalCount(), 1);

        (
            string memory title,
            string memory description,
            string memory ipfsHash,
            address payable scientistAddr,
            uint amountRequested,
            uint votes,
            bool funded
        ) = dao.proposals(0);

        assertEq(title, "Research Project");
        assertEq(description, "Conducting scientific research");
        assertEq(ipfsHash, "ipfs://hash");
        assertEq(scientistAddr, scientist);
        assertEq(amountRequested, 1 ether);
        assertEq(votes, 0);
        assertEq(funded, false);
    }

    function testVoteProject() public {
        // Setup project
        vm.prank(scientist);
        dao.joinDAO();

        vm.prank(scientist);
        dao.submitProject(
            "Research Project",
            "Conducting scientific research",
            1 ether,
            "ipfs://hash"
        );

        // Setup members
        vm.prank(member1);
        dao.joinDAO();

        // Vote
        vm.prank(member1);
        dao.voteProject(0);

        (, , , , , uint votes, ) = dao.proposals(0);
        assertEq(votes, 1);
    }

    function testFundProject() public {
        // Setup project
        vm.prank(scientist);
        dao.joinDAO();

        vm.prank(scientist);
        dao.submitProject(
            "Research Project",
            "Conducting scientific research",
            1 ether,
            "ipfs://hash"
        );

        // Setup members and vote
        vm.prank(member1);
        dao.joinDAO();

        vm.prank(member2);
        dao.joinDAO();

        vm.prank(member1);
        dao.voteProject(0);

        vm.prank(member2);
        dao.voteProject(0);

        // Add funds to DAO
        vm.prank(member1);
        dao.contributeFunds{value: 2 ether}();

        // Fund project
        vm.prank(member1);
        dao.fundProject(0);

        (, , , , , , bool funded) = dao.proposals(0);
        assertTrue(funded);
        assertEq(dao.getBalance(), 1 ether);
        assertEq(scientist.balance, 1 ether);
    }

    function testGetBalance() public {
        vm.prank(member1);
        dao.joinDAO();

        vm.prank(member1);
        dao.contributeFunds{value: 1 ether}();

        assertEq(dao.getBalance(), 1 ether);
    }

    function testIsMember() public {
        assertTrue(dao.isMember(founder));

        vm.prank(member1);
        dao.joinDAO();

        assertTrue(dao.isMember(member1));
        assertFalse(dao.isMember(member2));
    }
}
