// EW - версия компилятора не зафиксирована
// EW Ok
pragma solidity ^0.4.20;

/**
 * @title SafeMath
 * @dev Math operations with safety checks that throw on error
 */
// EW - Could use `require(...)` instead of `assert(...)` to save of gas in the case of an error
// EW Ok
library SafeMath {
    // EW Ok
    function mul(uint256 a, uint256 b) internal pure returns (uint256) {
        // EW Ok
        if (a == 0) {
            // EW Ok
            return 0;
        }
        // EW Ok
        uint256 c = a * b;
        // EW Ok
        assert(c / a == b);
        // EW Ok
        return c;
    }

    // EW Ok
    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        // assert(b > 0); // Solidity automatically throws when dividing by 0
        // EW Ok
        uint256 c = a / b;
        // assert(a == b * c + a % b); // There is no case in which this doesn't hold
        // EW Ok
        return c;
    }

    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        // EW Ok
        assert(b <= a);
        // EW Ok
        return a - b;
    }

    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        // EW Ok
        uint256 c = a + b;
        // EW Ok
        assert(c >= a);
        // EW Ok
        return c;
    }
}

/**
 * @title ERC20Basic
 * @dev Simpler version of ERC20 interface
 * @dev see https://github.com/ethereum/EIPs/issues/179
 */
// EW Ok
contract ERC20Basic {
    // EW Ok
    uint256 public totalSupply;
    // EW Ok
    function balanceOf(address who) public view returns (uint256);
    // EW Ok
    function transfer(address to, uint256 value) public returns (bool);
    // EW Ok
    event Transfer(address indexed from, address indexed to, uint256 value);
}


/**
 * @title ERC20 interface
 * @dev see https://github.com/ethereum/EIPs/issues/20
 */
// EW Ok
contract ERC20 is ERC20Basic {
    // EW Ok
    function allowance(address owner, address spender) public view returns (uint256);
    // EW Ok
    function transferFrom(address from, address to, uint256 value) public returns (bool);
    // EW Ok
    function approve(address spender, uint256 value) public returns (bool);
    // EW Ok
    event Approval(address indexed owner, address indexed spender, uint256 value);
}

// EW - Could use `require(...)` instead of `assert(...)` to save of gas in the case of an error
// EW Ok
contract ShortAddressProtection {
    // EW Ok
    modifier onlyPayloadSize(uint256 numwords) {
        // EW Ok
        assert(msg.data.length >= numwords * 32 + 4);
        // EW Ok
        _;
    }
}

/**
 * @title Basic token
 * @dev Basic version of StandardToken, with no allowances.
 */
// EW Ok
contract BasicToken is ERC20Basic, ShortAddressProtection {
    // EW Ok
    using SafeMath for uint256;
    // EW Ok
    mapping(address => uint256) internal balances;

    /**
    * @dev transfer token for a specified address
    * @param _to The address to transfer to.
    * @param _value The amount to be transferred.
    */
    // EW Ok
    function transfer(address _to, uint256 _value) onlyPayloadSize(2) public returns (bool) {
        // EW Ok
        require(_to != address(0));
        // EW Ok
        require(_value <= balances[msg.sender]);

        // SafeMath.sub will throw if there is not enough balance.
        // EW Ok
        balances[msg.sender] = balances[msg.sender].sub(_value);
        // EW Ok
        balances[_to] = balances[_to].add(_value);
        // EW Ok
        Transfer(msg.sender, _to, _value);
        // EW Ok
        return true;
    }

    /**
    * @dev Gets the balance of the specified address.
    * @param _owner The address to query the the balance of.
    * @return An uint256 representing the amount owned by the passed address.
    */
    // EW Ok
    function balanceOf(address _owner) public view returns (uint256 balance) {
        // EW Ok
        return balances[_owner];
    }

}

/**
 * @title Standard ERC20 token
 *
 * @dev Implementation of the basic standard token.
 * @dev https://github.com/ethereum/EIPs/issues/20
 * @dev Based on code by FirstBlood: https://github.com/Firstbloodio/token/blob/master/smart_contract/FirstBloodToken.sol
 */
