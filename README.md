## Foundry Defi Stablecoin

**This project is meant to be a stablecoin where users can deposit WETH and WBTC in exchange for a token that is pegged to the USD.**

## Getting Started

### Requirements

**[git](https://git-scm.com/book/en/v2/Getting-Started-Installing-Git)**

- You'll know you did it right if you can run git --version and you see a response like git version x.x.x

**[foundry](https://getfoundry.sh/)**

- You'll know you did it right if you can run forge --version and you see a response like forge 0.2.0 (816e00b 2023-03-16T00:05:26.396218Z)

## Quickstart

```shell
git clone https://github.com/prince6019/PSC_stablecoin.git
cd PSC_stablecoin
forge build
```

## Usage

### Build

```shell
$ forge build
```

### Test

```shell
$ forge test
```

### Format

```shell
$ forge fmt
```

### Gas Snapshots

```shell
$ forge snapshot
```

### Anvil

```shell
$ anvil
```

### Deploy

```shell
$ forge script script/Counter.s.sol:CounterScript --rpc-url <your_rpc_url> --private-key <your_private_key>
```

### Cast

```shell
$ cast <subcommand>
```

### Help

```shell
$ forge --help
$ anvil --help
$ cast --help
```
