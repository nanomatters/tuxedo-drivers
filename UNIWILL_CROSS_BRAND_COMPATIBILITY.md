# Uniwill Cross-Brand Compatibility Findings

**Last Updated:** February 9, 2026

## Overview

Uniwill (Tsinghua Tongfang) is a Chinese ODM (Original Design Manufacturer) that designs and manufactures laptop barebones sold to multiple brands worldwide. This document tracks DMI (Desktop Management Interface) board names, SKUs, and device features that are shared across brands, enabling the tuxedo-drivers kernel module to support hardware from various vendors.

### DMI Matching Strategy

- **DMI_BOARD_NAME**: Set by the ODM in firmware; identical across all brands using the same barebone
- **DMI_PRODUCT_SKU**: Typically vendor-specific; TUXEDO customizes this for their models
- **DMI_SYS_VENDOR**: Also vendor-specific; may be "TUXEDO", "SchenkerTechnologiesGmbH", "NB02", etc.
- **DMI_PRODUCT_NAME**: Can be either vendor-specific or unique identifier for QC71 variants

The driver uses `dmi_match()` to identify hardware capabilities and enable/disable features accordingly.

---

## Key Research Findings

### 1. Tongfang Naming Conventions

Tongfang uses a consistent naming scheme for their board identifiers:

| Pattern | Meaning | Example |
|---------|---------|---------|
| `GMx` | Gaming-Master category | `GMxHGxx`, `GMxNGxx`, `GMxXGxx` |
| `x` (position 3-4) | Screen size placeholder (5=15.6", 7=17.3") | `GM5IXxA`, `GM7IXxN` |
| Two-letter code | Platform/generation identifier | `HG`, `NG`, `XG`, `RG`, `TG`, `ZG` |
| `xx` (suffix) | Variant/configuration placeholder | Usually lowercase 'x' for wildcards |
| `GX` | InfinityBook Pro (Gen9+) | `GXxMRXx`, `GXxHRXx` |
| `PH` | InfinityBook Thin-and-Light (Gen6-8) | `PHxTxX1`, `PHxARX1_PHxAQF1`, `PH4PRX1_PH6PRX1` |
| `X` | InfinityBook Max + Stellaris Gen7-10 | `X6AR5xxY`, `X5KK45xS_X5SP45xS` |
| `POLARIS`/`PULSE` | Polaris/Pulse product lines | `POLARIS1501A1650TI`, `PULSE1401` |
| `TRINITY` | Trinity product line (Intel only) | `TRINITY1501I`, `TRINITY1701I` |

### 2. Wildcard vs Concrete Board Names

**TUXEDO/NB02 approach** (tuxedo-drivers, upstream kernel):
- Uses **wildcard patterns** with placeholder 'x' characters
- Example: `GMxHGxx` matches any concrete instance like `GM5HG0A`, `GM5HG5A`, `GM5HG7A`
- Enables support for multiple variants with single DMI entry
- Used in driver code via `dmi_match(DMI_BOARD_NAME, "GMxHGxx")`

**Brand-specific approach** (XMG, Schenker, others):
- Original Tongfang hardware may use **concrete board names** (specific variant codes)
- Different brands may flash different board names even on same physical hardware
- Covered by upstream kernel quirks in `acpi/resource.c`, `i8042-acpipnpio.h` (no vendor filter)

### 3. Vendor Identification in Firmware

| Vendor String | Device | Notes |
|---------------|--------|-------|
| `TUXEDO` | All TUXEDO models | sys_vendor field |
| `SchenkerTechnologiesGmbH` | XMG/Schenker models | sys_vendor field; also cross-checks board_name |
| `NB02` | Newer Uniwill (post-Gen9) | board_vendor field; indicates TUXEDO-owned barebone |
| `Intel(R) Client Systems` | Intel NUC x15 | sys_vendor; QC71 whitebook variant |
| `TongFang` | Raw ODM hardware | Appears in linux-hardware.org probes |
| `AiStone` | Third-party rebrand | Minor vendor for Xx-NAx series |

