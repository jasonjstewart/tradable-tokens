//SPDX-License-Identifier: MIT
pragma solidity >=0.6.2;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";

contract TestToken is ERC20, Ownable {
  string private TOKEN_NAME = "Test Token";
  string private TOKEN_SYMBOL = "TKN";

  event Sale(address seller, address indexed buyer, uint256 price, uint256 count);
  event Listed(address indexed owner, uint256 price, uint256 count);
  event Unlisted(address indexed owner, uint256 previousPrice, uint256 numTokens);

  uint256 private constant TOTAL_SUPPLY = 10000;

  constructor() ERC20(TOKEN_NAME, TOKEN_SYMBOL) {
    _mint(msg.sender, TOTAL_SUPPLY);
  }
  
  function decimals() public view virtual override returns (uint8) {
    return 0;
  }

  function mint(address to, uint256 amount) public onlyOwner {
    _mint(to, amount);
  }

  function burn(address from, uint256 amount) public onlyOwner {
    _burn(from, amount);
  }
  
//   function list(uint256 price, uint256 count) public {
//       uint256 total = price*count;
//       increaseAllowance(wallet, total);
//       sent=msg.sender;
//       doSomething(msg.sender);
//       emit Listed(msg.sender, price, count);
//   }
  
//     function unlist(uint256 price, uint256 count) public {
//       decreaseAllowance(wallet, 0);
//       emit Unlisted(msg.sender, price, count);
//   }

  function sale(address sellerAddress, uint256 count, uint256 price) public payable {
    require(balanceOf(sellerAddress)>=count, "Seller does not have enough tokens.");
    require(msg.value >= count*price, "Insufficient funds sent, please send the correct amount of funds.");
    transferFrom(sellerAddress, msg.sender, count);
    payable(sellerAddress).transfer(msg.value);
    emit Sale(sellerAddress, msg.sender, price, count);
  }
}
