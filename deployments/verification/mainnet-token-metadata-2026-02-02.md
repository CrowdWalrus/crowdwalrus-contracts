# Mainnet Token Metadata Verification (2026-02-02)

This file contains **raw** and **beautified** RPC outputs for the mainnet token metadata checks.

Notes:
- Source file: `mainnet-token-metadata-2026-02-02.txt`
- RPC endpoint: `https://fullnode.mainnet.sui.io:443`
- Methods used: `suix_getCoinMetadata`, `sui_getObject`
- The raw JSON blocks are preserved as-is for audit; beautified JSON is provided for readability.

## SUI (0x2::sui::SUI)

### suix_getCoinMetadata (raw)

```json
{"jsonrpc":"2.0","id":1,"result":{"decimals":9,"name":"Sui","symbol":"SUI","description":"","iconUrl":"","id":"0xf256d3fb6a50eaa748d94335b34f2982fbc3b63ceec78cafaa29ebc9ebaf2bbc"}}
```

### suix_getCoinMetadata (beautified)

```json
{
  "jsonrpc": "2.0",
  "id": 1,
  "result": {
    "decimals": 9,
    "name": "Sui",
    "symbol": "SUI",
    "description": "",
    "iconUrl": "",
    "id": "0xf256d3fb6a50eaa748d94335b34f2982fbc3b63ceec78cafaa29ebc9ebaf2bbc"
  }
}
```

## metadata id 0xf256d3fb6a50eaa748d94335b34f2982fbc3b63ceec78cafaa29ebc9ebaf2bbc

### sui_getObject (raw)

```json
{"jsonrpc":"2.0","id":1,"result":{"data":{"objectId":"0xf256d3fb6a50eaa748d94335b34f2982fbc3b63ceec78cafaa29ebc9ebaf2bbc","version":"646801005","digest":"E43Gp8bAs9hdAqBJdQLzm8FneKRCixi13bVX6yY1dpHx","type":"0x2::coin_registry::Currency<0x2::sui::SUI>","content":{"dataType":"moveObject","type":"0x2::coin_registry::Currency<0x2::sui::SUI>","hasPublicTransfer":false,"fields":{"decimals":9,"description":"","extra_fields":{"type":"0x2::vec_map::VecMap<0x1::string::String, 0x2::coin_registry::ExtraField>","fields":{"contents":[]}},"icon_url":"","id":{"id":"0xf256d3fb6a50eaa748d94335b34f2982fbc3b63ceec78cafaa29ebc9ebaf2bbc"},"metadata_cap_id":{"type":"0x2::coin_registry::MetadataCapState","variant":"Unclaimed","fields":{}},"name":"Sui","regulated":{"type":"0x2::coin_registry::RegulatedState","variant":"Unknown","fields":{}},"supply":{"type":"0x2::coin_registry::SupplyState<0x2::sui::SUI>","variant":"Unknown","fields":{}},"symbol":"SUI","treasury_cap_id":null}}}}}
```

### sui_getObject (beautified)

```json
{
  "jsonrpc": "2.0",
  "id": 1,
  "result": {
    "data": {
      "objectId": "0xf256d3fb6a50eaa748d94335b34f2982fbc3b63ceec78cafaa29ebc9ebaf2bbc",
      "version": "646801005",
      "digest": "E43Gp8bAs9hdAqBJdQLzm8FneKRCixi13bVX6yY1dpHx",
      "type": "0x2::coin_registry::Currency<0x2::sui::SUI>",
      "content": {
        "dataType": "moveObject",
        "type": "0x2::coin_registry::Currency<0x2::sui::SUI>",
        "hasPublicTransfer": false,
        "fields": {
          "decimals": 9,
          "description": "",
          "extra_fields": {
            "type": "0x2::vec_map::VecMap<0x1::string::String, 0x2::coin_registry::ExtraField>",
            "fields": {
              "contents": []
            }
          },
          "icon_url": "",
          "id": {
            "id": "0xf256d3fb6a50eaa748d94335b34f2982fbc3b63ceec78cafaa29ebc9ebaf2bbc"
          },
          "metadata_cap_id": {
            "type": "0x2::coin_registry::MetadataCapState",
            "variant": "Unclaimed",
            "fields": {}
          },
          "name": "Sui",
          "regulated": {
            "type": "0x2::coin_registry::RegulatedState",
            "variant": "Unknown",
            "fields": {}
          },
          "supply": {
            "type": "0x2::coin_registry::SupplyState<0x2::sui::SUI>",
            "variant": "Unknown",
            "fields": {}
          },
          "symbol": "SUI",
          "treasury_cap_id": null
        }
      }
    }
  }
}
```

