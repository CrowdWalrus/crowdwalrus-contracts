# Mainnet post-deploy log (2026-02-05)

Generated: 2026-02-05T15:45:55Z UTC

## Summary
- Package: 0x035cf7b699be1d67785cc54dabc83e497fae23516c0329bea39faabf3384f702
- Deployer: 0x0deaf2ae9d8e4877eb7bf5d86434488e343b6881bedff8fc78031b6d0df7c75a
- Token registry: 0x9409e01b8bafbad0b89e949bcfb8416be7f600f4b87df3bc4103e6f5d78cfb00
- Policy registry: 0xb9478cb0359b4a9a6a86b4e9ca2f6a171b7b6405f8ffada12b1f45d68077897c
- Badge config: 0xdbbc3ed362df0a25b68d62bdcb237c8ea7eb2c109228de69a575dd15a77de43e
- Donor badge display: 0x7c4ccf431be3b7519884945563f0c7e9e02d6326c5af5c470892efe8588a6ccc

### Key tx digests
- NS add: 25gZNcAY4iCQcvkac2Te3w2zNDUpyQrQgqwD3ZdtPoxZ
- NS enable: 5fjznGPizPHDtfa8Tf7p1uiGSssoLBYWfrnMtstd2pUQ
- BLUE add: 6C8iFMzoEVAQEReDW3HgMWcvVsRrw4SLq6wB34bWGUTB
- BLUE enable: DDjn5bjjhSAPfLWVyqYr6QXy3kohcHY66eHNRt1WUsu1
- Badge config update: CjP4JQv9GN4So2frTH85MAiikQothYzGz6UsSAoGaKp
- Policy update (standard): D2L3nN5rHNTRQG4GXtRgpSmHStLXdBSw3wLjJEHxrmR3
- Policy add (commercial): G73CTSZ4MTZCsz2pNh3fQciumHN8jdsyJAjYxU6FpXcY
- Badge display setup: GkYdXGvqq4WzAWDUm4ohTLtU8ujvdQynguUyUPj1vmF3

### Notes
- RPC intermittently returned 503 and object version mismatch warnings. The txs above all report `status: success`.
- Some CLI responses include `Cannot retrieve balance/object changes` due to version lag; these do not indicate failure.


## SUI token add (earlier)

Path: `/tmp/add_token_SUI_2026-02-05.json`

```json
{
  "digest": "D4N36PAi48FpS3rfP8mvBgm1f8zE9eo7377NgYzQHgLv",
  "transaction": {
    "data": {
      "messageVersion": "v1",
      "transaction": {
        "kind": "ProgrammableTransaction",
        "inputs": [
          {
            "type": "object",
            "objectType": "sharedObject",
            "objectId": "0x9409e01b8bafbad0b89e949bcfb8416be7f600f4b87df3bc4103e6f5d78cfb00",
            "initialSharedVersion": "773550337",
            "mutable": true
          },
          {
            "type": "object",
            "objectType": "immOrOwnedObject",
            "objectId": "0x684646dbd0b0c17ccff97904d59091766599fdbde56a542a29fe869af23bc94c",
            "version": "773550337",
            "digest": "37ZeGJzuAd5a1EhvtJ2J8HPLLD6hjG7bEsS7i3rugT9S"
          },
          {
            "type": "pure",
            "valueType": "0x1::string::String",
            "value": "SUI"
          },
          {
            "type": "pure",
            "valueType": "0x1::string::String",
            "value": "Sui"
          },
          {
            "type": "pure",
            "valueType": "u8",
            "value": 9
          },
          {
            "type": "pure",
            "valueType": "vector<u8>",
            "value": [
              35,
              215,
              49,
              81,
              19,
              245,
              177,
              211,
              186,
              122,
              131,
              96,
              76,
              68,
              185,
              77,
              121,
              244,
              253,
              105,
              175,
              119,
              248,
              4,
              252,
              127,
              146,
              10,
              109,
              198,
              87,
              68
            ]
          },
          {
            "type": "pure",
            "valueType": "u64",
            "value": "300000"
          },
          {
            "type": "object",
            "objectType": "sharedObject",
            "objectId": "0x0000000000000000000000000000000000000000000000000000000000000006",
            "initialSharedVersion": "1",
            "mutable": false
          }
        ],
        "transactions": [
          {
            "MoveCall": {
              "package": "0x035cf7b699be1d67785cc54dabc83e497fae23516c0329bea39faabf3384f702",
              "module": "crowd_walrus",
              "function": "add_token",
              "type_arguments": [
                "0x2::sui::SUI"
              ],
              "arguments": [
                {
                  "Input": 0
                },
                {
                  "Input": 1
                },
                {
                  "Input": 2
                },
                {
                  "Input": 3
                },
                {
                  "Input": 4
                },
                {
                  "Input": 5
                },
                {
                  "Input": 6
                },
                {
                  "Input": 7
                }
              ]
            }
          }
        ]
      },
      "sender": "0x0deaf2ae9d8e4877eb7bf5d86434488e343b6881bedff8fc78031b6d0df7c75a",
      "gasData": {
        "payment": [
          {
            "objectId": "0xd4300a22ed111e2748cbf37a9d8989a465fcc93d6d5e51c3b50a01c5947a68e0",
            "version": 741356502,
            "digest": "7x3hF3pnU6BSDQSCqwK3xKDFbpdQx8XsTte4kvWwHFg9"
          }
        ],
        "owner": "0x0deaf2ae9d8e4877eb7bf5d86434488e343b6881bedff8fc78031b6d0df7c75a",
        "price": "516",
        "budget": "20000000"
      }
    },
    "txSignatures": [
      "ALMV5xJoCelBNIBIleL8qRscyCTyhgyD23JEvHKKcYOVT86tvnkgLi/xW0TbptAJEAwQzom4O/FCkEUpP9wZUwr2kJBg/LwnsKrg9YAOh6iaiahK8sMaI1lFOELfahaYKg=="
    ]
  },
  "effects": {
    "messageVersion": "v1",
    "status": {
      "status": "success"
    },
    "executedEpoch": "1029",
    "gasUsed": {
      "computationCost": "516000",
      "storageCost": "7174400",
      "storageRebate": "4175820",
      "nonRefundableStorageFee": "42180"
    },
    "modifiedAtVersions": [
      {
        "objectId": "0x684646dbd0b0c17ccff97904d59091766599fdbde56a542a29fe869af23bc94c",
        "sequenceNumber": "773550337"
      },
      {
        "objectId": "0x9409e01b8bafbad0b89e949bcfb8416be7f600f4b87df3bc4103e6f5d78cfb00",
        "sequenceNumber": "773550337"
      },
      {
        "objectId": "0xd4300a22ed111e2748cbf37a9d8989a465fcc93d6d5e51c3b50a01c5947a68e0",
        "sequenceNumber": "741356502"
      }
    ],
    "sharedObjects": [
      {
        "objectId": "0x9409e01b8bafbad0b89e949bcfb8416be7f600f4b87df3bc4103e6f5d78cfb00",
        "version": 773550337,
        "digest": "6gkcMnTWZDsa87zfLdyUJKNLGfMLSx1iW14xayZAmMxn"
      },
      {
        "objectId": "0x0000000000000000000000000000000000000000000000000000000000000006",
        "version": 717881539,
        "digest": "FTozkcGWniAkN9d6BsqzCv6TnnfapaWGRJArTwq3xjWi"
      }
    ],
    "transactionDigest": "D4N36PAi48FpS3rfP8mvBgm1f8zE9eo7377NgYzQHgLv",
    "created": [
      {
        "owner": {
          "ObjectOwner": "0x9409e01b8bafbad0b89e949bcfb8416be7f600f4b87df3bc4103e6f5d78cfb00"
        },
        "reference": {
          "objectId": "0x2b4acc008ec955c1353180cda2fdef41b7e1c6d4ac4fea946d41c8b13fbfa131",
          "version": 773550338,
          "digest": "HK2iPatAvZEAfhniV9nNv5phJXtWLnb82JEfVRqBJWJz"
        }
      }
    ],
    "mutated": [
      {
        "owner": {
          "AddressOwner": "0x0deaf2ae9d8e4877eb7bf5d86434488e343b6881bedff8fc78031b6d0df7c75a"
        },
        "reference": {
          "objectId": "0x684646dbd0b0c17ccff97904d59091766599fdbde56a542a29fe869af23bc94c",
          "version": 773550338,
          "digest": "9ih88ckwEACidCVEEaS3XKcd4Bd6KwqUjhBAqvbaKS46"
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
          "version": 773550338,
          "digest": "DYnJTW2KfU97h4YwGHKEgfBYkPt17CUcMHbbcCBcV5JM"
        }
      },
      {
        "owner": {
          "AddressOwner": "0x0deaf2ae9d8e4877eb7bf5d86434488e343b6881bedff8fc78031b6d0df7c75a"
        },
        "reference": {
          "objectId": "0xd4300a22ed111e2748cbf37a9d8989a465fcc93d6d5e51c3b50a01c5947a68e0",
          "version": 773550338,
          "digest": "53catVVr8dwcpD1EGSLZygNFax5rm4PvpDL7V9e9Ywho"
        }
      }
    ],
    "gasObject": {
      "owner": {
        "AddressOwner": "0x0deaf2ae9d8e4877eb7bf5d86434488e343b6881bedff8fc78031b6d0df7c75a"
      },
      "reference": {
        "objectId": "0xd4300a22ed111e2748cbf37a9d8989a465fcc93d6d5e51c3b50a01c5947a68e0",
        "version": 773550338,
        "digest": "53catVVr8dwcpD1EGSLZygNFax5rm4PvpDL7V9e9Ywho"
      }
    },
    "eventsDigest": "2UpoZLa7UUcmq61RzDjkeqAaBkkDr3fzK8T52wVyAbG5",
    "dependencies": [
      "4NGPXrHHqymFowsPBgKLpiVnrNBvj7ZRAqjuUT2uUWgJ",
      "57adBNHHsjR7uJs3fonbsx8CUSddXMBAeQzWD6D37ALW",
      "7jiEfzJ5ZCREDe2TJhWMxo81TkQmHjidUDhssaJfAdic",
      "9tJFsfsE1xYR1QKfyXRnxgVhpdNTfNj5ZPVZ5rb2Ju2X"
    ]
  },
  "events": [
    {
      "id": {
        "txDigest": "D4N36PAi48FpS3rfP8mvBgm1f8zE9eo7377NgYzQHgLv",
        "eventSeq": "0"
      },
      "packageId": "0x035cf7b699be1d67785cc54dabc83e497fae23516c0329bea39faabf3384f702",
      "transactionModule": "crowd_walrus",
      "sender": "0x0deaf2ae9d8e4877eb7bf5d86434488e343b6881bedff8fc78031b6d0df7c75a",
      "type": "0x035cf7b699be1d67785cc54dabc83e497fae23516c0329bea39faabf3384f702::token_registry::TokenAdded",
      "parsedJson": {
        "coin_type": "0000000000000000000000000000000000000000000000000000000000000002::sui::SUI",
        "decimals": 9,
        "enabled": false,
        "max_age_ms": "300000",
        "name": "Sui",
        "pyth_feed_id": [
          35,
          215,
          49,
          81,
          19,
          245,
          177,
          211,
          186,
          122,
          131,
          96,
          76,
          68,
          185,
          77,
          121,
          244,
          253,
          105,
          175,
          119,
          248,
          4,
          252,
          127,
          146,
          10,
          109,
          198,
          87,
          68
        ],
        "symbol": "SUI",
        "timestamp_ms": "1770303271973"
      },
      "bcsEncoding": "base64",
      "bcs": "SjAwMDAwMDAwMDAwMDAwMDAwMDAwMDAwMDAwMDAwMDAwMDAwMDAwMDAwMDAwMDAwMDAwMDAwMDAwMDAwMDAwMDI6OnN1aTo6U1VJA1NVSQNTdWkJICPXMVET9bHTunqDYExEuU159P1pr3f4BPx/kgptxldE4JMEAAAAAAAAJTRMLpwBAAA="
    }
  ],
  "objectChanges": [
    {
      "type": "mutated",
      "sender": "0x0deaf2ae9d8e4877eb7bf5d86434488e343b6881bedff8fc78031b6d0df7c75a",
      "owner": {
        "AddressOwner": "0x0deaf2ae9d8e4877eb7bf5d86434488e343b6881bedff8fc78031b6d0df7c75a"
      },
      "objectType": "0x035cf7b699be1d67785cc54dabc83e497fae23516c0329bea39faabf3384f702::crowd_walrus::AdminCap",
      "objectId": "0x684646dbd0b0c17ccff97904d59091766599fdbde56a542a29fe869af23bc94c",
      "version": "773550338",
      "previousVersion": "773550337",
      "digest": "9ih88ckwEACidCVEEaS3XKcd4Bd6KwqUjhBAqvbaKS46"
    },
    {
      "type": "mutated",
      "sender": "0x0deaf2ae9d8e4877eb7bf5d86434488e343b6881bedff8fc78031b6d0df7c75a",
      "owner": {
        "Shared": {
          "initial_shared_version": 773550337
        }
      },
      "objectType": "0x035cf7b699be1d67785cc54dabc83e497fae23516c0329bea39faabf3384f702::token_registry::TokenRegistry",
      "objectId": "0x9409e01b8bafbad0b89e949bcfb8416be7f600f4b87df3bc4103e6f5d78cfb00",
      "version": "773550338",
      "previousVersion": "773550337",
      "digest": "DYnJTW2KfU97h4YwGHKEgfBYkPt17CUcMHbbcCBcV5JM"
    },
    {
      "type": "mutated",
      "sender": "0x0deaf2ae9d8e4877eb7bf5d86434488e343b6881bedff8fc78031b6d0df7c75a",
      "owner": {
        "AddressOwner": "0x0deaf2ae9d8e4877eb7bf5d86434488e343b6881bedff8fc78031b6d0df7c75a"
      },
      "objectType": "0x2::coin::Coin<0x2::sui::SUI>",
      "objectId": "0xd4300a22ed111e2748cbf37a9d8989a465fcc93d6d5e51c3b50a01c5947a68e0",
      "version": "773550338",
      "previousVersion": "741356502",
      "digest": "53catVVr8dwcpD1EGSLZygNFax5rm4PvpDL7V9e9Ywho"
    },
    {
      "type": "created",
      "sender": "0x0deaf2ae9d8e4877eb7bf5d86434488e343b6881bedff8fc78031b6d0df7c75a",
      "owner": {
        "ObjectOwner": "0x9409e01b8bafbad0b89e949bcfb8416be7f600f4b87df3bc4103e6f5d78cfb00"
      },
      "objectType": "0x2::dynamic_field::Field<0x035cf7b699be1d67785cc54dabc83e497fae23516c0329bea39faabf3384f702::token_registry::CoinKey<0x2::sui::SUI>, 0x035cf7b699be1d67785cc54dabc83e497fae23516c0329bea39faabf3384f702::token_registry::TokenMetadata>",
      "objectId": "0x2b4acc008ec955c1353180cda2fdef41b7e1c6d4ac4fea946d41c8b13fbfa131",
      "version": "773550338",
      "digest": "HK2iPatAvZEAfhniV9nNv5phJXtWLnb82JEfVRqBJWJz"
    }
  ],
  "balanceChanges": [
    {
      "owner": {
        "AddressOwner": "0x0deaf2ae9d8e4877eb7bf5d86434488e343b6881bedff8fc78031b6d0df7c75a"
      },
      "coinType": "0x2::sui::SUI",
      "amount": "-3514580"
    }
  ],
  "timestampMs": "1770303272142",
  "confirmedLocalExecution": true,
  "checkpoint": "241922782"
}
```


## USDC token enable (earlier; includes add/enable flow)

Path: `/tmp/set_token_enabled_usdc_2026-02-05.json`

