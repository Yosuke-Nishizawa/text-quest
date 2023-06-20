// SPDX-License-Identifier: MIT
pragma solidity ^0.8.18;

import "@openzeppelin/contracts/access/Ownable.sol";
import "./TextQuestItem.sol";
import "./TextQuestGold.sol";

contract TextQuestItemShop is Ownable {
    TextQuestItem private itemContract;
    TextQuestGold private goldContract;

    constructor(address _itemAddress, address _goldAddress) {
        itemContract = TextQuestItem(_itemAddress);
        goldContract = TextQuestGold(_goldAddress);
    }

    function buyItem(string memory _itemName, uint256 _price) public {
        require(
            goldContract.balanceOf(msg.sender) >= _price,
            "Insufficient gold balance"
        );
        itemContract.safeMint(msg.sender, _itemName);
        goldContract.transferFrom(msg.sender, address(this), _price);
    }

    function withdrawGold(uint256 _amount) public onlyOwner {
        require(
            goldContract.balanceOf(address(this)) >= _amount,
            "Insufficient contract gold balance"
        );
        goldContract.transfer(owner(), _amount);
    }
}
