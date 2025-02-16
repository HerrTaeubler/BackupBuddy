Add-Type -AssemblyName System.Windows.Forms
Add-Type -AssemblyName System.Drawing

# Config Path
$configPath = Join-Path $env:APPDATA "BackupBuddy\BackupBuddy_config.json"
$configDir = Split-Path $configPath -Parent

# Create directory if it doesn't exist
if (-not (Test-Path $configDir)) {
    New-Item -ItemType Directory -Path $configDir -Force | Out-Null
}

# Configuration
$config = @{
    SourceDirs = [System.Collections.ArrayList]@()
    TargetDir = ""
    IsDarkMode = $false
}

# Create the main form and UI elements first
$form = New-Object System.Windows.Forms.Form
$form.Text = "BackupBuddy"
$form.Size = New-Object System.Drawing.Size(700, 1050)  
$form.FormBorderStyle = [System.Windows.Forms.FormBorderStyle]::Fixed3D
$form.MaximizeBox = $false
$form.StartPosition = [System.Windows.Forms.FormStartPosition]::CenterScreen

# Create UI elements
$sourceLabel = New-Object System.Windows.Forms.Label
$sourceList = New-Object System.Windows.Forms.ListBox
$addSourceBtn = New-Object System.Windows.Forms.Button
$removeSourceBtn = New-Object System.Windows.Forms.Button
$targetLabel = New-Object System.Windows.Forms.Label
$targetPathLabel = New-Object System.Windows.Forms.Label
$selectTargetBtn = New-Object System.Windows.Forms.Button
$progressBar = New-Object System.Windows.Forms.ProgressBar
$statusLabel = New-Object System.Windows.Forms.Label
$backupBtn = New-Object System.Windows.Forms.Button

# Style Settings
$primaryColor = [System.Drawing.Color]::FromArgb(0, 120, 212)     # Microsoft Blue
$accentColor = [System.Drawing.Color]::FromArgb(0, 102, 190)      # Darker Blue for hover
$backgroundColor = [System.Drawing.Color]::White                   # Clean white background
$panelColor = [System.Drawing.Color]::FromArgb(245, 245, 245)     # Light gray for panels
$buttonTextColor = [System.Drawing.Color]::White
$labelColor = [System.Drawing.Color]::FromArgb(51, 51, 51)
$borderRadius = 8  # For rounded corners

# Dark Mode Colors
$darkModeColors = @{
    Primary = [System.Drawing.Color]::FromArgb(0, 120, 212)      
    Accent = [System.Drawing.Color]::FromArgb(0, 102, 190)       
    Background = [System.Drawing.Color]::FromArgb(32, 32, 32)    # Dark gray
    Panel = [System.Drawing.Color]::FromArgb(45, 45, 45)         # Slightly lighter gray
    Text = [System.Drawing.Color]::FromArgb(240, 240, 240)       # Light gray
    ButtonText = [System.Drawing.Color]::White                    # White
}

# Light Mode Colors
$lightModeColors = @{
    Primary = $primaryColor
    Accent = $accentColor
    Background = $backgroundColor
    Panel = $panelColor
    Text = $labelColor
    ButtonText = $buttonTextColor
}

$script:isDarkMode = $false

