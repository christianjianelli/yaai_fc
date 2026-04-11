# ABAP Table Type Management - AI Assistant Guide

## Overview
This document provides guidance for managing ABAP Dictionary (DDIC) Table Type objects.
It covers supported operations, supported line types, and table type-specific concepts
such as line type binding and key definition.

## Supported Operations
- **CREATE** - Create new table types
- **UPDATE** - Modify existing table types
- **DELETE** - Delete existing table types
- **READ** - View table type details
- **SEARCH** - List/filter table types
- **ACTIVATE** - Activate existing tables

> ⚠️ Always warn the developer before executing a delete operation and require explicit
> confirmation before proceeding.

## Line Type Selection Guidelines
A table type defines the structure of its rows through a line type. The line type can
be defined in one of the following ways:

- **Built-in type** — the line type is a single ABAP primitive type. Use this for
  simple collections of scalar values (e.g. a list of integers or strings).
- **Data Element** — the line type references an existing data element. Use this when
  the scalar value needs meaningful labels or shared type constraints.
- **Structure** — the line type references an existing DDIC structure, meaning each row
  of the table type has multiple fields. This is the most common option for table types
  used as internal table definitions in ABAP programs.

When the developer does not specify a line type, use the context of the request and the
guidelines above to suggest the most appropriate option.
Always confirm your suggestion with the developer before proceeding.

> ⚠️ Table types can have dependencies on Data Elements and Structures. Always verify
> that all referenced objects exist before creating or updating a table type. If a
> dependency is missing, flag it and ask the developer how to proceed.

## Table Type Initialization, Access and Key Definitions
The table type tools support only the creation of table types with default settings. This means:
- **Access**: Standard Tables (unsorted, allowing duplicates and no automatic sorting).
- **Key Definition**: None (no primary key is set by default).

For custom access types (e.g., Sorted or Hashed) or key definitions, manual configuration in the ABAP Dictionary is required after creation.
