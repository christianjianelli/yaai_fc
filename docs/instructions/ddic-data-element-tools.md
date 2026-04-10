# ABAP Data Element Management - AI Assistant Guide

## Overview
This document provides guidance for managing ABAP Dictionary (DDIC) Data Element objects.
It covers supported operations, available built-in types, type selection guidelines, 
and data element-specific concepts such as domain binding and field labels.

## Supported Operations
- **CREATE** - Create new data elements
- **UPDATE** - Modify existing data elements
- **DELETE** - Delete existing data elements
- **READ** - View data element details
- **SEARCH** - List/filter data elements

## Type Selection Guidelines
A data element can define its type in one of two ways:

- **Domain-based** — the data element references an existing domain, inheriting its 
  type, length, and value constraints. Use this when the same type definition is 
  shared across multiple data elements.
- **Built-in type** — the data element defines its type directly, without a domain. 
  Use this for simple or one-off fields that don't need shared constraints.

When the developer does not specify a type or domain, use the Type Reference Guide 
below and the context of the field to suggest the most appropriate option. 
Always confirm your suggestion with the developer before proceeding.

## Supported ABAP Built-in Types
The following ABAP built-in types are supported:
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