function Toggle-DarkMode {
    param(
        [bool]$force = $false,
        [bool]$state = $false
    )
    
    if ($force) {
        $script:isDarkMode = $state
    } else {
        $script:isDarkMode = -not $script:isDarkMode
    }
    
    $config.IsDarkMode = $script:isDarkMode
    $colors = if ($script:isDarkMode) { $darkModeColors } else { $lightModeColors }
    
    # Update Form
    $form.BackColor = $colors.Background
    $form.ForeColor = $colors.Text
    $containerPanel.BackColor = $colors.Panel
    
    # Update Panels
    $sourcePanel.BackColor = $colors.Panel
    $targetPanel.BackColor = $colors.Panel
    $progressPanel.BackColor = $colors.Panel
    $buttonPanel.BackColor = $colors.Panel
    
    # Update Lists
    $sourceList.BackColor = $colors.Panel
    $sourceList.ForeColor = $colors.Text
    
    # Update Labels
    $sourceLabel.ForeColor = $colors.Text
    $targetLabel.ForeColor = $colors.Text
    $targetPathLabel.ForeColor = $colors.Text
    $statusLabel.ForeColor = $colors.Text
    
    # Update Buttons (except Toggle-Button)
    $buttons = @($addSourceBtn, $removeSourceBtn, $selectTargetBtn, $backupBtn)
    foreach ($button in $buttons) {
        if ($button.Enabled) {
            $button.BackColor = $colors.Primary
        }
        $button.ForeColor = $colors.ButtonText
    }
    
    # Dark Mode Button Text update
    $darkModeBtn.Text = if ($script:isDarkMode) { "Light Mode" } else { "Dark Mode" }
    
    
    Save-Config
    
    # Log Panel and TextBox update
    $logPanel.BackColor = $colors.Panel
    $logTextBox.BackColor = $colors.Panel
    $logTextBox.ForeColor = $colors.Text
    
    # Log Label
    $logLabel.ForeColor = $colors.Text

    # Backup Button Panel update
    $backupButtonPanel.BackColor = $colors.Panel
}

# Form styling
$form.BackColor = $backgroundColor
$form.Font = New-Object System.Drawing.Font("Segoe UI", 9, [System.Drawing.FontStyle]::Regular)
$form.ForeColor = $labelColor
$form.Padding = New-Object System.Windows.Forms.Padding(30)
$form.MinimumSize = New-Object System.Drawing.Size(700, 1000)
$form.Size = New-Object System.Drawing.Size(700, 1000)
$form.MaximumSize = New-Object System.Drawing.Size(700, 1000)
$form.FormBorderStyle = [System.Windows.Forms.FormBorderStyle]::FixedSingle
$form.StartPosition = [System.Windows.Forms.FormStartPosition]::CenterScreen

# Container Panel
$containerPanel = New-Object System.Windows.Forms.Panel
$containerPanel.Dock = [System.Windows.Forms.DockStyle]::Fill
$containerPanel.AutoScroll = $true
$containerPanel.Padding = New-Object System.Windows.Forms.Padding(20)
$containerPanel.BackColor = $panelColor
$form.Controls.Add($containerPanel)

# Source List Panel
$sourcePanel = New-Object System.Windows.Forms.Panel
$sourcePanel.BackColor = [System.Drawing.Color]::White
$sourcePanel.Location = New-Object System.Drawing.Point(20, 20)
$sourcePanel.Size = New-Object System.Drawing.Size(640, 220)
$sourcePanel.Padding = New-Object System.Windows.Forms.Padding(15)
$sourcePanel.Anchor = [System.Windows.Forms.AnchorStyles]::Top -bor [System.Windows.Forms.AnchorStyles]::Left -bor [System.Windows.Forms.AnchorStyles]::Right
$sourcePanel.Width = $containerPanel.ClientSize.Width - 40
$sourcePanel.BorderStyle = [System.Windows.Forms.BorderStyle]::None
$containerPanel.Controls.Add($sourcePanel)

# Style source list
$sourceList.Dock = [System.Windows.Forms.DockStyle]::Fill
$sourceList.BorderStyle = [System.Windows.Forms.BorderStyle]::None
$sourceList.Font = New-Object System.Drawing.Font("Segoe UI", 10, [System.Drawing.FontStyle]::Regular)
$sourceList.BackColor = [System.Drawing.Color]::White
$sourceList.ForeColor = $labelColor
$sourceList.IntegralHeight = $false
$sourceList.Anchor = [System.Windows.Forms.AnchorStyles]::Top -bor [System.Windows.Forms.AnchorStyles]::Left -bor [System.Windows.Forms.AnchorStyles]::Right
$sourceList.Height = 120

# Style labels
$sourceLabel.Font = New-Object System.Drawing.Font("Segoe UI", 12, [System.Drawing.FontStyle]::Bold)
$targetLabel.Font = New-Object System.Drawing.Font("Segoe UI", 12, [System.Drawing.FontStyle]::Bold)

