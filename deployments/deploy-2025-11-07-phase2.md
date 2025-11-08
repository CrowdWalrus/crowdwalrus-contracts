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
Transaction Digest: CqFei2NF4saCuoWCgMiK9yUWSD4LE7nVY2EDbBEnqfs4
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
│  │ Version: 623841004                                                                                        │
│  │ Digest: 288emyyijwqn5yEvPYLgWZh1hrZJPEn4YRAwg9STNV81                                                      │
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
│    Q6C+yJHeww1NLeG05xrkgL2rqfSdzVlBvPADbYIaASiqGzHp423NUIaKz4GWc7Koij+5RZyoUrAQTvDXU4P2Dw==                  │
│                                                                                                              │
╰──────────────────────────────────────────────────────────────────────────────────────────────────────────────╯
╭───────────────────────────────────────────────────────────────────────────────────────────────────╮
│ Transaction Effects                                                                               │
├───────────────────────────────────────────────────────────────────────────────────────────────────┤
│ Digest: CqFei2NF4saCuoWCgMiK9yUWSD4LE7nVY2EDbBEnqfs4                                              │
│ Status: Success                                                                                   │
│ Executed Epoch: 911                                                                               │
│                                                                                                   │
│ Created Objects:                                                                                  │
│  ┌──                                                                                              │
│  │ ID: 0x10e5b1e7f63c33d8e49eeac79168badfb9b271209bd12a59bbcde1ecd0187596                         │
│  │ Owner: Shared( 623841005 )                                                                     │
│  │ Version: 623841005                                                                             │
│  │ Digest: 4Cb2onU5XhDG8MvXmg1U7stk9M86hrYHXdCVH5zFVR4s                                           │
│  └──                                                                                              │
│  ┌──                                                                                              │
│  │ ID: 0x10fcf8049ced73339c8fe8bef00bdd53312f932619ed7687e9baa17e5e02f097                         │
│  │ Owner: Account Address ( 0x4fcb599f85adb345fd608c69040615caa7af84ec8bbf181569a4dbe7368acfbb )  │
│  │ Version: 623841005                                                                             │
│  │ Digest: BAwhc55Xki65BZKDR1uccFGmq339yG3DrKjURKBbiEsu                                           │
│  └──                                                                                              │
│  ┌──                                                                                              │
│  │ ID: 0x14285866eb0b353bf8d2dcbc8b185189b6756b41481de63bf0c9a7dafa6cfa48                         │
│  │ Owner: Object ID: ( 0x10e5b1e7f63c33d8e49eeac79168badfb9b271209bd12a59bbcde1ecd0187596 )       │
│  │ Version: 623841005                                                                             │
│  │ Digest: 8CXubS6pSNozD6hhXQQEf9TDpBRemYUB4Wso8ncKfHLK                                           │
│  └──                                                                                              │
│  ┌──                                                                                              │
│  │ ID: 0x3d220d55745a74563ea5b0af717c2957bd17954be6403e738b8994875766afa3                         │
│  │ Owner: Account Address ( 0x4fcb599f85adb345fd608c69040615caa7af84ec8bbf181569a4dbe7368acfbb )  │
│  │ Version: 623841005                                                                             │
│  │ Digest: BzEvbtPfZUzr73fTZuGDCWeCUc69s8WhymfR33S8XdJ5                                           │
│  └──                                                                                              │
│  ┌──                                                                                              │
│  │ ID: 0x48ceb4364109da3b9cd889d29dc9e14bafa5983777ccaa3f5d6385958b8190cf                         │
│  │ Owner: Shared( 623841005 )                                                                     │
│  │ Version: 623841005                                                                             │
│  │ Digest: DjRWw3ZCfBDcNEa6ubmiGGAMZFybv3mWu3sw3iXqBU8p                                           │
│  └──                                                                                              │
│  ┌──                                                                                              │
│  │ ID: 0x71c1e75eb42a29a81680f9f1e454e87468561a5cd28e2217e841c6693d00ea23                         │
│  │ Owner: Shared( 623841005 )                                                                     │
│  │ Version: 623841005                                                                             │
│  │ Digest: D8JY5Q2fBXs5hN87ocVE7XosY2uz5qhQTaCCrapA5X1M                                           │
│  └──                                                                                              │
│  ┌──                                                                                              │
│  │ ID: 0x8484f94adc0330eeb9b580b5550614480a41dd7143b6a312faa24dae45ded855                         │
│  │ Owner: Object ID: ( 0x48ceb4364109da3b9cd889d29dc9e14bafa5983777ccaa3f5d6385958b8190cf )       │
│  │ Version: 623841005                                                                             │
│  │ Digest: EhoZEwebkEVzC6jreE7tzPvEVF9ucwLfRzun939kXLDS                                           │
│  └──                                                                                              │
│  ┌──                                                                                              │
│  │ ID: 0xaf5058f1ff30262fdeeeaa325b4b1ce12a73015abbf22867f63e9f449bb9e8c3                         │
│  │ Owner: Shared( 623841005 )                                                                     │
│  │ Version: 623841005                                                                             │
│  │ Digest: GynJSJHJD1qRMKqKmbkBsucTJjC6iLAtTjbzzdfU2YCM                                           │
│  └──                                                                                              │
│  ┌──                                                                                              │
│  │ ID: 0xafd251e536c837dc64ef58881965f2222b9e0f9966f9296f1f967367cb5da78b                         │
│  │ Owner: Account Address ( 0x4fcb599f85adb345fd608c69040615caa7af84ec8bbf181569a4dbe7368acfbb )  │
│  │ Version: 623841005                                                                             │
│  │ Digest: CQrRauBdw46k9MbofK4x1nSDudLQf62zK4jfEgZLNeiF                                           │
│  └──                                                                                              │
│  ┌──                                                                                              │
│  │ ID: 0xbbd5230ca6bd3a97109e26c76464baee1540f2e9376a60046f50d4bfc2c3e435                         │
│  │ Owner: Account Address ( 0x4fcb599f85adb345fd608c69040615caa7af84ec8bbf181569a4dbe7368acfbb )  │
│  │ Version: 623841005                                                                             │
│  │ Digest: 3kikV96ShNtVQsM1z3sEKr43T1Us6W7zXfXtu2Wu5Ffh                                           │
│  └──                                                                                              │
│  ┌──                                                                                              │
│  │ ID: 0xc762a509c02849b7ca0b63eb4226c1fb87aed519af51258424a3591faaacac10                         │
│  │ Owner: Immutable                                                                               │
│  │ Version: 1                                                                                     │
│  │ Digest: 8MJsfgV3RrXyjYHYVAhXcgRUYFK4ux2fTemoxZ6jPMAT                                           │
│  └──                                                                                              │
│  ┌──                                                                                              │
│  │ ID: 0xd72f3907908b0575afea266c457c0109690ab11e8568106364c76e2444c2aeac                         │
│  │ Owner: Shared( 623841005 )                                                                     │
│  │ Version: 623841005                                                                             │
│  │ Digest: YTjwRczK3T37pUcQ8FES6J9tXNsdBNC7cHiYRmXUKPc                                            │
│  └──                                                                                              │
│  ┌──                                                                                              │
│  │ ID: 0xee1330d94cd954ae58fd18a8336738562f05487fae56dda9c655f461eac52b6f                         │
│  │ Owner: Shared( 623841005 )                                                                     │
│  │ Version: 623841005                                                                             │
│  │ Digest: 6jka1y3p4VseKzed15VAkvzArjjBCWejemnsUcx4qVwk                                           │
│  └──                                                                                              │
│  ┌──                                                                                              │
│  │ ID: 0xf0f4ad823f383b1433e567567201eddda1cf72c7eb72c51abe83d51ec6891535                         │
│  │ Owner: Object ID: ( 0x9dc9126443d1c0d39b6142e9cc38960495b359da386c817aa36816c0d9c98cd4 )       │
│  │ Version: 623841005                                                                             │
│  │ Digest: D99eat6S5u33LVKjD1Yy8cZcqVLopfAu5Em3w81YBL2y                                           │
│  └──                                                                                              │
│ Mutated Objects:                                                                                  │
│  ┌──                                                                                              │
│  │ ID: 0xb8cd20f1a0a2a18a1fa21e7fec66b26dc9cc09bef16e79a5c3c0ad93646fcf8e                         │
│  │ Owner: Account Address ( 0x4fcb599f85adb345fd608c69040615caa7af84ec8bbf181569a4dbe7368acfbb )  │
│  │ Version: 623841005                                                                             │
│  │ Digest: QLcL5MK43o6EPF3vH7fac84zopMxHNKTqTjL2Qm8Hj8                                            │
│  └──                                                                                              │
│ Gas Object:                                                                                       │
│  ┌──                                                                                              │
│  │ ID: 0xb8cd20f1a0a2a18a1fa21e7fec66b26dc9cc09bef16e79a5c3c0ad93646fcf8e                         │
│  │ Owner: Account Address ( 0x4fcb599f85adb345fd608c69040615caa7af84ec8bbf181569a4dbe7368acfbb )  │
│  │ Version: 623841005                                                                             │
│  │ Digest: QLcL5MK43o6EPF3vH7fac84zopMxHNKTqTjL2Qm8Hj8                                            │
│  └──                                                                                              │
│ Gas Cost Summary:                                                                                 │
│    Storage Cost: 312892000 MIST                                                                   │
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
│    E2asrnMvFS9fg3gJ6ewLMzNe1BdA2rJDRxnAFeqTduqt                                                   │
│    GppkRKgQ5ZXNWpCC3BTd9tXG4zF3ACacZK9Pu8eCvJiz                                                   │
╰───────────────────────────────────────────────────────────────────────────────────────────────────╯
╭─────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────╮
│ Transaction Block Events                                                                                                │
├─────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────┤
│  ┌──                                                                                                                    │
│  │ EventID: CqFei2NF4saCuoWCgMiK9yUWSD4LE7nVY2EDbBEnqfs4:0                                                              │
│  │ PackageID: 0xc762a509c02849b7ca0b63eb4226c1fb87aed519af51258424a3591faaacac10                                        │
│  │ Transaction Module: crowd_walrus                                                                                     │
│  │ Sender: 0x4fcb599f85adb345fd608c69040615caa7af84ec8bbf181569a4dbe7368acfbb                                           │
│  │ EventType: 0xc762a509c02849b7ca0b63eb4226c1fb87aed519af51258424a3591faaacac10::platform_policy::PolicyAdded          │
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
│  │ EventID: CqFei2NF4saCuoWCgMiK9yUWSD4LE7nVY2EDbBEnqfs4:1                                                              │
│  │ PackageID: 0xc762a509c02849b7ca0b63eb4226c1fb87aed519af51258424a3591faaacac10                                        │
│  │ Transaction Module: crowd_walrus                                                                                     │
│  │ Sender: 0x4fcb599f85adb345fd608c69040615caa7af84ec8bbf181569a4dbe7368acfbb                                           │
│  │ EventType: 0xc762a509c02849b7ca0b63eb4226c1fb87aed519af51258424a3591faaacac10::crowd_walrus::AdminCreated            │
│  │ ParsedJSON:                                                                                                          │
│  │   ┌─────────────────┬────────────────────────────────────────────────────────────────────┐                           │
│  │   │ admin_id        │ 0x3d220d55745a74563ea5b0af717c2957bd17954be6403e738b8994875766afa3 │                           │
│  │   ├─────────────────┼────────────────────────────────────────────────────────────────────┤                           │
│  │   │ creator         │ 0x4fcb599f85adb345fd608c69040615caa7af84ec8bbf181569a4dbe7368acfbb │                           │
│  │   ├─────────────────┼────────────────────────────────────────────────────────────────────┤                           │
│  │   │ crowd_walrus_id │ 0x10e5b1e7f63c33d8e49eeac79168badfb9b271209bd12a59bbcde1ecd0187596 │                           │
│  │   └─────────────────┴────────────────────────────────────────────────────────────────────┘                           │
│  └──                                                                                                                    │
│  ┌──                                                                                                                    │
│  │ EventID: CqFei2NF4saCuoWCgMiK9yUWSD4LE7nVY2EDbBEnqfs4:2                                                              │
│  │ PackageID: 0xc762a509c02849b7ca0b63eb4226c1fb87aed519af51258424a3591faaacac10                                        │
│  │ Transaction Module: crowd_walrus                                                                                     │
│  │ Sender: 0x4fcb599f85adb345fd608c69040615caa7af84ec8bbf181569a4dbe7368acfbb                                           │
│  │ EventType: 0xc762a509c02849b7ca0b63eb4226c1fb87aed519af51258424a3591faaacac10::crowd_walrus::PolicyRegistryCreated   │
│  │ ParsedJSON:                                                                                                          │
│  │   ┌────────────────────┬────────────────────────────────────────────────────────────────────┐                        │
│  │   │ crowd_walrus_id    │ 0x10e5b1e7f63c33d8e49eeac79168badfb9b271209bd12a59bbcde1ecd0187596 │                        │
│  │   ├────────────────────┼────────────────────────────────────────────────────────────────────┤                        │
│  │   │ policy_registry_id │ 0xaf5058f1ff30262fdeeeaa325b4b1ce12a73015abbf22867f63e9f449bb9e8c3 │                        │
│  │   └────────────────────┴────────────────────────────────────────────────────────────────────┘                        │
│  └──                                                                                                                    │
│  ┌──                                                                                                                    │
│  │ EventID: CqFei2NF4saCuoWCgMiK9yUWSD4LE7nVY2EDbBEnqfs4:3                                                              │
│  │ PackageID: 0xc762a509c02849b7ca0b63eb4226c1fb87aed519af51258424a3591faaacac10                                        │
│  │ Transaction Module: crowd_walrus                                                                                     │
│  │ Sender: 0x4fcb599f85adb345fd608c69040615caa7af84ec8bbf181569a4dbe7368acfbb                                           │
│  │ EventType: 0xc762a509c02849b7ca0b63eb4226c1fb87aed519af51258424a3591faaacac10::crowd_walrus::ProfilesRegistryCreated │
│  │ ParsedJSON:                                                                                                          │
│  │   ┌──────────────────────┬────────────────────────────────────────────────────────────────────┐                      │
│  │   │ crowd_walrus_id      │ 0x10e5b1e7f63c33d8e49eeac79168badfb9b271209bd12a59bbcde1ecd0187596 │                      │
│  │   ├──────────────────────┼────────────────────────────────────────────────────────────────────┤                      │
│  │   │ profiles_registry_id │ 0xd72f3907908b0575afea266c457c0109690ab11e8568106364c76e2444c2aeac │                      │
│  │   └──────────────────────┴────────────────────────────────────────────────────────────────────┘                      │
│  └──                                                                                                                    │
│  ┌──                                                                                                                    │
│  │ EventID: CqFei2NF4saCuoWCgMiK9yUWSD4LE7nVY2EDbBEnqfs4:4                                                              │
│  │ PackageID: 0xc762a509c02849b7ca0b63eb4226c1fb87aed519af51258424a3591faaacac10                                        │
│  │ Transaction Module: crowd_walrus                                                                                     │
│  │ Sender: 0x4fcb599f85adb345fd608c69040615caa7af84ec8bbf181569a4dbe7368acfbb                                           │
│  │ EventType: 0xc762a509c02849b7ca0b63eb4226c1fb87aed519af51258424a3591faaacac10::crowd_walrus::TokenRegistryCreated    │
│  │ ParsedJSON:                                                                                                          │
│  │   ┌───────────────────┬────────────────────────────────────────────────────────────────────┐                         │
│  │   │ crowd_walrus_id   │ 0x10e5b1e7f63c33d8e49eeac79168badfb9b271209bd12a59bbcde1ecd0187596 │                         │
│  │   ├───────────────────┼────────────────────────────────────────────────────────────────────┤                         │
│  │   │ token_registry_id │ 0xee1330d94cd954ae58fd18a8336738562f05487fae56dda9c655f461eac52b6f │                         │
│  │   └───────────────────┴────────────────────────────────────────────────────────────────────┘                         │
│  └──                                                                                                                    │
│  ┌──                                                                                                                    │
│  │ EventID: CqFei2NF4saCuoWCgMiK9yUWSD4LE7nVY2EDbBEnqfs4:5                                                              │
│  │ PackageID: 0xc762a509c02849b7ca0b63eb4226c1fb87aed519af51258424a3591faaacac10                                        │
│  │ Transaction Module: crowd_walrus                                                                                     │
│  │ Sender: 0x4fcb599f85adb345fd608c69040615caa7af84ec8bbf181569a4dbe7368acfbb                                           │
│  │ EventType: 0xc762a509c02849b7ca0b63eb4226c1fb87aed519af51258424a3591faaacac10::crowd_walrus::BadgeConfigCreated      │
│  │ ParsedJSON:                                                                                                          │
│  │   ┌─────────────────┬────────────────────────────────────────────────────────────────────┐                           │
│  │   │ badge_config_id │ 0x71c1e75eb42a29a81680f9f1e454e87468561a5cd28e2217e841c6693d00ea23 │                           │
│  │   ├─────────────────┼────────────────────────────────────────────────────────────────────┤                           │
│  │   │ crowd_walrus_id │ 0x10e5b1e7f63c33d8e49eeac79168badfb9b271209bd12a59bbcde1ecd0187596 │                           │
│  │   └─────────────────┴────────────────────────────────────────────────────────────────────┘                           │
│  └──                                                                                                                    │
│  ┌──                                                                                                                    │
│  │ EventID: CqFei2NF4saCuoWCgMiK9yUWSD4LE7nVY2EDbBEnqfs4:6                                                              │
│  │ PackageID: 0xc762a509c02849b7ca0b63eb4226c1fb87aed519af51258424a3591faaacac10                                        │
│  │ Transaction Module: crowd_walrus                                                                                     │
│  │ Sender: 0x4fcb599f85adb345fd608c69040615caa7af84ec8bbf181569a4dbe7368acfbb                                           │
│  │ EventType: 0xc762a509c02849b7ca0b63eb4226c1fb87aed519af51258424a3591faaacac10::suins_manager::SuiNSManagerCreated    │
│  │ ParsedJSON:                                                                                                          │
│  │   ┌──────────────────┬────────────────────────────────────────────────────────────────────┐                          │
│  │   │ creator          │ 0x4fcb599f85adb345fd608c69040615caa7af84ec8bbf181569a4dbe7368acfbb │                          │
│  │   ├──────────────────┼────────────────────────────────────────────────────────────────────┤                          │
│  │   │ suins_manager_id │ 0x48ceb4364109da3b9cd889d29dc9e14bafa5983777ccaa3f5d6385958b8190cf │                          │
│  │   └──────────────────┴────────────────────────────────────────────────────────────────────┘                          │
│  └──                                                                                                                    │
│  ┌──                                                                                                                    │
│  │ EventID: CqFei2NF4saCuoWCgMiK9yUWSD4LE7nVY2EDbBEnqfs4:7                                                              │
│  │ PackageID: 0xc762a509c02849b7ca0b63eb4226c1fb87aed519af51258424a3591faaacac10                                        │
│  │ Transaction Module: crowd_walrus                                                                                     │
│  │ Sender: 0x4fcb599f85adb345fd608c69040615caa7af84ec8bbf181569a4dbe7368acfbb                                           │
│  │ EventType: 0xc762a509c02849b7ca0b63eb4226c1fb87aed519af51258424a3591faaacac10::suins_manager::AdminCreated           │
│  │ ParsedJSON:                                                                                                          │
│  │   ┌──────────────────┬────────────────────────────────────────────────────────────────────┐                          │
│  │   │ admin_id         │ 0xafd251e536c837dc64ef58881965f2222b9e0f9966f9296f1f967367cb5da78b │                          │
│  │   ├──────────────────┼────────────────────────────────────────────────────────────────────┤                          │
│  │   │ creator          │ 0x4fcb599f85adb345fd608c69040615caa7af84ec8bbf181569a4dbe7368acfbb │                          │
│  │   ├──────────────────┼────────────────────────────────────────────────────────────────────┤                          │
│  │   │ suins_manager_id │ 0x48ceb4364109da3b9cd889d29dc9e14bafa5983777ccaa3f5d6385958b8190cf │                          │
│  │   └──────────────────┴────────────────────────────────────────────────────────────────────┘                          │
│  └──                                                                                                                    │
╰─────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────╯
╭────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────╮
│ Object Changes                                                                                                                                                                                                                                     │
├────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────┤
│ Created Objects:                                                                                                                                                                                                                                   │
│  ┌──                                                                                                                                                                                                                                               │
│  │ ObjectID: 0x10e5b1e7f63c33d8e49eeac79168badfb9b271209bd12a59bbcde1ecd0187596                                                                                                                                                                    │
│  │ Sender: 0x4fcb599f85adb345fd608c69040615caa7af84ec8bbf181569a4dbe7368acfbb                                                                                                                                                                      │
│  │ Owner: Shared( 623841005 )                                                                                                                                                                                                                      │
│  │ ObjectType: 0xc762a509c02849b7ca0b63eb4226c1fb87aed519af51258424a3591faaacac10::crowd_walrus::CrowdWalrus                                                                                                                                       │
│  │ Version: 623841005                                                                                                                                                                                                                              │
│  │ Digest: 4Cb2onU5XhDG8MvXmg1U7stk9M86hrYHXdCVH5zFVR4s                                                                                                                                                                                            │
│  └──                                                                                                                                                                                                                                               │
│  ┌──                                                                                                                                                                                                                                               │
│  │ ObjectID: 0x10fcf8049ced73339c8fe8bef00bdd53312f932619ed7687e9baa17e5e02f097                                                                                                                                                                    │
│  │ Sender: 0x4fcb599f85adb345fd608c69040615caa7af84ec8bbf181569a4dbe7368acfbb                                                                                                                                                                      │
│  │ Owner: Account Address ( 0x4fcb599f85adb345fd608c69040615caa7af84ec8bbf181569a4dbe7368acfbb )                                                                                                                                                   │
│  │ ObjectType: 0x2::package::UpgradeCap                                                                                                                                                                                                            │
│  │ Version: 623841005                                                                                                                                                                                                                              │
│  │ Digest: BAwhc55Xki65BZKDR1uccFGmq339yG3DrKjURKBbiEsu                                                                                                                                                                                            │
│  └──                                                                                                                                                                                                                                               │
│  ┌──                                                                                                                                                                                                                                               │
│  │ ObjectID: 0x14285866eb0b353bf8d2dcbc8b185189b6756b41481de63bf0c9a7dafa6cfa48                                                                                                                                                                    │
│  │ Sender: 0x4fcb599f85adb345fd608c69040615caa7af84ec8bbf181569a4dbe7368acfbb                                                                                                                                                                      │
│  │ Owner: Object ID: ( 0x10e5b1e7f63c33d8e49eeac79168badfb9b271209bd12a59bbcde1ecd0187596 )                                                                                                                                                        │
│  │ ObjectType: 0x2::dynamic_field::Field<0xc762a509c02849b7ca0b63eb4226c1fb87aed519af51258424a3591faaacac10::crowd_walrus::TokenRegistryKey, 0xc762a509c02849b7ca0b63eb4226c1fb87aed519af51258424a3591faaacac10::crowd_walrus::TokenRegistrySlot>  │
│  │ Version: 623841005                                                                                                                                                                                                                              │
│  │ Digest: 8CXubS6pSNozD6hhXQQEf9TDpBRemYUB4Wso8ncKfHLK                                                                                                                                                                                            │
│  └──                                                                                                                                                                                                                                               │
│  ┌──                                                                                                                                                                                                                                               │
│  │ ObjectID: 0x3d220d55745a74563ea5b0af717c2957bd17954be6403e738b8994875766afa3                                                                                                                                                                    │
│  │ Sender: 0x4fcb599f85adb345fd608c69040615caa7af84ec8bbf181569a4dbe7368acfbb                                                                                                                                                                      │
│  │ Owner: Account Address ( 0x4fcb599f85adb345fd608c69040615caa7af84ec8bbf181569a4dbe7368acfbb )                                                                                                                                                   │
│  │ ObjectType: 0xc762a509c02849b7ca0b63eb4226c1fb87aed519af51258424a3591faaacac10::crowd_walrus::AdminCap                                                                                                                                          │
│  │ Version: 623841005                                                                                                                                                                                                                              │
│  │ Digest: BzEvbtPfZUzr73fTZuGDCWeCUc69s8WhymfR33S8XdJ5                                                                                                                                                                                            │
│  └──                                                                                                                                                                                                                                               │
│  ┌──                                                                                                                                                                                                                                               │
│  │ ObjectID: 0x48ceb4364109da3b9cd889d29dc9e14bafa5983777ccaa3f5d6385958b8190cf                                                                                                                                                                    │
│  │ Sender: 0x4fcb599f85adb345fd608c69040615caa7af84ec8bbf181569a4dbe7368acfbb                                                                                                                                                                      │
│  │ Owner: Shared( 623841005 )                                                                                                                                                                                                                      │
│  │ ObjectType: 0xc762a509c02849b7ca0b63eb4226c1fb87aed519af51258424a3591faaacac10::suins_manager::SuiNSManager                                                                                                                                     │
│  │ Version: 623841005                                                                                                                                                                                                                              │
│  │ Digest: DjRWw3ZCfBDcNEa6ubmiGGAMZFybv3mWu3sw3iXqBU8p                                                                                                                                                                                            │
│  └──                                                                                                                                                                                                                                               │
│  ┌──                                                                                                                                                                                                                                               │
│  │ ObjectID: 0x71c1e75eb42a29a81680f9f1e454e87468561a5cd28e2217e841c6693d00ea23                                                                                                                                                                    │
│  │ Sender: 0x4fcb599f85adb345fd608c69040615caa7af84ec8bbf181569a4dbe7368acfbb                                                                                                                                                                      │
│  │ Owner: Shared( 623841005 )                                                                                                                                                                                                                      │
│  │ ObjectType: 0xc762a509c02849b7ca0b63eb4226c1fb87aed519af51258424a3591faaacac10::badge_rewards::BadgeConfig                                                                                                                                      │
│  │ Version: 623841005                                                                                                                                                                                                                              │
│  │ Digest: D8JY5Q2fBXs5hN87ocVE7XosY2uz5qhQTaCCrapA5X1M                                                                                                                                                                                            │
│  └──                                                                                                                                                                                                                                               │
│  ┌──                                                                                                                                                                                                                                               │
│  │ ObjectID: 0x8484f94adc0330eeb9b580b5550614480a41dd7143b6a312faa24dae45ded855                                                                                                                                                                    │
│  │ Sender: 0x4fcb599f85adb345fd608c69040615caa7af84ec8bbf181569a4dbe7368acfbb                                                                                                                                                                      │
│  │ Owner: Object ID: ( 0x48ceb4364109da3b9cd889d29dc9e14bafa5983777ccaa3f5d6385958b8190cf )                                                                                                                                                        │
│  │ ObjectType: 0x2::dynamic_field::Field<0xc762a509c02849b7ca0b63eb4226c1fb87aed519af51258424a3591faaacac10::suins_manager::AppKey<0xc762a509c02849b7ca0b63eb4226c1fb87aed519af51258424a3591faaacac10::crowd_walrus::CrowdWalrusApp>, bool>        │
│  │ Version: 623841005                                                                                                                                                                                                                              │
│  │ Digest: EhoZEwebkEVzC6jreE7tzPvEVF9ucwLfRzun939kXLDS                                                                                                                                                                                            │
│  └──                                                                                                                                                                                                                                               │
│  ┌──                                                                                                                                                                                                                                               │
│  │ ObjectID: 0xaf5058f1ff30262fdeeeaa325b4b1ce12a73015abbf22867f63e9f449bb9e8c3                                                                                                                                                                    │
│  │ Sender: 0x4fcb599f85adb345fd608c69040615caa7af84ec8bbf181569a4dbe7368acfbb                                                                                                                                                                      │
│  │ Owner: Shared( 623841005 )                                                                                                                                                                                                                      │
│  │ ObjectType: 0xc762a509c02849b7ca0b63eb4226c1fb87aed519af51258424a3591faaacac10::platform_policy::PolicyRegistry                                                                                                                                 │
│  │ Version: 623841005                                                                                                                                                                                                                              │
│  │ Digest: GynJSJHJD1qRMKqKmbkBsucTJjC6iLAtTjbzzdfU2YCM                                                                                                                                                                                            │
│  └──                                                                                                                                                                                                                                               │
│  ┌──                                                                                                                                                                                                                                               │
│  │ ObjectID: 0xafd251e536c837dc64ef58881965f2222b9e0f9966f9296f1f967367cb5da78b                                                                                                                                                                    │
│  │ Sender: 0x4fcb599f85adb345fd608c69040615caa7af84ec8bbf181569a4dbe7368acfbb                                                                                                                                                                      │
│  │ Owner: Account Address ( 0x4fcb599f85adb345fd608c69040615caa7af84ec8bbf181569a4dbe7368acfbb )                                                                                                                                                   │
│  │ ObjectType: 0xc762a509c02849b7ca0b63eb4226c1fb87aed519af51258424a3591faaacac10::suins_manager::AdminCap                                                                                                                                         │
│  │ Version: 623841005                                                                                                                                                                                                                              │
│  │ Digest: CQrRauBdw46k9MbofK4x1nSDudLQf62zK4jfEgZLNeiF                                                                                                                                                                                            │
│  └──                                                                                                                                                                                                                                               │
│  ┌──                                                                                                                                                                                                                                               │
│  │ ObjectID: 0xbbd5230ca6bd3a97109e26c76464baee1540f2e9376a60046f50d4bfc2c3e435                                                                                                                                                                    │
│  │ Sender: 0x4fcb599f85adb345fd608c69040615caa7af84ec8bbf181569a4dbe7368acfbb                                                                                                                                                                      │
│  │ Owner: Account Address ( 0x4fcb599f85adb345fd608c69040615caa7af84ec8bbf181569a4dbe7368acfbb )                                                                                                                                                   │
│  │ ObjectType: 0x2::package::Publisher                                                                                                                                                                                                             │
│  │ Version: 623841005                                                                                                                                                                                                                              │
│  │ Digest: 3kikV96ShNtVQsM1z3sEKr43T1Us6W7zXfXtu2Wu5Ffh                                                                                                                                                                                            │
│  └──                                                                                                                                                                                                                                               │
│  ┌──                                                                                                                                                                                                                                               │
│  │ ObjectID: 0xd72f3907908b0575afea266c457c0109690ab11e8568106364c76e2444c2aeac                                                                                                                                                                    │
│  │ Sender: 0x4fcb599f85adb345fd608c69040615caa7af84ec8bbf181569a4dbe7368acfbb                                                                                                                                                                      │
│  │ Owner: Shared( 623841005 )                                                                                                                                                                                                                      │
│  │ ObjectType: 0xc762a509c02849b7ca0b63eb4226c1fb87aed519af51258424a3591faaacac10::profiles::ProfilesRegistry                                                                                                                                      │
│  │ Version: 623841005                                                                                                                                                                                                                              │
│  │ Digest: YTjwRczK3T37pUcQ8FES6J9tXNsdBNC7cHiYRmXUKPc                                                                                                                                                                                             │
│  └──                                                                                                                                                                                                                                               │
│  ┌──                                                                                                                                                                                                                                               │
│  │ ObjectID: 0xee1330d94cd954ae58fd18a8336738562f05487fae56dda9c655f461eac52b6f                                                                                                                                                                    │
│  │ Sender: 0x4fcb599f85adb345fd608c69040615caa7af84ec8bbf181569a4dbe7368acfbb                                                                                                                                                                      │
│  │ Owner: Shared( 623841005 )                                                                                                                                                                                                                      │
│  │ ObjectType: 0xc762a509c02849b7ca0b63eb4226c1fb87aed519af51258424a3591faaacac10::token_registry::TokenRegistry                                                                                                                                   │
│  │ Version: 623841005                                                                                                                                                                                                                              │
│  │ Digest: 6jka1y3p4VseKzed15VAkvzArjjBCWejemnsUcx4qVwk                                                                                                                                                                                            │
│  └──                                                                                                                                                                                                                                               │
│  ┌──                                                                                                                                                                                                                                               │
│  │ ObjectID: 0xf0f4ad823f383b1433e567567201eddda1cf72c7eb72c51abe83d51ec6891535                                                                                                                                                                    │
│  │ Sender: 0x4fcb599f85adb345fd608c69040615caa7af84ec8bbf181569a4dbe7368acfbb                                                                                                                                                                      │
│  │ Owner: Object ID: ( 0x9dc9126443d1c0d39b6142e9cc38960495b359da386c817aa36816c0d9c98cd4 )                                                                                                                                                        │
│  │ ObjectType: 0x2::dynamic_field::Field<0x1::string::String, 0xc762a509c02849b7ca0b63eb4226c1fb87aed519af51258424a3591faaacac10::platform_policy::Policy>                                                                                         │
│  │ Version: 623841005                                                                                                                                                                                                                              │
│  │ Digest: D99eat6S5u33LVKjD1Yy8cZcqVLopfAu5Em3w81YBL2y                                                                                                                                                                                            │
│  └──                                                                                                                                                                                                                                               │
│ Mutated Objects:                                                                                                                                                                                                                                   │
│  ┌──                                                                                                                                                                                                                                               │
│  │ ObjectID: 0xb8cd20f1a0a2a18a1fa21e7fec66b26dc9cc09bef16e79a5c3c0ad93646fcf8e                                                                                                                                                                    │
│  │ Sender: 0x4fcb599f85adb345fd608c69040615caa7af84ec8bbf181569a4dbe7368acfbb                                                                                                                                                                      │
│  │ Owner: Account Address ( 0x4fcb599f85adb345fd608c69040615caa7af84ec8bbf181569a4dbe7368acfbb )                                                                                                                                                   │
│  │ ObjectType: 0x2::coin::Coin<0x2::sui::SUI>                                                                                                                                                                                                      │
│  │ Version: 623841005                                                                                                                                                                                                                              │
│  │ Digest: QLcL5MK43o6EPF3vH7fac84zopMxHNKTqTjL2Qm8Hj8                                                                                                                                                                                             │
│  └──                                                                                                                                                                                                                                               │
│ Published Objects:                                                                                                                                                                                                                                 │
│  ┌──                                                                                                                                                                                                                                               │
│  │ PackageID: 0xc762a509c02849b7ca0b63eb4226c1fb87aed519af51258424a3591faaacac10                                                                                                                                                                   │
│  │ Version: 1                                                                                                                                                                                                                                      │
│  │ Digest: 8MJsfgV3RrXyjYHYVAhXcgRUYFK4ux2fTemoxZ6jPMAT                                                                                                                                                                                            │
│  │ Modules: badge_rewards, campaign, campaign_stats, crowd_walrus, donations, platform_policy, price_oracle, profiles, suins_manager, token_registry                                                                                               │
│  └──                                                                                                                                                                                                                                               │
╰────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────╯
╭───────────────────────────────────────────────────────────────────────────────────────────────────╮
│ Balance Changes                                                                                   │
├───────────────────────────────────────────────────────────────────────────────────────────────────┤
│  ┌──                                                                                              │
│  │ Owner: Account Address ( 0x4fcb599f85adb345fd608c69040615caa7af84ec8bbf181569a4dbe7368acfbb )  │
│  │ CoinType: 0x2::sui::SUI                                                                        │
│  │ Amount: -315913880                                                                             │
│  └──                                                                                              │
╰───────────────────────────────────────────────────────────────────────────────────────────────────╯
➜  crowd-walrus-contracts git:(sui-update) ✗
```

## Post-Deployment Admin Actions (Nov 8, 2025)

| Action | Tx Digest | Notes |
|--------|-----------|-------|
| Re-enabled default "standard" platform policy | `BRfLr73CqJjKfFLAT2mPunutjjNkHQF2hFTe25L9sZk9` | Called `crowd_walrus::enable_platform_policy` to emit a fresh `PolicyUpdated` event (0 bps, deployer address) and confirm the preset stays enabled for future campaigns. |
| Added "commercial" policy preset | `JB3YeQupHiSyqhuqNd2bJ7LereRQHWwafni3StwXL14G` | Ran `crowd_walrus::add_platform_policy` to create a 500 bps (5%) preset that routes platform fees to `0x4aa24001f656ee00a56c1d7a16c65973fa65b4b94c0b79adead1cc3b70261f45`. |

| Token | Tx Digests | Notes |
|-------|------------|-------|
| SUI added & enabled | `EMGASi3rii8L9MX4Ld9AEaQmMSLaNJeLrETdvjRJZysc` (add), `99ucADmBk4suaFqNR4fEasSWeAgAsPZSy723AtNoozGR` (enable) | Added with Pyth feed `0x0c723d5e6759de43502f5a10a51bce0858f25ab299147bb7d4fdceaf414cadca`, decimals 9, `max_age_ms=300000`, then enabled. |
| Native USDC added & enabled | `C2TjU2W7cMgpBzmSbatCLkyuLqwbktkdS6sZ5Znn98pw` (add), `GkG73wkDMpYbf8rK7y3YvzsiuKH8yXE55mrwYXwgs6K4` (enable) | Coin type `0xa1ec7fc00a6f40db9693ad1415d0c193ad3906494428cf252621037bd7117e29::usdc::USDC`, feed `0x41f3625971ca2ed2263e78573fe5ce23e13d2558ed3f2e47ab0f84fb9e7ae722`, decimals 6, `max_age_ms=300000`, then enabled. |
| DonorBadge Display registered | `CZWgWxEb318Z728Jt5CSPZSzXEBf9yeRkN6hWFXKeNub` | `badge_rewards::setup_badge_display` produced `Display<DonorBadge>` (templates for name, image_url, description, link) and shared it so wallets can render badges. |
