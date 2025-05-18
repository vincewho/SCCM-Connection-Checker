#Requires -Version 5.1

. .\Invoke-ServerConnectivityChecks.ps1

# SCCM Connectivity Checker v1.1
#------------------------------------------------------------------------------------
#region GUI Creation and Event Handling (Frontend)
#------------------------------------------------------------------------------------
Add-Type -AssemblyName System.Windows.Forms
Add-Type -AssemblyName System.Drawing

# Main Form
$Global:mainForm = New-Object System.Windows.Forms.Form # Make it global for easy access in GUI functions
$mainForm.Text = "SCCM Connectivity Checker v1.1"
$mainForm.Size = New-Object System.Drawing.Size(650, 600) # Slightly wider for timestamps
$mainForm.StartPosition = "CenterScreen"
$mainForm.FormBorderStyle = [System.Windows.Forms.FormBorderStyle]::FixedSingle
$mainForm.MaximizeBox = $false

# Font
$font = New-Object System.Drawing.Font("Segoe UI", 10)
$mainForm.Font = $font

# Labels and Textboxes for Server Inputs
$labelMP = New-Object System.Windows.Forms.Label
$labelMP.Text = "Management Point (MP):"
$labelMP.Location = New-Object System.Drawing.Point(20, 25)
$labelMP.Size = New-Object System.Drawing.Size(180, 20)
$mainForm.Controls.Add($labelMP)

$Global:textBoxMP = New-Object System.Windows.Forms.TextBox # Global for access in button click
$textBoxMP.Location = New-Object System.Drawing.Point(200, 20)
$textBoxMP.Size = New-Object System.Drawing.Size(410, 25)
$mainForm.Controls.Add($textBoxMP)

$labelDP = New-Object System.Windows.Forms.Label
$labelDP.Text = "Distribution Point (DP):"
$labelDP.Location = New-Object System.Drawing.Point(20, 65)
$labelDP.Size = New-Object System.Drawing.Size(180, 20)
$mainForm.Controls.Add($labelDP)

$Global:textBoxDP = New-Object System.Windows.Forms.TextBox # Global
$textBoxDP.Location = New-Object System.Drawing.Point(200, 60)
$textBoxDP.Size = New-Object System.Drawing.Size(410, 25)
$mainForm.Controls.Add($textBoxDP)

$labelDB = New-Object System.Windows.Forms.Label
$labelDB.Text = "Database Server (DB):"
$labelDB.Location = New-Object System.Drawing.Point(20, 105)
$labelDB.Size = New-Object System.Drawing.Size(180, 20)
$mainForm.Controls.Add($labelDB)

$Global:textBoxDB = New-Object System.Windows.Forms.TextBox # Global
$textBoxDB.Location = New-Object System.Drawing.Point(200, 100)
$textBoxDB.Size = New-Object System.Drawing.Size(410, 25)
$mainForm.Controls.Add($textBoxDB)

# Results Textbox
$Global:textBoxResults = New-Object System.Windows.Forms.RichTextBox # Global
$textBoxResults.Location = New-Object System.Drawing.Point(20, 180)
$textBoxResults.Size = New-Object System.Drawing.Size(590, 330) # Adjusted size
$textBoxResults.Multiline = $true
$textBoxResults.ScrollBars = [System.Windows.Forms.RichTextBoxScrollBars]::Vertical # Enum is slightly different
$textBoxResults.ReadOnly = $true
$textBoxResults.Font = New-Object System.Drawing.Font("Consolas", 9.5)
$mainForm.Controls.Add($textBoxResults)

# Status Label
$Global:statusLabel = New-Object System.Windows.Forms.Label # Global
$statusLabel.Text = "Enter server names and click 'Run Checks'."
$statusLabel.Location = New-Object System.Drawing.Point(20, 520) # Adjusted location
$statusLabel.Size = New-Object System.Drawing.Size(590, 20)
$statusLabel.ForeColor = [System.Drawing.Color]::Blue
$mainForm.Controls.Add($statusLabel)

# Run Checks Button
$Global:runButton = New-Object System.Windows.Forms.Button # Global
$runButton.Text = "Run Checks"
$runButton.Location = New-Object System.Drawing.Point(230, 140) # Centered a bit
$runButton.Size = New-Object System.Drawing.Size(180, 30)
$runButton.BackColor = [System.Drawing.Color]::LightGreen
$runButton.FlatStyle = [System.Windows.Forms.FlatStyle]::Flat
$runButton.FlatAppearance.BorderSize = 1
$runButton.FlatAppearance.BorderColor = [System.Drawing.Color]::DarkGreen
$mainForm.Controls.Add($runButton)

# Function to update the GUI results textbox
Function Update-ResultsDisplay {
    param (
        [PSCustomObject]$ResultItem
    )

    $color = switch ($ResultItem.Status) {
        "Success" { [System.Drawing.Color]::Green }
        "Failure" { [System.Drawing.Color]::Red }
        "Warning" { [System.Drawing.Color]::OrangeRed }
        "Header" { [System.Drawing.Color]::DarkBlue }
        "SubHeader" { [System.Drawing.Color]::DarkSlateGray }
        default { [System.Drawing.Color]::Black }
    }

    $textBoxResults.SelectionStart = $textBoxResults.TextLength
    $textBoxResults.SelectionLength = 0
    $textBoxResults.SelectionColor = $color
    $textBoxResults.AppendText("$($ResultItem.Timestamp.ToString('yyyy-MM-dd HH:mm:ss')) - $($ResultItem.Message)`r`n")
    $textBoxResults.ScrollToCaret()
}

# Event Handler for the Run Button
$runButton.Add_Click(
    {
        $textBoxResults.Clear()
        $statusLabel.Text = "Running checks... Please wait."
        $statusLabel.ForeColor = [System.Drawing.Color]::OrangeRed
        $mainForm.Cursor = [System.Windows.Forms.Cursors]::WaitCursor
        $runButton.Enabled = $false
        $mainForm.Update() # Ensure UI updates before long operations

        # Get server names from textboxes
        $mpServer = $textBoxMP.Text.Trim()
        $dpServer = $textBoxDP.Text.Trim()
        $dbServer = $textBoxDB.Text.Trim()

        # Process each server
        $serversToTest = @(
            @{ Name = $mpServer; Type = "MP" }
            @{ Name = $dpServer; Type = "DP" }
            @{ Name = $dbServer; Type = "DB" }
        )

        foreach ($server in $serversToTest) {
            $checkResults = Invoke-ServerConnectivityChecks -ServerName $server.Name -ServerType $server.Type
            foreach ($item in $checkResults) {
                Update-ResultsDisplay -ResultItem $item
            }
            # Add a blank line in the display if there were results for this server
            if ($checkResults.Count -gt 0 -and $checkResults[0].Message -notmatch "No server name provided") {
                $textBoxResults.AppendText("`r`n")
            }
            $mainForm.Update() # Update GUI after each server's checks
        }

        Update-ResultsDisplay -ResultItem ([PSCustomObject]@{
                Timestamp = Get-Date
                Message   = "All checks complete."
                Status    = "Info"
            })

        $statusLabel.Text = "Checks complete. Review results above."
        $statusLabel.ForeColor = [System.Drawing.Color]::DarkGreen
        $mainForm.Cursor = [System.Windows.Forms.Cursors]::Default
        $runButton.Enabled = $true
    }
)

# Show the form
$mainForm.ShowDialog() | Out-Null

#region Cleanup
# Dispose of form elements if necessary
# $mainForm.Dispose() # Usually handled by PowerShell when script ends
#endregion Cleanup

#endregion GUI Logic
