#Requires -Modules @{ ModuleName="Az.Resources"; ModuleVersion="6.4.1" }
#Requires -Modules @{ ModuleName="AzureAD"; ModuleVersion="2.0.2.140" }

PARAM
(
    [Parameter(Mandatory = $false)]
    [ValidateSet("development", "test", "production")]
    [string] $Stage = "development",
    [Parameter(Mandatory = $false)]
    [string] $CustomerShortCode = "dnug",
    [Parameter(Mandatory = $false)]
    [string] $GitHubRepositoryPath = "dotnet-meetup-2023-06/terraform-sonar-demo"
)

# This PowerShell script supports you in Configuring OpenID Connect in Azure
# For details see https://docs.github.com/en/actions/deployment/security-hardening-your-deployments/configuring-openid-connect-in-azure

$ErrorActionPreference = "Stop"
$VerbosePreference = "Continue"

$EnvCode = $Stage.Substring(0, 1)

# Connect to Azure and get the proper context
Connect-AzAccount
Get-AzTenant
$tenantId = Read-Host "Choose a tenant id"
Set-AzContext -TenantId $tenantId
Connect-AzureAD -TenantId $tenantId

$azContext = Get-AzContext;
if ($null -eq $azContext) {
    Write-Error "No Azure context found. Please connect to Azure first."
    exit 1
}
# --------------------------------------

# Create resource groups
$mainResourceGroupName = "$($CustomerShortCode)-$($EnvCode)-rg-core"
$tfResourceGroupName = "$($CustomerShortCode)-$($EnvCode)-rg-iac"

Get-AzResourceGroup -Name $mainResourceGroupName -ErrorVariable notPresent -ErrorAction SilentlyContinue
if ($notPresent) {
    New-AzResourceGroup -Name $mainResourceGroupName -Location "switzerlandnorth"
    Write-Host "Resource Group $($mainResourceGroupName) created."
}
else {
    Write-Host "Resource Group $($mainResourceGroupName) already exists."
}

Get-AzResourceGroup -Name $tfResourceGroupName -ErrorVariable notPresent -ErrorAction SilentlyContinue
if ($notPresent) {
    New-AzResourceGroup -Name $tfResourceGroupName -Location "switzerlandnorth"
    Write-Host "Resource Group $($tfResourceGroupName) created."
}
else {
    Write-Host "Resource Group $($tfResourceGroupName) already exists."
}
# --------------------------------------

# Create app registration
Write-Host ""
Write-Host "CREATING THE APP REGISTRATION" -ForegroundColor Green

$tenantId = $azContext.Tenant.Id;
$subscriptionId = $azContext.Subscription.Id;
$appDiplayName = "Github Service Connection Demo ($($stage))"

Write-Host "Azure Tenant: $($azContext.Name)";

$client = Get-AzADApplication -DisplayName $appDiplayName
if ($null -eq $client) {
    Write-Host "Creating new app registration $($appDiplayName)"
    $client = New-AzADApplication -DisplayName $appDiplayName
}
else {
    Write-Host "Found existing app registration $($appDiplayName)"
}

$clientId = $client.AppId
$clientObjectId = $client.Id
Write-Host "App registration id: $($clientId)";
Write-Host "App registration object id: $($clientObjectId)";
# --------------------------------------

# Create service principal for the app registration
Write-Host ""
Write-Host "CREATING THE SERVICE PRINCIPAL" -ForegroundColor Green

$servicePrincipal = Get-AzADServicePrincipal -DisplayName $appDiplayName
if ($null -eq $servicePrincipal) {
    Write-Host "Creating new service principal $($appDiplayName)"
    $servicePrincipal = New-AzADServicePrincipal -ApplicationId $clientId
}
else {
    Write-Host "Found existing service principal $($appDiplayName)"
}

$objectId = $servicePrincipal.Id
Write-Host "Service Principal id: $($objectId)";
# ------------------------------------------

# Create federated credentials
Write-Host ""
Write-Host "CREATING FEDERATED CREDENTIALS" -ForegroundColor Green

