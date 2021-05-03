#Export an Azure Sentinel Workspace
Import-Module AZSentinel
Import-Module AZ.SecurityInsights
Import-Module Az.OperationalInsights
Import-Module AZ.Resources
Connect-AzAccount
$Subscription = Get-AzSubscription | Out-GridView -PassThru
Set-AzContext -Subscription $Subscription.SubscriptionId
$RG = Get-AzResourceGroup | Out-GridView -PassThru
$OppInsightWorkspace = Get-AzOperationalInsightsWorkspace -ResourceGroupName $RG.ResourceGroupName | Out-GridView -PassThru
$ruleExportPath = '.\'
Export-AzSentinel -WorkspaceName $OppInsightWorkspace.Name -outputfolder '.\' -Kind All
$DataConnectors = Get-AzSentinelDataConnector -WorkspaceName $OppInsightWorkspace.Name
Write-Host ("Exporting " + $DataConnectors.count + " Data Connectors...") -ForegroundColor Yellow
$DataConnectors | ConvertTo-Json -Depth 15 | Out-File ($ruleExportPath + "\" + "DataConnectors.json") -Force
Disconnect-AzAccount