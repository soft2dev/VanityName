//SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import '@openzeppelin/contracts/access/Ownable.sol';
import '@openzeppelin/contracts/token/ERC20/ERC20.sol';

contract ERC20Token is ERC20, Ownable {
    constructor(string memory _name, string memory _symbol) ERC20(_name, _symbol) {}

    function mint(address _account, uint256 _amount) public onlyOwner {
        _mint(_account, _amount);
    }
}
