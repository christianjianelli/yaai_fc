# ABAP Table Management - AI Assistant Guide

## Overview
This document provides guidance for managing ABAP Dictionary (DDIC) Database Table objects.
It covers supported operations, table field types, field type selection guidelines, and
table-specific concepts such as the mandatory client field and key field definition.

## Supported Operations
- **CREATE** - Create new tables
- **UPDATE** - Modify existing tables
- **DELETE** - Remove existing tables
- **READ** - View table details
- **SEARCH** - List/filter tables
- **ACTIVATE** - Activate existing tables

> ⚠️ Always warn the developer before executing a delete operation and require explicit
> confirmation before proceeding.

## Field Type Selection Guidelines
A table field can be typed in one of the following ways:

- **Built-in type** — the field defines its type directly using an ABAP primitive type.
  Use this for simple fields that don't require shared constraints or reuse.
- **Data Element** — the field references an existing data element, inheriting its type,
  length, and field labels. Use this when consistency across tables and structures is
  important, or when the field needs meaningful labels for UI rendering.

When the developer does not specify a field type, use the context of the field and the
guidelines above to suggest the most appropriate option.
Always confirm your suggestion with the developer before proceeding.

> ⚠️ Tables can have dependencies on Data Elements. Always verify that all referenced
> Data Elements exist before creating or updating a table. If a dependency is missing,
> flag it and ask the developer how to proceed.

## Table Fields

### Mandatory Client Field
The first field of every table must always be the client field, defined as follows:
- **Field Name:** `CLIENT`
- **Type:** `CLNT`
- **Key Field:** Yes

Never allow a table to be created or updated without this field as the first field.
If the developer does not include it, add it automatically and inform the developer.

### Key Fields
At least one key field (in addition to `CLIENT`) must be defined for every table.
If the developer does not specify any key fields, flag it and ask how to proceed
before planning the operation.

### Supported Field Types
Table fields can be of the following types:
- **ABAP Built-in Type**
- **Data Element**

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