# Terraform Code Generation Instructions

This file provides GitHub Copilot with patterns, conventions, and standards for generating Terraform code in this data-driven infrastructure repository.

**Key Principle:** Infrastructure should be managed through data structures, not repetitive resource blocks. Users modify data; modules handle complexity.

---

## General: Data-Driven Terraform Patterns

### Core Architecture Pattern

**Three-Layer Structure:**

1. **Data Layer** (`modules/data/*.tf`)
   - Define infrastructure as simple data structures (lists of objects)
   - Include comprehensive docstrings explaining structure and constraints
   - Provide realistic examples in comments
   - Use locals for all definitions

2. **Infrastructure Modules** (`modules/infrastructure/*/`)
   - Accept list of objects as primary input
   - Use `for_each` for resource iteration with unified index
   - Output resource attributes (ARNs, IDs, names)
   - Separate concerns into focused files

3. **Instantiation Layer** (`infrastructure/*/`)
   - Wire data module to infrastructure modules
   - Use `for_each` to iterate over data module outputs
   - Include explicit `depends_on` where needed
   - Keep instantiation files simple and declarative

### Code Generation Rules

**When generating Terraform code:**

- Use Terraform 1.14+ syntax
- Always use `for_each` over `count` for resource iteration
- Create keyed loops using meaningful identifiers (e.g., `resource.name`)
- Define data structures as `list(object({...}))` types
- Use `optional()` for non-required fields with sensible defaults
- Include validation blocks for constrained values
- Separate resources into focused `.tf` files by concern

**Example structure:**
```terraform
locals {
  resources = [
    {
      name = "example"
      # ... other fields
    }
  ]

  resources_enriched = {
    for resource in local.resources :
    resource.name => merge(resource, {
      full_name = "${var.account}-${var.project}-${resource.name}"
    })
  }
}

resource "aws_resource" "example" {
  for_each = local.resources_enriched
  name     = each.value.full_name
}
```

### Naming Conventions

**Enforce these patterns:**
- All AWS resources: `${account}-${project}-${application}-${name}` (lowercase, hyphens)
- Terraform resource names: descriptive, singular (e.g., `aws_s3_bucket.bucket`)
- Local values: descriptive, plural for collections (e.g., `buckets_enriched`)
- Variables: snake_case with descriptive names
- File names: purpose-based (e.g., `buckets.tf`, `lambdas.tf`, `notifications.tf`)

### Documentation Requirements

**Always include when generating:**

1. **Docstrings for data structures** (in `modules/data/*.tf`):
   ```terraform
   /*
     Resource Type data structure definition:

     Each object requires:
     - field_name (type): Description

     Optional fields:
     - optional_field (type): Description (default: value)

     Constraints:
     - Constraint descriptions

     Example:
     {
       field_name = "value"
     }
   */
   ```

2. **Variable descriptions** (in `modules/infrastructure/*/variables.tf`):
   - Clear description of purpose
   - Document validation rules
   - Note default values and their reasoning

3. **Output descriptions** (in `*/outputs.tf`):
   - Explain what is being exposed
   - Document structure if complex

### Data Enrichment Pattern

**When generating data transformation code:**

```terraform
locals {
  # 1. Merge defaults with user input
  # 2. Add computed values
  # 3. Create lookup maps

  resources_enriched = [
    for resource in local.resources : merge(
      {
        # Defaults first
        account = local.account
        default_value = local.defaults.value
      },
      resource,  # User values override defaults
      {
        # Computed values last
        full_name = lower("${local.account}-${local.project}-${resource.name}")
      }
    )
  ]

  # Lookup map for cross-referencing
  resources_map = {
    for resource in local.resources_enriched : resource.name => resource
  }
}
```

**Key principles:**
- Resolve ALL cross-references in data layer, not instantiation
- Use maps for efficient lookups
- Compute full resource names/ARNs in enrichment
- Make enriched data self-contained

### Security Standards