See [tuxedo_compatibility_check.c](#) for compatibility check logic (allows TUXEDO, SchenkerTechnologiesGmbH, NB02, and specific CPU families).

### 4. QC71 Whitebook Equivalence

**Intel QC71 Whitebook** platform (@brief: Open platform from Intel, designed for Tongfang to manufacture):

| Board Name(s) | Brand | Model | Region |
|---|---|---|---|
| `LAPQC71A` | Schenker/XMG | XMG Fusion 15 | Germany/EU |
| `LAPQC71B` | Schenker/XMG | XMG Fusion 15 (board variant) | Germany/EU |
| `LAPAC71H` | Intel | Intel NUC x15 | Global |
| `LAPKC71F` | Intel | Intel NUC x15 (lightbar variant) | Global |
| `A60 MUV` | Avell | Avell A60 MUV (Brazil) | Brazil |
| (across GK5NR0O/GK7NR0R) | Eluktronics | Eluktronics MAG-15 | USA |
| (across GK5NR0O/GK7NR0R) | Aftershock | Aftershock Vapor 15 | Singapore/SEA |

**Features:**
- Lightbar support on `LAPKC71F` variant only
- FN lock **NOT** supported on any LAPQC71*/A60 MUV variants (excluded in `uniwill_fn_lock_available()`)
- Charging profile **NOT** supported (excluded in `uw_has_charging_profile()`)

---

## Board Name Catalog

### InfinityBook Pro (IBP) Series

#### Gen6 (Intel 10th/11th Gen)
| Board Name | Variants | TUXEDO Model | Features | Notes |
|---|---|---|---|---|
| `PHxTxX1` | `PH4TRX1`, `PH4TUX1` | IBP 14/16 Gen6 | Standard | Baseline Gen6 |
| `PHxTQx1` | `PH4TQx1`, `PH4TQF` | IBP 14 Gen6 | Standard | **[Added Feb 2026]** Variant alongside PHxTxX1 |

#### Gen7 (Intel 11th/12th Gen)
| Board Name | Variants | TUXEDO Model | Features | Notes |
|---|---|---|---|---|
| `PHxARX1_PHxAQF1` | `PH4ARx1`, `PH6AQx1` | IBP 14/16 Gen7 | Standard | Combined 14"/16" |
| `PH6AG01_PH6AQ71_PH6AQI1` | Variants | IBP 16 Gen7 | Standard | 16" specific, multiple board revisions |

#### Gen8 (Intel 12th/13th Gen)
| Board Name | Variants | TUXEDO Model | Features | Notes |
|---|---|---|---|---|
| `PH4PRX1_PH6PRX1` | `PH4PR*`, `PH6PR*` | IBP 14/16 Gen8 | Charging Priority | Combined 14"/16" with charging priority support |
| `PH6PG01_PH6PG71` | Variants | IBP 16 Gen8 | Charging Priority | 16" specific |
| `PH4PG31` | — | IBP 14 Gen8 | Charging Priority | 14" specific |

#### Gen9 (AMD Ryzen 6000H/8000HS, Intel 12th/13th Gen)
| Board Name | Variants | TUXEDO Model | Features | Notes |
|---|---|---|---|---|
| `GXxHRXx` | `GX4HRXL`, `GX5HRXG`, `GX5HRXL` | IBP 14/15 Gen9 AMD | — | AMD variant; wildcard pattern |
| `GXxMRXx` | `GX4MRXL`, `GX5MRXL` | IBP 14/15 Gen9 Intel / Commodore Omnia-Book 15 Gen9 | — | Intel variant; wildcard pattern |

#### Gen10 (AMD Ryzen AI 300 / Intel Core Ultra 200H)
| Board Name | Variants | TUXEDO Model | Features | Notes |
|---|---|---|---|---|
| `XxHP4NAx` | `X5HP4NAG`, `X4HP4NAL` | IBP 14/15 Gen10 AMD | TDP, Auto Boot, PowerShare | Wildcard pattern; 14"/15" share board name; TDP uses conservative 14" values (25/35/65W) **[TDP added Feb 2026]** |
| `XxKK4NAx_XxSP4NAx` | `X4KK4NAL`, `X5SP4NAG` | IBP 14/15 Gen10 AMD | TDP, Auto Boot, PowerShare | Dual variant (KK/SP); MECHREVO Wujie uses X5SP4NAG; same conservative TDP **[TDP added Feb 2026]** |
| `XxAR4NAx` | — | IBP 15 Gen10 Intel | TDP, Auto Boot, PowerShare | Intel-only 15" board; TDP 35/45/90W **[TDP added Feb 2026]** |

### InfinityBook Max Series

#### Gen10 (AMD Ryzen 7000H/8000HS, Intel 13th/14th Gen)
| Board Name | Variants | TUXEDO Model | Features | Notes |
|---|---|---|---|---|
| `X5KK45xS_X5SP45xS` | — | Max 15 Gen10 AMD | Auto Boot + PowerShare | Already in code |
| `X6HP45xU` | — | Max 16 Gen10 AMD | Auto Boot + PowerShare | **[Added Feb 2026]** 16" AMD variant |
| `X6KK45xU_X6SP45xU` | — | Max 16 Gen10 AMD | Auto Boot + PowerShare | **[Added Feb 2026]** 16" AMD variant (dual) |
| `X6AR55xU` | — | Max 16 Gen10 Intel | Auto Boot + PowerShare | **[Added Feb 2026]** 16" Intel variant |
| `X5AR45xS` | — | Max 15 Gen10 Intel | Auto Boot + PowerShare | **[Added Feb 2026]** 15" Intel variant |

### Polaris/Stellaris Series (Gen2-5)

#### Gen2 (2021, Intel 11th Gen / AMD Zen 3)
| Board Name | TUXEDO Model(s) | Features | Naming |
|---|---|---|---|
| `GMxMGxx` | Polaris 15/17 Gen2 (Intel) | Charging Priority | Wildcard: M=Intel |
| `GMxNGxx` | Polaris 15/17 Gen2 (AMD) | Charging Priority | Wildcard: N=AMD |

#### Gen3 (2021-2022, Intel 12th Gen / AMD Zen 3+)
| Board Name | TUXEDO Model(s) | Features | Naming |
|---|---|---|---|
| `GMxTGxx` | Polaris/Stellaris 15/17 Gen3 (Intel) | Charging Priority | Wildcard: T=Intel |
| `GMxZGxx` | Stellaris 15/17 Gen3 (AMD) | Charging Priority | Wildcard: Z=AMD |

#### Gen4 (2022-2023, Intel 12th Gen Tiger Lake / AMD Zen 4)
| Board Name | TUXEDO Model(s) | Features | Naming | Notes |
|---|---|---|---|---|
| `GMxRGxx` | Stellaris/Polaris 15/17 Gen4 AMD | Charging Priority | Wildcard: R=AMD | **[Added Feb 2026]** Upstream kernel has this |
| `GMxAGxx` | Stellaris 15 Gen4 (Intel) | Charging Priority | Wildcard: A=Intel | **[Added Feb 2026]** Upstream kernel has this |

#### Gen5 (2023, AMD Ryzen 7000H)
| Board Name | TUXEDO Model(s) | Features | Naming |
|---|---|---|---|
| `GMxXGxx` | Polaris 15/17 Gen5 AMD | Charging Priority | Wildcard: X=AMD (Polaris) |
| `GM6XGxX` | Stellaris 16 Gen5 AMD | Charging Priority | Variant suffix: capital X |

### Polaris Gen1 (2021, AMD Ryzen 4000H / NVIDIA RTX 2060/GTX 1650 Ti)

| Board Name | Size | CPU | GPU | Features |
|---|---|---|---|---|
| `POLARIS1501A1650TI` | 15" | AMD | GTX 1650 Ti | Charging Priority |
| `POLARIS1501A2060` | 15" | AMD | RTX 2060 | Charging Priority |
| `POLARIS1501I1650TI` | 15" | Intel | GTX 1650 Ti | Charging Priority |
| `POLARIS1501I2060` | 15" | Intel | RTX 2060 | Charging Priority |
| `POLARIS1701A1650TI` | 17" | AMD | GTX 1650 Ti | Charging Priority |
| `POLARIS1701A2060` | 17" | AMD | RTX 2060 | Charging Priority |
| `POLARIS1701I1650TI` | 17" | Intel | GTX 1650 Ti | Charging Priority |
| `POLARIS1701I2060` | 17" | Intel | RTX 2060 | Charging Priority |

**Cross-brand usage (via GK5NR0O/GK7NR0R Tongfang chassis):**
- XMG Core 15/17 (E20)
- Eluktronics RP-15/RP-17
- CyberpowerPC Tracer IV R
- PCSpecialist Optimus Pro 15/XI 17
- Hyperbook Pulsar Z15/Z17
- Mechrevo Jiaolong
- Illegear ONYX V Ryzen / ROGUE Ryzen
- And 12+ additional brands

### Stellaris Gen6 (Intel 12th/13th Gen)

| Board Name | Variants | TUXEDO Model | Features | Notes |
|---|---|---|---|---|
| `GM6IXxB_MB1` | — | Stellaris 16 Gen6 Intel | Standard | First motherboard revision |
| `GM6IXxB_MB2` | — | Stellaris 16 Gen6 Intel | Standard | Second motherboard revision |
| `GM7IXxN` | `GM7IX0N`, `GM7IX8N`, `GM7IX9N` | Stellaris 17 Gen6 Intel | Standard | 17" variant; wildcard pattern |
| `GM5IXxA` | `GM5IX0A` | Stellaris Slim 15 Gen6 Intel | Standard | Slim variant; wildcard pattern |
| `GMxHGxx` | `GM5HG0A`, `GM5HG5A`, `GM5HG7A` | Stellaris Slim 15 Gen6 AMD | Standard | Slim AMD variant; wildcard pattern |

**Note:** `GM6IXxB_MB1` and `GM6IXxB_MB2` represent different physical motherboard revisions, appearing concurrently in production.

### Stellaris Gen7 (AMD Ryzen 7000H, Intel 13th/14th Gen)

| Board Name | TUXEDO Model | Features | Notes |
|---|---|---|---|
| `X6AR5xxY` | Stellaris 16 Gen7 Intel | Standard | Wildcard pattern |
| `X6AR5xxY_mLED` | Stellaris 16 Gen7 Intel | Standard | Mini-LED display variant |
| `X6FR5xxY` | Stellaris 16 Gen7 AMD | Standard | Wildcard pattern |

### Pulse Series

| Board Name | TUXEDO Model | Features | Notes |
|---|---|---|---|
| `PULSE1401` | Pulse 14 Gen1 AMD | Charging Priority | 14" variant; Tongfang PF4NU1F |
| `PULSE1501` | Pulse 15 Gen1 AMD | Charging Priority | 15" variant; Tongfang PF5NU1G |
| `PF5LUXG` | Pulse 15 Gen2 AMD | Charging Priority | Gen2 refresh; Tongfang based |

**Cross-brand usage (via Tongfang PF4NU1F/PF5NU1G):**
- Schenker VIA 14/15 Pro
- Eluktronics THINN-15
- Mechrevo S2 Air (14")
- Slimbook Pro X 14/15
- Illegear Ionic 15 Ryzen
- And 10+ additional brands

### Book/BA Series

| Board Name | TUXEDO Model | Features | Notes |
|---|---|---|---|
| `PF5PU1G` | Book BA15 Gen10 AMD | Standard | TUXEDO-specific variant of PF5NU1G |

### Trinity Series (Intel-Only)

| Board Name | TUXEDO Model | Features | Notes |
|---|---|---|---|
| `TRINITY1501I` | Trinity 15 Intel Gen1 | Lightbar | 15" variant; TUXEDO-exclusive (no other brands found) |
| `TRINITY1701I` | Trinity 17 Intel Gen1 | Lightbar | 17" variant; TUXEDO-exclusive |

---

## Product SKU Catalog

SKUs are TUXEDO-specific product identifiers set during manufacturing. They map to board names for TDP (Thermal Design Power) configuration.

### Polaris Gen2-3
| SKU | Board Name | TUXEDO Model | VRM Config |
|---|---|---|---|
| `POLARIS1XI02` | `GMxMGxx` | Polaris Gen2 Intel | Intel 11th Gen |
| `POLARIS1XA02` | `GMxNGxx` | Polaris Gen2 AMD | AMD Zen 3 |
| `POLARIS1XI03` | `GMxTGxx` | Polaris/Stellaris Gen3 Intel | Intel 12th Gen |
| `STELLARIS1XI03` | `GMxTGxx` | Stellaris Gen3 Intel | Intel 12th Gen |
| `POLARIS1XA03` | `GMxZGxx` | Polaris Gen3 AMD | AMD Zen 3+ |
| `STELLARIS1XA03` | `GMxZGxx` | Stellaris Gen3 AMD | AMD Zen 3+ |

### Polaris/Stellaris Gen4-5
| SKU | Board Name | TUXEDO Model | VRM Config |
|---|---|---|---|
| `STELLARIS1XI04` | `GMxAGxx` | Stellaris Gen4 Intel | Intel 12th Gen |
| `STEPOL1XA04` | `GMxRGxx` | Stellaris/Polaris Gen4 AMD | AMD Zen 4 |
| `STELLARIS1XI05` | `GMxPXxx` | Stellaris Gen5 Intel | Intel 13th Gen |
| `POLARIS1XA05` | `GMxXGxx` | Polaris Gen5 AMD | AMD Ryzen 7000H |
| `STELLARIS1XA05` | `GMxXGxx` | Stellaris Gen5 AMD | AMD Ryzen 7000H |

### Stellaris Gen6-7
| SKU | Board Name | TUXEDO Model | Features |
|---|---|---|---|
| `STELLARIS16I06` | `GM6IXxB_MB1`, `GM6IXxB_MB2` | Stellaris 16 Gen6 Intel | TDP dual motherboard rev |
| `STELLARIS17I06` | `GM7IXxN` | Stellaris 17 Gen6 Intel | — |
| `STELLSL15I06` | `GM5IXxA` | Stellaris Slim 15 Gen6 Intel | — |
| `STELLSL15A06` | `GMxHGxx` | Stellaris Slim 15 Gen6 AMD | — |
| `STELLARIS16I07` | `X6AR5xxY` | Stellaris 16 Gen7 Intel | — |
| `STELLARIS16A07` | `X6FR5xxY` | Stellaris 16 Gen7 AMD | — |

### InfinityBook Pro Gen7-8
| SKU | TUXEDO Model | Features |
|---|---|---|
| `IBP1XI07MK1` | IBP 14/16 Gen7 Intel MK1 | — |
| `IBP1XI07MK2` | IBP 14/16 Gen7 Intel MK2 | — |
| `IBP1XI08MK1` | IBP 14/16 Gen8 Intel MK1 | — |
| `IBP1XI08MK2` | IBP 14/16 Gen8 Intel MK2 | — |
| `IBP14I08MK2` | IBP 14 Gen8 Intel MK2 | — |
| `IBP16I08MK2` | IBP 16 Gen8 Intel MK2 | — |
| `OMNIA08IMK2` | Commodore Omnia variant Gen8 | — |

### XMG NEO (Likely Cross-Brand Collaboration)
| SKU | Board Name (assumed) | Notes |
|---|---|---|
| `XNE16E25` | `X6AR5xxY` (TDP equivalent) | XMG NEO 16 Intel Gen7 = Stellaris 16 Gen7 Intel |
| `XNE16A25` | `X6FR5xxY` (TDP equivalent) | XMG NEO 16 AMD Gen7 = Stellaris 16 Gen7 AMD |

**Note:** XMG NEO SKUs don't follow TUXEDO naming (`STELLARIS`, `POLARIS`, etc.) yet use identical TDP profiles as Stellaris 16 Gen7, suggesting potential XMG-specific SKU assignment for the same hardware.

### XMG EVO (= TUXEDO InfinityBook Pro Gen10) **[Added Feb 2026]**
| SKU | Board Name (assumed) | TUXEDO Equivalent | Notes |
|---|---|---|---|
| `XEV15AE25` | `XxHP4NAx` or `XxKK4NAx_XxSP4NAx` | IBP Pro 15 Gen10 AMD | XMG EVO 15 (E25); SKU: XEV=EVO, 15=size, A=AMD, E25=2025 |
| `XEV14AE25` *(presumed)* | `XxHP4NAx` or `XxKK4NAx_XxSP4NAx` | IBP Pro 14 Gen10 AMD | XMG EVO 14 (E25); not yet confirmed in DMI dumps |
| `XEV15ME25` *(presumed)* | `XxAR4NAx` | IBP Pro 15 Gen10 Intel | XMG EVO 15 (M25); Intel-only 15" variant |

**Key facts:**
- XMG EVO 15 (E25) = TUXEDO InfinityBook Pro 15 Gen10 AMD: same dimensions (15.3", 1.75 kg), battery (99.8 Wh), CPUs (Ryzen AI 7/9), cooling (90W), aluminum chassis
- XMG EVO 14 (E25) = TUXEDO IBP Pro 14 Gen10 AMD: 14.0", 80 Wh battery, 65W cooling capacity
- XMG EVO 15 (M25) = TUXEDO IBP Pro 15 Gen10 Intel: Intel Core Ultra 7 255H only, 240Hz panel
- `XEV15AE25` added to `uw_id_tdp()` with 15" AMD TDP (25/35/90W) — overrides conservative board_name match

### Pulse/Book Series
| SKU | Board Name | TUXEDO Model |
|---|---|---|
| `PULSE1502` | `PF5LUXG` | Pulse 15 Gen2 AMD |

### InfinityBook Max Gen10
These entries use board_name matching instead of SKU matching (lack of Gen10 SKU entries in table).

---

## Feature Support Matrix

### Charging Priority
**Devices supporting this feature** (checked in `uw_has_charging_priority()`):

**Included:**
- IBP Gen6-8 (all variants): `PHxTxX1`, `PHxTQx1`, `PHxARX1_PHxAQF1`, `PH6AG01_PH6AQ71_PH6AQI1`, `PH4PRX1_PH6PRX1`, `PH6PG01_PH6PG71`, `PH4PG31`
- Polaris Gen1: All 8 variants (`POLARIS1*`)
- Polaris/Stellaris Gen2-5: `GMxMGxx`, `GMxNGxx`, `GMxRGxx`, `GMxAGxx`, `GMxTGxx`, `GMxZGxx`, `GMxXGxx`
- Pulse Gen1-2: `PULSE1401`, `PULSE1501`, `PF5LUXG`

**Not Supported:**
- QC71 variants (XMG Fusion, Intel NUC, Avell A60)
- InfinityBook Gen9-10
- Trinity (only Lightbar support)
- Stellaris Slim Gen6

### Charging Profile
**Devices NOT supporting** (excluded in `uw_has_charging_profile()`):
- `PF5PU1G` (TUXEDO Book BA15)
- `LAPQC71A`, `LAPQC71B` (XMG Fusion, QC71 variants)
- `LAPAC71H`, `LAPKC71F` (Intel NUC x15) **[Added Feb 2026]**
- `A60 MUV` (Avell, QC71 variant)

### Lightbar Support
**Devices supporting** (checked in `uw_lightbar_init()`):
- `LAPQC71A`, `LAPQC71B` (XMG Fusion)
- `LAPKC71F` (Intel NUC x15) **[Added Feb 2026]**
- `TRINITY1501I`, `TRINITY1701I` (TUXEDO Trinity)
- `A60 MUV` (Avell A60)
- SKUs: `STELLARIS1XI03`, `STELLARIS1XA03`, `STELLARIS1XI04`, `STEPOL1XA04` (Stellaris Gen3-4)

### Auto Boot & PowerShare
**Devices supporting** (checked in `is_auto_boot_and_powershare_supported()`):
- IBP Gen9: `GXxMRXx`, `GXxHRXx`
- IBP Gen10: `XxHP4NAx`, `XxKK4NAx_XxSP4NAx`, `XxAR4NAx`
- Stellaris Gen6: `GM6IXxB_MB1`, `GM6IXxB_MB2`, `GM7IXxN`
- Stellaris Gen7: `X6AR5xxY`, `X6AR5xxY_mLED`, `X6FR5xxY`
- Stellaris Slim Gen6: `GMxHGxx`, `GM5IXxA`
- InfinityBook Max Gen10: `X5KK45xS_X5SP45xS`, `X6HP45xU`, `X6KK45xU_X6SP45xU`, `X6AR55xU`, `X5AR45xS` **[4 variants added Feb 2026]**

### FN Lock
**Devices NOT supporting** (excluded in `uniwill_fn_lock_available()`):
- `LAPQC71A`, `LAPQC71B` (XMG Fusion)
- `A60 MUV` (Avell)

---

## Changes Made (February 2026)

### 1. Added to `uw_lightbar_init()` - Line 486
```c
|| dmi_match(DMI_PRODUCT_NAME, "LAPKC71F") // Intel NUC x15 (QC71 variant with lightbar)
```
**Reason:** Intel NUC x15 configuration with lightbar confirmed in upstream `uniwill-acpi.c` (DMI_FEATURE_LIGHTBAR flag set).

### 2. Added to `uw_has_charging_profile()` - Lines 745-746
```c
|| dmi_match(DMI_PRODUCT_NAME, "LAPAC71H") // Intel NUC x15 (QC71 variant)
|| dmi_match(DMI_PRODUCT_NAME, "LAPKC71F") // Intel NUC x15 (QC71 variant)
```
**Reason:** Intel NUC x15 variants (both LAPAC71H and LAPKC71F) use the same QC71 Uniwill barebone as XMG Fusion (LAPQC71A/B) and Avell A60 MUV, which explicitly exclude charging profile support due to firmware differences.

### 3. Added to `uw_has_charging_priority()` - Lines 611-612, 616-617
```c
|| dmi_match(DMI_BOARD_NAME, "PHxTQx1") // IBP Gen6 (variant)
|| dmi_match(DMI_BOARD_NAME, "GMxRGxx") // Stellaris/Polaris Gen4 AMD
|| dmi_match(DMI_BOARD_NAME, "GMxAGxx") // Stellaris Gen4 Intel
```
**Reason:**
- `PHxTQx1`: IBP Gen6 variant present in upstream kernel alongside `PHxTxX1` but missing from tuxedo-drivers
- `GMxRGxx` and `GMxAGxx`: Gen4 Stellaris/Polaris boards present in upstream kernel but missing from tuxedo-drivers; fill generation gap between Gen3 (already present) and Gen5 (already present)

### 4. Added to `is_auto_boot_and_powershare_supported()` - Lines 980-983
```c
|| dmi_match(DMI_BOARD_NAME, "X6HP45xU")
|| dmi_match(DMI_BOARD_NAME, "X6KK45xU_X6SP45xU")
|| dmi_match(DMI_BOARD_NAME, "X6AR55xU")
|| dmi_match(DMI_BOARD_NAME, "X5AR45xS")
```
**Reason:** InfinityBook Max Gen10 platform expands to 16" Intel/AMD variants alongside already-listed 15" AMD variant (`X5KK45xS_X5SP45xS`). Feature support extends across entire product line.

### 5. Board_name fallbacks added to `ite_8291.c` `color_scaling()`

Added `DMI_BOARD_NAME` alternatives alongside existing `DMI_PRODUCT_SKU` matches to enable correct keyboard backlight color scaling on non-TUXEDO brands sharing the same Tongfang barebone:

| SKU Match | Board_name Fallback(s) Added | Generation |
|---|---|---|
| `STEPOL1XA04` | `GMxRGxx` | Stellaris/Polaris Gen4 AMD |
| `STELLARIS1XI05` | `GMxPXxx` | Stellaris Gen5 Intel |
| `STELLARIS1XA05` | `GMxXGxx`, `GM6XGxX` | Stellaris Gen5 AMD |
| `STELLARIS17I06` | `GM7IXxN` | Stellaris 17 Gen6 Intel |
| `STELLSL15I06` / `STELLARIS16I06` | `GM5IXxA`, `GM6IXxB_MB1`, `GM6IXxB_MB2` | Stellaris Gen6 Slim/16" Intel |
| Gen7 block | `X6AR5xxY`, `X6AR5xxY_mLED`, `X6FR5xxY` | Stellaris Gen7 Intel/AMD |

**Reason:** Without these fallbacks, XMG NEO, Mechrevo, PCSpecialist, and other brands sharing the same ITE8291 keyboard hardware would receive the generic default color scaling (green 126/255, blue 120/255) instead of the calibrated per-model scaling. Same physical hardware requires identical color correction.

### 6. Board_name fallbacks added to `ite_8291_lb.c` `color_scaling()`

| SKU Match | Board_name Fallback Added | Generation |
|---|---|---|
| `STEPOL1XA04` | `GMxRGxx` | Stellaris/Polaris Gen4 AMD |
| `STELLARIS1XI05` | `GMxPXxx` | Stellaris Gen5 Intel |
| `STELLARIS17I06` | `GM7IXxN` | Stellaris 17 Gen6 Intel |

**Reason:** Same rationale as ite_8291.c — lightbar color scaling must match hardware, not brand.

### 7. Board_name fallback block added to `tuxedo_io.c` `uw_id_tdp()`

Added 17 new `DMI_BOARD_NAME` fallback entries after existing `DMI_PRODUCT_SKU` entries. Placed at lower priority (end of if/else chain before `#endif`) so TUXEDO and XMG SKU matches take precedence.

| Board_name | TDP Array | Corresponding SKU(s) |
|---|---|---|
| `PF5LUXG` | `tdp_*_pfxluxg` | `PULSE1502` |
| `GMxNGxx` | `tdp_*_gmxngxx` | `POLARIS1XA02` |
| `GMxMGxx` | `tdp_*_gmxmgxx` | `POLARIS1XI02` |
| `GMxTGxx` | `tdp_*_gmxtgxx` | `POLARIS1XI03` / `STELLARIS1XI03` |
| `GMxZGxx` | `tdp_*_gmxzgxx` | `POLARIS1XA03` / `STELLARIS1XA03` |
| `GMxAGxx` | `tdp_*_gmxagxx` | `STELLARIS1XI04` |
| `GMxRGxx` | `tdp_*_gmxrgxx` | `STEPOL1XA04` |
| `GMxPXxx` | `tdp_*_gmxpxxx` | `STELLARIS1XI05` |
| `GMxXGxx` / `GM6XGxX` | `tdp_*_gmxxgxx` | `POLARIS1XA05` / `STELLARIS1XA05` |
| `GM6IXxB_MB1` | `tdp_*_gmxixxb_mb1` | `STELLARIS16I06` (MB1) |
| `GM6IXxB_MB2` | `tdp_*_gmxixxb_mb2` | `STELLARIS16I06` (MB2) |
| `GM7IXxN` | `tdp_*_gmxixxn` | `STELLARIS17I06` |
| `GM5IXxA` | `tdp_*_gmxixxa` | `STELLSL15I06` |
| `GMxHGxx` | `tdp_*_gmxhgxa` | `STELLSL15A06` |
| `X6AR5xxY` / `X6AR5xxY_mLED` | `tdp_*_x6ar5xx` | `STELLARIS16I07` / `XNE16E25` |
| `X6FR5xxY` | `tdp_*_x6fr5xx` | `STELLARIS16A07` / `XNE16A25` |

**Reason:** Enables TDP control for XMG, Mechrevo, PCSpecialist, and other brands that share the same Tongfang barebone but don't set a custom `DMI_PRODUCT_SKU`. The Tongfang ODM sets `DMI_BOARD_NAME` identically across all brands. TDP arrays are named after board names (e.g., `tdp_min_gmxpxxx`), confirming they are hardware-specific, not brand-specific.

### 8. IBP Pro Gen10 TDP entries added to `tuxedo_io.c` (Phase 4) **[Added Feb 2026]**

Filled critical TDP gap: IBP Pro Gen10 boards (`XxHP4NAx`, `XxKK4NAx_XxSP4NAx`, `XxAR4NAx`) had keyboard/profile support but **no TDP control**. Added 3 new TDP array pairs and 4 new matching entries:

**New TDP arrays:**
| Array Name | Min (W) | Max (W) | Device |
|---|---|---|---|
| `tdp_*_xxxx4nax` | 10, 10, 10 | 25, 35, 65 | IBP Pro Gen10 AMD (conservative 14" values) |
| `tdp_*_xxxx4nax_15` | 10, 10, 10 | 25, 35, 90 | IBP Pro 15 Gen10 AMD (15" specific) |
| `tdp_*_xxar4nax` | 10, 10, 10 | 35, 45, 90 | IBP Pro 15 Gen10 Intel |

**New `uw_id_tdp()` entries:**
| Match | TDP Array | Context |
|---|---|---|
| SKU `XEV15AE25` | `tdp_*_xxxx4nax_15` | XMG EVO 15 AMD = IBP Pro 15 Gen10 AMD (90W max) |
| Board `XxHP4NAx` / `XxKK4NAx_XxSP4NAx` | `tdp_*_xxxx4nax` | IBP Pro Gen10 AMD; conservative 14" TDP (65W) since 14"/15" share board names |
| Board `XxAR4NAx` | `tdp_*_xxar4nax` | IBP Pro 15 Gen10 Intel (15" only, 90W) |

**Design decisions:**
- AMD board names (`XxHP4NAx`, `XxKK4NAx_XxSP4NAx`) are shared between 14" and 15" models with different TDP (65W vs 90W stage 3). No TUXEDO SKU exists for Gen10 to distinguish sizes. The board_name entry uses conservative 14" values (safe for both). The XEV15AE25 SKU entry overrides this for confirmed 15" XMG devices.
- Min TDP of 10W follows NB02-platform pattern (InfinityBook Max Gen10: `xxxx45xs`, `x6ar55xu`, `x5ar45xs` all use 10W min)
- TDP stages verified from tuxedocomputers.com product pages (IBP Pro 14/15 Gen10 AMD and Intel)

### 9. X6PR5551 investigation (Phase 4) **[Feb 2026]**

`X6PR5551` was investigated but **NOT ADDED** to any code:
- Zero results in linux-hardware.org, GitHub, tuxedo-drivers codebase
- Does not match any known Tongfang board name pattern (`XxHP4NAx`, `XxKK4NAx`, etc.)
- The `PR` two-letter code is unused in any known Tongfang naming convention
- Status: **unverifiable** — possibly fabricated, misremembered, or from unreleased hardware

---

## Cross-Brand DMI Identification Summary

### Brand DMI Behavior

| Brand | Custom PRODUCT_SKU? | Custom BOARD_NAME? | Coverage Strategy |
|---|---|---|---|
| **TUXEDO** | Yes (always) | Uses ODM wildcards | SKU match (primary) |
| **XMG/Schenker** | Gen7+ only (`XNE*`, `XEV*`) | Uses ODM board names | SKU match (Gen7+), board_name fallback (older) |
| **Commodore** | Yes (`OMNIA08IMK2`) | Uses ODM board names | SKU match |
| **Intel NUC** | No | Custom (`LAP*71*`) | PRODUCT_NAME match |
| **Mechrevo** | No | Uses ODM board names | Board_name fallback |
| **PCSpecialist** | No | Uses ODM board names | Board_name fallback |
| **Aftershock** | No | Mostly ODM | Board_name fallback |
| **Eluktronics** | No | Custom (e.g., `RP-15`) | **Not covered** (breaks board_name) |
| **SKIKK** | No | Custom (some models) | **Partially covered** |
| **Infinity (AU)** | No | Suffixed ODM (e.g., `GM5RG1E0009COM`) | **Not covered** (breaks exact match) |
| **Lunnen** | No | Custom | **Not covered** |
| **MACHENIKE** | No | Custom | **Not covered** |

---

## Document Revision History

| Date | Author | Changes |
|------|--------|---------|
| Feb 9, 2026 | Research Agent | Initial comprehensive survey of all DMI board names and SKUs in tuxedo-drivers; documented 4 changes made to uniwill_keyboard.h |
| Feb 9, 2026 | Research Agent | Phase 2: Added board_name fallbacks to ite_8291.c (6 entries), ite_8291_lb.c (3 entries), tuxedo_io.c (17 entries) for cross-brand support; documented XMG/Schenker DMI research findings |
| Feb 9, 2026 | Research Agent | Phase 4: Added IBP Pro Gen10 TDP support (3 array pairs, 4 uw_id_tdp entries); added XEV15AE25 XMG EVO 15 SKU; investigated X6PR5551 (not found); documented XMG EVO = IBP Pro Gen10 equivalence |

### Upstream Linux Kernel
- **`drivers/platform/x86/uniwill/uniwill-acpi.c`** — Armin Wolf's comprehensive DMI table with 52 Uniwill entries covering TUXEDO, Schenker/XMG, Intel, and Commodore
- **`drivers/acpi/resource.c`** — IRQ quirks for Tongfang boards (no vendor filter; covers 20+ brands)
- **`drivers/input/serio/i8042-acpipnpio.h`** — PS/2 keyboard quirks for Tongfang (no vendor filter)
- **`drivers/platform/x86/amd/pmc/pmc-quirks.c`** — AMD S2Idle quirks; identifies MECHREVO Wujie and other brands
- **`src/tuxedo_compatibility_check/tuxedo_compatibility_check.c`** — Vendor matching logic (TUXEDO, SchenkerTechnologiesGmbH, NB02, CPU families)

### Hardware Databases
- **linux-hardware.org** — Crowdsourced DMI probe database; searched vendor categories: TongFang, TUXEDO, Schenker, XMG, Eluktronics, Intel
  - Variants found for: QC71 (LAPQC71A/B/C/D), LP series, PH series, GM series, GX series, X series
  - Concrete instances: `GX4HRXL`, `GX5HRXG`, `GM7IX0N`, `GM5HG0A`, etc.

### GitHub Repositories
- **pobrn/qc71_laptop** — Independent QC71 driver with confirmed cross-brand matches (Schenker/XMG, Eluktronics, Aftershock, Intel, Avell)
- **wessel-novacustom/clevo-keyboard** — NovaCustom's tuxedo-drivers fork; retains identical GM board_name checks (confirms non-TUXEDO usage)
- **torvalds/linux** — Linux kernel master branch; source for upstream code references

### Community Research
- **Reddit r/XMG_gg** — Official XMG/Schenker subreddit; confirmed brand sharing Tongfang barebones
- **Reddit r/AMDLaptops** — Comprehensive vendor list for Tongfang GK5NR0O/GK7NR0R Polaris Gen1 (20+ brands documented)

---

## Known Limitations & TODOs

### Cannot Verify (Linux Hardware Probe DB Access Issues)
- Actual hardware probe data showing exact DMI board_name strings on non-TUXEDO brands
- linux-hardware.org required authentication/reCAPTCHA bypassed reliable access
- Concrete instances for many wildcard patterns require end-user hardware submissions

### Future Research Needs
- [ ] Verify `TRINITY1501I`/`TRINITY1701I` are truly TUXEDO-exclusive (unlikely to find external hardware probes)
- [x] ~~Confirm XMG NEO SKU usage~~ — Confirmed: `XNE16E25`/`XNE16A25` are XMG-assigned SKUs for Gen7 Stellaris equivalents. XMG did NOT set custom PRODUCT_SKU before Gen7 (2025). Pattern: `XNE` = XMG NEO, `16` = size, `E`/`A` = Intel/AMD, `25` = year
- [x] ~~Confirm XMG EVO = IBP Pro Gen10~~ — Confirmed: XMG EVO 15 (E25) = IBP Pro 15 Gen10 AMD (same dimensions, battery, CPUs, cooling). SKU pattern: `XEV` = EVO, `15` = size, `A` = AMD, `E25` = 2025. Added `XEV15AE25` to `uw_id_tdp()`
- [x] ~~Investigate X6PR5551~~ — NOT FOUND anywhere. Zero matches in linux-hardware.org, GitHub, tuxedo-drivers. Unverifiable identifier.
- [x] ~~Add IBP Pro Gen10 TDP entries~~ — Added 3 TDP array pairs and 4 `uw_id_tdp()` entries for `XxHP4NAx`/`XxKK4NAx_XxSP4NAx` (AMD), `XxAR4NAx` (Intel), and `XEV15AE25` (XMG EVO 15)
- [ ] Investigate Gen5 Stellaris Intel (`GMxPXxx`) cross-brand usage
- [ ] Check Commodore ORION line availability in linux-hardware.org after upstream kernel inclusion
- [ ] Monitor upstream kernel for additional QC71 variants (LAPMC71*, LAP*71*) that may imply new brands/models
- [ ] Obtain dmidecode dumps from Eluktronics, SKIKK, and Aftershock devices on Gen7+ Tongfang barebones to verify PRODUCT_SKU adoption
- [ ] Confirm XMG EVO 14 SKU: `XEV14AE25` (presumed) — once confirmed, add to `uw_id_tdp()` with 14" AMD TDP (25/35/65W identical to board_name fallback, so low priority)
- [ ] Confirm XMG EVO 15 Intel SKU: `XEV15ME25` (presumed) — once confirmed, add to `uw_id_tdp()` for Intel TDP
- [ ] Investigate whether `XxAR4NAx` needs `custom_profile_mode_needed` — AMD boards (`XxHP4NAx`, `XxKK4NAx_XxSP4NAx`) have it but Intel board does not
- [ ] Investigate `STELLSL15A06` (Stellaris Slim AMD Gen6) for ite_8291.c color_scaling needs — Intel counterpart `STELLSL15I06` has entry but AMD variant does not

### Potential Future Additions
- **Commodore ORION series** — Confirmed in upstream kernel as TUXEDO vendor but may expand to different vendor
- **XMG CORE/NEO/APEX series** — Various board_names found in upstream kernel (GMxRGxx, GMxBGxx, GMxXGxX)
- **PCSpecialist Elimina Pro** — Found in upstream `acpi/resource.c` with board names `GM6BGEQ`, `GM6BG5Q`, `GM6BG0Q`
- **Eluktronics RP/MECH/Prometheus series** — Likely using GM-series board names; requires verification via hardware probes

---

## Document Revision History

| Date | Author | Changes |
|------|--------|---------|
| Feb 9, 2026 | Research Agent | Initial comprehensive survey of all DMI board names and SKUs in tuxedo-drivers; documented 4 changes made to uniwill_keyboard.h |
| Feb 9, 2026 | Research Agent | Phase 2: Added board_name fallbacks to ite_8291.c (6 entries), ite_8291_lb.c (3 entries), tuxedo_io.c (17 entries) for cross-brand TDP + color scaling support |

---

## Notes for Future Updates

When adding new board names or SKUs:

1. **Cross-reference against upstream kernel** — Check `uniwill-acpi.c`, `acpi/resource.c`, `i8042-acpipnpio.h`, and `pmc-quirks.c` for existing entries
2. **Document vendor affiliation** — Note which brands are known to use the barebone (if any)
3. **Check TDP definitions** — Ensure `tuxedo_io/tuxedo_io.c` has TDP profiles for new boards
4. **Verify feature support** — Use EC register reads or check upstream flags for feature bits
5. **Update this document** — Add entry to appropriate section with sources and reasoning
6. **Test on actual hardware** (if available) — Confirm features work as expected