# Enhanced button style function
function Set-ButtonStyle {
    param($button)
    $button.FlatStyle = [System.Windows.Forms.FlatStyle]::Flat
    $button.BackColor = $primaryColor
    $button.ForeColor = $buttonTextColor
    $button.FlatAppearance.BorderSize = 0
    $button.Font = New-Object System.Drawing.Font("Segoe UI", 9, [System.Drawing.FontStyle]::Regular)
    $button.Cursor = [System.Windows.Forms.Cursors]::Hand
    $button.Padding = New-Object System.Windows.Forms.Padding(3)
    $button.Height = 35
    $button.FlatAppearance.MouseOverBackColor = $accentColor
    $button.FlatAppearance.MouseDownBackColor = $primaryColor

    # Hover Effect
    $button.Add_MouseEnter({
        $this.BackColor = $accentColor
    })
    $button.Add_MouseLeave({
        $this.BackColor = $primaryColor
    })
}

# Apply button styles
Set-ButtonStyle $addSourceBtn
Set-ButtonStyle $removeSourceBtn
Set-ButtonStyle $selectTargetBtn
Set-ButtonStyle $backupBtn

# Make backup button more prominent
$backupBtn.Height = 50
$backupBtn.Font = New-Object System.Drawing.Font("Segoe UI", 11, [System.Drawing.FontStyle]::Bold)

# Source List Label
$sourceLabel.Location = New-Object System.Drawing.Point(15, 15)
$sourceLabel.Size = New-Object System.Drawing.Size(200, 25)
$sourceLabel.Text = "Source Directories:"
$sourcePanel.Controls.Add($sourceLabel)

# Source List Box
$sourceList.Location = New-Object System.Drawing.Point(15, 45)
$sourceList.Size = New-Object System.Drawing.Size(610, 120)
$sourcePanel.Controls.Add($sourceList)

# Button Panel
$buttonPanel = New-Object System.Windows.Forms.Panel
$buttonPanel.BackColor = [System.Drawing.Color]::White
$buttonPanel.Location = New-Object System.Drawing.Point(15, 175)
$buttonPanel.Size = New-Object System.Drawing.Size(610, 35)
$buttonPanel.Anchor = [System.Windows.Forms.AnchorStyles]::Top -bor [System.Windows.Forms.AnchorStyles]::Left -bor [System.Windows.Forms.AnchorStyles]::Right
$buttonPanel.BorderStyle = [System.Windows.Forms.BorderStyle]::None
$sourcePanel.Controls.Add($buttonPanel)

# Add Source Button
$addSourceBtn.Location = New-Object System.Drawing.Point(0, 0)
$addSourceBtn.Size = New-Object System.Drawing.Size(85, 35)
$addSourceBtn.Text = "Add Source"
$buttonPanel.Controls.Add($addSourceBtn)

# Remove Source Button
$removeSourceBtn.Location = New-Object System.Drawing.Point(95, 0)
$removeSourceBtn.Size = New-Object System.Drawing.Size(85, 35)
$removeSourceBtn.Text = "Remove"
$buttonPanel.Controls.Add($removeSourceBtn)

# Dark Mode Button
$darkModeBtn = New-Object System.Windows.Forms.Button
$darkModeBtn.Location = New-Object System.Drawing.Point(480, 0)
$darkModeBtn.Size = New-Object System.Drawing.Size(85, 35)
$darkModeBtn.Text = "Dark Mode"
$buttonPanel.Controls.Add($darkModeBtn)

# Target Panel
$targetPanel = New-Object System.Windows.Forms.Panel
$targetPanel.BackColor = [System.Drawing.Color]::White
$targetPanel.Location = New-Object System.Drawing.Point(20, 260)
$targetPanel.Size = New-Object System.Drawing.Size(640, 220)
$targetPanel.Padding = New-Object System.Windows.Forms.Padding(15)
$targetPanel.Anchor = [System.Windows.Forms.AnchorStyles]::Top -bor [System.Windows.Forms.AnchorStyles]::Left -bor [System.Windows.Forms.AnchorStyles]::Right
$targetPanel.Width = $containerPanel.ClientSize.Width - 40
$targetPanel.BorderStyle = [System.Windows.Forms.BorderStyle]::None
$containerPanel.Controls.Add($targetPanel)

