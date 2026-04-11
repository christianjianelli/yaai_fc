# ABAP Domain Management - AI Assistant Guide

## Overview
This document provides guidance for managing ABAP Dictionary (DDIC) Domain objects.
It covers supported operations, available built-in types, and type selection guidelines.

## Supported Operations
- **CREATE** - Create new domains
- **UPDATE** - Modify existing domains
- **DELETE** - Delete existing domains
- **READ** - View domain details
- **SEARCH** - List/filter domains
- **ACTIVATE** - Activate existing domains
- **GET_TRANSLATION** - View domain fixed values translation 
- **SET_TRANSLATION** - Modify domain fixed values translation 

> ⚠️ Always warn the developer before executing a delete operation and require explicit
> confirmation before proceeding.

## Type Selection Guidelines
When the developer does not specify a built-in type, use the Type Reference Guide 
below to suggest the most appropriate one based on the field's intended use.
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
| `CURR` | Currency amount | Required | Required | - | Monetary amounts |
| `CUKY` | Currency key | Not allowed | No | Fixed length 5 (system-managed) | Currency codes |
| `QUAN` | Quantity | Required | Required | - | Stock quantities |
| `UNIT` | Unit of measure | Not allowed | No | - | Units (KG, L, M) |