```json
{
  "digest": "2H6L524aXaiZMFH4xRPaUvE1g2BvGXCXNzjdGXKySYZE",
  "transaction": {
    "data": {
      "messageVersion": "v1",
      "transaction": {
        "kind": "ProgrammableTransaction",
        "inputs": [
          {
            "type": "object",
            "objectType": "sharedObject",
            "objectId": "0x9409e01b8bafbad0b89e949bcfb8416be7f600f4b87df3bc4103e6f5d78cfb00",
            "initialSharedVersion": "773550337",
            "mutable": true
          },
          {
            "type": "object",
            "objectType": "immOrOwnedObject",
            "objectId": "0x684646dbd0b0c17ccff97904d59091766599fdbde56a542a29fe869af23bc94c",
            "version": "773550340",
            "digest": "52TNoTXXH8EwPsYZaqvFFnJFBgdtihKTqoxtGnVeY6Th"
          },
          {
            "type": "pure",
            "valueType": "bool",
            "value": true
          },
          {
            "type": "object",
            "objectType": "sharedObject",
            "objectId": "0x0000000000000000000000000000000000000000000000000000000000000006",
            "initialSharedVersion": "1",
            "mutable": false
          }
        ],
        "transactions": [
          {
            "MoveCall": {
              "package": "0x035cf7b699be1d67785cc54dabc83e497fae23516c0329bea39faabf3384f702",
              "module": "crowd_walrus",
              "function": "set_token_enabled",
              "type_arguments": [
                "0xdba34672e30cb065b1f93e3ab55318768fd6fef66c15942c9f7cb846e2f900e7::usdc::USDC"
              ],
              "arguments": [
                {
                  "Input": 0
                },
                {
                  "Input": 1
                },
                {
                  "Input": 2
                },
                {
                  "Input": 3
                }
              ]
            }
          }
        ]
      },
      "sender": "0x0deaf2ae9d8e4877eb7bf5d86434488e343b6881bedff8fc78031b6d0df7c75a",
      "gasData": {
        "payment": [
          {
            "objectId": "0xd4300a22ed111e2748cbf37a9d8989a465fcc93d6d5e51c3b50a01c5947a68e0",
            "version": 773550340,
            "digest": "4jv2RXAJYE9U1GMXaShbLnmNr36PH8VHNMzatZPoP43c"
          }
        ],
        "owner": "0x0deaf2ae9d8e4877eb7bf5d86434488e343b6881bedff8fc78031b6d0df7c75a",
        "price": "516",
        "budget": "10000000"
      }
    },
    "txSignatures": [
      "ALuJpocJBy4SeAosGrwgchhKt1MARq14NRC528J8K7DBG+fRxD0w+aAfAy+fiUvGLfvvIQwCEbldtag03LSqzgT2kJBg/LwnsKrg9YAOh6iaiahK8sMaI1lFOELfahaYKg=="
    ]
  },
  "effects": {
    "messageVersion": "v1",
    "status": {
      "status": "success"
    },
    "executedEpoch": "1029",
    "gasUsed": {
      "computationCost": "516000",
      "storageCost": "7204800",
      "storageRebate": "7132752",
      "nonRefundableStorageFee": "72048"
    },
    "modifiedAtVersions": [
      {
        "objectId": "0x684646dbd0b0c17ccff97904d59091766599fdbde56a542a29fe869af23bc94c",
        "sequenceNumber": "773550340"
      },
      {
        "objectId": "0x9409e01b8bafbad0b89e949bcfb8416be7f600f4b87df3bc4103e6f5d78cfb00",
        "sequenceNumber": "773550340"
      },
      {
        "objectId": "0xa78a76693a5429a416e0bc1d34f4a2322e6aad6f5dc21d85eaf2380e1dd80fb7",
        "sequenceNumber": "773550340"
      },
      {
        "objectId": "0xd4300a22ed111e2748cbf37a9d8989a465fcc93d6d5e51c3b50a01c5947a68e0",
        "sequenceNumber": "773550340"
      }
    ],
    "sharedObjects": [
      {
        "objectId": "0x9409e01b8bafbad0b89e949bcfb8416be7f600f4b87df3bc4103e6f5d78cfb00",
        "version": 773550340,
        "digest": "EUCC5HDhk2gDCeRykn2m8SYp2C2WGqghaBZbmGusPVA"
      },
      {
        "objectId": "0x0000000000000000000000000000000000000000000000000000000000000006",
        "version": 717883392,
        "digest": "13hW737BHnD1tQqiCa4LUzhWMVHniyAzzb83zmstHQ2V"
      }
    ],
    "transactionDigest": "2H6L524aXaiZMFH4xRPaUvE1g2BvGXCXNzjdGXKySYZE",
    "mutated": [
      {
        "owner": {
          "AddressOwner": "0x0deaf2ae9d8e4877eb7bf5d86434488e343b6881bedff8fc78031b6d0df7c75a"
        },
        "reference": {
          "objectId": "0x684646dbd0b0c17ccff97904d59091766599fdbde56a542a29fe869af23bc94c",
          "version": 773550341,
          "digest": "6KjaZnBhiFqkxNBEXrx6RPLmzLGyjZSGFxGcVvxqgfqL"
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
          "version": 773550341,
          "digest": "B3dpDMPyhP8UVZTnM9TbPh9TZX21N5J5E57GNY7qvZm6"
        }
      },
      {
        "owner": {
          "ObjectOwner": "0x9409e01b8bafbad0b89e949bcfb8416be7f600f4b87df3bc4103e6f5d78cfb00"
        },
        "reference": {
          "objectId": "0xa78a76693a5429a416e0bc1d34f4a2322e6aad6f5dc21d85eaf2380e1dd80fb7",
          "version": 773550341,
          "digest": "FqmLdUEjHgZjDCZMTaPX2T6xURvKw4mYPTLzwKYyCRBt"
        }
      },
      {
        "owner": {
          "AddressOwner": "0x0deaf2ae9d8e4877eb7bf5d86434488e343b6881bedff8fc78031b6d0df7c75a"
        },
        "reference": {
          "objectId": "0xd4300a22ed111e2748cbf37a9d8989a465fcc93d6d5e51c3b50a01c5947a68e0",
          "version": 773550341,
          "digest": "G6uxi8pJh6MbsGK1bybYj4VgT8KL8BqiYg4ftYVCYHYf"
        }
      }
    ],
    "gasObject": {
      "owner": {
        "AddressOwner": "0x0deaf2ae9d8e4877eb7bf5d86434488e343b6881bedff8fc78031b6d0df7c75a"
      },
      "reference": {
        "objectId": "0xd4300a22ed111e2748cbf37a9d8989a465fcc93d6d5e51c3b50a01c5947a68e0",
        "version": 773550341,
        "digest": "G6uxi8pJh6MbsGK1bybYj4VgT8KL8BqiYg4ftYVCYHYf"
      }
    },
    "eventsDigest": "A2a8ehKHQmab92oMfaU97i88h36JT1UPna1x7sNLpCtP",
    "dependencies": [
      "7DkJSrf5sPWGxqHbH2X1wXwFcftRm6myhJJnuTJbaMYr",
      "9KDFoBQ9zs6BFyStiWPLKgderFtKh23JYySimtETuC47",
      "9tJFsfsE1xYR1QKfyXRnxgVhpdNTfNj5ZPVZ5rb2Ju2X",
      "CVuEwscwpuaGGyeQRkspobxCQdBqKjED3Wa6ZPv6GfJY"
    ]
  },
  "events": [
    {
      "id": {
        "txDigest": "2H6L524aXaiZMFH4xRPaUvE1g2BvGXCXNzjdGXKySYZE",
        "eventSeq": "0"
      },
      "packageId": "0x035cf7b699be1d67785cc54dabc83e497fae23516c0329bea39faabf3384f702",
      "transactionModule": "crowd_walrus",
      "sender": "0x0deaf2ae9d8e4877eb7bf5d86434488e343b6881bedff8fc78031b6d0df7c75a",
      "type": "0x035cf7b699be1d67785cc54dabc83e497fae23516c0329bea39faabf3384f702::token_registry::TokenEnabled",
      "parsedJson": {
        "coin_type": "dba34672e30cb065b1f93e3ab55318768fd6fef66c15942c9f7cb846e2f900e7::usdc::USDC",
        "symbol": "USDC",
        "timestamp_ms": "1770303453182"
      },
      "bcsEncoding": "base64",
      "bcs": "TGRiYTM0NjcyZTMwY2IwNjViMWY5M2UzYWI1NTMxODc2OGZkNmZlZjY2YzE1OTQyYzlmN2NiODQ2ZTJmOTAwZTc6OnVzZGM6OlVTREMEVVNEQ/73Ti6cAQAA"
    }
  ],
  "timestampMs": "1770303453365",
  "confirmedLocalExecution": true,
  "checkpoint": "241923480",
  "errors": [
    "Cannot retrieve balance changes: Could not find the referenced object 0x684646dbd0b0c17ccff97904d59091766599fdbde56a542a29fe869af23bc94c as the asked version SequenceNumber(773550341) is higher than the latest SequenceNumber(773550340)",
    "Cannot retrieve object changes: Could not find the referenced object 0x684646dbd0b0c17ccff97904d59091766599fdbde56a542a29fe869af23bc94c as the asked version SequenceNumber(773550341) is higher than the latest SequenceNumber(773550340)"
  ]
}
```


## WAL token add (earlier)

Path: `/tmp/add_token_WAL_2026-02-05.json`

```json
{
  "digest": "CKQftCqcvHxhrE2obZQ68zXFG3QCaaVT6QnJ6WdYYnuu",
  "transaction": {
    "data": {
      "messageVersion": "v1",
      "transaction": {
        "kind": "ProgrammableTransaction",
        "inputs": [
          {
            "type": "object",
            "objectType": "sharedObject",
            "objectId": "0x9409e01b8bafbad0b89e949bcfb8416be7f600f4b87df3bc4103e6f5d78cfb00",
            "initialSharedVersion": "773550337",
            "mutable": true
          },
          {
            "type": "object",
            "objectType": "immOrOwnedObject",
            "objectId": "0x684646dbd0b0c17ccff97904d59091766599fdbde56a542a29fe869af23bc94c",
            "version": "773550341",
            "digest": "6KjaZnBhiFqkxNBEXrx6RPLmzLGyjZSGFxGcVvxqgfqL"
          },
          {
            "type": "pure",
            "valueType": "0x1::string::String",
            "value": "WAL"
          },
          {
            "type": "pure",
            "valueType": "0x1::string::String",
            "value": "WAL Token"
          },
          {
            "type": "pure",
            "valueType": "u8",
            "value": 9
          },
          {
            "type": "pure",
            "valueType": "vector<u8>",
            "value": [
              235,
              160,
              115,
              35,
              149,
              250,
              233,
              222,
              196,
              186,
              225,
              46,
              82,
              118,
              11,
              53,
              252,
              28,
              86,
              113,
              226,
              218,
              139,
              68,
              156,
              154,
              244,
              239,
              229,
              213,
              67,
              65
            ]
          },
          {
            "type": "pure",
            "valueType": "u64",
            "value": "300000"
          },
          {
            "type": "object",
            "objectType": "sharedObject",
            "objectId": "0x0000000000000000000000000000000000000000000000000000000000000006",
            "initialSharedVersion": "1",
            "mutable": false
          }
        ],
        "transactions": [
          {
            "MoveCall": {
              "package": "0x035cf7b699be1d67785cc54dabc83e497fae23516c0329bea39faabf3384f702",
              "module": "crowd_walrus",
              "function": "add_token",
              "type_arguments": [
                "0x356a26eb9e012a68958082340d4c4116e7f55615cf27affcff209cf0ae544f59::wal::WAL"
              ],
              "arguments": [
                {
                  "Input": 0
                },
                {
                  "Input": 1
                },
                {
                  "Input": 2
                },
                {
                  "Input": 3
                },
                {
                  "Input": 4
                },
                {
                  "Input": 5
                },
                {
                  "Input": 6
                },
                {
                  "Input": 7
                }
              ]
            }
          }
        ]
      },
      "sender": "0x0deaf2ae9d8e4877eb7bf5d86434488e343b6881bedff8fc78031b6d0df7c75a",
      "gasData": {
        "payment": [
          {
            "objectId": "0xd4300a22ed111e2748cbf37a9d8989a465fcc93d6d5e51c3b50a01c5947a68e0",
            "version": 773550341,
            "digest": "G6uxi8pJh6MbsGK1bybYj4VgT8KL8BqiYg4ftYVCYHYf"
          }
        ],
        "owner": "0x0deaf2ae9d8e4877eb7bf5d86434488e343b6881bedff8fc78031b6d0df7c75a",
        "price": "516",
        "budget": "20000000"
      }
    },
    "txSignatures": [
      "ABd7/l+Y6h0QR2IwwD3ALsm90zvsP1W8sHkrUOFyVrOGLiZC4NgPtEm4z5Q+GcmiUMqVDaXR4qmMig77z30K/AP2kJBg/LwnsKrg9YAOh6iaiahK8sMaI1lFOELfahaYKg=="
    ]
  },
  "effects": {
    "messageVersion": "v1",
    "status": {
      "status": "success"
    },
    "executedEpoch": "1029",
    "gasUsed": {
      "computationCost": "516000",
      "storageCost": "7220000",
      "storageRebate": "4175820",
      "nonRefundableStorageFee": "42180"
    },
    "modifiedAtVersions": [
      {
        "objectId": "0x684646dbd0b0c17ccff97904d59091766599fdbde56a542a29fe869af23bc94c",
        "sequenceNumber": "773550341"
      },
      {
        "objectId": "0x9409e01b8bafbad0b89e949bcfb8416be7f600f4b87df3bc4103e6f5d78cfb00",
        "sequenceNumber": "773550341"
      },
      {
        "objectId": "0xd4300a22ed111e2748cbf37a9d8989a465fcc93d6d5e51c3b50a01c5947a68e0",
        "sequenceNumber": "773550341"
      }
    ],
    "sharedObjects": [
      {
        "objectId": "0x9409e01b8bafbad0b89e949bcfb8416be7f600f4b87df3bc4103e6f5d78cfb00",
        "version": 773550341,
        "digest": "B3dpDMPyhP8UVZTnM9TbPh9TZX21N5J5E57GNY7qvZm6"
      },
      {
        "objectId": "0x0000000000000000000000000000000000000000000000000000000000000006",
        "version": 717883954,
        "digest": "92mKHzEPP1YBtya77qwVWwapuPPUwAaiYrBAMziYLxue"
      }
    ],
    "transactionDigest": "CKQftCqcvHxhrE2obZQ68zXFG3QCaaVT6QnJ6WdYYnuu",
    "created": [
      {
        "owner": {
          "ObjectOwner": "0x9409e01b8bafbad0b89e949bcfb8416be7f600f4b87df3bc4103e6f5d78cfb00"
        },
        "reference": {
          "objectId": "0xccc963294ad127a42dabf8322c3812826d1115758f324a0912d57b7e07f73fd7",
          "version": 773550342,
          "digest": "GFi7vxmvxWiXQsy5R3jQvt1n6bvwrgNsd24U8LkcKqC8"
        }
      }
    ],
    "mutated": [
      {
        "owner": {
          "AddressOwner": "0x0deaf2ae9d8e4877eb7bf5d86434488e343b6881bedff8fc78031b6d0df7c75a"
        },
        "reference": {
          "objectId": "0x684646dbd0b0c17ccff97904d59091766599fdbde56a542a29fe869af23bc94c",
          "version": 773550342,
          "digest": "3rbFhCeXavsncJAp1MpyHQH3bdvdByd4MbY2wXi96Q8G"
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
          "version": 773550342,
          "digest": "2g7U8kJAovA5s1RrBpoziH6GGFfhHm8dCWm7F8mwktKz"
        }
      },
      {
        "owner": {
          "AddressOwner": "0x0deaf2ae9d8e4877eb7bf5d86434488e343b6881bedff8fc78031b6d0df7c75a"
        },
        "reference": {
          "objectId": "0xd4300a22ed111e2748cbf37a9d8989a465fcc93d6d5e51c3b50a01c5947a68e0",
          "version": 773550342,
          "digest": "4aNrhSrhsibwheGVEUWeYtKP5aUxGbnZ3eBFW2w9H1yV"
        }
      }
    ],
    "gasObject": {
      "owner": {
        "AddressOwner": "0x0deaf2ae9d8e4877eb7bf5d86434488e343b6881bedff8fc78031b6d0df7c75a"
      },
      "reference": {
        "objectId": "0xd4300a22ed111e2748cbf37a9d8989a465fcc93d6d5e51c3b50a01c5947a68e0",
        "version": 773550342,
        "digest": "4aNrhSrhsibwheGVEUWeYtKP5aUxGbnZ3eBFW2w9H1yV"
      }
    },
    "eventsDigest": "CuFUBLcfLmyyXz8JWYXvEaGDGGNZPYQvmrdXVhL9tyNn",
    "dependencies": [
      "2H6L524aXaiZMFH4xRPaUvE1g2BvGXCXNzjdGXKySYZE",
      "3Zuk4wDwP5PCLqe4RaxenQ9an3GTepqREsPiMiVNLbGV",
      "7mM5sRre7Mx6kRChEycj2iy2W4fQkhSHQTDixBk42nNR",
      "9tJFsfsE1xYR1QKfyXRnxgVhpdNTfNj5ZPVZ5rb2Ju2X"
    ]
  },
  "events": [
    {
      "id": {
        "txDigest": "CKQftCqcvHxhrE2obZQ68zXFG3QCaaVT6QnJ6WdYYnuu",
        "eventSeq": "0"
      },
      "packageId": "0x035cf7b699be1d67785cc54dabc83e497fae23516c0329bea39faabf3384f702",
      "transactionModule": "crowd_walrus",
      "sender": "0x0deaf2ae9d8e4877eb7bf5d86434488e343b6881bedff8fc78031b6d0df7c75a",
      "type": "0x035cf7b699be1d67785cc54dabc83e497fae23516c0329bea39faabf3384f702::token_registry::TokenAdded",
      "parsedJson": {
        "coin_type": "356a26eb9e012a68958082340d4c4116e7f55615cf27affcff209cf0ae544f59::wal::WAL",
        "decimals": 9,
        "enabled": false,
        "max_age_ms": "300000",
        "name": "WAL Token",
        "pyth_feed_id": [
          235,
          160,
          115,
          35,
          149,
          250,
          233,
          222,
          196,
          186,
          225,
          46,
          82,
          118,
          11,
          53,
          252,
          28,
          86,
          113,
          226,
          218,
          139,
          68,
          156,
          154,
          244,
          239,
          229,
          213,
          67,
          65
        ],
        "symbol": "WAL",
        "timestamp_ms": "1770303507467"
      },
      "bcsEncoding": "base64",
      "bcs": "SjM1NmEyNmViOWUwMTJhNjg5NTgwODIzNDBkNGM0MTE2ZTdmNTU2MTVjZjI3YWZmY2ZmMjA5Y2YwYWU1NDRmNTk6OndhbDo6V0FMA1dBTAlXQUwgVG9rZW4JIOugcyOV+unexLrhLlJ2CzX8HFZx4tqLRJya9O/l1UNB4JMEAAAAAAAAC8xPLpwBAAA="
    }
  ],
  "objectChanges": [
    {
      "type": "mutated",
      "sender": "0x0deaf2ae9d8e4877eb7bf5d86434488e343b6881bedff8fc78031b6d0df7c75a",
      "owner": {
        "AddressOwner": "0x0deaf2ae9d8e4877eb7bf5d86434488e343b6881bedff8fc78031b6d0df7c75a"
      },
      "objectType": "0x035cf7b699be1d67785cc54dabc83e497fae23516c0329bea39faabf3384f702::crowd_walrus::AdminCap",
      "objectId": "0x684646dbd0b0c17ccff97904d59091766599fdbde56a542a29fe869af23bc94c",
      "version": "773550342",
      "previousVersion": "773550341",
      "digest": "3rbFhCeXavsncJAp1MpyHQH3bdvdByd4MbY2wXi96Q8G"
    },
    {
      "type": "mutated",
      "sender": "0x0deaf2ae9d8e4877eb7bf5d86434488e343b6881bedff8fc78031b6d0df7c75a",
      "owner": {
        "Shared": {
          "initial_shared_version": 773550337
        }
      },
      "objectType": "0x035cf7b699be1d67785cc54dabc83e497fae23516c0329bea39faabf3384f702::token_registry::TokenRegistry",
      "objectId": "0x9409e01b8bafbad0b89e949bcfb8416be7f600f4b87df3bc4103e6f5d78cfb00",
      "version": "773550342",
      "previousVersion": "773550341",
      "digest": "2g7U8kJAovA5s1RrBpoziH6GGFfhHm8dCWm7F8mwktKz"
    },
    {
      "type": "mutated",
      "sender": "0x0deaf2ae9d8e4877eb7bf5d86434488e343b6881bedff8fc78031b6d0df7c75a",
      "owner": {
        "AddressOwner": "0x0deaf2ae9d8e4877eb7bf5d86434488e343b6881bedff8fc78031b6d0df7c75a"
      },
      "objectType": "0x2::coin::Coin<0x2::sui::SUI>",
      "objectId": "0xd4300a22ed111e2748cbf37a9d8989a465fcc93d6d5e51c3b50a01c5947a68e0",
      "version": "773550342",
      "previousVersion": "773550341",
      "digest": "4aNrhSrhsibwheGVEUWeYtKP5aUxGbnZ3eBFW2w9H1yV"
    },
    {
      "type": "created",
      "sender": "0x0deaf2ae9d8e4877eb7bf5d86434488e343b6881bedff8fc78031b6d0df7c75a",
      "owner": {
        "ObjectOwner": "0x9409e01b8bafbad0b89e949bcfb8416be7f600f4b87df3bc4103e6f5d78cfb00"
      },
      "objectType": "0x2::dynamic_field::Field<0x035cf7b699be1d67785cc54dabc83e497fae23516c0329bea39faabf3384f702::token_registry::CoinKey<0x356a26eb9e012a68958082340d4c4116e7f55615cf27affcff209cf0ae544f59::wal::WAL>, 0x035cf7b699be1d67785cc54dabc83e497fae23516c0329bea39faabf3384f702::token_registry::TokenMetadata>",
      "objectId": "0xccc963294ad127a42dabf8322c3812826d1115758f324a0912d57b7e07f73fd7",
      "version": "773550342",
      "digest": "GFi7vxmvxWiXQsy5R3jQvt1n6bvwrgNsd24U8LkcKqC8"
    }
  ],
  "balanceChanges": [
    {
      "owner": {
        "AddressOwner": "0x0deaf2ae9d8e4877eb7bf5d86434488e343b6881bedff8fc78031b6d0df7c75a"
      },
      "coinType": "0x2::sui::SUI",
      "amount": "-3560180"
    }
  ],
  "confirmedLocalExecution": true
}
```


## WAL token enable (earlier)

Path: `/tmp/set_token_enabled_wal_2026-02-05.json`

