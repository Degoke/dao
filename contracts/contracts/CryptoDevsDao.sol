// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/access/Ownable.sol";

interface IFakeNftMarketplace {
    function getPrice() external view returns (uint256);

    function available(uint256 _tokenId) external view returns (bool);

    function purchase(uint256 _tokenId) external payable;
}

interface ICryptoDevsNft {
    function balanceOf(address owner) external view returns (uint256);

    function tokenOfOwnerByIndex(address owner, uint256 index) external view returns (uint256);
}

contract CryptoDevsDAO is Ownable {
    struct Proposal {
        uint256 nftTokenId;

        uint256 deadline;

        uint256 yayVotes;

        uint256 nayVotes;

        bool executed;

        mapping(uint256 => bool) voters;
    }

    mapping(uint256 => Proposal) public proposals;

    uint256 public numProposals;

    IFakeNftMarketplace nftMarketplace;
    ICryptoDevsNft cryptoDevsNFT;

    modifier nftHolderOnly() {
        require(cryptoDevsNFT.balanceOf(msg.sender) > 0, "NOT_A DAO_MEMBER");
        _;
    }

    modifier activeProposalOnly(uint256 proposalIndex) {
        require(proposals[proposalIndex].deadline > block.timestamp, "DEADLINE_EXCEEDED");
        _;
    }

    modifier inactiveProposalOnly(uint256 proposalIndex) {
        require(proposals[proposalIndex].deadline <= block.timestamp, "DEADLINE_NOT_EXCEEDED");
        require(proposals[proposalIndex].executed == false, "PROPOSAL_ALREADY_EXECUTED");
        _;
    }

    enum Vote {
        YAY,
        NAY
    }

    constructor(address _nftMarketPlace, address _cryptoDevsNFT) payable {
        nftMarketplace = IFakeNftMarketplace(_nftMarketPlace);
        cryptoDevsNFT = ICryptoDevsNft(_cryptoDevsNFT);
    }

    function createProposal(uint256 _nftTokenId) external nftHolderOnly returns (uint256) {
        Proposal storage proposal = proposals[numProposals];
        proposal.nftTokenId = _nftTokenId;
        proposal.deadline = block.timestamp + 5 minutes;
        
        numProposals++;

        return numProposals - 1;
    }

    function voteOnProposal(uint256 proposalIndex, Vote vote) external nftHolderOnly activeProposalOnly(proposalIndex) {
        Proposal storage proposal = proposals[proposalIndex];

        uint256 voterNFTBallance = cryptoDevsNFT.balanceOf(msg.sender);
        uint256 numVotes = 0;

        for (uint256 i = 0; i < voterNFTBallance; i++) {
            uint256 tokenId = cryptoDevsNFT.tokenOfOwnerByIndex(msg.sender, i);
            if (proposal.voters[tokenId] == false) {
                numVotes++;
                proposal.voters[tokenId] = true;
            }
        }
        require(numVotes > 0, "ALREADY_VOTED");

        if(vote == Vote.YAY) {
            proposal.yayVotes += numVotes;
        } else {
            proposal.nayVotes += numVotes;
        }
    }

    function executeProposal(uint256 proposalIndex) external nftHolderOnly inactiveProposalOnly(proposalIndex) {
        Proposal storage proposal = proposals[proposalIndex];

        if (proposal.yayVotes > proposal.nayVotes) {
            uint256 nftPrice = nftMarketplace.getPrice();
            require(address(this).balance >= nftPrice, "NOT_ENOUGH_FUNDS");
            nftMarketplace.purchase{value: nftPrice}(proposal.nftTokenId);
        }

        proposal.executed = true;
    }

    function withdrawEther() external onlyOwner {
        payable(owner()).transfer(address(this).balance);
    }

    receive() external payable {}

    fallback() external payable {}

}