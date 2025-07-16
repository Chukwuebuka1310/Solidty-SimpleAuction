//SPDX-License-Identifier: MIT

pragma solidity ^0.8.18;


contract SimpleAuction{

    //Custom Error
    error AuctionAlreadyEnded(uint currentTime, uint biddingTime);
    error NotEnoughBid(uint highestBid);
    error AuctionNotEnded();
    error AuctionEndAlreadyCalled();
    OnlyBeneficiary(address beneficiary);

    address payable immutable i_beneficiary;
    uint auctionEndTime;

    //State Variable that keeps record of the current highestBid and highestBidder
    uint highestBid;
    address highestBidder;

    //Bollean to track the auction is ended.
    bool ended;


    //Mapping
    //This keeps the record of all the overbidden bidder(that's the rest of the 
    //callers of the bid function, that their amount sent wasn't high enough to
    //be recorded in the state(highest bid and highest))
    mapping(address bidder => uint amount) pendingReturns;


    //Event
    event AuctionEnded(uint amount, address bidder);


    //Assigned during deploytime
    //Needs input of bindingTime and always in second.
    constructor(
        uint biddingTime
    ){
        auctionEndTime = block.timestamp + biddingTime;
        i_beneficiary = payable(msg.sender);
    }

    //When called enables the send of a native token ie ETH.
    //Therefore, the value input in the deploy tab must be field with some value
    //of the native token
    function Bid() public payable {

        //Check if the time for bidding has elapsed
        if(block.timestamp > auctionEndTime){
            revert AuctionAlreadyEnded(block.timestamp, autionEndTime);
        }

        //Check if the amount sent is enough
        if(msg.value <= highestBid){
            revert NotEnoughBid(highestBid);
        }

        /**
         * Every caller of this function is expected to displace some other bidder,
         * therefore when that displacement happen i want an update in the pendingReturns 
         * mapping(add the former highest bid and highestbidder to the mapping)
         */
        if(highestBid != 0){
            pendingReturns[highestBidder] += highestBid;
        }

        //After all the checks, then
        //Assign the new caller to the state variables
        highestBid = msg.value;
        highestBidder = msg.sender;
    }

    //Withdraw fundtion can be called by outbidden bidders
    function Withdraw() public view returns (bool) {

        //Get access to the value sent be the caller of the withdraw function,
        //By going to the pendingReturns mapping with the the amount sent with 
        //the help of the callers address. The func expect a resturn of boolean
        //(true/false).
        uint amount = pendingReturns[msg.sender];

        //Check if the amount is graeter than zero, it yes
        if(amount > 0){

            //Then, make that update that address to be zero, since we are about to
            //take the funds away(withdraw)
            pendingReturns[msg.sender] = 0;

            //Then check if the send transaction failed. if yes,
            if(!payable(msg.sender).send(amount)){

                //Then restor the address with the amount we wanted to withdraw
                pendingReturns[msg.sender] = amount;

                //finally return false, since the withdraw failed
                return false;
            }

        }

        //If all went well, then return false
        return true;
    }

    /**
    * Function auctionEnd to be called by the only beneficiary(modifier OnlyBeneficiary) to transfer the 
    * highestBid to his address
    */
    function auctionEnd() public OnlyBeneficiary {

        //Check if the current time (block.timestamp) is less then the assigned auctionEndTime, if yes
        //Revert the custom error
        if(block.timestamp < auctionEndTime)revert AuctionNotEnded();

        //Check if the ended variable of the type of bool returns true, then
        //revert with the  custom error
        if(ended) revert AuctionEndAlreadyCalled();

        //If all the above is cleared, then change the default value of ended to true
        ended = true;

        //Then emit an event telling the blockcahin of the success of the transaction
        emit AuctionEnded(highestBid, highestBidder);

        //Then transfer the fund to the beneficiary
        i_beneficiary.transfer(highestBid);

    }

    modifier OnlyBeneficiary{
        if(msg.sender != i_beneficiary) revert OnlyBeneficiary(i_beneficiary);
        _;
    }

}