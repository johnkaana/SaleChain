pragma solidity ^0.5.8;

import "openzeppelin-solidity/contracts/crowdsale/Crowdsale.sol";
import "openzeppelin-solidity/contracts/ownership/Ownable.sol";

contract MYToken {
    function mint(address account, uint256 amount) public returns (bool);
}

contract ParticipantEnumerable {
    // Mapping from account to the list of participants
    mapping(address => address[]) private _participants;

    // Mapping from participant to index of the account participants list
    mapping(address => uint256) private _participantsIndex;

    // Array with all participants, used for enumeration
    address[] private _allParticipants;

    // Mapping from participant to position in the allParticipants array
    mapping(address => uint256) private _allParticipantsIndex;

    // Mapping from account to parent participant
    mapping(address => address) private _parent;

    /**
     * @dev Getter the address of parent participant.
     */
    function parent(address account) public view returns (address) {
        return _parent[account];
    }

    /**
     * @dev Gets the participant at a given index of the participants list of the requested account.
     * @param account address the participants list
     * @param index uint256 representing the index of requested participants list
     * @return participant address at the given index of the participants list of requested address
     */
    function ParticipantOfAccountByIndex(address account, uint256 index) public view returns (address) {
        require(index < _participants[account].length, "ERC721Enumerable: account index out of bounds");
        return _participants[account][index];
    }

    /**
     * @dev Gets the total amount of participants stored by the contract.
     * @return uint256 representing the total amount of participants
     */
    function totalParticipant() public view returns (uint256) {
        return _allParticipants.length;
    }

    /**
     * @dev Gets the participant at a given index of all the participants in this contract
     * Reverts if the index is greater or equal to the total number of participants.
     * @param index uint256 representing the index of the participants list
     * @return participant address at the given index of the participants list
     */
    function participantByIndex(uint256 index) public view returns (address) {
        require(index < totalParticipant(), "ERC721Enumerable: global index out of bounds");
        return _allParticipants[index];
    }

    /**
     * @dev Gets the list of participants of the requested account.
     * @param account address of participant
     * @return address[] List of children of the requested account.
     */
    function participantsOfAccount(address account) public view returns (address[] memory) {
        return _participants[account];
    }

    /**
     * @dev Private function to add a participant to this extension's ownership-tracking data structures.
     * @param to address representing the new account of the given participant
     * @param participant address of the participant to be added to the participants list of the given address
     */
    function _addParticipant(address to, address participant) internal {
        _addParticipantToAccountEnumeration(to, participant);
        _addParticipantToAllParticipantsEnumeration(participant);
    }

    /**
     * @dev Private function to add a participant to this extension's ownership-tracking data structures.
     * @param to address representing the new account of the given participant
     * @param participant address of the participant to be added to the participants list of the given address
     */
    function _addParticipantToAccountEnumeration(address to, address participant) private {
        _participantsIndex[participant] = _participants[to].length;
        _participants[to].push(participant);
        _parent[participant] = to;
    }

    /**
     * @dev Private function to add a participant to this extension's participant tracking data structures.
     * @param participant address of the participant to be added to the participants list
     */
    function _addParticipantToAllParticipantsEnumeration(address participant) private {
        _allParticipantsIndex[participant] = _allParticipants.length;
        _allParticipants.push(participant);
    }

}

