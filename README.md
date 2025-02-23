<!-- PROJECT LOGO -->
<br />
<div align="center">
  <a href="https://github.com/sudoblark/sudoblark.terraform.modularised-demo">
    <img src="docs/logo.png" alt="Logo" width="80" height="80">
  </a>

<h3 align="center">sudoblark.terraform.modularised-demo</h3>

  <p align="center">
    An example Terraform setup using modularised components to fulfill a use-case - repo managed by sudoblark.terraform.github
    <br />
  </p>
</div>



<!-- TABLE OF CONTENTS -->
<details>
  <summary>Table of Contents</summary>
  <ol>
    <li>
      <a href="#about-the-project">About The Project</a>
      <ul>
        <li><a href="#built-with">Built With</a></li>
          <ul>
            <li><a href="#infrastructure">Infrastructure</a></li>
            <li><a href="#application-code">Application code</a></li>
          </ul>
      </ul>
    </li>
    <li>
      <a href="#getting-started">Getting Started</a>
      <ul>
        <li><a href="#prerequisites">Prerequisites</a></li>
        <li><a href="#pre-commit-hooks">Pre-commit hooks</a></li>
      </ul>
    </li>
    <li>
    <li>
      <a href="#architecture">Architecture</a>
      <ul>
        <li><a href="#infrastructure">Infrastructure</a></li>
        <li><a href="#workflows">Workflows</a></li>
      </ul>
    </li>
    <li>
      <a href="#usage">Usage</a>
      <ul>
        <li><a href="#deploying-terraform">Deploying Terraform</a></li>
        <li><a href="#processing-dummy-files">Processing dummy files</a></li>
      </ul>
    </li>
  </ol>
</details>



<!-- ABOUT THE PROJECT -->
## About The Project

This repo is simply a demo of how a modularised terraform setup may be utilised
in a micro-repo fashion - i.e. one repo per business-case.

It's counter may be considered to be [sudoblark.terraform.github](https://github.com/sudoblark/sudoblark.terraform.github)
, which is an example mono-repo to manage all aspects of a single SaaS product in one place.

For now, the repo is intended to be used in workshops/conferences to demonstrate a data-structure driven approach
to Terraform.

<p align="right">(<a href="#readme-top">back to top</a>)</p>



### Built With

