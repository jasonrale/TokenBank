// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface ERC20 {
    function balanceOf(address account) external view returns (uint256);

    function transfer(address to, uint256 value) external returns (bool);

    function transferFrom(address from, address to, uint256 value) external returns (bool);

    function approve(address spender, uint256 value) external returns (bool);
}

contract TokenBank {
    address private owner;

    mapping(address token => mapping(address account => uint256 amount)) private _erc20Balances;

    error NotOwner(address account);

    error DepositFailed(address sender, uint256 amount);

    error WithdrawFailed(address user, uint256 amount);

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
        uint256 senderBalance = ERC20(token).balanceOf(sender);

        if (amount < senderBalance) {
            revert ERC20InsufficientBalance(sender, senderBalance, amount);
        }

        if (!ERC20(token).transferFrom(sender, address(this), amount)) {
            revert DepositFailed(sender, amount);
        }

        _erc20Balances[token][sender] += amount;
    }

    function withdraw(address token, uint256 amount) external {
        address user = _msgSender();
        uint256 contractBalance = balanceOf(token, user);

        if (amount < contractBalance) {
            revert ERC20InsufficientBalance(address(this), contractBalance, amount);
        }

        if (!ERC20(token).transfer(user, amount)) {
            revert WithdrawFailed(user, amount);
        }

        _erc20Balances[token][user] -= amount;
    }

    function adminWithdraw(address token) external {
        address account = _msgSender();
        if (_msgSender() != owner) {
            revert NotOwner(account);
        }

        uint256 tokenBalance = ERC20(token).balanceOf(address(this));
        if (tokenBalance == 0) {
            revert InsufficientBankBalance(token, tokenBalance);
        }

        if (!ERC20(token).transfer(account, tokenBalance)) {
            revert WithdrawFailed(account, tokenBalance);
        }
    }
}