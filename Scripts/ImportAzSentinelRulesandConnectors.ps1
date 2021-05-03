Import-Module AZ.Accounts -Global
Import-Module AZ.SecurityInsights -Global
Import-Module AZSentinel
Connect-AzAccount
$Subscription = Get-AzSubscription | Out-GridView -PassThru
Set-AzContext -Subscription $Subscription.SubscriptionId
$RG = Get-AzResourceGroup | Out-GridView -PassThru
$OppInsightWorkspace = Get-AzOperationalInsightsWorkspace -ResourceGroupName $RG.ResourceGroupName

#Import Alerts and Queries from JSON hosted on Github - Working
$settingsfile = Invoke-RestMethod "https://raw.githubusercontent.com/DataGuys/Sentinel/main/AnalyticsRules/analytics-rules.json"
$settingsfile.MicrosoftSecurityIncidentCreation | ConvertTo-Json -Depth 15 | Out-File .\AnalyticsRules\MSSecurityIncidentRules.json
$settingsfile.Scheduled | ConvertTo-Json -Depth 15 | Out-File .\AnalyticsRules\ScheduledRules.json
$settingsfile.Fusion | ConvertTo-Json -Depth 15 | Out-File .\AnalyticsRules\FusionRules.json
$settingsfile.MLBehaviorAnalytics | ConvertTo-Json -Depth 15 | Out-File .\AnalyticsRules\MLUBEA.json

##################### Format Json Files Properly #########################################
#Scheduled JSON
#Add RuleName to top of JSON File Formatter
$jsonfile = '.\AnalyticsRules\ScheduledRules.json'
'{'  + '"Scheduled": ' +  (Get-Content $jsonfile -raw) | Set-Content $jsonfile
#Append bracket to end of json file
Add-Content $jsonfile "}"
### End Scheduled JSON ####
### MSSecurity Incidents JSON
#Add RuleName to top of JSON File Formatter
$jsonfile = '.\AnalyticsRules\MSSecurityIncidentRules.json'
'{'  + '"MicrosoftSecurityIncidentCreation": ' +  (Get-Content $jsonfile -raw) | Set-Content $jsonfile 
#Append bracket to end of json file
Add-Content $jsonfile "}"
#### MsSecurity End
##### MLAnalyticsRules
#Add RuleName to top of JSON File Formatter
$jsonfile = '.\AnalyticsRules\MLUBEA.json'
'{'  + '"MLBehaviorAnalytics": ' +  (Get-Content $jsonfile -raw) | Set-Content $jsonfile
#Append bracket to end of json file
Add-Content $jsonfile "}"
#### End ML Rules Formating ####
#### Fusion Rules Formatting Start
#Add RuleName to top of JSON File Formatter
$jsonfile = '.\AnalyticsRules\FusionRules.json'
'{'  + '"Fusion": [' +  (Get-Content $jsonfile -raw) | Set-Content $jsonfile
#Append bracket to end of json file
Add-Content $jsonfile "] }"
#End Fusion Rules Json Formatting
#Update JSON with Tenantid and Subscriptionid from the Subscription choice above
(Get-Content ".\AnalyticsRules\MSSecurityIncidentRules.json") -replace ('"subscriptionId"\:."([^"]*)"'), ('"subscriptionId": ' + $Subscription.SubscriptionId) | Out-Null
(Get-Content ".\AnalyticsRules\MSSecurityIncidentRules.json") -replace ('"tenantId"\:."([^"]*)"'), ('"tenantId": ' + $Subscription.TenantId) | Out-Null
(Get-Content ".\AnalyticsRules\ScheduledRules.json") -replace ('"subscriptionId"\:."([^"]*)"'), ('"subscriptionId": ' + $Subscription.SubscriptionId) | Out-Null
(Get-Content ".\AnalyticsRules\ScheduledRules.json") -replace ('"tenantId"\:."([^"]*)"'), ('"tenantId": ' + $Subscription.TenantId) | Out-Null
(Get-Content ".\AnalyticsRules\FusionRules.json") -replace ('"subscriptionId"\:."([^"]*)"'), ('"subscriptionId": ' + $Subscription.SubscriptionId) | Out-Null
(Get-Content ".\AnalyticsRules\FusionRules.json") -replace ('"tenantId"\:."([^"]*)"'), ('"tenantId": ' + $Subscription.TenantId) | Out-Null
(Get-Content ".\AnalyticsRules\MLUBEA.json") -replace ('"subscriptionId"\:."([^"]*)"'), ('"subscriptionId": ' + $Subscription.SubscriptionId) | Out-Null
(Get-Content ".\AnalyticsRules\MLUBEA.json") -replace ('"tenantId"\:."([^"]*)"'), ('"tenantId": ' + $Subscription.TenantId) | Out-Null
#End formatting JSON Files