## USDC (0xdba34672e30cb065b1f93e3ab55318768fd6fef66c15942c9f7cb846e2f900e7::usdc::USDC)

### suix_getCoinMetadata (raw)

```json
{"jsonrpc":"2.0","id":1,"result":{"decimals":6,"name":"USDC","symbol":"USDC","description":"USDC is a US dollar-backed stablecoin issued by Circle. USDC is designed to provide a faster, safer, and more efficient way to send, spend, and exchange money around the world.","iconUrl":"https://circle.com/usdc-icon","id":"0x75cfbbf8c962d542e99a1d15731e6069f60a00db895407785b15d14f606f2b4a"}}
```

### suix_getCoinMetadata (beautified)

```json
{
  "jsonrpc": "2.0",
  "id": 1,
  "result": {
    "decimals": 6,
    "name": "USDC",
    "symbol": "USDC",
    "description": "USDC is a US dollar-backed stablecoin issued by Circle. USDC is designed to provide a faster, safer, and more efficient way to send, spend, and exchange money around the world.",
    "iconUrl": "https://circle.com/usdc-icon",
    "id": "0x75cfbbf8c962d542e99a1d15731e6069f60a00db895407785b15d14f606f2b4a"
  }
}
```

## metadata id 0x75cfbbf8c962d542e99a1d15731e6069f60a00db895407785b15d14f606f2b4a

### sui_getObject (raw)

```json
{"jsonrpc":"2.0","id":1,"result":{"data":{"objectId":"0x75cfbbf8c962d542e99a1d15731e6069f60a00db895407785b15d14f606f2b4a","version":"751416438","digest":"9VC8NtL5fKUCkuj2wRa4HWUU1vtQ1BbDFR8XSTMqk8cM","type":"0x2::coin_registry::Currency<0xdba34672e30cb065b1f93e3ab55318768fd6fef66c15942c9f7cb846e2f900e7::usdc::USDC>","content":{"dataType":"moveObject","type":"0x2::coin_registry::Currency<0xdba34672e30cb065b1f93e3ab55318768fd6fef66c15942c9f7cb846e2f900e7::usdc::USDC>","hasPublicTransfer":false,"fields":{"decimals":6,"description":"USDC is a US dollar-backed stablecoin issued by Circle. USDC is designed to provide a faster, safer, and more efficient way to send, spend, and exchange money around the world.","extra_fields":{"type":"0x2::vec_map::VecMap<0x1::string::String, 0x2::coin_registry::ExtraField>","fields":{"contents":[]}},"icon_url":"https://circle.com/usdc-icon","id":{"id":"0x75cfbbf8c962d542e99a1d15731e6069f60a00db895407785b15d14f606f2b4a"},"metadata_cap_id":{"type":"0x2::coin_registry::MetadataCapState","variant":"Unclaimed","fields":{}},"name":"USDC","regulated":{"type":"0x2::coin_registry::RegulatedState","variant":"Regulated","fields":{"allow_global_pause":null,"cap":"0x699b31629c5afb1898ff72105ac323e6904c356587d607b086cdd7e883380ffe","variant":0}},"supply":{"type":"0x2::coin_registry::SupplyState<0xdba34672e30cb065b1f93e3ab55318768fd6fef66c15942c9f7cb846e2f900e7::usdc::USDC>","variant":"Unknown","fields":{}},"symbol":"USDC","treasury_cap_id":null}}}}}
```

### sui_getObject (beautified)

