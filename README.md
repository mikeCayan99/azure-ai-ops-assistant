# Azure AI Ops Assistant

Cloud-native AI-assisted operations API built on Microsoft Azure using Terraform, Docker, GitHub Actions, Azure Container Apps and Azure AI Foundry.

The project provides a containerized FastAPI service that accepts infrastructure or application log messages and sends them to an Azure-hosted language model for operational analysis.

Terraform provisions the Azure platform infrastructure, while GitHub Actions manages the application container lifecycle and deployment.

The architecture uses OpenID Connect and Azure Managed Identities for workload authentication wherever possible, reducing the use of long-lived credentials.

---

## Architecture

```text
                         GitHub Repository
                                │
                                │ Manual deployment
                                ▼
                      GitHub Actions Pipeline
                                │
                         OIDC Authentication
                                │
                                ▼
                    GitHub Managed Identity
                                │
                 ┌──────────────┴──────────────┐
                 │                             │
              AcrPush                Container Apps Contributor
                 │                             │
                 ▼                             │
       Azure Container Registry               │
                 ▲                             │
                 │                             │
              AcrPull                          │
                 │                             │
                 ▼                             │
         API Managed Identity                  │
                 │                             │
                 └──────────────┬──────────────┘
                                ▼
                     Azure Container App
                                │
                         FastAPI / Uvicorn
                                │
                       Managed Identity
                                │
                  Cognitive Services User
                                │
                                ▼
                      Azure AI Foundry
                                │
                         GPT-5.4-mini
```

The Container Apps environment sends platform and application logs to Azure Log Analytics.

---

## Technology Stack

| Component | Technology |
|---|---|
| Cloud Platform | Microsoft Azure |
| Infrastructure as Code | Terraform |
| AI Platform | Azure AI Foundry |
| AI Model | GPT-5.4-mini |
| Application | Python / FastAPI |
| Application Server | Uvicorn |
| Containerization | Docker |
| Container Runtime | Azure Container Apps |
| Container Registry | Azure Container Registry |
| CI/CD | GitHub Actions |
| Authentication | Microsoft Entra ID / OIDC |
| Workload Identity | Azure Managed Identities |
| Authorization | Azure RBAC |
| Monitoring | Azure Log Analytics |
| Source Control | Git / GitHub |

---

## Core Functionality

The API exposes two endpoints.

### Health Check

```http
GET /health
```

Example response:

```json
{
  "status": "healthy"
}
```

The health endpoint is intentionally excluded from application authentication so the deployment pipeline can verify application availability.

### Log Analysis

```http
POST /analyze
```

Example request:

```json
{
  "log": "CRITICAL: API returned HTTP 503 for 12 consecutive requests. Service: payment-api"
}
```

The API forwards the supplied log message to the deployed Azure AI model and returns the generated operational analysis.

Example response:

```json
{
  "analysis": "This log indicates a service availability problem..."
}
```

The log message is supplied dynamically through the request body rather than being hardcoded in the application.

Input validation limits log messages to a maximum of 4000 characters.

The application also implements a lightweight in-memory rate limit of five requests per client within a 60-second window.

---

## Azure AI Foundry

The project uses Azure AI Foundry as the AI backend.

Terraform manages:

```text
Azure AI Services Account
        │
        ▼
Azure AI Foundry Project
        │
        ▼
GPT-5.4-mini Deployment
```

Current model deployment:

```text
Model: gpt-5.4-mini
Deployment Type: GlobalStandard
```

The FastAPI application accesses the model through the OpenAI SDK using Microsoft Entra ID authentication.

Azure AI local authentication is disabled.

No Azure AI API key is stored in the application.

---

## Managed Identity Authentication

The application runtime uses a User Assigned Managed Identity:

```text
id-ai-ops-api-dev
```

Runtime communication:

```text
Azure Container App
        │
        ▼
User Assigned Managed Identity
        │
        ▼
Microsoft Entra ID
        │
        ▼
Azure AI Foundry
        │
        ▼
GPT-5.4-mini
```

The identity receives the Azure RBAC role:

```text
Cognitive Services User
```

This allows the application to obtain an Entra ID token and invoke the deployed AI model without storing an Azure AI API key.

The same workload identity receives:

```text
AcrPull
```

on Azure Container Registry so the Container App can pull its application image without registry passwords.

---

## Azure Infrastructure

The platform infrastructure is provisioned through Terraform.

Core resources include:

```text
Resource Group
Azure Container Registry
Log Analytics Workspace
Azure Container Apps Environment
User Assigned Managed Identities
Federated Identity Credential
Azure RBAC Role Assignments
Storage Account
Azure Key Vault
Azure AI Services Account
Azure AI Foundry Project
GPT-5.4-mini Deployment
```

The Storage Account is provisioned as part of the Azure platform foundation and is configured with shared-key access disabled.

The Key Vault is provisioned as part of the secure platform baseline and uses Azure RBAC for access control.

Terraform is responsible for the platform foundation.

GitHub Actions is responsible for creating or updating the application Container App during deployment.

This separation keeps infrastructure provisioning and application delivery as distinct lifecycle responsibilities.

