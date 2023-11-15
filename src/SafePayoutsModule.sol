// SPDX-License-Identifier: MIT
pragma solidity ^0.8.18;

interface Safe {
    enum Operation {
        Call,
        DelegateCall
    }

    function execTransactionFromModule(address to, uint256 value, bytes memory data, Operation operation)
        external
        returns (bool success);
}

contract SafePayoutsModule {
    mapping(address => bool) private operators;
    address[] private beneficiaries;
    mapping(address => uint256) private payouts;
    mapping(address => bool) private paid;

    modifier onlyOperator(address caller) {
        require(operators[caller], "no permissions");
        _;
    }

    constructor() {
        operators[msg.sender] = true;
    }

    function addPayout(address beneficiary, uint256 amount) public onlyOperator(msg.sender) {
        require(beneficiary != address(0), "address not valid");
        require(payouts[beneficiary] == 0, "address already exists");
        require(amount > 0, "amount too low");

        beneficiaries.push(beneficiary);
        payouts[beneficiary] = amount;
    }

    function executePayouts(Safe safe) public onlyOperator(msg.sender) {
        for (uint256 i; i < beneficiaries.length; ++i) {
            address receiver = beneficiaries[i];
            if (!paid[receiver]) {
                paid[receiver] = true;
                _transfer(safe, address(0), payable(receiver), payouts[receiver]);
            }
        }

        _resetPayouts();
    }

    function _resetPayouts() private {
        for (uint256 i; i < beneficiaries.length; ++i) {
            address ben = beneficiaries[i];
            paid[ben] = false;
        }
    }

    function _transfer(Safe safe, address token, address payable to, uint256 amount) private {
        if (token == address(0)) {
            require(
                safe.execTransactionFromModule(to, amount, "", Safe.Operation.Call),
                "could not execute ether transfer"
            );
        } else {
            bytes memory data = abi.encodeWithSignature("transfer(address,uint256)", to, amount);
            require(
                safe.execTransactionFromModule(token, 0, data, Safe.Operation.Call),
                "could not execute token transfer"
            );
        }
    }
}
