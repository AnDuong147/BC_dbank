// SPDX-License-Identifier: MIT
pragma solidity >=0.6.0 <0.8.0;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";

contract Token is ERC20 {
  //add minter variable
  address public minter;

  //add minter changed event
  event MinterChanged (address indexed oldAccount, address indexed newAccount);

  constructor() public payable ERC20("An Duong Money", "ADM") {
    //asign initial minter
    minter = msg.sender;
  }

  //Add pass minter role function
  function passMinterRole(address bankAccount) public returns (bool){
    require(msg.sender == minter, "Error, only the owner can pass minter role");
    address oldAccount = minter;
    minter = bankAccount;
    emit MinterChanged(oldAccount,minter);
    return true;
  }

  function mint(address account, uint256 amount) public {
    //check if msg.sender have minter role
    require(msg.sender == minter, "You get away !! You are not the owner!!You can't mint anything");
		_mint(account, amount);
	}
}