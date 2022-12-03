# Purpose

This repository contains a Terraform template to deploy an Azure Function and Cloudflare Access in front of it.

Only users with corporate email (ex: @myCompany.com) will receive the pin code when prompted to enter their email in CF Access.

Only Cloudflare IP's will be allowed at Function's level.

# PowerShell script (Windows)

```powershell
az login

$subscription = "Training Subscription"
az account set --subscription $subscription

# Configuration

$rgName = "frbar-cfaccess"
$envName = "frbarmyapp" # lowercase, only a-z and 0-9
$location = "West Europe"
$emailDomain = "myCompany.com"

$env:CF_API_TOKEN  = "xxx"
$env:CF_ZONE_ID    = "xxx"
$env:CF_DOMAIN     = "myCompany.com"

# Infrastructure provisioning

./terraform.exe -chdir=tf init
./terraform.exe -chdir=tf apply -var "rg_name=$($rgName)" `
                                -var "env_name=$($envName)" `
                                -var "location=$($location1)" `
                                -var "cf_zone_id=$($env:CF_ZONE_ID)" `
                                -var "cf_api_token=$($env:CF_API_TOKEN)" `
                                -var "cf_domain=$($env:CF_DOMAIN)" `
                                -var "email_domain=$($emailDomain)" `
                                -auto-approve

# Build of the function

remove-item publish\* -recurse -force
dotnet publish src\ -c Release -o publish
Compress-Archive publish\* publish.zip -Force

# Deployment of the function

az functionapp deployment source config-zip --src .\publish.zip -n "$($envName)-func" -g $rgName

echo "done!"
```

# Tear down

```powershell
./terraform.exe -chdir=tf apply -destroy `
                                -var "rg_name=$($rgName)" `
                                -var "env_name=$($envName)" `
                                -var "location=$($location1)" `
                                -var "cf_zone_id=$($env:CF_ZONE_ID)" `
                                -var "cf_api_token=$($env:CF_API_TOKEN)" `
                                -var "cf_domain=$($env:CF_DOMAIN)" `
                                -var "email_domain=$($emailDomain)"
```