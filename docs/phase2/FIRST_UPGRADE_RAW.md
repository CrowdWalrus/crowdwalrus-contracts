> Attempted upgrade log (2025-11-10). Resulting package `0x9d6710f1…` was not adopted; production still runs on `0xc762a509…`.

➜  crowd-walrus-contracts git:(fix-donation-ptb-issue) ✗ sui client upgrade \
  --upgrade-capability "$UPGRADE_CAP" \
  --verify-compatibility \
  --gas-budget "$GAS_BUDGET" \
  .
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
Transaction Digest: 6a1wQPsEP85dZaLcr1yhSGkh2Rv5d8MXeadiq3zVbFto
╭────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────╮
│ Transaction Data                                                                                                                                           │
├────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────┤
│ Sender: 0x4fcb599f85adb345fd608c69040615caa7af84ec8bbf181569a4dbe7368acfbb                                                                                 │
│ Gas Owner: 0x4fcb599f85adb345fd608c69040615caa7af84ec8bbf181569a4dbe7368acfbb                                                                              │
│ Gas Budget: 500000000 MIST                                                                                                                                 │
│ Gas Price: 1000 MIST                                                                                                                                       │
│ Gas Payment:                                                                                                                                               │
│  ┌──                                                                                                                                                       │
│  │ ID: 0xb8cd20f1a0a2a18a1fa21e7fec66b26dc9cc09bef16e79a5c3c0ad93646fcf8e                                                                                  │
│  │ Version: 647182187                                                                                                                                      │
│  │ Digest: Dd3U8JPiHhXzn9JjYA854PPqW1BxTwfAxpJ898pYpnWT                                                                                                    │
│  └──                                                                                                                                                       │
│                                                                                                                                                            │
│ Transaction Kind: Programmable                                                                                                                             │
│ ╭────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────╮ │
│ │ Input Objects                                                                                                                                          │ │
│ ├────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────┤ │
│ │ 0   Imm/Owned Object ID: 0x10fcf8049ced73339c8fe8bef00bdd53312f932619ed7687e9baa17e5e02f097                                                            │ │
│ │ 1   Pure Arg: Type: u8, Value: 0                                                                                                                       │ │
│ │ 2   Pure Arg: Type: vector<u8>, Value: [46,179,68,121,222,237,76,170,56,226,64,40,17,10,22,55,30,238,9,60,57,201,177,210,56,125,191,80,224,104,149,92] │ │
│ ╰────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────╯ │
│ ╭───────────────────────────────────────────────────────────────────────────────────────────╮                                                              │
│ │ Commands                                                                                  │                                                              │
│ ├───────────────────────────────────────────────────────────────────────────────────────────┤                                                              │
│ │ 0  MoveCall:                                                                              │                                                              │
│ │  ┌                                                                                        │                                                              │
│ │  │ Function:  authorize_upgrade                                                           │                                                              │
│ │  │ Module:    package                                                                     │                                                              │
│ │  │ Package:   0x0000000000000000000000000000000000000000000000000000000000000002          │                                                              │
│ │  │ Arguments:                                                                             │                                                              │
│ │  │   Input  0                                                                             │                                                              │
│ │  │   Input  1                                                                             │                                                              │
│ │  │   Input  2                                                                             │                                                              │
│ │  └                                                                                        │                                                              │
│ │                                                                                           │                                                              │
│ │ 1  Upgrade:                                                                               │                                                              │
│ │  ┌                                                                                        │                                                              │
│ │  │ Dependencies:                                                                          │                                                              │
│ │  │   0x0000000000000000000000000000000000000000000000000000000000000001                   │                                                              │
│ │  │   0xabf837e98c26087cba0883c0a7a28326b1fa3c5e1e2c5abdb486f9e8f594c837                   │                                                              │
│ │  │   0x0000000000000000000000000000000000000000000000000000000000000002                   │                                                              │
│ │  │   0xf47329f4344f3bf0f8e436e2f7b485466cff300f12a166563995d3888c296a94                   │                                                              │
│ │  │   0xa86c05fbc6371788eb31260dc5085f4bfeab8b95c95d9092c9eb86e63fae3d49                   │                                                              │
│ │  │   0x3c272bc45f9157b7818ece4f7411bdfa8af46303b071aca4e18c03119c9ff636                   │                                                              │
│ │  │   0x67072134f0867b886c9541873d1cb327feb7e161cd56dd76cb6aa9e464410db1                   │                                                              │
│ │  │ Current Package ID: 0xc762a509c02849b7ca0b63eb4226c1fb87aed519af51258424a3591faaacac10 │                                                              │
│ │  │ Ticket: Result 0                                                                       │                                                              │
│ │  └                                                                                        │                                                              │
│ │                                                                                           │                                                              │
│ │ 2  MoveCall:                                                                              │                                                              │
│ │  ┌                                                                                        │                                                              │
│ │  │ Function:  commit_upgrade                                                              │                                                              │
│ │  │ Module:    package                                                                     │                                                              │
│ │  │ Package:   0x0000000000000000000000000000000000000000000000000000000000000002          │                                                              │
│ │  │ Arguments:                                                                             │                                                              │
│ │  │   Input  0                                                                             │                                                              │
│ │  │   Result 1                                                                             │                                                              │
│ │  └                                                                                        │                                                              │
│ ╰───────────────────────────────────────────────────────────────────────────────────────────╯                                                              │
│                                                                                                                                                            │
│ Signatures:                                                                                                                                                │
│    ws0OY4pEXK5caeh7pZ5tJgZTLEL9fpegMsXFyjRY6RqhX57B0GEI1xP7BIBIYzr58RB7h/SbC87Qk34KBMYBAg==                                                                │
│                                                                                                                                                            │
╰────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────╯
╭───────────────────────────────────────────────────────────────────────────────────────────────────╮
│ Transaction Effects                                                                               │
├───────────────────────────────────────────────────────────────────────────────────────────────────┤
│ Digest: 6a1wQPsEP85dZaLcr1yhSGkh2Rv5d8MXeadiq3zVbFto                                              │
│ Status: Success                                                                                   │
│ Executed Epoch: 914                                                                               │
│                                                                                                   │
│ Created Objects:                                                                                  │
│  ┌──                                                                                              │
│  │ ID: 0xc762a509c02849b7ca0b63eb4226c1fb87aed519af51258424a3591faaacac10                         │
│  │ Owner: Immutable                                                                               │
│  │ Version: 2                                                                                     │
│  │ Digest: JBEn4FA5sZ6ZL8oupMkn5U9aEKEyyXzTmHXYyZviiKEA                                           │
│  └──                                                                                              │
│ Mutated Objects:                                                                                  │
│  ┌──                                                                                              │
│  │ ID: 0x10fcf8049ced73339c8fe8bef00bdd53312f932619ed7687e9baa17e5e02f097                         │
│  │ Owner: Account Address ( 0x4fcb599f85adb345fd608c69040615caa7af84ec8bbf181569a4dbe7368acfbb )  │
│  │ Version: 647182188                                                                             │
│  │ Digest: 9xr7kCHznTqfFKEpksiwqmkaTgYM6aRb1DuWERYEgXjk                                           │
│  └──                                                                                              │
│  ┌──                                                                                              │
│  │ ID: 0xb8cd20f1a0a2a18a1fa21e7fec66b26dc9cc09bef16e79a5c3c0ad93646fcf8e                         │
│  │ Owner: Account Address ( 0x4fcb599f85adb345fd608c69040615caa7af84ec8bbf181569a4dbe7368acfbb )  │
│  │ Version: 647182188                                                                             │
│  │ Digest: Fh8Pj14zR3smCQi8gjk2z4D2JjDzTiCqGKuAAVsiiKvh                                           │
│  └──                                                                                              │
│ Gas Object:                                                                                       │
│  ┌──                                                                                              │
│  │ ID: 0xb8cd20f1a0a2a18a1fa21e7fec66b26dc9cc09bef16e79a5c3c0ad93646fcf8e                         │
│  │ Owner: Account Address ( 0x4fcb599f85adb345fd608c69040615caa7af84ec8bbf181569a4dbe7368acfbb )  │
│  │ Version: 647182188                                                                             │
│  │ Digest: Fh8Pj14zR3smCQi8gjk2z4D2JjDzTiCqGKuAAVsiiKvh                                           │
│  └──                                                                                              │
│ Gas Cost Summary:                                                                                 │
│    Storage Cost: 290434000 MIST                                                                   │
│    Computation Cost: 5000000 MIST                                                                 │
│    Storage Rebate: 2595780 MIST                                                                   │
│    Non-refundable Storage Fee: 26220 MIST                                                         │
│                                                                                                   │
│ Transaction Dependencies:                                                                         │
│    4UsjtEMfQyBfpWh5psnDzRqbFpiDecvGQjP57rg1oLP3                                                   │
│    529gXBgfiDC9qTmTmRvuX2iFCsU3RGcmuuiEjpE21EnW                                                   │
│    8hyfuhwkzf4VTRcmKdETXCbYytSKWHvtH4tQBGCQQEYG                                                   │
│    BF2e72MvTgXtwCcf3fJ2Ai89nYhbiR5P3sCxUjcCsjAJ                                                   │
│    CNmS7baTJffHBw3XE4xhYVQfEX5JzWFFRsiEh2XWL44K                                                   │
│    CqFei2NF4saCuoWCgMiK9yUWSD4LE7nVY2EDbBEnqfs4                                                   │
│    Dd9pn1zFcSJjinxQewFd2gQdR4XKsHxFioD5MYnwLZQz                                                   │
│    EUXLEGCyMsaHcWMY16GgWygyhHvjaNFXGMtW8p5PobmC                                                   │
│    GppkRKgQ5ZXNWpCC3BTd9tXG4zF3ACacZK9Pu8eCvJiz                                                   │
╰───────────────────────────────────────────────────────────────────────────────────────────────────╯
╭─────────────────────────────╮
│ No transaction block events │
╰─────────────────────────────╯