# Target Label
$targetLabel.Location = New-Object System.Drawing.Point(15, 15)
$targetLabel.Size = New-Object System.Drawing.Size(200, 25)
$targetLabel.Text = "Target Directory:"
$targetPanel.Controls.Add($targetLabel)

# Target Path Label
$targetPathLabel.Location = New-Object System.Drawing.Point(15, 45)
$targetPathLabel.Size = New-Object System.Drawing.Size(610, 25)
$targetPathLabel.Text = "No target directory selected"
$targetPathLabel.Anchor = [System.Windows.Forms.AnchorStyles]::Top -bor [System.Windows.Forms.AnchorStyles]::Left -bor [System.Windows.Forms.AnchorStyles]::Right
$targetPathLabel.Width = $targetPanel.ClientSize.Width - 30
$targetPanel.Controls.Add($targetPathLabel)

# Select Target Button
$selectTargetBtn.Location = New-Object System.Drawing.Point(15, 175)
$selectTargetBtn.Size = New-Object System.Drawing.Size(120, 35)
$selectTargetBtn.Text = "Select Target"
$targetPanel.Controls.Add($selectTargetBtn)

# Progress Panel
$progressPanel = New-Object System.Windows.Forms.Panel
$progressPanel.BackColor = [System.Drawing.Color]::White
$progressPanel.Location = New-Object System.Drawing.Point(20, 500)
$progressPanel.Size = New-Object System.Drawing.Size(640, 100)
$progressPanel.Padding = New-Object System.Windows.Forms.Padding(15)
$progressPanel.Anchor = [System.Windows.Forms.AnchorStyles]::Top -bor [System.Windows.Forms.AnchorStyles]::Left -bor [System.Windows.Forms.AnchorStyles]::Right
$progressPanel.Width = $containerPanel.ClientSize.Width - 40
$progressPanel.BorderStyle = [System.Windows.Forms.BorderStyle]::None
$containerPanel.Controls.Add($progressPanel)

# Progress Bar
$progressBar.Location = New-Object System.Drawing.Point(15, 15)
$progressBar.Size = New-Object System.Drawing.Size(610, 30)
$progressBar.Anchor = [System.Windows.Forms.AnchorStyles]::Top -bor [System.Windows.Forms.AnchorStyles]::Left -bor [System.Windows.Forms.AnchorStyles]::Right
$progressBar.Width = $progressPanel.ClientSize.Width - 30
$progressPanel.Controls.Add($progressBar)

# Status Label
$statusLabel.Location = New-Object System.Drawing.Point(15, 55)
$statusLabel.Size = New-Object System.Drawing.Size(610, 25)
$statusLabel.Text = "Ready"
$statusLabel.Anchor = [System.Windows.Forms.AnchorStyles]::Top -bor [System.Windows.Forms.AnchorStyles]::Left -bor [System.Windows.Forms.AnchorStyles]::Right
$statusLabel.Width = $progressPanel.ClientSize.Width - 30
$progressPanel.Controls.Add($statusLabel)

# Backup Button Panel create - before the backup button
$backupButtonPanel = New-Object System.Windows.Forms.Panel
$backupButtonPanel.BackColor = [System.Drawing.Color]::White
$backupButtonPanel.Location = New-Object System.Drawing.Point(20, 840)
$backupButtonPanel.Size = New-Object System.Drawing.Size(640, 60)
$backupButtonPanel.Padding = New-Object System.Windows.Forms.Padding(15)
$backupButtonPanel.Anchor = [System.Windows.Forms.AnchorStyles]::Top -bor [System.Windows.Forms.AnchorStyles]::Left -bor [System.Windows.Forms.AnchorStyles]::Right
$backupButtonPanel.Width = $containerPanel.ClientSize.Width - 40
$backupButtonPanel.BorderStyle = [System.Windows.Forms.BorderStyle]::None
$containerPanel.Controls.Add($backupButtonPanel)

# Backup Button - only one definition
$backupBtn.Location = New-Object System.Drawing.Point(15, 10)
$backupBtn.Size = New-Object System.Drawing.Size(($backupButtonPanel.ClientSize.Width - 30), 40)
$backupBtn.Text = "Start Backup"
$backupBtn.Anchor = [System.Windows.Forms.AnchorStyles]::Top -bor [System.Windows.Forms.AnchorStyles]::Left -bor [System.Windows.Forms.AnchorStyles]::Right
$backupButtonPanel.Controls.Add($backupBtn)

