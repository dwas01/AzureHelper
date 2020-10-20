Function Get-AHBackedUpVMs {
    <#
.SYNOPSIS
    Gets the backed up VMs and their status
.DESCRIPTION
    Gets the backed up VMs and their status
.PARAMETER AllSubscriptions
    Run this command against all subscriptions.
.PARAMETER Subscription
    Specifies the subscription to run against. The default is the current subscription.
.EXAMPLE
    Get-AHBackedUpVMs

    Lists all backed up VMs in the subscription
.INPUTS
    String
.OUTPUTS
    Selected.System.String
.NOTES
    Author:  Paul Harrison
#>

    [CmdletBinding()]
    param (
        [Switch]
        $AllSubscriptions,
    
        [Parameter(ValueFromPipeline = $true)]
        $Subscription
    )
    begin {
        $MyScriptBlock = {
            $fgColor = [console]::ForegroundColor
            try { az account set --subscription ((Get-AzContext).Subscription.Id) }
            catch { throw }
            $sub = ((Get-AzContext).Subscription.Name)
            $VMList = @()
            ForEach ($Vault in (Get-AzRecoveryServicesVault)) {
                $VMs = az backup item list --resource-group $($Vault.ResourceGroupName) --vault-name $($Vault.Name) | ConvertFrom-Json
                ForEach ($item in ($VMs | Where-Object { ($_.Name -split (';'))[0] -eq 'VM' })) {
                    $VM = "" | Select-Object 'Subscription', 'VMName', 'ResourceGroupName', 'VaultName', 'LastBackupStatus', 'LastBackupTime', 'Id'
                    $VM.Id = ($item.Id -split (';'))[0]
                    $VM.Subscription = $sub
                    $VM.VMName = $item.properties.FriendlyName
                    $VM.ResourceGroupName = $item.ResourceGroup
                    $VM.VaultName = $Vault.Name
                    $VM.LastBackupStatus = $item.properties.LastBackupStatus
                    $VM.LastBackupTime = $item.properties.LastBackupTime
                    $VMList += $VM
                }
            }
            [console]::ForegroundColor = $fgColor
            $VMList
        }
    }
    process {
        if ($Subscription) { $Subscription | Invoke-AzureCommand -ScriptBlock $MyScriptBlock }
        else { Invoke-AzureCommand -ScriptBlock $MyScriptBlock -AllSubscriptions:$AllSubscriptions }
    }
}