// EW Ok
contract StandardToken is ERC20, BasicToken {

    // EW Ok
    mapping(address => mapping(address => uint256)) internal allowed;


    /**
     * @dev Transfer tokens from one address to another
     * @param _from address The address which you want to send tokens from
     * @param _to address The address which you want to transfer to
     * @param _value uint256 the amount of tokens to be transferred
     */
    // EW Ok
    function transferFrom(address _from, address _to, uint256 _value) onlyPayloadSize(3) public returns (bool) {
        // EW Ok
        require(_to != address(0));
        // EW Ok
        require(_value <= balances[_from]);
        // EW Ok
        require(_value <= allowed[_from][msg.sender]);

        // EW Ok
        balances[_from] = balances[_from].sub(_value);
        // EW Ok
        balances[_to] = balances[_to].add(_value);
        // EW Ok
        allowed[_from][msg.sender] = allowed[_from][msg.sender].sub(_value);
        // EW Ok
        Transfer(_from, _to, _value);
        // EW Ok
        return true;
    }

    /**
     * @dev Approve the passed address to spend the specified amount of tokens on behalf of msg.sender.
     *
     * Beware that changing an allowance with this method brings the risk that someone may use both the old
     * and the new allowance by unfortunate transaction ordering. One possible solution to mitigate this
     * race condition is to first reduce the spender's allowance to 0 and set the desired value afterwards:
     * https://github.com/ethereum/EIPs/issues/20#issuecomment-263524729
     * @param _spender The address which will spend the funds.
     * @param _value The amount of tokens to be spent.
     */
    // EW Ok
    function approve(address _spender, uint256 _value) onlyPayloadSize(2) public returns (bool) {
        //require user to set to zero before resetting to nonzero
        // EW Ok
        require((_value == 0) || (allowed[msg.sender][_spender] == 0));
        // EW Ok
        allowed[msg.sender][_spender] = _value;
        // EW Ok
        Approval(msg.sender, _spender, _value);
        // EW Ok
        return true;
    }

    /**
     * @dev Function to check the amount of tokens that an owner allowed to a spender.
     * @param _owner address The address which owns the funds.
     * @param _spender address The address which will spend the funds.
     * @return A uint256 specifying the amount of tokens still available for the spender.
     */
    // EW Ok
    function allowance(address _owner, address _spender) public view returns (uint256) {
        // EW Ok
        return allowed[_owner][_spender];
    }

    /**
     * @dev Increase the amount of tokens that an owner allowed to a spender.
     *
     * approve should be called when allowed[_spender] == 0. To increment
     * allowed value is better to use this function to avoid 2 calls (and wait until
     * the first transaction is mined)
     * From MonolithDAO Token.sol
     * @param _spender The address which will spend the funds.
     * @param _addedValue The amount of tokens to increase the allowance by.
     */
    // EW Ok
    function increaseApproval(address _spender, uint _addedValue) onlyPayloadSize(2) public returns (bool) {
        // EW Ok
        allowed[msg.sender][_spender] = allowed[msg.sender][_spender].add(_addedValue);
        // EW Ok
        Approval(msg.sender, _spender, allowed[msg.sender][_spender]);
        // EW Ok
        return true;
    }

    /**
     * @dev Decrease the amount of tokens that an owner allowed to a spender.
     *
     * approve should be called when allowed[_spender] == 0. To decrement
     * allowed value is better to use this function to avoid 2 calls (and wait until
     * the first transaction is mined)
     * From MonolithDAO Token.sol
     * @param _spender The address which will spend the funds.
     * @param _subtractedValue The amount of tokens to decrease the allowance by.
     */
    // EW Ok
    function decreaseApproval(address _spender, uint _subtractedValue) onlyPayloadSize(2) public returns (bool) {
        // EW Ok
        uint oldValue = allowed[msg.sender][_spender];
        // EW Ok
        if (_subtractedValue > oldValue) {
            // EW Ok
            allowed[msg.sender][_spender] = 0;
            // EW Ok
        } else {
            // EW Ok
            allowed[msg.sender][_spender] = oldValue.sub(_subtractedValue);
        }
        // EW Ok
        Approval(msg.sender, _spender, allowed[msg.sender][_spender]);
        // EW Ok
        return true;
    }
}

// EW Ok
contract Ownable {
    // EW Ok
    address public owner;
    // EW Ok
    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);


    /**
     * @dev The Ownable constructor sets the original `owner` of the contract to the sender
     * account.
     */
    // EW Ok
    function Ownable() public {
        // EW Ok
        owner = msg.sender;
    }

    /**
     * @dev Throws if called by any account other than the owner.
     */
    // EW Ok
    modifier onlyOwner() {
        // EW Ok
        require(msg.sender == owner);
        // EW Ok
        _;
    }

    /**
     * @dev Allows the current owner to transfer control of the contract to a newOwner.
     * @param newOwner The address to transfer ownership to.
     */
    // EW - Only owner can execute
    // EW Ok
    function transferOwnership(address newOwner) public onlyOwner {
        // EW Ok
        require(newOwner != address(0));
        // EW - first you need to change the owner, and then announce the event
        // EW Ok
        OwnershipTransferred(owner, newOwner);
        // EW Ok
        owner = newOwner;
    }
}

/**
 * @title MintableToken token
 */