╭──────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────╮
│ Object Changes                                                                                                                                       │
├──────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────┤
│ Mutated Objects:                                                                                                                                     │
│  ┌──                                                                                                                                                 │
│  │ ObjectID: 0x10fcf8049ced73339c8fe8bef00bdd53312f932619ed7687e9baa17e5e02f097                                                                      │
│  │ Sender: 0x4fcb599f85adb345fd608c69040615caa7af84ec8bbf181569a4dbe7368acfbb                                                                        │
│  │ Owner: Account Address ( 0x4fcb599f85adb345fd608c69040615caa7af84ec8bbf181569a4dbe7368acfbb )                                                     │
│  │ ObjectType: 0x2::package::UpgradeCap                                                                                                              │
│  │ Version: 647182188                                                                                                                                │
│  │ Digest: 9xr7kCHznTqfFKEpksiwqmkaTgYM6aRb1DuWERYEgXjk                                                                                              │
│  └──                                                                                                                                                 │
│  ┌──                                                                                                                                                 │
│  │ ObjectID: 0xb8cd20f1a0a2a18a1fa21e7fec66b26dc9cc09bef16e79a5c3c0ad93646fcf8e                                                                      │
│  │ Sender: 0x4fcb599f85adb345fd608c69040615caa7af84ec8bbf181569a4dbe7368acfbb                                                                        │
│  │ Owner: Account Address ( 0x4fcb599f85adb345fd608c69040615caa7af84ec8bbf181569a4dbe7368acfbb )                                                     │
│  │ ObjectType: 0x2::coin::Coin<0x2::sui::SUI>                                                                                                        │
│  │ Version: 647182188                                                                                                                                │
│  │ Digest: Fh8Pj14zR3smCQi8gjk2z4D2JjDzTiCqGKuAAVsiiKvh                                                                                              │
│  └──                                                                                                                                                 │
│ Published Objects:                                                                                                                                   │
│  ┌──                                                                                                                                                 │
│  │ PackageID: 0xc762a509c02849b7ca0b63eb4226c1fb87aed519af51258424a3591faaacac10                                                                     │
│  │ Version: 2                                                                                                                                        │
│  │ Digest: JBEn4FA5sZ6ZL8oupMkn5U9aEKEyyXzTmHXYyZviiKEA                                                                                              │
│  │ Modules: badge_rewards, campaign, campaign_stats, crowd_walrus, donations, platform_policy, price_oracle, profiles, suins_manager, token_registry │
│  └──                                                                                                                                                 │
╰──────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────╯
╭───────────────────────────────────────────────────────────────────────────────────────────────────╮
│ Balance Changes                                                                                   │
├───────────────────────────────────────────────────────────────────────────────────────────────────┤
│  ┌──                                                                                              │
│  │ Owner: Account Address ( 0x4fcb599f85adb345fd608c69040615caa7af84ec8bbf181569a4dbe7368acfbb )  │
│  │ CoinType: 0x2::sui::SUI                                                                        │
│  │ Amount: -292838220                                                                             │
│  └──                                                                                              │
╰───────────────────────────────────────────────────────────────────────────────────────────────────╯
➜  crowd-walrus-contracts git:(fix-donation-ptb-issue) ✗
