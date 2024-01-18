// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import {IERC20} from "./IERC20.sol";
import "./SafeERC20.sol";

interface TokenRecipient {
    function tokenReceived(address sender, uint256 value, bytes memory data) external returns (bool);
}

contract TokenBank is TokenRecipient {
    using SafeERC20 for IERC20;

    address private owner;

    mapping(address token => mapping(address account => uint256 amount)) private _erc20Balances;

    error NotOwner(address account);

    error ERC20InsufficientBalance(address sender, uint256 balance, uint256 needed);

    error InsufficientBankBalance(address token, uint256 balance);

    constructor() {
        owner = msg.sender;
    }

    function _msgSender() internal view returns (address) {
        return msg.sender;
    }

    function balanceOf(address token, address account) public view returns (uint256) {
        return _erc20Balances[token][account];
    }

    function depositERC20(address token, uint256 amount) public {
        address sender = _msgSender();
        IERC20(token).safeTransferFrom(sender, address(this), amount);
        _erc20Balances[token][sender] += amount;
    }

    function withdraw(address token, uint256 amount) external {
        address user = _msgSender();
        IERC20(token).safeTransfer(user, amount);
        _erc20Balances[token][user] -= amount;
    }

    function adminWithdraw(address token) external {
        address account = _msgSender();
        if (_msgSender() != owner) {
            revert NotOwner(account);
        }

        uint256 tokenBalance = IERC20(token).balanceOf(address(this));
        IERC20(token).safeTransfer(account, tokenBalance);
    }

    function tokenReceived(address sender, uint256 value, bytes memory data) override external returns (bool) {
        _erc20Balances[msg.sender][sender] += value;
        return true;
    }
}