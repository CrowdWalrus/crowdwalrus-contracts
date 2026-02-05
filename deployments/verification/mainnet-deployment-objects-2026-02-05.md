# Mainnet Deployment Objects (2026-02-05)
## Summary
- Tx digest: `9tJFsfsE1xYR1QKfyXRnxgVhpdNTfNj5ZPVZ5rb2Ju2X`
- Package ID: `0x035cf7b699be1d67785cc54dabc83e497fae23516c0329bea39faabf3384f702`
- Checkpoint: `241918501`
- Timestamp (UTC): `2026-02-05T14:35:44.968000Z`

## Shared Objects
- crowdWalrus: `0x95084b96d2f27283fd91db36166d96c477a02d8d76317655b6ba04cfa24e94a0`
- policyRegistry: `0xb9478cb0359b4a9a6a86b4e9ca2f6a171b7b6405f8ffada12b1f45d68077897c`
- profilesRegistry: `0xd95e1968dcbf42ea0eccb1184ec9c529bbc7b7651b046a7d9247903b14869501`
- tokenRegistry: `0x9409e01b8bafbad0b89e949bcfb8416be7f600f4b87df3bc4103e6f5d78cfb00`
- badgeConfig: `0xdbbc3ed362df0a25b68d62bdcb237c8ea7eb2c109228de69a575dd15a77de43e`
- suinsManager: `0xd71de83cc6a3a1f266b7b1dddb751b3b268ec9cd741e759f827e5fab10d6890e`

## Owned Caps
- adminCap: `0x684646dbd0b0c17ccff97904d59091766599fdbde56a542a29fe869af23bc94c`
- suinsAdminCap: `0x1dd88336103fd741e4bc76d7c0c3c9ebe76361eded792bfa037a13722ac37451`
- publisher: `0xc3b2a631c52092caa19fad982a1dba0531e4a1057f5aa5afa1bf5ebdc2fa6139`
- upgradeCap: `0x8a9731247bc1faa9f2ddea34c665c9aaacb9840b54a18cdadd25ea773ec19ce2`

## Verification
- created objects: `13`
- published objects: `1`
- mutated objects: `1`
- verified ok: `14` / `14`

