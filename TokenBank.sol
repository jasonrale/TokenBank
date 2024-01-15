// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import {IERC20} from "./IERC20.sol";
import "./SafeERC20.sol";

interface TokenRecipient {
    function tokensReceived(address token, address from, uint256 amount) external returns (bool);
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

    function depositERC20(address token, uint256 amount) external {
        address sender = _msgSender();
        uint256 senderBalance = IERC20(token).balanceOf(sender);

        if (amount < senderBalance) {
            revert ERC20InsufficientBalance(sender, senderBalance, amount);
        }

        IERC20(token).safeTransferFrom(sender, address(this), amount);
        _erc20Balances[token][sender] += amount;
    }

    function withdraw(address token, uint256 amount) external {
        address user = _msgSender();
        uint256 contractBalance = balanceOf(token, user);

        if (amount < contractBalance) {
            revert ERC20InsufficientBalance(address(this), contractBalance, amount);
        }

        IERC20(token).safeTransfer(user, amount);

        _erc20Balances[token][user] -= amount;
    }

    function adminWithdraw(address token) external {
        address account = _msgSender();
        if (_msgSender() != owner) {
            revert NotOwner(account);
        }

        uint256 tokenBalance = IERC20(token).balanceOf(address(this));
        if (tokenBalance == 0) {
            revert InsufficientBankBalance(token, tokenBalance);
        }

        IERC20(token).safeTransfer(account, tokenBalance);
    }

    function tokensReceived(address token, address from, uint256 amount) override external returns (bool) {
        uint256 senderBalance = IERC20(token).balanceOf(from);

        if (amount < senderBalance) {
            revert ERC20InsufficientBalance(from, senderBalance, amount);
        }

        IERC20(token).safeTransferFrom(from, address(this), amount);
        _erc20Balances[token][from] += amount;

        return true;
    }
}