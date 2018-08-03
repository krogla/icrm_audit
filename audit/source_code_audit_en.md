#  TKP smart contracts audit

Status - completed, last edition 2018-04-18

## General remarks

The contract code is checked for software bookmarks and critical errors that can lead to loss of money by investors.
  
* For a successful participation in the ICO stages, the participant must be present in the whitelist.
* There is a possibility of sending / using tokens before the end of the ICO.
* The presence of a `Controller` contract does not exclude the possibility of stages without the use of this contract.

Token TKP inherits the functionality of contracts `ERC20Basic`, `ERC20`, `BasicToken`, `StandardToken`, `MintableToken`, as well as `Ownable`, which implements the contract ownership mechanism and allows owner to install an agent that is allowed to issue tokens.

The pre-sale of TKP tokens is done through a `preICO` contract that inherits the `FinalizableCrowdsale` - finalizable sales function, `WhitelistedCrowdsale`, which defines the whitelist of the participants, and the `Ownable` contract, which implements the contract ownership, and `Pausable`, which allows the sale to pause.

The TKP tokens are sold through an `ICO` contract that inherits `WhitelistedCrowdsale` contracts - a whitelist of the participants, `Ownable` - which implements the contract ownership mechanism and `Pausable` - allowing owner to put a sellout on a pause.

The finalization of the ICO is carried out with the help of the `postICO` contract, in which additional tokens are issued, the contract inherits `Ownable`, which implements the contract ownership mechanism.

The management of the current stage of the ICO is carried out by the `Controller` contract.

Some contracts use the `MathLib` library methods for secure computing.

### Recommendations

* Set `pragma solidity 0.4.20;` (without ^), because now the compiler version is not fixed, and this setting allows for newer versions of the compiler, but already now compilation in them causes multiple warning messages.
* To focus investors' attention on the fact of having `Controller` contract, as the only true source of contracts for the ICO stages.
* (optional) To carry out the deploying of each of the ICO stages directly from the corresponding function of the `Controller` contract, in this case, the manual transmission of the parameters and the contracts of each of the stages will be partially eliminated, and will simply be absent in the block-chain until the beginning of these steps.

## Review of contracts

`MathLib`

1) (Not critical) Using the `require` statement instead of `assert` will save gas in case of erroneous calculations in contract methods.

`ERC20Basic`

1) (Note) A simplified version of the `ERC20` interface

`ERC20`

1) (Note) `ERC20` interface

`ShortAddressProtection`

1) (Not critical) Using the `require` statement instead of `assert` will save gas in case of erroneous calculations in contract methods.

`BasicToken`

1) (Important) `ICO` and `preICO` contracts, that uses by this token, are inherit the `Pausable` contract modifiers that prohibit the purchase of tokens during pauses, but the transfer does not take this into account, which can allow participants to use / forward existing tokens during the stopped `preICO` or `ICO`.

`StandardToken`

1) (Important) the function `transferFrom` does not take into account the pause in contracts `ICO` and `preICO` (see note to `BasicToken`)

`Ownable`

1) (Note) A contract owner may designate another owner.

`MintableToken`

1) (Important) Issue of can be done only from agent's address
2) (Important) Only the owner can set the agent address, it is necessary to use the `Controller` contract to control the ICO stages to exclude the possibility of setting an arbitrary agent address before calling the finalization function in `postICO`

`Token`

1) (note) Sets the public parameters of the token.

`Pausable`

1) Inherits `Ownable`
2) (Note) The contract contains a functional allowing its owner to switch the trigger `paused` to the on and off position, and modifiers allowing the calling of certain functions only in pause mode or vise versa.

`WhitelistedCrowdsale`

1) Inherits `Ownable`
2) (Note) Allows owner to create a "white list" of addresses, contains modifiers that allowing the calling of certain functions only by this list of addresses. The contract owner can supplement the list with addresses one by one or a bundle at a time.
3) (Minor) There is no possibility to delete addresses from the list.

`FinalizableCrowdsale`

1) Inherits `Pausable`
2) (Note) Only the owner can finish the crowdsdale

RefundVault

1) (Note) the contract stores all funds for the time of the crowdsdale, the owner of the vault is the `preICO` contract

`preICO`

1) Inherits `FinalizableCrowdsale`, the owner can change ownership and pause
2) Inherits `WhitelistedCrowdsale`, the owner sets a whitelist of member addresses.
3) (Note) the restriction on the minimum number of tokens bought is strictly fixed - 100
4) (Note) the purchase of tokens is limited to a "white list"
5) (Important) tokens can be forwarded / used outside the `preICO` contract during pause (see note to `BasicToken`)
6) (Medium) for correct operation, the `Controller` contract must be used to automate the switch between the ICO stages, otherwise the token owner must set address of this contract as `saleAgent`
7) (Medium) If `preICO` does not take place (softCap does not closed), there is a refund to investors, but there is no refund / incineration of tokens if, for example, ICO retries are planned.

`ICO`

1) Inherits `Pausable`, the owner can change ownership and pause
2) Inherits `WhitelistedCrowdsale`, the owner sets a "whitelist" of participant addresses
3) (Note) the restriction on the minimum number of tokens bought is strictly fixed - 100
4) (Note) the purchase of tokens is limited to a "white list"
5) (Important) tokens can be sent / used outside of the `preICO` contract during pause (see note to `BasicToken` and `preICO`)
6) (Important) there are no restrictions on sending / using tokens during ICO periods
7) (Not critical) the calculated periods of the token price  are shifted by 2 minutes from the start of the ICO, i.e. actually operate from 0:01:00 on the day of launch and then in each period until 23:59 on the 6th day, respectively, the beginning of the period is not at 0:00:00 on the first day of the next period, but at 23:59:00 on the last day of the previous period
8) (Medium) for correct operation, the `Controller` contract must be used to automate the switch between the ICO stages, otherwise the token owner must set address of this contract as `saleAgent`
9) (Note) When a contract is being deployed, you must specify the start and end dates of the ICO precisely so that they do not intersect in the `preICO`
10) (Not critical) is defined `mapping (address => uint256) public deposited;` - but not used

`postICO`

1) Inherits `Ownable`, the owner can change ownership
2) (Note) When a contract is being deployed, you must specify the end date of the ICO precisely so that it does not intersect ICO
3) (Medium) for correct operation, the `Controller` contract must be used to automate the switch between the ICO stages, otherwise the token owner must set address of this contract as `saleAgent`
4) (Not critical), the `claim` functions have a non-optimal code and in some cases a slight gas overrun

`Controller`

1) Inherits `Ownable`, the owner can change ownership
2) (Medium) After the contract has been deployed, for the correct work, the owner must set it's address as the new owner of the token
3) (Medium) The addresses of all other contracts of the ICO stages must be set, when this contract is deployed, i.e. they should already be deployed in the block-chain.
4) (Not critical) check `require (token.owner () == address (this));` in functions `startICO` and `startPostICO` is redundant, because there are no conditions under which this verification may not be performed
5) (Important) The presence of this contract does not prohibit the owner from not using it at all for the ICO stages, since investors do not have the opportunity to verify that the management of the ICO stages is carried out exactly through this contract.

The Migrations contract is not related to other contracts.

## Disclaimer of Liability

This audit concerns only the source codes of smart contracts and should not be regarded as the approval of a platform, team or company.

## Authors

The audit was provided by [Mikhail Semenkin] (https://t.me/krogla), the team [EthereumWorks] (https://github.com/EthereumWorks)
For smart contract audit and development, please contact: Telegram - @SlavaPoe, Skype - v.poskonin (MousePo).