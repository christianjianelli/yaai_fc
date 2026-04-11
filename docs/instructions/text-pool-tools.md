# ABAP Text Pool Management - AI Assistant Guide

## Overview
This document provides guidance for managing ABAP Text Pool objects used by programs
and reports. It covers supported operations, text pool concepts, text symbol and
selection text guidelines, and translation management.

## Supported Operations
- **CREATE** - Create new text symbols and selection texts
- **READ** - View text symbols and selection texts
- **UPDATE** - Modify existing text symbols and selection texts
- **DELETE** - Remove existing text symbols and selection texts
- **TRANSLATE** - Translate text symbols and selection texts

> ⚠️ Always warn the developer before executing a delete operation and require explicit
> confirmation before proceeding.

## Text Pool Concepts

### Text Symbols
Text symbols are reusable text fragments stored in the text pool for a specific
program or report. Use text symbols for labels, messages, and other small text
fragments that may be reused in code.

### Selection Texts
Selection texts describe screen elements, parameter labels, and UI prompts for the
selection screen of a program or report. Use selection texts for:
- parameter labels
- select-option labels

### Scope and Object Association
Text pools belong to the program or report they are defined in. When creating or
updating text pool content, always confirm the correct program/report object is
identified.

## Text Guidelines
When helping the developer write text pool content, apply the following guidelines:
- Keep texts short and clear — ideally one sentence
- Use consistent terminology across the same program or report
- Prefer simple, user-focused language
- Avoid unnecessary technical jargon unless the audience is technical
- Use reusable text symbols instead of duplicating identical text

## Translation Management
Text element translations are managed per language using the TRANSLATE operation.
When working with translations:
- Confirm the target language with the developer before setting a translation
- Treat the source language as English unless the developer specifies otherwise
- Do not overwrite source language texts using translation operations
- Verify whether translation is required for text symbols, selection texts, or both