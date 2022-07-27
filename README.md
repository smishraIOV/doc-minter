# Sample DoC Minter Project

This project demonstrates a basic DoC token minting use case. It comes with a sample contract, a test for that contract,
a script that deploys that contract, and a task that mints DoC tokens.

Try running some of the following tasks:

```shell
npx hardhat help
npx hardhat test
GAS_REPORT=true npx hardhat test
npx hardhat node
npx hardhat run scripts/deploy.ts
npx hardhat run scripts/deploy.ts --network rskTestnet

# note the conversion of command options .. e.g minterAddr -> minter-addr etc
npx hardhat mint --minter-addr "0x133b6ebca32c5dcc272a415457822e056ae41b33"  --rbtc-to-mint "1000000000000000" --total-value-to-send "2000000000000000" --network rskTestnet
```
