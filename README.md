# yaai_fc - ABAP AI tools Function Calling Library

[![License: MIT](https://img.shields.io/badge/License-MIT-yellow.svg)](https://opensource.org/licenses/MIT)

A comprehensive function calling library designed specifically for AI agents to interact with ABAP Dictionary (DDIC) objects and related development artifacts in SAP ABAP environments.

## Overview

`yaai_fc` is part of the [ABAP AI tools](https://github.com/christianjianelli/yaai) ecosystem, providing a standardized set of function calling interfaces that enable AI assistants to perform ABAP development tasks programmatically. This library bridges the gap between natural language instructions and ABAP development operations, allowing AI agents to create, modify, and manage ABAP Dictionary objects and other ABAP development artifacts like message classes and translations, on the user's behalf.

## Key Features

- **AI-Agent Optimized**: Designed specifically for function calling by AI assistants
- **Comprehensive DDIC Coverage**: Support for many ABAP Dictionary objects
- **Translation Tools**: Translation management for a variety of texts and labels
- **Transport Management**: Transport request management tools


## Available Tools

### ABAP Dictionary (DDIC) Management

#### Core DDIC Objects
- **Domains** (`ycl_aai_fc_domain_tools`)
  - Create, update, delete domains
  - Manage fixed values
  - Manage translations for domain fixed values

- **Data Elements** (`ycl_aai_fc_data_element_tools`)
  - Create, update, delete data elements with built-in types or domain references
  - Manage translations for data element labels

- **Structures** (`ycl_aai_fc_structure_tools`)
  - Create, update, delete structures

- **Tables** (`ycl_aai_fc_table_tools`)
  - Create, update, delete transparent tables
  - Manage technical settings (data class, size category)

- **Table Types** (`ycl_aai_fc_table_type_tools`)
  - Create, update, delete table types

### Development Artifacts

- **Message Classes** (`ycl_aai_fc_message_class_tools`)
  - Create and manage message classes
  - Add, update, and delete messages
  - Handle message translations across languages

- **Text Pools** (`ycl_aai_fc_text_pool_tools`)
  - Manage text symbols for programs/reports
  - Manage translations for text symbols and selection texts

### Transport Management

- **Transport Requests** (`ycl_aai_fc_transport_tools`)
  - Create workbench and customizing requests
  - Search and read transport request details

## Architecture

The library follows a modular architecture with dedicated classes for each tool category:

```
Classes
├── ycl_aai_fc_domain_tools         # Domain management
├── ycl_aai_fc_data_element_tools   # Data element management
├── ycl_aai_fc_structure_tools      # Structure management
├── ycl_aai_fc_table_tools          # Table management
├── ycl_aai_fc_table_type_tools     # Table type management
├── ycl_aai_fc_message_class_tools  # Message class management
├── ycl_aai_fc_text_pool_tools      # Text pool management
└── ycl_aai_fc_transport_tools      # Transport request management
```

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

- [Domain Tools](docs/instructions/ddic-domain-tools.md)
- [Data Element Tools](docs/instructions/ddic-data-element-tools.md)
- [Structure Tools](docs/instructions/ddic-structure-tools.md)
- [Table Tools](docs/instructions/ddic-table-tools.md)
- [Table Type Tools](docs/instructions/ddic-table-type-tools.md)
- [Message Class Tools](docs/instructions/message-class-tools.md)
- [Text Pool Tools](docs/instructions/text-pool-tools.md)
- [Transport Request Tools](docs/instructions/transport-request-tools.md)