---

## Terraform Import Workflow

Some Azure resources were initially explored manually and subsequently brought under Terraform management.

The workflow demonstrates:

```text
Existing Azure Resource
        │
        ▼
Terraform Resource Definition
        │
        ▼
terraform import
        │
        ▼
Terraform State
        │
        ▼
terraform plan
```

This allows manually explored resources to transition into Infrastructure as Code management.

---

## Docker

The FastAPI application is packaged as a Docker image based on the slim Python runtime.

The container includes:

```text
Python runtime
FastAPI application
Python dependencies
Uvicorn application server
Health check
```

### Non-Root Runtime

The container does not run the application as the root user.

The Dockerfile creates a dedicated application user:

```text
appuser
```

Application files are assigned to that user and the runtime switches to:

```dockerfile
USER appuser
```

This reduces container privileges and follows a common container-hardening practice.

---

## Image Versioning

GitHub Actions builds a new Docker image for each deployment and tags it using the corresponding Git commit SHA.

Example:

```text
acraiopsmikedev.azurecr.io/azure-ai-ops-assistant:<commit-sha>
```

This provides traceability between:

```text
Git Commit
     ↓
Docker Image
     ↓
Container App Deployment
```

---

## CI/CD

Application deployment is automated through GitHub Actions.

The deployment workflow is triggered manually using:

```yaml
workflow_dispatch
```

Deployment flow:

```text
Manual Workflow Trigger
        │
        ▼
Checkout Repository
        │
        ▼
Authenticate to Azure using OIDC
        │
        ▼
Resolve API Managed Identity
        │
        ▼
Build Docker Image
        │
        ▼
Authenticate to ACR
        │
        ▼
Push Docker Image
        │
        ▼
Create / Update Container App
        │
        ▼
Configure Authentication
        │
        ▼
Enable External Ingress
        │
        ▼
Health Check
```

The deployment workflow uses immutable image tags based on Git commit SHAs.

The final health check includes retry logic so temporary Container App startup delays do not immediately fail the deployment.

---

## Pull Request Validation

Pull requests targeting `main` run a separate validation workflow before merge.

The workflow checks:

```text
Terraform formatting
        │
        ▼
Terraform initialization
        │
        ▼
Terraform validation
        │
        ▼
Docker build validation
```

The validation pipeline uses:

```bash
terraform fmt -check -recursive
terraform init -backend=false
terraform validate
docker build
```

This catches common Terraform and Docker issues before changes reach `main`.

---

## GitHub OIDC Authentication

GitHub Actions authenticates against Azure using OpenID Connect instead of a stored Azure deployment client secret.

```text
GitHub Actions
      │
      │ OIDC Token
      ▼
Microsoft Entra ID
      │
      ▼
GitHub Managed Identity
      │
      ▼
Azure Resources
```

The deployment identity is:

```text
id-ai-ops-github-dev
```

Terraform creates the federated identity credential that establishes trust between the GitHub repository and Azure.

No Azure client secret is required for the GitHub-to-Azure login flow.

---

## Least-Privilege Deployment RBAC

The GitHub deployment identity does not receive a broad `Contributor` role over the Resource Group.

Instead, deployment permissions are separated by responsibility.

### Azure Container Registry

```text
AcrPush
```

Allows GitHub Actions to push Docker images to Azure Container Registry.

### Azure Container Apps

```text
Container Apps Contributor
```

Allows the deployment identity to manage the Container App lifecycle.

### Managed Identity Assignment

```text
Managed Identity Operator
```

This role is scoped specifically to the API User Assigned Managed Identity:

```text
id-ai-ops-api-dev
```

It allows the deployment process to attach that identity to the Container App without granting broad Resource Group permissions.

---

## Container App Authentication

The public API is protected using Azure Container Apps built-in Microsoft Entra authentication.

Unauthenticated requests to protected application endpoints return:

```text
401 Unauthorized
```

The health endpoint remains accessible:

```text
/health
```

so automated deployment health checks can run successfully.

The current Easy Auth configuration uses an Entra application registration and a client secret.

That secret is stored as a protected GitHub Actions Secret and is not hardcoded in the repository.

This means the architecture is not completely secretless.

Instead, secretless authentication is used for the two main workload paths:

```text
GitHub Actions → Azure
OIDC

Container App → Azure AI Foundry
Managed Identity
```

---

## Fail-Closed Deployment

The deployment workflow avoids exposing an application update before authentication has been configured.

For an existing Container App:

```text
Disable external ingress
        │
        ▼
Update application
        │
        ▼
Configure authentication
        │
        ▼
Enable external ingress
```

For a newly created Container App, ingress is enabled only after authentication configuration has been applied.

This reduces the risk of temporarily exposing an unauthenticated application during deployment.

---

## Container App Configuration

The application runs in Azure Container Apps.

Current configuration:

```text
External HTTP ingress
Target port: 8000
Minimum replicas: 0
Maximum replicas: 1
CPU: 0.25
Memory: 0.5 Gi
Scale-to-zero enabled
```

Scale-to-zero keeps the development environment cost-efficient when the application is not being used.

---

