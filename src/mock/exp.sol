// SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;

/// ----------------------------------------------------------------------------
/// Overview
/// ----------------------------------------------------------------------------

// based on import "@rari-capital/solmate/src/tokens/ERC20.sol";
// based on https://github.com/m1guelpf/erc721-drop/blob/main/src/LilOwnable.sol

/// ----------------------------------------------------------------------------
/// Library Imports
/// ----------------------------------------------------------------------------
import "./solmate_ERC20_abridged.sol";
import "./LilOwnable.sol";

// import "hardhat/console.sol";

/// ----------------------------------------------------------------------------
/// Errors
/// ----------------------------------------------------------------------------

error NotAuthorized();
error BalanceTooLow();

/**
 * @title exp
 * @dev redacted
 */

contract exp is ERC20, LilOwnable {
    /// ------------------------------------------------------------------------
    /// Events
    /// ------------------------------------------------------------------------
    event TokenAdminSet(address indexed _adminAddr, bool indexed _isAdmin);

    /// ------------------------------------------------------------------------
    /// Variables
    /// ------------------------------------------------------------------------
    mapping(address => bool) public tokenAdmins;

    /// ------------------------------------------------------------------------
    /// Constructor
    /// ------------------------------------------------------------------------

    /**
     * @param _name token name
     * @param _symbol token symbol
     * @param _decimals decimal places
     * @param _owner initial owner of the contract
     * @dev set ERC20 parameters using ERC20 constructor
     * @dev set initial owner using LilOwnable constructor
     */
    constructor(
        string memory _name,
        string memory _symbol,
        uint8 _decimals,
        address _owner
    ) ERC20(_name, _symbol, _decimals) LilOwnable(_owner) {
        // deployer is initial tokenAdmin
        tokenAdmins[msg.sender] = true;
    }

    /// ------------------------------------------------------------------------
    /// Basic ERC20 Functionality
    /// ------------------------------------------------------------------------

    /**
     * @param _adminAddr tokenAdmin address
     * @param _isAdmin enable or disable mint/burn priviledges
     * @dev manages the permissions mapping for mint/brun priviledges
     */
    function setApprovedMinter(address _adminAddr, bool _isAdmin) public {
        if (msg.sender != _owner) revert NotOwner();
        tokenAdmins[_adminAddr] = _isAdmin;
        emit TokenAdminSet(_adminAddr, _isAdmin);
    }

    /**
     * @param _to recipient
     * @param _value number of tokens to mint
     * @dev creates and transfers soulbound tokens. caller must be tokenAdmin.
     */
    function mint(address _to, uint256 _value) public {
        if (tokenAdmins[msg.sender] == false) revert NotAuthorized();
        _mint(_to, _value);
    }

    /**
     * @param _from target
     * @param _value number of tokens to burn
     * @dev destroys soulbound tokens. caller must be tokenAdmin or target
     */
    function burn(address _from, uint256 _value) public {
        if ((tokenAdmins[msg.sender] == false) && (msg.sender != _from))
            revert NotAuthorized();
        if (balanceOf[_from] < _value) revert BalanceTooLow();
        _burn(_from, _value);
    }
}
