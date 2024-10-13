# Secondary Contracts

This folder contains all the logic that is necessary for creating an offer to resell an option contract.

## OfferFactory

This contract performs the job of creating new offers and keeping track of all offers created in past. The usage of factory contract makes sure that the logic of the created offer contracts is not altered.

## Offer

This contract contains the logic of reselling an option contract. Any trader who holds an option contract (inside the option contract, buyer == trader) has the ability to create an offer wherein he/she resells the option contract by accepting premium tokens and transferring the option contract rights to the new buyer.

## OfferInterface

This contract is a very abstracted interface of the option contract wherein we only have the `buy` and `transfer` functions, as these are the only functions required to successfully execute Offer logic for both `Call` and `Put` options collectively.