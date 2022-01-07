pragma solidity >=0.8.0 <0.9.0;
//SPDX-License-Identifier: MIT

import "hardhat/console.sol";
// import "@openzeppelin/contracts/access/Ownable.sol"; 
// // https://github.com/OpenZeppelin/openzeppelin-contracts/blob/master/contracts/access/Ownable.sol

contract YourContract {

  uint public numOfConfermationRequired;

  address[] public owners;

  struct Transaction {
    bool executed;
    uint txn;
    uint value;
    uint numOfConfermation;
    address to;
    bytes data;
  }

  Transaction[] public transactions;

  mapping(address => bool) isOwner;

  mapping(uint => mapping(address => bool)) isConfirmed;

  event Deposit(address indexed sender, uint amount, uint balance);

  modifier onlyOwner() {
    require(isOwner[msg.sender], "You are not authorized to do this.");
    _;
  }

  modifier txnExists(uint _txn) {
    require(_txn <= transactions.length, "Transaction Does not Exists." );
    _;
  }

  modifier notExecuted(uint _txn) {
    require(!transactions[_txn].executed, "Transaction Already Executed");
    _;
  }

  modifier notConfirmed(uint _txn) {
    require(!isConfirmed[_txn][msg.sender], "You already confirmed the Trasaction.");
    _;
  }

  constructor(address[] memory _owners, uint _numOfConfirmationRequired)  {
    require(_numOfConfirmationRequired > 0 , "Number of Confirmation Required must be greater than 0.");
    require(_numOfConfirmationRequired <= _owners.length, "Number of Confirmation Required greater then Owners.");
    require(_owners.length > 1, "You need at least 2 owners to create a MultiSigWallet");
    
    numOfConfermationRequired = _numOfConfirmationRequired;
    isOwner[msg.sender] = true;
    
    for (uint i = 0; i < _owners.length; i++) {
    
      require(_owners[i] != address(0), "Owner cannot be the Zero Address.");
      require(!isOwner[_owners[i]], "Owner already exists.");
    
      isOwner[_owners[i]] = true;
      owners.push(_owners[i]);
    
    }
  }
  

  receive() external payable {
      emit Deposit(msg.sender, msg.value, address(this).balance);
  }

  function initializeTransaction(address _to, uint _value, bytes memory _data) public onlyOwner {
    uint _txn = transactions.length;

    transactions.push(
      Transaction({
        executed: false,
        txn: _txn,
        value: _value,
        numOfConfermation: 0,
        to: _to,
        data: _data
      })
    );
  }

  function confirmTransaction(uint _txn) public onlyOwner txnExists(_txn) notExecuted(_txn) notConfirmed(_txn) {
    Transaction storage transaction = transactions[_txn];
    transaction.numOfConfermation += 1;
    isConfirmed[_txn][msg.sender] = true;
  }

  function executeTransaction(uint _txn) public onlyOwner txnExists(_txn) notExecuted(_txn) {
    Transaction storage transaction = transactions[_txn];
    require(transaction.numOfConfermation >= numOfConfermationRequired, "Transaction is not confirmed");
    transaction.executed = true;
    (bool sent, ) = transaction.to.call{value: transaction.value}(transaction.data);
    require(sent, "Transaction Failed");
  }

  function revokeTransaction(uint _txn) public onlyOwner txnExists(_txn) notExecuted(_txn) {
    Transaction storage transaction = transactions[_txn];
    require(isConfirmed[_txn][msg.sender], "tx not confirmed");
    transaction.numOfConfermation -= 1;
    isConfirmed[_txn][msg.sender] = false;
  }

  function getTransactionCount() public view returns(uint) {
    return transactions.length;
  }
}
