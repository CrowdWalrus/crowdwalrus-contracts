# Phase 2 Testnet Deployment — November 7, 2025

**Command Executed**

```bash
sui client publish --gas-budget 500000000
```

**Full CLI Output**

```
➜  crowd-walrus-contracts git:(sui-update) sui client publish --gas-budget 500000000
[Note]: Dependency sources are no longer verified automatically during publication and upgrade. You can pass the `--verify-deps` option if you would like to verify them as part of publication or upgrade.
UPDATING GIT DEPENDENCY https://github.com/pyth-network/pyth-crosschain.git
UPDATING GIT DEPENDENCY https://github.com/wormhole-foundation/wormhole.git
UPDATING GIT DEPENDENCY https://github.com/aminlatifi/suins-contracts.git
UPDATING GIT DEPENDENCY https://github.com/MystenLabs/sui.git
INCLUDING DEPENDENCY Bridge
INCLUDING DEPENDENCY Pyth
INCLUDING DEPENDENCY Wormhole
INCLUDING DEPENDENCY SuiSystem
INCLUDING DEPENDENCY subdomains
INCLUDING DEPENDENCY denylist
INCLUDING DEPENDENCY suins
INCLUDING DEPENDENCY Sui
INCLUDING DEPENDENCY MoveStdlib
BUILDING crowd_walrus
warning[W01004]: invalid documentation comment
  ┌─ /Users/alireza/.move/https___github_com_pyth-network_pyth-crosschain_git_sui-contract-testnet/target_chains/sui/contracts/sources/price.move:4:5
  │
4 │ ╭     /// A price with a degree of uncertainty, represented as a price +- a confidence interval.
5 │ │     ///
6 │ │     /// The confidence interval roughly corresponds to the standard error of a normal distribution.
7 │ │     /// Both the price and confidence are stored in a fixed-point numeric representation,
8 │ │     /// `x * (10^expo)`, where `expo` is the exponent.
  │ ╰──────────────────────────────────────────────────────^ Documentation comment cannot be matched to a language item

Total number of linter warnings suppressed: 1 (unique lints: 1)
Skipping dependency verification
Transaction Digest: E2asrnMvFS9fg3gJ6ewLMzNe1BdA2rJDRxnAFeqTduqt
╭──────────────────────────────────────────────────────────────────────────────────────────────────────────────╮
│ Transaction Data                                                                                             │
├──────────────────────────────────────────────────────────────────────────────────────────────────────────────┤
│ Sender: 0x4fcb599f85adb345fd608c69040615caa7af84ec8bbf181569a4dbe7368acfbb                                   │
│ Gas Owner: 0x4fcb599f85adb345fd608c69040615caa7af84ec8bbf181569a4dbe7368acfbb                                │
│ Gas Budget: 500000000 MIST                                                                                   │
│ Gas Price: 1000 MIST                                                                                         │
│ Gas Payment:                                                                                                 │
│  ┌──                                                                                                         │
│  │ ID: 0xb8cd20f1a0a2a18a1fa21e7fec66b26dc9cc09bef16e79a5c3c0ad93646fcf8e                                    │
│  │ Version: 623841003                                                                                        │
│  │ Digest: F8dhGztjgYiqWca9p4UMoZQxTzYrxcp9kFHJt9ocodyc                                                      │
│  └──                                                                                                         │
│                                                                                                              │
│ Transaction Kind: Programmable                                                                               │
│ ╭──────────────────────────────────────────────────────────────────────────────────────────────────────────╮ │
│ │ Input Objects                                                                                            │ │
│ ├──────────────────────────────────────────────────────────────────────────────────────────────────────────┤ │
│ │ 0   Pure Arg: Type: address, Value: "0x4fcb599f85adb345fd608c69040615caa7af84ec8bbf181569a4dbe7368acfbb" │ │
│ ╰──────────────────────────────────────────────────────────────────────────────────────────────────────────╯ │
│ ╭─────────────────────────────────────────────────────────────────────────╮                                  │
│ │ Commands                                                                │                                  │
│ ├─────────────────────────────────────────────────────────────────────────┤                                  │
│ │ 0  Publish:                                                             │                                  │
│ │  ┌                                                                      │                                  │
│ │  │ Dependencies:                                                        │                                  │
│ │  │   0x0000000000000000000000000000000000000000000000000000000000000001 │                                  │
│ │  │   0xabf837e98c26087cba0883c0a7a28326b1fa3c5e1e2c5abdb486f9e8f594c837 │                                  │
│ │  │   0x0000000000000000000000000000000000000000000000000000000000000002 │                                  │
│ │  │   0xf47329f4344f3bf0f8e436e2f7b485466cff300f12a166563995d3888c296a94 │                                  │
│ │  │   0xa86c05fbc6371788eb31260dc5085f4bfeab8b95c95d9092c9eb86e63fae3d49 │                                  │
│ │  │   0x3c272bc45f9157b7818ece4f7411bdfa8af46303b071aca4e18c03119c9ff636 │                                  │
│ │  │   0x67072134f0867b886c9541873d1cb327feb7e161cd56dd76cb6aa9e464410db1 │                                  │
│ │  └                                                                      │                                  │
│ │                                                                         │                                  │
│ │ 1  TransferObjects:                                                     │                                  │
│ │  ┌                                                                      │                                  │
│ │  │ Arguments:                                                           │                                  │
│ │  │   Result 0                                                           │                                  │
│ │  │ Address: Input  0                                                    │                                  │
│ │  └                                                                      │                                  │
│ ╰─────────────────────────────────────────────────────────────────────────╯                                  │
│                                                                                                              │
│ Signatures:                                                                                                  │
│    4/Ry6lgZWkc5J7ggvlzepyxs9xHJgRF1RY9FqLgOBYSi8hHe9B3PJ1jSOJWsxJyBsb3tlxjD7Vmw5A6X7qTJBg==                  │
│                                                                                                              │
╰──────────────────────────────────────────────────────────────────────────────────────────────────────────────╯
╭───────────────────────────────────────────────────────────────────────────────────────────────────╮
│ Transaction Effects                                                                               │
├───────────────────────────────────────────────────────────────────────────────────────────────────┤
│ Digest: E2asrnMvFS9fg3gJ6ewLMzNe1BdA2rJDRxnAFeqTduqt                                              │
│ Status: Success                                                                                   │
│ Executed Epoch: 911                                                                               │
│                                                                                                   │
│ Created Objects:                                                                                  │
│  ┌──                                                                                              │
│  │ ID: 0x09839ac664fb54f6db4e5d63c4a8fd168932f353fffff6a3594392a2dd9dac94                         │
│  │ Owner: Account Address ( 0x4fcb599f85adb345fd608c69040615caa7af84ec8bbf181569a4dbe7368acfbb )  │
│  │ Version: 623841004                                                                             │
│  │ Digest: CTSdwW6KLrJk7BPFZnE53R1ARgVaN9bC5XfXV4A6EGyd                                           │
│  └──                                                                                              │
│  ┌──                                                                                              │
│  │ ID: 0x16e38b4863ea42bf4210346d994885a0a4a2d4d30d48028f8b228f656f2c0656                         │
│  │ Owner: Object ID: ( 0x898b24f1adc1eff7c5e19fa5c3dadf2b26e16adf8de456274064881efda05d53 )       │
│  │ Version: 623841004                                                                             │
│  │ Digest: D3KcivL2zYYYT4NEH4ozknEGYHkouMvSWbVfP3wNudsA                                           │
│  └──                                                                                              │
│  ┌──                                                                                              │
│  │ ID: 0x27fd4da16127b07b6127bb32fb0979771a04e0382d218fc2fd79ebcf9fc7f46a                         │
│  │ Owner: Shared( 623841004 )                                                                     │
│  │ Version: 623841004                                                                             │
│  │ Digest: 3fUutVmaNc2QSRd7JGj1xw96JeD6cynr46bfYPyGgpL6                                           │
│  └──                                                                                              │
│  ┌──                                                                                              │
│  │ ID: 0x2adf37351f87becf103a570af3c32e4579a5d00024181e16da88bea37342b137                         │
│  │ Owner: Shared( 623841004 )                                                                     │
│  │ Version: 623841004                                                                             │
│  │ Digest: EzDQS7YZcFhH5JaLRZHYtXKNE5KQgBJfQjWNUpnTtWmY                                           │
│  └──                                                                                              │
│  ┌──                                                                                              │
│  │ ID: 0x8db76c73f61ec85a9d116d1e2a658c6c47bc77b3782e4fbb265ef6c23c5fc67f                         │
│  │ Owner: Shared( 623841004 )                                                                     │
│  │ Version: 623841004                                                                             │
│  │ Digest: AK5qqzTtonqLSVeKpCcuFQ9eTXSnLuSfpJjHSUvYiYWG                                           │
│  └──                                                                                              │
│  ┌──                                                                                              │
│  │ ID: 0x8fe72299a328a9d9f63d21f3f49086cccee8a9b76cab5898cebf1411f6b5d09b                         │
│  │ Owner: Object ID: ( 0x8db76c73f61ec85a9d116d1e2a658c6c47bc77b3782e4fbb265ef6c23c5fc67f )       │
│  │ Version: 623841004                                                                             │
│  │ Digest: Bc1BsCFhC1pN4ngdNjuLE99RSz6Sj8MnGH2wugQpCY8h                                           │
│  └──                                                                                              │
│  ┌──                                                                                              │
│  │ ID: 0xa9cc569df704519c1811e84aa6b5e0522e81ac922f25a6f1861a795da75213b6                         │
│  │ Owner: Shared( 623841004 )                                                                     │
│  │ Version: 623841004                                                                             │
│  │ Digest: B4e5Xob9vN24jfrMP7TRpe2oATc8asztunmPFkGL4uP2                                           │
│  └──                                                                                              │
│  ┌──                                                                                              │
│  │ ID: 0xc1a5b7ebe13c51d57889f78123e3de87b852d6f6d956c2ca40fc9ce61872bcfe                         │
│  │ Owner: Shared( 623841004 )                                                                     │
│  │ Version: 623841004                                                                             │
│  │ Digest: 8gWvNvpYRvrDNrX6igkmseAq95L3KPkokRrTkJ4BhDUE                                           │
│  └──                                                                                              │
│  ┌──                                                                                              │
│  │ ID: 0xcce63d8e3fba9530218b83af57360abd730382a71bec9c5616f1b23fe19d7f02                         │
│  │ Owner: Object ID: ( 0xa9cc569df704519c1811e84aa6b5e0522e81ac922f25a6f1861a795da75213b6 )       │
│  │ Version: 623841004                                                                             │
│  │ Digest: 9LNRNFuPuBGDkkK5dtorNbmo15pZsNB8PPiTxRQAXpYE                                           │
│  └──                                                                                              │
│  ┌──                                                                                              │
│  │ ID: 0xd71bc7cd83f6b2ca8d6241264553fe9dc22c65f52104e19424c670983942fe8f                         │
│  │ Owner: Account Address ( 0x4fcb599f85adb345fd608c69040615caa7af84ec8bbf181569a4dbe7368acfbb )  │
│  │ Version: 623841004                                                                             │
│  │ Digest: FpM7Mrm29Yvmng2C1egPuWaAC9w88DCmpKHZef86KaV3                                           │
│  └──                                                                                              │
│  ┌──                                                                                              │
│  │ ID: 0xd7fe4cdf6df2fa3f566019b3110d5a7d1573abb9995835adce516747b3153686                         │
│  │ Owner: Shared( 623841004 )                                                                     │
│  │ Version: 623841004                                                                             │
│  │ Digest: FeAUgFLLSvp1UwStUSodWKDzWX8PBurBzsUYcUzX7Jvm                                           │
│  └──                                                                                              │
│  ┌──                                                                                              │
│  │ ID: 0xe94de4239f0af7d351e6894464cbeace43e6ba8902732c492df8ad17a456514a                         │
│  │ Owner: Account Address ( 0x4fcb599f85adb345fd608c69040615caa7af84ec8bbf181569a4dbe7368acfbb )  │
│  │ Version: 623841004                                                                             │
│  │ Digest: 4cqf29v8WWNF6S2ysXZKEFhApoKM4PPq7xhj8jDq4iQg                                           │
│  └──                                                                                              │
│  ┌──                                                                                              │
│  │ ID: 0xf5d2b6fdc9cff7569f696c2aeb8c824839ece0f3b8c035ae5c4ff30621f2f0eb                         │
│  │ Owner: Immutable                                                                               │
│  │ Version: 1                                                                                     │
│  │ Digest: 9EUxYaRpXYoSWYAEPnbdpaHLiy1qxcpeBxV7KVqMkJAB                                           │
│  └──                                                                                              │
│ Mutated Objects:                                                                                  │
│  ┌──                                                                                              │
│  │ ID: 0xb8cd20f1a0a2a18a1fa21e7fec66b26dc9cc09bef16e79a5c3c0ad93646fcf8e                         │
│  │ Owner: Account Address ( 0x4fcb599f85adb345fd608c69040615caa7af84ec8bbf181569a4dbe7368acfbb )  │
│  │ Version: 623841004                                                                             │
│  │ Digest: 288emyyijwqn5yEvPYLgWZh1hrZJPEn4YRAwg9STNV81                                           │
│  └──                                                                                              │
│ Gas Object:                                                                                       │
│  ┌──                                                                                              │
│  │ ID: 0xb8cd20f1a0a2a18a1fa21e7fec66b26dc9cc09bef16e79a5c3c0ad93646fcf8e                         │
│  │ Owner: Account Address ( 0x4fcb599f85adb345fd608c69040615caa7af84ec8bbf181569a4dbe7368acfbb )  │
│  │ Version: 623841004                                                                             │
│  │ Digest: 288emyyijwqn5yEvPYLgWZh1hrZJPEn4YRAwg9STNV81                                           │
│  └──                                                                                              │
│ Gas Cost Summary:                                                                                 │
│    Storage Cost: 310604400 MIST                                                                   │
│    Computation Cost: 4000000 MIST                                                                 │
│    Storage Rebate: 978120 MIST                                                                    │
│    Non-refundable Storage Fee: 9880 MIST                                                          │
│                                                                                                   │
│ Transaction Dependencies:                                                                         │
│    4UsjtEMfQyBfpWh5psnDzRqbFpiDecvGQjP57rg1oLP3                                                   │
│    529gXBgfiDC9qTmTmRvuX2iFCsU3RGcmuuiEjpE21EnW                                                   │
│    8hyfuhwkzf4VTRcmKdETXCbYytSKWHvtH4tQBGCQQEYG                                                   │
│    BF2e72MvTgXtwCcf3fJ2Ai89nYhbiR5P3sCxUjcCsjAJ                                                   │
│    CNmS7baTJffHBw3XE4xhYVQfEX5JzWFFRsiEh2XWL44K                                                   │
│    Dd9pn1zFcSJjinxQewFd2gQdR4XKsHxFioD5MYnwLZQz                                                   │
│    GppkRKgQ5ZXNWpCC3BTd9tXG4zF3ACacZK9Pu8eCvJiz                                                   │
│    HiiEL3jwxR238pWdoWQ7tCQB8gTkmVrccZ2ZYy4MMY7a                                                   │
╰───────────────────────────────────────────────────────────────────────────────────────────────────╯
╭─────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────╮
│ Transaction Block Events                                                                                                │
├─────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────┤
│  ┌──                                                                                                                    │
│  │ EventID: E2asrnMvFS9fg3gJ6ewLMzNe1BdA2rJDRxnAFeqTduqt:0                                                              │
│  │ PackageID: 0xf5d2b6fdc9cff7569f696c2aeb8c824839ece0f3b8c035ae5c4ff30621f2f0eb                                        │
│  │ Transaction Module: crowd_walrus                                                                                     │
│  │ Sender: 0x4fcb599f85adb345fd608c69040615caa7af84ec8bbf181569a4dbe7368acfbb                                           │
│  │ EventType: 0xf5d2b6fdc9cff7569f696c2aeb8c824839ece0f3b8c035ae5c4ff30621f2f0eb::platform_policy::PolicyAdded          │
│  │ ParsedJSON:                                                                                                          │
│  │   ┌──────────────────┬────────────────────────────────────────────────────────────────────┐                          │
│  │   │ enabled          │ true                                                               │                          │
│  │   ├──────────────────┼────────────────────────────────────────────────────────────────────┤                          │
│  │   │ platform_address │ 0x4fcb599f85adb345fd608c69040615caa7af84ec8bbf181569a4dbe7368acfbb │                          │
│  │   ├──────────────────┼────────────────────────────────────────────────────────────────────┤                          │
│  │   │ platform_bps     │ 0                                                                  │                          │
│  │   ├──────────────────┼────────────────────────────────────────────────────────────────────┤                          │
│  │   │ policy_name      │ standard                                                           │                          │
│  │   ├──────────────────┼────────────────────────────────────────────────────────────────────┤                          │
│  │   │ timestamp_ms     │ 0                                                                  │                          │
│  │   └──────────────────┴────────────────────────────────────────────────────────────────────┘                          │
│  └──                                                                                                                    │
│  ┌──                                                                                                                    │
│  │ EventID: E2asrnMvFS9fg3gJ6ewLMzNe1BdA2rJDRxnAFeqTduqt:1                                                              │
│  │ PackageID: 0xf5d2b6fdc9cff7569f696c2aeb8c824839ece0f3b8c035ae5c4ff30621f2f0eb                                        │
│  │ Transaction Module: crowd_walrus                                                                                     │
│  │ Sender: 0x4fcb599f85adb345fd608c69040615caa7af84ec8bbf181569a4dbe7368acfbb                                           │
│  │ EventType: 0xf5d2b6fdc9cff7569f696c2aeb8c824839ece0f3b8c035ae5c4ff30621f2f0eb::crowd_walrus::AdminCreated            │
│  │ ParsedJSON:                                                                                                          │
│  │   ┌─────────────────┬────────────────────────────────────────────────────────────────────┐                           │
│  │   │ admin_id        │ 0xd71bc7cd83f6b2ca8d6241264553fe9dc22c65f52104e19424c670983942fe8f │                           │
│  │   ├─────────────────┼────────────────────────────────────────────────────────────────────┤                           │
│  │   │ creator         │ 0x4fcb599f85adb345fd608c69040615caa7af84ec8bbf181569a4dbe7368acfbb │                           │
│  │   ├─────────────────┼────────────────────────────────────────────────────────────────────┤                           │
│  │   │ crowd_walrus_id │ 0x8db76c73f61ec85a9d116d1e2a658c6c47bc77b3782e4fbb265ef6c23c5fc67f │                           │
│  │   └─────────────────┴────────────────────────────────────────────────────────────────────┘                           │
│  └──                                                                                                                    │
│  ┌──                                                                                                                    │
│  │ EventID: E2asrnMvFS9fg3gJ6ewLMzNe1BdA2rJDRxnAFeqTduqt:2                                                              │
│  │ PackageID: 0xf5d2b6fdc9cff7569f696c2aeb8c824839ece0f3b8c035ae5c4ff30621f2f0eb                                        │
│  │ Transaction Module: crowd_walrus                                                                                     │
│  │ Sender: 0x4fcb599f85adb345fd608c69040615caa7af84ec8bbf181569a4dbe7368acfbb                                           │
│  │ EventType: 0xf5d2b6fdc9cff7569f696c2aeb8c824839ece0f3b8c035ae5c4ff30621f2f0eb::crowd_walrus::PolicyRegistryCreated   │
│  │ ParsedJSON:                                                                                                          │
│  │   ┌────────────────────┬────────────────────────────────────────────────────────────────────┐                        │
│  │   │ crowd_walrus_id    │ 0x8db76c73f61ec85a9d116d1e2a658c6c47bc77b3782e4fbb265ef6c23c5fc67f │                        │
│  │   ├────────────────────┼────────────────────────────────────────────────────────────────────┤                        │
│  │   │ policy_registry_id │ 0x2adf37351f87becf103a570af3c32e4579a5d00024181e16da88bea37342b137 │                        │
│  │   └────────────────────┴────────────────────────────────────────────────────────────────────┘                        │
│  └──                                                                                                                    │
│  ┌──                                                                                                                    │
│  │ EventID: E2asrnMvFS9fg3gJ6ewLMzNe1BdA2rJDRxnAFeqTduqt:3                                                              │
│  │ PackageID: 0xf5d2b6fdc9cff7569f696c2aeb8c824839ece0f3b8c035ae5c4ff30621f2f0eb                                        │
│  │ Transaction Module: crowd_walrus                                                                                     │
│  │ Sender: 0x4fcb599f85adb345fd608c69040615caa7af84ec8bbf181569a4dbe7368acfbb                                           │
│  │ EventType: 0xf5d2b6fdc9cff7569f696c2aeb8c824839ece0f3b8c035ae5c4ff30621f2f0eb::crowd_walrus::ProfilesRegistryCreated │
│  │ ParsedJSON:                                                                                                          │
│  │   ┌──────────────────────┬────────────────────────────────────────────────────────────────────┐                      │
│  │   │ crowd_walrus_id      │ 0x8db76c73f61ec85a9d116d1e2a658c6c47bc77b3782e4fbb265ef6c23c5fc67f │                      │
│  │   ├──────────────────────┼────────────────────────────────────────────────────────────────────┤                      │
│  │   │ profiles_registry_id │ 0xd7fe4cdf6df2fa3f566019b3110d5a7d1573abb9995835adce516747b3153686 │                      │
│  │   └──────────────────────┴────────────────────────────────────────────────────────────────────┘                      │
│  └──                                                                                                                    │
│  ┌──                                                                                                                    │
│  │ EventID: E2asrnMvFS9fg3gJ6ewLMzNe1BdA2rJDRxnAFeqTduqt:4                                                              │
│  │ PackageID: 0xf5d2b6fdc9cff7569f696c2aeb8c824839ece0f3b8c035ae5c4ff30621f2f0eb                                        │
│  │ Transaction Module: crowd_walrus                                                                                     │
│  │ Sender: 0x4fcb599f85adb345fd608c69040615caa7af84ec8bbf181569a4dbe7368acfbb                                           │
│  │ EventType: 0xf5d2b6fdc9cff7569f696c2aeb8c824839ece0f3b8c035ae5c4ff30621f2f0eb::crowd_walrus::TokenRegistryCreated    │
│  │ ParsedJSON:                                                                                                          │
│  │   ┌───────────────────┬────────────────────────────────────────────────────────────────────┐                         │
│  │   │ crowd_walrus_id   │ 0x8db76c73f61ec85a9d116d1e2a658c6c47bc77b3782e4fbb265ef6c23c5fc67f │                         │
│  │   ├───────────────────┼────────────────────────────────────────────────────────────────────┤                         │
│  │   │ token_registry_id │ 0xc1a5b7ebe13c51d57889f78123e3de87b852d6f6d956c2ca40fc9ce61872bcfe │                         │
│  │   └───────────────────┴────────────────────────────────────────────────────────────────────┘                         │
│  └──                                                                                                                    │
│  ┌──                                                                                                                    │
│  │ EventID: E2asrnMvFS9fg3gJ6ewLMzNe1BdA2rJDRxnAFeqTduqt:5                                                              │
│  │ PackageID: 0xf5d2b6fdc9cff7569f696c2aeb8c824839ece0f3b8c035ae5c4ff30621f2f0eb                                        │
│  │ Transaction Module: crowd_walrus                                                                                     │
│  │ Sender: 0x4fcb599f85adb345fd608c69040615caa7af84ec8bbf181569a4dbe7368acfbb                                           │
│  │ EventType: 0xf5d2b6fdc9cff7569f696c2aeb8c824839ece0f3b8c035ae5c4ff30621f2f0eb::crowd_walrus::BadgeConfigCreated      │
│  │ ParsedJSON:                                                                                                          │
│  │   ┌─────────────────┬────────────────────────────────────────────────────────────────────┐                           │
│  │   │ badge_config_id │ 0x27fd4da16127b07b6127bb32fb0979771a04e0382d218fc2fd79ebcf9fc7f46a │                           │
│  │   ├─────────────────┼────────────────────────────────────────────────────────────────────┤                           │
│  │   │ crowd_walrus_id │ 0x8db76c73f61ec85a9d116d1e2a658c6c47bc77b3782e4fbb265ef6c23c5fc67f │                           │
│  │   └─────────────────┴────────────────────────────────────────────────────────────────────┘                           │
│  └──                                                                                                                    │
│  ┌──                                                                                                                    │
│  │ EventID: E2asrnMvFS9fg3gJ6ewLMzNe1BdA2rJDRxnAFeqTduqt:6                                                              │
│  │ PackageID: 0xf5d2b6fdc9cff7569f696c2aeb8c824839ece0f3b8c035ae5c4ff30621f2f0eb                                        │
│  │ Transaction Module: crowd_walrus                                                                                     │
│  │ Sender: 0x4fcb599f85adb345fd608c69040615caa7af84ec8bbf181569a4dbe7368acfbb                                           │
│  │ EventType: 0xf5d2b6fdc9cff7569f696c2aeb8c824839ece0f3b8c035ae5c4ff30621f2f0eb::suins_manager::SuiNSManagerCreated    │
│  │ ParsedJSON:                                                                                                          │
│  │   ┌──────────────────┬────────────────────────────────────────────────────────────────────┐                          │
│  │   │ creator          │ 0x4fcb599f85adb345fd608c69040615caa7af84ec8bbf181569a4dbe7368acfbb │                          │
│  │   ├──────────────────┼────────────────────────────────────────────────────────────────────┤                          │
│  │   │ suins_manager_id │ 0xa9cc569df704519c1811e84aa6b5e0522e81ac922f25a6f1861a795da75213b6 │                          │
│  │   └──────────────────┴────────────────────────────────────────────────────────────────────┘                          │
│  └──                                                                                                                    │
│  ┌──                                                                                                                    │
│  │ EventID: E2asrnMvFS9fg3gJ6ewLMzNe1BdA2rJDRxnAFeqTduqt:7                                                              │
│  │ PackageID: 0xf5d2b6fdc9cff7569f696c2aeb8c824839ece0f3b8c035ae5c4ff30621f2f0eb                                        │
│  │ Transaction Module: crowd_walrus                                                                                     │
│  │ Sender: 0x4fcb599f85adb345fd608c69040615caa7af84ec8bbf181569a4dbe7368acfbb                                           │
│  │ EventType: 0xf5d2b6fdc9cff7569f696c2aeb8c824839ece0f3b8c035ae5c4ff30621f2f0eb::suins_manager::AdminCreated           │
│  │ ParsedJSON:                                                                                                          │
│  │   ┌──────────────────┬────────────────────────────────────────────────────────────────────┐                          │
│  │   │ admin_id         │ 0xe94de4239f0af7d351e6894464cbeace43e6ba8902732c492df8ad17a456514a │                          │
│  │   ├──────────────────┼────────────────────────────────────────────────────────────────────┤                          │
│  │   │ creator          │ 0x4fcb599f85adb345fd608c69040615caa7af84ec8bbf181569a4dbe7368acfbb │                          │
│  │   ├──────────────────┼────────────────────────────────────────────────────────────────────┤                          │
│  │   │ suins_manager_id │ 0xa9cc569df704519c1811e84aa6b5e0522e81ac922f25a6f1861a795da75213b6 │                          │
│  │   └──────────────────┴────────────────────────────────────────────────────────────────────┘                          │
│  └──                                                                                                                    │
╰─────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────╯
╭────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────╮
│ Object Changes                                                                                                                                                                                                                                     │
├────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────┤
│ Created Objects:                                                                                                                                                                                                                                   │
│  ┌──                                                                                                                                                                                                                                               │
│  │ ObjectID: 0x09839ac664fb54f6db4e5d63c4a8fd168932f353fffff6a3594392a2dd9dac94                                                                                                                                                                    │
│  │ Sender: 0x4fcb599f85adb345fd608c69040615caa7af84ec8bbf181569a4dbe7368acfbb                                                                                                                                                                      │
│  │ Owner: Account Address ( 0x4fcb599f85adb345fd608c69040615caa7af84ec8bbf181569a4dbe7368acfbb )                                                                                                                                                   │
│  │ ObjectType: 0x2::package::UpgradeCap                                                                                                                                                                                                            │
│  │ Version: 623841004                                                                                                                                                                                                                              │
│  │ Digest: CTSdwW6KLrJk7BPFZnE53R1ARgVaN9bC5XfXV4A6EGyd                                                                                                                                                                                            │
│  └──                                                                                                                                                                                                                                               │
│  ┌──                                                                                                                                                                                                                                               │
│  │ ObjectID: 0x16e38b4863ea42bf4210346d994885a0a4a2d4d30d48028f8b228f656f2c0656                                                                                                                                                                    │
│  │ Sender: 0x4fcb599f85adb345fd608c69040615caa7af84ec8bbf181569a4dbe7368acfbb                                                                                                                                                                      │
│  │ Owner: Object ID: ( 0x898b24f1adc1eff7c5e19fa5c3dadf2b26e16adf8de456274064881efda05d53 )                                                                                                                                                        │
│  │ ObjectType: 0x2::dynamic_field::Field<0x1::string::String, 0xf5d2b6fdc9cff7569f696c2aeb8c824839ece0f3b8c035ae5c4ff30621f2f0eb::platform_policy::Policy>                                                                                         │
│  │ Version: 623841004                                                                                                                                                                                                                              │
│  │ Digest: D3KcivL2zYYYT4NEH4ozknEGYHkouMvSWbVfP3wNudsA                                                                                                                                                                                            │
│  └──                                                                                                                                                                                                                                               │
│  ┌──                                                                                                                                                                                                                                               │
│  │ ObjectID: 0x27fd4da16127b07b6127bb32fb0979771a04e0382d218fc2fd79ebcf9fc7f46a                                                                                                                                                                    │
│  │ Sender: 0x4fcb599f85adb345fd608c69040615caa7af84ec8bbf181569a4dbe7368acfbb                                                                                                                                                                      │
│  │ Owner: Shared( 623841004 )                                                                                                                                                                                                                      │
│  │ ObjectType: 0xf5d2b6fdc9cff7569f696c2aeb8c824839ece0f3b8c035ae5c4ff30621f2f0eb::badge_rewards::BadgeConfig                                                                                                                                      │
│  │ Version: 623841004                                                                                                                                                                                                                              │
│  │ Digest: 3fUutVmaNc2QSRd7JGj1xw96JeD6cynr46bfYPyGgpL6                                                                                                                                                                                            │
│  └──                                                                                                                                                                                                                                               │
│  ┌──                                                                                                                                                                                                                                               │
│  │ ObjectID: 0x2adf37351f87becf103a570af3c32e4579a5d00024181e16da88bea37342b137                                                                                                                                                                    │
│  │ Sender: 0x4fcb599f85adb345fd608c69040615caa7af84ec8bbf181569a4dbe7368acfbb                                                                                                                                                                      │
│  │ Owner: Shared( 623841004 )                                                                                                                                                                                                                      │
│  │ ObjectType: 0xf5d2b6fdc9cff7569f696c2aeb8c824839ece0f3b8c035ae5c4ff30621f2f0eb::platform_policy::PolicyRegistry                                                                                                                                 │
│  │ Version: 623841004                                                                                                                                                                                                                              │
│  │ Digest: EzDQS7YZcFhH5JaLRZHYtXKNE5KQgBJfQjWNUpnTtWmY                                                                                                                                                                                            │
│  └──                                                                                                                                                                                                                                               │
│  ┌──                                                                                                                                                                                                                                               │
│  │ ObjectID: 0x8db76c73f61ec85a9d116d1e2a658c6c47bc77b3782e4fbb265ef6c23c5fc67f                                                                                                                                                                    │
│  │ Sender: 0x4fcb599f85adb345fd608c69040615caa7af84ec8bbf181569a4dbe7368acfbb                                                                                                                                                                      │
│  │ Owner: Shared( 623841004 )                                                                                                                                                                                                                      │
│  │ ObjectType: 0xf5d2b6fdc9cff7569f696c2aeb8c824839ece0f3b8c035ae5c4ff30621f2f0eb::crowd_walrus::CrowdWalrus                                                                                                                                       │
│  │ Version: 623841004                                                                                                                                                                                                                              │
│  │ Digest: AK5qqzTtonqLSVeKpCcuFQ9eTXSnLuSfpJjHSUvYiYWG                                                                                                                                                                                            │
│  └──                                                                                                                                                                                                                                               │
│  ┌──                                                                                                                                                                                                                                               │
│  │ ObjectID: 0x8fe72299a328a9d9f63d21f3f49086cccee8a9b76cab5898cebf1411f6b5d09b                                                                                                                                                                    │
│  │ Sender: 0x4fcb599f85adb345fd608c69040615caa7af84ec8bbf181569a4dbe7368acfbb                                                                                                                                                                      │
│  │ Owner: Object ID: ( 0x8db76c73f61ec85a9d116d1e2a658c6c47bc77b3782e4fbb265ef6c23c5fc67f )                                                                                                                                                        │
│  │ ObjectType: 0x2::dynamic_field::Field<0xf5d2b6fdc9cff7569f696c2aeb8c824839ece0f3b8c035ae5c4ff30621f2f0eb::crowd_walrus::TokenRegistryKey, 0xf5d2b6fdc9cff7569f696c2aeb8c824839ece0f3b8c035ae5c4ff30621f2f0eb::crowd_walrus::TokenRegistrySlot>  │
│  │ Version: 623841004                                                                                                                                                                                                                              │
│  │ Digest: Bc1BsCFhC1pN4ngdNjuLE99RSz6Sj8MnGH2wugQpCY8h                                                                                                                                                                                            │
│  └──                                                                                                                                                                                                                                               │
│  ┌──                                                                                                                                                                                                                                               │
│  │ ObjectID: 0xa9cc569df704519c1811e84aa6b5e0522e81ac922f25a6f1861a795da75213b6                                                                                                                                                                    │
│  │ Sender: 0x4fcb599f85adb345fd608c69040615caa7af84ec8bbf181569a4dbe7368acfbb                                                                                                                                                                      │
│  │ Owner: Shared( 623841004 )                                                                                                                                                                                                                      │
│  │ ObjectType: 0xf5d2b6fdc9cff7569f696c2aeb8c824839ece0f3b8c035ae5c4ff30621f2f0eb::suins_manager::SuiNSManager                                                                                                                                     │
│  │ Version: 623841004                                                                                                                                                                                                                              │
│  │ Digest: B4e5Xob9vN24jfrMP7TRpe2oATc8asztunmPFkGL4uP2                                                                                                                                                                                            │
│  └──                                                                                                                                                                                                                                               │
│  ┌──                                                                                                                                                                                                                                               │
│  │ ObjectID: 0xc1a5b7ebe13c51d57889f78123e3de87b852d6f6d956c2ca40fc9ce61872bcfe                                                                                                                                                                    │
│  │ Sender: 0x4fcb599f85adb345fd608c69040615caa7af84ec8bbf181569a4dbe7368acfbb                                                                                                                                                                      │
│  │ Owner: Shared( 623841004 )                                                                                                                                                                                                                      │
│  │ ObjectType: 0xf5d2b6fdc9cff7569f696c2aeb8c824839ece0f3b8c035ae5c4ff30621f2f0eb::token_registry::TokenRegistry                                                                                                                                   │
│  │ Version: 623841004                                                                                                                                                                                                                              │
│  │ Digest: 8gWvNvpYRvrDNrX6igkmseAq95L3KPkokRrTkJ4BhDUE                                                                                                                                                                                            │
│  └──                                                                                                                                                                                                                                               │
│  ┌──                                                                                                                                                                                                                                               │
│  │ ObjectID: 0xcce63d8e3fba9530218b83af57360abd730382a71bec9c5616f1b23fe19d7f02                                                                                                                                                                    │
│  │ Sender: 0x4fcb599f85adb345fd608c69040615caa7af84ec8bbf181569a4dbe7368acfbb                                                                                                                                                                      │
│  │ Owner: Object ID: ( 0xa9cc569df704519c1811e84aa6b5e0522e81ac922f25a6f1861a795da75213b6 )                                                                                                                                                        │
│  │ ObjectType: 0x2::dynamic_field::Field<0xf5d2b6fdc9cff7569f696c2aeb8c824839ece0f3b8c035ae5c4ff30621f2f0eb::suins_manager::AppKey<0xf5d2b6fdc9cff7569f696c2aeb8c824839ece0f3b8c035ae5c4ff30621f2f0eb::crowd_walrus::CrowdWalrusApp>, bool>        │
│  │ Version: 623841004                                                                                                                                                                                                                              │
│  │ Digest: 9LNRNFuPuBGDkkK5dtorNbmo15pZsNB8PPiTxRQAXpYE                                                                                                                                                                                            │
│  └──                                                                                                                                                                                                                                               │
│  ┌──                                                                                                                                                                                                                                               │
│  │ ObjectID: 0xd71bc7cd83f6b2ca8d6241264553fe9dc22c65f52104e19424c670983942fe8f                                                                                                                                                                    │
│  │ Sender: 0x4fcb599f85adb345fd608c69040615caa7af84ec8bbf181569a4dbe7368acfbb                                                                                                                                                                      │
│  │ Owner: Account Address ( 0x4fcb599f85adb345fd608c69040615caa7af84ec8bbf181569a4dbe7368acfbb )                                                                                                                                                   │
│  │ ObjectType: 0xf5d2b6fdc9cff7569f696c2aeb8c824839ece0f3b8c035ae5c4ff30621f2f0eb::crowd_walrus::AdminCap                                                                                                                                          │
│  │ Version: 623841004                                                                                                                                                                                                                              │
│  │ Digest: FpM7Mrm29Yvmng2C1egPuWaAC9w88DCmpKHZef86KaV3                                                                                                                                                                                            │
│  └──                                                                                                                                                                                                                                               │
│  ┌──                                                                                                                                                                                                                                               │
│  │ ObjectID: 0xd7fe4cdf6df2fa3f566019b3110d5a7d1573abb9995835adce516747b3153686                                                                                                                                                                    │
│  │ Sender: 0x4fcb599f85adb345fd608c69040615caa7af84ec8bbf181569a4dbe7368acfbb                                                                                                                                                                      │
│  │ Owner: Shared( 623841004 )                                                                                                                                                                                                                      │
│  │ ObjectType: 0xf5d2b6fdc9cff7569f696c2aeb8c824839ece0f3b8c035ae5c4ff30621f2f0eb::profiles::ProfilesRegistry                                                                                                                                      │
│  │ Version: 623841004                                                                                                                                                                                                                              │
│  │ Digest: FeAUgFLLSvp1UwStUSodWKDzWX8PBurBzsUYcUzX7Jvm                                                                                                                                                                                            │
│  └──                                                                                                                                                                                                                                               │
│  ┌──                                                                                                                                                                                                                                               │
│  │ ObjectID: 0xe94de4239f0af7d351e6894464cbeace43e6ba8902732c492df8ad17a456514a                                                                                                                                                                    │
│  │ Sender: 0x4fcb599f85adb345fd608c69040615caa7af84ec8bbf181569a4dbe7368acfbb                                                                                                                                                                      │
│  │ Owner: Account Address ( 0x4fcb599f85adb345fd608c69040615caa7af84ec8bbf181569a4dbe7368acfbb )                                                                                                                                                   │
│  │ ObjectType: 0xf5d2b6fdc9cff7569f696c2aeb8c824839ece0f3b8c035ae5c4ff30621f2f0eb::suins_manager::AdminCap                                                                                                                                         │
│  │ Version: 623841004                                                                                                                                                                                                                              │
│  │ Digest: 4cqf29v8WWNF6S2ysXZKEFhApoKM4PPq7xhj8jDq4iQg                                                                                                                                                                                            │
│  └──                                                                                                                                                                                                                                               │
│ Mutated Objects:                                                                                                                                                                                                                                   │
│  ┌──                                                                                                                                                                                                                                               │
│  │ ObjectID: 0xb8cd20f1a0a2a18a1fa21e7fec66b26dc9cc09bef16e79a5c3c0ad93646fcf8e                                                                                                                                                                    │
│  │ Sender: 0x4fcb599f85adb345fd608c69040615caa7af84ec8bbf181569a4dbe7368acfbb                                                                                                                                                                      │
│  │ Owner: Account Address ( 0x4fcb599f85adb345fd608c69040615caa7af84ec8bbf181569a4dbe7368acfbb )                                                                                                                                                   │
│  │ ObjectType: 0x2::coin::Coin<0x2::sui::SUI>                                                                                                                                                                                                      │
│  │ Version: 623841004                                                                                                                                                                                                                              │
│  │ Digest: 288emyyijwqn5yEvPYLgWZh1hrZJPEn4YRAwg9STNV81                                                                                                                                                                                            │
│  └──                                                                                                                                                                                                                                               │
│ Published Objects:                                                                                                                                                                                                                                 │
│  ┌──                                                                                                                                                                                                                                               │
│  │ PackageID: 0xf5d2b6fdc9cff7569f696c2aeb8c824839ece0f3b8c035ae5c4ff30621f2f0eb                                                                                                                                                                   │
│  │ Version: 1                                                                                                                                                                                                                                      │
│  │ Digest: 9EUxYaRpXYoSWYAEPnbdpaHLiy1qxcpeBxV7KVqMkJAB                                                                                                                                                                                            │
│  │ Modules: badge_rewards, campaign, campaign_stats, crowd_walrus, donations, platform_policy, price_oracle, profiles, suins_manager, token_registry                                                                                               │
│  └──                                                                                                                                                                                                                                               │
╰────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────╯
╭───────────────────────────────────────────────────────────────────────────────────────────────────╮
│ Balance Changes                                                                                   │
├───────────────────────────────────────────────────────────────────────────────────────────────────┤
│  ┌──                                                                                              │
│  │ Owner: Account Address ( 0x4fcb599f85adb345fd608c69040615caa7af84ec8bbf181569a4dbe7368acfbb )  │
│  │ CoinType: 0x2::sui::SUI                                                                        │
│  │ Amount: -313626280                                                                             │
│  └──                                                                                              │
╰───────────────────────────────────────────────────────────────────────────────────────────────────╯
```