#Start import of Alert rules Json files
Import-AzSentinelAlertRule -WorkspaceName $OppInsightWorkspace.Name -SubscriptionId $Subscription.SubscriptionId -SettingsFile '.\AnalyticsRules\MSSecurityIncidentRules.json' -ErrorAction Continue
Import-AzSentinelAlertRule -WorkspaceName $OppInsightWorkspace.Name -SubscriptionId $Subscription.SubscriptionId -SettingsFile '.\AnalyticsRules\ScheduledRules.json' -ErrorAction Continue
Import-AzSentinelAlertRule -WorkspaceName $OppInsightWorkspace.Name -SubscriptionId $Subscription.SubscriptionId -SettingsFile '.\AnalyticsRules\FusionRules.json' -ErrorAction Continue
Import-AzSentinelAlertRule -WorkspaceName $OppInsightWorkspace.Name -SubscriptionId $Subscription.SubscriptionId -SettingsFile '.\AnalyticsRules\MLUBEA.json' -ErrorAction Continue

#Enable default Azure and Office 365 connectors
New-AzSentinelDataConnector -ResourceGroupName $rg.ResourceGroupName -WorkspaceName $OppInsightWorkspace.Name -MicrosoftCloudAppSecurity -Alerts Enabled -DiscoveryLogs Enabled
New-AzSentinelDataConnector -ResourceGroupName $rg.ResourceGroupName -WorkspaceName $OppInsightWorkspace.Name -AzureActiveDirectory -Alerts Enabled
New-AzSentinelDataConnector -ResourceGroupName $rg.ResourceGroupName -WorkspaceName $OppInsightWorkspace.Name -AzureAdvancedThreatProtection -Alerts Enabled
New-AzSentinelDataConnector -ResourceGroupName $rg.ResourceGroupName -WorkspaceName $OppInsightWorkspace.Name -AzureSecurityCenter -Alerts Enabled -SubscriptionId $Subscription.SubscriptionId
New-AzSentinelDataConnector -ResourceGroupName $rg.ResourceGroupName -WorkspaceName $OppInsightWorkspace.Name -Office365 -SharePoint Enabled -Exchange Enabled -Teams Enabled 
New-AzSentinelDataConnector -ResourceGroupName $rg.ResourceGroupName -WorkspaceName $OppInsightWorkspace.Name -MicrosoftDefenderAdvancedThreatProtection -alerts Enabled
New-AzSentinelDataConnector -ResourceGroupName $rg.ResourceGroupName -WorkspaceName $OppInsightWorkspace.Name -ThreatIntelligence -Indicators Enabled

#Import Connectors From JSON
$settingsfile = Invoke-RestMethod "https://raw.githubusercontent.com/DataGuys/Sentinel/main/Connectors/connectors.json"
$settingsfile.connectors | ConvertTo-Json -Depth 15 | Out-File .\Connectors\connectors.json
(Get-Content ".\Connectors\Connectors.json") -replace ('"subscriptionId"\:."([^"]*)"'), ('"subscriptionId": ' + $Subscription.SubscriptionId) | Out-Null
(Get-Content ".\Connectors\Connectors.json") -replace ('"tenantId"\:."([^"]*)"'), ('"tenantId": ' + $Subscription.TenantId) | Out-Null
$jsonfile = '.\Connectors\connectors.json'
'{'  + '"Connectors": ' +  (Get-Content $jsonfile -raw) | Set-Content $jsonfile
#Append bracket to end of json file
Add-Content $jsonfile " }"
#End formatting of JSON connectors file
#Import Script outside of this file
.\Scripts\SentinelAllInOneConnectors.ps1 -ResourceGroup $rg.ResourceGroupName -Workspace $OppInsightWorkspace.Name -Location $location.Location -ErrorAction SilentlyContinue
Disconnect-AzAccount