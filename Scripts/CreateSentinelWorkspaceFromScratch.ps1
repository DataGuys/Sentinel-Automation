#Install-Module AZSentinel -AllowClobber
Import-Module Az.SecurityInsights -Global
Import-Module Az.Accounts -Global
Import-Module Azsentinel -Force
Connect-AzAccount
Set-Location -Path $env:OneDriveCommercial\SentinelExport
$subscriptionId = Get-AzSubscription | Out-GridView -PassThru
$subscriptionId = $subscriptionId.SubscriptionId
Set-AzContext -Subscription $subscriptionId
$location = Get-AzLocation | Where-Object {$_.Providers -contains "Microsoft.OperationalInsights"} | Sort-Object DisplayName | Out-GridView -PassThru
$SentinelWorkspaceName = "Sentinel-" + $location.Location + "-" + (Get-Random -maximum 200)
#Create the resource group
$resourceGroupCreated = New-AzResourceGroup -Name $SentinelWorkspaceName -Location $location.Location
#Create the Sentinel Workspace with underlying LAW
$workspaceName = New-AzOperationalInsightsWorkspace -Name $resourceGroupCreated.ResourceGroupName -ResourceGroupName $resourceGroupCreated.ResourceGroupName -Location $location.Location -PublicNetworkAccessForIngestion Enabled -PublicNetworkAccessForQuery Enabled -RetentionInDays 90 -Sku pergb2018
Set-AzSentinel -subscriptionid  $subscriptionId -WorkspaceName $workspaceName.Name -Confirm:$false
#Enable default insight intelligencepacks on the Sentinel Workspace
Set-AzOperationalInsightsIntelligencepack -ResourceGroupName $resourceGroupCreated.ResourceGroupName -WorkspaceName $workspaceName.ResourceGroupName -IntelligencePackName SecurityInsights -Enabled $true
Set-AzOperationalInsightsIntelligencepack -ResourceGroupName $resourceGroupCreated.ResourceGroupName -WorkspaceName $workspaceName.ResourceGroupName -IntelligencePackName AzureResources -Enabled $true
Disconnect-Azaccount