// EW Ok
contract MintableToken is Ownable, StandardToken {

    // EW Ok
    event Mint(address indexed to, uint256 amount);
    // EW Ok
    event MintFinished();
    // EW Ok
    bool public mintingFinished = false;
    // EW Ok
    address public saleAgent;
    // EW Ok
    modifier canMint() {
        require(!mintingFinished);
        _;
    }
    // EW Ok
    modifier onlySaleAgent() {
        require(msg.sender == saleAgent);
        _;
    }
    // EW Ok
    function setSaleAgent(address _saleAgent) onlyOwner public {
        // EW Ok
        require(_saleAgent != address(0));
        // EW Ok
        saleAgent = _saleAgent;
    }

    /**
     * @dev Function to mint tokens
     * @param _to The address that will receive the minted tokens.
     * @param _amount The amount of tokens to mint.
     * @return A boolean that indicates if the operation was successful.
     */
    // EW Ok
    function mint(address _to, uint256 _amount) onlySaleAgent canMint public returns (bool) {
        // EW Ok
        totalSupply = totalSupply.add(_amount);
        // EW Ok
        balances[_to] = balances[_to].add(_amount);
        // EW Ok
        Mint(_to, _amount);
        // EW Ok
        Transfer(address(0), _to, _amount);
        // EW Ok
        return true;
    }

    /**
     * @dev Function to stop minting new tokens.
     * @return True if the operation was successful.
     */
    // EW Ok
    function finishMinting() onlySaleAgent canMint public returns (bool) {
        // EW Ok
        mintingFinished = true;
        // EW Ok
        MintFinished();
        // EW Ok
        return true;
    }
}

// EW Ok
contract Token is MintableToken {
    // EW Ok
    string public constant name = "TOKPIE";
    // EW Ok
    string public constant symbol = "TKP";
    // EW Ok
    uint8 public constant decimals = 18;
}

/**
 * @title Pausable
 * @dev Base contract which allows children to implement an emergency stop mechanism.
 */
// EW - only owner can change the pause state
// EW Ok
contract Pausable is Ownable {
    // EW Ok
    event Pause();
    // EW Ok
    event Unpause();
    // EW Ok
    bool public paused = false;


    /**
     * @dev Modifier to make a function callable only when the contract is not paused.
     */
    // EW Ok
    modifier whenNotPaused() {
        // EW Ok
        require(!paused);
        // EW Ok
        _;
    }

    /**
     * @dev Modifier to make a function callable only when the contract is paused.
     */
    // EW Ok
    modifier whenPaused() {
        // EW Ok
        require(paused);
        // EW Ok
        _;
    }

    /**
     * @dev called by the owner to pause, triggers stopped state
     */
    // EW Ok
    function pause() onlyOwner whenNotPaused public {
        // EW Ok
        paused = true;
        // EW Ok
        Pause();
    }

    /**
     * @dev called by the owner to unpause, returns to normal state
     */
    // EW Ok
    function unpause() onlyOwner whenPaused public {
        // EW Ok
        paused = false;
        // EW Ok
        Unpause();
    }
}

/**
 * @title WhitelistedCrowdsale
 * @dev Crowdsale in which only whitelisted users can contribute.
 */
// EW Ok
contract WhitelistedCrowdsale is Ownable {
    // EW Ok
    mapping(address => bool) public whitelist;

    /**
     * @dev Reverts if beneficiary is not whitelisted. Can be used when extending this contract.
     */
    // EW Ok
    modifier isWhitelisted(address _beneficiary) {
        // EW Ok
        require(whitelist[_beneficiary]);
        _;
    }

    /**
     * @dev Adds single address to whitelist.
     * @param _beneficiary Address to be added to the whitelist
     */
    // EW Ok
    function addToWhitelist(address _beneficiary) external onlyOwner {
        // EW Ok
        whitelist[_beneficiary] = true;
    }

    /**
     * @dev Adds list of addresses to whitelist. Not overloaded due to limitations with truffle testing.
     * @param _beneficiaries Addresses to be added to the whitelist
     */
    // EW Ok
    function addManyToWhitelist(address[] _beneficiaries) external onlyOwner {
        // EW Ok
        for (uint256 i = 0; i < _beneficiaries.length; i++) {
            // EW Ok
            whitelist[_beneficiaries[i]] = true;
        }
    }
}

/**
 * @title FinalizableCrowdsale
 * @dev Extension of Crowdsale where an owner can do extra work
 * after finishing.
 */
// EW Ok
contract FinalizableCrowdsale is Pausable {
    // EW Ok
    using SafeMath for uint256;
    // EW Ok
    bool public isFinalized = false;
    // EW Ok
    event Finalized();

    /**
     * @dev Must be called after crowdsale ends, to do some extra finalization
     * work. Calls the contract's finalization function.
     */
    // EW Ok
    function finalize() onlyOwner public {
        // EW Ok
        require(!isFinalized);
        // EW Ok
        finalization();
        // EW Ok
        Finalized();
        // EW Ok
        isFinalized = true;
    }

    /**
     * @dev Can be overridden to add finalization logic. The overriding function
     * should call super.finalization() to ensure the chain of finalization is
     * executed entirely.
     */
    // EW Ok
    function finalization() internal;
}

