#Write-Output "PowerShell function executing at:$(get-date)";
# Input bindings are passed in via param block.
param($Timer)

# Get the current universal time in the default string format.
$currentUTCtime = (Get-Date).ToUniversalTime()

# The 'IsPastDue' property is 'true' when the current function invocation is later than scheduled.
if ($Timer.IsPastDue) {
    Write-Host "PowerShell timer is running late!"
}

# Write an information log with the current time.
Write-Host "PowerShell timer trigger function ran! TIME: $currentUTCtime"

#Environment creds
Import-Module AzureAD -UseWindowsPowerShell
$azureAplicationId ='Your app id'
$azureTenantId= 'your tennat id'
$azurePassword = ConvertTo-SecureString "your app password" -AsPlainText -Force
$psCred = New-Object System.Management.Automation.PSCredential($azureAplicationId , $azurePassword)
Connect-AzAccount -Credential $psCred -TenantId $azureTenantId -ServicePrincipal
#Get addtoken
$context = [Microsoft.Azure.Commands.Common.Authentication.Abstractions.AzureRmProfileProvider]::Instance.Profile.DefaultContext
$aadToken = [Microsoft.Azure.Commands.Common.Authentication.AzureSession]::Instance.AuthenticationFactory.Authenticate($context.Account, $context.Environment, $context.Tenant.Id.ToString(), $null, [Microsoft.Azure.Commands.Common.Authentication.ShowDialog]::Never, $null, "https://graph.windows.net").AccessToken
Connect-AzureAD -AadAccessToken $aadToken -AccountId $context.Account.Id -TenantId $context.tenant.id
#Main
$NullLocation = Get-AzureADUser -All $true | Where {$_.UsageLocation -eq $Null}
if($NullLocation.Count -ge 1){
    Write-Host "Found user without UsageLocation $($NullLocation.Count)"
        foreach($user in $NullLocation){
        Set-AzureADUser -ObjectId $user.ObjectId -UsageLocation RU
	$as += ":users: $($user.UserPrincipalName) `n"
        }
}else{
	Write-Host "User not found without UsageLocation"
}
#send to slack or other information
if($NullLocation.Count -ge 1){
$SlackText = "Found user without UsageLocation $($NullLocation.Count)`n" + $as
$URLSlack = 'your slack webhook'
$SlackTextJson = @{ text=$SlackText} | ConvertTo-Json
Invoke-WebRequest -Uri $URLSlack  -Method POS -body $SlackTextJson -ContentType "text/json; charset=utf-8"

}

Write-Output "PowerShell function executed at:$(get-date)"