```json
{
  "jsonrpc": "2.0",
  "id": 1,
  "result": {
    "data": {
      "objectId": "0x75cfbbf8c962d542e99a1d15731e6069f60a00db895407785b15d14f606f2b4a",
      "version": "751416438",
      "digest": "9VC8NtL5fKUCkuj2wRa4HWUU1vtQ1BbDFR8XSTMqk8cM",
      "type": "0x2::coin_registry::Currency<0xdba34672e30cb065b1f93e3ab55318768fd6fef66c15942c9f7cb846e2f900e7::usdc::USDC>",
      "content": {
        "dataType": "moveObject",
        "type": "0x2::coin_registry::Currency<0xdba34672e30cb065b1f93e3ab55318768fd6fef66c15942c9f7cb846e2f900e7::usdc::USDC>",
        "hasPublicTransfer": false,
        "fields": {
          "decimals": 6,
          "description": "USDC is a US dollar-backed stablecoin issued by Circle. USDC is designed to provide a faster, safer, and more efficient way to send, spend, and exchange money around the world.",
          "extra_fields": {
            "type": "0x2::vec_map::VecMap<0x1::string::String, 0x2::coin_registry::ExtraField>",
            "fields": {
              "contents": []
            }
          },
          "icon_url": "https://circle.com/usdc-icon",
          "id": {
            "id": "0x75cfbbf8c962d542e99a1d15731e6069f60a00db895407785b15d14f606f2b4a"
          },
          "metadata_cap_id": {
            "type": "0x2::coin_registry::MetadataCapState",
            "variant": "Unclaimed",
            "fields": {}
          },
          "name": "USDC",
          "regulated": {
            "type": "0x2::coin_registry::RegulatedState",
            "variant": "Regulated",
            "fields": {
              "allow_global_pause": null,
              "cap": "0x699b31629c5afb1898ff72105ac323e6904c356587d607b086cdd7e883380ffe",
              "variant": 0
            }
          },
          "supply": {
            "type": "0x2::coin_registry::SupplyState<0xdba34672e30cb065b1f93e3ab55318768fd6fef66c15942c9f7cb846e2f900e7::usdc::USDC>",
            "variant": "Unknown",
            "fields": {}
          },
          "symbol": "USDC",
          "treasury_cap_id": null
        }
      }
    }
  }
}
```

## WAL (0x356a26eb9e012a68958082340d4c4116e7f55615cf27affcff209cf0ae544f59::wal::WAL)

### suix_getCoinMetadata (raw)

```json
{"jsonrpc":"2.0","id":1,"result":{"decimals":9,"name":"WAL Token","symbol":"WAL","description":"The native token for the Walrus Protocol.","iconUrl":"https://www.walrus.xyz/wal-icon.svg","id":"0xb6a0c0bacb1c87c3be4dff20c22ef1012125b5724b5b0ff424f852a2651b23fa"}}
```

### suix_getCoinMetadata (beautified)

```json
{
  "jsonrpc": "2.0",
  "id": 1,
  "result": {
    "decimals": 9,
    "name": "WAL Token",
    "symbol": "WAL",
    "description": "The native token for the Walrus Protocol.",
    "iconUrl": "https://www.walrus.xyz/wal-icon.svg",
    "id": "0xb6a0c0bacb1c87c3be4dff20c22ef1012125b5724b5b0ff424f852a2651b23fa"
  }
}
```

## metadata id 0xb6a0c0bacb1c87c3be4dff20c22ef1012125b5724b5b0ff424f852a2651b23fa

### sui_getObject (raw)

```json
{"jsonrpc":"2.0","id":1,"result":{"data":{"objectId":"0xb6a0c0bacb1c87c3be4dff20c22ef1012125b5724b5b0ff424f852a2651b23fa","version":"749938931","digest":"HKBRwU88pCQK75sRM5kSB2pHut57f2wotA234wyYTsxL","type":"0x2::coin_registry::Currency<0x356a26eb9e012a68958082340d4c4116e7f55615cf27affcff209cf0ae544f59::wal::WAL>","content":{"dataType":"moveObject","type":"0x2::coin_registry::Currency<0x356a26eb9e012a68958082340d4c4116e7f55615cf27affcff209cf0ae544f59::wal::WAL>","hasPublicTransfer":false,"fields":{"decimals":9,"description":"The native token for the Walrus Protocol.","extra_fields":{"type":"0x2::vec_map::VecMap<0x1::string::String, 0x2::coin_registry::ExtraField>","fields":{"contents":[]}},"icon_url":"https://www.walrus.xyz/wal-icon.svg","id":{"id":"0xb6a0c0bacb1c87c3be4dff20c22ef1012125b5724b5b0ff424f852a2651b23fa"},"metadata_cap_id":{"type":"0x2::coin_registry::MetadataCapState","variant":"Unclaimed","fields":{}},"name":"WAL Token","regulated":{"type":"0x2::coin_registry::RegulatedState","variant":"Unknown","fields":{}},"supply":{"type":"0x2::coin_registry::SupplyState<0x356a26eb9e012a68958082340d4c4116e7f55615cf27affcff209cf0ae544f59::wal::WAL>","variant":"Unknown","fields":{}},"symbol":"WAL","treasury_cap_id":null}}}}}
```

### sui_getObject (beautified)

