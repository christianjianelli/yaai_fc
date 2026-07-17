[![License](https://img.shields.io/github/license/christianjianelli/yaai_fc)](https://github.com/christianjianelli/yaai_fc/blob/main/LICENSE)

# ABAP AI tools - Function Calling Library

A comprehensive function calling library designed specifically for AI agents to interact with ABAP Dictionary (DDIC) objects and related development artifacts in SAP ABAP environments.

## Overview

This library is part of the [ABAP AI tools](https://github.com/christianjianelli/yaai) ecosystem, providing a standardized set of function calling tools that enable AI assistants to perform ABAP development tasks programmatically. This library bridges the gap between natural language instructions and ABAP development operations, allowing AI agents to create, modify, and manage ABAP Dictionary objects and other ABAP development artifacts like message classes and translations, on the user's behalf.

## Key Features

- **AI-Agent Optimized**: Designed specifically for function calling by AI assistants
- **Comprehensive DDIC Coverage**: Support for many ABAP Dictionary objects
- **Translation Tools**: Translation management for a variety of texts and labels
- **Transport Management**: Transport request management tools


## Available Tools

### ABAP Dictionary (DDIC) Management

- **Domains** (`YCL_AAI_FC_DOMAIN_TOOLS`)
  - Read, search, create, update, delete domains
  - Manage fixed values
  - Manage translations for domain fixed values

- **Data Elements** (`YCL_AAI_FC_DATA_ELEMENT_TOOLS`)
  - Read, search, create, update, delete data elements with built-in types or domain references
  - Manage translations for data element labels

- **Structures** (`YCL_AAI_FC_STRUCTURE_TOOLS`)
  - Read, search, create, update, delete structures

- **Tables** (`YCL_AAI_FC_TABLE_TOOLS`)
  - Read, search, create, update, delete transparent tables
  - Manage technical settings (data class, size category)

- **Table Types** (`YCL_AAI_FC_TABLE_TYPE_TOOLS`)
  - Read, search, create, update, delete table types

- **CDS views** (`YCL_AAI_FC_CDS_TOOLS`)
  - Read, search, create, update, delete CDS views

### SQL Tools

- **SQL** (`YCL_AAI_FC_SQL_TOOLS`)
  - Perform SELECT, INSERT, UPDATE and DELETE statements on the SAP system

### Development Artifacts

- **Message Classes** (`YCL_AAI_FC_MESSAGE_CLASS_TOOLS`)
  - Create and manage message classes
  - Add, update, and delete messages
  - Handle message translations across languages

- **Transactions** (`YCL_AAI_FC_TRANSACTION_TOOLS`)
  - Read, search, create, translate ABAP Transactions (Report and Dialog types)

### Transport Management

- **Transport Requests** (`YCL_AAI_FC_TRANSPORT_TOOLS`)
  - Create workbench and customizing requests
  - Search and read transport request details

### ABAP Source Code Tools

- **ABAP Class** (`YCL_AAI_FC_OO_CLASS_TOOLS`)
  - Read, search, create, update, check, activate ABAP Classes

- **ABAP Interface** (`YCL_AAI_FC_OO_INTERFACE_TOOLS`)
  - Read, search, create, update, check, activate ABAP Interfaces

- **ABAP Program** (`YCL_AAI_FC_PROGRAM_TOOLS`)
  - Read, search, create, update, check, activate ABAP Programs

- **ABAP Include** (`YCL_AAI_FC_INCLUDE_TOOLS`)
  - Read, search, create, update, check, activate ABAP Includes

- **Text Pools** (`YCL_AAI_FC_TEXT_POOL_TOOLS`)
  - Manage text symbols for programs/reports
  - Manage translations for text symbols and selection texts

- **ABAP Function Group** (`YCL_AAI_FC_FUNC_GROUP_TOOLS`)
  - Read, search, create, update, check, activate ABAP Function Groups

- **ABAP Function Module** (`YCL_AAI_FC_FUNC_MODULE_TOOLS`)
  - Read, search, create, update, check, activate ABAP Function Modules

### ABAP Runtime Errors (ST22)

- **ABAP Runtime Errors** (`YCL_AAI_FC_RUNTIME_ERROR_TOOLS`)
  - Get ABAP runtime errors (ST22)

### ABAP Test Cockpit (ATC) and Code Inspector Tools

- **ATC Tools** (`YCL_AAI_FC_ATC_TOOLS`)
  - Execute ATC Run for all objects included in a given transport request
  - Get the results of a previously executed ATC Run for a given transport request

- **Code Inspector Tools** (`YCL_AAI_FC_CI_TOOLS`)
  - Execute a Code Inspector inspection for all objects included in a given transport request
  - Get the results of a previously executed Code Inspector inspection for a given transport request

### Email Tools

- **Email Tools** (`YCL_AAI_FC_EMAIL_TOOLS`)
  - Send Email

## Architecture

The library follows a modular architecture with dedicated classes for each tool category:

```
Classes
├── YCL_AAI_FC_DOMAIN_TOOLS         # Domain management
├── YCL_AAI_FC_DATA_ELEMENT_TOOLS   # Data element management
├── YCL_AAI_FC_STRUCTURE_TOOLS      # Structure management
├── YCL_AAI_FC_TABLE_TOOLS          # Table management
├── YCL_AAI_FC_TABLE_TYPE_TOOLS     # Table type management
├── YCL_AAI_FC_CDS_TOOLS            # CDS view management
├── YCL_AAI_FC_SQL_TOOLS            # SQL
├── YCL_AAI_FC_MESSAGE_CLASS_TOOLS  # Message class management
├── YCL_AAI_FC_TEXT_POOL_TOOLS      # Text pool management
└── YCL_AAI_FC_TRANSPORT_TOOLS      # Transport request management
└── YCL_AAI_FC_OO_CLASS_TOOLS       # ABAP Class
└── YCL_AAI_FC_OO_INTERFACE_TOOLS   # ABAP Interface
└── YCL_AAI_FC_OO_PROGRAM_TOOLS     # ABAP Program
└── YCL_AAI_FC_OO_INCLUDE_TOOLS     # ABAP Include
└── YCL_AAI_FC_TRANSACTION_TOOLS    # ABAP Transaction
└── YCL_AAI_FC_OO_FUNC_MODULE_TOOLS # ABAP Function Module
└── YCL_AAI_FC_FUNC_GROUP_TOOLS     # ABAP Function Group
└── YCL_AAI_FC_ABAP_ACTIVATE        # ABAP Mass Activation 
└── YCL_AAI_FC_RUNTIME_ERROR_TOOLS  # ABAP Runtime Errors
└── YCL_AAI_FC_ATC_TOOLS            # ABAP Test Cockpit (ATC)
└── YCL_AAI_FC_CI_TOOLS             # Code Inspector
└── YCL_AAI_FC_EMAIL_TOOLS          # Send Email 
```

## Usage through MCP clients

The tools available in this library can also be used through MCP clients, although they are not directly exposed. To use them via an MCP client, you must install the [ABAP AI tools - MCP tools](https://github.com/christianjianelli/yaai_mcp) library on your SAP backend and the [abap-mcp-server](https://github.com/christianjianelli/abap-mcp-server) on your local machine.

## Usage for AI Agents

This library is designed for AI assistants to perform tasks through function calling. Each tool provides a simple and intuitive interface that requires minimal documentation for AI agents to learn how to use them.

### Usage with ABAP AI tools

When used with the [ABAP AI tools](https://github.com/christianjianelli/yaai):

1. AI agents can discover available functions through the tool registry
2. AI agents can request detailed documentation for the tools they need to use
3. Operations return results with success/failure status, providing clear and actionable feedback for the AI agent

## Installation
Please read the [installation instructions](./docs/installation.md).

## Tools Documentation

Detailed documentation for each tool is available in the `docs/instructions/` directory:

### ABAP Dictionary (DDIC) Management

- [Domain Tools](docs/instructions/ddic-domain-tools.md)
- [Data Element Tools](docs/instructions/ddic-data-element-tools.md)
- [Structure Tools](docs/instructions/ddic-structure-tools.md)
- [Table Tools](docs/instructions/ddic-table-tools.md)
- [Table Type Tools](docs/instructions/ddic-table-type-tools.md)
- [CDS View Tools (WIP)](./)

### SQL Tools

- [SQL Tools (WIP)](./)

### Development Artifacts

- [Message Class Tools](docs/instructions/message-class-tools.md)
- [Transaction Tools (WIP)](./)

### ABAP Source Code Tools

- [Class Tools (WIP)](./)
- [Interface Tools (WIP)](./)
- [Program Tools (WIP)](./)
- [Include Tools (WIP)](./)
- [Text Pool Tools](docs/instructions/text-pool-tools.md)
- [Function Group Tools (WIP)](./)
- [Function Module Tools (WIP)](./)

### Transport Management

- [Transport Request Tools](docs/instructions/transport-request-tools.md)

### ABAP Runtime Errors (ST22)

- [Runtime Errors Tools (WIP)](./)

### ABAP Test Cockpit (ATC) and Code Inspector Tools

- [ATC Tools (WIP)](./)
- [Code Inspector Tools (WIP)](./)

### Emails

- [Send Email Tool (WIP)](./)  
