// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity >=0.8.0;

import "openzeppelin-contracts/contracts/token/ERC721/ERC721.sol";
import "openzeppelin-contracts/contracts/access/Ownable.sol";
import "openzeppelin-contracts/contracts/utils/Strings.sol";
import "openzeppelin-contracts/contracts/utils/cryptography/ECDSA.sol";

contract VNFT is ERC721, Ownable {
    uint256 public constant MAX_SUPPLY = 10000;
    uint256 public constant MAX_TX = 2;
    uint256 public constant MAX_WALLET = 2;

    uint256 public totalSupply;
    mapping(address => uint256) public mintsPerWallet;
    string public baseURI;

    constructor() ERC721("VulnerableNFT", "VNFT") {}

    function withdraw() external onlyOwner {
        uint256 balance = address(this).balance;
        payable(msg.sender).transfer(balance);
    }

    function setBaseURI(string memory _baseURI) external onlyOwner {
        baseURI = _baseURI;
    }

    // try your luck and mint even if you are not whitelisted
    function imFeelingLucky(
        address to,
        uint256 qty,
        uint256 number
    ) external {
        require(qty > 0 && qty <= MAX_TX, "Invalid quantity");
        require(totalSupply + qty <= MAX_SUPPLY, "Max supply reached");
        require(
            mintsPerWallet[to] + qty <= MAX_WALLET,
            "Max balance per wallet reached"
        );
        require((msg.sender).code.length == 0, "Only EOA allowed");

        uint256 randomNumber = uint256(
            keccak256(
                abi.encodePacked(
                    blockhash(block.number - 1),
                    block.timestamp,
                    totalSupply
                )
            )
        ) % 100;

        require(randomNumber == number, "Better luck next time!");

        unchecked {
            mintsPerWallet[to] += qty;
            uint256 mintId = totalSupply;
            totalSupply += qty;
            for (uint256 i = 0; i < qty; i++) {
                _safeMint(to, mintId++);
            }
        }
    }

    // only whitelisted wallets can mint
    function whitelistMint(
        address to,
        uint256 qty,
        bytes32 hash,
        bytes memory signature
    ) external payable {
        require(
            recoverSigner(hash, signature) == owner(),
            "Address is not allowlisted"
        );
        require(totalSupply + qty <= MAX_SUPPLY, "Max supply reached");
        require(
            mintsPerWallet[to] + qty <= MAX_WALLET,
            "Max balance per wallet reached"
        );

        unchecked {
            mintsPerWallet[to] += qty;
            uint256 mintId = totalSupply;
            totalSupply += qty;
            for (uint256 i = 0; i < qty; i++) {
                _safeMint(to, mintId++);
            }
        }
    }

    /**
     * @dev See {IERC721Metadata-tokenURI}.
     */
    function tokenURI(uint256 _tokenId)
        public
        view
        override
        returns (string memory)
    {
        require(_tokenId < totalSupply, "Non existent token");
        return string(abi.encodePacked(baseURI, Strings.toString(_tokenId)));
    }

    function recoverSigner(bytes32 hash, bytes memory signature)
        public
        pure
        returns (address)
    {
        bytes32 messageDigest = keccak256(
            abi.encodePacked("\x19Ethereum Signed Message:\n32", hash)
        );
        return ECDSA.recover(messageDigest, signature);
    }
}
