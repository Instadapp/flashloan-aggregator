# Flashloan Aggregator

## Deployments

### Mainnet
- Proxy: `0x619Ad2D02dBeE6ebA3CDbDA3F98430410e892882`
- Implementation: `0xf52AE7868e01074EaAd587060d75e996baed9aEF`
- AdvancedRoute Implementation: `0xeD4DF5d720F5FA036d16C971FdF409c202C3D8F6`

### Pre Requisites

Before running any command, make sure to install dependencies:

```sh
$ npm install
```

### Compile

Compile the smart contracts with Hardhat:

```sh
$ npm run compile
```

### TypeChain

Compile the smart contracts and generate TypeChain artifacts:

```sh
$ npm run typechain
```

### Test

Run tests using interactive CLI

```sh
$ npm run test:runner
```

Run all the tests:

```sh
$ npm run test
```

### Deploy

Deploy the contracts to Hardhat Network:

```sh
$ npm run deploy
```