```json
{
  "digest": "HyfWo9qdDwfY2ByRQi9cVWdfQz29BuWrNuxWVYLanyLu",
  "transaction": {
    "data": {
      "messageVersion": "v1",
      "transaction": {
        "kind": "ProgrammableTransaction",
        "inputs": [
          {
            "type": "object",
            "objectType": "sharedObject",
            "objectId": "0x9409e01b8bafbad0b89e949bcfb8416be7f600f4b87df3bc4103e6f5d78cfb00",
            "initialSharedVersion": "773550337",
            "mutable": true
          },
          {
            "type": "object",
            "objectType": "immOrOwnedObject",
            "objectId": "0x684646dbd0b0c17ccff97904d59091766599fdbde56a542a29fe869af23bc94c",
            "version": "773550342",
            "digest": "3rbFhCeXavsncJAp1MpyHQH3bdvdByd4MbY2wXi96Q8G"
          },
          {
            "type": "pure",
            "valueType": "bool",
            "value": true
          },
          {
            "type": "object",
            "objectType": "sharedObject",
            "objectId": "0x0000000000000000000000000000000000000000000000000000000000000006",
            "initialSharedVersion": "1",
            "mutable": false
          }
        ],
        "transactions": [
          {
            "MoveCall": {
              "package": "0x035cf7b699be1d67785cc54dabc83e497fae23516c0329bea39faabf3384f702",
              "module": "crowd_walrus",
              "function": "set_token_enabled",
              "type_arguments": [
                "0x356a26eb9e012a68958082340d4c4116e7f55615cf27affcff209cf0ae544f59::wal::WAL"
              ],
              "arguments": [
                {
                  "Input": 0
                },
                {
                  "Input": 1
                },
                {
                  "Input": 2
                },
                {
                  "Input": 3
                }
              ]
            }
          }
        ]
      },
      "sender": "0x0deaf2ae9d8e4877eb7bf5d86434488e343b6881bedff8fc78031b6d0df7c75a",
      "gasData": {
        "payment": [
          {
            "objectId": "0xd4300a22ed111e2748cbf37a9d8989a465fcc93d6d5e51c3b50a01c5947a68e0",
            "version": 773550342,
            "digest": "4aNrhSrhsibwheGVEUWeYtKP5aUxGbnZ3eBFW2w9H1yV"
          }
        ],
        "owner": "0x0deaf2ae9d8e4877eb7bf5d86434488e343b6881bedff8fc78031b6d0df7c75a",
        "price": "516",
        "budget": "10000000"
      }
    },
    "txSignatures": [
      "AM9RL4/MYpsnIF971VKtdWWYtzDKS+TktpMxFNQxHWu74TdfD6LZ/E5DT25ghIdT/ISP7n2F8HxWvQAqJNuisgj2kJBg/LwnsKrg9YAOh6iaiahK8sMaI1lFOELfahaYKg=="
    ]
  },
  "effects": {
    "messageVersion": "v1",
    "status": {
      "status": "success"
    },
    "executedEpoch": "1029",
    "gasUsed": {
      "computationCost": "516000",
      "storageCost": "7220000",
      "storageRebate": "7147800",
      "nonRefundableStorageFee": "72200"
    },
    "modifiedAtVersions": [
      {
        "objectId": "0x684646dbd0b0c17ccff97904d59091766599fdbde56a542a29fe869af23bc94c",
        "sequenceNumber": "773550342"
      },
      {
        "objectId": "0x9409e01b8bafbad0b89e949bcfb8416be7f600f4b87df3bc4103e6f5d78cfb00",
        "sequenceNumber": "773550342"
      },
      {
        "objectId": "0xccc963294ad127a42dabf8322c3812826d1115758f324a0912d57b7e07f73fd7",
        "sequenceNumber": "773550342"
      },
      {
        "objectId": "0xd4300a22ed111e2748cbf37a9d8989a465fcc93d6d5e51c3b50a01c5947a68e0",
        "sequenceNumber": "773550342"
      }
    ],
    "sharedObjects": [
      {
        "objectId": "0x9409e01b8bafbad0b89e949bcfb8416be7f600f4b87df3bc4103e6f5d78cfb00",
        "version": 773550342,
        "digest": "2g7U8kJAovA5s1RrBpoziH6GGFfhHm8dCWm7F8mwktKz"
      },
      {
        "objectId": "0x0000000000000000000000000000000000000000000000000000000000000006",
        "version": 717884123,
        "digest": "CurZZGAorCiadSqVhs6FvemaH6pd9FbZq4LDJR2MCWRV"
      }
    ],
    "transactionDigest": "HyfWo9qdDwfY2ByRQi9cVWdfQz29BuWrNuxWVYLanyLu",
    "mutated": [
      {
        "owner": {
          "AddressOwner": "0x0deaf2ae9d8e4877eb7bf5d86434488e343b6881bedff8fc78031b6d0df7c75a"
        },
        "reference": {
          "objectId": "0x684646dbd0b0c17ccff97904d59091766599fdbde56a542a29fe869af23bc94c",
          "version": 773550343,
          "digest": "4ZvHLoufMwvdEjNEjT5ChBaS9Eu68xDTPFhJb3ssEZjJ"
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
          "version": 773550343,
          "digest": "q3kFAhk6EKCqHnxewzocuPBJj6JYmBD87n7tQU1rmh2"
        }
      },
      {
        "owner": {
          "ObjectOwner": "0x9409e01b8bafbad0b89e949bcfb8416be7f600f4b87df3bc4103e6f5d78cfb00"
        },
        "reference": {
          "objectId": "0xccc963294ad127a42dabf8322c3812826d1115758f324a0912d57b7e07f73fd7",
          "version": 773550343,
          "digest": "77u2zny4ViB7JdFbCBedXWPHBdJaaKPWLnDxSJRn3Bci"
        }
      },
      {
        "owner": {
          "AddressOwner": "0x0deaf2ae9d8e4877eb7bf5d86434488e343b6881bedff8fc78031b6d0df7c75a"
        },
        "reference": {
          "objectId": "0xd4300a22ed111e2748cbf37a9d8989a465fcc93d6d5e51c3b50a01c5947a68e0",
          "version": 773550343,
          "digest": "9LKYxNsFgpNH84wX9cvWYzwoquSJMLrbSMndmuiq17R9"
        }
      }
    ],
    "gasObject": {
      "owner": {
        "AddressOwner": "0x0deaf2ae9d8e4877eb7bf5d86434488e343b6881bedff8fc78031b6d0df7c75a"
      },
      "reference": {
        "objectId": "0xd4300a22ed111e2748cbf37a9d8989a465fcc93d6d5e51c3b50a01c5947a68e0",
        "version": 773550343,
        "digest": "9LKYxNsFgpNH84wX9cvWYzwoquSJMLrbSMndmuiq17R9"
      }
    },
    "eventsDigest": "3uourqroqNqyBqeqpNVsnA9gpc2WA32EtE3RUS83wffK",
    "dependencies": [
      "7Wq7k8CaG4f3yi11k7mmQ2Lx1kuvxyKn68nPbh9fr5vS",
      "7mM5sRre7Mx6kRChEycj2iy2W4fQkhSHQTDixBk42nNR",
      "9tJFsfsE1xYR1QKfyXRnxgVhpdNTfNj5ZPVZ5rb2Ju2X",
      "CKQftCqcvHxhrE2obZQ68zXFG3QCaaVT6QnJ6WdYYnuu"
    ]
  },
  "events": [
    {
      "id": {
        "txDigest": "HyfWo9qdDwfY2ByRQi9cVWdfQz29BuWrNuxWVYLanyLu",
        "eventSeq": "0"
      },
      "packageId": "0x035cf7b699be1d67785cc54dabc83e497fae23516c0329bea39faabf3384f702",
      "transactionModule": "crowd_walrus",
      "sender": "0x0deaf2ae9d8e4877eb7bf5d86434488e343b6881bedff8fc78031b6d0df7c75a",
      "type": "0x035cf7b699be1d67785cc54dabc83e497fae23516c0329bea39faabf3384f702::token_registry::TokenEnabled",
      "parsedJson": {
        "coin_type": "356a26eb9e012a68958082340d4c4116e7f55615cf27affcff209cf0ae544f59::wal::WAL",
        "symbol": "WAL",
        "timestamp_ms": "1770303524645"
      },
      "bcsEncoding": "base64",
      "bcs": "SjM1NmEyNmViOWUwMTJhNjg5NTgwODIzNDBkNGM0MTE2ZTdmNTU2MTVjZjI3YWZmY2ZmMjA5Y2YwYWU1NDRmNTk6OndhbDo6V0FMA1dBTCUPUC6cAQAA"
    }
  ],
  "objectChanges": [
    {
      "type": "mutated",
      "sender": "0x0deaf2ae9d8e4877eb7bf5d86434488e343b6881bedff8fc78031b6d0df7c75a",
      "owner": {
        "AddressOwner": "0x0deaf2ae9d8e4877eb7bf5d86434488e343b6881bedff8fc78031b6d0df7c75a"
      },
      "objectType": "0x035cf7b699be1d67785cc54dabc83e497fae23516c0329bea39faabf3384f702::crowd_walrus::AdminCap",
      "objectId": "0x684646dbd0b0c17ccff97904d59091766599fdbde56a542a29fe869af23bc94c",
      "version": "773550343",
      "previousVersion": "773550342",
      "digest": "4ZvHLoufMwvdEjNEjT5ChBaS9Eu68xDTPFhJb3ssEZjJ"
    },
    {
      "type": "mutated",
      "sender": "0x0deaf2ae9d8e4877eb7bf5d86434488e343b6881bedff8fc78031b6d0df7c75a",
      "owner": {
        "Shared": {
          "initial_shared_version": 773550337
        }
      },
      "objectType": "0x035cf7b699be1d67785cc54dabc83e497fae23516c0329bea39faabf3384f702::token_registry::TokenRegistry",
      "objectId": "0x9409e01b8bafbad0b89e949bcfb8416be7f600f4b87df3bc4103e6f5d78cfb00",
      "version": "773550343",
      "previousVersion": "773550342",
      "digest": "q3kFAhk6EKCqHnxewzocuPBJj6JYmBD87n7tQU1rmh2"
    },
    {
      "type": "mutated",
      "sender": "0x0deaf2ae9d8e4877eb7bf5d86434488e343b6881bedff8fc78031b6d0df7c75a",
      "owner": {
        "ObjectOwner": "0x9409e01b8bafbad0b89e949bcfb8416be7f600f4b87df3bc4103e6f5d78cfb00"
      },
      "objectType": "0x2::dynamic_field::Field<0x035cf7b699be1d67785cc54dabc83e497fae23516c0329bea39faabf3384f702::token_registry::CoinKey<0x356a26eb9e012a68958082340d4c4116e7f55615cf27affcff209cf0ae544f59::wal::WAL>, 0x035cf7b699be1d67785cc54dabc83e497fae23516c0329bea39faabf3384f702::token_registry::TokenMetadata>",
      "objectId": "0xccc963294ad127a42dabf8322c3812826d1115758f324a0912d57b7e07f73fd7",
      "version": "773550343",
      "previousVersion": "773550342",
      "digest": "77u2zny4ViB7JdFbCBedXWPHBdJaaKPWLnDxSJRn3Bci"
    },
    {
      "type": "mutated",
      "sender": "0x0deaf2ae9d8e4877eb7bf5d86434488e343b6881bedff8fc78031b6d0df7c75a",
      "owner": {
        "AddressOwner": "0x0deaf2ae9d8e4877eb7bf5d86434488e343b6881bedff8fc78031b6d0df7c75a"
      },
      "objectType": "0x2::coin::Coin<0x2::sui::SUI>",
      "objectId": "0xd4300a22ed111e2748cbf37a9d8989a465fcc93d6d5e51c3b50a01c5947a68e0",
      "version": "773550343",
      "previousVersion": "773550342",
      "digest": "9LKYxNsFgpNH84wX9cvWYzwoquSJMLrbSMndmuiq17R9"
    }
  ],
  "balanceChanges": [
    {
      "owner": {
        "AddressOwner": "0x0deaf2ae9d8e4877eb7bf5d86434488e343b6881bedff8fc78031b6d0df7c75a"
      },
      "coinType": "0x2::sui::SUI",
      "amount": "-588200"
    }
  ],
  "confirmedLocalExecution": true
}
```


## NS token add

Path: `/tmp/mainnet_add_token_ns.json`

```json
{
  "digest": "25gZNcAY4iCQcvkac2Te3w2zNDUpyQrQgqwD3ZdtPoxZ",
  "transaction": {
    "data": {
      "messageVersion": "v1",
      "transaction": {
        "kind": "ProgrammableTransaction",
        "inputs": [
          {
            "type": "object",
            "objectType": "sharedObject",
            "objectId": "0x9409e01b8bafbad0b89e949bcfb8416be7f600f4b87df3bc4103e6f5d78cfb00",
            "initialSharedVersion": "773550337",
            "mutable": true
          },
          {
            "type": "object",
            "objectType": "immOrOwnedObject",
            "objectId": "0x684646dbd0b0c17ccff97904d59091766599fdbde56a542a29fe869af23bc94c",
            "version": "773550343",
            "digest": "4ZvHLoufMwvdEjNEjT5ChBaS9Eu68xDTPFhJb3ssEZjJ"
          },
          {
            "type": "pure",
            "valueType": "0x1::string::String",
            "value": "NS"
          },
          {
            "type": "pure",
            "valueType": "0x1::string::String",
            "value": "SuiNS Token"
          },
          {
            "type": "pure",
            "valueType": "u8",
            "value": 6
          },
          {
            "type": "pure",
            "valueType": "vector<u8>",
            "value": [
              187,
              95,
              242,
              110,
              71,
              163,
              166,
              204,
              126,
              194,
              252,
              225,
              219,
              153,
              108,
              42,
              20,
              83,
              0,
              237,
              197,
              172,
              170,
              190,
              67,
              191,
              159,
              247,
              197,
              221,
              93,
              50
            ]
          },
          {
            "type": "pure",
            "valueType": "u64",
            "value": "300000"
          },
          {
            "type": "object",
            "objectType": "sharedObject",
            "objectId": "0x0000000000000000000000000000000000000000000000000000000000000006",
            "initialSharedVersion": "1",
            "mutable": false
          }
        ],
        "transactions": [
          {
            "MoveCall": {
              "package": "0x035cf7b699be1d67785cc54dabc83e497fae23516c0329bea39faabf3384f702",
              "module": "crowd_walrus",
              "function": "add_token",
              "type_arguments": [
                "0x5145494a5f5100e645e4b0aa950fa6b68f614e8c59e17bc5ded3495123a79178::ns::NS"
              ],
              "arguments": [
                {
                  "Input": 0
                },
                {
                  "Input": 1
                },
                {
                  "Input": 2
                },
                {
                  "Input": 3
                },
                {
                  "Input": 4
                },
                {
                  "Input": 5
                },
                {
                  "Input": 6
                },
                {
                  "Input": 7
                }
              ]
            }
          }
        ]
      },
      "sender": "0x0deaf2ae9d8e4877eb7bf5d86434488e343b6881bedff8fc78031b6d0df7c75a",
      "gasData": {
        "payment": [
          {
            "objectId": "0xd4300a22ed111e2748cbf37a9d8989a465fcc93d6d5e51c3b50a01c5947a68e0",
            "version": 773550343,
            "digest": "9LKYxNsFgpNH84wX9cvWYzwoquSJMLrbSMndmuiq17R9"
          }
        ],
        "owner": "0x0deaf2ae9d8e4877eb7bf5d86434488e343b6881bedff8fc78031b6d0df7c75a",
        "price": "516",
        "budget": "20000000"
      }
    },
    "txSignatures": [
      "AIgdsOl8+GGksn3h7qUwdKoB5qQuCK7OK/ZbNjzCLxjOxyQLTOpyO0dyIeKJ2aDME9DPAlu48cB22mAayY+qSQf2kJBg/LwnsKrg9YAOh6iaiahK8sMaI1lFOELfahaYKg=="
    ]
  },
  "effects": {
    "messageVersion": "v1",
    "status": {
      "status": "success"
    },
    "executedEpoch": "1029",
    "gasUsed": {
      "computationCost": "516000",
      "storageCost": "7212400",
      "storageRebate": "4175820",
      "nonRefundableStorageFee": "42180"
    },
    "modifiedAtVersions": [
      {
        "objectId": "0x684646dbd0b0c17ccff97904d59091766599fdbde56a542a29fe869af23bc94c",
        "sequenceNumber": "773550343"
      },
      {
        "objectId": "0x9409e01b8bafbad0b89e949bcfb8416be7f600f4b87df3bc4103e6f5d78cfb00",
        "sequenceNumber": "773550343"
      },
      {
        "objectId": "0xd4300a22ed111e2748cbf37a9d8989a465fcc93d6d5e51c3b50a01c5947a68e0",
        "sequenceNumber": "773550343"
      }
    ],
    "sharedObjects": [
      {
        "objectId": "0x9409e01b8bafbad0b89e949bcfb8416be7f600f4b87df3bc4103e6f5d78cfb00",
        "version": 773550343,
        "digest": "q3kFAhk6EKCqHnxewzocuPBJj6JYmBD87n7tQU1rmh2"
      },
      {
        "objectId": "0x0000000000000000000000000000000000000000000000000000000000000006",
        "version": 717888847,
        "digest": "HyHj6GHyx8XUFLbooZB1hR1meUvkWgTLWCH1aZKKdroC"
      }
    ],
    "transactionDigest": "25gZNcAY4iCQcvkac2Te3w2zNDUpyQrQgqwD3ZdtPoxZ",
    "created": [
      {
        "owner": {
          "ObjectOwner": "0x9409e01b8bafbad0b89e949bcfb8416be7f600f4b87df3bc4103e6f5d78cfb00"
        },
        "reference": {
          "objectId": "0x7dd6f5084edb348062223be60e2c022a30d93c838f89d8e3f4583d78189910d3",
          "version": 773550344,
          "digest": "3RbYLEnyQJt47sMUcpwmeN9dhDtjc4KWGdg4jVzVdMPz"
        }
      }
    ],
    "mutated": [
      {
        "owner": {
          "AddressOwner": "0x0deaf2ae9d8e4877eb7bf5d86434488e343b6881bedff8fc78031b6d0df7c75a"
        },
        "reference": {
          "objectId": "0x684646dbd0b0c17ccff97904d59091766599fdbde56a542a29fe869af23bc94c",
          "version": 773550344,
          "digest": "7tUwbcd4cGgEdyPYWHxoERFL8p7YYqrGWccwEM6su7cE"
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
          "version": 773550344,
          "digest": "2MDtXVKSrGbZ6GHPXuq3DZJXCu7YkHcAer8YhsuH8xtZ"
        }
      },
      {
        "owner": {
          "AddressOwner": "0x0deaf2ae9d8e4877eb7bf5d86434488e343b6881bedff8fc78031b6d0df7c75a"
        },
        "reference": {
          "objectId": "0xd4300a22ed111e2748cbf37a9d8989a465fcc93d6d5e51c3b50a01c5947a68e0",
          "version": 773550344,
          "digest": "wZ813N6bqb6cMtRiGCkUEDgUrYuxAB8oCymEhMhkYvZ"
        }
      }
    ],
    "gasObject": {
      "owner": {
        "AddressOwner": "0x0deaf2ae9d8e4877eb7bf5d86434488e343b6881bedff8fc78031b6d0df7c75a"
      },
      "reference": {
        "objectId": "0xd4300a22ed111e2748cbf37a9d8989a465fcc93d6d5e51c3b50a01c5947a68e0",
        "version": 773550344,
        "digest": "wZ813N6bqb6cMtRiGCkUEDgUrYuxAB8oCymEhMhkYvZ"
      }
    },
    "eventsDigest": "2ZBUQghybgbXXoTEyhpFwtD1H9sPQEFZeNXBDbf4vXPG",
    "dependencies": [
      "7Lc5pPSAPRHxH7QNdTeswuwTJPp4sMe4Z1gUotuX7NWp",
      "9tJFsfsE1xYR1QKfyXRnxgVhpdNTfNj5ZPVZ5rb2Ju2X",
      "AZar5kDSPkiu1Er8XoHCeKRaoQbrPiyrfhivuKKS3e2k",
      "HyfWo9qdDwfY2ByRQi9cVWdfQz29BuWrNuxWVYLanyLu"
    ]
  },
  "events": [
    {
      "id": {
        "txDigest": "25gZNcAY4iCQcvkac2Te3w2zNDUpyQrQgqwD3ZdtPoxZ",
        "eventSeq": "0"
      },
      "packageId": "0x035cf7b699be1d67785cc54dabc83e497fae23516c0329bea39faabf3384f702",
      "transactionModule": "crowd_walrus",
      "sender": "0x0deaf2ae9d8e4877eb7bf5d86434488e343b6881bedff8fc78031b6d0df7c75a",
      "type": "0x035cf7b699be1d67785cc54dabc83e497fae23516c0329bea39faabf3384f702::token_registry::TokenAdded",
      "parsedJson": {
        "coin_type": "5145494a5f5100e645e4b0aa950fa6b68f614e8c59e17bc5ded3495123a79178::ns::NS",
        "decimals": 6,
        "enabled": false,
        "max_age_ms": "300000",
        "name": "SuiNS Token",
        "pyth_feed_id": [
          187,
          95,
          242,
          110,
          71,
          163,
          166,
          204,
          126,
          194,
          252,
          225,
          219,
          153,
          108,
          42,
          20,
          83,
          0,
          237,
          197,
          172,
          170,
          190,
          67,
          191,
          159,
          247,
          197,
          221,
          93,
          50
        ],
        "symbol": "NS",
        "timestamp_ms": "1770304034212"
      },
      "bcsEncoding": "base64",
      "bcs": "SDUxNDU0OTRhNWY1MTAwZTY0NWU0YjBhYTk1MGZhNmI2OGY2MTRlOGM1OWUxN2JjNWRlZDM0OTUxMjNhNzkxNzg6Om5zOjpOUwJOUwtTdWlOUyBUb2tlbgYgu1/ybkejpsx+wvzh25lsKhRTAO3FrKq+Q7+f98XdXTLgkwQAAAAAAACk1VcunAEAAA=="
    }
  ],
  "timestampMs": "1770304034408",
  "confirmedLocalExecution": true,
  "checkpoint": "241925653",
  "errors": [
    "Cannot retrieve balance changes: Could not find the referenced object 0x684646dbd0b0c17ccff97904d59091766599fdbde56a542a29fe869af23bc94c as the asked version SequenceNumber(773550344) is higher than the latest SequenceNumber(773550343)",
    "Cannot retrieve object changes: Could not find the referenced object 0x684646dbd0b0c17ccff97904d59091766599fdbde56a542a29fe869af23bc94c as the asked version SequenceNumber(773550344) is higher than the latest SequenceNumber(773550343)"
  ]
}
```


