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

    address public constant REGISTRY =
        address(0xd9145CCE52D386f254917e481eB44e9943F39138);
    address public constant INVENTORY_IMPLEMENTATION =
        address(0xd8b934580fcE35a11B58C6D73aDeE468a2833fa8);
    address public constant GOLD =
        address(0xf8e81D47203A594245E36C48e151709F0C19fBe8);
    address public constant ITEM =
        address(0xD7ACd2a9FD159E69Bb102A1ca21C9a3e3A5F771B);

    Counters.Counter private _tokenIdCounter;
    mapping(uint256 => string) private _characterNames;
    mapping(uint256 => address) private _characterInventories;

    constructor() ERC721("Text Quest Character", "TQC") {}

    function safeMint(address to, string memory characterName) public {
        require(bytes(characterName).length > 0, "Name cannot be empty");
        uint256 tokenId = _tokenIdCounter.current();
        _tokenIdCounter.increment();
        _safeMint(to, tokenId);
        _characterNames[tokenId] = characterName;

        address inventoryAddress = createAccount(tokenId);
        _characterInventories[tokenId] = inventoryAddress;
        TextQuestGold(GOLD).mint(inventoryAddress, 100);
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
        bytes memory image = generateImage(tokenId);
        return
            string(
                abi.encodePacked(
                    'data:application/json,{"tokenId": "',
                    Strings.toString(tokenId),
                    '", "name":"',
                    name,
                    '", "image": "data:image/svg+xml;base64,',
                    Base64.encode(image),
                    '"}'
                )
            );
    }

    function generateImage(
        uint256 tokenId
    ) internal view returns (bytes memory) {
        string memory name = _characterNames[tokenId];
        uint256 gold = goldBalanceOf(tokenId);
        uint256[] memory items = itemsOf(tokenId);
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
                    TextQuestItem(ITEM).itemName(index),
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
            IERC6551Registry(REGISTRY).createAccount(
                INVENTORY_IMPLEMENTATION,
                block.chainid,
                address(this),
                tokenId,
                0,
                ""
            );
    }

    function itemsOf(uint256 tokenId) public view returns (uint256[] memory) {
        address inventoryAddress = _characterInventories[tokenId];
        return TextQuestItem(ITEM).tokensOfOwner(inventoryAddress);
    }

    function goldBalanceOf(uint256 tokenId) public view returns (uint256) {
        address inventoryAddress = _characterInventories[tokenId];
        return TextQuestGold(GOLD).balanceOf(inventoryAddress);
    }
}