**Always enforce:**
- Never hardcode secrets or credentials
- Use `sensitive = true` for sensitive outputs
- Reference secrets via `data.aws_secretsmanager_secret`
- Apply least privilege to IAM roles
- Enable encryption for data at rest
- Use external IDs for cross-account assume role

### Testing and Validation

**Include validation when generating:**
```terraform
variable "environment" {
  type = string
  validation {
    condition     = contains(["development", "staging", "production"], var.environment)
    error_message = "Environment must be development, staging, or production"
  }
}
```

**Use type constraints:**
```terraform
variable "resources" {
  type = list(object({
    name     = string
    optional = optional(string, "default")
  }))
}
```

---

## Path-Specific Instructions

### For `modules/data/*.tf` files

**Purpose:** Define infrastructure as data structures

**Rules:**
- Start every file with a comprehensive multi-line comment docstring
- Use `locals` blocks exclusively (no resources)
- Define structures as lists of objects
- Include realistic examples in docstrings
- Document all required and optional fields
- Note constraints and cross-references
- Keep individual files focused (one resource type per file)

**Template:**
```terraform
/*
  [Resource Type] data structure definition:

  [Detailed documentation here]
*/

locals {
  resource_types = [
    # Definitions
  ]
}
```

### For `modules/infrastructure/*/variables.tf` files

**Purpose:** Define module inputs

**Rules:**
- Every variable needs a clear description
- Use `type = list(object({...}))` for resource collections
- Include validation blocks for constrained values
- Use `optional()` for non-required fields with defaults
- Document the purpose of each field in the description

**Template:**
```terraform
variable "account" {
  description = "Which account this is being instantiated in."
  type        = string
  validation {
    condition     = contains([...], var.account)
    error_message = "Must be one of: ..."
  }
}

variable "resources" {
  description = "List of resources to create. See main documentation."
  type = list(object({
    name     = string
    optional = optional(string, "default")
  }))
}
```

### For `modules/infrastructure/*/*.tf` resource files

**Purpose:** Create AWS resources from data structures

**Rules:**
- Use `for_each` for all resource iteration
- Key by meaningful identifier from data
- Keep resources focused (one type per file typically)
- Use `each.value` for all attributes
- Add `depends_on` only when truly necessary
- Include comments for complex logic

**Template:**
```terraform
resource "aws_service_resource" "name" {
  for_each = { for item in var.items : item.name => item }

  name = each.value.full_name
  # ... other attributes from each.value

  tags = each.value.tags
}
```

### For `modules/infrastructure/*/outputs.tf` files

**Purpose:** Expose resource attributes

**Rules:**
- Output comprehensive resource information
- Use maps keyed by resource identifier
- Include descriptions for all outputs
- Document structure if complex
- Make outputs useful for cross-referencing

**Template:**
```terraform
output "resource_map" {
  description = "Map of created resources with their attributes"
  value = {
    for name, resource in aws_service_resource.name : name => {
      id  = resource.id
      arn = resource.arn
    }
  }
}
```

### For `infrastructure/*/` instantiation files

**Purpose:** Wire data and modules together

**Rules:**
- One module call per resource type
- Use `for_each` over data module outputs
- Pass values directly from `each.value`
- Add `depends_on` for explicit dependencies
- Keep files simple and declarative

**Template:**
```terraform
module "resources" {
  for_each = { for r in module.data.resources : r.name => r }

  source = "../../modules/infrastructure/resource"

  account = each.value.account
  project = each.value.project
  name    = each.value.name
  # ... pass all attributes
}
```

### For `infrastructure/*/main.tf` files

**Purpose:** Provider and backend configuration

**Rules:**
- Include required_version constraint
- Configure S3 backend with encryption
- Use assume_role for AWS provider
- Include external_id for security
- Add default_tags at provider level

