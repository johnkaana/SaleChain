pragma solidity ^0.5.8;

import "openzeppelin-solidity/contracts/math/SafeMath.sol";
import "openzeppelin-solidity/contracts/utils/Address.sol";
import "./tokens/TRC20/ITRC20.sol";
import "openzeppelin-solidity/contracts/token/ERC20/SafeERC20.sol";

contract StakingEnumerable {
    using SafeMath for uint256;

    // Array with all holders addresses, used for enumeration
    address[] private _allHolders;

    // Mapping from holder address to position in the allHolders array
    mapping(address => uint256) private _allHoldersIndex;

    /**
     * @dev Gets the total amount of holders stored by the contract.
     * @return uint256 representing the total amount of holders
     */
    function totalHolder() public view returns (uint256) {
        return _allHolders.length;
    }

    /**
     * @dev Gets the account address at a given index of all the holders in this contract
     * Reverts if the index is greater or equal to the total number of holders.
     * @param index uint256 representing the index to be accessed of the holders list
     * @return account address at the given index of the holders list
     */
    function holderByIndex(uint256 index) public view returns (address) {
        require(index < totalHolder(), "StakingEnumerable: global index out of bounds");
        return _allHolders[index];
    }

    /**
     * @dev Gets the account address at a given index of all the holders in this contract
     * Reverts if the index is greater or equal to the total number of holders.
     * @return account address at the given index of the holders list
     */
    function allHolders() public view returns (address[] memory) {
        return _allHolders;
    }

    /**
     * @dev Internal function to add a holder to holder List.
     * @param account address of tokens to be emitted
     */
    function addHolder(address account) internal {
        if (_allHoldersIndex[account] == 0){
            _addAccountToAllAccountsEnumeration(account);
        }
    }

    /**
     * @dev Internal function to add a holder to holder List.
     * @param account address of tokens to be emitted
     */
    function removeHolder(address account) internal {
        if (_allHoldersIndex[account] != 0){
            _removeAccountFromAllAccountsEnumeration(account);
        }
    }

    /**
     * @dev Private function to add a holder to this extension's holder tracking data structures.
     * @param account address of the holder to be added to the tokens list
     */
    function _addAccountToAllAccountsEnumeration(address account) private {
        _allHoldersIndex[account] = _allHolders.length;
        _allHolders.push(account);
    }

    /**
     * @dev Private function to remove a holder from this extension's holder tracking data structures.
     * This has O(1) time complexity, but alters the order of the _allHolders array.
     * @param account address of the holder to be removed from the tokens list
     */
    function _removeAccountFromAllAccountsEnumeration(address account) private {
        // To prevent a gap in the tokens array, we store the last holder in the index of the holder to delete, and
        // then delete the last slot (swap and pop).

        uint256 lastAccountIndex = _allHolders.length.sub(1);
        uint256 accountIndex = _allHoldersIndex[account];

        // When the holder to delete is the last token, the swap operation is unnecessary. However, since this occurs so
        // rarely (when the last minted holder is burnt) that we still do the swap here to avoid the gas cost of adding
        // an 'if' statement (like in _removeAccountFromOwnerEnumeration)
        address lastAccount = _allHolders[lastAccountIndex];

        _allHolders[accountIndex] = lastAccount; // Move the last holder to the slot of the to-delete token
        _allHoldersIndex[lastAccount] = accountIndex; // Update the moved token's index

        // This also deletes the contents at the last position of the array
        _allHolders.length--;
        _allHoldersIndex[account] = 0;
    }
}

contract SaleChainStaking is StakingEnumerable {
    using SafeMath for uint256;
    using Address for address payable;

    // The token being sold
    ITRC20 private _token;

    uint256 private _totalShares;

    mapping(address => uint256) private _deposits;
    mapping(address => uint256) private _depositsTime;

    /**
     * Event for release staking fund logging
     * @param distributary who paid for the fund
     * @param amount amount of TRX has been released
     */
    event ReleaseFund(address indexed distributary, uint256 amount);

    /**
     * @dev Getter for the total shares held by payees.
     */
    function totalShares() public view returns (uint256) {
        return _totalShares;
    }

    function depositsOf(address payee) public view returns (uint256) {
        return _deposits[payee];
    }

    function depositsTime(address payee) public view returns (uint256) {
        return _depositsTime[payee];
    }

    /**
     * Event for token Staking logging
     * @param payee The destination address of the tokens.
     * @param tokenAmount amount of tokens purchased
     */
    event StakeWin(address indexed payee, uint256 tokenAmount);

    /**
     * Event for token unfreeze logging
     * @param payee The destination address of the tokens.
     * @param tokenAmount amount of tokens purchased
     */
    event Unfreeze(address indexed payee, uint256 tokenAmount);

    /**
     * @dev The rate is the conversion between sun and the smallest and indivisible
     * token unit. So, if you are using a rate of 1 with a TRC20Detailed token
     * with 3 decimals called TOK, 1 sun will give you 1 unit, or 0.001 TOK.
     * @param token Address of the token being sold
     */
    constructor (ITRC20 token) public {
        require(address(token) != address(0), "SaleChainStaking: token is the zero address");

        _token = token;
    }

    /**
     * @dev freeze amount Of tokens to get staking fund.
     * @param payee The destination address of the tokens.
     * @param tokenAmount amount of tokens to be freeze
     */
    function stakeWin(address payee, uint256 tokenAmount) public {
        _token.transferFrom(payee, address(this), tokenAmount);
        _deposits[payee] = _deposits[payee].add(tokenAmount);
        _depositsTime[payee] = block.timestamp;
        _totalShares = _totalShares.add(tokenAmount);
        super.addHolder(payee);
        emit StakeWin(payee, tokenAmount);
    }

    /**
     * @dev unfreeze amount Of tokens
     * @param tokenAmount amount of tokens to be freeze
     */
    function unfreeze(uint256 tokenAmount) public {
        address payee = msg.sender;
        require(depositsTime(payee) < block.timestamp.sub(24 hours), "SaleChainStaking: Unfreeze must after 1 hours");
        _deposits[payee] = _deposits[payee].sub(tokenAmount, "SaleChainStaking: Unfreeze amount exceeds balance");
        _token.transfer(payee, tokenAmount);
        _totalShares = _totalShares.sub(tokenAmount);
        if (_deposits[payee] == 0){
            super.removeHolder(payee);
        }
        emit Unfreeze(payee, tokenAmount);
    }

    /**
     * @dev Function to distribute Staking Fund
     * @return A boolean that indicates if the operation was successful.
     */
    function distributeFund() public payable{
        uint256 totalHolder = totalHolder();
        uint256 totalShares = totalShares();
        for(uint i = 0; i < totalHolder; i++){
            address payable account = address(uint160(holderByIndex(i)));
            uint256 amount = msg.value.mul(depositsOf(account)).div(totalShares);
            account.transfer(amount);
        }
        emit ReleaseFund(msg.sender, msg.value);
    }
}