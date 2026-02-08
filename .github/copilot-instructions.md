# Copilot Instructions: Data-Driven Terraform Repository

This repository uses specialized instruction files organized by purpose for better maintainability and clarity.

---

## Instruction Files

### For Terraform Code Generation

**File:** [instructions/terraform.md](instructions/terraform.md)

**Applies to:** All `.tf` files in this repository

**Contains:**
- Data-driven Terraform patterns and architecture
- Code generation rules and templates
- Path-specific instructions for different file types
- Naming conventions and security standards
- Repository-specific context (ETL pipeline, current infrastructure)
- Quick reference for common tasks

**Use when:** Generating or modifying any Terraform code, including:
- Data structure definitions (`modules/data/*.tf`)
- Infrastructure modules (`modules/infrastructure/*/`)
- Environment instantiation (`infrastructure/*/`)

### For README Documentation

**File:** [instructions/readme.md](instructions/readme.md)

**Applies to:** `README.md` and documentation files

**Contains:**
- Documentation structure and required sections
- Writing style guidelines
- Code example formatting standards
- Mermaid diagram best practices
- Content update guidelines
- Repository-specific documentation focus

**Use when:** Creating or updating repository documentation

### For Python Code

**File:** [instructions/python.md](instructions/python.md)

**Applies to:** All `.py` files, especially Lambda functions

**Contains:**
- Type hints and explicit return types
- Docstring standards (Google style)
- Pydantic for data validation
- Exception handling patterns
- Security and logging best practices
- Lambda-specific patterns
- Testing guidelines for pytest

**Use when:** Writing or modifying Python code for Lambda functions or utilities

---

## Key Principle

**Infrastructure should be managed through data structures, not repetitive resource blocks.** Users modify data; modules handle complexity.
