// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;
import {ReentrancyGuard} from "@openzeppelin/contracts/utils/ReentrancyGuard.sol";
import {OwnableUpgradeable} from "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import {Initializable} from "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import {UUPSUpgradeable} from "@openzeppelin/contracts-upgradeable/proxy/utils/UUPSUpgradeable.sol";

contract EtherVault is ReentrancyGuard, OwnableUpgradeable, UUPSUpgradeable {

    event Deposit(address indexed user, uint256 amount);
    event Withdraw(address indexed user, uint256 amount);
    event FeeUpdated(uint256 oldFee, uint256 newFee);
    event FeeWithdrawn(address indexed receiver, uint256 amount);
    error NotAdmin();
    error Paused();
    error InsufficientBalance();
    error InsufficientDeposit();
    error TransferUnsuccessful();

    struct UserData {


        uint256 balance;
        uint256 timestamp;
        bool alreadyDeposited;
    }

    struct VaultConfig {


        uint256 totalDeposit;
        uint256 totalUser;
        uint256 fee;
        bool status;
    }

    uint256 public constant FEE_BPS = 100;
    uint256 public constant MIN_DEPOSIT = 0.1 ether;
    VaultConfig public vault;
    mapping(address => UserData) public userData;

    constructor() {
        _disableInitializers();
    }

    function initialize(uint256 _fee) public initializer {
        __Ownable_init(msg.sender);
        vault.fee = _fee;
        vault.status = true;
    }


    modifier paused() {
        _checkPaused();
        _;
    }

    function deposit() public payable paused nonReentrant returns (uint256 amount_) {
        amount_ = msg.value;
        uint256 userAmount = amount_ - ((amount_ * vault.fee) / FEE_BPS);
        if (amount_ < MIN_DEPOSIT) revert InsufficientDeposit();

        if (userData[msg.sender].balance == 0 && !userData[msg.sender].alreadyDeposited) {
            vault.totalUser += 1;
            userData[msg.sender].alreadyDeposited = true;
        }

        vault.totalDeposit += userAmount;
        userData[msg.sender].balance += userAmount;
        userData[msg.sender].timestamp = block.timestamp;
    }

    function withdraw(uint256 amount) public paused nonReentrant returns (uint256) {
        if (amount > userData[msg.sender].balance) revert InsufficientBalance();

        vault.totalDeposit -= amount;
        userData[msg.sender].balance -= amount;

        (bool success,) = msg.sender.call{value: amount}("");
        if (!success) revert TransferUnsuccessful();

        return amount;
    }

    function updateFee(uint256 _newfee) public onlyOwner {
        vault.fee = _newfee;
    }

    function withdrawFee(address reciever) public onlyOwner nonReentrant(){
        uint256 feeAmount = address(this).balance - vault.totalDeposit;
        (bool success,) = reciever.call{value: feeAmount}("");
        if (!success) revert TransferUnsuccessful();
        emit FeeWithdrawn(reciever, feeAmount);
    }

    function feeBalance() public view returns (uint256 balance) {
        balance = address(this).balance - vault.totalDeposit;
    }

  
    function _checkPaused() private view {
        if (!vault.status) revert Paused();
    }

    function vaultBalance() public view returns (uint256) {
        return address(this).balance;
    }

    function _authorizeUpgrade(address newImplementation) internal override onlyOwner {}

    receive() external payable {}
}
