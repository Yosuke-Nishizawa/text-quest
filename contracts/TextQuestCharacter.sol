// SPDX-License-Identifier: MIT
pragma solidity ^0.8.18;

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721Enumerable.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721Burnable.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/Counters.sol";
import "@openzeppelin/contracts/utils/Base64.sol";
import "@openzeppelin/contracts/utils/Strings.sol";
import "./interfaces/IERC6551Registry.sol";
import "./TextQuestGold.sol";
import "./TextQuestItem.sol";

contract TextQuestCharacter is
    ERC721,
    ERC721Enumerable,
    ERC721Burnable,
    Ownable
{
    using Counters for Counters.Counter;

    address public registryAddress;
    address public inventoryImplementationAddress;
    address public goldAddress;
    address public itemAddress;

    Counters.Counter private _tokenIdCounter;
    mapping(uint256 => string) private _characterNames;
    mapping(uint256 => address) private _characterInventories;

    constructor(
        address _registryAddress,
        address _inventoryImplementationAddress,
        address _goldAddress,
        address _itemAddress
    ) ERC721("Text Quest Character", "TQC") {
        registryAddress = _registryAddress;
        inventoryImplementationAddress = _inventoryImplementationAddress;
        goldAddress = _goldAddress;
        itemAddress = _itemAddress;
    }

    function safeMint(address to, string memory characterName) public {
        require(bytes(characterName).length > 0, "Name cannot be empty");
        uint256 tokenId = _tokenIdCounter.current();
        _tokenIdCounter.increment();
        _safeMint(to, tokenId);
        _characterNames[tokenId] = characterName;

        address inventoryAddress = createAccount(tokenId);
        _characterInventories[tokenId] = inventoryAddress;
        TextQuestGold(goldAddress).mint(inventoryAddress, 100 * 10 ** 18);
    }

    // The following functions are overrides required by Solidity.

    function _beforeTokenTransfer(
        address from,
        address to,
        uint256 tokenId,
        uint256 batchSize
    ) internal override(ERC721, ERC721Enumerable) {
        super._beforeTokenTransfer(from, to, tokenId, batchSize);
    }

    function supportsInterface(
        bytes4 interfaceId
    ) public view override(ERC721, ERC721Enumerable) returns (bool) {
        return super.supportsInterface(interfaceId);
    }

    function tokenURI(
        uint256 tokenId
    ) public view virtual override returns (string memory) {
        string memory name = _characterNames[tokenId];
        uint256 gold = goldBalanceOf(tokenId) / (10 ** 18);
        uint256[] memory itemIds = itemsOf(tokenId);
        string[] memory items = new string[](itemIds.length);

        for (uint256 i = 0; i < itemIds.length; i++) {
            items[i] = TextQuestItem(itemAddress).itemName(itemIds[i]);
        }
        bytes memory image = generateImage(name, gold, items);
        return
            string(
                abi.encodePacked(
                    'data:application/json,{"tokenId": "',
                    Strings.toString(tokenId),
                    '", "name":"',
                    name,
                    '", "gold":',
                    Strings.toString(gold),
                    ', "items":',
                    arrayToString(items),
                    ', "image": "data:image/svg+xml;base64,',
                    Base64.encode(image),
                    '"}'
                )
            );
    }

    function generateImage(
        string memory name,
        uint256 gold,
        string[] memory items
    ) internal pure returns (bytes memory) {
        string
            memory svgStart = '<svg xmlns="http://www.w3.org/2000/svg" preserveAspectRatio="xMinYMin meet" viewBox="0 0 300 300"><style>.base { fill: white; font-family: serif; font-size: 14px; }</style><rect width="100%" height="100%" fill="black" />';
        string memory svgEnd = "</svg>";

        string memory ownerText = string(
            abi.encodePacked(
                '<text x="10" y="20" class="base">',
                "name: ",
                name,
                "</text>"
            )
        );

        string memory goldText = string(
            abi.encodePacked(
                '<text x="10" y="40" class="base">',
                "gold: ",
                Strings.toString(gold),
                "G",
                "</text>"
            )
        );

        string
            memory itemsTextStart = '<text x="10" y="60" class="base">items: ';
        string memory itemsTextEnd = "</text>";
        string memory itemsTextContent;

        for (uint256 index = 0; index < items.length; index++) {
            itemsTextContent = string(
                abi.encodePacked(
                    itemsTextContent,
                    items[index],
                    index == items.length - 1 ? "" : ", "
                )
            );
        }

        string memory itemsText = string(
            abi.encodePacked(itemsTextStart, itemsTextContent, itemsTextEnd)
        );

        string memory svgContent = string(
            abi.encodePacked(ownerText, goldText, itemsText)
        );

        return abi.encodePacked(svgStart, svgContent, svgEnd);
    }

    function createAccount(uint256 tokenId) private returns (address) {
        return
            IERC6551Registry(registryAddress).createAccount(
                inventoryImplementationAddress,
                block.chainid,
                address(this),
                tokenId,
                0,
                ""
            );
    }

    function itemsOf(uint256 tokenId) public view returns (uint256[] memory) {
        address inventoryAddress = _characterInventories[tokenId];
        return TextQuestItem(itemAddress).tokensOfOwner(inventoryAddress);
    }

    function goldBalanceOf(uint256 tokenId) public view returns (uint256) {
        address inventoryAddress = _characterInventories[tokenId];
        return TextQuestGold(goldAddress).balanceOf(inventoryAddress);
    }

    function getCharacterInventory(
        uint256 tokenId
    ) public view returns (address) {
        return _characterInventories[tokenId];
    }

    function arrayToString(
        string[] memory array
    ) internal pure returns (string memory) {
        string memory result = "[";
        for (uint i = 0; i < array.length; i++) {
            result = string(abi.encodePacked(result, '"', array[i], '"'));
            if (i != array.length - 1) {
                result = string(abi.encodePacked(result, ","));
            }
        }
        result = string(abi.encodePacked(result, "]"));
        return result;
    }
}
