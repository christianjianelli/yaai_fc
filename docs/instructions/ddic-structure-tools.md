# ABAP Structure Management - AI Assistant Guide

## Overview
This document provides guidance for managing ABAP Dictionary (DDIC) Structure objects.
It covers supported operations, supported field types, and type selection guidelines,
including structure-specific concepts such as field type binding and nested structures.

## Supported Operations
- **CREATE** - Create new structures
- **UPDATE** - Modify existing structures
- **DELETE** - Remove existing structures
- **READ** - View structure details
- **SEARCH** - List/filter structures

## Field Type Selection Guidelines
A structure field can be typed in one of the following ways:

- **Built-in type** — the field defines its type directly using an ABAP primitive type.
  Use this for simple fields that don't require shared constraints or reuse.
- **Data Element** — the field references an existing data element, inheriting its type,
  length, and field labels. Use this when consistency across structures and tables is
  important, or when the field needs meaningful labels for UI rendering.
- **Structure** — the field references an existing structure, embedding it as a nested
  component. Use this to group related fields or reuse a shared structure definition.
- **Table** — the field references an existing DDIC table, embedding its field definition
  as a component. Use this when the field represents a row-compatible type.
- **Table Type** — the field references an existing table type, typically used to embed
  an internal table as a component within the structure.

When the developer does not specify a field type, use the context of the field and the
guidelines above to suggest the most appropriate option.
Always confirm your suggestion with the developer before proceeding.

> ⚠️ Structures can have dependencies on Data Elements, other Structures, Tables, and
> Table Types. Always verify that all referenced objects exist before creating or updating
> a structure. If a dependency is missing, flag it and ask the developer how to proceed.

## Supported ABAP Built-in Types
The following ABAP built-in types are supported when using the Built-in type option:
- CHAR
- STRING
- NUMC
- LANG
- CLNT
- INT1
- INT2
- INT4
- DEC
- FLTP
- DATS
- TIMS
- CURR
- CUKY
- QUAN
- UNIT

### Type Reference Guide

#### 1. Character/String Types
| Type | Description | Length | Decimals | Notes | Example Use Cases |
|------|-------------|--------|----------|-------|-------------------|
| `CHAR` | Fixed-length character | Required | No | - | Names, codes, IDs |
| `STRING` | Variable-length string | Not allowed | No | - | Long text, descriptions |
| `NUMC` | Numeric text | Required | No | - | IDs with leading zeros |
| `LANG` | Language key | Not allowed | No | Fixed length 1 (system-managed) | Language fields |
| `CLNT` | Client field | Not allowed | No | Fixed length 3 (system-managed) | Mandt fields |

#### 2. Numeric Types
| Type | Description | Length | Decimals | Notes | Example Use Cases |
|------|-------------|--------|----------|-------|------------------|
| `INT1` | 1-byte integer | Not allowed | No | Range: 0–255 | Status codes, flags |
| `INT2` | 2-byte integer | Not allowed | No | Range: -32,768–32,767 | Medium integers |
| `INT4` | 4-byte integer | Not allowed | No | Range: -2,147,483,648–2,147,483,647 | Counters, IDs |
| `DEC` | Packed decimal | Required | Required | Max 31 digits | Amounts, quantities |
| `FLTP` | Floating point | Not allowed | No | 8-byte IEEE 754 | Scientific values |

#### 3. Date/Time Types
| Type | Description | Length | Decimals | Notes | Example Use Cases |
|------|-------------|--------|----------|-------|------------------|
| `DATS` | Date | Not allowed | No | Fixed format YYYYMMDD (system-managed) | Date fields |
| `TIMS` | Time | Not allowed | No | Fixed format HHMMSS (system-managed) | Time fields |

#### 4. Business Types
| Type | Description | Length | Decimals | Notes | Example Use Cases |
|------|-------------|--------|----------|-------|------------------|
| `CURR` | Currency amount | Required | Required | Must be linked to a CUKY reference field | Monetary amounts |
| `CUKY` | Currency key | Not allowed | No | Fixed length 5 (system-managed) | Currency codes |
| `QUAN` | Quantity | Required | Required | Must be linked to a UNIT reference field | Stock quantities |
| `UNIT` | Unit of measure | Not allowed | No | - | Units (KG, L, M) |