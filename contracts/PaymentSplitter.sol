// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/utils/Address.sol";

contract PaymentSplitter {
    using Address for address payable;

    address[] private _payees;
    uint256 private _totalShares;
    mapping(address => uint256) private _shares;
    mapping(address => uint256) private _released;
    uint256 private _totalReleased;

    constructor(address[] memory payees, uint256[] memory shares) payable {
        require(payees.length == shares.length, "Mismatched arrays");
        require(payees.length > 0, "No payees");

        for (uint256 i = 0; i < payees.length; i++) {
            address payee = payees[i];
            uint256 share = shares[i];
            require(payee != address(0), "Zero address payee");
            require(share > 0, "Zero shares");
            require(_shares[payee] == 0, "Duplicate payee");

            _payees.push(payee);
            _shares[payee] = share;
            _totalShares += share;
        }
    }

    receive() external payable {}

    function release(address payable account) public virtual {
        require(_shares[account] > 0, "Account has no shares");

        uint256 totalReceived = address(this).balance + _totalReleased;
        uint256 payment = (totalReceived * _shares[account]) / _totalShares - _released[account];

        require(payment > 0, "Account is not due payment");

        _released[account] += payment;
        _totalReleased += payment;

        account.sendValue(payment);
    }
}