## NS token enable

Path: `/tmp/mainnet_enable_token_ns.json`

```json
{
  "digest": "5fjznGPizPHDtfa8Tf7p1uiGSssoLBYWfrnMtstd2pUQ",
  "transaction": {
    "data": {
      "messageVersion": "v1",
      "transaction": {
        "kind": "ProgrammableTransaction",
        "inputs": [
          {
            "type": "object",
            "objectType": "sharedObject",
            "objectId": "0x9409e01b8bafbad0b89e949bcfb8416be7f600f4b87df3bc4103e6f5d78cfb00",
            "initialSharedVersion": "773550337",
            "mutable": true
          },
          {
            "type": "object",
            "objectType": "immOrOwnedObject",
            "objectId": "0x684646dbd0b0c17ccff97904d59091766599fdbde56a542a29fe869af23bc94c",
            "version": "773550344",
            "digest": "7tUwbcd4cGgEdyPYWHxoERFL8p7YYqrGWccwEM6su7cE"
          },
          {
            "type": "pure",
            "valueType": "bool",
            "value": true
          },
          {
            "type": "object",
            "objectType": "sharedObject",
            "objectId": "0x0000000000000000000000000000000000000000000000000000000000000006",
            "initialSharedVersion": "1",
            "mutable": false
          }
        ],
        "transactions": [
          {
            "MoveCall": {
              "package": "0x035cf7b699be1d67785cc54dabc83e497fae23516c0329bea39faabf3384f702",
              "module": "crowd_walrus",
              "function": "set_token_enabled",
              "type_arguments": [
                "0x5145494a5f5100e645e4b0aa950fa6b68f614e8c59e17bc5ded3495123a79178::ns::NS"
              ],
              "arguments": [
                {
                  "Input": 0
                },
                {
                  "Input": 1
                },
                {
                  "Input": 2
                },
                {
                  "Input": 3
                }
              ]
            }
          }
        ]
      },
      "sender": "0x0deaf2ae9d8e4877eb7bf5d86434488e343b6881bedff8fc78031b6d0df7c75a",
      "gasData": {
        "payment": [
          {
            "objectId": "0xd4300a22ed111e2748cbf37a9d8989a465fcc93d6d5e51c3b50a01c5947a68e0",
            "version": 773550344,
            "digest": "wZ813N6bqb6cMtRiGCkUEDgUrYuxAB8oCymEhMhkYvZ"
          }
        ],
        "owner": "0x0deaf2ae9d8e4877eb7bf5d86434488e343b6881bedff8fc78031b6d0df7c75a",
        "price": "516",
        "budget": "10000000"
      }
    },
    "txSignatures": [
      "AHXWYUornuO9kLbKl2ijbSiwLqwlkhxmoteF+Yehe5BaQP2rtZvsVdZY506gwMb79TRVjmtqMthdcehtpyU5nwD2kJBg/LwnsKrg9YAOh6iaiahK8sMaI1lFOELfahaYKg=="
    ]
  },
  "effects": {
    "messageVersion": "v1",
    "status": {
      "status": "success"
    },
    "executedEpoch": "1029",
    "gasUsed": {
      "computationCost": "516000",
      "storageCost": "7212400",
      "storageRebate": "7140276",
      "nonRefundableStorageFee": "72124"
    },
    "modifiedAtVersions": [
      {
        "objectId": "0x684646dbd0b0c17ccff97904d59091766599fdbde56a542a29fe869af23bc94c",
        "sequenceNumber": "773550344"
      },
      {
        "objectId": "0x7dd6f5084edb348062223be60e2c022a30d93c838f89d8e3f4583d78189910d3",
        "sequenceNumber": "773550344"
      },
      {
        "objectId": "0x9409e01b8bafbad0b89e949bcfb8416be7f600f4b87df3bc4103e6f5d78cfb00",
        "sequenceNumber": "773550344"
      },
      {
        "objectId": "0xd4300a22ed111e2748cbf37a9d8989a465fcc93d6d5e51c3b50a01c5947a68e0",
        "sequenceNumber": "773550344"
      }
    ],
    "sharedObjects": [
      {
        "objectId": "0x9409e01b8bafbad0b89e949bcfb8416be7f600f4b87df3bc4103e6f5d78cfb00",
        "version": 773550344,
        "digest": "2MDtXVKSrGbZ6GHPXuq3DZJXCu7YkHcAer8YhsuH8xtZ"
      },
      {
        "objectId": "0x0000000000000000000000000000000000000000000000000000000000000006",
        "version": 717890448,
        "digest": "4JTDgzoUzBp6mhefEGrPuSBjS518T3mFUbtvd9UWosXh"
      }
    ],
    "transactionDigest": "5fjznGPizPHDtfa8Tf7p1uiGSssoLBYWfrnMtstd2pUQ",
    "mutated": [
      {
        "owner": {
          "AddressOwner": "0x0deaf2ae9d8e4877eb7bf5d86434488e343b6881bedff8fc78031b6d0df7c75a"
        },
        "reference": {
          "objectId": "0x684646dbd0b0c17ccff97904d59091766599fdbde56a542a29fe869af23bc94c",
          "version": 773550345,
          "digest": "5m78YGTHDZy37zWWNvpJycWtfWmSLZa27hKdBZuQXGxx"
        }
      },
      {
        "owner": {
          "ObjectOwner": "0x9409e01b8bafbad0b89e949bcfb8416be7f600f4b87df3bc4103e6f5d78cfb00"
        },
        "reference": {
          "objectId": "0x7dd6f5084edb348062223be60e2c022a30d93c838f89d8e3f4583d78189910d3",
          "version": 773550345,
          "digest": "GMfQZRx3GshQRCYKFbsyC4rqQQhQAkEjfhYSRPy3apyM"
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
          "version": 773550345,
          "digest": "H4RTWvq3nD1Yhq3MS4A2YbeyenuDTkTNBeSXVc2L5RbZ"
        }
      },
      {
        "owner": {
          "AddressOwner": "0x0deaf2ae9d8e4877eb7bf5d86434488e343b6881bedff8fc78031b6d0df7c75a"
        },
        "reference": {
          "objectId": "0xd4300a22ed111e2748cbf37a9d8989a465fcc93d6d5e51c3b50a01c5947a68e0",
          "version": 773550345,
          "digest": "BxpVSNmeAvGuqentFfvWrMJpFrsfrD6bepjXiqBEMCTa"
        }
      }
    ],
    "gasObject": {
      "owner": {
        "AddressOwner": "0x0deaf2ae9d8e4877eb7bf5d86434488e343b6881bedff8fc78031b6d0df7c75a"
      },
      "reference": {
        "objectId": "0xd4300a22ed111e2748cbf37a9d8989a465fcc93d6d5e51c3b50a01c5947a68e0",
        "version": 773550345,
        "digest": "BxpVSNmeAvGuqentFfvWrMJpFrsfrD6bepjXiqBEMCTa"
      }
    },
    "eventsDigest": "E6EAJQgQQmLNWE2khq7mtp6mjNdkntkTDRDG4DoR4ccF",
    "dependencies": [
      "25gZNcAY4iCQcvkac2Te3w2zNDUpyQrQgqwD3ZdtPoxZ",
      "7Lc5pPSAPRHxH7QNdTeswuwTJPp4sMe4Z1gUotuX7NWp",
      "9tJFsfsE1xYR1QKfyXRnxgVhpdNTfNj5ZPVZ5rb2Ju2X",
      "A725csNCxJa1F5kGw1yGEBtjZ5wzg9pmtVRyt5TEU8r8"
    ]
  },
  "events": [
    {
      "id": {
        "txDigest": "5fjznGPizPHDtfa8Tf7p1uiGSssoLBYWfrnMtstd2pUQ",
        "eventSeq": "0"
      },
      "packageId": "0x035cf7b699be1d67785cc54dabc83e497fae23516c0329bea39faabf3384f702",
      "transactionModule": "crowd_walrus",
      "sender": "0x0deaf2ae9d8e4877eb7bf5d86434488e343b6881bedff8fc78031b6d0df7c75a",
      "type": "0x035cf7b699be1d67785cc54dabc83e497fae23516c0329bea39faabf3384f702::token_registry::TokenEnabled",
      "parsedJson": {
        "coin_type": "5145494a5f5100e645e4b0aa950fa6b68f614e8c59e17bc5ded3495123a79178::ns::NS",
        "symbol": "NS",
        "timestamp_ms": "1770304198447"
      },
      "bcsEncoding": "base64",
      "bcs": "SDUxNDU0OTRhNWY1MTAwZTY0NWU0YjBhYTk1MGZhNmI2OGY2MTRlOGM1OWUxN2JjNWRlZDM0OTUxMjNhNzkxNzg6Om5zOjpOUwJOUy9XWi6cAQAA"
    }
  ],
  "timestampMs": "1770304198637",
  "confirmedLocalExecution": true,
  "checkpoint": "241926274",
  "errors": [
    "Cannot retrieve balance changes: Could not find the referenced object 0x684646dbd0b0c17ccff97904d59091766599fdbde56a542a29fe869af23bc94c as the asked version SequenceNumber(773550345) is higher than the latest SequenceNumber(773550344)",
    "Cannot retrieve object changes: Could not find the referenced object 0x684646dbd0b0c17ccff97904d59091766599fdbde56a542a29fe869af23bc94c as the asked version SequenceNumber(773550345) is higher than the latest SequenceNumber(773550344)"
  ]
}
```


## BLUE token add

Path: `/tmp/mainnet_add_token_blue.json`

```json
{
  "digest": "6C8iFMzoEVAQEReDW3HgMWcvVsRrw4SLq6wB34bWGUTB",
  "transaction": {
    "data": {
      "messageVersion": "v1",
      "transaction": {
        "kind": "ProgrammableTransaction",
        "inputs": [
          {
            "type": "object",
            "objectType": "sharedObject",
            "objectId": "0x9409e01b8bafbad0b89e949bcfb8416be7f600f4b87df3bc4103e6f5d78cfb00",
            "initialSharedVersion": "773550337",
            "mutable": true
          },
          {
            "type": "object",
            "objectType": "immOrOwnedObject",
            "objectId": "0x684646dbd0b0c17ccff97904d59091766599fdbde56a542a29fe869af23bc94c",
            "version": "773550345",
            "digest": "5m78YGTHDZy37zWWNvpJycWtfWmSLZa27hKdBZuQXGxx"
          },
          {
            "type": "pure",
            "valueType": "0x1::string::String",
            "value": "BLUE"
          },
          {
            "type": "pure",
            "valueType": "0x1::string::String",
            "value": "Bluefin"
          },
          {
            "type": "pure",
            "valueType": "u8",
            "value": 9
          },
          {
            "type": "pure",
            "valueType": "vector<u8>",
            "value": [
              4,
              207,
              235,
              123,
              20,
              62,
              185,
              196,
              142,
              155,
              7,
              65,
              37,
              193,
              163,
              68,
              123,
              133,
              245,
              156,
              49,
              22,
              77,
              194,
              12,
              27,
              234,
              166,
              242,
              31,
              43,
              107
            ]
          },
          {
            "type": "pure",
            "valueType": "u64",
            "value": "300000"
          },
          {
            "type": "object",
            "objectType": "sharedObject",
            "objectId": "0x0000000000000000000000000000000000000000000000000000000000000006",
            "initialSharedVersion": "1",
            "mutable": false
          }
        ],
        "transactions": [
          {
            "MoveCall": {
              "package": "0x035cf7b699be1d67785cc54dabc83e497fae23516c0329bea39faabf3384f702",
              "module": "crowd_walrus",
              "function": "add_token",
              "type_arguments": [
                "0xe1b45a0e641b9955a20aa0ad1c1f4ad86aad8afb07296d4085e349a50e90bdca::blue::BLUE"
              ],
              "arguments": [
                {
                  "Input": 0
                },
                {
                  "Input": 1
                },
                {
                  "Input": 2
                },
                {
                  "Input": 3
                },
                {
                  "Input": 4
                },
                {
                  "Input": 5
                },
                {
                  "Input": 6
                },
                {
                  "Input": 7
                }
              ]
            }
          }
        ]
      },
      "sender": "0x0deaf2ae9d8e4877eb7bf5d86434488e343b6881bedff8fc78031b6d0df7c75a",
      "gasData": {
        "payment": [
          {
            "objectId": "0xd4300a22ed111e2748cbf37a9d8989a465fcc93d6d5e51c3b50a01c5947a68e0",
            "version": 773550345,
            "digest": "BxpVSNmeAvGuqentFfvWrMJpFrsfrD6bepjXiqBEMCTa"
          }
        ],
        "owner": "0x0deaf2ae9d8e4877eb7bf5d86434488e343b6881bedff8fc78031b6d0df7c75a",
        "price": "516",
        "budget": "20000000"
      }
    },
    "txSignatures": [
      "AFNikvjCvLQlzRLXkjjJakWmK//+xx9Nj8KYf7lZ5Qecue8V2mVUy7YvBdbI6F88x/SJrQsgBWGagdYZDb+RKQn2kJBg/LwnsKrg9YAOh6iaiahK8sMaI1lFOELfahaYKg=="
    ]
  },
  "effects": {
    "messageVersion": "v1",
    "status": {
      "status": "success"
    },
    "executedEpoch": "1029",
    "gasUsed": {
      "computationCost": "516000",
      "storageCost": "7227600",
      "storageRebate": "4175820",
      "nonRefundableStorageFee": "42180"
    },
    "modifiedAtVersions": [
      {
        "objectId": "0x684646dbd0b0c17ccff97904d59091766599fdbde56a542a29fe869af23bc94c",
        "sequenceNumber": "773550345"
      },
      {
        "objectId": "0x9409e01b8bafbad0b89e949bcfb8416be7f600f4b87df3bc4103e6f5d78cfb00",
        "sequenceNumber": "773550345"
      },
      {
        "objectId": "0xd4300a22ed111e2748cbf37a9d8989a465fcc93d6d5e51c3b50a01c5947a68e0",
        "sequenceNumber": "773550345"
      }
    ],
    "sharedObjects": [
      {
        "objectId": "0x9409e01b8bafbad0b89e949bcfb8416be7f600f4b87df3bc4103e6f5d78cfb00",
        "version": 773550345,
        "digest": "H4RTWvq3nD1Yhq3MS4A2YbeyenuDTkTNBeSXVc2L5RbZ"
      },
      {
        "objectId": "0x0000000000000000000000000000000000000000000000000000000000000006",
        "version": 717892233,
        "digest": "5tbEFVgP1T4nDrrqvm6W5kaTDfHECqfSRc9p5xMbzQVw"
      }
    ],
    "transactionDigest": "6C8iFMzoEVAQEReDW3HgMWcvVsRrw4SLq6wB34bWGUTB",
    "created": [
      {
        "owner": {
          "ObjectOwner": "0x9409e01b8bafbad0b89e949bcfb8416be7f600f4b87df3bc4103e6f5d78cfb00"
        },
        "reference": {
          "objectId": "0xe9d2847f2888a0e36a9105c73dee04be0c93915acf1296f07a4241d26e8b0e2e",
          "version": 773550346,
          "digest": "ArmLVjYfeGtmeodVW92cv9tcxjwPNYG7DUy1SBssDwkg"
        }
      }
    ],
    "mutated": [
      {
        "owner": {
          "AddressOwner": "0x0deaf2ae9d8e4877eb7bf5d86434488e343b6881bedff8fc78031b6d0df7c75a"
        },
        "reference": {
          "objectId": "0x684646dbd0b0c17ccff97904d59091766599fdbde56a542a29fe869af23bc94c",
          "version": 773550346,
          "digest": "CHvuRDcQgyBMLSKt79fXDreLQzW474JavHBFxmkH1u88"
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
          "version": 773550346,
          "digest": "443TNdV2xTe2SSrmgyT1dc4bkc8QaE5X3Fy6bqewJt2h"
        }
      },
      {
        "owner": {
          "AddressOwner": "0x0deaf2ae9d8e4877eb7bf5d86434488e343b6881bedff8fc78031b6d0df7c75a"
        },
        "reference": {
          "objectId": "0xd4300a22ed111e2748cbf37a9d8989a465fcc93d6d5e51c3b50a01c5947a68e0",
          "version": 773550346,
          "digest": "7utQy1RsEX88BQTUXQqCVPVUY2tkGpPRxYAopwXDBcoe"
        }
      }
    ],
    "gasObject": {
      "owner": {
        "AddressOwner": "0x0deaf2ae9d8e4877eb7bf5d86434488e343b6881bedff8fc78031b6d0df7c75a"
      },
      "reference": {
        "objectId": "0xd4300a22ed111e2748cbf37a9d8989a465fcc93d6d5e51c3b50a01c5947a68e0",
        "version": 773550346,
        "digest": "7utQy1RsEX88BQTUXQqCVPVUY2tkGpPRxYAopwXDBcoe"
      }
    },
    "eventsDigest": "8ChcMB2SikLA3AFxuGHT7Db2j76442UTiewNpCFiAdQ7",
    "dependencies": [
      "4WjLDjRMzKjF7aSDCqdnyHkxC5hDorba2aoA75ZeCAZn",
      "5fjznGPizPHDtfa8Tf7p1uiGSssoLBYWfrnMtstd2pUQ",
      "9tJFsfsE1xYR1QKfyXRnxgVhpdNTfNj5ZPVZ5rb2Ju2X",
      "EGcNGjGp4wZdt2aAZhPgQnJ6WtSatXxmvTF4Bo5bGhoW"
    ]
  },
  "events": [
    {
      "id": {
        "txDigest": "6C8iFMzoEVAQEReDW3HgMWcvVsRrw4SLq6wB34bWGUTB",
        "eventSeq": "0"
      },
      "packageId": "0x035cf7b699be1d67785cc54dabc83e497fae23516c0329bea39faabf3384f702",
      "transactionModule": "crowd_walrus",
      "sender": "0x0deaf2ae9d8e4877eb7bf5d86434488e343b6881bedff8fc78031b6d0df7c75a",
      "type": "0x035cf7b699be1d67785cc54dabc83e497fae23516c0329bea39faabf3384f702::token_registry::TokenAdded",
      "parsedJson": {
        "coin_type": "e1b45a0e641b9955a20aa0ad1c1f4ad86aad8afb07296d4085e349a50e90bdca::blue::BLUE",
        "decimals": 9,
        "enabled": false,
        "max_age_ms": "300000",
        "name": "Bluefin",
        "pyth_feed_id": [
          4,
          207,
          235,
          123,
          20,
          62,
          185,
          196,
          142,
          155,
          7,
          65,
          37,
          193,
          163,
          68,
          123,
          133,
          245,
          156,
          49,
          22,
          77,
          194,
          12,
          27,
          234,
          166,
          242,
          31,
          43,
          107
        ],
        "symbol": "BLUE",
        "timestamp_ms": "1770304407389"
      },
      "bcsEncoding": "base64",
      "bcs": "TGUxYjQ1YTBlNjQxYjk5NTVhMjBhYTBhZDFjMWY0YWQ4NmFhZDhhZmIwNzI5NmQ0MDg1ZTM0OWE1MGU5MGJkY2E6OmJsdWU6OkJMVUUEQkxVRQdCbHVlZmluCSAEz+t7FD65xI6bB0ElwaNEe4X1nDEWTcIMG+qm8h8ra+CTBAAAAAAAAF2HXS6cAQAA"
    }
  ],
  "timestampMs": "1770304407389",
  "confirmedLocalExecution": true,
  "checkpoint": "241927057",
  "errors": [
    "Cannot retrieve balance changes: Could not find the referenced object 0x684646dbd0b0c17ccff97904d59091766599fdbde56a542a29fe869af23bc94c as the asked version SequenceNumber(773550346) is higher than the latest SequenceNumber(773550345)",
    "Cannot retrieve object changes: Could not find the referenced object 0x684646dbd0b0c17ccff97904d59091766599fdbde56a542a29fe869af23bc94c as the asked version SequenceNumber(773550346) is higher than the latest SequenceNumber(773550345)"
  ]
}
```