contract SaleChainCrowdsale is Crowdsale, ParticipantEnumerable, Ownable {
    using SafeMath for uint256;

    uint256 constant private SCH_RATE_500_10000 = 100;
    uint256 constant private SCH_RATE_10000_70000 = 103;
    uint256 constant private SCH_RATE_70000_300000 = 107;
    uint256 constant private SCH_RATE_300000_800000 = 114;
    uint256 constant private SCH_RATE_800000_up = 125;

    address private _lastParticipant;

    // Addresses where funds and token will be collected
    address payable private _stakingFundWallet;
    address payable private _teamFundWallet;
    address payable private _teamTokenWallet;

    uint256[] private _percentage = [22, 15, 10, 7, 5, 4, 3, 2, 1, 1];

    MYToken _myToken;
    // Mapping from account to amount of participant
    mapping(address => uint256) private _participantAmount;

    /**
     * @dev Getter for the amount of participant by an account.
     */
    function lastParticipant() public view returns (address) {
        return _lastParticipant;
    }

    /**
     * @dev Getter for the amount of participant by an account.
     */
    function participantAmount(address account) public view returns (uint256) {
        return _participantAmount[account];
    }

    constructor (uint256 rate, address payable teamWallet, address payable teamTokenWallet, address payable stakingFundWallet, address payable level2Wallet, IERC20 token, MYToken mintableToken)
        public Crowdsale(rate, teamWallet, token) {
        _myToken = mintableToken;
        _teamFundWallet = teamWallet;
        _teamTokenWallet = teamTokenWallet;
        _stakingFundWallet = stakingFundWallet;
        _addParticipant(address(0), msg.sender);
        _addParticipant(msg.sender, level2Wallet);
        _lastParticipant = level2Wallet;
    }

    /**
     * @return the address where staking funds will be collected.
     */
    function stakingFundWallet() public view returns (address payable) {
        return _stakingFundWallet;
    }

    /**
     * @return set the address where staking funds will be collected.
     */
    function setStakingFundWallet(address payable account) public onlyOwner {
        require(account != address(0), "StakingFund wallet is the zero address");
        _stakingFundWallet = account;
    }

    /**
     * @return the address where team funds will be collected.
     */
    function teamFundWallet() public view returns (address payable) {
        return _teamFundWallet;
    }

    /**
     * @return set the address where team funds will be collected.
     */
    function setTeamFundWallet(address payable account) public onlyOwner {
        require(account != address(0), "Owner wallet is the zero address");
        _teamFundWallet = account;
    }

    /**
     * @return the address where team tokens will be collected.
     */
    function teamTokenWallet() public view returns (address payable) {
        return _teamTokenWallet;
    }

    /**
     * @return set the address where team tokens will be collected.
     */
    function setTeamTokenWallet(address payable account) public onlyOwner {
        require(account != address(0), "Owner wallet is the zero address");
        _teamTokenWallet = account;
    }

     /**
     * @dev This function to purchase via reffral account
     * @param beneficiary Recipient of the token purchase
     * @param referAccount Refer purchaser to purchase token
     */
    function buyTokensWithRefer(address beneficiary, address referAccount) public payable {
        if (parent(beneficiary) == address(0)){
            _lastParticipant = referAccount;
        }
        buyTokens(beneficiary);
    }

    /**
     * @dev Overrides function in the Crowdsale contract to revert contributions less than
     *      50 TRX during the first period and less than 500 trx during the rest of the crowdsale
     * @param beneficiary Address performing the token purchase
     * @param weiAmount Value in sun involved in the purchase
     */
    function _preValidatePurchase(address beneficiary, uint256 weiAmount) internal view {
        super._preValidatePurchase(beneficiary, weiAmount);
        require(weiAmount >= 500000000, "Not enough trx. Contributions must be at least 500 trx during the crowdsale");
        require(_lastParticipant != beneficiary || parent(beneficiary) != address(0), "beneficiary Contributions can't refer to self");
        require(parent(_lastParticipant) != address(0), "beneficiary Contributions can't refer to self");
    }

    /**
     * @dev Overrides function in the Crowdsale contract to enable a custom phased distribution
     * @param weiAmount Value in sun to be converted into tokens
     * @return Number of tokens that can be purchased with the specified sun amount
     */
    function _getTokenAmount(uint256 weiAmount) internal view returns (uint256) {
        if (weiAmount >= 800000000000) {
            return weiAmount.div(1000).mul(SCH_RATE_800000_up);
        } else if (weiAmount >= 300000000000) {
            return weiAmount.div(1000).mul(SCH_RATE_300000_800000);
        } else if (weiAmount >= 70000000000) {
            return weiAmount.div(1000).mul(SCH_RATE_70000_300000);
        } else if (weiAmount >= 10000000000) {
            return weiAmount.div(1000).mul(SCH_RATE_10000_70000);
        } else {
            return weiAmount.div(1000).mul(SCH_RATE_500_10000);
        }
    }

    /**
     * @dev Overrides function in the Crowdsale contract to add functionality for distribution.
     * @param beneficiary Token purchaser
     * @param tokenAmount Amount of tokens purchased
     */
    function _deliverTokens(address beneficiary, uint256 tokenAmount) internal {
        _myToken.mint(beneficiary, tokenAmount);
        _myToken.mint(_teamTokenWallet, tokenAmount.mul(5).div(95));
    }

    /**
     * @dev Determines how TRX is stored/forwarded on purchases.
     */
    function _forwardFunds() internal {
        uint256 amount = msg.value;
        uint256 relased = 0;
        uint256 levelNo = 0;
        uint256 value = 0;
        address payable ParticipantWallet = address(uint160(parent(_lastParticipant)));

        while(ParticipantWallet != address(0) && levelNo < 10){
            value = amount.mul(_percentage[levelNo]).div(100);
            relased = relased.add(value);
            ParticipantWallet.transfer(value);
            ParticipantWallet = address(uint160(parent(ParticipantWallet)));
            levelNo = levelNo.add(1);
        }

        value = amount.mul(20).div(100);
        _stakingFundWallet.transfer(value);
        relased = relased.add(value);

        amount = amount.sub(relased);
        _teamFundWallet.transfer(amount);
    }

    /**
     * @dev Override for extensions that require an internal state to check for validity (current user contributions,
     * etc.)
     * @param beneficiary Address receiving the tokens
     * @param weiAmount Value in sun involved in the purchase
     */
    function _updatePurchasingState(address beneficiary, uint256 weiAmount) internal {
        if (parent(beneficiary) == address(0)){
            _addParticipant(_lastParticipant, beneficiary);
            _lastParticipant = beneficiary;
        }
        _participantAmount[beneficiary] = _participantAmount[beneficiary].add(weiAmount);
    }
}