```json
{
  "jsonrpc": "2.0",
  "id": 1,
  "result": {
    "data": {
      "objectId": "0xb6a0c0bacb1c87c3be4dff20c22ef1012125b5724b5b0ff424f852a2651b23fa",
      "version": "749938931",
      "digest": "HKBRwU88pCQK75sRM5kSB2pHut57f2wotA234wyYTsxL",
      "type": "0x2::coin_registry::Currency<0x356a26eb9e012a68958082340d4c4116e7f55615cf27affcff209cf0ae544f59::wal::WAL>",
      "content": {
        "dataType": "moveObject",
        "type": "0x2::coin_registry::Currency<0x356a26eb9e012a68958082340d4c4116e7f55615cf27affcff209cf0ae544f59::wal::WAL>",
        "hasPublicTransfer": false,
        "fields": {
          "decimals": 9,
          "description": "The native token for the Walrus Protocol.",
          "extra_fields": {
            "type": "0x2::vec_map::VecMap<0x1::string::String, 0x2::coin_registry::ExtraField>",
            "fields": {
              "contents": []
            }
          },
          "icon_url": "https://www.walrus.xyz/wal-icon.svg",
          "id": {
            "id": "0xb6a0c0bacb1c87c3be4dff20c22ef1012125b5724b5b0ff424f852a2651b23fa"
          },
          "metadata_cap_id": {
            "type": "0x2::coin_registry::MetadataCapState",
            "variant": "Unclaimed",
            "fields": {}
          },
          "name": "WAL Token",
          "regulated": {
            "type": "0x2::coin_registry::RegulatedState",
            "variant": "Unknown",
            "fields": {}
          },
          "supply": {
            "type": "0x2::coin_registry::SupplyState<0x356a26eb9e012a68958082340d4c4116e7f55615cf27affcff209cf0ae544f59::wal::WAL>",
            "variant": "Unknown",
            "fields": {}
          },
          "symbol": "WAL",
          "treasury_cap_id": null
        }
      }
    }
  }
}
```

## NS (0x5145494a5f5100e645e4b0aa950fa6b68f614e8c59e17bc5ded3495123a79178::ns::NS)

### suix_getCoinMetadata (raw)

```json
{"jsonrpc":"2.0","id":1,"result":{"decimals":6,"name":"SuiNS Token","symbol":"NS","description":"The native token for the SuiNS Protocol.","iconUrl":"https://token-image.suins.io/icon.svg","id":"0x279adec041f8ec5c2d419abf2c32713ae7930a9a3a1ff244c88e5ceced40db6e"}}
```

### suix_getCoinMetadata (beautified)

```json
{
  "jsonrpc": "2.0",
  "id": 1,
  "result": {
    "decimals": 6,
    "name": "SuiNS Token",
    "symbol": "NS",
    "description": "The native token for the SuiNS Protocol.",
    "iconUrl": "https://token-image.suins.io/icon.svg",
    "id": "0x279adec041f8ec5c2d419abf2c32713ae7930a9a3a1ff244c88e5ceced40db6e"
  }
}
```

## metadata id 0x279adec041f8ec5c2d419abf2c32713ae7930a9a3a1ff244c88e5ceced40db6e

### sui_getObject (raw)

```json
{"jsonrpc":"2.0","id":1,"result":{"data":{"objectId":"0x279adec041f8ec5c2d419abf2c32713ae7930a9a3a1ff244c88e5ceced40db6e","version":"265050737","digest":"3QaTE8GvMuS3mD3PfwVKgNs16zCEmxCUwLgVxCmhkyqZ","type":"0x2::coin::CoinMetadata<0x5145494a5f5100e645e4b0aa950fa6b68f614e8c59e17bc5ded3495123a79178::ns::NS>","content":{"dataType":"moveObject","type":"0x2::coin::CoinMetadata<0x5145494a5f5100e645e4b0aa950fa6b68f614e8c59e17bc5ded3495123a79178::ns::NS>","hasPublicTransfer":true,"fields":{"decimals":6,"description":"The native token for the SuiNS Protocol.","icon_url":"https://token-image.suins.io/icon.svg","id":{"id":"0x279adec041f8ec5c2d419abf2c32713ae7930a9a3a1ff244c88e5ceced40db6e"},"name":"SuiNS Token","symbol":"NS"}}}}}
```

### sui_getObject (beautified)