/**
 * @title RefundVault
 * @dev This contract is used for storing funds while a crowdsale
 * is in progress. Supports refunding the money if crowdsale fails,
 * and forwarding it if crowdsale is successful.
 */
// EW Ok
contract RefundVault is Ownable {
    // EW Ok
    using SafeMath for uint256;
    // EW Ok
    enum State {Active, Refunding, Closed}
    // EW Ok
    mapping(address => uint256) public deposited;
    // EW Ok
    address public wallet;
    // EW Ok
    State public state;
    // EW Ok
    event Closed();
    // EW Ok
    event RefundsEnabled();
    // EW Ok
    event Refunded(address indexed beneficiary, uint256 weiAmount);

    /**
     * @param _wallet Vault address
     */
    // EW Ok
    function RefundVault(address _wallet) public {
        // EW Ok
        require(_wallet != address(0));
        // EW Ok
        wallet = _wallet;
        // EW Ok
        state = State.Active;
    }

    /**
     * @param investor Investor address
     */
    // EW Ok
    function deposit(address investor) onlyOwner public payable {
        // EW Ok
        require(state == State.Active);
        // EW Ok
        deposited[investor] = deposited[investor].add(msg.value);
    }
    // EW Ok
    function close() onlyOwner public {
        // EW Ok
        require(state == State.Active);
        // EW Ok
        state = State.Closed;
        // EW Ok
        Closed();
        // EW Ok
        wallet.transfer(this.balance);
    }

    // EW Ok
    function enableRefunds() onlyOwner public {
        // EW Ok
        require(state == State.Active);
        // EW Ok
        state = State.Refunding;
        // EW Ok
        RefundsEnabled();
    }

    /**
     * @param investor Investor address
     */
    // EW Ok
    function refund(address investor) public {
        // EW Ok
        require(state == State.Refunding);
        // EW Ok
        uint256 depositedValue = deposited[investor];
        // EW Ok
        deposited[investor] = 0;
        // EW Ok
        investor.transfer(depositedValue);
        // EW Ok
        Refunded(investor, depositedValue);
    }
}

// EW Ok
contract preICO is FinalizableCrowdsal, WhitelistedCrowdsale {
    // EW Ok
    Token public token;

    // May 01, 2018 @ UTC 0:01
    // EW Ok
    uint256 public startDate;

    // May 14, 2018 @ UTC 23:59
    // EW Ok
    uint256 public endDate;

    // amount of raised money in wei

    uint256 public weiRaised;

    // how many token units a buyer gets per wei
    // EW Ok
    uint256 public constant rate = 1920;
    // EW Ok
    uint256 public constant softCap = 500 * (1 ether);
    // EW Ok
    uint256 public constant hardCap = 1000 * (1 ether);

    // refund vault used to hold funds while crowdsale is running
    // EW Ok
    RefundVault public vault;

    /**
     * event for token purchase logging
     * @param purchaser who paid for the tokens
     * @param beneficiary who got the tokens
     * @param value weis paid for purchase
     * @param amount amount of tokens purchased
     */
    // EW Ok
    event TokenPurchase(address indexed purchaser, address indexed beneficiary, uint256 value, uint256 amount);

    /**
     * @dev _wallet where collect funds during crowdsale
     * @dev _startDate should be 1525132860
     * @dev _endDate should be 1526342340
     * @dev _maxEtherPerInvestor should be 10 ether
     */
    // EW Ok
    function preICO(address _token, address _wallet, uint256 _startDate, uint256 _endDate) public {
        // EW Ok
        require(_token != address(0) && _wallet != address(0));
        // EW Ok
        require(_endDate > _startDate);
        // EW Ok
        startDate = _startDate;
        // EW Ok
        endDate = _endDate;
        // EW Ok
        token = Token(_token);
        // EW preICO contract is owner of vault
        // EW Ok
        vault = new RefundVault(_wallet);
    }

    /**
     * @dev Investors can claim refunds here if crowdsale is unsuccessful
     */
    // EW Ok
    function claimRefund() public {
        // EW Ok
        require(isFinalized);
        // EW Ok
        require(!goalReached());
        // EW Ok
        vault.refund(msg.sender);
    }

    /**
     * @dev Checks whether funding goal was reached.
     * @return Whether funding goal was reached
     */
    // EW Ok
    function goalReached() public view returns (bool) {
        // EW Ok
        return weiRaised >= softCap;
    }

    /**
     * @dev vault finalization task, called when owner calls finalize()
     */
    // EW Ok
    function finalization() internal {
        // EW Ok
        require(hasEnded());
        // EW Ok
        if (goalReached()) {
            // EW all funds from vault goes to wallet address
            // EW Ok
            vault.close();
            // EW Ok
        } else {
            // EW Ok
            vault.enableRefunds();
        }
    }

    // fallback function can be used to buy tokens
    // EW Ok
    function() external payable {
        // EW Ok
        buyTokens(msg.sender);
    }

    // low level token purchase function
    // EW Ok
    function buyTokens(address beneficiary) whenNotPaused isWhitelisted(beneficiary) isWhitelisted(msg.sender) public payable {
        // EW Ok
        require(beneficiary != address(0));
        // EW Ok
        require(validPurchase());
        // EW Ok
        require(!hasEnded());
        // EW Ok
        uint256 weiAmount = msg.value;

        // calculate token amount to be created
        // EW Ok
        uint256 tokens = weiAmount.mul(rate);

        // Minimum contribution level in TKP tokens for each investor = 100 TKP
        // EW Ok
        require(tokens >= 100 * (10 ** 18));

        // update state
        // EW Ok
        weiRaised = weiRaised.add(weiAmount);
        // EW Ok
        token.mint(beneficiary, tokens);
        // EW Ok
        TokenPurchase(msg.sender, beneficiary, weiAmount, tokens);
        // EW Ok
        forwardFunds();
    }

    // send ether to the fund collection wallet
    // EW Ok
    function forwardFunds() internal {
        // EW Ok
        vault.deposit.value(msg.value)(msg.sender);
    }

    // @return true if the transaction can buy tokens
    // EW Ok
    function validPurchase() internal view returns (bool) {
        // EW Ok
        return !isFinalized && now >= startDate && msg.value != 0;
    }

    // @return true if crowdsale event has ended
    // EW Ok
    function hasEnded() public view returns (bool) {
        // EW Ok
        return (now > endDate || weiRaised >= hardCap);
    }
}


