# Azure AI Ops Assistant

Cloud-native AI-assisted operations API built on Microsoft Azure using Terraform, Docker, GitHub Actions, Azure Container Apps and Azure AI Foundry.

The project provides a containerized FastAPI service that accepts infrastructure or application log messages and sends them to an Azure-hosted language model for operational analysis.

Infrastructure is provisioned with Terraform, application deployments are automated through GitHub Actions, and authentication between services uses Microsoft Entra ID, OpenID Connect and Azure Managed Identities instead of long-lived credentials.

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
                           AcrPush
                                │
                                ▼
                 ┌─────────────────────────┐
                 │ Azure Container Registry│
                 │                         │
                 │ Docker Image            │
                 └────────────┬────────────┘
                              │
                           AcrPull
                              │
                              ▼
                 ┌─────────────────────────┐
                 │ Azure Container Apps    │
                 │                         │
                 │ FastAPI / Uvicorn       │
                 └────────────┬────────────┘
                              │
                       Managed Identity
                              │
                 Cognitive Services User
                              │
                              ▼
                 ┌─────────────────────────┐
                 │ Azure AI Foundry        │
                 │                         │
                 │ gpt-5.4-mini            │
                 └─────────────────────────┘
                              │
                              ▼
                      Log Analytics
```

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

No API key is stored in the application.

---

## Managed Identity Authentication

The runtime communication path is:

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

The Container App uses:

```text
id-ai-ops-api-dev
```

The identity is assigned the Azure RBAC role:

```text
Cognitive Services User
```

This allows the application to obtain an Entra ID token and invoke the deployed AI model without storing an Azure AI API key.

---

## Azure Infrastructure

The Azure infrastructure is provisioned through Terraform.

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

The project also includes imported Azure resources that were initially explored manually in the Azure Portal and subsequently brought under Terraform management.

This demonstrates a common Infrastructure-as-Code workflow:

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

---

## Docker

The FastAPI application is packaged as a Docker image.

The image contains:

```text
Python runtime
FastAPI application
Python dependencies
Uvicorn application server
Health check
```

GitHub Actions builds a new image for each deployment and tags it with the corresponding Git commit SHA.

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

The deployment workflow performs:

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
Resolve API Managed Identity Client ID
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
Configure Managed Identity
        │
        ▼
Health Check
```

The workflow uses:

```yaml
workflow_dispatch
```

Deployments are therefore triggered manually through GitHub Actions.

---

## GitHub OIDC Authentication

GitHub Actions authenticates against Azure using OpenID Connect rather than a stored Azure client secret.

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

The GitHub deployment identity can push images to Azure Container Registry and manage the application deployment.

This avoids storing long-lived Azure authentication secrets inside GitHub.

---

## Container App Configuration

The application runs in Azure Container Apps.

Configuration:

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

---

## Infrastructure as Code

Terraform is used to manage the Azure infrastructure.

Typical workflow:

```bash
terraform fmt
terraform validate
terraform plan
terraform apply
```

Resources that were initially created manually during Azure AI Foundry exploration were subsequently imported into Terraform state and are now managed as code.

Infrastructure changes are developed through feature branches and merged into `main` using Pull Requests.

---

## Git Workflow

Development follows a feature-branch workflow.

```text
main
 │
 ├── feature/foundry-infra
 ├── feature/foundry-model-rbac
 ├── feature/foundry-model-deployment
 ├── feature/foundry-api-integration
 └── feature/dynamic-log-analysis
```

Typical workflow:

```text
Create branch
     ↓
Implement change
     ↓
Commit
     ↓
Push
     ↓
Pull Request
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
│       └── deploy-api.yml
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
- Azure AI Foundry integration
- GPT-5.4-mini model deployment
- Entra ID authentication for AI access
- User Assigned Managed Identity
- Azure RBAC
- Terraform Infrastructure as Code
- Terraform import workflow
- Dockerized application
- Azure Container Registry
- Azure Container Apps
- GitHub Actions CI/CD
- GitHub OIDC authentication
- Immutable image tagging using Git SHAs
- Automated deployment health checks
- Azure Log Analytics integration
- Scale-to-zero configuration

---

## Security

The project avoids long-lived Azure credentials where possible.

Authentication mechanisms include:

```text
GitHub Actions → Azure
OIDC + Managed Identity

Container App → Azure AI Foundry
Managed Identity + Entra ID + RBAC

Container App → ACR
Managed Identity + AcrPull

GitHub Actions → ACR
Managed Identity + AcrPush
```

No Azure AI API key is required by the FastAPI application.

---

## Cost Optimization

The project is designed as a development and portfolio environment with a strong focus on keeping Azure costs low.

Measures include:

- Azure Container Apps scale-to-zero
- Maximum of one application replica
- Small CPU and memory allocation
- ACR Basic tier
- Standard LRS storage
- Pay-as-you-go AI model usage
- Infrastructure destroyed when not actively being used

The complete environment can be recreated using Terraform and the deployment pipeline when further development or testing is required.

---

## Future Improvements

Potential improvements include:

- Structured AI responses
- Severity and category fields
- Recommended remediation actions
- API error handling
- Additional automated tests
- Expanded observability
- Additional CI/CD validation
- Application security improvements

These are intentionally kept outside the current MVP.

---

## Project Status

The core MVP is complete.

The project demonstrates an end-to-end cloud-native AI application workflow:

```text
Terraform
   ↓
Azure Infrastructure
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