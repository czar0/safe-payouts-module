// SPDX-License-Identifier: MIT
pragma solidity ^0.8.18;

/// @title An example implementation of a Safe module for recurring payouts
/// @author Cesare Valitutto - @czar0
/// @notice This contract implements methods to perform multiple payouts at once using funds available on the corresponding Safe account passed in input
/// @dev As modules could represent a security threat for your Safe account, the following implementation measures are recommended for production-ready usage:
/// > Restricted access roles for operators should be defined and assigned by the owners
/// > Avoid arbitrary values function parameters
/// > Implement reentrancy guards
/// > Limit token allowance (value-based and/or time-based)
/// > Beware of the risks of using delegatecall()
/// > Use Safe Guards
/// For details on how to use this module with Safe, check the README
contract SafePayoutsModule {
    mapping(address => bool) private operators;
    address[] private beneficiaries;
    mapping(address => uint256) private payouts;
    mapping(address => bool) private paid;
    mapping(address => uint256) private indexes;

    modifier onlyOperator(address caller) {
        require(operators[caller], "no permissions");
        _;
    }

    constructor() {
        operators[msg.sender] = true;
    }

    /// Add a new payout  to the list (only if authorized)
    /// @param beneficiary the address of the recipient
    /// @param amount the value to be sent to the recipient
    /// @dev Restrict this operation to authorized actors
    function addPayout(address beneficiary, uint256 amount) public onlyOperator(msg.sender) {
        require(beneficiary != address(0), "address not valid");
        require(payouts[beneficiary] == 0, "address already exists");
        require(amount > 0, "amount too low");

        indexes[beneficiary] = beneficiaries.length;
        beneficiaries.push(beneficiary);
        payouts[beneficiary] = amount;
    }

    /// Remove a payout from the list (only if authorized)
    /// @param beneficiary the address of the recipient
    /// @dev Restrict this operation to authorized actors
    function removePayout(address beneficiary) public onlyOperator(msg.sender) {
        require(beneficiary != address(0), "address not valid");
        require(payouts[beneficiary] != 0, "address do not exist");

        uint256 index = indexes[beneficiary];
        beneficiaries[index] = beneficiaries[beneficiaries.length - 1];
        indexes[beneficiaries[index]] = index;
        beneficiaries.pop();
    }

    /// Execute all the payouts (only if authorized)
    /// @param safe the address of the corresponding Safe account that enables this module
    /// @dev Limit allowance and define a timelock
    function executePayouts(SafeModuleManager safe) public onlyOperator(msg.sender) {
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

    function _transfer(SafeModuleManager safe, address token, address payable to, uint256 amount) private {
        if (token == address(0)) {
            require(
                safe.execTransactionFromModule(to, amount, "", SafeModuleManager.Operation.Call),
                "could not execute ether transfer"
            );
        } else {
            bytes memory data = abi.encodeCall(SafeModuleManager.transfer, (to, amount));
            require(
                safe.execTransactionFromModule(token, 0, data, SafeModuleManager.Operation.Call),
                "could not execute token transfer"
            );
        }
    }
}

/// @title Interface for Safe Module Manager
/// @author Cesare Valitutto - @czar0
/// @notice The interface defines methods to perform transfers and execute call/delegatecall transactions on the Account via the Module Manager
/// @dev Using interfaces reduces the amount of code imported by the main contract and, conseguently, the gas fees during the deployment phase
/// However, interfaces can expose to incompatibility issues or errors in case the original contracts they refer to changed
/// Before deploying the contract, it is recommended to verify the correctness of all methods and parameters or, alternatively, to refactor the code to use imports rather than interfaces
/// The version of the original contract is listed below:
///
/// function execTransactionFromModule > ModuleManager.sol - https://github.com/safe-global/safe-contracts/blob/v1.3.0/contracts/base/ModuleManager.sol
/// enum Operation > Enum.sol - https://github.com/safe-global/safe-contracts/blob/v1.3.0/contracts/common/Enum.sol
interface SafeModuleManager {
    enum Operation {
        Call,
        DelegateCall
    }

    /// @dev Allows a Module to execute a Safe transaction without any further confirmations.
    /// @param to Destination address of module transaction.
    /// @param value Ether value of module transaction.
    /// @param data Data payload of module transaction.
    /// @param operation Operation type of module transaction.
    function execTransactionFromModule(address to, uint256 value, bytes memory data, Operation operation)
        external
        returns (bool success);

    function transfer(address to, uint256 amount) external;
}
