# ProRock 🤟

**ProRock** is an open-source Delphi library for **schema-driven data modeling and serialization**, designed for long-lived codebases and incremental adoption.

ProRock focuses on clarity, explicit structure, and maintainability, while keeping code plain, transparent, and under full developer control.

- [What problem ProRock solves](#what-problem-prorock-solves)
- [Core architecture](#core-architecture)
  - [Basite](#basite-core)
  - [Extensions](#extensions)
  - [Xmlite](#xmlite)
- [Platform and compiler support](#platform-and-compiler-support)
- [Installation](#installation)

---

## What problem ProRock solves

ProRock is built with a simple goal: **to make complex, schema-based data handling easier to use in Delphi**, without hiding how things actually work.

ProRock started with XML because it is one of the most complex and widely used data formats. If an approach works well for XML, it can usually be applied to simpler formats too.

In many Delphi projects, working with structured data often leads to:
- tightly coupled parsing logic
- fragile runtime metadata
- excessive RTTI usage
- ad-hoc DOM-based reading and writing, often resulting in brittle and hard-to-maintain code

ProRock approaches this differently.

It separates:
- **data models**
- **metadata**
- **format-specific logic**

and keeps each part explicit, reusable, and composable.

The goal is not to hide complexity, but to **manage it in a way that stays understandable, fast, and maintainable over time**.

ProRock does not treat XML as a theoretical exercise. It focuses on practical, real-world usage, where XML is often complex, verbose, and easy to misuse, while still allowing developers to opt into stricter, standards-aware processing when needed.

---

## Core architecture

### Basite (Core)

**Basite** is the foundation of ProRock.

It provides a metadata-driven object model system for Delphi, independent of any specific data format.

Basite handles:
- **MetaModels** – plain Delphi object models (PODOs)
- **MetaBank** – centralized metadata storage and indexing
- **fast access** to metadata without repeated RTTI scanning
- **automatic initialization and lifecycle management** of nested object structures
- a flexible **extension mechanism** for attaching additional metadata and behavior

Basite itself is **format-agnostic** and does not depend on XML, JSON, or any other serialization format.

---

### Extensions

ProRock functionality is extended through **Basite extensions**.

Each extension:
- builds on top of Basite
- adds domain-specific metadata and behavior
- does not modify the underlying data models
- can be enabled only when needed

Extensions are introduced incrementally and become public only once considered stable for real-world use.

Currently available or planned extensions include:

|   |   |   |
|---|---|---|
| 🟢 | **Xmlite** | XML parsing and serialization to and from PODOs. Actively developed and ready for use. |
| 🔵 | **Jsonite** | JSON parsing and serialization to and from PODOs. Planned. |
| 🟡 | **Calcite** | OOXML spreadsheet processing. Partially developed, not yet public. Built on top of Xmlite. |
| ⚪ | **Other** | FHIR, EDI, and similar formats. Planned. |

---

### Xmlite

**Xmlite** is a Basite extension that adds support for **XML parsing and serialization**.

Xmlite introduces:
- XML-specific metadata (elements, attributes, namespaces)
- parsing and serialization helpers
- namespace-aware XML processing

`TXmlite` and `TXmliteList` inherit from `TBasite` and `TBasiteList`.

Most XML helpers are designed to work with `TBasite` models as well, allowing developers to:
- use Basite-level models for simple, DOM-style XML usage
- gradually opt into namespace-aware and schema-aware XML processing when needed

Xmlite aims to provide correct and standards-aware XML handling, while keeping the entry barrier low.

#### Current limitations (Xmlite)

Some XML Schema features are not fully supported yet, including:

- mixed content
- unions

These areas are under active development.  
Feedback and contributions are especially welcome here.

---

## Platform and compiler support

Development and active testing focus on recent Delphi releases and **64-bit** Windows targets.  
**Win32** is supported, but not the main focus of development.

ProRock relies on standard Delphi language features and the RTL. It should work with any Delphi version that supports **inline variable declarations**.

## Installation

ProRock does not require installation or IDE integration.  
It is a pure source-based library and does not rely on design-time packages or component registration.

To use it:
1. Clone or download the repository
2. Add the ProRock source directory to your project or IDE library path
3. Use the required units in your code

That’s it — ProRock is ready to use.  

Have fun, and let’s ProRock! 🤟

