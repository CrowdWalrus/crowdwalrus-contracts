# Last Deployment

## Deployment Information

**Command:** `sui client publish`

**Transaction Digest:** `3NfVTJ41pTeUqxNZBNB4wPWRCmF6z3mi9bvkNJjzuHbx`

**Status:** ✅ Success

**Epoch:** 884

**Deployer Address:** `0x4fcb599f85adb345fd608c69040615caa7af84ec8bbf181569a4dbe7368acfbb`

---

## Package Information

**Package ID:** `0x7c0e35909394908e79505a301860db084fa0a0d2eace8496528da995e7de3a64`

**Version:** 1

**Digest:** `6WyMXebsxtPX7ACWzLZ1kpbaBBGVKpc7neuwVQZg9MkM`

**Modules:** `campaign`, `crowd_walrus`, `suins_manager`

---

## Created Objects

### 1. SuiNS Manager AdminCap
- **ObjectID:** `0x1917949fab2d395c2de12e183085f9776aac1a8e9e3db6c8cd4871440d4bd432`
- **Type:** `suins_manager::AdminCap`
- **Owner:** Account Address (deployer)
- **Version:** 600620702
- **Digest:** `D1rmiPkKAqFaaErqM86Etgxa8AuGu6Mj4rdvQdZBNZoF`

### 2. Package UpgradeCap
- **ObjectID:** `0x57d40fa326079150740922142c4d0133aa78c40566b5a847a636a512481e6906`
- **Type:** `0x2::package::UpgradeCap`
- **Owner:** Account Address (deployer)
- **Version:** 600620702
- **Digest:** `HFvKPytqsZgxVwPL3wUTqYbNnmBydtTG1Ko86PqVCq1t`

### 3. SuiNSManager (Shared Object)
- **ObjectID:** `0x8a0b7028dcff9b0a263971caad0716cd8f295f2fc830ef72e1c0f68a42675c01`
- **Type:** `suins_manager::SuiNSManager`
- **Owner:** Shared (600620702)
- **Version:** 600620702
- **Digest:** `GF3WfLduJ6bjVddxwLDT6DbMN2UXMBFBLSsU622jZxQr`

### 4. CrowdWalrus App Authorization Dynamic Field
- **ObjectID:** `0xd18157dc539e6242710086c2e3224b17d36f7b643961e9f1300d215da280c235`
- **Type:** `dynamic_field::Field<AppKey<CrowdWalrusApp>, bool>`
- **Owner:** Object ID (SuiNSManager)
- **Version:** 600620702
- **Digest:** `4e3h8oiWrf3N5s1xCmLjQpsHRYrmdiiKG2pHMVsgnSR5`

### 5. CrowdWalrus AdminCap
- **ObjectID:** `0xe6a3321787aa59bc40eaffd38a16ab4ee50f0128a561c2fc8917c5f534beed73`
- **Type:** `crowd_walrus::AdminCap`
- **Owner:** Account Address (deployer)
- **Version:** 600620702
- **Digest:** `D6n9ZXBJJPzbTXdDcyPLdBA6A1CduP63qUVbV66N2YPu`

### 6. CrowdWalrus Platform (Shared Object)
- **ObjectID:** `0xf7f40450c3d5adabac7232e97320039bd94f19b8c3b664c90893b514cac4226f`
- **Type:** `crowd_walrus::CrowdWalrus`
- **Owner:** Shared (600620702)
- **Version:** 600620702
- **Digest:** `Cfm7CDkQxaY8JFyeDd6ijwkncV6tpumv2SZvvjPqkEbf`

---

## Events Emitted

### Event 1: AdminCreated (CrowdWalrus)
- **EventID:** `3NfVTJ41pTeUqxNZBNB4wPWRCmF6z3mi9bvkNJjzuHbx:0`
- **EventType:** `crowd_walrus::AdminCreated`
- **Data:**
  - `admin_id`: `0xe6a3321787aa59bc40eaffd38a16ab4ee50f0128a561c2fc8917c5f534beed73`
  - `creator`: `0x4fcb599f85adb345fd608c69040615caa7af84ec8bbf181569a4dbe7368acfbb`
  - `crowd_walrus_id`: `0xf7f40450c3d5adabac7232e97320039bd94f19b8c3b664c90893b514cac4226f`