## BLUE token enable

Path: `/tmp/mainnet_enable_token_blue.json`

```json
{
  "digest": "DDjn5bjjhSAPfLWVyqYr6QXy3kohcHY66eHNRt1WUsu1",
  "transaction": {
    "data": {
      "messageVersion": "v1",
      "transaction": {
        "kind": "ProgrammableTransaction",
        "inputs": [
          {
            "type": "object",
            "objectType": "sharedObject",
            "objectId": "0x9409e01b8bafbad0b89e949bcfb8416be7f600f4b87df3bc4103e6f5d78cfb00",
            "initialSharedVersion": "773550337",
            "mutable": true
          },
          {
            "type": "object",
            "objectType": "immOrOwnedObject",
            "objectId": "0x684646dbd0b0c17ccff97904d59091766599fdbde56a542a29fe869af23bc94c",
            "version": "773550346",
            "digest": "CHvuRDcQgyBMLSKt79fXDreLQzW474JavHBFxmkH1u88"
          },
          {
            "type": "pure",
            "valueType": "bool",
            "value": true
          },
          {
            "type": "object",
            "objectType": "sharedObject",
            "objectId": "0x0000000000000000000000000000000000000000000000000000000000000006",
            "initialSharedVersion": "1",
            "mutable": false
          }
        ],
        "transactions": [
          {
            "MoveCall": {
              "package": "0x035cf7b699be1d67785cc54dabc83e497fae23516c0329bea39faabf3384f702",
              "module": "crowd_walrus",
              "function": "set_token_enabled",
              "type_arguments": [
                "0xe1b45a0e641b9955a20aa0ad1c1f4ad86aad8afb07296d4085e349a50e90bdca::blue::BLUE"
              ],
              "arguments": [
                {
                  "Input": 0
                },
                {
                  "Input": 1
                },
                {
                  "Input": 2
                },
                {
                  "Input": 3
                }
              ]
            }
          }
        ]
      },
      "sender": "0x0deaf2ae9d8e4877eb7bf5d86434488e343b6881bedff8fc78031b6d0df7c75a",
      "gasData": {
        "payment": [
          {
            "objectId": "0xd4300a22ed111e2748cbf37a9d8989a465fcc93d6d5e51c3b50a01c5947a68e0",
            "version": 773550346,
            "digest": "7utQy1RsEX88BQTUXQqCVPVUY2tkGpPRxYAopwXDBcoe"
          }
        ],
        "owner": "0x0deaf2ae9d8e4877eb7bf5d86434488e343b6881bedff8fc78031b6d0df7c75a",
        "price": "516",
        "budget": "10000000"
      }
    },
    "txSignatures": [
      "ADwDtR9nSS8fPljhTQWr5mEu6LExFM8GVGXr4tZfO3aPrWBTfyutUJ66eTjFNOWTDhwuF0LyyvEds/pF0Ly1bQr2kJBg/LwnsKrg9YAOh6iaiahK8sMaI1lFOELfahaYKg=="
    ]
  },
  "effects": {
    "messageVersion": "v1",
    "status": {
      "status": "success"
    },
    "executedEpoch": "1029",
    "gasUsed": {
      "computationCost": "516000",
      "storageCost": "7227600",
      "storageRebate": "7155324",
      "nonRefundableStorageFee": "72276"
    },
    "modifiedAtVersions": [
      {
        "objectId": "0x684646dbd0b0c17ccff97904d59091766599fdbde56a542a29fe869af23bc94c",
        "sequenceNumber": "773550346"
      },
      {
        "objectId": "0x9409e01b8bafbad0b89e949bcfb8416be7f600f4b87df3bc4103e6f5d78cfb00",
        "sequenceNumber": "773550346"
      },
      {
        "objectId": "0xd4300a22ed111e2748cbf37a9d8989a465fcc93d6d5e51c3b50a01c5947a68e0",
        "sequenceNumber": "773550346"
      },
      {
        "objectId": "0xe9d2847f2888a0e36a9105c73dee04be0c93915acf1296f07a4241d26e8b0e2e",
        "sequenceNumber": "773550346"
      }
    ],
    "sharedObjects": [
      {
        "objectId": "0x9409e01b8bafbad0b89e949bcfb8416be7f600f4b87df3bc4103e6f5d78cfb00",
        "version": 773550346,
        "digest": "443TNdV2xTe2SSrmgyT1dc4bkc8QaE5X3Fy6bqewJt2h"
      },
      {
        "objectId": "0x0000000000000000000000000000000000000000000000000000000000000006",
        "version": 717895884,
        "digest": "EYnyEqWHmTMGSyFGPEgEcebrgUZUzuxEBTNNriishbdH"
      }
    ],
    "transactionDigest": "DDjn5bjjhSAPfLWVyqYr6QXy3kohcHY66eHNRt1WUsu1",
    "mutated": [
      {
        "owner": {
          "AddressOwner": "0x0deaf2ae9d8e4877eb7bf5d86434488e343b6881bedff8fc78031b6d0df7c75a"
        },
        "reference": {
          "objectId": "0x684646dbd0b0c17ccff97904d59091766599fdbde56a542a29fe869af23bc94c",
          "version": 773550347,
          "digest": "eNKcyT1F9wHeM3gbmD5ZxcqJvEP8xpQdqfMiFjpo7PG"
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
          "version": 773550347,
          "digest": "FhGGoSbqVAhZUWf9w4AvukUW3JYMdpqeXTbrJQWFPm7W"
        }
      },
      {
        "owner": {
          "AddressOwner": "0x0deaf2ae9d8e4877eb7bf5d86434488e343b6881bedff8fc78031b6d0df7c75a"
        },
        "reference": {
          "objectId": "0xd4300a22ed111e2748cbf37a9d8989a465fcc93d6d5e51c3b50a01c5947a68e0",
          "version": 773550347,
          "digest": "ECJqbxDuYWXxia6tkx2Ff1tpeXKxz4xgi2mz1qa52YqU"
        }
      },
      {
        "owner": {
          "ObjectOwner": "0x9409e01b8bafbad0b89e949bcfb8416be7f600f4b87df3bc4103e6f5d78cfb00"
        },
        "reference": {
          "objectId": "0xe9d2847f2888a0e36a9105c73dee04be0c93915acf1296f07a4241d26e8b0e2e",
          "version": 773550347,
          "digest": "GN1XUrQ7DhvPhu5wtCfuvpyUmNkYQGUitRa5siC1k3TP"
        }
      }
    ],
    "gasObject": {
      "owner": {
        "AddressOwner": "0x0deaf2ae9d8e4877eb7bf5d86434488e343b6881bedff8fc78031b6d0df7c75a"
      },
      "reference": {
        "objectId": "0xd4300a22ed111e2748cbf37a9d8989a465fcc93d6d5e51c3b50a01c5947a68e0",
        "version": 773550347,
        "digest": "ECJqbxDuYWXxia6tkx2Ff1tpeXKxz4xgi2mz1qa52YqU"
      }
    },
    "eventsDigest": "9FkQjAzhdtwLjQRv5w5yiADMVC72WKdXEJAsBTjNDSWn",
    "dependencies": [
      "6C8iFMzoEVAQEReDW3HgMWcvVsRrw4SLq6wB34bWGUTB",
      "95hUSnBsLm14jeSegcsDs1kjYxKDJRCZLSB9pjCurvqv",
      "9tJFsfsE1xYR1QKfyXRnxgVhpdNTfNj5ZPVZ5rb2Ju2X",
      "EGcNGjGp4wZdt2aAZhPgQnJ6WtSatXxmvTF4Bo5bGhoW"
    ]
  },
  "events": [
    {
      "id": {
        "txDigest": "DDjn5bjjhSAPfLWVyqYr6QXy3kohcHY66eHNRt1WUsu1",
        "eventSeq": "0"
      },
      "packageId": "0x035cf7b699be1d67785cc54dabc83e497fae23516c0329bea39faabf3384f702",
      "transactionModule": "crowd_walrus",
      "sender": "0x0deaf2ae9d8e4877eb7bf5d86434488e343b6881bedff8fc78031b6d0df7c75a",
      "type": "0x035cf7b699be1d67785cc54dabc83e497fae23516c0329bea39faabf3384f702::token_registry::TokenEnabled",
      "parsedJson": {
        "coin_type": "e1b45a0e641b9955a20aa0ad1c1f4ad86aad8afb07296d4085e349a50e90bdca::blue::BLUE",
        "symbol": "BLUE",
        "timestamp_ms": "1770304784821"
      },
      "bcsEncoding": "base64",
      "bcs": "TGUxYjQ1YTBlNjQxYjk5NTVhMjBhYTBhZDFjMWY0YWQ4NmFhZDhhZmIwNzI5NmQ0MDg1ZTM0OWE1MGU5MGJkY2E6OmJsdWU6OkJMVUUEQkxVRbVJYy6cAQAA"
    }
  ],
  "timestampMs": "1770304784821",
  "confirmedLocalExecution": true,
  "checkpoint": "241928482",
  "errors": [
    "Cannot retrieve balance changes: Could not find the referenced object 0x684646dbd0b0c17ccff97904d59091766599fdbde56a542a29fe869af23bc94c as the asked version SequenceNumber(773550347) is higher than the latest SequenceNumber(773550346)",
    "Cannot retrieve object changes: Could not find the referenced object 0x684646dbd0b0c17ccff97904d59091766599fdbde56a542a29fe869af23bc94c as the asked version SequenceNumber(773550347) is higher than the latest SequenceNumber(773550346)"
  ]
}
```


## Badge config update

Path: `/tmp/mainnet_update_badge_config.json`

```json
{
  "digest": "CjP4JQv9GN4So2frTH85MAiikQothYzGz6UsSAoGaKp",
  "transaction": {
    "data": {
      "messageVersion": "v1",
      "transaction": {
        "kind": "ProgrammableTransaction",
        "inputs": [
          {
            "type": "object",
            "objectType": "sharedObject",
            "objectId": "0xdbbc3ed362df0a25b68d62bdcb237c8ea7eb2c109228de69a575dd15a77de43e",
            "initialSharedVersion": "773550337",
            "mutable": true
          },
          {
            "type": "object",
            "objectType": "immOrOwnedObject",
            "objectId": "0x684646dbd0b0c17ccff97904d59091766599fdbde56a542a29fe869af23bc94c",
            "version": "773550347",
            "digest": "eNKcyT1F9wHeM3gbmD5ZxcqJvEP8xpQdqfMiFjpo7PG"
          },
          {
            "type": "pure",
            "valueType": "vector<u64>",
            "value": [
              "10000000",
              "150000000",
              "400000000",
              "900000000",
              "1800000000"
            ]
          },
          {
            "type": "pure",
            "valueType": "vector<u64>",
            "value": [
              "1",
              "2",
              "4",
              "8",
              "15"
            ]
          },
          {
            "type": "pure",
            "valueType": "vector<0x1::string::String>",
            "value": [
              "https://aggregator.walrus-mainnet.walrus.space/v1/blobs/by-quilt-patch-id/BiFXQRMI4aR1nJwo-0VpMKjz9YJURDKll8XGOU1xQY8BAQBHAA",
              "https://aggregator.walrus-mainnet.walrus.space/v1/blobs/by-quilt-patch-id/BiFXQRMI4aR1nJwo-0VpMKjz9YJURDKll8XGOU1xQY8BRwCgAA",
              "https://aggregator.walrus-mainnet.walrus.space/v1/blobs/by-quilt-patch-id/BiFXQRMI4aR1nJwo-0VpMKjz9YJURDKll8XGOU1xQY8BoAAFAQ",
              "https://aggregator.walrus-mainnet.walrus.space/v1/blobs/by-quilt-patch-id/BiFXQRMI4aR1nJwo-0VpMKjz9YJURDKll8XGOU1xQY8BBQFyAQ",
              "https://aggregator.walrus-mainnet.walrus.space/v1/blobs/by-quilt-patch-id/BiFXQRMI4aR1nJwo-0VpMKjz9YJURDKll8XGOU1xQY8BcgEnAg"
            ]
          },
          {
            "type": "object",
            "objectType": "sharedObject",
            "objectId": "0x0000000000000000000000000000000000000000000000000000000000000006",
            "initialSharedVersion": "1",
            "mutable": false
          }
        ],
        "transactions": [
          {
            "MoveCall": {
              "package": "0x035cf7b699be1d67785cc54dabc83e497fae23516c0329bea39faabf3384f702",
              "module": "crowd_walrus",
              "function": "update_badge_config",
              "arguments": [
                {
                  "Input": 0
                },
                {
                  "Input": 1
                },
                {
                  "Input": 2
                },
                {
                  "Input": 3
                },
                {
                  "Input": 4
                },
                {
                  "Input": 5
                }
              ]
            }
          }
        ]
      },
      "sender": "0x0deaf2ae9d8e4877eb7bf5d86434488e343b6881bedff8fc78031b6d0df7c75a",
      "gasData": {
        "payment": [
          {
            "objectId": "0xd4300a22ed111e2748cbf37a9d8989a465fcc93d6d5e51c3b50a01c5947a68e0",
            "version": 773550347,
            "digest": "ECJqbxDuYWXxia6tkx2Ff1tpeXKxz4xgi2mz1qa52YqU"
          }
        ],
        "owner": "0x0deaf2ae9d8e4877eb7bf5d86434488e343b6881bedff8fc78031b6d0df7c75a",
        "price": "516",
        "budget": "25000000"
      }
    },
    "txSignatures": [
      "ACeTFjxN5w11LTlqz2Q68y35oMNhLa8DQqNnBh5iYxExYxLymJKWmlCQ9U2N+n4B2+j1kD6CzfvHOgQ8/BfxLQD2kJBg/LwnsKrg9YAOh6iaiahK8sMaI1lFOELfahaYKg=="
    ]
  },
  "effects": {
    "messageVersion": "v1",
    "status": {
      "status": "success"
    },
    "executedEpoch": "1029",
    "gasUsed": {
      "computationCost": "516000",
      "storageCost": "9576000",
      "storageRebate": "4175820",
      "nonRefundableStorageFee": "42180"
    },
    "modifiedAtVersions": [
      {
        "objectId": "0x684646dbd0b0c17ccff97904d59091766599fdbde56a542a29fe869af23bc94c",
        "sequenceNumber": "773550347"
      },
      {
        "objectId": "0xd4300a22ed111e2748cbf37a9d8989a465fcc93d6d5e51c3b50a01c5947a68e0",
        "sequenceNumber": "773550347"
      },
      {
        "objectId": "0xdbbc3ed362df0a25b68d62bdcb237c8ea7eb2c109228de69a575dd15a77de43e",
        "sequenceNumber": "773550337"
      }
    ],
    "sharedObjects": [
      {
        "objectId": "0xdbbc3ed362df0a25b68d62bdcb237c8ea7eb2c109228de69a575dd15a77de43e",
        "version": 773550337,
        "digest": "5yssi6qK6JodGjd8dvPKxMptx6vgMF2UUPqNcgJnmH88"
      },
      {
        "objectId": "0x0000000000000000000000000000000000000000000000000000000000000006",
        "version": 717898627,
        "digest": "EV6JABoRpLwHkQWbEH82ecrnyN2Sx6zQPJJkvJSkzmpg"
      }
    ],
    "transactionDigest": "CjP4JQv9GN4So2frTH85MAiikQothYzGz6UsSAoGaKp",
    "mutated": [
      {
        "owner": {
          "AddressOwner": "0x0deaf2ae9d8e4877eb7bf5d86434488e343b6881bedff8fc78031b6d0df7c75a"
        },
        "reference": {
          "objectId": "0x684646dbd0b0c17ccff97904d59091766599fdbde56a542a29fe869af23bc94c",
          "version": 773550348,
          "digest": "49q5gLuhxdDsHoVRxuaCDPRX4XRGdwQiyiPM7yJdMvNy"
        }
      },
      {
        "owner": {
          "AddressOwner": "0x0deaf2ae9d8e4877eb7bf5d86434488e343b6881bedff8fc78031b6d0df7c75a"
        },
        "reference": {
          "objectId": "0xd4300a22ed111e2748cbf37a9d8989a465fcc93d6d5e51c3b50a01c5947a68e0",
          "version": 773550348,
          "digest": "6ALzVhf17QJMbVgpjbsbrwiBAT3beAPHhr7w5bNh6a2h"
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
          "version": 773550348,
          "digest": "otnVwg4h4s6KpvuhUKLJxbWeuDQG8eZgr4RF4TuBYt3"
        }
      }
    ],
    "gasObject": {
      "owner": {
        "AddressOwner": "0x0deaf2ae9d8e4877eb7bf5d86434488e343b6881bedff8fc78031b6d0df7c75a"
      },
      "reference": {
        "objectId": "0xd4300a22ed111e2748cbf37a9d8989a465fcc93d6d5e51c3b50a01c5947a68e0",
        "version": 773550348,
        "digest": "6ALzVhf17QJMbVgpjbsbrwiBAT3beAPHhr7w5bNh6a2h"
      }
    },
    "eventsDigest": "AUkN1ejg8zgqBExaTTjwho6ajSVuG3J54ULAgxe7a9E2",
    "dependencies": [
      "9pGHuoWgEdnptMPxnoevy1GmrLVssrC3YwZ5Xzyh5Ydp",
      "9tJFsfsE1xYR1QKfyXRnxgVhpdNTfNj5ZPVZ5rb2Ju2X",
      "DDjn5bjjhSAPfLWVyqYr6QXy3kohcHY66eHNRt1WUsu1"
    ]
  },
  "events": [
    {
      "id": {
        "txDigest": "CjP4JQv9GN4So2frTH85MAiikQothYzGz6UsSAoGaKp",
        "eventSeq": "0"
      },
      "packageId": "0x035cf7b699be1d67785cc54dabc83e497fae23516c0329bea39faabf3384f702",
      "transactionModule": "crowd_walrus",
      "sender": "0x0deaf2ae9d8e4877eb7bf5d86434488e343b6881bedff8fc78031b6d0df7c75a",
      "type": "0x035cf7b699be1d67785cc54dabc83e497fae23516c0329bea39faabf3384f702::badge_rewards::BadgeConfigUpdated",
      "parsedJson": {
        "amount_thresholds_micro": [
          "10000000",
          "150000000",
          "400000000",
          "900000000",
          "1800000000"
        ],
        "image_uris": [
          "https://aggregator.walrus-mainnet.walrus.space/v1/blobs/by-quilt-patch-id/BiFXQRMI4aR1nJwo-0VpMKjz9YJURDKll8XGOU1xQY8BAQBHAA",
          "https://aggregator.walrus-mainnet.walrus.space/v1/blobs/by-quilt-patch-id/BiFXQRMI4aR1nJwo-0VpMKjz9YJURDKll8XGOU1xQY8BRwCgAA",
          "https://aggregator.walrus-mainnet.walrus.space/v1/blobs/by-quilt-patch-id/BiFXQRMI4aR1nJwo-0VpMKjz9YJURDKll8XGOU1xQY8BoAAFAQ",
          "https://aggregator.walrus-mainnet.walrus.space/v1/blobs/by-quilt-patch-id/BiFXQRMI4aR1nJwo-0VpMKjz9YJURDKll8XGOU1xQY8BBQFyAQ",
          "https://aggregator.walrus-mainnet.walrus.space/v1/blobs/by-quilt-patch-id/BiFXQRMI4aR1nJwo-0VpMKjz9YJURDKll8XGOU1xQY8BcgEnAg"
        ],
        "payment_thresholds": [
          "1",
          "2",
          "4",
          "8",
          "15"
        ],
        "timestamp_ms": "1770305125467"
      },
      "bcsEncoding": "base64",
      "bcs": "BYCWmAAAAAAAgNHwCAAAAAAAhNcXAAAAAADppDUAAAAAANJJawAAAAAFAQAAAAAAAAACAAAAAAAAAAQAAAAAAAAACAAAAAAAAAAPAAAAAAAAAAV8aHR0cHM6Ly9hZ2dyZWdhdG9yLndhbHJ1cy1tYWlubmV0LndhbHJ1cy5zcGFjZS92MS9ibG9icy9ieS1xdWlsdC1wYXRjaC1pZC9CaUZYUVJNSTRhUjFuSndvLTBWcE1Lano5WUpVUkRLbGw4WEdPVTF4UVk4QkFRQkhBQXxodHRwczovL2FnZ3JlZ2F0b3Iud2FscnVzLW1haW5uZXQud2FscnVzLnNwYWNlL3YxL2Jsb2JzL2J5LXF1aWx0LXBhdGNoLWlkL0JpRlhRUk1JNGFSMW5Kd28tMFZwTUtqejlZSlVSREtsbDhYR09VMXhRWThCUndDZ0FBfGh0dHBzOi8vYWdncmVnYXRvci53YWxydXMtbWFpbm5ldC53YWxydXMuc3BhY2UvdjEvYmxvYnMvYnktcXVpbHQtcGF0Y2gtaWQvQmlGWFFSTUk0YVIxbkp3by0wVnBNS2p6OVlKVVJES2xsOFhHT1UxeFFZOEJvQUFGQVF8aHR0cHM6Ly9hZ2dyZWdhdG9yLndhbHJ1cy1tYWlubmV0LndhbHJ1cy5zcGFjZS92MS9ibG9icy9ieS1xdWlsdC1wYXRjaC1pZC9CaUZYUVJNSTRhUjFuSndvLTBWcE1Lano5WUpVUkRLbGw4WEdPVTF4UVk4QkJRRnlBUXxodHRwczovL2FnZ3JlZ2F0b3Iud2FscnVzLW1haW5uZXQud2FscnVzLnNwYWNlL3YxL2Jsb2JzL2J5LXF1aWx0LXBhdGNoLWlkL0JpRlhRUk1JNGFSMW5Kd28tMFZwTUtqejlZSlVSREtsbDhYR09VMXhRWThCY2dFbkFnW3xoLpwBAAA="
    }
  ],
  "timestampMs": "1770305125612",
  "confirmedLocalExecution": true,
  "checkpoint": "241929723",
  "errors": [
    "Cannot retrieve balance changes: Could not find the referenced object 0x684646dbd0b0c17ccff97904d59091766599fdbde56a542a29fe869af23bc94c as the asked version SequenceNumber(773550348) is higher than the latest SequenceNumber(773550347)",
    "Cannot retrieve object changes: Could not find the referenced object 0x684646dbd0b0c17ccff97904d59091766599fdbde56a542a29fe869af23bc94c as the asked version SequenceNumber(773550348) is higher than the latest SequenceNumber(773550347)"
  ]
}
```