# Dark Mode Button Click Handler
$darkModeBtn.Add_Click({
    Toggle-DarkMode
})

# Dark Mode Button also style
Set-ButtonStyle $darkModeBtn

# Global variable for cancellation status
$script:cancelBackup = $false

# Timer for UI updates (at the beginning after the UI elements)
$updateTimer = New-Object System.Windows.Forms.Timer
$updateTimer.Interval = 500  # Update every 500ms
$script:currentStatus = ""
$script:currentProgress = 0

$updateTimer.Add_Tick({
    if ($script:currentStatus -ne $statusLabel.Text) {
        $statusLabel.Text = $script:currentStatus
    }
    if ($script:currentProgress -ne $progressBar.Value) {
        $progressBar.Value = $script:currentProgress
    }
    $form.Refresh()
})

# Helper Functions
function Save-Config {
    # Check/create directory again in case of deletion
    if (-not (Test-Path $configDir)) {
        New-Item -ItemType Directory -Path $configDir -Force | Out-Null
    }
    
    @{
        SourceDirs = [Array]$config.SourceDirs
        TargetDir = $config.TargetDir
        IsDarkMode = $script:isDarkMode
    } | ConvertTo-Json | Set-Content $configPath
}

function Update-BackupButton {
    $backupBtn.Enabled = ($config.SourceDirs.Count -gt 0 -and $config.TargetDir)
    if ($backupBtn.Enabled) {
        $backupBtn.BackColor = $primaryColor
    } else {
        $backupBtn.BackColor = [System.Drawing.Color]::FromArgb(200, 200, 200)  # Gray for disabled state
    }
}

function Get-FileHash($filePath) {
    return (Get-FileHash -Path $filePath -Algorithm MD5).Hash
}

# Function for quick hash comparison (only start and end of file)
function Compare-LargeFiles {
    param(
        $sourcePath,
        $targetPath,
        $chunkSize = 1MB
    )
    
    try {
        $sourceStream = [System.IO.File]::OpenRead($sourcePath)
        $targetStream = [System.IO.File]::OpenRead($targetPath)
        
        # Check file size
        if ($sourceStream.Length -ne $targetStream.Length) {
            return $false
        }
        
        # Read and compare first chunk
        $sourceBuffer = New-Object byte[] $chunkSize
        $targetBuffer = New-Object byte[] $chunkSize
        
        $sourceRead = $sourceStream.Read($sourceBuffer, 0, $chunkSize)
        $targetRead = $targetStream.Read($targetBuffer, 0, $chunkSize)
        
        if ($sourceRead -ne $targetRead) {
            return $false
        }
        
        for ($i = 0; $i -lt $sourceRead; $i++) {
            if ($sourceBuffer[$i] -ne $targetBuffer[$i]) {
                return $false
            }
        }
        
        # Check last chunk
        if ($sourceStream.Length -gt $chunkSize) {
            $sourceStream.Position = [Math]::Max(0, $sourceStream.Length - $chunkSize)
            $targetStream.Position = [Math]::Max(0, $targetStream.Length - $chunkSize)
            
            $sourceRead = $sourceStream.Read($sourceBuffer, 0, $chunkSize)
            $targetRead = $targetStream.Read($targetBuffer, 0, $chunkSize)
            
            if ($sourceRead -ne $targetRead) {
                return $false
            }
            
            for ($i = 0; $i -lt $sourceRead; $i++) {
                if ($sourceBuffer[$i] -ne $targetBuffer[$i]) {
                    return $false
                }
            }
        }
        
        return $true
    }
    finally {
        if ($sourceStream) { $sourceStream.Dispose() }
        if ($targetStream) { $targetStream.Dispose() }
    }
}