$federatedCredentials = Get-AzADAppFederatedCredential -ApplicationObjectId $clientObjectId
if ($federatedCredentials.Count -ne 1) {
    Write-Host "Creating federated credential for environment $($Stage)"
    New-AzADAppFederatedCredential                                  `
        -ApplicationObjectId $clientObjectId                        `
        -Audience "api://AzureADTokenExchange"                      `
        -Issuer "https://token.actions.githubusercontent.com"       `
        -Name "$($CustomerShortCode)-github-environment-$($Stage)"  `
        -Subject "repo:$($GitHubRepositoryPath):environment:$($Stage)"
}
else {
    Write-Host "Federated credential already created"
}
# ---------------------------------------

# Assign required roles to the service principal
Write-Host ""
Write-Host "ASSIGNING REQUIRED ROLES" -ForegroundColor Green

$subscriptionContributor = Get-AzRoleAssignment -ObjectId $objectId -RoleDefinitionName "Contributor" -Scope "/subscriptions/$($subscriptionId)"
if ($null -eq $subscriptionContributor) {
    Write-Host "Assigning Contributor role for scope subscription to $($objectId)"
    New-AzRoleAssignment -ObjectId $objectId -RoleDefinitionName "Contributor" -Scope "/subscriptions/$($subscriptionId)"
}
else {
    Write-Host "Contributor role for scope subscription already assigned to $($objectId)"
}
# ---------------------------------------

# Add app permissions
# Write-Host ""
# Write-Host "ADDING APP PERMISSIONS" -ForegroundColor Green

# $permissions = Get-AzADAppPermission -ObjectId $clientObjectId
# if ($permissions.Count -ne 4) {
#     Write-Host "Adding app permissions to $($appDiplayName)"
#     # Application.ReadWrite.OwnedBy
#     Add-AzADAppPermission -ApiId "00000003-0000-0000-c000-000000000000" -ObjectId $clientObjectId -PermissionId "18a4783c-866b-4cc7-a460-3d5e5662c884" -Type "Role"
#     Write-Host "Added permission 18a4783c-866b-4cc7-a460-3d5e5662c884"
#     # Application.ReadWrite.All
#     Add-AzADAppPermission -ApiId "00000003-0000-0000-c000-000000000000" -ObjectId $clientObjectId -PermissionId "1bfefb4e-e0b5-418b-a88f-73c46d2cc8e9" -Type "Role"
#     Write-Host "Added permission 1bfefb4e-e0b5-418b-a88f-73c46d2cc8e9"
#     # Directory.Read.All
#     Add-AzADAppPermission -ApiId "00000003-0000-0000-c000-000000000000" -ObjectId $clientObjectId -PermissionId "7ab1d382-f21e-4acd-a863-ba3e13f7da61" -Type "Role"
#     Write-Host "Added permission 7ab1d382-f21e-4acd-a863-ba3e13f7da61"
#     # Domain.Read.All
#     Add-AzADAppPermission -ApiId "00000003-0000-0000-c000-000000000000" -ObjectId $clientObjectId -PermissionId "dbb9058a-0e50-45d7-ae91-66909b5d4664" -Type "Role"
#     Write-Host "Added permission dbb9058a-0e50-45d7-ae91-66909b5d4664"
# }
# else {
#     Write-Host "App permissions already added to $($appDiplayName)"
# }
# Write-Host "REMEMBER TO GRANT ADMIN CONSENT TO THE PERMISSIONS IN THE AZURE PORTAL!" -ForegroundColor Yellow
# ---------------------------------------

Write-Host "Create GitHub secrets as described under https://learn.microsoft.com/en-us/azure/developer/github/connect-from-azure?tabs=azure-portal%2Cwindows#create-github-secrets"
Write-Host "AZURE_CLIENT_ID $($clientId)"
Write-Host "AZURE_TENANT_ID $($tenantId)"
Write-Host "AZURE_SUBSCRIPTION_ID $($subscriptionId)"