## Policy update: standard

Path: `/tmp/mainnet_update_policy_standard.json`

```json
{
  "digest": "D2L3nN5rHNTRQG4GXtRgpSmHStLXdBSw3wLjJEHxrmR3",
  "transaction": {
    "data": {
      "messageVersion": "v1",
      "transaction": {
        "kind": "ProgrammableTransaction",
        "inputs": [
          {
            "type": "object",
            "objectType": "sharedObject",
            "objectId": "0xb9478cb0359b4a9a6a86b4e9ca2f6a171b7b6405f8ffada12b1f45d68077897c",
            "initialSharedVersion": "773550337",
            "mutable": true
          },
          {
            "type": "object",
            "objectType": "immOrOwnedObject",
            "objectId": "0x684646dbd0b0c17ccff97904d59091766599fdbde56a542a29fe869af23bc94c",
            "version": "773550348",
            "digest": "49q5gLuhxdDsHoVRxuaCDPRX4XRGdwQiyiPM7yJdMvNy"
          },
          {
            "type": "pure",
            "valueType": "0x1::string::String",
            "value": "standard"
          },
          {
            "type": "pure",
            "valueType": "u16",
            "value": 0
          },
          {
            "type": "pure",
            "valueType": "address",
            "value": "0xa0cd94d73e0df4e76010e3f2232435839cc619190826508a2540eea768192c1d"
          },
          {
            "type": "object",
            "objectType": "sharedObject",
            "objectId": "0x0000000000000000000000000000000000000000000000000000000000000006",
            "initialSharedVersion": "1",
            "mutable": false
          }
        ],
        "transactions": [
          {
            "MoveCall": {
              "package": "0x035cf7b699be1d67785cc54dabc83e497fae23516c0329bea39faabf3384f702",
              "module": "crowd_walrus",
              "function": "update_platform_policy",
              "arguments": [
                {
                  "Input": 0
                },
                {
                  "Input": 1
                },
                {
                  "Input": 2
                },
                {
                  "Input": 3
                },
                {
                  "Input": 4
                },
                {
                  "Input": 5
                }
              ]
            }
          }
        ]
      },
      "sender": "0x0deaf2ae9d8e4877eb7bf5d86434488e343b6881bedff8fc78031b6d0df7c75a",
      "gasData": {
        "payment": [
          {
            "objectId": "0xd4300a22ed111e2748cbf37a9d8989a465fcc93d6d5e51c3b50a01c5947a68e0",
            "version": 773550348,
            "digest": "6ALzVhf17QJMbVgpjbsbrwiBAT3beAPHhr7w5bNh6a2h"
          }
        ],
        "owner": "0x0deaf2ae9d8e4877eb7bf5d86434488e343b6881bedff8fc78031b6d0df7c75a",
        "price": "516",
        "budget": "15000000"
      }
    },
    "txSignatures": [
      "ADrV+H6IIj0iD5THJDzeieFpQiz0JC+NzNpY3nyjySiLYcjgQuIseGGAL4Ag6ApCRTedJj6AWNCm4xZNe6p8vAj2kJBg/LwnsKrg9YAOh6iaiahK8sMaI1lFOELfahaYKg=="
    ]
  },
  "effects": {
    "messageVersion": "v1",
    "status": {
      "status": "success"
    },
    "executedEpoch": "1029",
    "gasUsed": {
      "computationCost": "516000",
      "storageCost": "6999600",
      "storageRebate": "6929604",
      "nonRefundableStorageFee": "69996"
    },
    "modifiedAtVersions": [
      {
        "objectId": "0x1dd1fa6ffb4e68007880380cfc206daa80a2275f307d539b0be3a881b5a92799",
        "sequenceNumber": "773550337"
      },
      {
        "objectId": "0x684646dbd0b0c17ccff97904d59091766599fdbde56a542a29fe869af23bc94c",
        "sequenceNumber": "773550348"
      },
      {
        "objectId": "0xb9478cb0359b4a9a6a86b4e9ca2f6a171b7b6405f8ffada12b1f45d68077897c",
        "sequenceNumber": "773550337"
      },
      {
        "objectId": "0xd4300a22ed111e2748cbf37a9d8989a465fcc93d6d5e51c3b50a01c5947a68e0",
        "sequenceNumber": "773550348"
      }
    ],
    "sharedObjects": [
      {
        "objectId": "0xb9478cb0359b4a9a6a86b4e9ca2f6a171b7b6405f8ffada12b1f45d68077897c",
        "version": 773550337,
        "digest": "9G31ZzBqVmmB8iaRBD9tpz8z6aMrtH3bQnoY7cQW7Y2d"
      },
      {
        "objectId": "0x0000000000000000000000000000000000000000000000000000000000000006",
        "version": 717901238,
        "digest": "6R6YqFc9yAPm7L7YWgTr5GC7smyCVnfigLHAAsiSqbHr"
      }
    ],
    "transactionDigest": "D2L3nN5rHNTRQG4GXtRgpSmHStLXdBSw3wLjJEHxrmR3",
    "mutated": [
      {
        "owner": {
          "ObjectOwner": "0x79767ca44deef0c4ecd5f761df162b4b74e69732678fd46cd69fab0167785cbf"
        },
        "reference": {
          "objectId": "0x1dd1fa6ffb4e68007880380cfc206daa80a2275f307d539b0be3a881b5a92799",
          "version": 773550349,
          "digest": "BnvwRDsXVCPNm3AxVuSwbmQnCmRaiQr6EHdYWdCsXzmi"
        }
      },
      {
        "owner": {
          "AddressOwner": "0x0deaf2ae9d8e4877eb7bf5d86434488e343b6881bedff8fc78031b6d0df7c75a"
        },
        "reference": {
          "objectId": "0x684646dbd0b0c17ccff97904d59091766599fdbde56a542a29fe869af23bc94c",
          "version": 773550349,
          "digest": "2HwtRTEiVwdMfy51sUETCJeM6ASL4sYekaA3dLa2hgEt"
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
          "version": 773550349,
          "digest": "12FttJqDqCuWNxEJdA2NuU4Qg6ubSepQK4BvrDLWJyQ4"
        }
      },
      {
        "owner": {
          "AddressOwner": "0x0deaf2ae9d8e4877eb7bf5d86434488e343b6881bedff8fc78031b6d0df7c75a"
        },
        "reference": {
          "objectId": "0xd4300a22ed111e2748cbf37a9d8989a465fcc93d6d5e51c3b50a01c5947a68e0",
          "version": 773550349,
          "digest": "Maq9UMxkQc9Ux4RVTQrmCVVH9oVJ3RYLZuta7w6AFVJ"
        }
      }
    ],
    "gasObject": {
      "owner": {
        "AddressOwner": "0x0deaf2ae9d8e4877eb7bf5d86434488e343b6881bedff8fc78031b6d0df7c75a"
      },
      "reference": {
        "objectId": "0xd4300a22ed111e2748cbf37a9d8989a465fcc93d6d5e51c3b50a01c5947a68e0",
        "version": 773550349,
        "digest": "Maq9UMxkQc9Ux4RVTQrmCVVH9oVJ3RYLZuta7w6AFVJ"
      }
    },
    "eventsDigest": "CR29niS1F5scGkdxmkHNBgsEnFfjYZQvGUMx759ZtD7e",
    "dependencies": [
      "9iMVLA6fjdW3u6UrhdPhUkyzNzjrk1gBmaB1uVTgKSR",
      "CjP4JQv9GN4So2frTH85MAiikQothYzGz6UsSAoGaKp",
      "9tJFsfsE1xYR1QKfyXRnxgVhpdNTfNj5ZPVZ5rb2Ju2X"
    ]
  },
  "events": [
    {
      "id": {
        "txDigest": "D2L3nN5rHNTRQG4GXtRgpSmHStLXdBSw3wLjJEHxrmR3",
        "eventSeq": "0"
      },
      "packageId": "0x035cf7b699be1d67785cc54dabc83e497fae23516c0329bea39faabf3384f702",
      "transactionModule": "crowd_walrus",
      "sender": "0x0deaf2ae9d8e4877eb7bf5d86434488e343b6881bedff8fc78031b6d0df7c75a",
      "type": "0x035cf7b699be1d67785cc54dabc83e497fae23516c0329bea39faabf3384f702::platform_policy::PolicyUpdated",
      "parsedJson": {
        "enabled": true,
        "platform_address": "0xa0cd94d73e0df4e76010e3f2232435839cc619190826508a2540eea768192c1d",
        "platform_bps": 0,
        "policy_name": "standard",
        "timestamp_ms": "1770305442923"
      },
      "bcsEncoding": "base64",
      "bcs": "CHN0YW5kYXJkAACgzZTXPg3052AQ4/IjJDWDnMYZGQgmUIolQO6naBksHQFrVG0unAEAAA=="
    }
  ],
  "timestampMs": "1770305443031",
  "confirmedLocalExecution": true,
  "checkpoint": "241930898",
  "errors": [
    "Cannot retrieve balance changes: Could not find the referenced object 0x1dd1fa6ffb4e68007880380cfc206daa80a2275f307d539b0be3a881b5a92799 as the asked version SequenceNumber(773550349) is higher than the latest SequenceNumber(773550337)",
    "Cannot retrieve object changes: Could not find the referenced object 0x1dd1fa6ffb4e68007880380cfc206daa80a2275f307d539b0be3a881b5a92799 as the asked version SequenceNumber(773550349) is higher than the latest SequenceNumber(773550337)"
  ]
}
```


## Policy add: commercial

Path: `/tmp/mainnet_add_policy_commercial.json`

```json
{
  "digest": "G73CTSZ4MTZCsz2pNh3fQciumHN8jdsyJAjYxU6FpXcY",
  "transaction": {
    "data": {
      "messageVersion": "v1",
      "transaction": {
        "kind": "ProgrammableTransaction",
        "inputs": [
          {
            "type": "object",
            "objectType": "sharedObject",
            "objectId": "0xb9478cb0359b4a9a6a86b4e9ca2f6a171b7b6405f8ffada12b1f45d68077897c",
            "initialSharedVersion": "773550337",
            "mutable": true
          },
          {
            "type": "object",
            "objectType": "immOrOwnedObject",
            "objectId": "0x684646dbd0b0c17ccff97904d59091766599fdbde56a542a29fe869af23bc94c",
            "version": "773550349",
            "digest": "2HwtRTEiVwdMfy51sUETCJeM6ASL4sYekaA3dLa2hgEt"
          },
          {
            "type": "pure",
            "valueType": "0x1::string::String",
            "value": "commercial"
          },
          {
            "type": "pure",
            "valueType": "u16",
            "value": 500
          },
          {
            "type": "pure",
            "valueType": "address",
            "value": "0xa0cd94d73e0df4e76010e3f2232435839cc619190826508a2540eea768192c1d"
          },
          {
            "type": "object",
            "objectType": "sharedObject",
            "objectId": "0x0000000000000000000000000000000000000000000000000000000000000006",
            "initialSharedVersion": "1",
            "mutable": false
          }
        ],
        "transactions": [
          {
            "MoveCall": {
              "package": "0x035cf7b699be1d67785cc54dabc83e497fae23516c0329bea39faabf3384f702",
              "module": "crowd_walrus",
              "function": "add_platform_policy",
              "arguments": [
                {
                  "Input": 0
                },
                {
                  "Input": 1
                },
                {
                  "Input": 2
                },
                {
                  "Input": 3
                },
                {
                  "Input": 4
                },
                {
                  "Input": 5
                }
              ]
            }
          }
        ]
      },
      "sender": "0x0deaf2ae9d8e4877eb7bf5d86434488e343b6881bedff8fc78031b6d0df7c75a",
      "gasData": {
        "payment": [
          {
            "objectId": "0xd4300a22ed111e2748cbf37a9d8989a465fcc93d6d5e51c3b50a01c5947a68e0",
            "version": 773550349,
            "digest": "Maq9UMxkQc9Ux4RVTQrmCVVH9oVJ3RYLZuta7w6AFVJ"
          }
        ],
        "owner": "0x0deaf2ae9d8e4877eb7bf5d86434488e343b6881bedff8fc78031b6d0df7c75a",
        "price": "516",
        "budget": "15000000"
      }
    },
    "txSignatures": [
      "AJj1oFC2GB7vOKIN4saFGRb7QzLeocfsMsSd+3u3b8btGxndEX0YDfSoUp8gsqFJVN7jA1MqL8eMPY4FzJYT/gT2kJBg/LwnsKrg9YAOh6iaiahK8sMaI1lFOELfahaYKg=="
    ]
  },
  "effects": {
    "messageVersion": "v1",
    "status": {
      "status": "success"
    },
    "executedEpoch": "1029",
    "gasUsed": {
      "computationCost": "516000",
      "storageCost": "7014800",
      "storageRebate": "4491828",
      "nonRefundableStorageFee": "45372"
    },
    "modifiedAtVersions": [
      {
        "objectId": "0x684646dbd0b0c17ccff97904d59091766599fdbde56a542a29fe869af23bc94c",
        "sequenceNumber": "773550349"
      },
      {
        "objectId": "0xb9478cb0359b4a9a6a86b4e9ca2f6a171b7b6405f8ffada12b1f45d68077897c",
        "sequenceNumber": "773550349"
      },
      {
        "objectId": "0xd4300a22ed111e2748cbf37a9d8989a465fcc93d6d5e51c3b50a01c5947a68e0",
        "sequenceNumber": "773550349"
      }
    ],
    "sharedObjects": [
      {
        "objectId": "0xb9478cb0359b4a9a6a86b4e9ca2f6a171b7b6405f8ffada12b1f45d68077897c",
        "version": 773550349,
        "digest": "12FttJqDqCuWNxEJdA2NuU4Qg6ubSepQK4BvrDLWJyQ4"
      },
      {
        "objectId": "0x0000000000000000000000000000000000000000000000000000000000000006",
        "version": 717903376,
        "digest": "5ruNqcDzGz5WoP2h8LcXpQgjhS4m5cpsbvZ7FEGzakzN"
      }
    ],
    "transactionDigest": "G73CTSZ4MTZCsz2pNh3fQciumHN8jdsyJAjYxU6FpXcY",
    "created": [
      {
        "owner": {
          "ObjectOwner": "0x79767ca44deef0c4ecd5f761df162b4b74e69732678fd46cd69fab0167785cbf"
        },
        "reference": {
          "objectId": "0xaa6055cbaeb720ba5662dba9c66049d90be986500f7159d317b50f7b80a956fd",
          "version": 773550350,
          "digest": "GNKoPWDvPmgyHeAcjSA6jzfi7g7sKRHCWRcxWebtFd7e"
        }
      }
    ],
    "mutated": [
      {
        "owner": {
          "AddressOwner": "0x0deaf2ae9d8e4877eb7bf5d86434488e343b6881bedff8fc78031b6d0df7c75a"
        },
        "reference": {
          "objectId": "0x684646dbd0b0c17ccff97904d59091766599fdbde56a542a29fe869af23bc94c",
          "version": 773550350,
          "digest": "4nHDzcUpHYSZenCrvKymmz272jtKWY8cnA4kQpXLxJ2Q"
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
          "version": 773550350,
          "digest": "BF66Qq4fC6kXEGiqpr5wqR6UFx9YznMktjyEGRXaM2bP"
        }
      },
      {
        "owner": {
          "AddressOwner": "0x0deaf2ae9d8e4877eb7bf5d86434488e343b6881bedff8fc78031b6d0df7c75a"
        },
        "reference": {
          "objectId": "0xd4300a22ed111e2748cbf37a9d8989a465fcc93d6d5e51c3b50a01c5947a68e0",
          "version": 773550350,
          "digest": "HxY7UHwMxa125U22DNyXpPqdhqNbJV6Fbr3mGXu5oqHJ"
        }
      }
    ],
    "gasObject": {
      "owner": {
        "AddressOwner": "0x0deaf2ae9d8e4877eb7bf5d86434488e343b6881bedff8fc78031b6d0df7c75a"
      },
      "reference": {
        "objectId": "0xd4300a22ed111e2748cbf37a9d8989a465fcc93d6d5e51c3b50a01c5947a68e0",
        "version": 773550350,
        "digest": "HxY7UHwMxa125U22DNyXpPqdhqNbJV6Fbr3mGXu5oqHJ"
      }
    },
    "eventsDigest": "4eTPG3u3QaiH3CdrUpLfBjkhswXtzQzzawEaJMfH3sAp",
    "dependencies": [
      "2PJu3ark1AnY6E51eNaTnWBGSvMxZ8ZQeuijq7Ki5vyB",
      "9tJFsfsE1xYR1QKfyXRnxgVhpdNTfNj5ZPVZ5rb2Ju2X",
      "D2L3nN5rHNTRQG4GXtRgpSmHStLXdBSw3wLjJEHxrmR3"
    ]
  },
  "events": [
    {
      "id": {
        "txDigest": "G73CTSZ4MTZCsz2pNh3fQciumHN8jdsyJAjYxU6FpXcY",
        "eventSeq": "0"
      },
      "packageId": "0x035cf7b699be1d67785cc54dabc83e497fae23516c0329bea39faabf3384f702",
      "transactionModule": "crowd_walrus",
      "sender": "0x0deaf2ae9d8e4877eb7bf5d86434488e343b6881bedff8fc78031b6d0df7c75a",
      "type": "0x035cf7b699be1d67785cc54dabc83e497fae23516c0329bea39faabf3384f702::platform_policy::PolicyAdded",
      "parsedJson": {
        "enabled": true,
        "platform_address": "0xa0cd94d73e0df4e76010e3f2232435839cc619190826508a2540eea768192c1d",
        "platform_bps": 500,
        "policy_name": "commercial",
        "timestamp_ms": "1770305702026"
      },
      "bcsEncoding": "base64",
      "bcs": "CmNvbW1lcmNpYWz0AaDNlNc+DfTnYBDj8iMkNYOcxhkZCCZQiiVA7qdoGSwdAYpIcS6cAQAA"
    }
  ],
  "timestampMs": "1770305702026",
  "confirmedLocalExecution": true,
  "checkpoint": "241931846",
  "errors": [
    "Cannot retrieve balance changes: Could not find the referenced object 0x684646dbd0b0c17ccff97904d59091766599fdbde56a542a29fe869af23bc94c as the asked version SequenceNumber(773550350) is higher than the latest SequenceNumber(773550349)",
    "Cannot retrieve object changes: Could not find the referenced object 0x684646dbd0b0c17ccff97904d59091766599fdbde56a542a29fe869af23bc94c as the asked version SequenceNumber(773550350) is higher than the latest SequenceNumber(773550349)"
  ]
}
```


