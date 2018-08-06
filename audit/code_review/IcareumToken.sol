// EW Ok
pragma solidity ^0.4.23;
// EW Ok
import './openzeppelin/Ownable.sol';
// EW Ok
import './openzeppelin/ERC20.sol';
// EW Ok
import './openzeppelin/SafeMath.sol';
// EW Ok
contract IcareumToken is ERC20, Ownable {
  // EW Ok
  using SafeMath for uint256;
  // балансы адресов
  // EW Ok
  mapping (address => uint256) balances;
  // адрес разрешает другому адресу снять количество токенов
  // EW Ok
  mapping (address => mapping (address => uint256)) allowed;
  // общее количество токенов в обращении
  // EW Ok
  uint256 public totalSupply;
  // EW Ok
  uint8 public decimals = 18;
  // EW Ok
  string public symbol = "ICRM";
  // EW Ok
  bool public mintingFinished = false;
  // EW Ok
  event Mint(address indexed to, uint256 amount);
  // EW Ok
  event MintFinished();
  // EW Ok
  // EW избыточное определение событий, они уже есть в ERC20
  event Transfer(address indexed from, address indexed to, uint256 value);
  // EW Ok
  event Approval(address indexed owner, address indexed spender, uint256 value);
  // EW Ok
  modifier ifTransferAllowed() {
    // EW Ok
     require(mintingFinished);
    // EW Ok
     _;
  }

  //@dev disabling ability to accidantaly send ether
  // EW Ok
  function() public payable {
    // EW Ok
  	  revert();
  }
  /**
  * @dev Transfer token for a specified address
  * @param _to The address to transfer to.
  * @param _value The amount to be transferred.
  */
  // EW Ok
  function transfer(address _to, uint256 _value) ifTransferAllowed public returns (bool) {
    // EW Ok
    require(_to != address(0));
    // EW Ok
    require(_value <= balances[msg.sender]);
    // EW Ok
    balances[msg.sender] = balances[msg.sender].sub(_value);
    // EW Ok
    balances[_to] = balances[_to].add(_value);
    // EW Ok
    emit Transfer(msg.sender, _to, _value);
    // EW Ok
    return true;
  }
  /**
  * @dev Gets the balance of the specified address.
  * @param _owner The address to query the the balance of.
  * @return An uint256 representing the amount owned by the passed address.
  */
  // EW Ok
  function balanceOf(address _owner) public view returns (uint256) {
    // EW Ok
    return balances[_owner];
  }

  // EW Ok
  // EW избыточный getter для totalSupply, создается автоматически для public перменной
  function totalSupply() public view returns (uint256) {
    // EW Ok
    return totalSupply;
  }

 /**
   * @dev Transfer tokens from one address to another
   * @param _from address The address which you want to send tokens from
   * @param _to address The address which you want to transfer to
   * @param _value uint256 the amount of tokens to be transferred
   */
  // EW Ok
  function transferFrom( address _from, address _to,uint256 _value) ifTransferAllowed public returns (bool) {
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
    emit Transfer(_from, _to, _value);
    // EW Ok
    return true;
  }
  // EW Ok
  function approve(address _spender, uint256 _value) ifTransferAllowed public returns (bool) {
    // EW Ok
    allowed[msg.sender][_spender] = _value;
    // EW Ok
    emit Approval(msg.sender, _spender, _value);
    // EW Ok
    return true;
  }
  /**
   * @dev Function to check the amount of tokens that an owner allowed to a spender.
   * @param _owner address The address which owns the funds.
   * @param _spender address The address which will spend the funds.
   * @return A uint256 specifying the amount of tokens still available for the spender.
   */
  function allowance( address _owner, address _spender) public view returns (uint256) {
    return allowed[_owner][_spender];
  }
  /**
   * @dev Increase the amount of tokens that an owner allowed to a spender.
   *
   * approve should be called when allowed[_spender] == 0. To increment
   * allowed value is better to use this function to avoid 2 calls (and wait until
   * the first transaction is mined)
   * @param _spender The address which will spend the funds.
   * @param _addedValue The amount of tokens to increase the allowance by.
   */
  // EW Ok
  function increaseApproval(address _spender, uint _addedValue) ifTransferAllowed public returns (bool) {
    // EW Ok
    allowed[msg.sender][_spender] = (
    // EW Ok
      allowed[msg.sender][_spender].add(_addedValue));
    // EW Ok
    emit Approval(msg.sender, _spender, allowed[msg.sender][_spender]);
    // EW Ok
    return true;
  }
  /**
   * @dev Decrease the amount of tokens that an owner allowed to a spender.
   *
   * approve should be called when allowed[_spender] == 0. To decrement
   * allowed value is better to use this function to avoid 2 calls (and wait until
   * the first transaction is mined)
   * @param _spender The address which will spend the funds.
   * @param _subtractedValue The amount of tokens to decrease the allowance by.
   */
  // EW Ok
  function decreaseApproval(address _spender, uint _subtractedValue) ifTransferAllowed public returns (bool) {
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
	    emit Approval(msg.sender, _spender, allowed[msg.sender][_spender]);
        // EW Ok
	    return true;
  	}

  // EW Ok
  modifier canMint() {
    // EW Ok
    require(!mintingFinished);
    // EW Ok
    _;
  }

  // EW Ok
  function mint(address _to, uint256 _amount) onlyOwner canMint public returns (bool) {
    // EW Ok
    totalSupply = totalSupply.add(_amount);
    // EW Ok
    balances[_to] = balances[_to].add(_amount);
    // EW Ok
    emit Mint(_to, _amount);
    // EW !надо добавить событие Transfer для правильного учета токенов в других системах
    // EW Ok
    return true;
  }
  // EW Ok
  function finishMinting() onlyOwner public returns (bool) {
    // EW Ok
    mintingFinished = true;
    // EW Ok
    emit MintFinished();
    // EW Ok
    return true;
  }
}