// EW Ok
contract ICO is Pausable, WhitelistedCrowdsale {
    // EW Ok
    using SafeMath for uint256;
    // EW Ok
    Token public token;

    // June 01, 2018 @ UTC 0:01
    // EW Ok
    uint256 public startDate;

    // July 05, 2018 on UTC 23:59
    // EW Ok
    uint256 public endDate;
    // EW Ok
    uint256 public hardCap;

    // amount of raised money in wei
    // EW Ok
    uint256 public weiRaised;
    // EW Ok
    address public wallet;
    // EW - redundant
    // EW Ok
    mapping(address => uint256) public deposited;

    /**
     * event for token purchase logging
     * @param purchaser who paid for the tokens
     * @param beneficiary who got the tokens
     * @param value weis paid for purchase
     * @param amount amount of tokens purchased
     */
    // EW Ok
    event TokenPurchase(address indexed purchaser, address indexed beneficiary, uint256 value, uint256 amount);

    /**
     * @dev _wallet where collect funds during crowdsale
     * @dev _startDate should be 1527811260
     * @dev _endDate should be 1530835140
     * @dev _maxEtherPerInvestor should be 10 ether
     * @dev _hardCap should be 8700 ether
     */
    function ICO(address _token, address _wallet, uint256 _startDate, uint256 _endDate, uint256 _hardCap) public {
        // EW Ok
        require(_token != address(0) && _wallet != address(0));
        // EW Ok
        require(_endDate > _startDate);
        // EW Ok
        require(_hardCap > 0);
        // EW Ok
        startDate = _startDate;
        // EW Ok
        endDate = _endDate;
        // EW Ok
        hardCap = _hardCap;
        // EW Ok
        token = Token(_token);
        // EW Ok
        wallet = _wallet;
    }

    // EW Ok
    function claimFunds() onlyOwner public {
        // EW Ok
        require(hasEnded());
        // EW Ok
        wallet.transfer(this.balance);
    }

    // EW Ok
    function getRate() public view returns (uint256) {
        // EW Ok
        if (now < startDate || hasEnded()) return 0;

        // Period: from June 01, 2018 @ UTC 0:01 to June 7, 2018 @ UTC 23:59; Price: 1 ETH = 1840 TKP
        // EW - period not equal to full 7 days (=10078 minutes =6.998611 days)
        // EW Ok
        if (now >= startDate && now < startDate + 604680) return 1840;
        // EW Ok
        // Period: from June 08, 2018 @ UTC 0:00 to June 14, 2018 @ UTC 23:59; Price: 1 ETH = 1760 TKP
        // EW - period not equal to full 7 days (=10078 minutes =6.998611 days)
        // EW Ok
        if (now >= startDate + 604680 && now < startDate + 1209480) return 1760;
        // EW Ok
        // Period: from June 15, 2018 @ UTC 0:00 to June 21, 2018 @ UTC 23:59; Price: 1 ETH = 1680 TKP
        // EW - period not equal to full 7 days (=10078 minutes =6.998611 days)
        // EW Ok
        if (now >= startDate + 1209480 && now < startDate + 1814280) return 1680;
        // EW - period not equal to full 7 days (=10078 minutes =6.998611 days)
        // EW Ok
        // Period: from June 22, 2018 @ UTC 0:00 to June 28, 2018 @ UTC 23:59; Price: 1 ETH = 1648 TKP
        // EW - period not equal to full 7 days (=10078 minutes =6.998611 days)
        // EW Ok
        if (now >= startDate + 1814280 && now < startDate + 2419080) return 1648;
        // EW Ok
        // Period: from June 29, 2018 @ UTC 0:00 to July 5, 2018 @ UTC 23:59; Price: 1 ETH = 1600 TKP
        if (now >= startDate + 2419080) return 1600;
    }

    // fallback function can be used to buy tokens
    // EW Ok
    function() external payable {
        // EW Ok
        buyTokens(msg.sender);
    }

    // low level token purchase function
    // EW Ok
    function buyTokens(address beneficiary) whenNotPaused isWhitelisted(beneficiary) isWhitelisted(msg.sender) public payable {
        // EW Ok
        require(beneficiary != address(0));
        // EW Ok
        require(validPurchase());
        // EW Ok
        require(!hasEnded());
        // EW Ok
        uint256 weiAmount = msg.value;

        // calculate token amount to be created
        // EW Ok
        uint256 tokens = weiAmount.mul(getRate());

        // Minimum contribution level in TKP tokens for each investor = 100 TKP
        // EW Ok
        require(tokens >= 100 * (10 ** 18));

        // update state
        // EW Ok
        weiRaised = weiRaised.add(weiAmount);
        // EW Ok
        token.mint(beneficiary, tokens);
        // EW Ok
        TokenPurchase(msg.sender, beneficiary, weiAmount, tokens);
    }

    // @return true if the transaction can buy tokens
    // EW Ok
    function validPurchase() internal view returns (bool) {
        // EW Ok
        return now >= startDate && msg.value != 0;
    }

    // @return true if crowdsale event has ended
    // EW Ok
    function hasEnded() public view returns (bool) {
        // EW Ok
        return (now > endDate || weiRaised >= hardCap);
    }
}

