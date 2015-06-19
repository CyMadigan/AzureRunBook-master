<#
.SYNOPSIS 
    Sets up the connection to an Azure subscription

.DESCRIPTION
    WARNING: This runbook is deprecated. Please use OrgID credential auth to connect to Azure, instead of
	certificate auth using this runbook. You can learn more about using credential auth with Azure here:
	http://aka.ms/Sspv1l
	
	This runbook sets up a connection to an Azure subscription.
    Requirements: 
        1. Automation Certificate Asset containing the management certificate loaded to Azure 
        2. Automation Connection Asset containing the subscription id and the name of the certificate 
           setting in Automation Assets 


.PARAMETER AzureConnectionName
    Name of the Azure connection setting that was created in the Automation service.
    This connection setting contains the subscription id and the name of the certificate setting that 
    holds the management certificate.

.EXAMPLE
    Connect-Azure -AzureConnectionName "Visual Studio Ultimate with MSDN"

.NOTES
    AUTHOR: System Center Automation Team
    LASTEDIT: Aug 14, 2014 
#>

workflow Connect-Azure
{
   # By default, errors in PowerShell do not cause workflows to suspend, like exceptions do.
	# This means a runbook can still reach 'completed' state, even if it encounters errors
	# during execution. The below command will cause all errors in the runbook to be thrown as
	# exceptions, therefore causing the runbook to suspend when an error is hit.
	$ErrorActionPreference = "Stop"
	
	# Grab the credential to use to authenticate to Azure. 
	# TODO: Fill in the -Name parameter with the name of the Automation PSCredential asset
	# that has access to your Azure subscription
	$Cred = Get-AutomationPSCredential -Name "kevraj@microsoft.com"

	# Connect to Azure
	Add-AzureAccount -Credential $Cred | Write-Verbose

	# Select the Azure subscription you want to work against
	# TODO: Fill in the -SubscriptionName parameter with the name of your Azure subscription
	Select-AzureSubscription -SubscriptionName "Visual Studio Ultimate with MSDN" | Write-Verbose
}