```json
{
  "jsonrpc": "2.0",
  "id": 1,
  "result": {
    "data": {
      "objectId": "0x279adec041f8ec5c2d419abf2c32713ae7930a9a3a1ff244c88e5ceced40db6e",
      "version": "265050737",
      "digest": "3QaTE8GvMuS3mD3PfwVKgNs16zCEmxCUwLgVxCmhkyqZ",
      "type": "0x2::coin::CoinMetadata<0x5145494a5f5100e645e4b0aa950fa6b68f614e8c59e17bc5ded3495123a79178::ns::NS>",
      "content": {
        "dataType": "moveObject",
        "type": "0x2::coin::CoinMetadata<0x5145494a5f5100e645e4b0aa950fa6b68f614e8c59e17bc5ded3495123a79178::ns::NS>",
        "hasPublicTransfer": true,
        "fields": {
          "decimals": 6,
          "description": "The native token for the SuiNS Protocol.",
          "icon_url": "https://token-image.suins.io/icon.svg",
          "id": {
            "id": "0x279adec041f8ec5c2d419abf2c32713ae7930a9a3a1ff244c88e5ceced40db6e"
          },
          "name": "SuiNS Token",
          "symbol": "NS"
        }
      }
    }
  }
}
```

## BLUE (0xe1b45a0e641b9955a20aa0ad1c1f4ad86aad8afb07296d4085e349a50e90bdca::blue::BLUE)

### suix_getCoinMetadata (raw)

```json
{"jsonrpc":"2.0","id":1,"result":{"decimals":9,"name":"Bluefin","symbol":"BLUE","description":"BLUE is the native token of Bluefin","iconUrl":"https://bluefin.io/images/square.png","id":"0xf6d6cc0f3f0e6e838340c263d1cebb0529c4371913dc5139c1897388cc86977f"}}
```

### suix_getCoinMetadata (beautified)

```json
{
  "jsonrpc": "2.0",
  "id": 1,
  "result": {
    "decimals": 9,
    "name": "Bluefin",
    "symbol": "BLUE",
    "description": "BLUE is the native token of Bluefin",
    "iconUrl": "https://bluefin.io/images/square.png",
    "id": "0xf6d6cc0f3f0e6e838340c263d1cebb0529c4371913dc5139c1897388cc86977f"
  }
}
```

## metadata id 0xf6d6cc0f3f0e6e838340c263d1cebb0529c4371913dc5139c1897388cc86977f

### sui_getObject (raw)

```json
{"jsonrpc":"2.0","id":1,"result":{"data":{"objectId":"0xf6d6cc0f3f0e6e838340c263d1cebb0529c4371913dc5139c1897388cc86977f","version":"304079199","digest":"Ca5nD5XVujVu63Wkj1nRiwfh3KUT3db5xZrSomqbKCbC","type":"0x2::coin::CoinMetadata<0xe1b45a0e641b9955a20aa0ad1c1f4ad86aad8afb07296d4085e349a50e90bdca::blue::BLUE>","content":{"dataType":"moveObject","type":"0x2::coin::CoinMetadata<0xe1b45a0e641b9955a20aa0ad1c1f4ad86aad8afb07296d4085e349a50e90bdca::blue::BLUE>","hasPublicTransfer":true,"fields":{"decimals":9,"description":"BLUE is the native token of Bluefin","icon_url":"https://bluefin.io/images/square.png","id":{"id":"0xf6d6cc0f3f0e6e838340c263d1cebb0529c4371913dc5139c1897388cc86977f"},"name":"Bluefin","symbol":"BLUE"}}}}}
```

### sui_getObject (beautified)

```json
{
  "jsonrpc": "2.0",
  "id": 1,
  "result": {
    "data": {
      "objectId": "0xf6d6cc0f3f0e6e838340c263d1cebb0529c4371913dc5139c1897388cc86977f",
      "version": "304079199",
      "digest": "Ca5nD5XVujVu63Wkj1nRiwfh3KUT3db5xZrSomqbKCbC",
      "type": "0x2::coin::CoinMetadata<0xe1b45a0e641b9955a20aa0ad1c1f4ad86aad8afb07296d4085e349a50e90bdca::blue::BLUE>",
      "content": {
        "dataType": "moveObject",
        "type": "0x2::coin::CoinMetadata<0xe1b45a0e641b9955a20aa0ad1c1f4ad86aad8afb07296d4085e349a50e90bdca::blue::BLUE>",
        "hasPublicTransfer": true,
        "fields": {
          "decimals": 9,
          "description": "BLUE is the native token of Bluefin",
          "icon_url": "https://bluefin.io/images/square.png",
          "id": {
            "id": "0xf6d6cc0f3f0e6e838340c263d1cebb0529c4371913dc5139c1897388cc86977f"
          },
          "name": "Bluefin",
          "symbol": "BLUE"
        }
      }
    }
  }
}
```