**Template:**
```terraform
terraform {
  required_version = "~> 1.14"

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = ">= 6.0"
    }
  }

  backend "s3" {
    bucket  = "..."
    key     = "..."
    encrypt = true
    region  = "..."
    assume_role = {
      role_arn     = "..."
      session_name = "..."
      external_id  = "CI_CD_PLATFORM"
    }
  }
}

provider "aws" {
  region = "..."
  assume_role {
    role_arn     = "..."
    session_name = "..."
    external_id  = "CI_CD_PLATFORM"
  }
  default_tags {
    tags = {
      environment = "..."
      managed_by  = "..."
    }
  }
}
```

---

## Repository-Specific Context

### Application Purpose

This repository demonstrates data-driven Terraform through a practical ETL pipeline:
- **Landing bucket**: Receives ZIP files
- **Unzip Lambda**: Extracts CSV files to raw bucket
- **Raw bucket**: Stores CSV files
- **Parquet Converter Lambda**: Converts CSV to Parquet with date partitioning
- **Processed bucket**: Stores Parquet files

### Current Infrastructure

**S3 Buckets:**
- `landing` - No folder structure
- `raw` - No folder structure
- `processed` - No folder structure

**Lambda Functions:**
- `unzip-processor` - Python 3.11, 512MB memory, 60s timeout
- `parquet-converter` - Python 3.11, 1024MB memory, 120s timeout

**S3 Notifications:**
- `landing` → `unzip-processor` on `.zip` files
- `raw` → `parquet-converter` on `.csv` files

**Environment:**
- Account: `aws-sudoblark-development`
- Project: `demos`
- Application: `tf-micro-repo`
- All resources prefixed: `aws-sudoblark-development-demos-tf-micro-repo-`

### When Generating New Resources

**For S3 buckets:** Add to `modules/data/buckets.tf` list
**For Lambda functions:** Add to `modules/data/lambdas.tf` list (requires IAM role exists)
**For notifications:** Add to `modules/data/notifications.tf` list (must reference existing bucket and Lambda)

**Remember:**
- Bucket names are auto-prefixed (just provide short name like "landing")
- Lambda function names are auto-prefixed
- Cross-references use short names (enrichment resolves to ARNs)
- IAM roles follow pattern: `${account}-${project}-${application}-${role_name}`

### Code Style Preferences

**Terraform formatting:**
- Use `terraform fmt` standards
- One blank line between blocks
- Align `=` in blocks when reasonable
- Comments above the code they describe

**Python (for Lambda functions):**
- Black formatter (88 char line length)
- Type hints for function signatures
- Docstrings for all functions
- PEP 8 naming conventions

---

## What NOT to Generate

**Avoid these patterns:**
- Using `count` for resource iteration (use `for_each`)
- Hardcoding account IDs, region names, or ARNs in data layer
- Creating resources directly in data files (use locals only)
- Repeating resource blocks (abstract to modules)
- Manual cross-referencing (let enrichment resolve)
- Inline policies in instantiation (define in modules)
- Skipping validation on constrained values

**Don't modify:**
- Backend configuration without approval
- Provider versions without testing
- Naming convention patterns
- File organization structure

---

## Quick Reference for Common Tasks

**Add a new S3 bucket:**
```terraform
# In modules/data/buckets.tf
{
  name         = "new-bucket"
  folder_paths = ["optional", "folders"]  # Can be empty []
}
```

**Add a new Lambda:**
```terraform
# In modules/data/lambdas.tf
{
  name             = "new-lambda"
  description      = "What it does"
  zip_file_path    = "./lambda-packages/new-lambda.zip"
  handler          = "module.handler"
  runtime          = "python3.11"
  role_name        = "new-lambda-role"  # Must exist in AWS
  environment_variables = {
    KEY = "value"
  }
}
```

**Add a notification:**
```terraform
# In modules/data/notifications.tf
{
  bucket_name = "existing-bucket"  # Must match bucket name
  lambda_notifications = [
    {
      lambda_name   = "existing-lambda"  # Must match lambda name
      events        = ["s3:ObjectCreated:*"]
      filter_suffix = ".ext"  # File extension filter
    }
  ]
}
```

---

**Remember:** The goal is infrastructure that's as easy to modify as updating a data structure. If generated code requires Terraform knowledge to use, it doesn't follow this pattern.
