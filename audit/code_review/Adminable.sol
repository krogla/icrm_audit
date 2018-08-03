pragma solidity ^0.4.23;


import "./openzeppelin/Ownable.sol";

contract Adminable is Ownable {
    mapping (address => bool) internal isAdmin;  

    modifier onlyAdmin {
        require(isAdmin[msg.sender]);
        _;
    }  
    constructor() public {
        addAdmin(owner);
    }

    function addAdmin(address _addr) public 
    onlyOwner {
        isAdmin[_addr] = true;
    }
    
    function remAdmin(address _addr) public 
    onlyOwner {
        isAdmin[_addr] = false;
    }
}