contract postICO is Ownable {
    // EW Ok
    using SafeMath for uint256;
    // EW Ok
    Token public token;

    // EW Ok
    address public walletE;
    // EW Ok
    address public walletB;
    // EW Ok
    address public walletC;
    // EW Ok
    address public walletF;
    // EW Ok
    address public walletG;

    // 05.07.18 @ UTC 23:59
    // EW Ok
    uint256 public endICODate;
    // EW Ok
    bool public finished = false;
    // EW Ok
    uint256 public FTST;

    // Save complete of transfers (due to schedule) to these wallets
    // EW Ok
    mapping(uint8 => bool) completedE;
    // EW Ok
    mapping(uint8 => bool) completedBC;
    // EW Ok
    uint256 public paymentSizeE;
    // EW Ok
    uint256 public paymentSizeB;
    // EW Ok
    uint256 public paymentSizeC;

    /**
     * @dev _endICODate should be 1530835140
     */
    // EW Ok
    function postICO(
        address _token,
        address _walletE,
        address _walletB,
        address _walletC,
        address _walletF,
        address _walletG,
        uint256 _endICODate
    ) public {
        // EW Ok
        require(_token != address(0));
        // EW Ok
        require(_walletE != address(0));
        // EW Ok
        require(_walletB != address(0));
        // EW Ok
        require(_walletC != address(0));
        // EW Ok
        require(_walletF != address(0));
        // EW Ok
        require(_walletG != address(0));
        // EW Ok
        require(_endICODate >= now);
        // EW Ok
        token = Token(_token);
        // EW Ok
        endICODate = _endICODate;
        // EW Ok
        walletE = _walletE;
        // EW Ok
        walletB = _walletB;
        // EW Ok
        walletC = _walletC;
        // EW Ok
        walletF = _walletF;
        // EW Ok
        walletG = _walletG;
    }

    function finish() onlyOwner public {
        // EW Ok
        require(now > endICODate);
        // EW Ok
        require(!finished);
        require(token.saleAgent() == address(this));
        // EW Ok
        FTST = token.totalSupply().mul(100).div(65);

        // post ICO token allocation: 35% of final total supply of tokens (FTST) will be distributed to the wallets E, B, C, F, G due to the schedule described below. Where FTST = the number of tokens sold during crowdsale x 100 / 65.
        // Growth reserve: 21% (4-years lock). Distribute 2.625% of the final total supply of tokens (FTST*2625/100000) 8 (eight) times every half a year during 4 (four) years after the endICODate to the wallet [E].
        // hold this tokens on postICO contract
        // EW Ok
        paymentSizeE = FTST.mul(2625).div(100000);
        // EW Ok
        uint256 tokensE = paymentSizeE.mul(8);
        // EW Ok
        token.mint(this, tokensE);

        // Team: 9.6% (2-years lock).
        // Distribute 0.25% of final total supply of tokens (FTST*25/10000) 4 (four) times every half a year during 2 (two) years after endICODate to the wallet [B].
        // hold this tokens on postICO contract
        // EW Ok
        paymentSizeB = FTST.mul(25).div(10000);
        // EW Ok
        uint256 tokensB = paymentSizeB.mul(4);
        // EW Ok
        token.mint(this, tokensB);

        // Distribute 2.15% of final total supply of tokens (FTST*215/10000) 4 (four) times every half a year during 2 (two) years after endICODate to the wallet [C].
        // hold this tokens on postICO contract
        // EW Ok
        paymentSizeC = FTST.mul(215).div(10000);
        // EW Ok
        uint256 tokensC = paymentSizeC.mul(4);
        // EW Ok
        token.mint(this, tokensC);

        // Angel investors: 2%. Distribute 2% of final total supply of tokens (FTST*2/100) after endICODate to the wallet [F].
        // EW Ok
        uint256 tokensF = FTST.mul(2).div(100);
        // EW Ok
        token.mint(walletF, tokensF);

        // Referral program 1,3% + Bounty program: 1,1%. Distribute 2,4% of final total supply of tokens (FTST*24/1000) after endICODate to the wallet [G].
        // EW Ok
        uint256 tokensG = FTST.mul(24).div(1000);
        // EW Ok
        token.mint(walletG, tokensG);

        // EW Ok
        token.finishMinting();
        // EW Ok
        finished = true;
    }

    // EW Ok
    function claimTokensE(uint8 order) onlyOwner public {
        // EW Ok
        require(finished);
        // EW Ok
        require(order >= 1 && order <= 8);
        // EW Ok
        require(!completedE[order]);

        // On January 03, 2019 @ UTC 23:59 = FTST*2625/100000 (2.625% of final total supply of tokens) to the wallet [E].
        // EW Ok
        if (order == 1) {
            // Thursday, 3 January 2019 г., 23:59:00
            // EW Ok
            require(now >= endICODate + 15724800);
            // EW Ok
            token.transfer(walletE, paymentSizeE);
            // EW Ok
            completedE[order] = true;
        }
        // On July 05, 2019 @ UTC 23:59 = FTST*2625/100000 (2.625% of final total supply of tokens) to the wallet [E].
        // EW Ok
        if (order == 2) {
            // Friday, 5 July 2019 г., 23:59:00
            // EW Ok
            require(now >= endICODate + 31536000);
            // EW Ok
            token.transfer(walletE, paymentSizeE);
            // EW Ok
            completedE[order] = true;
        }
        // On January 03, 2020 @ UTC 23:59 = FTST*2625/100000 (2.625% of final total supply of tokens) to the wallet [E].
        // EW Ok
        if (order == 3) {
            // Friday, 3 January 2020 г., 23:59:00
            // EW Ok
            require(now >= endICODate + 47260800);
            // EW Ok
            token.transfer(walletE, paymentSizeE);
            // EW Ok
            completedE[order] = true;
        }
        // On July 04, 2020 @ UTC 23:59 = FTST*2625/100000 (2.625% of final total supply of tokens) to the wallet [E].
        // EW Ok
        if (order == 4) {
            // Saturday, 4 July 2020 г., 23:59:00
            // EW Ok
            require(now >= endICODate + 63072000);
            // EW Ok
            token.transfer(walletE, paymentSizeE);
            // EW Ok
            completedE[order] = true;
        }
        // On January 02, 2021 @ UTC 23:59 = FTST*2625/100000 (2.625% of final total supply of tokens) to the wallet [E].
        // EW Ok
        if (order == 5) {
            // Saturday, 2 January 2021 г., 23:59:00
            // EW Ok
            require(now >= endICODate + 78796800);
            // EW Ok
            token.transfer(walletE, paymentSizeE);
            // EW Ok
            completedE[order] = true;
        }
        // On July 04, 2021 @ UTC 23:59 = FTST*2625/100000 (2.625% of final total supply of tokens) to the wallet [E].
        // EW Ok
        if (order == 6) {
            // Sunday, 4 July 2021 г., 23:59:00
            // EW Ok
            require(now >= endICODate + 94608000);
            // EW Ok
            token.transfer(walletE, paymentSizeE);
            // EW Ok
            completedE[order] = true;
        }
        // On January 02, 2022 @ UTC 23:59 = FTST*2625/100000 (2.625% of final total supply of tokens) to the wallet [E].
        // EW Ok
        if (order == 7) {
            // Sunday, 2 January 2022 г., 23:59:00
            // EW Ok
            require(now >= endICODate + 110332800);
            // EW Ok
            token.transfer(walletE, paymentSizeE);
            // EW Ok
            completedE[order] = true;
        }
        // On July 04, 2022@ UTC 23:59 = FTST*2625/100000 (2.625% of final total supply of tokens) to the wallet [E].
        // EW Ok
        if (order == 8) {
            // Monday, 4 July 2022 г., 23:59:00
            // EW Ok
            require(now >= endICODate + 126144000);
            // EW Ok
            token.transfer(walletE, paymentSizeE);
            // EW Ok
            completedE[order] = true;
        }
    }
    // EW Ok
    function claimTokensBC(uint8 order) onlyOwner public {
        // EW Ok
        require(finished);
        // EW Ok
        require(order >= 1 && order <= 4);
        // EW Ok
        require(!completedBC[order]);

        // On January 03, 2019 @ UTC 23:59 = FTST*25/10000 (0.25% of final total supply of tokens) to the wallet [B] and FTST*215/10000 (2.15% of final total supply of tokens) to the wallet [C].
        // EW Ok
        if (order == 1) {
            // Thursday, 3 January 2019 г., 23:59:00
            // EW Ok
            require(now >= endICODate + 15724800);
            // EW Ok
            token.transfer(walletB, paymentSizeB);
            // EW Ok
            token.transfer(walletC, paymentSizeC);
            // EW Ok
            completedBC[order] = true;
        }
        // On July 05, 2019 @ UTC 23:59 = FTST*25/10000 (0.25% of final total supply of tokens) to the wallet [B] and FTST*215/10000 (2.15% of final total supply of tokens) to the wallet [C].
        // EW Ok
        if (order == 2) {
            // Friday, 5 July 2019 г., 23:59:00
            // EW Ok
            require(now >= endICODate + 31536000);
            // EW Ok
            token.transfer(walletB, paymentSizeB);
            // EW Ok
            token.transfer(walletC, paymentSizeC);
            // EW Ok
            completedBC[order] = true;
        }
        // On January 03, 2020 @ UTC 23:59 = FTST*25/10000 (0.25% of final total supply of tokens) to the wallet [B] and FTST*215/10000 (2.15% of final total supply of tokens) to the wallet [C].
        // EW Ok
        if (order == 3) {
            // Friday, 3 January 2020 г., 23:59:00
            // EW Ok
            require(now >= endICODate + 47260800);
            // EW Ok
            token.transfer(walletB, paymentSizeB);
            // EW Ok
            token.transfer(walletC, paymentSizeC);
            // EW Ok
            completedBC[order] = true;
        }
        // On July 04, 2020 @ UTC 23:59 = FTST*25/10000 (0.25% of final total supply of tokens) to the wallet [B] and FTST*215/10000 (2.15% of final total supply of tokens) to the wallet [C].
        // EW Ok
        if (order == 4) {
            // Saturday, 4 July 2020 г., 23:59:00
            // EW Ok
            require(now >= endICODate + 63072000);
            // EW Ok
            token.transfer(walletB, paymentSizeB);
            // EW Ok
            token.transfer(walletC, paymentSizeC);
            // EW Ok
            completedBC[order] = true;
        }
    }
}