#### Infrastructure
* [Terraform v1.5.1](https://github.com/hashicorp/terraform/releases/tag/v1.5.1)
* [tfenv](https://github.com/tfutils/tfenv)
* [awscli](https://aws.amazon.com/cli/)

#### Application code
* [Python 3.10](https://peps.python.org/pep-0619/)
* [Black](https://black.readthedocs.io/en/stable/)
* [Flake8](https://flake8.pycqa.org/en/latest/index.html)

#### Pipelines
* [sudoblark.github-actions.library 1.0.0](https://github.com/sudoblark/sudoblark.github-actions.library/releases/tag/1.0.0)

<p align="right">(<a href="#readme-top">back to top</a>)</p>



<!-- GETTING STARTED -->
## Getting Started

Below we outlined how to interact with both Infrastructure and Application code bases.

The repo structure is relatively simple:

- `application` is the top-level for app code. Subfolders in here should be made
such that Python apps following their respective best-practices, and we
have a single source of truth for state machine JSON etc.
- `infrastructure` contains both:
  - `sudoblark` folder which instantiates modules for the account, you may have `n` folders here - one for each
    account - provided they all use the same stack
  - `modules` folder to act as a top-level for re-usable Terraform modules

This repo is intended to be used for demonstration purposes when delivering
conferences, but is also made public such that conference attendees may
query it in their own time as well.

### Prerequisites

Note: Below instructions are for MacOS only, alteration may be required
to get this working on other operating systems.

* tfenv
```sh
git clone https://github.com/tfutils/tfenv.git ~/.tfenv
echo 'export PATH="$HOME/.tfenv/bin:$PATH"' >> ~/.bash_profile
```

* awscli
```sh
curl "https://awscli.amazonaws.com/awscli-exe-linux-x86_64.zip" -o "awscliv2.zip"
unzip awscliv2.zip
./aws/install
```

* Virtual environment with pre-commit installed

```sh
python3 -m venv venv
source venv/bin/activate
pip install pre-commit
```

* Poetry
```sh
pip install -U pip setuptools
pip install poetry
```

### Pre-commit hooks
Various pre-commit hooks are in place in order to ensure consistency across the codebases.

You may run these yourself as follows:

```sh
source venv/bin/activate
pip install pre-commit
pre-commit run --all-files
```

<p align="right">(<a href="#readme-top">back to top</a>)</p>

<!-- ARCHITECTURE -->
## Architecture

The below sections outline architecture diagrams and explanations in order to better understand just _what_ this
demo repo both in terms of infrastructure and application workflows.

### Infrastructure

```mermaid
architecture-beta
    group demo(cloud)[AWS Account]

    service unzipLambda(server)[Unzip lambda] in demo
    service rawBucket(database)[raw bucket] in demo
    service processedBucket(database)[processed bucket] in demo
    service bucketNotification(disk)[Bucket notification] in demo

    rawBucket:R -- L:bucketNotification
    bucketNotification:R -- L:unzipLambda
    unzipLambda:R -- L:processedBucket
```

Note: `s3_files` module, as you can see, is not needed for ETL. It is instead included
as it's one of the simplest data-driven modules you can have. Therefore, it's included
to be used as a simple, but useful, example in a conference/workshop setting.

### Workflows

```mermaid
---
title: Demo workflow
---
flowchart TD
    start((.ZIP uploaded to s3://raw/dogs/landing prefix))
    bucketNotification(Bucket notification)

    subgraph UnzipLambda
        lambdaStart(For each file in .ZIP)
        startPartition(Grabs year/month/day from filename)
        uploads(Uploads to s3://processed/dogs/daily/<partition>)

    end

    sns[\Send failure notification to topic/]
    endNode((Processed complete))

    start -- triggers --> bucketNotification
    bucketNotification -- triggers --> UnzipLambda

    lambdaStart --> startPartition
    startPartition --> uploads
    uploads -- If all succeed --> endNode
    uploads -- If fail --> sns
    sns --> endNode
```

<p align="right">(<a href="#readme-top">back to top</a>)</p>

<!-- USAGE EXAMPLES -->
## Usage

Below we will outline intended use-cases for the repository.

Note: This section assumes you've installed pre-requisites as
per above.

### Deploying Terraform

> **_NOTE:_** There is an example of continuous delivery in the form
> of the .github/deploy.yaml workflow. However, as this is continuous
> delivery - and not deployment - it is gated behind the approval
> of a member of Sudoblark and thus is intended to be used in workshop
> settings only. However, feel free to reference as an example of both
> continuous delivery, a pull model for CI/CD actions, and usage of GitHub
> composite actions.
>
> See below for instructions on how to deploy to your own AWS environment.

The `main.tf` file in `sudoblark` configures a backend state.

Clone this repo, and change this to your backend in order to instantiate
in our own account... otherwise this is suitable for demonstration purposes.

Simply:

1. Navigate to the instantiation folder:

```sh
cd infrastructure/example-account
```

2. Ensure your shell is authenticated to an appropriate profile for AWS

```sh
export AWS_DEFAULT_PROFILE=<PROFILE-NAME>
```

3. ZIP the lambda (Note in a production environment this would usually be done via CI/CD)

```sh
cd application/unzip-lambda/unzip_lambda
zip -r lambda.zip lambda_function.py
mkdir src
mv lambda.zip src
```

4. Init, plan and then apply.

```sh
terraform init
terraform plan
terraform apply
```

5. Simply tear-down when required

```sh
terraform destroy
```

### Processing dummy files
Files under `application/dummy_uploads` contain the contents of the ZIP file our unzip lambda
unzips from the `raw` to `processed` bucket.

Files names are in the format: `YYYYmmdd.csv` Each file corresponds to dogs viewed that day, with rows
being in the format of:

```
dog_name, breed, location
```
For example, we may have a file named 20241008.csv with a single row:

```
Cerberus, Molossus, Hades
```

Thus indicating that on the 08th October 2024, we spotted Cerberus doing a valiant job guarding the gates to Hates.

To upload these dummy files after the solution has been deployed in to AWS:

1. First ZIP the files:

```sh
cd application/dummy_uploads
zip -r uploads.zip .
```

2. Then, upload the ZIP to the `dev-raw` bucket at the `dogs/landing/` prefix:

```sh
aws s3 rm s3://dev-demo-raw/dogs/landing/uploads.zip
aws s3 cp ./application/dummy_uploads/uploads.zip s3://dev-demo-raw/dogs/landing/
```
3. This should then trigger an s3 bucket notification to run the lambda.
4. This lambda, in turn, should unzip the files and re-upload them into the `dev-processed` bucket,
at the `dogs/daily` root with prefix determined by date. i.e. for 20241008.csv we'd expect
an upload at `dogs/daily/_year=2024/_month=10/_day=08/viewings`

<p align="right">(<a href="#readme-top">back to top</a>)</p>