# Copy-LargeFile function
function Copy-LargeFile {
    param(
        $sourcePath,
        $targetPath,
        $fileSize,
        $progress
    )
    
    $fileSizeMB = [math]::Round($fileSize / 1MB, 2)
    $script:currentStatus = "($progress%) Starting copy of large file ($fileSizeMB MB)"
    $progressBar.Style = 'Continuous'  # Change to Continuous for better feedback
    
    try {
        $buffer = New-Object byte[] (1024 * 1024)  # 1MB Buffer
        $sourceStream = [System.IO.File]::OpenRead($sourcePath)
        $targetStream = [System.IO.File]::Create($targetPath)
        $startTime = Get-Date
        $totalBytesRead = 0
        
        while ($true) {
            if ($script:cancelBackup) { throw "Backup canceled by user" }
            
            $bytesRead = $sourceStream.Read($buffer, 0, $buffer.Length)
            if ($bytesRead -eq 0) { break }
            
            $targetStream.Write($buffer, 0, $bytesRead)
            $totalBytesRead += $bytesRead
            
            # Calculate progress and speed
            $percentComplete = [math]::Round(($totalBytesRead / $fileSize) * 100)
            $elapsedSeconds = ((Get-Date) - $startTime).TotalSeconds
            if ($elapsedSeconds -gt 0) {
                $currentSpeedMB = [math]::Round(($totalBytesRead / 1MB) / $elapsedSeconds, 2)
                $script:currentStatus = "($progress%) Copying large file: $([math]::Round($totalBytesRead / 1MB, 2)) MB of $fileSizeMB MB ($percentComplete%) at $currentSpeedMB MB/s"
            }
            
            # UI update, but not too often
            if ($totalBytesRead % (5 * 1024 * 1024) -eq 0) {  # Every 5MB
                $progressBar.Value = $percentComplete
                [System.Windows.Forms.Application]::DoEvents()
            }
        }
        
        $endTime = Get-Date
        $duration = ($endTime - $startTime).TotalSeconds
        $speedMBs = [math]::Round($fileSizeMB / $duration, 2)
        return "($progress%) Completed: $fileSizeMB MB copied at average speed of $speedMBs MB/s"
    }
    finally {
        if ($sourceStream) { $sourceStream.Dispose() }
        if ($targetStream) { $targetStream.Dispose() }
    }
}

# Log Panel für Output
$logPanel = New-Object System.Windows.Forms.Panel
$logPanel.BackColor = [System.Drawing.Color]::White
$logPanel.Location = New-Object System.Drawing.Point(20, 620)
$logPanel.Size = New-Object System.Drawing.Size(640, 200)  
$logPanel.Padding = New-Object System.Windows.Forms.Padding(15)
$logPanel.Anchor = [System.Windows.Forms.AnchorStyles]::Top -bor [System.Windows.Forms.AnchorStyles]::Left -bor [System.Windows.Forms.AnchorStyles]::Right
$logPanel.Width = $containerPanel.ClientSize.Width - 40
$logPanel.BorderStyle = [System.Windows.Forms.BorderStyle]::None
$containerPanel.Controls.Add($logPanel)

# Log Label
$logLabel = New-Object System.Windows.Forms.Label
$logLabel.Font = New-Object System.Drawing.Font("Segoe UI", 12, [System.Drawing.FontStyle]::Bold)
$logLabel.Location = New-Object System.Drawing.Point(15, 15)
$logLabel.Size = New-Object System.Drawing.Size(200, 25)
$logLabel.Text = "Backup Log:"
$logPanel.Controls.Add($logLabel)

# Log TextBox
$logTextBox = New-Object System.Windows.Forms.TextBox
$logTextBox.Multiline = $true
$logTextBox.ScrollBars = "Vertical"
$logTextBox.Location = New-Object System.Drawing.Point(15, 45)
$logTextBox.Size = New-Object System.Drawing.Size(($logPanel.ClientSize.Width - 30), 125)
$logTextBox.ReadOnly = $true
$logTextBox.Font = New-Object System.Drawing.Font("Consolas", 9)
$logTextBox.BackColor = [System.Drawing.Color]::FromArgb(245, 245, 245)  
$logTextBox.ForeColor = $labelColor
$logTextBox.Anchor = [System.Windows.Forms.AnchorStyles]::Top -bor [System.Windows.Forms.AnchorStyles]::Left -bor [System.Windows.Forms.AnchorStyles]::Right
$logPanel.Controls.Add($logTextBox)