## Badge display setup

Path: `/tmp/mainnet_setup_badge_display.json`

```json
{
  "digest": "GkYdXGvqq4WzAWDUm4ohTLtU8ujvdQynguUyUPj1vmF3",
  "transaction": {
    "data": {
      "messageVersion": "v1",
      "transaction": {
        "kind": "ProgrammableTransaction",
        "inputs": [
          {
            "type": "object",
            "objectType": "immOrOwnedObject",
            "objectId": "0xc3b2a631c52092caa19fad982a1dba0531e4a1057f5aa5afa1bf5ebdc2fa6139",
            "version": "773550337",
            "digest": "F7fBszhYvvVm8EJuc4ydy1jt1R8uHCKhtDg3h2N2fR4v"
          }
        ],
        "transactions": [
          {
            "MoveCall": {
              "package": "0x035cf7b699be1d67785cc54dabc83e497fae23516c0329bea39faabf3384f702",
              "module": "badge_rewards",
              "function": "setup_badge_display",
              "arguments": [
                {
                  "Input": 0
                }
              ]
            }
          }
        ]
      },
      "sender": "0x0deaf2ae9d8e4877eb7bf5d86434488e343b6881bedff8fc78031b6d0df7c75a",
      "gasData": {
        "payment": [
          {
            "objectId": "0x98a43439d58f5ece303484f261f1e533ee92281f4094e1322b974ed756173577",
            "version": 773550338,
            "digest": "F4MANE7PMKQMujAC57Bq5wq4GWe1dLrYxPYFR3SrABxh"
          }
        ],
        "owner": "0x0deaf2ae9d8e4877eb7bf5d86434488e343b6881bedff8fc78031b6d0df7c75a",
        "price": "516",
        "budget": "15000000"
      }
    },
    "txSignatures": [
      "AH2XjjkS+dI0lozwFx1Gwywu81w97pLTY7ETauihWNELu3molFaXo+aWG0ZxvP24xpFuTArH/j0Fu2YE6Xa3ZQb2kJBg/LwnsKrg9YAOh6iaiahK8sMaI1lFOELfahaYKg=="
    ]
  },
  "effects": {
    "messageVersion": "v1",
    "status": {
      "status": "success"
    },
    "executedEpoch": "1029",
    "gasUsed": {
      "computationCost": "516000",
      "storageCost": "6232000",
      "storageRebate": "2866644",
      "nonRefundableStorageFee": "28956"
    },
    "modifiedAtVersions": [
      {
        "objectId": "0x98a43439d58f5ece303484f261f1e533ee92281f4094e1322b974ed756173577",
        "sequenceNumber": "773550338"
      },
      {
        "objectId": "0xc3b2a631c52092caa19fad982a1dba0531e4a1057f5aa5afa1bf5ebdc2fa6139",
        "sequenceNumber": "773550337"
      }
    ],
    "transactionDigest": "GkYdXGvqq4WzAWDUm4ohTLtU8ujvdQynguUyUPj1vmF3",
    "created": [
      {
        "owner": {
          "Shared": {
            "initial_shared_version": 773550339
          }
        },
        "reference": {
          "objectId": "0x7c4ccf431be3b7519884945563f0c7e9e02d6326c5af5c470892efe8588a6ccc",
          "version": 773550339,
          "digest": "FAEgbkPEVjaiYcusR32wjvCXb7RDccpdxjRDGtBphWC1"
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
          "version": 773550339,
          "digest": "655Lga8krBUS2cVpaUvPP8CRripXBxvxShNpCeyuMZZz"
        }
      },
      {
        "owner": {
          "AddressOwner": "0x0deaf2ae9d8e4877eb7bf5d86434488e343b6881bedff8fc78031b6d0df7c75a"
        },
        "reference": {
          "objectId": "0xc3b2a631c52092caa19fad982a1dba0531e4a1057f5aa5afa1bf5ebdc2fa6139",
          "version": 773550339,
          "digest": "BdZcGumCWLPQVZux5qQYFsqxTeGtuUioXWc51Y3SoPxv"
        }
      }
    ],
    "gasObject": {
      "owner": {
        "AddressOwner": "0x0deaf2ae9d8e4877eb7bf5d86434488e343b6881bedff8fc78031b6d0df7c75a"
      },
      "reference": {
        "objectId": "0x98a43439d58f5ece303484f261f1e533ee92281f4094e1322b974ed756173577",
        "version": 773550339,
        "digest": "655Lga8krBUS2cVpaUvPP8CRripXBxvxShNpCeyuMZZz"
      }
    },
    "eventsDigest": "66oEdm3tcgGoBYSHvgt6eDH1PLTsYhzDZHjGoNhSdq2a",
    "dependencies": [
      "Z4c3fuHFHUdNrowdqeLEHsPbrMF34t9WaRYi2EZnUgx",
      "9tJFsfsE1xYR1QKfyXRnxgVhpdNTfNj5ZPVZ5rb2Ju2X"
    ]
  },
  "events": [
    {
      "id": {
        "txDigest": "GkYdXGvqq4WzAWDUm4ohTLtU8ujvdQynguUyUPj1vmF3",
        "eventSeq": "0"
      },
      "packageId": "0x035cf7b699be1d67785cc54dabc83e497fae23516c0329bea39faabf3384f702",
      "transactionModule": "badge_rewards",
      "sender": "0x0deaf2ae9d8e4877eb7bf5d86434488e343b6881bedff8fc78031b6d0df7c75a",
      "type": "0x2::display::DisplayCreated<0x035cf7b699be1d67785cc54dabc83e497fae23516c0329bea39faabf3384f702::badge_rewards::DonorBadge>",
      "parsedJson": {
        "id": "0x7c4ccf431be3b7519884945563f0c7e9e02d6326c5af5c470892efe8588a6ccc"
      },
      "bcsEncoding": "base64",
      "bcs": "fEzPQxvjt1GYhJRVY/DH6eAtYybFr1xHCJLv6FiKbMw="
    },
    {
      "id": {
        "txDigest": "GkYdXGvqq4WzAWDUm4ohTLtU8ujvdQynguUyUPj1vmF3",
        "eventSeq": "1"
      },
      "packageId": "0x035cf7b699be1d67785cc54dabc83e497fae23516c0329bea39faabf3384f702",
      "transactionModule": "badge_rewards",
      "sender": "0x0deaf2ae9d8e4877eb7bf5d86434488e343b6881bedff8fc78031b6d0df7c75a",
      "type": "0x2::display::VersionUpdated<0x035cf7b699be1d67785cc54dabc83e497fae23516c0329bea39faabf3384f702::badge_rewards::DonorBadge>",
      "parsedJson": {
        "fields": {
          "contents": [
            {
              "key": "name",
              "value": "Crowd Walrus Donor Badge Level {level}"
            },
            {
              "key": "image_url",
              "value": "{image_uri}"
            },
            {
              "key": "description",
              "value": "Rewarded to {owner} for reaching badge level {level}. Issued at {issued_at_ms} ms."
            },
            {
              "key": "link",
              "value": "https://crowdwalrus.xyz/profile/{owner}"
            }
          ]
        },
        "id": "0x7c4ccf431be3b7519884945563f0c7e9e02d6326c5af5c470892efe8588a6ccc",
        "version": 1
      },
      "bcsEncoding": "base64",
      "bcs": "fEzPQxvjt1GYhJRVY/DH6eAtYybFr1xHCJLv6FiKbMwBAAQEbmFtZSZDcm93ZCBXYWxydXMgRG9ub3IgQmFkZ2UgTGV2ZWwge2xldmVsfQlpbWFnZV91cmwLe2ltYWdlX3VyaX0LZGVzY3JpcHRpb25SUmV3YXJkZWQgdG8ge293bmVyfSBmb3IgcmVhY2hpbmcgYmFkZ2UgbGV2ZWwge2xldmVsfS4gSXNzdWVkIGF0IHtpc3N1ZWRfYXRfbXN9IG1zLgRsaW5rJ2h0dHBzOi8vY3Jvd2R3YWxydXMueHl6L3Byb2ZpbGUve293bmVyfQ=="
    }
  ],
  "timestampMs": "1770306038019",
  "confirmedLocalExecution": true,
  "checkpoint": "241933112",
  "errors": [
    "Cannot retrieve balance changes: Could not find the referenced object 0x98a43439d58f5ece303484f261f1e533ee92281f4094e1322b974ed756173577 as the asked version SequenceNumber(773550339) is higher than the latest SequenceNumber(773550338)",
    "Cannot retrieve object changes: Could not find the referenced object 0x98a43439d58f5ece303484f261f1e533ee92281f4094e1322b974ed756173577 as the asked version SequenceNumber(773550339) is higher than the latest SequenceNumber(773550338)"
  ]
}
```



# Publicnode RPC verification (2026-02-05T16:11:03Z)


RPC used: https://sui-rpc.publicnode.com


## TokenRegistry dynamic fields (publicnode-mainnet)

Path: `/tmp/publicnode_token_registry_fields.json`

```json
{
  "data": [
    {
      "name": {
        "type": "0x035cf7b699be1d67785cc54dabc83e497fae23516c0329bea39faabf3384f702::token_registry::CoinKey<0x2::sui::SUI>",
        "value": {
          "dummy_field": false
        }
      },
      "bcsEncoding": "base64",
      "bcsName": "AA==",
      "type": "DynamicField",
      "objectType": "0x035cf7b699be1d67785cc54dabc83e497fae23516c0329bea39faabf3384f702::token_registry::TokenMetadata",
      "objectId": "0x2b4acc008ec955c1353180cda2fdef41b7e1c6d4ac4fea946d41c8b13fbfa131",
      "version": 773550339,
      "digest": "GxG8BEUXGDqth2zbuE9ogQ8qCBD6A7SzFLGjDUvfNn3Q"
    },
    {
      "name": {
        "type": "0x035cf7b699be1d67785cc54dabc83e497fae23516c0329bea39faabf3384f702::token_registry::CoinKey<0x5145494a5f5100e645e4b0aa950fa6b68f614e8c59e17bc5ded3495123a79178::ns::NS>",
        "value": {
          "dummy_field": false
        }
      },
      "bcsEncoding": "base64",
      "bcsName": "AA==",
      "type": "DynamicField",
      "objectType": "0x035cf7b699be1d67785cc54dabc83e497fae23516c0329bea39faabf3384f702::token_registry::TokenMetadata",
      "objectId": "0x7dd6f5084edb348062223be60e2c022a30d93c838f89d8e3f4583d78189910d3",
      "version": 773550345,
      "digest": "GMfQZRx3GshQRCYKFbsyC4rqQQhQAkEjfhYSRPy3apyM"
    },
    {
      "name": {
        "type": "0x035cf7b699be1d67785cc54dabc83e497fae23516c0329bea39faabf3384f702::token_registry::CoinKey<0xdba34672e30cb065b1f93e3ab55318768fd6fef66c15942c9f7cb846e2f900e7::usdc::USDC>",
        "value": {
          "dummy_field": false
        }
      },
      "bcsEncoding": "base64",
      "bcsName": "AA==",
      "type": "DynamicField",
      "objectType": "0x035cf7b699be1d67785cc54dabc83e497fae23516c0329bea39faabf3384f702::token_registry::TokenMetadata",
      "objectId": "0xa78a76693a5429a416e0bc1d34f4a2322e6aad6f5dc21d85eaf2380e1dd80fb7",
      "version": 773550341,
      "digest": "FqmLdUEjHgZjDCZMTaPX2T6xURvKw4mYPTLzwKYyCRBt"
    },
    {
      "name": {
        "type": "0x035cf7b699be1d67785cc54dabc83e497fae23516c0329bea39faabf3384f702::token_registry::CoinKey<0x356a26eb9e012a68958082340d4c4116e7f55615cf27affcff209cf0ae544f59::wal::WAL>",
        "value": {
          "dummy_field": false
        }
      },
      "bcsEncoding": "base64",
      "bcsName": "AA==",
      "type": "DynamicField",
      "objectType": "0x035cf7b699be1d67785cc54dabc83e497fae23516c0329bea39faabf3384f702::token_registry::TokenMetadata",
      "objectId": "0xccc963294ad127a42dabf8322c3812826d1115758f324a0912d57b7e07f73fd7",
      "version": 773550343,
      "digest": "77u2zny4ViB7JdFbCBedXWPHBdJaaKPWLnDxSJRn3Bci"
    },
    {
      "name": {
        "type": "0x035cf7b699be1d67785cc54dabc83e497fae23516c0329bea39faabf3384f702::token_registry::CoinKey<0xe1b45a0e641b9955a20aa0ad1c1f4ad86aad8afb07296d4085e349a50e90bdca::blue::BLUE>",
        "value": {
          "dummy_field": false
        }
      },
      "bcsEncoding": "base64",
      "bcsName": "AA==",
      "type": "DynamicField",
      "objectType": "0x035cf7b699be1d67785cc54dabc83e497fae23516c0329bea39faabf3384f702::token_registry::TokenMetadata",
      "objectId": "0xe9d2847f2888a0e36a9105c73dee04be0c93915acf1296f07a4241d26e8b0e2e",
      "version": 773550347,
      "digest": "GN1XUrQ7DhvPhu5wtCfuvpyUmNkYQGUitRa5siC1k3TP"
    }
  ],
  "nextCursor": "0xe9d2847f2888a0e36a9105c73dee04be0c93915acf1296f07a4241d26e8b0e2e",
  "hasNextPage": false
}
```


## Policy table dynamic fields (publicnode-mainnet)

Path: `/tmp/publicnode_policy_table_fields.json`

```json
{
  "data": [
    {
      "name": {
        "type": "0x1::string::String",
        "value": "standard"
      },
      "bcsEncoding": "base64",
      "bcsName": "CHN0YW5kYXJk",
      "type": "DynamicField",
      "objectType": "0x035cf7b699be1d67785cc54dabc83e497fae23516c0329bea39faabf3384f702::platform_policy::Policy",
      "objectId": "0x1dd1fa6ffb4e68007880380cfc206daa80a2275f307d539b0be3a881b5a92799",
      "version": 773550349,
      "digest": "BnvwRDsXVCPNm3AxVuSwbmQnCmRaiQr6EHdYWdCsXzmi"
    },
    {
      "name": {
        "type": "0x1::string::String",
        "value": "commercial"
      },
      "bcsEncoding": "base64",
      "bcsName": "CmNvbW1lcmNpYWw=",
      "type": "DynamicField",
      "objectType": "0x035cf7b699be1d67785cc54dabc83e497fae23516c0329bea39faabf3384f702::platform_policy::Policy",
      "objectId": "0xaa6055cbaeb720ba5662dba9c66049d90be986500f7159d317b50f7b80a956fd",
      "version": 773550350,
      "digest": "GNKoPWDvPmgyHeAcjSA6jzfi7g7sKRHCWRcxWebtFd7e"
    }
  ],
  "nextCursor": "0xaa6055cbaeb720ba5662dba9c66049d90be986500f7159d317b50f7b80a956fd",
  "hasNextPage": false
}
```


## Policy object: standard

Path: `/tmp/publicnode_policy_1dd1fa6ffb4e68007880380cfc206daa80a2275f307d539b0be3a881b5a92799.json`

```json
{
  "objectId": "0x1dd1fa6ffb4e68007880380cfc206daa80a2275f307d539b0be3a881b5a92799",
  "version": "773550349",
  "digest": "BnvwRDsXVCPNm3AxVuSwbmQnCmRaiQr6EHdYWdCsXzmi",
  "type": "0x2::dynamic_field::Field<0x1::string::String, 0x035cf7b699be1d67785cc54dabc83e497fae23516c0329bea39faabf3384f702::platform_policy::Policy>",
  "owner": {
    "ObjectOwner": "0x79767ca44deef0c4ecd5f761df162b4b74e69732678fd46cd69fab0167785cbf"
  },
  "previousTransaction": "D2L3nN5rHNTRQG4GXtRgpSmHStLXdBSw3wLjJEHxrmR3",
  "storageRebate": "2462400",
  "content": {
    "dataType": "moveObject",
    "type": "0x2::dynamic_field::Field<0x1::string::String, 0x035cf7b699be1d67785cc54dabc83e497fae23516c0329bea39faabf3384f702::platform_policy::Policy>",
    "hasPublicTransfer": false,
    "fields": {
      "id": {
        "id": "0x1dd1fa6ffb4e68007880380cfc206daa80a2275f307d539b0be3a881b5a92799"
      },
      "name": "standard",
      "value": {
        "type": "0x035cf7b699be1d67785cc54dabc83e497fae23516c0329bea39faabf3384f702::platform_policy::Policy",
        "fields": {
          "enabled": true,
          "platform_address": "0xa0cd94d73e0df4e76010e3f2232435839cc619190826508a2540eea768192c1d",
          "platform_bps": 0
        }
      }
    }
  }
}
```


## Policy object: commercial

Path: `/tmp/publicnode_policy_aa6055cbaeb720ba5662dba9c66049d90be986500f7159d317b50f7b80a956fd.json`

```json
{
  "objectId": "0xaa6055cbaeb720ba5662dba9c66049d90be986500f7159d317b50f7b80a956fd",
  "version": "773550350",
  "digest": "GNKoPWDvPmgyHeAcjSA6jzfi7g7sKRHCWRcxWebtFd7e",
  "type": "0x2::dynamic_field::Field<0x1::string::String, 0x035cf7b699be1d67785cc54dabc83e497fae23516c0329bea39faabf3384f702::platform_policy::Policy>",
  "owner": {
    "ObjectOwner": "0x79767ca44deef0c4ecd5f761df162b4b74e69732678fd46cd69fab0167785cbf"
  },
  "previousTransaction": "G73CTSZ4MTZCsz2pNh3fQciumHN8jdsyJAjYxU6FpXcY",
  "storageRebate": "2477600",
  "content": {
    "dataType": "moveObject",
    "type": "0x2::dynamic_field::Field<0x1::string::String, 0x035cf7b699be1d67785cc54dabc83e497fae23516c0329bea39faabf3384f702::platform_policy::Policy>",
    "hasPublicTransfer": false,
    "fields": {
      "id": {
        "id": "0xaa6055cbaeb720ba5662dba9c66049d90be986500f7159d317b50f7b80a956fd"
      },
      "name": "commercial",
      "value": {
        "type": "0x035cf7b699be1d67785cc54dabc83e497fae23516c0329bea39faabf3384f702::platform_policy::Policy",
        "fields": {
          "enabled": true,
          "platform_address": "0xa0cd94d73e0df4e76010e3f2232435839cc619190826508a2540eea768192c1d",
          "platform_bps": 500
        }
      }
    }
  }
}
```


