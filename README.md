# Safe - Payouts module 💸

A simple implementation of a Gnosis Safe module for company/DAO payouts written in Solidity.

**🚨 Beware this is a demo-purpose-only contract and it is not recommended to deploy it (as is) to production networks. Modules can be a security risk since they can execute arbitrary transactions bypassing the signature quorum. Only add trusted and audited modules to a Safe. A malicious module can take over a Safe.**

## Requirements

_Note: this step is only required if you want to build, test, and run this project locally. Otherwise, you can directly jump to the Deploy section._

- [**solc**](https://github.com/ethereum/solidity/) - solidity compiler
- [**solc-select**](https://github.com/crytic/solc-select) - manages the installation and the setting of different solc compiler versions **(recommended)**
- [**foundry**](https://github.com/foundry-rs/foundry) - a blazing fast, portable and modular toolkit for Ethereum application development written in Rust

_Make sure your solidity compiler matches with the minimum specific version or version range defined in the contracts._

## Build

To build the contracts simply run:

```shell
forge build
```

## Deploy

### via UI

You can deploy this contract and interact with it directly on your browser via Remix. Click on the link below.

[SafePayoutsModule.sol > Remix](https://remix.ethereum.org/#url=https://github.com/czar0/safe-payouts-module/blob/main/src/SafePayoutsModule.sol)

## Work with a module

### Enable the module

To add a module to your Safe account follow this comprehensive guide: [Safe - Add a module](https://help.safe.global/en/articles/40826-add-a-module).

To find out the version of your Safe account mastercopy contract, navigate to _Settings > Setup_ on your Safe wallet UI. Then, find the corresponding version of the deployed address (for your selected chain) in this repository: [safe-deployment](https://github.com/safe-global/safe-deployments/tree/main/src/assets).

### Remove the module

You can perform this action directly from the Safe wallet UI, navigating to _Settings > Modules_, identifying the module based on its address and then clicking on the delete icon.

## Execute transactions

Once the module is enabled in your Safe account, you can jump on Remix and start performing some actions, such as:

- **addPayout(address beneficiary, uint256 amount)** - which will add new payout information (beneficiary and amount)
- **removePayout(address beneficiary)** - that will remove the payout information associated with the passed beneficiary
- **executePayouts(address safeAccount)** - which will perform all the payouts in the list using funds from your Safe account (taking in input the account address)

## Resources

- [Safe modules](https://docs.safe.global/safe-smart-account/modules)
- [safe-contracts](https://github.com/safe-global/safe-contracts)