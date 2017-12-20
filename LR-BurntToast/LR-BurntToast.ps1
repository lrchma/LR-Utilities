[CmdletBinding()]
param(
  [Parameter(Mandatory=$false)]
  [string]$notificationTitle = "Title",

  [Parameter(Mandatory=$false)]
  [string]$notificationMessage = "Message",

  [Parameter(Mandatory=$false)]
  [string]$notificationURL = "http://www.logrhythm.com"

)

# ********************************************************************
# Error handling
# 

# BurntToast works on PowerShell 5, so let's set that as a minimum
if($PSVersionTable.PSVersion.Major -ge 5){<#true#>}else{write-output "PowerShell 5 or greater is required"; break}

$OS = Get-CimInstance Win32_OperatingSystem
if($OS.Caption -eq "Microsoft Windows 10 Enterprise"){<#true#>}else{write-output "Windows 10 is required"; break}

# Identify clean way to check module is loaded
#if (!(Get-Module "BurntToast")) {
#    write-host "BurntToast module not loaded."
#}



New-BurntToastNotification -Text "$notificationTitle", $notificationMessage -AppLogo "C:\GitHub\LR-Utilities\LR-BurntToast\LR-Logo.png"

<#
$Text1 = New-BTText -Content $notificationTitle
$Text2 = New-BTText -Content $notificationMessage

$Binding1 = New-BTBinding -Children $Text1, $Text2

$Visual1 = New-BTVisual -BindingGeneric $Binding1

$Content1 = New-BTContent -Visual $Visual1 -Launch $notificationURL -ActivationType Protocol

Submit-BTNotification -Content $Content1
#>