## Deployment Record (JSON)
```json
{
  "summary": {
    "txDigest": "9tJFsfsE1xYR1QKfyXRnxgVhpdNTfNj5ZPVZ5rb2Ju2X",
    "packageId": "0x035cf7b699be1d67785cc54dabc83e497fae23516c0329bea39faabf3384f702",
    "timestampMs": "1770302144968",
    "checkpoint": "241918501",
    "sharedObjects": {
      "crowdWalrus": "0x95084b96d2f27283fd91db36166d96c477a02d8d76317655b6ba04cfa24e94a0",
      "policyRegistry": "0xb9478cb0359b4a9a6a86b4e9ca2f6a171b7b6405f8ffada12b1f45d68077897c",
      "profilesRegistry": "0xd95e1968dcbf42ea0eccb1184ec9c529bbc7b7651b046a7d9247903b14869501",
      "tokenRegistry": "0x9409e01b8bafbad0b89e949bcfb8416be7f600f4b87df3bc4103e6f5d78cfb00",
      "badgeConfig": "0xdbbc3ed362df0a25b68d62bdcb237c8ea7eb2c109228de69a575dd15a77de43e",
      "suinsManager": "0xd71de83cc6a3a1f266b7b1dddb751b3b268ec9cd741e759f827e5fab10d6890e"
    },
    "ownedCaps": {
      "adminCap": "0x684646dbd0b0c17ccff97904d59091766599fdbde56a542a29fe869af23bc94c",
      "suinsAdminCap": "0x1dd88336103fd741e4bc76d7c0c3c9ebe76361eded792bfa037a13722ac37451",
      "publisher": "0xc3b2a631c52092caa19fad982a1dba0531e4a1057f5aa5afa1bf5ebdc2fa6139",
      "upgradeCap": "0x8a9731247bc1faa9f2ddea34c665c9aaacb9840b54a18cdadd25ea773ec19ce2"
    },
    "verification": {
      "createdObjects": 13,
      "publishedObjects": 1,
      "mutatedObjects": 1,
      "verifiedOk": 14,
      "verifiedTotal": 14
    }
  },
  "createdObjects": [
    {
      "type": "created",
      "sender": "0x0deaf2ae9d8e4877eb7bf5d86434488e343b6881bedff8fc78031b6d0df7c75a",
      "owner": {
        "ObjectOwner": "0x79767ca44deef0c4ecd5f761df162b4b74e69732678fd46cd69fab0167785cbf"
      },
      "objectType": "0x2::dynamic_field::Field<0x1::string::String, 0x035cf7b699be1d67785cc54dabc83e497fae23516c0329bea39faabf3384f702::platform_policy::Policy>",
      "objectId": "0x1dd1fa6ffb4e68007880380cfc206daa80a2275f307d539b0be3a881b5a92799",
      "version": "773550337",
      "digest": "Ge9NRUxFfpTV9TxtVJUXvFxQoAAqz6F6bZfBuFHEXp6N"
    },
    {
      "type": "created",
      "sender": "0x0deaf2ae9d8e4877eb7bf5d86434488e343b6881bedff8fc78031b6d0df7c75a",
      "owner": {
        "AddressOwner": "0x0deaf2ae9d8e4877eb7bf5d86434488e343b6881bedff8fc78031b6d0df7c75a"
      },
      "objectType": "0x035cf7b699be1d67785cc54dabc83e497fae23516c0329bea39faabf3384f702::suins_manager::AdminCap",
      "objectId": "0x1dd88336103fd741e4bc76d7c0c3c9ebe76361eded792bfa037a13722ac37451",
      "version": "773550337",
      "digest": "F9XkSLAj1eNRbSV2S7ZVfBecfU8J7QUC7D62q8evpzKz"
    },
    {
      "type": "created",
      "sender": "0x0deaf2ae9d8e4877eb7bf5d86434488e343b6881bedff8fc78031b6d0df7c75a",
      "owner": {
        "ObjectOwner": "0xd71de83cc6a3a1f266b7b1dddb751b3b268ec9cd741e759f827e5fab10d6890e"
      },
      "objectType": "0x2::dynamic_field::Field<0x035cf7b699be1d67785cc54dabc83e497fae23516c0329bea39faabf3384f702::suins_manager::AppKey<0x035cf7b699be1d67785cc54dabc83e497fae23516c0329bea39faabf3384f702::crowd_walrus::CrowdWalrusApp>, bool>",
      "objectId": "0x37424137afc41c2cf5f6b5ca75c09ef550a9c24d9a8c54482d88c02893722a74",
      "version": "773550337",
      "digest": "J3twcLXFp7AQzyAkjttXCCTytAWGq7ceo94B1HPfYpYv"
    },
    {
      "type": "created",
      "sender": "0x0deaf2ae9d8e4877eb7bf5d86434488e343b6881bedff8fc78031b6d0df7c75a",
      "owner": {
        "AddressOwner": "0x0deaf2ae9d8e4877eb7bf5d86434488e343b6881bedff8fc78031b6d0df7c75a"
      },
      "objectType": "0x035cf7b699be1d67785cc54dabc83e497fae23516c0329bea39faabf3384f702::crowd_walrus::AdminCap",
      "objectId": "0x684646dbd0b0c17ccff97904d59091766599fdbde56a542a29fe869af23bc94c",
      "version": "773550337",
      "digest": "37ZeGJzuAd5a1EhvtJ2J8HPLLD6hjG7bEsS7i3rugT9S"
    },
    {
      "type": "created",
      "sender": "0x0deaf2ae9d8e4877eb7bf5d86434488e343b6881bedff8fc78031b6d0df7c75a",
      "owner": {
        "AddressOwner": "0x0deaf2ae9d8e4877eb7bf5d86434488e343b6881bedff8fc78031b6d0df7c75a"
      },
      "objectType": "0x2::package::UpgradeCap",
      "objectId": "0x8a9731247bc1faa9f2ddea34c665c9aaacb9840b54a18cdadd25ea773ec19ce2",
      "version": "773550337",
      "digest": "4J9hJs2LUxfaX5jzUncNGQMoCcbbLhdsvnwVaz4Cf2dJ"
    },
    {
      "type": "created",
      "sender": "0x0deaf2ae9d8e4877eb7bf5d86434488e343b6881bedff8fc78031b6d0df7c75a",
      "owner": {
        "ObjectOwner": "0x95084b96d2f27283fd91db36166d96c477a02d8d76317655b6ba04cfa24e94a0"
      },
      "objectType": "0x2::dynamic_field::Field<0x035cf7b699be1d67785cc54dabc83e497fae23516c0329bea39faabf3384f702::crowd_walrus::TokenRegistryKey, 0x035cf7b699be1d67785cc54dabc83e497fae23516c0329bea39faabf3384f702::crowd_walrus::TokenRegistrySlot>",
      "objectId": "0x91a547f0f314b273398c35c7d76810366e2a41365f745a0061f92bb946ebeac6",
      "version": "773550337",
      "digest": "EieLFmNFuuuqrHyQRpN51voif5ACn74fhdiAXmswexVM"
    },
    {
      "type": "created",
      "sender": "0x0deaf2ae9d8e4877eb7bf5d86434488e343b6881bedff8fc78031b6d0df7c75a",
      "owner": {
        "Shared": {
          "initial_shared_version": 773550337
        }
      },
      "objectType": "0x035cf7b699be1d67785cc54dabc83e497fae23516c0329bea39faabf3384f702::token_registry::TokenRegistry",
      "objectId": "0x9409e01b8bafbad0b89e949bcfb8416be7f600f4b87df3bc4103e6f5d78cfb00",
      "version": "773550337",
      "digest": "6gkcMnTWZDsa87zfLdyUJKNLGfMLSx1iW14xayZAmMxn"
    },
    {
      "type": "created",
      "sender": "0x0deaf2ae9d8e4877eb7bf5d86434488e343b6881bedff8fc78031b6d0df7c75a",
      "owner": {
        "Shared": {
          "initial_shared_version": 773550337
        }
      },
      "objectType": "0x035cf7b699be1d67785cc54dabc83e497fae23516c0329bea39faabf3384f702::crowd_walrus::CrowdWalrus",
      "objectId": "0x95084b96d2f27283fd91db36166d96c477a02d8d76317655b6ba04cfa24e94a0",
      "version": "773550337",
      "digest": "3NDfdQYDKx38MQg3iGULsG8hR8yQp3zvgFPGieL13oXd"
    },
    {
      "type": "created",
      "sender": "0x0deaf2ae9d8e4877eb7bf5d86434488e343b6881bedff8fc78031b6d0df7c75a",
      "owner": {
        "Shared": {
          "initial_shared_version": 773550337
        }
      },
      "objectType": "0x035cf7b699be1d67785cc54dabc83e497fae23516c0329bea39faabf3384f702::platform_policy::PolicyRegistry",
      "objectId": "0xb9478cb0359b4a9a6a86b4e9ca2f6a171b7b6405f8ffada12b1f45d68077897c",
      "version": "773550337",
      "digest": "9G31ZzBqVmmB8iaRBD9tpz8z6aMrtH3bQnoY7cQW7Y2d"
    },
    {
      "type": "created",
      "sender": "0x0deaf2ae9d8e4877eb7bf5d86434488e343b6881bedff8fc78031b6d0df7c75a",
      "owner": {
        "AddressOwner": "0x0deaf2ae9d8e4877eb7bf5d86434488e343b6881bedff8fc78031b6d0df7c75a"
      },
      "objectType": "0x2::package::Publisher",
      "objectId": "0xc3b2a631c52092caa19fad982a1dba0531e4a1057f5aa5afa1bf5ebdc2fa6139",
      "version": "773550337",
      "digest": "F7fBszhYvvVm8EJuc4ydy1jt1R8uHCKhtDg3h2N2fR4v"
    },
    {
      "type": "created",
      "sender": "0x0deaf2ae9d8e4877eb7bf5d86434488e343b6881bedff8fc78031b6d0df7c75a",
      "owner": {
        "Shared": {
          "initial_shared_version": 773550337
        }
      },
      "objectType": "0x035cf7b699be1d67785cc54dabc83e497fae23516c0329bea39faabf3384f702::suins_manager::SuiNSManager",
      "objectId": "0xd71de83cc6a3a1f266b7b1dddb751b3b268ec9cd741e759f827e5fab10d6890e",
      "version": "773550337",
      "digest": "AUrFzgFe6wMt3WwU8nYXtLHBpoCWW1jqPddmWKz9k2z2"
    },
    {
      "type": "created",
      "sender": "0x0deaf2ae9d8e4877eb7bf5d86434488e343b6881bedff8fc78031b6d0df7c75a",
      "owner": {
        "Shared": {
          "initial_shared_version": 773550337
        }
      },
      "objectType": "0x035cf7b699be1d67785cc54dabc83e497fae23516c0329bea39faabf3384f702::profiles::ProfilesRegistry",
      "objectId": "0xd95e1968dcbf42ea0eccb1184ec9c529bbc7b7651b046a7d9247903b14869501",
      "version": "773550337",
      "digest": "BZ5nZ459d1uBDMewj35aPgP6TP36QvBco1gyovaBWD1x"
    },
    {
      "type": "created",
      "sender": "0x0deaf2ae9d8e4877eb7bf5d86434488e343b6881bedff8fc78031b6d0df7c75a",
      "owner": {
        "Shared": {
          "initial_shared_version": 773550337
        }
      },
      "objectType": "0x035cf7b699be1d67785cc54dabc83e497fae23516c0329bea39faabf3384f702::badge_rewards::BadgeConfig",
      "objectId": "0xdbbc3ed362df0a25b68d62bdcb237c8ea7eb2c109228de69a575dd15a77de43e",
      "version": "773550337",
      "digest": "5yssi6qK6JodGjd8dvPKxMptx6vgMF2UUPqNcgJnmH88"
    }
  ],
  "publishedObjects": [
    {
      "type": "published",
      "packageId": "0x035cf7b699be1d67785cc54dabc83e497fae23516c0329bea39faabf3384f702",
      "version": "1",
      "digest": "EBaaYNPjjCqkCv3MQx31YmqhY4es48Uh9Gbs39oDKDrx",
      "modules": [
        "badge_rewards",
        "campaign",
        "campaign_stats",
        "crowd_walrus",
        "donations",
        "platform_policy",
        "price_oracle",
        "profiles",
        "suins_manager",
        "token_registry"
      ]
    }
  ],
  "mutatedObjects": [
    {
      "type": "mutated",
      "sender": "0x0deaf2ae9d8e4877eb7bf5d86434488e343b6881bedff8fc78031b6d0df7c75a",
      "owner": {
        "AddressOwner": "0x0deaf2ae9d8e4877eb7bf5d86434488e343b6881bedff8fc78031b6d0df7c75a"
      },
      "objectType": "0x2::coin::Coin<0x2::sui::SUI>",
      "objectId": "0x98a43439d58f5ece303484f261f1e533ee92281f4094e1322b974ed756173577",
      "version": "773550337",
      "previousVersion": "773550336",
      "digest": "5vdKK7JLCCAQXiXDCFwPB57mD15fXhbkoLVDxJ2oV5Xi"
    }
  ],
  "verification": [
    {
      "objectId": "0x1dd1fa6ffb4e68007880380cfc206daa80a2275f307d539b0be3a881b5a92799",
      "expectedType": "0x2::dynamic_field::Field<0x1::string::String, 0x035cf7b699be1d67785cc54dabc83e497fae23516c0329bea39faabf3384f702::platform_policy::Policy>",
      "chainType": "0x2::dynamic_field::Field<0x1::string::String, 0x035cf7b699be1d67785cc54dabc83e497fae23516c0329bea39faabf3384f702::platform_policy::Policy>",
      "expectedOwner": {
        "ObjectOwner": "0x79767ca44deef0c4ecd5f761df162b4b74e69732678fd46cd69fab0167785cbf"
      },
      "chainOwner": {
        "ObjectOwner": "0x79767ca44deef0c4ecd5f761df162b4b74e69732678fd46cd69fab0167785cbf"
      },
      "status": "ok"
    },
    {
      "objectId": "0x1dd88336103fd741e4bc76d7c0c3c9ebe76361eded792bfa037a13722ac37451",
      "expectedType": "0x035cf7b699be1d67785cc54dabc83e497fae23516c0329bea39faabf3384f702::suins_manager::AdminCap",
      "chainType": "0x035cf7b699be1d67785cc54dabc83e497fae23516c0329bea39faabf3384f702::suins_manager::AdminCap",
      "expectedOwner": {
        "AddressOwner": "0x0deaf2ae9d8e4877eb7bf5d86434488e343b6881bedff8fc78031b6d0df7c75a"
      },
      "chainOwner": {
        "AddressOwner": "0x0deaf2ae9d8e4877eb7bf5d86434488e343b6881bedff8fc78031b6d0df7c75a"
      },
      "status": "ok"
    },
    {
      "objectId": "0x37424137afc41c2cf5f6b5ca75c09ef550a9c24d9a8c54482d88c02893722a74",
      "expectedType": "0x2::dynamic_field::Field<0x035cf7b699be1d67785cc54dabc83e497fae23516c0329bea39faabf3384f702::suins_manager::AppKey<0x035cf7b699be1d67785cc54dabc83e497fae23516c0329bea39faabf3384f702::crowd_walrus::CrowdWalrusApp>, bool>",
      "chainType": "0x2::dynamic_field::Field<0x035cf7b699be1d67785cc54dabc83e497fae23516c0329bea39faabf3384f702::suins_manager::AppKey<0x035cf7b699be1d67785cc54dabc83e497fae23516c0329bea39faabf3384f702::crowd_walrus::CrowdWalrusApp>, bool>",
      "expectedOwner": {
        "ObjectOwner": "0xd71de83cc6a3a1f266b7b1dddb751b3b268ec9cd741e759f827e5fab10d6890e"
      },
      "chainOwner": {
        "ObjectOwner": "0xd71de83cc6a3a1f266b7b1dddb751b3b268ec9cd741e759f827e5fab10d6890e"
      },
      "status": "ok"
    },
    {
      "objectId": "0x684646dbd0b0c17ccff97904d59091766599fdbde56a542a29fe869af23bc94c",
      "expectedType": "0x035cf7b699be1d67785cc54dabc83e497fae23516c0329bea39faabf3384f702::crowd_walrus::AdminCap",
      "chainType": "0x035cf7b699be1d67785cc54dabc83e497fae23516c0329bea39faabf3384f702::crowd_walrus::AdminCap",
      "expectedOwner": {
        "AddressOwner": "0x0deaf2ae9d8e4877eb7bf5d86434488e343b6881bedff8fc78031b6d0df7c75a"
      },
      "chainOwner": {
        "AddressOwner": "0x0deaf2ae9d8e4877eb7bf5d86434488e343b6881bedff8fc78031b6d0df7c75a"
      },
      "status": "ok"
    },
    {
      "objectId": "0x8a9731247bc1faa9f2ddea34c665c9aaacb9840b54a18cdadd25ea773ec19ce2",
      "expectedType": "0x2::package::UpgradeCap",
      "chainType": "0x2::package::UpgradeCap",
      "expectedOwner": {
        "AddressOwner": "0x0deaf2ae9d8e4877eb7bf5d86434488e343b6881bedff8fc78031b6d0df7c75a"
      },
      "chainOwner": {
        "AddressOwner": "0x0deaf2ae9d8e4877eb7bf5d86434488e343b6881bedff8fc78031b6d0df7c75a"
      },
      "status": "ok"
    },
    {
      "objectId": "0x91a547f0f314b273398c35c7d76810366e2a41365f745a0061f92bb946ebeac6",
      "expectedType": "0x2::dynamic_field::Field<0x035cf7b699be1d67785cc54dabc83e497fae23516c0329bea39faabf3384f702::crowd_walrus::TokenRegistryKey, 0x035cf7b699be1d67785cc54dabc83e497fae23516c0329bea39faabf3384f702::crowd_walrus::TokenRegistrySlot>",
      "chainType": "0x2::dynamic_field::Field<0x035cf7b699be1d67785cc54dabc83e497fae23516c0329bea39faabf3384f702::crowd_walrus::TokenRegistryKey, 0x035cf7b699be1d67785cc54dabc83e497fae23516c0329bea39faabf3384f702::crowd_walrus::TokenRegistrySlot>",
      "expectedOwner": {
        "ObjectOwner": "0x95084b96d2f27283fd91db36166d96c477a02d8d76317655b6ba04cfa24e94a0"
      },
      "chainOwner": {
        "ObjectOwner": "0x95084b96d2f27283fd91db36166d96c477a02d8d76317655b6ba04cfa24e94a0"
      },
      "status": "ok"
    },
    {
      "objectId": "0x9409e01b8bafbad0b89e949bcfb8416be7f600f4b87df3bc4103e6f5d78cfb00",
      "expectedType": "0x035cf7b699be1d67785cc54dabc83e497fae23516c0329bea39faabf3384f702::token_registry::TokenRegistry",
      "chainType": "0x035cf7b699be1d67785cc54dabc83e497fae23516c0329bea39faabf3384f702::token_registry::TokenRegistry",
      "expectedOwner": {
        "Shared": {
          "initial_shared_version": 773550337
        }
      },
      "chainOwner": {
        "Shared": {
          "initial_shared_version": 773550337
        }
      },
      "status": "ok"
    },
    {
      "objectId": "0x95084b96d2f27283fd91db36166d96c477a02d8d76317655b6ba04cfa24e94a0",
      "expectedType": "0x035cf7b699be1d67785cc54dabc83e497fae23516c0329bea39faabf3384f702::crowd_walrus::CrowdWalrus",
      "chainType": "0x035cf7b699be1d67785cc54dabc83e497fae23516c0329bea39faabf3384f702::crowd_walrus::CrowdWalrus",
      "expectedOwner": {
        "Shared": {
          "initial_shared_version": 773550337
        }
      },
      "chainOwner": {
        "Shared": {
          "initial_shared_version": 773550337
        }
      },
      "status": "ok"
    },
    {
      "objectId": "0xb9478cb0359b4a9a6a86b4e9ca2f6a171b7b6405f8ffada12b1f45d68077897c",
      "expectedType": "0x035cf7b699be1d67785cc54dabc83e497fae23516c0329bea39faabf3384f702::platform_policy::PolicyRegistry",
      "chainType": "0x035cf7b699be1d67785cc54dabc83e497fae23516c0329bea39faabf3384f702::platform_policy::PolicyRegistry",
      "expectedOwner": {
        "Shared": {
          "initial_shared_version": 773550337
        }
      },
      "chainOwner": {
        "Shared": {
          "initial_shared_version": 773550337
        }
      },
      "status": "ok"
    },
    {
      "objectId": "0xc3b2a631c52092caa19fad982a1dba0531e4a1057f5aa5afa1bf5ebdc2fa6139",
      "expectedType": "0x2::package::Publisher",
      "chainType": "0x2::package::Publisher",
      "expectedOwner": {
        "AddressOwner": "0x0deaf2ae9d8e4877eb7bf5d86434488e343b6881bedff8fc78031b6d0df7c75a"
      },
      "chainOwner": {
        "AddressOwner": "0x0deaf2ae9d8e4877eb7bf5d86434488e343b6881bedff8fc78031b6d0df7c75a"
      },
      "status": "ok"
    },
    {
      "objectId": "0xd71de83cc6a3a1f266b7b1dddb751b3b268ec9cd741e759f827e5fab10d6890e",
      "expectedType": "0x035cf7b699be1d67785cc54dabc83e497fae23516c0329bea39faabf3384f702::suins_manager::SuiNSManager",
      "chainType": "0x035cf7b699be1d67785cc54dabc83e497fae23516c0329bea39faabf3384f702::suins_manager::SuiNSManager",
      "expectedOwner": {
        "Shared": {
          "initial_shared_version": 773550337
        }
      },
      "chainOwner": {
        "Shared": {
          "initial_shared_version": 773550337
        }
      },
      "status": "ok"
    },
    {
      "objectId": "0xd95e1968dcbf42ea0eccb1184ec9c529bbc7b7651b046a7d9247903b14869501",
      "expectedType": "0x035cf7b699be1d67785cc54dabc83e497fae23516c0329bea39faabf3384f702::profiles::ProfilesRegistry",
      "chainType": "0x035cf7b699be1d67785cc54dabc83e497fae23516c0329bea39faabf3384f702::profiles::ProfilesRegistry",
      "expectedOwner": {
        "Shared": {
          "initial_shared_version": 773550337
        }
      },
      "chainOwner": {
        "Shared": {
          "initial_shared_version": 773550337
        }
      },
      "status": "ok"
    },
    {
      "objectId": "0xdbbc3ed362df0a25b68d62bdcb237c8ea7eb2c109228de69a575dd15a77de43e",
      "expectedType": "0x035cf7b699be1d67785cc54dabc83e497fae23516c0329bea39faabf3384f702::badge_rewards::BadgeConfig",
      "chainType": "0x035cf7b699be1d67785cc54dabc83e497fae23516c0329bea39faabf3384f702::badge_rewards::BadgeConfig",
      "expectedOwner": {
        "Shared": {
          "initial_shared_version": 773550337
        }
      },
      "chainOwner": {
        "Shared": {
          "initial_shared_version": 773550337
        }
      },
      "status": "ok"
    },
    {
      "objectId": "0x035cf7b699be1d67785cc54dabc83e497fae23516c0329bea39faabf3384f702",
      "expectedType": "package",
      "chainType": "package",
      "expectedOwner": "Immutable",
      "chainOwner": "Immutable",
      "status": "ok"
    }
  ],
  "rawTx": {
    "digest": "9tJFsfsE1xYR1QKfyXRnxgVhpdNTfNj5ZPVZ5rb2Ju2X",
    "transaction": {
      "data": {
        "messageVersion": "v1",
        "transaction": {
          "kind": "ProgrammableTransaction",
          "inputs": [
            {
              "type": "pure",
              "valueType": "address",
              "value": "0x0deaf2ae9d8e4877eb7bf5d86434488e343b6881bedff8fc78031b6d0df7c75a"
            }
          ],
          "transactions": [
            {
              "Publish": [
                "0x0000000000000000000000000000000000000000000000000000000000000001",
                "0x04e20ddf36af412a4096f9014f4a565af9e812db9a05cc40254846cf6ed0ad91",
                "0x0000000000000000000000000000000000000000000000000000000000000002",
                "0x5306f64e312b581766351c07af79c72fcb1cd25147157fdc2f8ad76de9a3fb6a",
                "0x71af035413ed499710980ed8adb010bbf2cc5cacf4ab37c7710a4bb87eb58ba5",
                "0xc967b7862d926720761ee15fbd0254a975afa928712abcaa4f7c17bb2b38d38b",
                "0xe0108df96c8dfac6d285e5b8afbeafc9a205002a3ec7807329929c8b4d53a8a0"
              ]
            },
            {
              "TransferObjects": [
                [
                  {
                    "Result": 0
                  }
                ],
                {
                  "Input": 0
                }
              ]
            }
          ]
        },
        "sender": "0x0deaf2ae9d8e4877eb7bf5d86434488e343b6881bedff8fc78031b6d0df7c75a",
        "gasData": {
          "payment": [
            {
              "objectId": "0x98a43439d58f5ece303484f261f1e533ee92281f4094e1322b974ed756173577",
              "version": 773550336,
              "digest": "7J4VNPenC5umjuT2Z71eo4uwr8F8aVWmei8xCdh9csUV"
            }
          ],
          "owner": "0x0deaf2ae9d8e4877eb7bf5d86434488e343b6881bedff8fc78031b6d0df7c75a",
          "price": "516",
          "budget": "500000000"
        }
      },
      "txSignatures": [
        "AMcIYJkwJQJXfKr7cJF454OVERKmONzarWn7lCF1Qea+6ANBH7b7dRqgfWx/AtQbk9+mnJcmzBfV4jNOiER15gH2kJBg/LwnsKrg9YAOh6iaiahK8sMaI1lFOELfahaYKg=="
      ]
    },
    "effects": {
      "messageVersion": "v1",
      "status": {
        "status": "success"
      },
      "executedEpoch": "1029",
      "gasUsed": {
        "computationCost": "2260080",
        "storageCost": "343960800",
        "storageRebate": "978120",
        "nonRefundableStorageFee": "9880"
      },
      "modifiedAtVersions": [
        {
          "objectId": "0x98a43439d58f5ece303484f261f1e533ee92281f4094e1322b974ed756173577",
          "sequenceNumber": "773550336"
        }
      ],
      "transactionDigest": "9tJFsfsE1xYR1QKfyXRnxgVhpdNTfNj5ZPVZ5rb2Ju2X",
      "created": [
        {
          "owner": "Immutable",
          "reference": {
            "objectId": "0x035cf7b699be1d67785cc54dabc83e497fae23516c0329bea39faabf3384f702",
            "version": 1,
            "digest": "EBaaYNPjjCqkCv3MQx31YmqhY4es48Uh9Gbs39oDKDrx"
          }
        },
        {
          "owner": {
            "ObjectOwner": "0x79767ca44deef0c4ecd5f761df162b4b74e69732678fd46cd69fab0167785cbf"
          },
          "reference": {
            "objectId": "0x1dd1fa6ffb4e68007880380cfc206daa80a2275f307d539b0be3a881b5a92799",
            "version": 773550337,
            "digest": "Ge9NRUxFfpTV9TxtVJUXvFxQoAAqz6F6bZfBuFHEXp6N"
          }
        },
        {
          "owner": {
            "AddressOwner": "0x0deaf2ae9d8e4877eb7bf5d86434488e343b6881bedff8fc78031b6d0df7c75a"
          },
          "reference": {
            "objectId": "0x1dd88336103fd741e4bc76d7c0c3c9ebe76361eded792bfa037a13722ac37451",
            "version": 773550337,
            "digest": "F9XkSLAj1eNRbSV2S7ZVfBecfU8J7QUC7D62q8evpzKz"
          }
        },
        {
          "owner": {
            "ObjectOwner": "0xd71de83cc6a3a1f266b7b1dddb751b3b268ec9cd741e759f827e5fab10d6890e"
          },
          "reference": {
            "objectId": "0x37424137afc41c2cf5f6b5ca75c09ef550a9c24d9a8c54482d88c02893722a74",
            "version": 773550337,
            "digest": "J3twcLXFp7AQzyAkjttXCCTytAWGq7ceo94B1HPfYpYv"
          }
        },
        {
          "owner": {
            "AddressOwner": "0x0deaf2ae9d8e4877eb7bf5d86434488e343b6881bedff8fc78031b6d0df7c75a"
          },
          "reference": {
            "objectId": "0x684646dbd0b0c17ccff97904d59091766599fdbde56a542a29fe869af23bc94c",
            "version": 773550337,
            "digest": "37ZeGJzuAd5a1EhvtJ2J8HPLLD6hjG7bEsS7i3rugT9S"
          }
        },
        {
          "owner": {
            "AddressOwner": "0x0deaf2ae9d8e4877eb7bf5d86434488e343b6881bedff8fc78031b6d0df7c75a"
          },
          "reference": {
            "objectId": "0x8a9731247bc1faa9f2ddea34c665c9aaacb9840b54a18cdadd25ea773ec19ce2",
            "version": 773550337,
            "digest": "4J9hJs2LUxfaX5jzUncNGQMoCcbbLhdsvnwVaz4Cf2dJ"
          }
        },
        {
          "owner": {
            "ObjectOwner": "0x95084b96d2f27283fd91db36166d96c477a02d8d76317655b6ba04cfa24e94a0"
          },
          "reference": {
            "objectId": "0x91a547f0f314b273398c35c7d76810366e2a41365f745a0061f92bb946ebeac6",
            "version": 773550337,
            "digest": "EieLFmNFuuuqrHyQRpN51voif5ACn74fhdiAXmswexVM"
          }
        },
        {
          "owner": {
            "Shared": {
              "initial_shared_version": 773550337
            }
          },
          "reference": {
            "objectId": "0x9409e01b8bafbad0b89e949bcfb8416be7f600f4b87df3bc4103e6f5d78cfb00",
            "version": 773550337,
            "digest": "6gkcMnTWZDsa87zfLdyUJKNLGfMLSx1iW14xayZAmMxn"
          }
        },
        {
          "owner": {
            "Shared": {
              "initial_shared_version": 773550337
            }
          },
          "reference": {
            "objectId": "0x95084b96d2f27283fd91db36166d96c477a02d8d76317655b6ba04cfa24e94a0",
            "version": 773550337,
            "digest": "3NDfdQYDKx38MQg3iGULsG8hR8yQp3zvgFPGieL13oXd"
          }
        },
        {
          "owner": {
            "Shared": {
              "initial_shared_version": 773550337
            }
          },
          "reference": {
            "objectId": "0xb9478cb0359b4a9a6a86b4e9ca2f6a171b7b6405f8ffada12b1f45d68077897c",
            "version": 773550337,
            "digest": "9G31ZzBqVmmB8iaRBD9tpz8z6aMrtH3bQnoY7cQW7Y2d"
          }
        },
        {
          "owner": {
            "AddressOwner": "0x0deaf2ae9d8e4877eb7bf5d86434488e343b6881bedff8fc78031b6d0df7c75a"
          },
          "reference": {
            "objectId": "0xc3b2a631c52092caa19fad982a1dba0531e4a1057f5aa5afa1bf5ebdc2fa6139",
            "version": 773550337,
            "digest": "F7fBszhYvvVm8EJuc4ydy1jt1R8uHCKhtDg3h2N2fR4v"
          }
        },
        {
          "owner": {
            "Shared": {
              "initial_shared_version": 773550337
            }
          },
          "reference": {
            "objectId": "0xd71de83cc6a3a1f266b7b1dddb751b3b268ec9cd741e759f827e5fab10d6890e",
            "version": 773550337,
            "digest": "AUrFzgFe6wMt3WwU8nYXtLHBpoCWW1jqPddmWKz9k2z2"
          }
        },
        {
          "owner": {
            "Shared": {
              "initial_shared_version": 773550337
            }
          },
          "reference": {
            "objectId": "0xd95e1968dcbf42ea0eccb1184ec9c529bbc7b7651b046a7d9247903b14869501",
            "version": 773550337,
            "digest": "BZ5nZ459d1uBDMewj35aPgP6TP36QvBco1gyovaBWD1x"
          }
        },
        {
          "owner": {
            "Shared": {
              "initial_shared_version": 773550337
            }
          },
          "reference": {
            "objectId": "0xdbbc3ed362df0a25b68d62bdcb237c8ea7eb2c109228de69a575dd15a77de43e",
            "version": 773550337,
            "digest": "5yssi6qK6JodGjd8dvPKxMptx6vgMF2UUPqNcgJnmH88"
          }
        }
      ],
      "mutated": [
        {
          "owner": {
            "AddressOwner": "0x0deaf2ae9d8e4877eb7bf5d86434488e343b6881bedff8fc78031b6d0df7c75a"
          },
          "reference": {
            "objectId": "0x98a43439d58f5ece303484f261f1e533ee92281f4094e1322b974ed756173577",
            "version": 773550337,
            "digest": "5vdKK7JLCCAQXiXDCFwPB57mD15fXhbkoLVDxJ2oV5Xi"
          }
        }
      ],
      "gasObject": {
        "owner": {
          "AddressOwner": "0x0deaf2ae9d8e4877eb7bf5d86434488e343b6881bedff8fc78031b6d0df7c75a"
        },
        "reference": {
          "objectId": "0x98a43439d58f5ece303484f261f1e533ee92281f4094e1322b974ed756173577",
          "version": 773550337,
          "digest": "5vdKK7JLCCAQXiXDCFwPB57mD15fXhbkoLVDxJ2oV5Xi"
        }
      },
      "eventsDigest": "3bgutZDu6x7xLGq1DXe4bcGT6exHstruRrzdMnz18f3F",
      "dependencies": [
        "5YcEyvpb827y7orDKoLyN2ZHWqW1dY6ByjA2zkk68rqq",
        "7jiEfzJ5ZCREDe2TJhWMxo81TkQmHjidUDhssaJfAdic",
        "9aXs2UJPyeQHV8gq15yXHU91LDjaetPvNRZAVonX2TUh",
        "A7Vb4jFpuH7sicEjY1G5vYLaBBf6uT5RMrsAYhGGUNN1",
        "C3wFcACFqgmaDqW3BArZBbb8gKc6MSrjHUYft6d7FWa3",
        "FLkpZib6FQa9iGKDuJGAu2DNZtHabWTrd9VuUgixvyLh",
        "JBN6xXir7rBYRXVLkfv1qQX7C64z4TA8x1VtixgfwwUc"
      ]
    },
    "events": [
      {
        "id": {
          "txDigest": "9tJFsfsE1xYR1QKfyXRnxgVhpdNTfNj5ZPVZ5rb2Ju2X",
          "eventSeq": "0"
        },
        "packageId": "0x035cf7b699be1d67785cc54dabc83e497fae23516c0329bea39faabf3384f702",
        "transactionModule": "crowd_walrus",
        "sender": "0x0deaf2ae9d8e4877eb7bf5d86434488e343b6881bedff8fc78031b6d0df7c75a",
        "type": "0x035cf7b699be1d67785cc54dabc83e497fae23516c0329bea39faabf3384f702::platform_policy::PolicyAdded",
        "parsedJson": {
          "enabled": true,
          "platform_address": "0x0deaf2ae9d8e4877eb7bf5d86434488e343b6881bedff8fc78031b6d0df7c75a",
          "platform_bps": 0,
          "policy_name": "standard",
          "timestamp_ms": "0"
        },
        "bcsEncoding": "base64",
        "bcs": "CHN0YW5kYXJkAAAN6vKunY5Id+t79dhkNEiONDtogb7f+Px4AxttDffHWgEAAAAAAAAAAA=="
      },
      {
        "id": {
          "txDigest": "9tJFsfsE1xYR1QKfyXRnxgVhpdNTfNj5ZPVZ5rb2Ju2X",
          "eventSeq": "1"
        },
        "packageId": "0x035cf7b699be1d67785cc54dabc83e497fae23516c0329bea39faabf3384f702",
        "transactionModule": "crowd_walrus",
        "sender": "0x0deaf2ae9d8e4877eb7bf5d86434488e343b6881bedff8fc78031b6d0df7c75a",
        "type": "0x035cf7b699be1d67785cc54dabc83e497fae23516c0329bea39faabf3384f702::crowd_walrus::AdminCreated",
        "parsedJson": {
          "admin_id": "0x684646dbd0b0c17ccff97904d59091766599fdbde56a542a29fe869af23bc94c",
          "creator": "0x0deaf2ae9d8e4877eb7bf5d86434488e343b6881bedff8fc78031b6d0df7c75a",
          "crowd_walrus_id": "0x95084b96d2f27283fd91db36166d96c477a02d8d76317655b6ba04cfa24e94a0"
        },
        "bcsEncoding": "base64",
        "bcs": "lQhLltLycoP9kds2Fm2WxHegLY12MXZVtroEz6JOlKBoRkbb0LDBfM/5eQTVkJF2ZZn9veVqVCop/oaa8jvJTA3q8q6djkh363v12GQ0SI40O2iBvt/4/HgDG20N98da"
      },
      {
        "id": {
          "txDigest": "9tJFsfsE1xYR1QKfyXRnxgVhpdNTfNj5ZPVZ5rb2Ju2X",
          "eventSeq": "2"
        },
        "packageId": "0x035cf7b699be1d67785cc54dabc83e497fae23516c0329bea39faabf3384f702",
        "transactionModule": "crowd_walrus",
        "sender": "0x0deaf2ae9d8e4877eb7bf5d86434488e343b6881bedff8fc78031b6d0df7c75a",
        "type": "0x035cf7b699be1d67785cc54dabc83e497fae23516c0329bea39faabf3384f702::crowd_walrus::PolicyRegistryCreated",
        "parsedJson": {
          "crowd_walrus_id": "0x95084b96d2f27283fd91db36166d96c477a02d8d76317655b6ba04cfa24e94a0",
          "policy_registry_id": "0xb9478cb0359b4a9a6a86b4e9ca2f6a171b7b6405f8ffada12b1f45d68077897c"
        },
        "bcsEncoding": "base64",
        "bcs": "lQhLltLycoP9kds2Fm2WxHegLY12MXZVtroEz6JOlKC5R4ywNZtKmmqGtOnKL2oXG3tkBfj/raErH0XWgHeJfA=="
      },
      {
        "id": {
          "txDigest": "9tJFsfsE1xYR1QKfyXRnxgVhpdNTfNj5ZPVZ5rb2Ju2X",
          "eventSeq": "3"
        },
        "packageId": "0x035cf7b699be1d67785cc54dabc83e497fae23516c0329bea39faabf3384f702",
        "transactionModule": "crowd_walrus",
        "sender": "0x0deaf2ae9d8e4877eb7bf5d86434488e343b6881bedff8fc78031b6d0df7c75a",
        "type": "0x035cf7b699be1d67785cc54dabc83e497fae23516c0329bea39faabf3384f702::crowd_walrus::ProfilesRegistryCreated",
        "parsedJson": {
          "crowd_walrus_id": "0x95084b96d2f27283fd91db36166d96c477a02d8d76317655b6ba04cfa24e94a0",
          "profiles_registry_id": "0xd95e1968dcbf42ea0eccb1184ec9c529bbc7b7651b046a7d9247903b14869501"
        },
        "bcsEncoding": "base64",
        "bcs": "lQhLltLycoP9kds2Fm2WxHegLY12MXZVtroEz6JOlKDZXhlo3L9C6g7MsRhOycUpu8e3ZRsEan2SR5A7FIaVAQ=="
      },
      {
        "id": {
          "txDigest": "9tJFsfsE1xYR1QKfyXRnxgVhpdNTfNj5ZPVZ5rb2Ju2X",
          "eventSeq": "4"
        },
        "packageId": "0x035cf7b699be1d67785cc54dabc83e497fae23516c0329bea39faabf3384f702",
        "transactionModule": "crowd_walrus",
        "sender": "0x0deaf2ae9d8e4877eb7bf5d86434488e343b6881bedff8fc78031b6d0df7c75a",
        "type": "0x035cf7b699be1d67785cc54dabc83e497fae23516c0329bea39faabf3384f702::crowd_walrus::TokenRegistryCreated",
        "parsedJson": {
          "crowd_walrus_id": "0x95084b96d2f27283fd91db36166d96c477a02d8d76317655b6ba04cfa24e94a0",
          "token_registry_id": "0x9409e01b8bafbad0b89e949bcfb8416be7f600f4b87df3bc4103e6f5d78cfb00"
        },
        "bcsEncoding": "base64",
        "bcs": "lQhLltLycoP9kds2Fm2WxHegLY12MXZVtroEz6JOlKCUCeAbi6+60LielJvPuEFr5/YA9Lh987xBA+b114z7AA=="
      },
      {
        "id": {
          "txDigest": "9tJFsfsE1xYR1QKfyXRnxgVhpdNTfNj5ZPVZ5rb2Ju2X",
          "eventSeq": "5"
        },
        "packageId": "0x035cf7b699be1d67785cc54dabc83e497fae23516c0329bea39faabf3384f702",
        "transactionModule": "crowd_walrus",
        "sender": "0x0deaf2ae9d8e4877eb7bf5d86434488e343b6881bedff8fc78031b6d0df7c75a",
        "type": "0x035cf7b699be1d67785cc54dabc83e497fae23516c0329bea39faabf3384f702::crowd_walrus::BadgeConfigCreated",
        "parsedJson": {
          "badge_config_id": "0xdbbc3ed362df0a25b68d62bdcb237c8ea7eb2c109228de69a575dd15a77de43e",
          "crowd_walrus_id": "0x95084b96d2f27283fd91db36166d96c477a02d8d76317655b6ba04cfa24e94a0"
        },
        "bcsEncoding": "base64",
        "bcs": "lQhLltLycoP9kds2Fm2WxHegLY12MXZVtroEz6JOlKDbvD7TYt8KJbaNYr3LI3yOp+ssEJIo3mmldd0Vp33kPg=="
      },
      {
        "id": {
          "txDigest": "9tJFsfsE1xYR1QKfyXRnxgVhpdNTfNj5ZPVZ5rb2Ju2X",
          "eventSeq": "6"
        },
        "packageId": "0x035cf7b699be1d67785cc54dabc83e497fae23516c0329bea39faabf3384f702",
        "transactionModule": "crowd_walrus",
        "sender": "0x0deaf2ae9d8e4877eb7bf5d86434488e343b6881bedff8fc78031b6d0df7c75a",
        "type": "0x035cf7b699be1d67785cc54dabc83e497fae23516c0329bea39faabf3384f702::suins_manager::SuiNSManagerCreated",
        "parsedJson": {
          "creator": "0x0deaf2ae9d8e4877eb7bf5d86434488e343b6881bedff8fc78031b6d0df7c75a",
          "suins_manager_id": "0xd71de83cc6a3a1f266b7b1dddb751b3b268ec9cd741e759f827e5fab10d6890e"
        },
        "bcsEncoding": "base64",
        "bcs": "1x3oPMajofJmt7Hd23UbOyaOyc10HnWfgn5fqxDWiQ4N6vKunY5Id+t79dhkNEiONDtogb7f+Px4AxttDffHWg=="
      },
      {
        "id": {
          "txDigest": "9tJFsfsE1xYR1QKfyXRnxgVhpdNTfNj5ZPVZ5rb2Ju2X",
          "eventSeq": "7"
        },
        "packageId": "0x035cf7b699be1d67785cc54dabc83e497fae23516c0329bea39faabf3384f702",
        "transactionModule": "crowd_walrus",
        "sender": "0x0deaf2ae9d8e4877eb7bf5d86434488e343b6881bedff8fc78031b6d0df7c75a",
        "type": "0x035cf7b699be1d67785cc54dabc83e497fae23516c0329bea39faabf3384f702::suins_manager::AdminCreated",
        "parsedJson": {
          "admin_id": "0x1dd88336103fd741e4bc76d7c0c3c9ebe76361eded792bfa037a13722ac37451",
          "creator": "0x0deaf2ae9d8e4877eb7bf5d86434488e343b6881bedff8fc78031b6d0df7c75a",
          "suins_manager_id": "0xd71de83cc6a3a1f266b7b1dddb751b3b268ec9cd741e759f827e5fab10d6890e"
        },
        "bcsEncoding": "base64",
        "bcs": "1x3oPMajofJmt7Hd23UbOyaOyc10HnWfgn5fqxDWiQ4d2IM2ED/XQeS8dtfAw8nr52Nh7e15K/oDehNyKsN0UQ3q8q6djkh363v12GQ0SI40O2iBvt/4/HgDG20N98da"
      }
    ],
    "objectChanges": [
      {
        "type": "mutated",
        "sender": "0x0deaf2ae9d8e4877eb7bf5d86434488e343b6881bedff8fc78031b6d0df7c75a",
        "owner": {
          "AddressOwner": "0x0deaf2ae9d8e4877eb7bf5d86434488e343b6881bedff8fc78031b6d0df7c75a"
        },
        "objectType": "0x2::coin::Coin<0x2::sui::SUI>",
        "objectId": "0x98a43439d58f5ece303484f261f1e533ee92281f4094e1322b974ed756173577",
        "version": "773550337",
        "previousVersion": "773550336",
        "digest": "5vdKK7JLCCAQXiXDCFwPB57mD15fXhbkoLVDxJ2oV5Xi"
      },
      {
        "type": "published",
        "packageId": "0x035cf7b699be1d67785cc54dabc83e497fae23516c0329bea39faabf3384f702",
        "version": "1",
        "digest": "EBaaYNPjjCqkCv3MQx31YmqhY4es48Uh9Gbs39oDKDrx",
        "modules": [
          "badge_rewards",
          "campaign",
          "campaign_stats",
          "crowd_walrus",
          "donations",
          "platform_policy",
          "price_oracle",
          "profiles",
          "suins_manager",
          "token_registry"
        ]
      },
      {
        "type": "created",
        "sender": "0x0deaf2ae9d8e4877eb7bf5d86434488e343b6881bedff8fc78031b6d0df7c75a",
        "owner": {
          "ObjectOwner": "0x79767ca44deef0c4ecd5f761df162b4b74e69732678fd46cd69fab0167785cbf"
        },
        "objectType": "0x2::dynamic_field::Field<0x1::string::String, 0x035cf7b699be1d67785cc54dabc83e497fae23516c0329bea39faabf3384f702::platform_policy::Policy>",
        "objectId": "0x1dd1fa6ffb4e68007880380cfc206daa80a2275f307d539b0be3a881b5a92799",
        "version": "773550337",
        "digest": "Ge9NRUxFfpTV9TxtVJUXvFxQoAAqz6F6bZfBuFHEXp6N"
      },
      {
        "type": "created",
        "sender": "0x0deaf2ae9d8e4877eb7bf5d86434488e343b6881bedff8fc78031b6d0df7c75a",
        "owner": {
          "AddressOwner": "0x0deaf2ae9d8e4877eb7bf5d86434488e343b6881bedff8fc78031b6d0df7c75a"
        },
        "objectType": "0x035cf7b699be1d67785cc54dabc83e497fae23516c0329bea39faabf3384f702::suins_manager::AdminCap",
        "objectId": "0x1dd88336103fd741e4bc76d7c0c3c9ebe76361eded792bfa037a13722ac37451",
        "version": "773550337",
        "digest": "F9XkSLAj1eNRbSV2S7ZVfBecfU8J7QUC7D62q8evpzKz"
      },
      {
        "type": "created",
        "sender": "0x0deaf2ae9d8e4877eb7bf5d86434488e343b6881bedff8fc78031b6d0df7c75a",
        "owner": {
          "ObjectOwner": "0xd71de83cc6a3a1f266b7b1dddb751b3b268ec9cd741e759f827e5fab10d6890e"
        },
        "objectType": "0x2::dynamic_field::Field<0x035cf7b699be1d67785cc54dabc83e497fae23516c0329bea39faabf3384f702::suins_manager::AppKey<0x035cf7b699be1d67785cc54dabc83e497fae23516c0329bea39faabf3384f702::crowd_walrus::CrowdWalrusApp>, bool>",
        "objectId": "0x37424137afc41c2cf5f6b5ca75c09ef550a9c24d9a8c54482d88c02893722a74",
        "version": "773550337",
        "digest": "J3twcLXFp7AQzyAkjttXCCTytAWGq7ceo94B1HPfYpYv"
      },
      {
        "type": "created",
        "sender": "0x0deaf2ae9d8e4877eb7bf5d86434488e343b6881bedff8fc78031b6d0df7c75a",
        "owner": {
          "AddressOwner": "0x0deaf2ae9d8e4877eb7bf5d86434488e343b6881bedff8fc78031b6d0df7c75a"
        },
        "objectType": "0x035cf7b699be1d67785cc54dabc83e497fae23516c0329bea39faabf3384f702::crowd_walrus::AdminCap",
        "objectId": "0x684646dbd0b0c17ccff97904d59091766599fdbde56a542a29fe869af23bc94c",
        "version": "773550337",
        "digest": "37ZeGJzuAd5a1EhvtJ2J8HPLLD6hjG7bEsS7i3rugT9S"
      },
      {
        "type": "created",
        "sender": "0x0deaf2ae9d8e4877eb7bf5d86434488e343b6881bedff8fc78031b6d0df7c75a",
        "owner": {
          "AddressOwner": "0x0deaf2ae9d8e4877eb7bf5d86434488e343b6881bedff8fc78031b6d0df7c75a"
        },
        "objectType": "0x2::package::UpgradeCap",
        "objectId": "0x8a9731247bc1faa9f2ddea34c665c9aaacb9840b54a18cdadd25ea773ec19ce2",
        "version": "773550337",
        "digest": "4J9hJs2LUxfaX5jzUncNGQMoCcbbLhdsvnwVaz4Cf2dJ"
      },
      {
        "type": "created",
        "sender": "0x0deaf2ae9d8e4877eb7bf5d86434488e343b6881bedff8fc78031b6d0df7c75a",
        "owner": {
          "ObjectOwner": "0x95084b96d2f27283fd91db36166d96c477a02d8d76317655b6ba04cfa24e94a0"
        },
        "objectType": "0x2::dynamic_field::Field<0x035cf7b699be1d67785cc54dabc83e497fae23516c0329bea39faabf3384f702::crowd_walrus::TokenRegistryKey, 0x035cf7b699be1d67785cc54dabc83e497fae23516c0329bea39faabf3384f702::crowd_walrus::TokenRegistrySlot>",
        "objectId": "0x91a547f0f314b273398c35c7d76810366e2a41365f745a0061f92bb946ebeac6",
        "version": "773550337",
        "digest": "EieLFmNFuuuqrHyQRpN51voif5ACn74fhdiAXmswexVM"
      },
      {
        "type": "created",
        "sender": "0x0deaf2ae9d8e4877eb7bf5d86434488e343b6881bedff8fc78031b6d0df7c75a",
        "owner": {
          "Shared": {
            "initial_shared_version": 773550337
          }
        },
        "objectType": "0x035cf7b699be1d67785cc54dabc83e497fae23516c0329bea39faabf3384f702::token_registry::TokenRegistry",
        "objectId": "0x9409e01b8bafbad0b89e949bcfb8416be7f600f4b87df3bc4103e6f5d78cfb00",
        "version": "773550337",
        "digest": "6gkcMnTWZDsa87zfLdyUJKNLGfMLSx1iW14xayZAmMxn"
      },
      {
        "type": "created",
        "sender": "0x0deaf2ae9d8e4877eb7bf5d86434488e343b6881bedff8fc78031b6d0df7c75a",
        "owner": {
          "Shared": {
            "initial_shared_version": 773550337
          }
        },
        "objectType": "0x035cf7b699be1d67785cc54dabc83e497fae23516c0329bea39faabf3384f702::crowd_walrus::CrowdWalrus",
        "objectId": "0x95084b96d2f27283fd91db36166d96c477a02d8d76317655b6ba04cfa24e94a0",
        "version": "773550337",
        "digest": "3NDfdQYDKx38MQg3iGULsG8hR8yQp3zvgFPGieL13oXd"
      },
      {
        "type": "created",
        "sender": "0x0deaf2ae9d8e4877eb7bf5d86434488e343b6881bedff8fc78031b6d0df7c75a",
        "owner": {
          "Shared": {
            "initial_shared_version": 773550337
          }
        },
        "objectType": "0x035cf7b699be1d67785cc54dabc83e497fae23516c0329bea39faabf3384f702::platform_policy::PolicyRegistry",
        "objectId": "0xb9478cb0359b4a9a6a86b4e9ca2f6a171b7b6405f8ffada12b1f45d68077897c",
        "version": "773550337",
        "digest": "9G31ZzBqVmmB8iaRBD9tpz8z6aMrtH3bQnoY7cQW7Y2d"
      },
      {
        "type": "created",
        "sender": "0x0deaf2ae9d8e4877eb7bf5d86434488e343b6881bedff8fc78031b6d0df7c75a",
        "owner": {
          "AddressOwner": "0x0deaf2ae9d8e4877eb7bf5d86434488e343b6881bedff8fc78031b6d0df7c75a"
        },
        "objectType": "0x2::package::Publisher",
        "objectId": "0xc3b2a631c52092caa19fad982a1dba0531e4a1057f5aa5afa1bf5ebdc2fa6139",
        "version": "773550337",
        "digest": "F7fBszhYvvVm8EJuc4ydy1jt1R8uHCKhtDg3h2N2fR4v"
      },
      {
        "type": "created",
        "sender": "0x0deaf2ae9d8e4877eb7bf5d86434488e343b6881bedff8fc78031b6d0df7c75a",
        "owner": {
          "Shared": {
            "initial_shared_version": 773550337
          }
        },
        "objectType": "0x035cf7b699be1d67785cc54dabc83e497fae23516c0329bea39faabf3384f702::suins_manager::SuiNSManager",
        "objectId": "0xd71de83cc6a3a1f266b7b1dddb751b3b268ec9cd741e759f827e5fab10d6890e",
        "version": "773550337",
        "digest": "AUrFzgFe6wMt3WwU8nYXtLHBpoCWW1jqPddmWKz9k2z2"
      },
      {
        "type": "created",
        "sender": "0x0deaf2ae9d8e4877eb7bf5d86434488e343b6881bedff8fc78031b6d0df7c75a",
        "owner": {
          "Shared": {
            "initial_shared_version": 773550337
          }
        },
        "objectType": "0x035cf7b699be1d67785cc54dabc83e497fae23516c0329bea39faabf3384f702::profiles::ProfilesRegistry",
        "objectId": "0xd95e1968dcbf42ea0eccb1184ec9c529bbc7b7651b046a7d9247903b14869501",
        "version": "773550337",
        "digest": "BZ5nZ459d1uBDMewj35aPgP6TP36QvBco1gyovaBWD1x"
      },
      {
        "type": "created",
        "sender": "0x0deaf2ae9d8e4877eb7bf5d86434488e343b6881bedff8fc78031b6d0df7c75a",
        "owner": {
          "Shared": {
            "initial_shared_version": 773550337
          }
        },
        "objectType": "0x035cf7b699be1d67785cc54dabc83e497fae23516c0329bea39faabf3384f702::badge_rewards::BadgeConfig",
        "objectId": "0xdbbc3ed362df0a25b68d62bdcb237c8ea7eb2c109228de69a575dd15a77de43e",
        "version": "773550337",
        "digest": "5yssi6qK6JodGjd8dvPKxMptx6vgMF2UUPqNcgJnmH88"
      }
    ],
    "timestampMs": "1770302144968",
    "checkpoint": "241918501"
  }
}
```
