pragma solidity ^0.5.8;

import "./tokens/TRC20/TRC20.sol";
import "./tokens/TRC20/TRC20Detailed.sol";
import "./tokens/TRC20/TRC20Capped.sol";
import "./roles/MinterRole.sol";

/**
 * @title SaleChainToken
 * @dev TRC20 minting logic
 */
contract SaleChainToken is TRC20, MinterRole, TRC20Detailed, TRC20Capped{

    constructor(string memory name, string memory symbol, uint8 decimals, uint256 cap)
        TRC20Detailed(name, symbol, decimals)
        TRC20Capped(cap)
        public
    {

    }

     /**
     * @dev Function to mint tokens
     * @param to The address that will receive the minted tokens.
     * @param value The amount of tokens to mint.
     * @return A boolean that indicates if the operation was successful.
     */
    function mint(address to, uint256 value) public onlyMinter returns (bool) {
        _mint(to, value);
        return true;
    }
}