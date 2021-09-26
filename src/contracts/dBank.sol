// SPDX-License-Identifier: MIT
pragma solidity >=0.6.0 <0.8.0;

import "./Token.sol";

contract dBank {

  //assign Token contract to variable
  Token private token;

  //add mappings
  mapping (address => uint) public EthBal;
  mapping (address => uint) public depositStart;
  mapping (address => bool) public isDeposited;
  mapping (address => bool) public stLoan;
  mapping (address => uint) public EthCollateral;

  //add events
  event Deposit(address indexed user, uint EthAmount, uint tiStart);
  event Withdraw(address indexed user, uint userAmount, uint depositTime, uint interestEarned);
  event Borrow(address indexed user,uint collateralAmount, uint borrowAmount);
  event PayOff(address indexed user, uint fee);


  //pass as constructor argument deployed Token contract
  constructor(Token _token) public {
    //assign token deployed contract to variable
    token = _token;
  }

  function deposit() payable public {
    //check if msg.sender didn't already deposited funds
    require(isDeposited[msg.sender] == false, "Error: You already deposited. Can't do it anymore");
    //check if msg.value is >= than 0.01 ETH
    require(msg.value >= 1e16,"Error: Deposit must be >= 0.01 ETH");

    //increase msg.sender ether deposit balance
    EthBal[msg.sender] = EthBal[msg.sender] + msg.value;
    //start msg.sender hodling time
    depositStart[msg.sender] = depositStart[msg.sender] + block.timestamp;

    //set msg.sender deposit status to true
    isDeposited[msg.sender] = true;
    //emit Deposit event
    emit Deposit(msg.sender,msg.value,block.timestamp);
  }

  function withdraw() public {
    //check if msg.sender deposit status is true
    require(isDeposited[msg.sender] == true, "Error: User hans't deposited");
    //assign msg.sender ether deposit balance to variable for event
    uint userBal = EthBal[msg.sender];

    //check user's hodl time
    uint depositTime = block.timestamp - depositStart[msg.sender];

    //calc interest per second
    uint interestPerSecond = 31668087 * (EthBal[msg.sender]/1e16);
    //calc accrued interest
    uint interestEarned = interestPerSecond * depositTime;

    //send eth to user
    msg.sender.transfer(userBal);
    //send interest in tokens to user
    token.mint(msg.sender, interestEarned);

    //reset depositer data
    EthBal[msg.sender] = 0;
    depositStart[msg.sender] = 0;
    isDeposited[msg.sender] = false;

    //emit event
    emit Withdraw(msg.sender,userBal,depositTime,interestEarned);
  }

  function borrow() payable public {
    //check if collateral is >= than 0.01 ETH
    require(msg.value >= 1e16,"Error: Collateral is too low mate !!");
    //check if user doesn't have active loan
    require(stLoan[msg.sender] == false,"Error: You are having active loan! No you can't borrow no more!");

    //add msg.value to ether collateral
    EthCollateral[msg.sender] = EthCollateral[msg.sender] + msg.value;

    //calc tokens amount to mint, 50% of msg.value
    uint tokenAmount = msg.value;
    tokenAmount = tokenAmount/2;

    //mint&send tokens to user
    token.mint(msg.sender,tokenAmount);

    //activate borrower's loan status
    stLoan[msg.sender] = true;

    //emit event
    Borrow(msg.sender,EthCollateral[msg.sender],msg.value);
  }

  function payOff() public {
    //check if loan is active
    require(stLoan[msg.sender] == true, "Error: You are not borrowing anthing !!!");
    //transfer tokens from user back to the contract
    require(token.transferFrom(msg.sender, address(this), EthCollateral[msg.sender]/2),"Error: Can't receive tokens"); 

    //calc fee
    uint fee = EthCollateral[msg.sender]/10; // 10% fee

    //send user's collateral minus fee
    msg.sender.transfer(EthCollateral[msg.sender] - fee);

    //reset borrower's data
    EthCollateral[msg.sender] = 0;
    stLoan[msg.sender] = false;

    //emit event
    emit PayOff(msg.sender, fee);

  }
}