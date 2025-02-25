# Laravel Deployment Infrastructure

Welcome to laravel-aws-iac! This repo is my go-to Terraform-based solution for setting up the AWS infrastructure needed to run a Laravel application. It’s opinionated, battle-tested, and designed to be a learning tool for folks who are more familiar with Laravel than DevOps. (Heads up: Kubernetes, Docker, and Helm setups live in separate repos!)

## Table of Contents

1. [Project Overview](#1-project-overview)
2. [Architecture Overview](#2-architecture-overview)
3. [Prerequisites](#3-prerequisites)
4. [Installation & Setup](#4-installation--setup)
   - Terraform Backend
   - Environment Variables & Variables File
5. [Infrastructure Components](#5-infrastructure-components)
   - VPC & Networking
   - RDS Database
   - EKS Cluster
   - Redis ElastiCache
   - S3 Bucket for Logs
   - Secrets Management
   - IAM Roles & Policies
6. [Deployment](#6-deployment)
7. [CI/CD with GitHub Actions](#7-cicd-with-github-actions)
8. [Customization & Variables](#8-customization--variables)
9. [Troubleshooting & FAQ](#9-troubleshooting--faq)
10. [Future Enhancements](#10-future-enhancements)
11. [Contributing](#11-contributing)
12. [License](#12-license)

### 1. Project Overview

What’s this about?
This repo uses Terraform to set up the AWS infrastructure for a Laravel app. It covers (almost) everything from VPCs and databases to EKS clusters and Redis, making it easier for Laravel developers to dip their toes into cloud infrastructure.

Who’s it for?
Folks who know Laravel but want to get started with DevOps. I’m not a Terraform guru, but I’ve built this solution through trial, error, and plenty of learning—and I hope it helps you too!

What’s NOT here?
No Kubernetes app deployments or local Docker setups. Those are handled in separate repos.

### 2. Architecture Overview

High-Level Picture:
(Coming soon: A cool diagram showing how the pieces fit together!)

**Core Components:**

- VPC & Networking: An isolated network for all our AWS goodies.
- RDS: A PostgreSQL database (with some notes on scaling and the potential Aurora upgrade).
- EKS Cluster: Provisioned for container orchestration (the actual app deployments are in another repo).
- Elasticache for Redis: Our caching layer with custom parameter groups.
- S3 Bucket: For storing RDS logs with versioning and lifecycle rules.
- Secrets Manager: Keeping sensitive info like DB and Redis credentials safe.
- IAM Roles & Policies: For EKS nodes and autoscaling—you know, the usual AWS housekeeping.

### 3. Prerequisites

!!! NEED TO ADD WHAT PERMISSIONS THE USER NEEDS TO HAVE TO RUN THE TERRAFORM CODE. ALSO MAY WANT TO ADD HOW TO ADD A DEFAULT/DIFFERENT AWS PROFILE TO THE MACHINE.

- [Terraform](https://developer.hashicorp.com/terraform/tutorials/aws-get-started/install-cli)
- [AWS CLI](https://docs.aws.amazon.com/cli/latest/userguide/getting-started-install.html)
- AWS IAM Permissions
  - TODO

### 4. Installation & Setup

#### Terraform Backend

backend.tf:
This file sets up the remote state using an S3 bucket (laravel-deployment-tfstate). Make sure the bucket exists and you have access!

#### Environment Variables & Variables File

- **variables.tf:**
  Here you define your environment, region, DB settings, Redis settings, etc. A common practice is to also use a `terraform.tfvars` file that your `variables.tf` file references.
- **Credentials:**
  It’s best to manage AWS access keys and other sensitive info through environment variables or a secure secrets manager.

### 5. Infrastructure Components

#### VPC & Networking

We’re using the [terraform-aws-modules/vpc/aws](https://registry.terraform.io/modules/terraform-aws-modules/vpc/aws/latest) module to create a VPC with public and private subnets, NAT gateways, and DNS support.

#### RDS Database

A PostgreSQL instance is set up using the [terraform-aws-modules/rds/aws](https://registry.terraform.io/modules/terraform-aws-modules/rds/aws/latest) module.

Things to Note:
There are manual steps for scaling (read up on the Aurora note for zero downtime writes).
A dedicated subnet group and security group are set up to secure your DB.

**Important**
RDS Instance sizes are **NOT** the same as EC2 Instance sizes. Use this list to find acceptable instance sizes [https://aws.amazon.com/rds/instance-types/](https://aws.amazon.com/rds/instance-types/)

#### EKS Cluster

We provision an EKS cluster with managed node groups using the [terraform-aws-modules/eks/aws](https://registry.terraform.io/modules/terraform-aws-modules/eks/aws/latest) module.

**Important:**

- Although the cluster is created here, deploying your app on it is handled elsewhere.
- Node Sizes: I had a lot of trouble with this during development. I chose `t2.medium` for my `node_size` for testing and it alleviated a lot of the errors I was facing. For reference, I was using `t2.nano` and got coredns/insufficient replica errors.
- Nodes: You're limited on the number of nodes you're allowed within a Node Group depending on the size of the instance. Review here [https://docs.aws.amazon.com/eks/latest/userguide/eks-outposts-capacity-considerations.html](https://docs.aws.amazon.com/eks/latest/userguide/eks-outposts-capacity-considerations.html)

#### Redis ElastiCache

A Redis instance is managed via the [terraform-aws-modules/elasticache/aws](https://registry.terraform.io/modules/terraform-aws-modules/elasticache/aws/latest) module.

Future Work:
Consider switching to a replication group for improved high availability.

#### S3 Bucket for Logs

Using the [terraform-aws-modules/s3-bucket/aws](https://registry.terraform.io/modules/terraform-aws-modules/s3-bucket/aws/latest) module, we create a bucket for RDS logs with versioning and lifecycle rules.

#### Secrets Management

AWS Secrets Manager is used to store your DB and Redis credentials securely, with some random password generation magic thrown in.

#### IAM Roles & Policies

Custom IAM roles for EKS worker nodes (with policies like AmazonEKSWorkerNodePolicy, AmazonSSMManagedInstanceCore, etc.) and RBAC configurations to manage cluster access.

### 6. Deployment

Deploying the infrastructure is pretty straightforward:

- Initialize: Run `terraform init` to pull in modules and set up your backend.
- Plan: Run `terraform plan` to see what changes will be made.
- Apply: Run `terraform apply` to create your AWS resources.
- Verify: Check the AWS console and S3 bucket to ensure everything's running as expected. It may take 20-30 minutes to fully deploy all assets

### 7. CI/CD with GitHub Actions

I've also set up a GitHub Actions workflow (coming soon in this repo) that automates the Terraform workflow:

**What It Does:**

Runs terraform init, plan, and (optionally) apply on push or PR, ensuring your infrastructure is always in sync.

**Why GitHub Actions?**

It's an easy-to-use CI/CD tool that integrates seamlessly with GitHub, helping automate your deployments and catch issues early.

### 8. Customization & Variables

**What You Can Tweak:**

All configurable options (like environment, DB settings, Redis configs, etc.) are defined in `variables.tf`.

**Tips:**

Override defaults by providing a `terraform.tfvars` file or environment variables.
**Keep sensitive data out of version control by using Secrets Manager or environment variables.**

### 9. Troubleshooting & FAQ

**Common Issues:**

_Secrets manager:_

```
Error: creating Secrets Manager Secret (<your-secret>): operation error Secrets Manager: CreateSecret, https response error StatusCode: 400, RequestID: ..., InvalidRequestException: You can't create this secret because a secret with this name is already scheduled for deletion.
```

Cause: The Terraform configuration attempts to create a new secret with the same name as one that was deleted but is still in the AWS deletion queue.

Solution: added `recovery_window_in_days` property in `secrets.tf`.

_Terraform State Issues:_

```
Error: Cannot lock state: state already locked
```

Cause: The Terraform state file is locked due to an interrupted apply.

Solution: Manually unlock the Terraform state: `terraform force-unlock <LOCK_ID>`

_Cluster Node Group Auth Issues_

```
Error: You must be logged into the server (unauthorize)
```

or you may see a notice in the dashboard that says something like "The current user doesn't have access to the resource type nodes"

Cause: the AWS dashboard user that you're logged in as may not be the same user that is running terraform commmands and is not authorized to view the nodes/node groups. There are AWS IAM roles/permissions and Kubernetes Role Based Access Control (RBAC) permissions.

Solution: in `terraform.tfvars` file add the ARN ID of the uesrs who also need dashboard access to the cluster node groups like so:

```
eks_access_entries = [
  {
    name          = "username-1"
    principal_arn = "arn:aws:iam::XXXXX:user/username-1"
  },
  {
    name          = "root-username"
    principal_arn = "arn:aws:iam::XXXYYY:root"
  }
]
```

and view `main.tf` line 155 to see how we are adding those users to the cluster

**Tips:**

- Enable detailed Terraform logging.[https://developer.hashicorp.com/terraform/internals/debugging](https://developer.hashicorp.com/terraform/internals/debugging)

### 10. Future Enhancements

**Planned Improvements:**

- Example configurations for Aurora to eliminate write downtime.
- More advanced autoscaling options for RDS and Redis.
- Enhanced monitoring integrations (think CloudWatch dashboards).

**Keep an Eye Out:**

Some sections here are a work in progress and will be fleshed out as new features are added.

### 11. Contributing

**Want to Help?**

- Feel free to open issues or submit pull requests. This is a learning project, and contributions are welcome—let’s learn and improve together!
- Follow the existing style and structure. If you have suggestions, I’m all ears.

### 12. License & Public Use

This repository is public and shared for educational purposes. There isn’t a formal license attached, so feel free to fork, tweak, and use it as a reference for your own projects—but remember, it’s provided “as-is” without any warranty.
