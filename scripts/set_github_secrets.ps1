<#
.SYNOPSIS
    Cria os GitHub Actions secrets/variables necessários para o pipeline.

.DESCRIPTION
    Lê os outputs da stack Terraform `bootstrap` (WIF_PROVIDER, DEPLOYER_SA) e
    cria os secrets no repositório GitHub via `gh` CLI. Os project ids e os
    valores Astronomer são passados como parâmetros.

    Pré-requisitos:
      - GitHub CLI autenticado:  gh auth login
      - Terraform bootstrap já aplicado (para o ambiente correspondente)

.EXAMPLE
    ./scripts/set_github_secrets.ps1 `
        -Repo "owner/music-stream-rawdp" `
        -ProjectDev "music-stream-dev-123" `
        -ProjectPrd "music-stream-prd-123" `
        -Region "europe-west1"

.NOTES
    WIF_PROVIDER e DEPLOYER_SA são lidos do estado local da bootstrap. Como a
    bootstrap usa state local por diretório, corre este script logo após o
    `terraform apply` do ambiente cujos outputs queres usar (normalmente dev).
#>
[CmdletBinding()]
param(
    [Parameter(Mandatory = $true)] [string] $Repo,
    [Parameter(Mandatory = $true)] [string] $ProjectDev,
    [Parameter(Mandatory = $true)] [string] $ProjectPrd,
    [string] $Region = "europe-west1",
    [string] $WifProvider,
    [string] $DeployerSa,
    [string] $AstroApiToken,
    [string] $AstroDeploymentIdDev,
    [string] $AstroDeploymentIdPrd
)

$ErrorActionPreference = "Stop"
$bootstrapDir = Join-Path $PSScriptRoot "..\infrastructure\projects\bootstrap"

function Get-TfOutput([string] $name) {
    Push-Location $bootstrapDir
    try {
        return (terraform output -raw $name)
    }
    finally {
        Pop-Location
    }
}

# Resolve WIF_PROVIDER / DEPLOYER_SA from terraform outputs if not provided.
if (-not $WifProvider) { $WifProvider = Get-TfOutput "wif_provider" }
if (-not $DeployerSa) { $DeployerSa = Get-TfOutput "sa_deployer_email" }

Write-Host "Setting secrets on $Repo ..." -ForegroundColor Cyan

function Set-Secret([string] $name, [string] $value) {
    if ([string]::IsNullOrWhiteSpace($value)) {
        Write-Host "  - skip $name (no value)" -ForegroundColor DarkYellow
        return
    }
    $value | gh secret set $name --repo $Repo --body -
    Write-Host "  + secret $name" -ForegroundColor Green
}

Set-Secret "WIF_PROVIDER" $WifProvider
Set-Secret "DEPLOYER_SA"  $DeployerSa
Set-Secret "GCP_PROJECT_DEV" $ProjectDev
Set-Secret "GCP_PROJECT_PRD" $ProjectPrd
Set-Secret "ASTRO_API_TOKEN" $AstroApiToken
Set-Secret "ASTRO_DEPLOYMENT_ID_DEV" $AstroDeploymentIdDev
Set-Secret "ASTRO_DEPLOYMENT_ID_PRD" $AstroDeploymentIdPrd

# GCP_REGION is a (non-secret) repository variable.
gh variable set GCP_REGION --repo $Repo --body $Region | Out-Null
Write-Host "  + variable GCP_REGION = $Region" -ForegroundColor Green

Write-Host "Done." -ForegroundColor Cyan