// EW Ok
contract Controller is Ownable {
    // EW Ok
    Token public token;
    // EW Ok
    preICO public pre;
    // EW Ok
    ICO public ico;
    // EW Ok
    postICO public post;
    // EW Ok
    enum State {NONE, PRE_ICO, ICO, POST}
    // EW Ok
    State public state;
    // EW Ok
    function Controller(address _token, address _preICO, address _ico, address _postICO) public {
        // EW Ok
        require(_token != address(0x0));
        // EW Ok
        token = Token(_token);
        // EW Ok
        pre = preICO(_preICO);
        // EW Ok
        ico = ICO(_ico);
        // EW Ok
        post = postICO(_postICO);
        // EW Ok
        require(post.endICODate() == ico.endDate());
        // EW Ok
        require(pre.weiRaised() == 0);
        // EW Ok
        require(ico.weiRaised() == 0);
        // EW Ok
        require(token.totalSupply() == 0);
        // EW Ok
        state = State.NONE;
    }

    // EW Ok
    function startPreICO() onlyOwner public {
        // EW Ok
        require(state == State.NONE);
        // EW Ok
        require(token.owner() == address(this));
        // EW Ok
        token.setSaleAgent(pre);
        // EW Ok
        state = State.PRE_ICO;
    }

    // EW Ok
    function startICO() onlyOwner public {
        // EW Ok
        require(now > pre.endDate());
        // EW Ok
        require(state == State.PRE_ICO);
        // EW - redundant
        // EW Ok
        require(token.owner() == address(this));
        // EW Ok
        token.setSaleAgent(ico);
        // EW Ok
        state = State.ICO;
    }

    // EW Ok
    function startPostICO() onlyOwner public {
        // EW Ok
        require(now > ico.endDate());
        // EW Ok
        require(state == State.ICO);
        // EW - redundant
        // EW Ok
        require(token.owner() == address(this));
        // EW Ok
        token.setSaleAgent(post);
        // EW Ok
        state = State.POST;
    }
}
