// SPDX-License-Identifier: MIT
pragma solidity ^0.8.22;

import "./BiscuitToken.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/utils/cryptography/ECDSA.sol";

contract BiscuitRouter {
    using ECDSA for bytes32;

    IERC20 public biscuit;
    uint8 internal constant DEPOSIT_SLOT = 1;
    uint8 internal constant NONCE_SLOT = 2;

    event Deposit(address indexed user, uint256 amount);
    event Withdraw(address indexed user, uint256 amount);

    constructor(address _biscuit) {
        biscuit = IERC20(_biscuit);
    }

    function move(
        uint256 _amount, 
        address to,
        address signer,
        bytes calldata sig, 
        uint256 nonce, 
        string calldata message
    ) external {
        require(_amount > 0, "Amount must be greater than 0");
        require(nonce == _getNonce()[signer], "Invalid nonce");
        require(verify(signer, keccak256(abi.encodePacked(_amount, to, signer, address(this), nonce, message)), sig), "Invalid signature");
        _getDeposit()[msg.sender] -= _amount;
        _getDeposit()[to] += _amount;
    }

    function withdraw(
        uint256 _amount,
        address signer,
        bytes calldata sig,
        uint256 nonce,
        string calldata message
    ) external {
        require(_amount > 0, "Amount must be greater than 0");
        require(nonce == _getNonce()[signer], "Invalid nonce");
        require(verify(signer, keccak256(abi.encodePacked(_amount, signer, address(this), nonce, message)), sig), "Invalid signature");
        require(_getDeposit()[signer] >= _amount, "Insufficient balance");
        _getDeposit()[signer] -= _amount;
        biscuit.transfer(signer, _amount);
        emit Withdraw(signer, _amount);
    }

    function deposit(uint256 _amount) external {
        require(_amount > 0, "Amount must be greater than 0");
        biscuit.transferFrom(msg.sender, address(this), _amount);
        _getDeposit()[msg.sender] += _amount;
        emit Deposit(msg.sender, _amount);
    }

    function getDeposit(address user) external view returns (uint256) {
        return _getDeposit()[user];
    }

    function getNonce(address user) external view returns (uint256) {
        return _getNonce()[user];
    }

    function _getDeposit() internal pure returns (mapping(address => uint256) storage _s) {
        uint256 slot = DEPOSIT_SLOT;
        assembly {
            _s.slot := slot
        }
    }

    function _getNonce() internal pure returns (mapping(address => uint256) storage _s) {
        uint256 slot = NONCE_SLOT;
        assembly {
            _s.slot := slot
        }
    }

    function verify(address signer, bytes32 messageHash, bytes memory signature) internal returns (bool) {
        address recoveredAddress = messageHash.recover(signature);
        bool result = recoveredAddress == signer;
        if(result) {
            _getNonce()[signer]++;
        }
        return result;
    }
}