# Function to add log entries
function Add-LogEntry {
    param($message)
    $timestamp = Get-Date -Format "HH:mm:ss"
    $logTextBox.AppendText("[$timestamp] $message`r`n")
    $logTextBox.ScrollToCaret()
}

function Start-Backup {
    try {
        Add-LogEntry "Starting backup process..."
        $updateTimer.Start()  # Timer start
        $backupBtn.Enabled = $true  # Button remains active for cancellation
        $progressBar.Value = 0
        $statusLabel.Text = "Starting backup..."
        $form.Refresh()

        # Validate directories
        foreach ($sourceDir in $config.SourceDirs) {
            if (-not (Test-Path -Path $sourceDir)) {
                throw "Source directory not found: $sourceDir"
            }
        }
        
        if (-not (Test-Path -Path $config.TargetDir)) {
            throw "Target directory not found: $($config.TargetDir)"
        }

        # Process each source directory independently
        $totalDirs = $config.SourceDirs.Count
        $currentDir = 0

        foreach ($sourceDir in $config.SourceDirs) {
            if ($script:cancelBackup) {
                throw "Backup canceled by user"
            }
            
            $currentDir++
            $script:currentStatus = "Processing directory $currentDir of $totalDirs : $sourceDir"

            # Get files for current directory
            $files = Get-ChildItem -Path $sourceDir -Recurse -File
            $totalFiles = $files.Count
            $currentFile = 0

            foreach ($file in $files) {
                if ($script:cancelBackup) {
                    throw "Backup canceled by user"
                }

                $currentFile++
                $script:currentProgress = [math]::Round((($currentDir - 1) / $totalDirs * 100) + 
                                                      ($currentFile / $totalFiles * (100 / $totalDirs)))
                $progressBar.Value = $script:currentProgress

                # Calculate paths
                $relativePath = $file.FullName.Substring($sourceDir.Length).TrimStart('\')
                $sourceDirName = Split-Path -Path $sourceDir -Leaf
                $targetPath = Join-Path -Path $config.TargetDir -ChildPath $sourceDirName
                $targetPath = Join-Path -Path $targetPath -ChildPath $relativePath

                $statusLabel.Text = "($script:currentProgress%) Copying from $sourceDirName : $relativePath"
                $form.Refresh()

                # Create directory if needed
                $targetDir = Split-Path -Path $targetPath -Parent
                if (-not (Test-Path -Path $targetDir)) {
                    New-Item -ItemType Directory -Path $targetDir -Force | Out-Null
                }

                # Copy if needed
                if (Test-Path -Path $targetPath) {
                    $sourceItem = Get-Item -Path $file.FullName
                    $targetItem = Get-Item -Path $targetPath
                    
                    if ($sourceItem.Length -gt 100MB) {
                        # For large files: faster comparison
                        if ($sourceItem.Length -eq $targetItem.Length -and 
                            $sourceItem.LastWriteTime -eq $targetItem.LastWriteTime -and 
                            (Compare-LargeFiles -sourcePath $file.FullName -targetPath $targetPath)) {
                            $statusLabel.Text = "($progress%) Skipping identical large file: $relativePath"
                            $form.Refresh()
                            Add-LogEntry "Skipping identical file"
                            continue
                        }                        
                    }
                    else {
                        # small files
                        Copy-Item -Path $file.FullName -Destination $targetPath -Force
                        Add-LogEntry "Copying file..."
                    }
                }
                else {
                    # large files
                    if ($file.Length -gt 100MB) {
                        try {
                            $statusMessage = Copy-LargeFile -sourcePath $file.FullName -targetPath $targetPath -fileSize $file.Length -progress $script:currentProgress
                            $statusLabel.Text = $statusMessage
                            Add-LogEntry "Large file detected: $relativePath ($fileSizeMB MB)"
                            Add-LogEntry "Copying file..."
                        }
                        catch {
                            throw
                        }
                    }
                    else {
                        Copy-Item -Path $file.FullName -Destination $targetPath -Force
                        Add-LogEntry "Copying file..."
                    }
                }

                if ($currentFile % 10 -eq 0) {  # Only every 10th file
                    [System.Windows.Forms.Application]::DoEvents()
                }
            }
        }

        $progressBar.Value = 100
        $statusLabel.Text = "Backup completed successfully!"
        Add-LogEntry "Backup completed successfully!"
    }
    catch {
        if ($_.ToString() -eq "Backup canceled by user") {
            $statusLabel.Text = "Backup canceled by user."
            $progressBar.Value = 0
            Add-LogEntry "Backup canceled by user."
        } else {
            $statusLabel.Text = "Error: $_"
            $progressBar.Value = 0
            Add-LogEntry "Error: $_"
        }
    }
    finally {
        $updateTimer.Stop()  # Timer stop
        $script:cancelBackup = $false
        $backupBtn.Text = "Start Backup"
        $backupBtn.BackColor = $primaryColor
        $backupBtn.Enabled = $true
        $progressBar.Style = 'Continuous'
        $form.Refresh()
    }
}

# Load config if exists
if (Test-Path $configPath) {
    $loadedConfig = Get-Content $configPath | ConvertFrom-Json
    $config.TargetDir = $loadedConfig.TargetDir
    $config.SourceDirs.Clear()
    if ($loadedConfig.SourceDirs) {
        $loadedConfig.SourceDirs | ForEach-Object {
            [void]$config.SourceDirs.Add($_)
            $sourceList.Items.Add($_)
        }
    }
    if ($loadedConfig.TargetDir) {
        $config.TargetDir = $loadedConfig.TargetDir
        $targetPathLabel.Text = $loadedConfig.TargetDir
    }
    if ($null -ne $loadedConfig.IsDarkMode) {
        Toggle-DarkMode -force $true -state $loadedConfig.IsDarkMode
        $darkModeBtn.Text = if ($script:isDarkMode) { "Light Mode" } else { "Dark Mode" }
    }
}

# Call Update-BackupButton
Update-BackupButton

# Apply Button-Styles
Set-ButtonStyle $addSourceBtn
Set-ButtonStyle $removeSourceBtn
Set-ButtonStyle $selectTargetBtn
if ($backupBtn.Enabled) {
    Set-ButtonStyle $backupBtn
}

# Make backup button more prominent - after styling
$backupBtn.Height = 50
$backupBtn.Font = New-Object System.Drawing.Font("Segoe UI", 11, [System.Drawing.FontStyle]::Bold)

# Add Source Button Click Handler
$addSourceBtn.Add_Click({
    $folderBrowser = New-Object System.Windows.Forms.FolderBrowserDialog
    $folderBrowser.Description = "Select source directory"
    if ($folderBrowser.ShowDialog() -eq [System.Windows.Forms.DialogResult]::OK) {
        $selectedPath = $folderBrowser.SelectedPath
        if ($sourceList.Items -notcontains $selectedPath) {
            [void]$config.SourceDirs.Add($selectedPath)
            $sourceList.Items.Add($selectedPath)
            Save-Config
            Update-BackupButton
        }
    }
})

# Remove Source Button Click Handler
$removeSourceBtn.Add_Click({
    if ($sourceList.SelectedItem) {
        $selectedPath = $sourceList.SelectedItem
        [void]$config.SourceDirs.Remove($selectedPath)
        $sourceList.Items.Remove($selectedPath)
        Save-Config
        Update-BackupButton
    }
})

# Select Target Button Click Handler
$selectTargetBtn.Add_Click({
    $folderBrowser = New-Object System.Windows.Forms.FolderBrowserDialog
    $folderBrowser.Description = "Select target directory"
    if ($folderBrowser.ShowDialog() -eq [System.Windows.Forms.DialogResult]::OK) {
        $config.TargetDir = $folderBrowser.SelectedPath
        $targetPathLabel.Text = $folderBrowser.SelectedPath
        Save-Config
        Update-BackupButton
    }
})

# Backup Button Click Handler
$backupBtn.Add_Click({
    if ($backupBtn.Text -eq "Cancel Backup") {
        $script:cancelBackup = $true
        $script:currentStatus = "Canceling backup... Please wait."
    } else {
        $script:cancelBackup = $false
        $backupBtn.Text = "Cancel Backup"
        $backupBtn.BackColor = [System.Drawing.Color]::FromArgb(200, 50, 50)
        Start-Backup
    }
})

# Show the form
$form.ShowDialog() 