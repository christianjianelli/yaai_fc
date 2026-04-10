# ABAP Message Class Management - AI Assistant Guide

## Overview
This document provides guidance for managing ABAP Message Class objects.
It covers supported operations and message class-specific concepts such as
message numbering, text guidelines, and translation management.

## Supported Operations
- **Create Message** - Create a new message in a message class
- **Read Message** - Retrieve a specific message from a message class
- **Update Message** - Update the text of an existing message in a message class
- **Delete Message** - Delete a specific message from a message class
- **Read All Messages** - Retrieve all messages from a message class
- **Set Translation** - Set or update the translation of a message in a specific language
- **Get Translation** - Retrieve the translation of a message for a specific language

## Message Class Concepts

### Message Numbers
Each message in a message class is identified by a 3-digit number (000–999).
When the developer does not specify a message number, suggest the next available
number in the message class and confirm with the developer before proceeding.

### Message Types
ABAP messages are classified by type. The type is not managed by these tools directly,
but the developer may reference it when describing the intended use of a message.
The standard message types are:

| Type | Description | Typical Use |
|------|-------------|-------------|
| `S` | Success | Confirmation of a successful operation |
| `I` | Information | Neutral informational message |
| `W` | Warning | Non-critical issue, processing continues |
| `E` | Error | Critical issue, processing is interrupted |
| `A` | Abend | Fatal error, transaction is terminated |
| `X` | Exit | Program termination with short dump |

### Message Text Guidelines
When helping the developer write message texts, apply the following guidelines:
- Keep messages short and clear — ideally one sentence
- Use placeholders (`&1`, `&2`, `&3`, `&4`) for dynamic values where needed
- Use consistent terminology across messages in the same message class
- Avoid technical jargon unless the target audience is technical

### Translation Management
Message translations are managed per language using the Set Translation and
Get Translation operations. When working with translations:
- Always confirm the target language with the developer before setting a translation
- The source language of the message class is typically English — do not overwrite
  source language texts using the Set Translation operation
- When retrieving translations, confirm whether the developer wants a specific
  message or all messages in the class for the target language

> ⚠️ Always warn the developer before executing a delete operation and require explicit
> confirmation before proceeding.