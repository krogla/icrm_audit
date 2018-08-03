// EW - версия компилятора не зафиксирована
// EW Ok
pragma solidity ^0.4.23;

// EW Ok
import "./openzeppelin/Ownable.sol";
// EW Ok
contract Adminable is Ownable {
    // EW Ok
    mapping (address => bool) internal isAdmin;
    // EW Ok
    modifier onlyAdmin {
        // EW Ok
        require(isAdmin[msg.sender]);
        // EW Ok
        _;
    }
    // EW Ok
    constructor() public {
        // EW Ok
        addAdmin(owner);
    }
    // EW Ok
    function addAdmin(address _addr) public 
    onlyOwner {
        // EW Ok
        isAdmin[_addr] = true;
    }
    // EW Ok
    function remAdmin(address _addr) public
    onlyOwner {
        // EW Ok
        isAdmin[_addr] = false;
    }
}