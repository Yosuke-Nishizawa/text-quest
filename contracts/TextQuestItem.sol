// SPDX-License-Identifier: MIT
pragma solidity ^0.8.18;

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721Enumerable.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721Burnable.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/Counters.sol";
import "@openzeppelin/contracts/utils/Base64.sol";

contract TextQuestItem is ERC721, ERC721Enumerable, ERC721Burnable, Ownable {
    using Counters for Counters.Counter;

    Counters.Counter private _tokenIdCounter;
    mapping(uint256 => string) private _itemNames;

    constructor() ERC721("TextQuestItem", "TQI") {}

    function safeMint(address to, string memory _itemName) public {
        require(bytes(_itemName).length > 0, "Name cannot be empty");
        uint256 tokenId = _tokenIdCounter.current();
        _tokenIdCounter.increment();
        _safeMint(to, tokenId);
        _itemNames[tokenId] = _itemName;
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
        string memory name = _itemNames[tokenId];
        bytes memory image = generateImage(name);
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
        string memory name
    ) internal pure returns (bytes memory) {
        return
            abi.encodePacked(
                '<svg xmlns="http://www.w3.org/2000/svg" preserveAspectRatio="xMinYMin meet" viewBox="0 0 300 300"><style>.base { fill: white; font-family: serif; font-size: 24px; }</style><rect width="100%" height="100%" fill="black" /><text x="50%" y="50%" class="base" dominant-baseline="middle" text-anchor="middle">',
                name,
                "</text></svg>"
            );
    }

    function tokensOfOwner(
        address owner
    ) public view returns (uint256[] memory) {
        uint256 tokenCount = balanceOf(owner);

        if (tokenCount == 0) {
            // Return an empty array
            return new uint256[](0);
        } else {
            uint256[] memory result = new uint256[](tokenCount);
            for (uint256 index = 0; index < tokenCount; index++) {
                result[index] = tokenOfOwnerByIndex(owner, index);
            }
            return result;
        }
    }

    function itemName(uint256 tokenId) public view returns (string memory) {
        return _itemNames[tokenId];
    }
}
