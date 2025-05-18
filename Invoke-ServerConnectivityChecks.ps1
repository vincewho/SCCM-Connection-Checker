#Requires -Version 5.1
<#
.SYNOPSIS
    A PowerShell script with a GUI to check connectivity to SCCM servers (DP, MP, Database).
    This version separates GUI logic from connectivity testing functions.
.DESCRIPTION
    This script provides a simple graphical interface to input SCCM server names
    and performs basic connectivity tests like ping and port checks.
    The connectivity logic is designed to be more independent of the GUI.
.NOTES
    Author: Vincent Li
    Version: 1.1
    Ensure PowerShell execution policy allows running scripts.
    Run with appropriate permissions if checking remote services or WMI.
#>

#------------------------------------------------------------------------------------
#region Core Connectivity Logic (Backend - Could be moved to a .psm1 module)
#------------------------------------------------------------------------------------

Function Invoke-ServerConnectivityChecks {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $true)]
        [string]$ServerName,

        [Parameter(Mandatory = $true)]
        [ValidateSet("MP", "DP", "DB")]
        [string]$ServerType
    )

    $results = [System.Collections.Generic.List[PSCustomObject]]::new()

    # Helper to add a structured result
    Function Add-CheckResult {
        param ($Message, $Status = "Info", [switch]$IsHeader)
        $results.Add([PSCustomObject]@{
                Timestamp = Get-Date
                Message   = $Message
                Status    = $Status # "Success", "Failure", "Warning", "Info", "Header", "SubHeader"
                IsHeader  = $IsHeader.IsPresent
            })
    }

    if ([string]::IsNullOrWhiteSpace($ServerName)) {
        Add-CheckResult -Message "No server name provided for $ServerType. Skipping." -Status "Warning"
        return $results
    }

    Add-CheckResult -Message "--- Starting checks for $ServerType - $ServerName ---" -Status "Header" -IsHeader

    # 1. DNS Resolution Check
    Add-CheckResult -Message "Performing DNS Resolution for $ServerName..." -Status "SubHeader"
    try {
        $ipAddress = [System.Net.Dns]::GetHostAddresses($ServerName)[0].IPAddressToString
        Add-CheckResult -Message "DNS Resolution for $ServerName - SUCCESS ($ipAddress)" -Status "Success"
    }
    catch {
        Add-CheckResult -Message "DNS Resolution for $ServerName - FAILED ($($_.Exception.Message))" -Status "Failure"
        Add-CheckResult -Message "--- Ending checks for $ServerType - $ServerName (DNS resolution failed) ---" -Status "Header" -IsHeader
        return $results # Stop further checks if DNS fails
    }

    # 2. Ping Test
    Add-CheckResult -Message "Pinging $ServerName..." -Status "SubHeader"
    if (Test-Connection -ComputerName $ServerName -Count 2 -Quiet -ErrorAction SilentlyContinue) {
        Add-CheckResult -Message "Ping $ServerName - SUCCESS" -Status "Success"
    }
    else {
        Add-CheckResult -Message "Ping $ServerName - FAILED" -Status "Failure"
    }

    # 3. Port Checks
    Add-CheckResult -Message "Performing Port Checks for $ServerName..." -Status "SubHeader"
    $portsToCheck = @{}
    switch ($ServerType) {
        "MP" { $portsToCheck = @{80 = "HTTP"; 443 = "HTTPS" } }
        "DP" { $portsToCheck = @{80 = "HTTP"; 443 = "HTTPS"; 445 = "SMB" } }
        "DB" { $portsToCheck = @{1433 = "SQL Server"; 1434 = "SQL Browser (UDP)" } }
    }

    foreach ($portInfo in $portsToCheck.GetEnumerator()) {
        $port = $portInfo.Name
        $protocolName = $portInfo.Value
        $isUdp = ($protocolName -like "*UDP*")

        Add-CheckResult -Message "Testing port $port ($protocolName)..."
        try {
            if ($isUdp) {
                Add-CheckResult -Message "Port $port ($protocolName): UDP - Manual check recommended. Test-NetConnection is not reliable for UDP." -Status "Warning"
            }
            else {
                $tcpTest = Test-NetConnection -ComputerName $ServerName -Port $port -InformationLevel Quiet -ErrorAction SilentlyContinue -WarningAction SilentlyContinue -ConnectTimeoutSeconds 5
                if ($tcpTest.TcpTestSucceeded) {
                    Add-CheckResult -Message "Port $port ($protocolName): OPEN" -Status "Success"
                }
                else {
                    Add-CheckResult -Message "Port $port ($protocolName): CLOSED or FILTERED" -Status "Failure"
                }
            }
        }
        catch {
            Add-CheckResult -Message "Port $port ($protocolName): ERROR testing ($($_.Exception.Message))" -Status "Failure"
        }
    }
    Add-CheckResult -Message "--- Finished checks for $ServerType - $ServerName ---" -Status "Header" -IsHeader
    return $results
}

#endregion Core Connectivity Logic