## DonorBadge Display object

Path: `/tmp/publicnode_badge_display.json`

```json
{
  "objectId": "0x7c4ccf431be3b7519884945563f0c7e9e02d6326c5af5c470892efe8588a6ccc",
  "version": "773550339",
  "digest": "FAEgbkPEVjaiYcusR32wjvCXb7RDccpdxjRDGtBphWC1",
  "type": "0x2::display::Display<0x035cf7b699be1d67785cc54dabc83e497fae23516c0329bea39faabf3384f702::badge_rewards::DonorBadge>",
  "owner": {
    "Shared": {
      "initial_shared_version": 773550339
    }
  },
  "previousTransaction": "GkYdXGvqq4WzAWDUm4ohTLtU8ujvdQynguUyUPj1vmF3",
  "storageRebate": "3336400",
  "content": {
    "dataType": "moveObject",
    "type": "0x2::display::Display<0x035cf7b699be1d67785cc54dabc83e497fae23516c0329bea39faabf3384f702::badge_rewards::DonorBadge>",
    "hasPublicTransfer": true,
    "fields": {
      "fields": {
        "type": "0x2::vec_map::VecMap<0x1::string::String, 0x1::string::String>",
        "fields": {
          "contents": [
            {
              "type": "0x2::vec_map::Entry<0x1::string::String, 0x1::string::String>",
              "fields": {
                "key": "name",
                "value": "Crowd Walrus Donor Badge Level {level}"
              }
            },
            {
              "type": "0x2::vec_map::Entry<0x1::string::String, 0x1::string::String>",
              "fields": {
                "key": "image_url",
                "value": "{image_uri}"
              }
            },
            {
              "type": "0x2::vec_map::Entry<0x1::string::String, 0x1::string::String>",
              "fields": {
                "key": "description",
                "value": "Rewarded to {owner} for reaching badge level {level}. Issued at {issued_at_ms} ms."
              }
            },
            {
              "type": "0x2::vec_map::Entry<0x1::string::String, 0x1::string::String>",
              "fields": {
                "key": "link",
                "value": "https://crowdwalrus.xyz/profile/{owner}"
              }
            }
          ]
        }
      },
      "id": {
        "id": "0x7c4ccf431be3b7519884945563f0c7e9e02d6326c5af5c470892efe8588a6ccc"
      },
      "version": 1
    }
  }
}
```


## BadgeConfig object

Path: `/tmp/publicnode_badge_config.json`

```json
{
  "objectId": "0xdbbc3ed362df0a25b68d62bdcb237c8ea7eb2c109228de69a575dd15a77de43e",
  "version": "773550348",
  "digest": "otnVwg4h4s6KpvuhUKLJxbWeuDQG8eZgr4RF4TuBYt3",
  "type": "0x035cf7b699be1d67785cc54dabc83e497fae23516c0329bea39faabf3384f702::badge_rewards::BadgeConfig",
  "owner": {
    "Shared": {
      "initial_shared_version": 773550337
    }
  },
  "previousTransaction": "CjP4JQv9GN4So2frTH85MAiikQothYzGz6UsSAoGaKp",
  "storageRebate": "6999600",
  "content": {
    "dataType": "moveObject",
    "type": "0x035cf7b699be1d67785cc54dabc83e497fae23516c0329bea39faabf3384f702::badge_rewards::BadgeConfig",
    "hasPublicTransfer": false,
    "fields": {
      "amount_thresholds_micro": [
        "10000000",
        "150000000",
        "400000000",
        "900000000",
        "1800000000"
      ],
      "crowd_walrus_id": "0x95084b96d2f27283fd91db36166d96c477a02d8d76317655b6ba04cfa24e94a0",
      "id": {
        "id": "0xdbbc3ed362df0a25b68d62bdcb237c8ea7eb2c109228de69a575dd15a77de43e"
      },
      "image_uris": [
        "https://aggregator.walrus-mainnet.walrus.space/v1/blobs/by-quilt-patch-id/BiFXQRMI4aR1nJwo-0VpMKjz9YJURDKll8XGOU1xQY8BAQBHAA",
        "https://aggregator.walrus-mainnet.walrus.space/v1/blobs/by-quilt-patch-id/BiFXQRMI4aR1nJwo-0VpMKjz9YJURDKll8XGOU1xQY8BRwCgAA",
        "https://aggregator.walrus-mainnet.walrus.space/v1/blobs/by-quilt-patch-id/BiFXQRMI4aR1nJwo-0VpMKjz9YJURDKll8XGOU1xQY8BoAAFAQ",
        "https://aggregator.walrus-mainnet.walrus.space/v1/blobs/by-quilt-patch-id/BiFXQRMI4aR1nJwo-0VpMKjz9YJURDKll8XGOU1xQY8BBQFyAQ",
        "https://aggregator.walrus-mainnet.walrus.space/v1/blobs/by-quilt-patch-id/BiFXQRMI4aR1nJwo-0VpMKjz9YJURDKll8XGOU1xQY8BcgEnAg"
      ],
      "payment_thresholds": [
        "1",
        "2",
        "4",
        "8",
        "15"
      ]
    }
  }
}
```


## Token metadata object: 2b4acc008ec955c1353180cda2fdef41b7e1c6d4ac4fea946d41c8b13fbfa131

Path: `/tmp/publicnode_token_meta_2b4acc008ec955c1353180cda2fdef41b7e1c6d4ac4fea946d41c8b13fbfa131.json`

```json
{
  "objectId": "0x2b4acc008ec955c1353180cda2fdef41b7e1c6d4ac4fea946d41c8b13fbfa131",
  "version": "773550339",
  "digest": "GxG8BEUXGDqth2zbuE9ogQ8qCBD6A7SzFLGjDUvfNn3Q",
  "type": "0x2::dynamic_field::Field<0x035cf7b699be1d67785cc54dabc83e497fae23516c0329bea39faabf3384f702::token_registry::CoinKey<0x2::sui::SUI>, 0x035cf7b699be1d67785cc54dabc83e497fae23516c0329bea39faabf3384f702::token_registry::TokenMetadata>",
  "owner": {
    "ObjectOwner": "0x9409e01b8bafbad0b89e949bcfb8416be7f600f4b87df3bc4103e6f5d78cfb00"
  },
  "previousTransaction": "GeieLjJiun9v9Gg9FWjfGZ54rH8TGUtVeKJ3eey8DUtE",
  "storageRebate": "2956400",
  "content": {
    "dataType": "moveObject",
    "type": "0x2::dynamic_field::Field<0x035cf7b699be1d67785cc54dabc83e497fae23516c0329bea39faabf3384f702::token_registry::CoinKey<0x2::sui::SUI>, 0x035cf7b699be1d67785cc54dabc83e497fae23516c0329bea39faabf3384f702::token_registry::TokenMetadata>",
    "hasPublicTransfer": false,
    "fields": {
      "id": {
        "id": "0x2b4acc008ec955c1353180cda2fdef41b7e1c6d4ac4fea946d41c8b13fbfa131"
      },
      "name": {
        "type": "0x035cf7b699be1d67785cc54dabc83e497fae23516c0329bea39faabf3384f702::token_registry::CoinKey<0x2::sui::SUI>",
        "fields": {
          "dummy_field": false
        }
      },
      "value": {
        "type": "0x035cf7b699be1d67785cc54dabc83e497fae23516c0329bea39faabf3384f702::token_registry::TokenMetadata",
        "fields": {
          "decimals": 9,
          "enabled": true,
          "max_age_ms": "300000",
          "name": "Sui",
          "pyth_feed_id": [
            35,
            215,
            49,
            81,
            19,
            245,
            177,
            211,
            186,
            122,
            131,
            96,
            76,
            68,
            185,
            77,
            121,
            244,
            253,
            105,
            175,
            119,
            248,
            4,
            252,
            127,
            146,
            10,
            109,
            198,
            87,
            68
          ],
          "symbol": "SUI"
        }
      }
    }
  }
}
```


## Token metadata object: 7dd6f5084edb348062223be60e2c022a30d93c838f89d8e3f4583d78189910d3

Path: `/tmp/publicnode_token_meta_7dd6f5084edb348062223be60e2c022a30d93c838f89d8e3f4583d78189910d3.json`

```json
{
  "objectId": "0x7dd6f5084edb348062223be60e2c022a30d93c838f89d8e3f4583d78189910d3",
  "version": "773550345",
  "digest": "GMfQZRx3GshQRCYKFbsyC4rqQQhQAkEjfhYSRPy3apyM",
  "type": "0x2::dynamic_field::Field<0x035cf7b699be1d67785cc54dabc83e497fae23516c0329bea39faabf3384f702::token_registry::CoinKey<0x5145494a5f5100e645e4b0aa950fa6b68f614e8c59e17bc5ded3495123a79178::ns::NS>, 0x035cf7b699be1d67785cc54dabc83e497fae23516c0329bea39faabf3384f702::token_registry::TokenMetadata>",
  "owner": {
    "ObjectOwner": "0x9409e01b8bafbad0b89e949bcfb8416be7f600f4b87df3bc4103e6f5d78cfb00"
  },
  "previousTransaction": "5fjznGPizPHDtfa8Tf7p1uiGSssoLBYWfrnMtstd2pUQ",
  "storageRebate": "2994400",
  "content": {
    "dataType": "moveObject",
    "type": "0x2::dynamic_field::Field<0x035cf7b699be1d67785cc54dabc83e497fae23516c0329bea39faabf3384f702::token_registry::CoinKey<0x5145494a5f5100e645e4b0aa950fa6b68f614e8c59e17bc5ded3495123a79178::ns::NS>, 0x035cf7b699be1d67785cc54dabc83e497fae23516c0329bea39faabf3384f702::token_registry::TokenMetadata>",
    "hasPublicTransfer": false,
    "fields": {
      "id": {
        "id": "0x7dd6f5084edb348062223be60e2c022a30d93c838f89d8e3f4583d78189910d3"
      },
      "name": {
        "type": "0x035cf7b699be1d67785cc54dabc83e497fae23516c0329bea39faabf3384f702::token_registry::CoinKey<0x5145494a5f5100e645e4b0aa950fa6b68f614e8c59e17bc5ded3495123a79178::ns::NS>",
        "fields": {
          "dummy_field": false
        }
      },
      "value": {
        "type": "0x035cf7b699be1d67785cc54dabc83e497fae23516c0329bea39faabf3384f702::token_registry::TokenMetadata",
        "fields": {
          "decimals": 6,
          "enabled": true,
          "max_age_ms": "300000",
          "name": "SuiNS Token",
          "pyth_feed_id": [
            187,
            95,
            242,
            110,
            71,
            163,
            166,
            204,
            126,
            194,
            252,
            225,
            219,
            153,
            108,
            42,
            20,
            83,
            0,
            237,
            197,
            172,
            170,
            190,
            67,
            191,
            159,
            247,
            197,
            221,
            93,
            50
          ],
          "symbol": "NS"
        }
      }
    }
  }
}
```


## Token metadata object: a78a76693a5429a416e0bc1d34f4a2322e6aad6f5dc21d85eaf2380e1dd80fb7

Path: `/tmp/publicnode_token_meta_a78a76693a5429a416e0bc1d34f4a2322e6aad6f5dc21d85eaf2380e1dd80fb7.json`

```json
{
  "objectId": "0xa78a76693a5429a416e0bc1d34f4a2322e6aad6f5dc21d85eaf2380e1dd80fb7",
  "version": "773550341",
  "digest": "FqmLdUEjHgZjDCZMTaPX2T6xURvKw4mYPTLzwKYyCRBt",
  "type": "0x2::dynamic_field::Field<0x035cf7b699be1d67785cc54dabc83e497fae23516c0329bea39faabf3384f702::token_registry::CoinKey<0xdba34672e30cb065b1f93e3ab55318768fd6fef66c15942c9f7cb846e2f900e7::usdc::USDC>, 0x035cf7b699be1d67785cc54dabc83e497fae23516c0329bea39faabf3384f702::token_registry::TokenMetadata>",
  "owner": {
    "ObjectOwner": "0x9409e01b8bafbad0b89e949bcfb8416be7f600f4b87df3bc4103e6f5d78cfb00"
  },
  "previousTransaction": "2H6L524aXaiZMFH4xRPaUvE1g2BvGXCXNzjdGXKySYZE",
  "storageRebate": "2986800",
  "content": {
    "dataType": "moveObject",
    "type": "0x2::dynamic_field::Field<0x035cf7b699be1d67785cc54dabc83e497fae23516c0329bea39faabf3384f702::token_registry::CoinKey<0xdba34672e30cb065b1f93e3ab55318768fd6fef66c15942c9f7cb846e2f900e7::usdc::USDC>, 0x035cf7b699be1d67785cc54dabc83e497fae23516c0329bea39faabf3384f702::token_registry::TokenMetadata>",
    "hasPublicTransfer": false,
    "fields": {
      "id": {
        "id": "0xa78a76693a5429a416e0bc1d34f4a2322e6aad6f5dc21d85eaf2380e1dd80fb7"
      },
      "name": {
        "type": "0x035cf7b699be1d67785cc54dabc83e497fae23516c0329bea39faabf3384f702::token_registry::CoinKey<0xdba34672e30cb065b1f93e3ab55318768fd6fef66c15942c9f7cb846e2f900e7::usdc::USDC>",
        "fields": {
          "dummy_field": false
        }
      },
      "value": {
        "type": "0x035cf7b699be1d67785cc54dabc83e497fae23516c0329bea39faabf3384f702::token_registry::TokenMetadata",
        "fields": {
          "decimals": 6,
          "enabled": true,
          "max_age_ms": "300000",
          "name": "USDC",
          "pyth_feed_id": [
            234,
            160,
            32,
            198,
            28,
            196,
            121,
            113,
            40,
            19,
            70,
            28,
            225,
            83,
            137,
            74,
            150,
            166,
            192,
            11,
            33,
            237,
            12,
            252,
            39,
            152,
            209,
            249,
            169,
            233,
            201,
            74
          ],
          "symbol": "USDC"
        }
      }
    }
  }
}
```


## Token metadata object: ccc963294ad127a42dabf8322c3812826d1115758f324a0912d57b7e07f73fd7

Path: `/tmp/publicnode_token_meta_ccc963294ad127a42dabf8322c3812826d1115758f324a0912d57b7e07f73fd7.json`

```json
{
  "objectId": "0xccc963294ad127a42dabf8322c3812826d1115758f324a0912d57b7e07f73fd7",
  "version": "773550343",
  "digest": "77u2zny4ViB7JdFbCBedXWPHBdJaaKPWLnDxSJRn3Bci",
  "type": "0x2::dynamic_field::Field<0x035cf7b699be1d67785cc54dabc83e497fae23516c0329bea39faabf3384f702::token_registry::CoinKey<0x356a26eb9e012a68958082340d4c4116e7f55615cf27affcff209cf0ae544f59::wal::WAL>, 0x035cf7b699be1d67785cc54dabc83e497fae23516c0329bea39faabf3384f702::token_registry::TokenMetadata>",
  "owner": {
    "ObjectOwner": "0x9409e01b8bafbad0b89e949bcfb8416be7f600f4b87df3bc4103e6f5d78cfb00"
  },
  "previousTransaction": "HyfWo9qdDwfY2ByRQi9cVWdfQz29BuWrNuxWVYLanyLu",
  "storageRebate": "3002000",
  "content": {
    "dataType": "moveObject",
    "type": "0x2::dynamic_field::Field<0x035cf7b699be1d67785cc54dabc83e497fae23516c0329bea39faabf3384f702::token_registry::CoinKey<0x356a26eb9e012a68958082340d4c4116e7f55615cf27affcff209cf0ae544f59::wal::WAL>, 0x035cf7b699be1d67785cc54dabc83e497fae23516c0329bea39faabf3384f702::token_registry::TokenMetadata>",
    "hasPublicTransfer": false,
    "fields": {
      "id": {
        "id": "0xccc963294ad127a42dabf8322c3812826d1115758f324a0912d57b7e07f73fd7"
      },
      "name": {
        "type": "0x035cf7b699be1d67785cc54dabc83e497fae23516c0329bea39faabf3384f702::token_registry::CoinKey<0x356a26eb9e012a68958082340d4c4116e7f55615cf27affcff209cf0ae544f59::wal::WAL>",
        "fields": {
          "dummy_field": false
        }
      },
      "value": {
        "type": "0x035cf7b699be1d67785cc54dabc83e497fae23516c0329bea39faabf3384f702::token_registry::TokenMetadata",
        "fields": {
          "decimals": 9,
          "enabled": true,
          "max_age_ms": "300000",
          "name": "WAL Token",
          "pyth_feed_id": [
            235,
            160,
            115,
            35,
            149,
            250,
            233,
            222,
            196,
            186,
            225,
            46,
            82,
            118,
            11,
            53,
            252,
            28,
            86,
            113,
            226,
            218,
            139,
            68,
            156,
            154,
            244,
            239,
            229,
            213,
            67,
            65
          ],
          "symbol": "WAL"
        }
      }
    }
  }
}
```


## Token metadata object: e9d2847f2888a0e36a9105c73dee04be0c93915acf1296f07a4241d26e8b0e2e

Path: `/tmp/publicnode_token_meta_e9d2847f2888a0e36a9105c73dee04be0c93915acf1296f07a4241d26e8b0e2e.json`

```json
{
  "objectId": "0xe9d2847f2888a0e36a9105c73dee04be0c93915acf1296f07a4241d26e8b0e2e",
  "version": "773550347",
  "digest": "GN1XUrQ7DhvPhu5wtCfuvpyUmNkYQGUitRa5siC1k3TP",
  "type": "0x2::dynamic_field::Field<0x035cf7b699be1d67785cc54dabc83e497fae23516c0329bea39faabf3384f702::token_registry::CoinKey<0xe1b45a0e641b9955a20aa0ad1c1f4ad86aad8afb07296d4085e349a50e90bdca::blue::BLUE>, 0x035cf7b699be1d67785cc54dabc83e497fae23516c0329bea39faabf3384f702::token_registry::TokenMetadata>",
  "owner": {
    "ObjectOwner": "0x9409e01b8bafbad0b89e949bcfb8416be7f600f4b87df3bc4103e6f5d78cfb00"
  },
  "previousTransaction": "DDjn5bjjhSAPfLWVyqYr6QXy3kohcHY66eHNRt1WUsu1",
  "storageRebate": "3009600",
  "content": {
    "dataType": "moveObject",
    "type": "0x2::dynamic_field::Field<0x035cf7b699be1d67785cc54dabc83e497fae23516c0329bea39faabf3384f702::token_registry::CoinKey<0xe1b45a0e641b9955a20aa0ad1c1f4ad86aad8afb07296d4085e349a50e90bdca::blue::BLUE>, 0x035cf7b699be1d67785cc54dabc83e497fae23516c0329bea39faabf3384f702::token_registry::TokenMetadata>",
    "hasPublicTransfer": false,
    "fields": {
      "id": {
        "id": "0xe9d2847f2888a0e36a9105c73dee04be0c93915acf1296f07a4241d26e8b0e2e"
      },
      "name": {
        "type": "0x035cf7b699be1d67785cc54dabc83e497fae23516c0329bea39faabf3384f702::token_registry::CoinKey<0xe1b45a0e641b9955a20aa0ad1c1f4ad86aad8afb07296d4085e349a50e90bdca::blue::BLUE>",
        "fields": {
          "dummy_field": false
        }
      },
      "value": {
        "type": "0x035cf7b699be1d67785cc54dabc83e497fae23516c0329bea39faabf3384f702::token_registry::TokenMetadata",
        "fields": {
          "decimals": 9,
          "enabled": true,
          "max_age_ms": "300000",
          "name": "Bluefin",
          "pyth_feed_id": [
            4,
            207,
            235,
            123,
            20,
            62,
            185,
            196,
            142,
            155,
            7,
            65,
            37,
            193,
            163,
            68,
            123,
            133,
            245,
            156,
            49,
            22,
            77,
            194,
            12,
            27,
            234,
            166,
            242,
            31,
            43,
            107
          ],
          "symbol": "BLUE"
        }
      }
    }
  }
}
```