## Security

The project applies several security controls across infrastructure, CI/CD and the application runtime.

### Authentication

```text
GitHub Actions → Azure
OIDC + Federated Identity

Container App → Azure AI Foundry
Managed Identity + Entra ID + RBAC

Container App → ACR
Managed Identity + AcrPull

GitHub Actions → ACR
Managed Identity + AcrPush

Client → Container App
Microsoft Entra ID Easy Auth
```

### Infrastructure Hardening

The Terraform configuration includes:

- Azure AI local authentication disabled
- Storage Account shared-key access disabled
- Storage local users disabled
- Public nested storage items disabled
- Azure RBAC-based access
- Dedicated workload identities
- Least-privilege deployment roles

### Container Hardening

The Docker container:

- runs as a dedicated non-root user
- contains an application health check
- uses a slim Python base image

### GitHub Actions Hardening

External GitHub Actions are pinned to immutable commit SHAs rather than floating version tags.

This reduces supply-chain risk caused by unexpected changes to external action versions.

---

## Monitoring

The Container Apps environment is integrated with Azure Log Analytics.

```text
Container App
      │
      ▼
Log Analytics
      │
      ├── Application logs
      ├── Platform logs
      └── Operational troubleshooting
```

The deployment pipeline also performs an HTTP health check against:

```text
GET /health
```

A successful deployment must return:

```text
200 OK
```

The health check retries temporary failures during Container App startup.

---

## Infrastructure as Code

Terraform manages the Azure platform infrastructure.

Typical workflow:

```bash
terraform fmt
terraform validate
terraform plan
terraform apply
```

Infrastructure changes are developed through feature branches and merged into `main` using Pull Requests.

The environment can also be destroyed and recreated when it is not actively needed.

---

## Git Workflow

Development follows a branch-and-Pull-Request workflow.

```text
main
 │
 ├── feature/*
 ├── fix/*
 ├── security/*
 ├── ci/*
 └── docs/*
```

Typical workflow:

```text
Create branch
     ↓
Implement change
     ↓
Validate locally
     ↓
Commit
     ↓
Push
     ↓
Pull Request
     ↓
Automated PR validation
     ↓
Merge into main
```

---

## Project Structure

```text
azure-ai-ops-assistant/
│
├── .github/
│   └── workflows/
│       ├── deploy-api.yml
│       └── pr-validation.yml
│
├── app/
│   └── main.py
│
├── infrastructure/
│   ├── main.tf
│   ├── foundry.tf
│   ├── variables.tf
│   ├── outputs.tf
│   ├── providers.tf
│   └── versions.tf
│
├── Dockerfile
├── requirements.txt
├── .gitignore
└── README.md
```

---

## Current Capabilities

- FastAPI REST API
- Dynamic log analysis endpoint
- Input validation
- Basic request rate limiting
- Azure AI Foundry integration
- GPT-5.4-mini model deployment
- Microsoft Entra authentication for Azure AI access
- User Assigned Managed Identities
- Azure RBAC
- Least-privilege deployment permissions
- Terraform Infrastructure as Code
- Terraform import workflow
- Dockerized non-root application
- Azure Container Registry
- Azure Container Apps
- GitHub Actions CI/CD
- GitHub OIDC authentication
- Pull Request validation workflow
- Immutable image tagging using Git SHAs
- Pinned GitHub Action dependencies
- Fail-closed application deployment
- Automated deployment health checks with retry logic
- Azure Log Analytics integration
- Scale-to-zero configuration
- Security and cost guardrails

---

## Cost Optimization

The project is designed as a development and portfolio environment with a strong focus on keeping Azure costs low.

Measures include:

- Azure Container Apps scale-to-zero
- Maximum of one application replica
- Small CPU and memory allocation
- ACR Basic tier
- Standard LRS storage
- Log Analytics daily ingestion quota
- Low AI model deployment capacity
- Infrastructure destroyed when not actively being used

The environment can be recreated using Terraform and the deployment pipeline when further development or testing is required.

---

## Future Improvements

Potential improvements include:

- Structured AI responses
- Severity and category fields
- Recommended remediation actions
- Expanded API error handling
- Additional automated application tests
- Expanded observability
- Centralized rate limiting for multi-replica deployments
- Further authentication hardening

These improvements are intentionally kept outside the current MVP.

---

## Project Status

The core MVP is complete.

The project demonstrates an end-to-end cloud-native AI application workflow:

```text
Terraform
   ↓
Azure Platform Infrastructure
   ↓
GitHub Actions
   ↓
Docker
   ↓
Azure Container Registry
   ↓
Azure Container Apps
   ↓
Managed Identity
   ↓
Azure AI Foundry
   ↓
GPT-5.4-mini
```

A client can submit a log message to the deployed FastAPI API and receive an AI-generated operational analysis from the Azure-hosted model.

The project has been tested through the complete deployment path, including OIDC authentication, ACR image delivery, Container App deployment, Managed Identity assignment and application health validation.

---

## Environment

```text
Environment: Development
Cloud: Microsoft Azure
Region: Germany West Central
```

---

## License

This project is provided for demonstration and development purposes.