### Event 2: SuiNSManagerCreated
- **EventID:** `3NfVTJ41pTeUqxNZBNB4wPWRCmF6z3mi9bvkNJjzuHbx:1`
- **EventType:** `suins_manager::SuiNSManagerCreated`
- **Data:**
  - `creator`: `0x4fcb599f85adb345fd608c69040615caa7af84ec8bbf181569a4dbe7368acfbb`
  - `suins_manager_id`: `0x8a0b7028dcff9b0a263971caad0716cd8f295f2fc830ef72e1c0f68a42675c01`

### Event 3: AdminCreated (SuiNS Manager)
- **EventID:** `3NfVTJ41pTeUqxNZBNB4wPWRCmF6z3mi9bvkNJjzuHbx:2`
- **EventType:** `suins_manager::AdminCreated`
- **Data:**
  - `admin_id`: `0x1917949fab2d395c2de12e183085f9776aac1a8e9e3db6c8cd4871440d4bd432`
  - `creator`: `0x4fcb599f85adb345fd608c69040615caa7af84ec8bbf181569a4dbe7368acfbb`
  - `suins_manager_id`: `0x8a0b7028dcff9b0a263971caad0716cd8f295f2fc830ef72e1c0f68a42675c01`

---

## Gas Cost Summary

- **Storage Cost:** 91,952,400 MIST (0.0919524 SUI)
- **Computation Cost:** 2,000,000 MIST (0.002 SUI)
- **Storage Rebate:** 978,120 MIST (0.00097812 SUI)
- **Non-refundable Storage Fee:** 9,880 MIST (0.00000988 SUI)
- **Total Cost:** 92,974,280 MIST (0.09297428 SUI)

---

## Package Dependencies

The package was published with the following dependencies:

1. **MoveStdlib** - `0x0000000000000000000000000000000000000000000000000000000000000001`
2. **Sui Framework** - `0x0000000000000000000000000000000000000000000000000000000000000002`
3. **SuiNS Core** - `0xa86c05fbc6371788eb31260dc5085f4bfeab8b95c95d9092c9eb86e63fae3d49`
4. **Subdomains** - `0x3c272bc45f9157b7818ece4f7411bdfa8af46303b071aca4e18c03119c9ff636`
5. **Denylist** - `0x67072134f0867b886c9541873d1cb327feb7e161cd56dd76cb6aa9e464410db1`

---

## Build Warnings/Notes

- ⚠️ **API Version Mismatch:** Client version 1.57.0, Server version 1.58.1
- ℹ️ **Dependency Verification:** Sources are not verified automatically. Use `--verify-deps` to verify.
- ℹ️ **Move.toml Note:** Dependencies on Bridge, MoveStdlib, Sui, and SuiSystem are auto-added but disabled because Sui is explicitly included.

---

## Quick Reference

### Key Object IDs for Interaction

```bash
# Package ID (use in Move.toml)
PACKAGE_ID="0x7c0e35909394908e79505a301860db084fa0a0d2eace8496528da995e7de3a64"

# Shared Objects (required for transactions)
CROWD_WALRUS="0xf7f40450c3d5adabac7232e97320039bd94f19b8c3b664c90893b514cac4226f"
SUINS_MANAGER="0x8a0b7028dcff9b0a263971caad0716cd8f295f2fc830ef72e1c0f68a42675c01"

# Admin Capabilities (owned by deployer)
CROWD_WALRUS_ADMIN="0xe6a3321787aa59bc40eaffd38a16ab4ee50f0128a561c2fc8917c5f534beed73"
SUINS_MANAGER_ADMIN="0x1917949fab2d395c2de12e183085f9776aac1a8e9e3db6c8cd4871440d4bd432"
UPGRADE_CAP="0x57d40fa326079150740922142c4d0133aa78c40566b5a847a636a512481e6906"
```

### Update Move.toml

After this deployment, update your [Move.toml](Move.toml) file:

```toml
[addresses]
crowd_walrus = "0x7c0e35909394908e79505a301860db084fa0a0d2eace8496528da995e7de3a64"
```
