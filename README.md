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
npx hardhat mint --minter-addr "<minter addr>" --rbtc-to-mint "<rbtc to mint>" --network rskTestnet
```
