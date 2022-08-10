//  SPDX-License-Identifier: GPL-3.0

pragma solidity >=0.5.0. <0.9.0;

contract AuctionCreator{
    Auction[] public auctions;

    function createAuction() public{
        Auction newAuction = new Auction(msg.sender);
        auctions.push(newAuction);
    }
}


contract Auction{
    address payable public owner;
    uint public startBlock;
    uint public endBlock;
    string public ipfsHash;

    enum State {Started, Running, Ended, Canceled}
    State public auctionState;

    uint public highestBindingBid;
    address payable public highestBider;

    mapping(address =>uint) public bids;
    uint bidIncrement;


    constructor(address eoa){
        owner = payable(eoa);
        auctionState = State.Running;
        startBlock = block.number;
        endBlock = block.number + 40320;
        ipfsHash = "";
        bidIncrement = 100;

    }
    modifier notowner(){
        require(msg.sender != owner);
        _;
    }
    modifier afterStart(){
        require(block.number >= startBlock);
        _;
    }
    modifier beforeEnd(){
        require(block.number <= endBlock);
        _;
    }
    modifier onlyOwner(){
        require(msg.sender == owner);
        _;
    }

    function cancelAuction() public onlyOwner{
        auctionState = State.Canceled;
    
    }

    function min(uint a, uint b) pure internal returns(uint){
        if(a <= b){
            return a;
        }else{
            return b;
        }
    }    

    function placeBid() public payable notowner afterStart beforeEnd{
        require(auctionState == State.Running);
        require(msg.value >= 100);

        uint currentBid = bids[msg.sender] + msg.value;
        require(currentBid > highestBindingBid);

        bids[msg.sender] = currentBid;

        if(currentBid <= bids[highestBider]){
            highestBindingBid = min(currentBid + bidIncrement, bids[highestBider]);
        }else{
            highestBindingBid = min(currentBid, bids[highestBider] + bidIncrement);
            highestBider = payable(msg.sender);

        }
    }

    function finalizeAuction() public{
        require(auctionState == State.Canceled || block.number > endBlock);
        require(msg.sender == owner || bids[msg.sender] > 0);

        address payable recipient;
        uint value;

        if(auctionState == State.Canceled){
            recipient = payable(msg.sender);
            value = bids[msg.sender];
        }else{
            if(msg.sender == owner){
                recipient = owner;
                value = highestBindingBid;
            }else{
                if(msg.sender == highestBider){
                    recipient = highestBider;
                    value = bids[highestBider] - highestBindingBid;
                }else{
                    recipient = payable(msg.sender);
                    value = bids[msg.sender];
                }
            }

        }

        bids [recipient] = 0;
        recipient.transfer(value);
    }
}