🚧 Work in progress

# Azure AI Ops Assistant

Cloud-native AI operations platform built on Microsoft Azure with Terraform, Docker, GitHub Actions and Azure Container Apps.

The project provides a containerized Python API as the foundation for an AI-assisted operations platform. Infrastructure is provisioned using Infrastructure as Code, while application builds and deployments are automated through GitHub Actions using OpenID Connect authentication.

---

## Architecture

```text
                        GitHub Repository
                               │
                               │ Push / Pull Request
                               ▼
                     GitHub Actions Pipeline
                               │
                         OIDC Authentication
                               │
                               ▼
                   Managed Identity (GitHub)
                               │
                         AcrPush Role
                               │
                               ▼
                    ┌────────────────────┐
                    │ Azure Container    │
                    │ Registry (ACR)     │
                    │                    │
                    │ azure-ai-ops-      │
                    │ assistant          │
                    └─────────┬──────────┘
                              │
                         AcrPull
                              │
                              ▼
                 ┌─────────────────────────┐
                 │ Azure Container Apps    │
                 │                         │
                 │ ca-ai-ops-api-dev       │
                 │                         │
                 │ FastAPI / Uvicorn       │
                 └────────────┬────────────┘
                              │
                              ▼
                    Log Analytics
                    Workspace
```

---

## Technology Stack

| Component | Technology |
|---|---|
| Cloud Platform | Microsoft Azure |
| Infrastructure as Code | Terraform |
| Container Runtime | Azure Container Apps |
| Container Registry | Azure Container Registry |
| Application | Python / FastAPI |
| Application Server | Uvicorn |
| Containerization | Docker |
| CI/CD | GitHub Actions |
| Authentication | Microsoft Entra ID / OIDC |
| Identity | Azure Managed Identities |
| Monitoring | Azure Log Analytics |
| Source Control | Git / GitHub |

---

## Azure Infrastructure

The infrastructure is provisioned with Terraform.

### Resource Group

```text
rg-ai-ops-dev
```

### Container Registry

```text
acraiopsmikedev
```

The registry stores versioned container images for the API.

Images are tagged using the corresponding Git commit SHA, allowing deployments to reference an immutable application version.

### Container Apps Environment

```text
cae-ai-ops-dev
```

Provides the managed runtime environment for Azure Container Apps.

### Container App

```text
ca-ai-ops-api-dev
```

The API runs as a containerized FastAPI application.

Current configuration:

- External HTTP ingress
- Target port: `8000`
- Minimum replicas: `0`
- Maximum replicas: `1`
- CPU: `0.25`
- Memory: `0.5 Gi`
- Scale-to-zero enabled

The application exposes a health endpoint:

```text
GET /health
```

Example response:

```json
{
  "status": "healthy"
}
```

---

## Managed Identities

The platform uses Azure Managed Identities instead of storing registry credentials inside the application or CI/CD pipeline.

### GitHub Actions Identity

```text
id-ai-ops-github-dev
```

Used by GitHub Actions to authenticate against Azure through OIDC.

Assigned role:

```text
AcrPush
```

This allows the CI/CD pipeline to push container images to Azure Container Registry.

### Container App Identity

```text
id-ai-ops-api-dev
```

Used by the Azure Container App to authenticate against Azure resources without storing registry passwords.

Assigned role:

```text
AcrPull
```

This allows the Container App to pull its container image from ACR.

---

## CI/CD

GitHub Actions handles the application build and deployment workflow.

### Deployment Flow

```text
Git Push
   │
   ▼
GitHub Actions
   │
   ├── Checkout repository
   │
   ├── Authenticate with Azure using OIDC
   │
   ├── Build Docker image
   │
   ├── Push image to Azure Container Registry
   │
   ├── Create / update Azure Container App
   │
   └── Run deployment health check
```

The workflow uses the Git commit SHA as the container image tag.

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
Container App Revision
```

---

## Authentication & Security

The deployment pipeline uses GitHub Actions OpenID Connect instead of long-lived Azure client secrets.

```text
GitHub Actions
      │
      │ OIDC Token
      ▼
Microsoft Entra ID
      │
      ▼
Managed Identity
      │
      ▼
Azure Resource
```

No Azure client secret is required for the GitHub Actions authentication flow.

Container Registry access is controlled through Azure RBAC:

- `AcrPush` for the CI/CD identity
- `AcrPull` for the Container App identity

---

## Monitoring

Application and platform logs are integrated with Azure Log Analytics.

```text
Container App
      │
      ▼
Log Analytics
      │
      ├── Application logs
      ├── System logs
      └── Query / analysis
```

The Container App also provides a live log stream for operational troubleshooting.

---

## Health Checks

The deployment pipeline validates the application after deployment.

The API health endpoint is:

```text
GET /health
```

Expected HTTP status:

```text
200 OK
```

This provides a basic deployment validation before considering the deployment successful.

---

## Infrastructure as Code

All Azure infrastructure is managed through Terraform.

Typical workflow:

```bash
terraform fmt
terraform init
terraform validate
terraform plan
terraform apply
```

Infrastructure changes are reviewed through Git branches and pull requests before being merged into `main`.

---

## Git Workflow

Feature and fix branches are used for infrastructure and application changes.

Example:

```text
main
 │
 ├── feature/...
 │
 └── fix/...
```

Changes are reviewed and merged through Pull Requests.

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
│   ├── variables.tf
│   ├── outputs.tf
│   └── ...
│
├── Dockerfile
├── requirements.txt
├── .gitignore
└── README.md
```

---

## Current Capabilities

- FastAPI-based API
- Dockerized application
- Azure Container Registry integration
- Azure Container Apps deployment
- Scale-to-zero configuration
- Managed Identity authentication
- GitHub Actions CI/CD
- GitHub OIDC authentication
- Azure RBAC for registry access
- Automated deployment health check
- Azure Log Analytics integration
- Git-based deployment traceability

---

## Roadmap

Planned platform capabilities include:

- AI-assisted operational analysis
- Azure AI / Foundry integration
- Python SDK integration
- Structured incident and system analysis
- Additional observability capabilities
- Expanded CI/CD validation
- Container and application security improvements

---

## Environment

Current environment:

```text
Environment: Development
Cloud: Microsoft Azure
Region: Germany West Central
```

---

## License

This project is provided for demonstration and development purposes.