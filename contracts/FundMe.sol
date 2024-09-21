// SPDX-License-Identifier: GPL-3.0

pragma solidity >=0.7.0 <0.9.0;

import {PriceConverter} from "./PriceConverter.sol";

error NotOwner();

contract FundMe {

    address public immutable i_owner;

    using PriceConverter for uint256; // attaching the converter library to all uint256

    uint256 public constant MINIMUM_USD = 5 * (10**18); // 5e18

    address[] public funders;
    mapping (address funder => uint256 amountFunded) public addressToAmountFunded;

    constructor() {
        // setting the owner of the contract to the msg sender 
        i_owner = msg.sender;
    }

    modifier onlyOwner() {
        require(msg.sender == i_owner, "You are not the owner");
        if(msg.sender != i_owner){ revert NotOwner();}
        _;
    }

    function fund() public payable {
        require(msg.value.getConversionRate() >= MINIMUM_USD, "You cant send less than 1 ETH");

        funders.push(msg.sender);
        addressToAmountFunded[msg.sender] += msg.value;
    }

    function withdraw() public onlyOwner { 
        for(uint256 founderIndex = 0; founderIndex < funders.length; founderIndex++) {
            address funder = funders[founderIndex];
            addressToAmountFunded[funder] = 0; 
        }
        // resettting the funders array
        funders = new address[](0);

        // withdraw the funds
        // payable(msg.sender).transfer(address(this).balance);
        // bool sendSuccess = payable(msg.sender).send(address(this).balance);
        // require(sendSuccess, "Send failed!");
        (bool success,) = msg.sender.call{value: address(this).balance}("");
        require(success, "Withdrawal failed");
    }

    receive() external payable { 
        fund();
    }

    fallback() external payable { 
        fund();
    }

}