########################################################################
# Name: Power(shell) Syslog Server
# Version: v2.0.1 (9/8/2017)
# Original Release Date: 30/9/2014
# Created By: James Cussen
# Web Site: http://www.myskypelab.com
# Notes: For more information on the requirements for setting up and using this tool please visit http://www.myskypelab.com
# Copyright: Copyright (c) 2017, James Cussen (www.myskypelab.com) All rights reserved.
# Licence: 	Redistribution and use of script, source and binary forms, with or without modification, are permitted provided that the following conditions are met:
#				1) Redistributions of script code must retain the above copyright notice, this list of conditions and the following disclaimer.
#				2) Redistributions of source code must retain the above copyright notice, this list of conditions and the following disclaimer.
#				3) Redistributions in binary form must reproduce the above copyright notice, this list of conditions and the following disclaimer in the documentation and/or other materials provided with the distribution.
#				4) This license does not include any resale or commercial use of this software.
#				5) Any portion of this software may not be reproduced, duplicated, copied, sold, resold, or otherwise exploited for any commercial purpose without express written consent of James Cussen.
#			THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS" AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT HOLDER OR CONTRIBUTORS BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA, OR PROFITS; LOSS OF GOODWILL OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
#
# Release Notes:
# 1.00 Initial Release.
#	- Zero installation.
#	- Signed Powershell Script.
#	- Real time log display (Approximately 1000 lines).
#	- Copy the displayed text with the Copy Text button. This is useful for more in depth analysis in your favourite notepad software.
#	- Rolling log files based on file size and number of files to keep.
#	- Clear display and Pause display functions.
#	- Filter real-time display with regular expression.
#	- Filter logging to file with regular expression.
#	- Open firewall for Syslog Server port with the click of a button. If you are not seeing any syslog output in the Power Syslog Server display log then try pressing the Open Firewall button.
#	- Server listening port can be changed by creating a config file (PowerSyslogServerSettings.cfg) in the same directory as the script. The config file needs to have text in it in the following format "SyslogPort=514". This allows you to maintain the integrity of the code signing by not directly editing the script file.
#
# 2.00 Update
#	- In version 2 if you create a config file named "PowerSyslogServerSettings.cfg" in the same directory as the tool it will use the config file to save all of its settings. The SyslogPort="514" setting remains a hidden setting that can still be used in the config file to change the listening port number.
#	- UDP socket code has been made more robust to deal with errors when the listening port is being used by another app.
#	- Changed the font to Courier New for fixed width goodness.
#	- Fixed issue with rolling files in folders including "." in name and faster processing.
#	- Added Output formatting options to work with Sonus LX tool and AudioCodes Syslog Viewer tool (Commonly used Skype for Business syslog tools):
#       +
#		+ Setting: "None" - To output syslog in the exact format that it was sent from the device in.
#       + Prefix format: No prefix!
#       +
#		+ Setting: "SonusLX" - To output syslog in Sonus LX format use the Format setting to "SonusLX".
#       + Prefix format: "10.20.1.150:53434 <==>"
#       +
#		+ Setting: "AudioCodes" - To output syslog in AudioCodes Syslog Viewer tool format set the Format setting to "AudioCodes"
#		+ Prefix format: "17:50:17.588  10.20.2.170     local0.notice"
#       +
#		+ Setting: "Level" - To prefix the syslog with the Facility and Severity levels.
#		+ Prefix format: "Local0.Debug"
#       +
#		+ Setting: "DateTime" - To prefix the syslog with the date and time.
#		+ Prefix format: "2011-10-11 15:00:02.123"
#       +
#		+ Setting: "DateTimeLevel" - To prefix the syslog with Date/Time, Facility/Severity, and IP Address of the device.
#		+ Prefix format: "2011-10-11 15:00:02.123 Local0.Debug"
#       +
#		+ Setting: "DateTimeLevelIP" - To prefix the syslog with Date/Time, Facility/Severity, and IP Address of the device.
#		+ Prefix format: "2011-10-11 15:00:02.123 Local0.Debug    192.168.0.100"
#       +
#		+ Note: Sonus LX tool cannot open AudioCodes files and AudioCodes cannot open LX files. So you need to select the correct format for the device and tool you are using.
#
# Example Config File Format:
#
#	If you want to set a non default port for syslogging (ie. not 514), then you can create a settings file named "PowerSyslogServerSettings.cfg" and put it in the same folder as the script.
#
#	File format is in text format and the settings are shown below (values must be surrounded by quote marks):  
#
#	SyslogPort="514"
#	Format="AudioCodes"
#	LogFile="C:\PowerSyslogFile.cfg"
#	KeepFiles="2000"
#	RollFile="20"
#
# 2.01 Lots of Bug Fixes
#	- Fixed Sonus LX output formatting to only have LF and not CRLF.
#	- Increased socket buffer and tuned threading to fix dropped packet issues and double writing of some lines.
#	- Added disable display checkbox to increase performance when display is not required.
#
########################################################################


$theVersion = $PSVersionTable.PSVersion
$MajorVersion = $theVersion.Major

Write-Host ""
Write-Host "--------------------------------------------------------------"
Write-Host "Powershell Version Check..." -foreground "yellow"
if($MajorVersion -eq  "1")
{
	Write-Host "This machine only has Version 1 Powershell installed.  This version of Powershell is not supported." -foreground "red"
	exit
}
elseif($MajorVersion -eq  "2")
{
	Write-Host "This machine only has Version 2 Powershell installed.  This version of Powershell is not supported." -foreground "red"
	exit
}
elseif($MajorVersion -eq  "3")
{
	Write-Host "This machine has version 3 Powershell installed. CHECK PASSED!" -foreground "green"
}
elseif($MajorVersion -eq  "4")
{
	Write-Host "This machine has version 4 Powershell installed. CHECK PASSED!" -foreground "green"
}
elseif($MajorVersion -eq  "5")
{
	Write-Host "This machine has version 5 Powershell installed. CHECK PASSED!" -foreground "green"
}
else
{
	Write-Host "This machine has version $MajorVersion Powershell installed. Unknown level of support for this version." -foreground "yellow"
}
Write-Host "--------------------------------------------------------------"
Write-Host ""


$SyncHash = [hashtable]::Synchronized(@{})
$SyncHash.SysLogPort = 514      # Default SysLog Port is 514. If you want to change this use a "PowerSyslogServerSettings.cfg" settings file. Details below.
$SyncHash.ServerRunning = $true
$SyncHash.UDPServerSocket = $Null
$SyncHash.FileNumber = 1
$SyncHash.Paused = $false
$SyncHash.LogText = ""
$SyncHash.LogFileText = ""
$SyncHash.FinishedWritingLogFile = $false
$SyncHash.StartedWritingLogFile = $false
$SyncHash.FormatOutput = 0
$LogFilePath = "C:\PowerSyslog.txt"
$KeepNumberDefault = 10
$RollFileDefault = 1000


$scriptpath = $MyInvocation.MyCommand.Path
$dir = Split-Path $scriptpath
$fso = New-Object -ComObject Scripting.FileSystemObject
$shortname = $fso.GetFolder($dir).ShortPath
Write-host "Script directory: $shortname"
$SettingsFile = "$shortname/PowerSyslogServerSettings.cfg"

if (Test-Path $SettingsFile -PathType leaf)
{
	Write-Host "Found Settings file. Reading Settings..." -foreground "green"
	$textfile = get-content $SettingsFile -Encoding UTF8
	foreach ($line in $textfile) 
	{
		[string]$theLine = $line
		if($theLine -imatch "SyslogPort")
		{
			if($theLine.Contains("="))
			{
				$regex = new-object System.Text.RegularExpressions.Regex ('SyslogPort\s*?=\s*?"(\d*)"', [System.Text.RegularExpressions.RegexOptions]::IgnoreCase)
				[string]$Response = ($regex.Match($theLine)).Groups[1]
				
				$Response = $Response.Trim()
				
				if($Response -ne "" -and $Response -ne $null)
				{
					if($Response -match "^(6553[0-5])$|^(655[0-2]\d)$|^(65[0-4]\d{2})$|^(6[0-4]\d{3})$|^([1-5]\d{4})$|^([1-9]\d{1,3})$|^(\d{1})$")
					{
						$returnedInt = 0
						[bool]$result = [int]::TryParse($Response, [ref]$returnedInt)
						if($result)
						{
							$SyncHash.SysLogPort = $returnedInt
							Write-Host "Found SyslogPort: " $SyncHash.SysLogPort -foreground "green"
						}
						else
						{
							Write-Host "WARNING: Config file found but SyslogPort parameter is not an number. Using default port 514." -foreground "yellow"
						}
					}
					else
					{
						Write-Host "WARNING: Config file found but SyslogPort parameter $Response, however, it is not in the port range 1-65535. Using default port 514." -foreground "yellow"
					}
				}
				else
				{
					Write-Host "WARNING: Config file contains the SyslogPort parameter but no value was found. Note: values in the config file must be surrounded by quote marks. Using default port 514." -foreground "yellow"
				}
			}
			else
			{
				Write-Host "WARNING: Config file found with SyslogPort parameter but no port number was specified. Using default port 514." -foreground "yellow"
			}
		}
		
		if($theLine -imatch "Format")
		{
			if($theLine.Contains("="))
			{
				
				$regex = new-object System.Text.RegularExpressions.Regex ('Format\s*?=\s*?"(\S*)"', [System.Text.RegularExpressions.RegexOptions]::IgnoreCase)
				[string]$Response = ($regex.Match($theLine)).Groups[1]
				
				$Response = $Response.Trim()
				
				if($Response -ne "" -and $Response -ne $null)
				{
					if($Response -match "^None$")
					{
						#<135>...
						$SyncHash.FormatOutput = 0
						Write-Host "INFO: The config file has selected format None. This means that the output file will contain the LogLevel (eg. <135> at the start of each line)" -foreground "green"
					}
					elseif($Response -match "^AudioCodes$")
					{
						#17:50:17.588  10.20.2.170     local0.notice  
						$SyncHash.FormatOutput = 1
						Write-Host "INFO: The config file has selected format AudioCodes. This means the output will be the same as the AudioCodes Syslog Viewer Tool." -foreground "green"
					}
					elseif($Response -match "^SonusLX$")
					{
						#10.20.1.150:53434 <==> 
						$SyncHash.FormatOutput = 2
						Write-Host "INFO: The config file has selected format SonusLX. This means the format will be the same as the Sonus LX tool outputs." -foreground "green"
					}
					elseif($Response -match "^Level$")
					{
						#Local0.Debug 
						$SyncHash.FormatOutput = 3
						Write-Host "INFO: The config file has selected format Level. This means that the output file will contain <135> value replaced with its Facility/severity values" -foreground "green"
					}
					elseif($Response -match "^DateTime$")
					{
						#2011-10-11 15:00:02.123
						$SyncHash.FormatOutput = 4
						Write-Host "INFO: The config file has selected format DateTime." -foreground "green"
					}
					elseif($Response -match "^DateTimeLevel$")
					{
						#2011-10-11 15:00:02.123 Local0.Debug
						$SyncHash.FormatOutput = 5
						Write-Host "INFO: The config file has selected format DateTimeLevel Formatting." -foreground "green"
					}
					elseif($Response -match "^DateTimeLevelIP$")
					{
						#2011-10-11 15:00:02.123 Local0.Debug    192.168.0.100
						$SyncHash.FormatOutput = 6
						Write-Host "INFO: The config file has selected format DateTimeLevelIP Formatting." -foreground "green"
					}
					else
					{
						Write-Host "WARNING: Config file has a Format value of `"$Response`". This not a valid value, please fix the file." -foreground "yellow"
					}
				}
				else
				{
					Write-Host "WARNING: Config file contains the Format parameter but no value was found. Note: values in the config file must be surrounded by quote marks. Using default setting." -foreground "yellow"
				}
			}
			else
			{
				Write-Host "WARNING: Config file found with Format parameter but no value was specified. This not a valid value, please fix the file." -foreground "yellow"
			}
		}
		
		if($theLine -imatch "LogFile")
		{
			if($theLine.Contains("="))
			{
				$regex = new-object System.Text.RegularExpressions.Regex ('LogFile\s*?=\s*?"(\S*)"', [System.Text.RegularExpressions.RegexOptions]::IgnoreCase)
				[string]$Response = ($regex.Match($theLine)).Groups[1]
				$Response = $Response.Trim()
				
				if($Response -ne "" -and $Response -ne $null)
				{
					$ValidPath = Test-Path $Response -IsValid
					if ($ValidPath -eq $True)
					{
						$LogFilePath = $Response
					}
					else
					{
						Write-Host "WARNING: LogFile Path selected in config file is not valid. Please fix config file." -foreground "yellow"
					}
				}
				else
				{
					Write-Host "WARNING: Config file contains the LogFile parameter but no value was found. Note: values in the config file must be surrounded by quote marks. Using default setting." -foreground "yellow"
				}
			}
			else
			{
				Write-Host "WARNING: Config file found with LogFile parameter but no value was specified. This not a valid value, please fix the file." -foreground "yellow"
			}
		}
		
		#KeepFiles
		if($theLine -imatch "KeepFiles")
		{
			if($theLine.Contains("="))
			{
				$regex = new-object System.Text.RegularExpressions.Regex ('KeepFiles\s*?=\s*?"(\d*)"', [System.Text.RegularExpressions.RegexOptions]::IgnoreCase)
				[string]$Response = ($regex.Match($theLine)).Groups[1]
				
				$Response = $Response.Trim()
				
				if($Response -ne "" -and $Response -ne $null)
				{
					$returnedInt = 0
					[bool]$result = [int]::TryParse($Response, [ref]$returnedInt)
					if($result)
					{
						if($returnedInt -ge 1 -and $returnedInt -le 1000)
						{
							$KeepNumberDefault = $returnedInt
							Write-Host "Found KeepFiles: " $returnedInt -foreground "green"
						}
						else
						{
							Write-Host "WARNING: Config file found but KeepFiles parameter $Response, however, it is not in the port range 1-1000. Using default port 10." -foreground "yellow"
						}
						
					}
					else
					{
						Write-Host "WARNING: Config file found but KeepFiles parameter is not an number. Using default value of 10." -foreground "yellow"
					}
				}
				else
				{
					Write-Host "WARNING: Config file contains the KeepFiles parameter but no value was found. Note: values in the config file must be surrounded by quote marks. Using default setting." -foreground "yellow"
				}
			}
			else
			{
				Write-Host "WARNING: Config file found with KeepFiles parameter but no port number was specified. Using default value of 10." -foreground "yellow"
			}
		}
		
		
		#RollFile
		if($theLine -imatch "RollFile")
		{
			if($theLine.Contains("="))
			{
				$regex = new-object System.Text.RegularExpressions.Regex ('RollFile\s*?=\s*?"(\d*)"', [System.Text.RegularExpressions.RegexOptions]::IgnoreCase)
				[string]$Response = ($regex.Match($theLine)).Groups[1]
				
				$Response = $Response.Trim()
				
				if($Response -ne "" -and $Response -ne $null)
				{
					$returnedInt = 0
					[bool]$result = [int]::TryParse($Response, [ref]$returnedInt)
					if($result)
					{
						if($returnedInt -ge 100 -and $returnedInt -le 10000)
						{
							$RollFileDefault = $returnedInt
							Write-Host "Found RollFile: " $returnedInt -foreground "green"
						}
						else
						{
							Write-Host "WARNING: Config file found but RollFile parameter $Response, however, it is not in the port range 100-10000. Using default port 10." -foreground "yellow"
						}
						
					}
					else
					{
						Write-Host "WARNING: Config file found but RollFile parameter is not an number. Using default value of 100." -foreground "yellow"
					}
				}
				else
				{
					Write-Host "WARNING: Config file contains the RollFile parameter but no value was found. Note: values in the config file must be surrounded by quote marks. Using default setting." -foreground "yellow"
				}
			}
			else
			{
				Write-Host "WARNING: Config file found with RollFile parameter but no port number was specified. Using default value of 100." -foreground "yellow"
			}
		}
	}	
}


$objServerThread = New-Object -Type PSCustomObject -Property @{
	objRunspace = $Null
	objPowershell = $Null
	objHandle = $Null
}

# GUI Logging Thread
$objServerThreadLogging = New-Object -Type PSCustomObject -Property @{
	objRunspaceLogging = $Null
	objPowershellLogging = $Null
	objHandleLogging = $Null
}

# Set up the form  ============================================================
[void] [System.Reflection.Assembly]::LoadWithPartialName("System.Windows.Forms")
[void] [System.Reflection.Assembly]::LoadWithPartialName("System.Drawing") 

$objForm = New-Object System.Windows.Forms.Form 
$objForm.Text = "Power Syslog Server v2.01"
$objForm.Size = New-Object System.Drawing.Size(640,640) 
$objForm.MinimumSize = New-Object System.Drawing.Size(640,640)
$objForm.StartPosition = "CenterScreen"
#Myskypelab Icon
[byte[]]$WindowIcon = @(137, 80, 78, 71, 13, 10, 26, 10, 0, 0, 0, 13, 73, 72, 68, 82, 0, 0, 0, 32, 0, 0, 0, 32, 8, 6, 0, 0, 0, 115, 122, 122, 244, 0, 0, 0, 6, 98, 75, 71, 68, 0, 255, 0, 255, 0, 255, 160, 189, 167, 147, 0, 0, 0, 9, 112, 72, 89, 115, 0, 0, 11, 19, 0, 0, 11, 19, 1, 0, 154, 156, 24, 0, 0, 0, 7, 116, 73, 77, 69, 7, 225, 7, 26, 1, 36, 51, 211, 178, 227, 235, 0, 0, 5, 235, 73, 68, 65, 84, 88, 195, 197, 151, 91, 108, 92, 213, 21, 134, 191, 189, 207, 57, 115, 159, 216, 78, 176, 27, 98, 72, 226, 88, 110, 66, 66, 34, 185, 161, 168, 193, 73, 21, 17, 2, 2, 139, 75, 164, 182, 106, 145, 170, 190, 84, 74, 104, 65, 16, 144, 218, 138, 138, 244, 173, 69, 106, 101, 42, 129, 42, 149, 170, 162, 15, 168, 168, 151, 7, 4, 22, 180, 1, 41, 92, 172, 52, 196, 68, 105, 130, 19, 138, 98, 76, 154, 27, 174, 227, 248, 58, 247, 57, 103, 175, 62, 236, 241, 177, 199, 246, 140, 67, 26, 169, 251, 237, 236, 61, 179, 215, 191, 214, 191, 214, 191, 214, 86, 188, 62, 37, 252, 31, 151, 174, 123, 42, 224, 42, 72, 56, 138, 152, 99, 191, 175, 247, 114, 107, 29, 172, 75, 106, 94, 254, 74, 156, 109, 13, 58, 180, 155, 53, 240, 216, 64, 129, 63, 156, 43, 95, 55, 0, 106, 62, 5, 158, 134, 83, 59, 147, 116, 36, 106, 7, 103, 188, 44, 228, 13, 120, 202, 126, 151, 12, 100, 3, 225, 183, 231, 203, 60, 55, 88, 66, 4, 80, 215, 0, 96, 89, 68, 113, 97, 87, 138, 180, 3, 163, 101, 120, 116, 160, 192, 161, 81, 159, 203, 69, 33, 230, 40, 58, 27, 52, 251, 215, 69, 248, 198, 74, 183, 238, 165, 175, 141, 248, 60, 114, 178, 192, 165, 188, 44, 9, 100, 22, 128, 192, 127, 238, 73, 209, 18, 81, 252, 109, 52, 224, 222, 247, 179, 179, 46, 206, 93, 102, 142, 119, 193, 76, 216, 96, 247, 13, 46, 223, 189, 201, 101, 207, 74, 143, 148, 99, 183, 159, 250, 184, 72, 207, 96, 169, 46, 136, 16, 192, 183, 91, 61, 94, 233, 140, 241, 81, 198, 176, 229, 173, 204, 226, 198, 175, 102, 5, 194, 243, 157, 113, 246, 221, 236, 225, 42, 232, 29, 9, 184, 255, 104, 174, 62, 0, 165, 192, 239, 78, 163, 129, 174, 195, 57, 14, 143, 5, 255, 115, 114, 197, 29, 197, 200, 221, 41, 82, 14, 188, 63, 30, 240, 245, 190, 220, 162, 145, 208, 0, 141, 174, 66, 1, 37, 129, 195, 163, 254, 34, 40, 1, 191, 70, 25, 250, 50, 75, 197, 156, 149, 15, 132, 27, 254, 62, 205, 229, 178, 176, 163, 201, 161, 103, 115, 172, 182, 14, 196, 181, 53, 114, 38, 107, 64, 22, 194, 92, 147, 80, 200, 67, 105, 50, 247, 165, 171, 156, 104, 141, 105, 70, 186, 211, 200, 131, 105, 214, 46, 82, 53, 69, 3, 119, 244, 217, 240, 63, 177, 214, 35, 233, 170, 250, 66, 164, 20, 11, 221, 52, 240, 171, 77, 49, 114, 6, 198, 74, 18, 158, 106, 5, 239, 110, 79, 208, 236, 41, 254, 93, 16, 206, 102, 204, 162, 30, 14, 78, 27, 158, 60, 93, 68, 1, 7, 191, 150, 176, 73, 60, 31, 64, 182, 178, 185, 49, 169, 103, 80, 132, 235, 166, 164, 38, 238, 64, 66, 67, 104, 94, 224, 229, 206, 56, 111, 93, 182, 116, 61, 246, 81, 177, 118, 166, 107, 248, 253, 121, 43, 92, 119, 52, 106, 86, 39, 245, 66, 0, 147, 101, 9, 105, 188, 171, 165, 186, 198, 127, 179, 57, 202, 233, 233, 106, 216, 9, 79, 113, 169, 96, 216, 119, 179, 135, 47, 112, 240, 114, 185, 110, 169, 77, 149, 132, 95, 159, 181, 32, 182, 54, 58, 139, 83, 112, 231, 7, 121, 0, 126, 210, 17, 129, 96, 150, 134, 213, 9, 205, 84, 185, 42, 29, 121, 103, 91, 130, 15, 38, 45, 228, 105, 95, 40, 207, 97, 173, 209, 83, 124, 179, 213, 227, 153, 13, 81, 16, 91, 205, 247, 174, 116, 113, 42, 118, 31, 89, 227, 86, 37, 109, 8, 224, 189, 97, 159, 178, 64, 71, 82, 207, 166, 129, 192, 75, 231, 203, 180, 68, 170, 235, 252, 95, 57, 195, 150, 138, 218, 156, 43, 8, 70, 102, 43, 98, 96, 103, 146, 63, 119, 198, 120, 115, 216, 210, 243, 179, 245, 81, 222, 248, 106, 156, 141, 73, 77, 201, 192, 109, 141, 14, 86, 171, 231, 39, 161, 99, 209, 158, 43, 152, 48, 156, 237, 41, 205, 123, 163, 1, 174, 99, 55, 38, 3, 225, 209, 142, 40, 7, 78, 23, 217, 182, 220, 2, 120, 247, 202, 172, 59, 27, 155, 28, 90, 163, 138, 76, 32, 28, 159, 12, 192, 23, 30, 110, 181, 148, 238, 63, 85, 64, 128, 166, 121, 149, 160, 23, 118, 96, 21, 122, 255, 226, 150, 40, 103, 178, 134, 132, 182, 123, 167, 50, 134, 95, 222, 18, 229, 108, 198, 112, 99, 212, 238, 29, 155, 156, 5, 240, 253, 53, 54, 84, 127, 25, 246, 9, 4, 214, 175, 112, 104, 139, 107, 46, 20, 132, 129, 41, 179, 196, 60, 96, 108, 228, 155, 61, 107, 60, 237, 41, 140, 82, 100, 138, 66, 186, 146, 151, 67, 89, 195, 119, 142, 231, 65, 36, 212, 251, 209, 188, 132, 212, 116, 85, 18, 236, 233, 143, 139, 0, 252, 174, 34, 62, 71, 39, 131, 80, 107, 138, 82, 11, 128, 182, 213, 176, 33, 169, 33, 128, 159, 174, 143, 176, 231, 104, 30, 20, 172, 170, 120, 187, 111, 181, 199, 171, 151, 124, 80, 48, 94, 17, 204, 111, 173, 246, 160, 44, 188, 182, 45, 73, 103, 131, 189, 110, 120, 218, 240, 192, 74, 151, 29, 77, 22, 80, 207, 80, 137, 6, 79, 227, 42, 136, 42, 112, 230, 244, 153, 16, 128, 18, 155, 193, 0, 127, 237, 74, 48, 81, 18, 50, 190, 128, 8, 55, 198, 236, 207, 186, 251, 243, 161, 10, 205, 112, 255, 189, 85, 46, 178, 103, 25, 61, 67, 37, 222, 24, 177, 168, 142, 237, 74, 209, 28, 213, 76, 248, 66, 206, 192, 67, 95, 242, 56, 240, 229, 8, 253, 21, 26, 126, 176, 54, 178, 112, 34, 18, 5, 63, 255, 180, 196, 211, 237, 17, 20, 240, 236, 39, 37, 11, 79, 89, 158, 247, 159, 242, 57, 50, 211, 164, 20, 60, 126, 178, 64, 68, 131, 163, 96, 239, 201, 2, 34, 112, 100, 220, 231, 135, 107, 35, 188, 114, 209, 103, 119, 179, 67, 163, 171, 24, 200, 24, 122, 134, 138, 124, 158, 23, 86, 197, 53, 23, 239, 74, 242, 112, 171, 199, 243, 131, 69, 112, 212, 188, 137, 40, 0, 121, 48, 109, 109, 244, 102, 174, 105, 8, 92, 151, 208, 244, 109, 79, 112, 177, 32, 220, 182, 76, 115, 123, 95, 142, 254, 137, 32, 188, 127, 172, 59, 133, 163, 160, 225, 245, 105, 112, 213, 188, 42, 112, 224, 197, 138, 108, 158, 216, 153, 248, 226, 61, 88, 224, 79, 91, 227, 180, 189, 157, 97, 115, 74, 115, 104, 44, 160, 127, 78, 153, 162, 160, 28, 64, 84, 171, 218, 101, 184, 247, 159, 5, 174, 248, 176, 37, 165, 121, 118, 83, 244, 11, 5, 161, 179, 209, 225, 76, 222, 240, 194, 230, 24, 142, 134, 61, 253, 121, 112, 170, 69, 172, 33, 162, 24, 47, 75, 157, 177, 92, 65, 87, 95, 22, 128, 31, 183, 69, 56, 176, 33, 90, 37, 205, 245, 214, 241, 241, 128, 67, 35, 1, 39, 38, 13, 94, 239, 52, 147, 229, 234, 255, 221, 211, 234, 17, 85, 208, 119, 37, 176, 237, 116, 177, 169, 120, 38, 148, 91, 151, 59, 124, 216, 149, 168, 12, 153, 1, 123, 79, 228, 25, 206, 203, 82, 47, 137, 186, 244, 100, 187, 211, 36, 52, 220, 255, 97, 158, 222, 138, 84, 235, 26, 131, 26, 199, 198, 3, 154, 14, 102, 152, 240, 133, 7, 90, 28, 62, 223, 157, 226, 165, 173, 113, 86, 120, 138, 168, 14, 29, 176, 169, 163, 150, 54, 254, 199, 219, 227, 36, 52, 156, 206, 25, 122, 47, 148, 107, 191, 11, 22, 72, 165, 130, 95, 108, 140, 241, 163, 54, 111, 230, 46, 138, 6, 2, 17, 130, 202, 212, 173, 21, 228, 12, 220, 249, 143, 28, 3, 19, 166, 170, 53, 183, 196, 20, 71, 182, 39, 105, 139, 219, 205, 230, 131, 25, 70, 75, 114, 245, 0, 102, 100, 122, 69, 76, 177, 171, 217, 229, 153, 142, 8, 183, 166, 106, 243, 112, 46, 47, 97, 146, 165, 92, 104, 175, 140, 106, 99, 62, 108, 122, 39, 195, 112, 65, 234, 191, 140, 150, 10, 37, 70, 64, 43, 54, 164, 53, 77, 17, 133, 8, 92, 42, 26, 118, 44, 119, 121, 170, 61, 66, 103, 186, 26, 220, 80, 78, 120, 238, 179, 18, 47, 12, 150, 170, 43, 226, 154, 0, 92, 197, 155, 0, 20, 237, 203, 172, 238, 127, 50, 101, 108, 239, 175, 147, 36, 238, 117, 125, 234, 86, 12, 125, 58, 51, 100, 106, 150, 124, 36, 254, 23, 153, 41, 93, 205, 81, 212, 105, 60, 0, 0, 0, 0, 73, 69, 78, 68, 174, 66, 96, 130)
$ico = New-Object IO.MemoryStream($WindowIcon, 0, $WindowIcon.Length)
$objForm.Icon = [System.Drawing.Icon]::FromHandle((new-object System.Drawing.Bitmap -argument $ico).GetHIcon())
$objForm.KeyPreview = $True
$objForm.TabStop = $false


#Log Textbox ============================================================
$FontCourier = new-object System.Drawing.Font("Courier New",9,[Drawing.FontStyle]'Regular')
$SyncHash.InformationTextBox = New-Object System.Windows.Forms.TextBox
#$SyncHash.InformationTextBox = New-Object System.Windows.Forms.RichTextBox
$SyncHash.InformationTextBox.Location = New-Object System.Drawing.Size(20,30)
$SyncHash.InformationTextBox.Size = New-Object System.Drawing.Size(580,390)  
$SyncHash.InformationTextBox.Font = $FontCourier
$SyncHash.InformationTextBox.Multiline = $True	
$SyncHash.InformationTextBox.Wordwrap = $false
$SyncHash.InformationTextBox.ReadOnly = $true
$SyncHash.InformationTextBox.BackColor = [System.Drawing.Color]::White
$SyncHash.InformationTextBox.Text = ""
$SyncHash.InformationTextBox.TabStop = $false
$SyncHash.InformationTextBox.ScrollBars = [System.Windows.Forms.ScrollBars]::Both
$SyncHash.InformationTextBox.Anchor = [System.Windows.Forms.AnchorStyles]::Top -bor [System.Windows.Forms.AnchorStyles]::Right -bor [System.Windows.Forms.AnchorStyles]::Left -bor [System.Windows.Forms.AnchorStyles]::Bottom
$objForm.Controls.Add($SyncHash.InformationTextBox) 

#Copy button ============================================================
$copyButton = New-Object System.Windows.Forms.Button
$copyButton.Location = New-Object System.Drawing.Size(500,5)
$copyButton.Size = New-Object System.Drawing.Size(100,20)
$copyButton.Text = "Copy Text"
$copyButton.tabIndex = 3
$copyButton.Anchor = [System.Windows.Forms.AnchorStyles]::Top -bor [System.Windows.Forms.AnchorStyles]::Right
$copyButton.Add_Click(
{
	[Windows.Forms.Clipboard]::Clear()
	[string]$clipText = $SyncHash.InformationTextBox.Text
    if ( ($clipText -ne $null) -and ($clipText -ne '') ) {
            [Windows.Forms.Clipboard]::SetText( $clipText )
	}
})
$objForm.Controls.Add($copyButton)


$logLabel = New-Object System.Windows.Forms.Label
$logLabel.Location = New-Object System.Drawing.Size(20,15) 
$logLabel.Size = New-Object System.Drawing.Size(150,15) 
$logLabel.Text = "Syslog Output:"
$logLabel.TabStop = $False
$objForm.Controls.Add($logLabel)


#Start button ============================================================
$startButton = New-Object System.Windows.Forms.Button
$startButton.Location = New-Object System.Drawing.Size(30,430)
$startButton.Size = New-Object System.Drawing.Size(100,23)
$startButton.Text = "Start"
$startButton.tabIndex = 1
$startButton.Anchor = [System.Windows.Forms.AnchorStyles]::Bottom
$startButton.Add_Click(
{
	
	Write-Host "Start GUI Thread"
	
	$BrowseButton.Enabled = $false
	$SyncHash.FileLocationTextBox.Enabled = $false
	
	$runspaceLogging = [System.Management.Automation.Runspaces.RunspaceFactory]::CreateRunspace($Host)
	$runspaceLogging.Open()
	$runspaceLogging.SessionStateProxy.SetVariable('SyncHash',$SyncHash)
	$powershellLogging = [System.Management.Automation.PowerShell]::Create()
	$powershellLogging.Runspace = $runspaceLogging
	$powershellLogging.AddScript({
		
		[string]$theFilename = $SyncHash.FileLocationTextBox.text
		$fileNumber = $SyncHash.FileNumber

		#NEW FILE HANDLING CODE
		$ParentFolder = Split-Path $theFilename -Parent
		$FileName = Split-Path $theFilename -Leaf
		$NewFileName = $FileName -replace '(.*)(?:\..*)',"`${1}${fileNumber}.txt"
		[string]$fullFilename = Join-Path -Path $ParentFolder -ChildPath $NewFileName
		
		if($SyncHash.OutFileCheckBox.Checked -eq $true)
		{
			Write-Host "Creating File... $fullFilename" -foreground "green"
			#If file exists, delete it.
			if (Test-Path $fullFilename)
			{
				Remove-Item $fullFilename
			}
			New-Item $fullFilename -type file
		}
			
		[int]$rollValue = $SyncHash.rollNumberBox.Value
		[int]$keepValue = $SyncHash.KeepNumberBox.Value
			
		Write-Host "Rolling File At: $rollValue KB"
		$rollValueKB = $rollValue * 1024	
		$DataOutputted = 0
		$TextInWindowLength = 0
		
		$TextInWindow = ""		
		While($true)
		{
			
			if(!$SyncHash.Paused)
			{
				if($TextInWindow -ne $SyncHash.LogText)
				{
					$TextInWindow = $SyncHash.LogText
					$TextInWindowLength = $TextInWindow.length
					Try {
					
						$SyncHash.InformationTextBox.Text = $TextInWindow
					
					} Catch {
					
						Write-Warning "$($Error[0])"
						Write-Host "ERROR: Error when writing text to textbox..." -Foreground "red"
					}
					Try {
					
						$SyncHash.InformationTextBox.SelectionStart = $TextInWindowLength
						$SyncHash.InformationTextBox.ScrollToCaret()

					} Catch {
						Write-Warning "$($Error[0])"
						Write-Host "ERROR: Error when autoscrolling textbox..." -Foreground "red"
					}
				}
			}
					
			
			##LOG TO FILE
			if($SyncHash.OutFileCheckBox.Checked -eq $true)
			{
				if($SyncHash.LogFileText -ne "" -and $SyncHash.LogFileText -ne $null)
				{
					$ReturnedDataLength = $SyncHash.LogFileText.length

					$DataOutputted += $ReturnedDataLength
					#Write-Host "Data Outputted: $DataOutputted" #Debugging
					
					#Roll file code
					if (Test-Path $fullFilename) 
					{
						if($DataOutputted -gt $rollValueKB)
						{
							if($SyncHash.FileNumber -ge $keepValue)
							{
								$SyncHash.FileNumber = 1
								
								#NEW FILE HANDLING CODE
								[string]$theFilename = $SyncHash.FileLocationTextBox.text
								$fileNumber = $SyncHash.FileNumber
								$ParentFolder = Split-Path $theFilename -Parent
								$FileName = Split-Path $theFilename -Leaf
								$NewFileName = $FileName -replace '(.*)(?:\..*)',"`${1}${fileNumber}.txt"
								[string]$fullFilename = Join-Path -Path $ParentFolder -ChildPath $NewFileName
		
							}
							else
							{
								$SyncHash.FileNumber++
								
								#NEW FILE HANDLING CODE
								[string]$theFilename = $SyncHash.FileLocationTextBox.text
								$fileNumber = $SyncHash.FileNumber
								$ParentFolder = Split-Path $theFilename -Parent
								$FileName = Split-Path $theFilename -Leaf
								$NewFileName = $FileName -replace '(.*)(?:\..*)',"`${1}${fileNumber}.txt"
								[string]$fullFilename = Join-Path -Path $ParentFolder -ChildPath $NewFileName
							}
							$DataOutputted = 0
							Write-Host "Rolling File... $fullFilename" -foreground "green"
							#If file exists, delete it.
							if (Test-Path $fullFilename)
							{
								Remove-Item $fullFilename
							}
							New-Item $fullFilename -type file
						}
					}
					else
					{
						Write-Host "Creating File... $fullFilename" -foreground "green"
						New-Item $fullFilename -type file
					}
					Try {
					#UTF-8 files...
					$SyncHash.StartedWritingLogFile = $true
					$TempOutput = $SyncHash.LogFileText
					$SyncHash.FinishedWritingLogFile = $true

					
					$TempOutput.Trim() | out-file -Encoding UTF8 -FilePath $fullFilename -Force -Append
					} Catch {
						Write-Warning "$($Error[0])"
						Write-Host "ERROR: Issue when writing file..." -Foreground "red"
					}
				}
				
			}
			Try {
			Start-Sleep -Milliseconds 3000
			} Catch {
				Write-Warning "$($Error[0])"
				Write-Host "ERROR: Issue sleeping thread..." -Foreground "red"
			}
		}
		
	}) | Out-Null

		
	$handleLogging = $powershellLogging.BeginInvoke()
	$objServerThreadLogging.objRunspaceLogging = $runspaceLogging
	$objServerThreadLogging.objPowershellLogging = $powershellLogging
	$objServerThreadLogging.objHandleLogging = $handleLogging	
	
		
	
	Write-host "Start Socket Thread"
	$SyncHash.ServerRunning = $true
	
	$runspace = [System.Management.Automation.Runspaces.RunspaceFactory]::CreateRunspace($Host)
	$runspace.Open()
	$runspace.SessionStateProxy.SetVariable('SyncHash',$SyncHash)
	$powershell = [System.Management.Automation.PowerShell]::Create()
	$powershell.Runspace = $runspace
	$powershell.AddScript({
		
			$LogWriteCache = ""
			
			$facility = @{"0" = "kern"; "1" = "user"; "2" = "mail"; "3" = "daemon"; "4" = "auth"; "5" = "syslog"; "6" = "lpr"; "7" = "news"; "8" = "uucp"; "9" = ""; "10" = "authpriv"; "11" = "ftp"; "12" = "ntp"; "13" = "audit"; "14" = "alert"; "15" = "cron"; "16" = "local0"; "17" = "local1"; "18" = "local2"; "19" = "local3"; "20" = "local4"; "21" = "local5"; "22" = "local6"; "23" = "local7"}
			$severity = @{"0" = "emerg"; "1" = "alert"; "2" = "crit"; "3" = "err"; "4" = "warn"; "5" = "notice"; "6" = "info"; "7" = "debug"}
			
			$port = $SyncHash.SysLogPort
			$IPAddress = "0.0.0.0"
			
			$InterfaceIP = [System.Net.IPAddress]::Parse($IPAddress)
			$IPEndPoint = New-Object System.Net.IPEndPoint($InterfaceIP, $port)
			$SyncHash.UDPServerSocket = new-Object system.Net.Sockets.Udpclient($IPEndPoint)
			
			#To fix UDP buffer overflow issues in previous versions
			try
			{
				$SyncHash.UDPServerSocket.Client.ReceiveBufferSize = 1000000
			}
			catch
			{
				Write-Host "ERROR: Unable to set socket buffer size" -foreground "red"
			}
			
			Write-Host "Waiting for a connection on UDP port $port... IP address $IPAddress"
			$remoteendpoint = New-Object system.net.ipendpoint([system.net.ipaddress]::Any,0)
			
			$a = new-object system.text.asciiencoding
			
			
			function ProcessInput([string] $inputString)
			{
				if($SyncHash.FormatOutput -eq 0) #None
				{
					$outputString += "$inputString`r`n"
				}
				elseif($SyncHash.FormatOutput -eq 1) #AudioCodes
				{
					#FORMAT
					#17:50:17.588  10.20.2.170     local0.notice
					
					#Generate Time / Facility format
					[string]$LogLevel = ([regex]::Match($inputString,'^<(\d*)>')).Groups[1]
					
					[int] $returnedInt = 0
					[bool]$result = [int]::TryParse($LogLevel, [ref]$returnedInt)
					if($result)
					{
						[int] $fac =  [Math]::Floor([decimal]($returnedInt / 8))
						[int] $sev = $returnedInt - ($fac * 8 )
					}
					
					$FacOut = $facility["$fac"]  
					$SevOut = $severity["$sev"]
					
					#Strip the <135> value
					$inputString = $inputString -replace "^<\d*>",""
										
					$date = Get-Date -format "hh:mm:ss.fff"
					
					$ip = "${RemoteIP}"
					$ip = $ip.PadRight(16)
					$priority = "${FacOut}.${SevOut}"
					$priority = $priority.PadRight(15)
													
					$outputString += "${date}  ${ip}$priority${inputString}`r`n"
				
				}
				elseif($SyncHash.FormatOutput -eq 2) #SonusLX
				{
					#FORMAT
					#10.20.1.150:53434 <==> 
					$outputString += "${RemoteIP}:${RemotePort} <==> $inputString`n"
					
				}
				elseif($SyncHash.FormatOutput -eq 3) #Level
				{
					#FORMAT
					#Local0.Debug 
					
					#Generate Time / Facility format
					[string]$LogLevel = ([regex]::Match($inputString,'^<(\d*)>')).Groups[1]
					#Write-Host "LOG LEVEL $LogLevel"
					
					[int] $returnedInt = 0
					[bool]$result = [int]::TryParse($LogLevel, [ref]$returnedInt)
					if($result)
					{
						[int] $fac =  [Math]::Floor([decimal]($returnedInt / 8))
						[int] $sev = $returnedInt - ($fac * 8 )
					}
					
					$FacOut = $facility["$fac"]  
					$SevOut = $severity["$sev"]
					
					#Strip the <135> value
					$inputString = $inputString -replace "^<\d*>",""
											
					$priority = "${FacOut}.${SevOut}"
					$priority = $priority.PadRight(15)
													
					$outputString += "$priority${inputString}`r`n"
					
				}
				elseif($SyncHash.FormatOutput -eq 4) #DateTime
				{
					#FORMAT
					#2011-10-11 15:00:02.123
					
					$date = Get-Date -format "yyyy-MM-dd hh:mm:ss.fff"
					
					$outputString += "${date}  ${inputString}`r`n"
				}
				elseif($SyncHash.FormatOutput -eq 5) #DateTimeLevel
				{
					#2011-10-11 15:00:02.123 Local0.Debug
					
					#Generate Time / Facility format
					[string]$LogLevel = ([regex]::Match($inputString,'^<(\d*)>')).Groups[1]
					
					[int] $returnedInt = 0
					[bool]$result = [int]::TryParse($LogLevel, [ref]$returnedInt)
					if($result)
					{
						[int]$fac =  [Math]::Floor([decimal]($returnedInt / 8))
						[int] $sev = $returnedInt - ($fac * 8 )
					}
					
					$FacOut = $facility["$fac"]  
					$SevOut = $severity["$sev"]
					
					$inputString = $inputString -replace "^<\d*>",""
					
					$date = Get-Date -format "yyyy-MM-dd hh:mm:ss.fff"
										
					$priority = "${FacOut}.${SevOut}"
					$priority = $priority.PadRight(15)
					
					$outputString += "${date}  ${priority}${inputString}`r`n"
				}
				elseif($SyncHash.FormatOutput -eq 6) #DateTimeLevelIP
				{
					#2011-10-11 15:00:02.123 Local0.Debug    192.168.0.100
					
					#Generate Time / Facility format
					[string]$LogLevel = ([regex]::Match($inputString,'^<(\d*)>')).Groups[1]
					
					[int] $returnedInt = 0
					[bool]$result = [int]::TryParse($LogLevel, [ref]$returnedInt)
					if($result)
					{
						[int]$fac =  [Math]::Floor([decimal]($returnedInt / 8))
						[int] $sev = $returnedInt - ($fac * 8 )
					}
					
					$FacOut = $facility["$fac"]  
					$SevOut = $severity["$sev"]
					
					$inputString = $inputString -replace "^<\d*>",""
					
					$date = Get-Date -format "yyyy-MM-dd hh:mm:ss.fff"
					
					$ip = "${RemoteIP}"
					$ip = $ip.PadRight(16)
					
					$priority = "${FacOut}.${SevOut}"
					$priority = $priority.PadRight(15)
					
					$outputString += "${date}  ${priority}${ip}${inputString}`r`n"
				}
				else
				{
					$outputString += "$inputString`r`n"
				}
				
				return $outputString
			}
			
			function ProcessDisplayInput([string] $inputString)
			{
				if($SyncHash.FormatOutput -eq 0) #None
				{
					$outputString += "$inputString`r`n"
				}
				elseif($SyncHash.FormatOutput -eq 1) #AudioCodes
				{
					#FORMAT
					#17:50:17.588  10.20.2.170     local0.notice
					
					#Generate Time / Facility format
					[string]$LogLevel = ([regex]::Match($inputString,'^<(\d*)>')).Groups[1]
					
					[int] $returnedInt = 0
					[bool]$result = [int]::TryParse($LogLevel, [ref]$returnedInt)
					if($result)
					{
						[int] $fac =  [Math]::Floor([decimal]($returnedInt / 8))
						[int] $sev = $returnedInt - ($fac * 8 )
					}
					
					$FacOut = $facility["$fac"]  
					$SevOut = $severity["$sev"]
					
					#Strip the <135> value
					$inputString = $inputString -replace "^<\d*>",""
										
					$date = Get-Date -format "hh:mm:ss.fff"
					
					$ip = "${RemoteIP}"
					$ip = $ip.PadRight(16)
					$priority = "${FacOut}.${SevOut}"
					$priority = $priority.PadRight(15)
													
					$outputString += "${date}  ${ip}$priority${inputString}`r`n"
				
				}
				elseif($SyncHash.FormatOutput -eq 2) #SonusLX
				{
					
					$pattern = '(?<!\r)\n'
					if($inputString -match $pattern)
					{
						$regexdata = $inputString -replace $pattern, "`r`n"
						$inputString = $regexdata
						#Write-Host "Trimming String with 0A at the end..."
					}
					
					#FORMAT
					#10.20.1.150:53434 <==> 
					$outputString += "${RemoteIP}:${RemotePort} <==> $inputString`r`n"
					
				}
				elseif($SyncHash.FormatOutput -eq 3) #Level
				{
					#FORMAT
					#Local0.Debug 
					
					#Generate Time / Facility format
					[string]$LogLevel = ([regex]::Match($inputString,'^<(\d*)>')).Groups[1]
					#Write-Host "LOG LEVEL $LogLevel"
					
					[int] $returnedInt = 0
					[bool]$result = [int]::TryParse($LogLevel, [ref]$returnedInt)
					if($result)
					{
						[int] $fac =  [Math]::Floor([decimal]($returnedInt / 8))
						[int] $sev = $returnedInt - ($fac * 8 )
					}
					
					$FacOut = $facility["$fac"]  
					$SevOut = $severity["$sev"]
					
					#Strip the <135> value
					$inputString = $inputString -replace "^<\d*>",""
											
					$priority = "${FacOut}.${SevOut}"
					$priority = $priority.PadRight(15)
													
					$outputString += "$priority${inputString}`r`n"
					
				}
				elseif($SyncHash.FormatOutput -eq 4) #DateTime
				{
					#FORMAT
					#2011-10-11 15:00:02.123
					
					$date = Get-Date -format "yyyy-MM-dd hh:mm:ss.fff"
					
					$outputString += "${date}  ${inputString}`r`n"
				}
				elseif($SyncHash.FormatOutput -eq 5) #DateTimeLevel
				{
					#2011-10-11 15:00:02.123 Local0.Debug
					
					#Generate Time / Facility format
					[string]$LogLevel = ([regex]::Match($inputString,'^<(\d*)>')).Groups[1]
					
					[int] $returnedInt = 0
					[bool]$result = [int]::TryParse($LogLevel, [ref]$returnedInt)
					if($result)
					{
						[int]$fac =  [Math]::Floor([decimal]($returnedInt / 8))
						[int] $sev = $returnedInt - ($fac * 8 )
					}
					
					$FacOut = $facility["$fac"]  
					$SevOut = $severity["$sev"]
					
					$inputString = $inputString -replace "^<\d*>",""
					
					$date = Get-Date -format "yyyy-MM-dd hh:mm:ss.fff"
										
					$priority = "${FacOut}.${SevOut}"
					$priority = $priority.PadRight(15)
					
					$outputString += "${date}  ${priority}${inputString}`r`n"
				}
				elseif($SyncHash.FormatOutput -eq 6) #DateTimeLevelIP
				{
					#2011-10-11 15:00:02.123 Local0.Debug    192.168.0.100
					
					#Generate Time / Facility format
					[string]$LogLevel = ([regex]::Match($inputString,'^<(\d*)>')).Groups[1]
					
					[int] $returnedInt = 0
					[bool]$result = [int]::TryParse($LogLevel, [ref]$returnedInt)
					if($result)
					{
						[int]$fac =  [Math]::Floor([decimal]($returnedInt / 8))
						[int] $sev = $returnedInt - ($fac * 8 )
					}
					
					$FacOut = $facility["$fac"]  
					$SevOut = $severity["$sev"]
					
					$inputString = $inputString -replace "^<\d*>",""
					
					$date = Get-Date -format "yyyy-MM-dd hh:mm:ss.fff"
					
					$ip = "${RemoteIP}"
					$ip = $ip.PadRight(16)
					
					$priority = "${FacOut}.${SevOut}"
					$priority = $priority.PadRight(15)
					
					$outputString += "${date}  ${priority}${ip}${inputString}`r`n"
				}
				else
				{
					$outputString += "$inputString`r`n"
				}
				
				return $outputString
			}
			
			$TextInWindow = ""
			While ($SyncHash.ServerRunning -eq $True)
			{
				Try {
					$receivebytes = $SyncHash.UDPServerSocket.Receive([ref]$remoteendpoint)
					[string]$RemoteIP = $remoteendpoint.Address
					[string]$RemotePort = $remoteendpoint.Port
					#Write-Host "Received: $receivebytes" #Debugging
				} Catch {
					Write-Warning "$($Error[0])"
					Write-Host "ERROR: Socket Error. Check that port $port is not currently in use by another application." -Foreground "red"
					Start-Sleep -s 5
					Write-Host "Recreating socket on UDP port $port... IP address $IPAddress"
					$SyncHash.UDPServerSocket = new-Object system.Net.Sockets.Udpclient($IPEndPoint)
					#Socket Probably being used by another service.
				}
				if ($receivebytes) {
					
					[string]$returndata = $a.GetString($receivebytes)
					
					
					if($returndata -ne "" -and $returndata -ne $null)
					{
						#Write-host "Message: **$returndata**" #Debugging
						$DisplayFilter = $SyncHash.DisplayFilterBox.text
						$LogFilter = $SyncHash.LogFilterBox.text
						
						if($DisplayFilter -ne "")
						{
							if($returndata -imatch $DisplayFilter)
							{
								if(!$SyncHash.DisableDisplayCheckBox.Checked)
								{
									$SyncHash.LogText += ProcessDisplayInput $returndata
									
									#Roll display data if required.
									if($SyncHash.LogText.length -gt 170000)
									{
										Try {
										$LogLength = $SyncHash.LogText.length - 170000
										$SyncHash.LogText = $SyncHash.LogText.substring($LogLength)
										} Catch {
											Write-Warning "$($Error[0])"
											Write-Host "ERROR: Error when cropping text box log..." -Foreground "red"
										}
									}
																		
								}
							}								
						}
						else
						{
							if(!$SyncHash.DisableDisplayCheckBox.Checked)
							{
								$SyncHash.LogText += ProcessDisplayInput $returndata
								
								#Roll display data if required.
								if($SyncHash.LogText.length -gt 170000)
								{
									Try {
									$LogLength = $SyncHash.LogText.length - 170000
									$SyncHash.LogText = $SyncHash.LogText.substring($LogLength)
									} Catch {
										Write-Warning "$($Error[0])"
										Write-Host "ERROR: Error when cropping text box log..." -Foreground "red"
									}
								}
							}
						}
						#Only log to file if the outfilecheckbox is checked
						if($SyncHash.OutFileCheckBox.Checked -eq $true)
						{
							if($LogFilter -ne "")
							{
								if($returndata -imatch $LogFilter)
								{
									#Special processing to cache data whilst other thread is working
									if($SyncHash.StartedWritingLogFile -eq $true -and $SyncHash.FinishedWritingLogFile -eq $false)
									{
										$LogWriteCache += ProcessInput $returndata 
									}
									elseif($SyncHash.StartedWritingLogFile -eq $true -and $SyncHash.FinishedWritingLogFile -eq $true)
									{
										$SyncHash.LogFileText = ""
										
										$SyncHash.FinishedWritingLogFile = $false
										$SyncHash.StartedWritingLogFile = $false
										
										$SyncHash.LogFileText += $LogWriteCache
										
										$LogWriteCache = ""
									}
									
									$SyncHash.LogFileText += ProcessInput $returndata
								}
							}
							else
							{
								#Special processing to cache data whilst other thread is working
								if($SyncHash.StartedWritingLogFile -eq $true -and $SyncHash.FinishedWritingLogFile -eq $false)
								{
									$LogWriteCache += ProcessInput $returndata 
								}
								elseif($SyncHash.StartedWritingLogFile -eq $true -and $SyncHash.FinishedWritingLogFile -eq $true)
								{
									$SyncHash.LogFileText = ""
									
									$SyncHash.FinishedWritingLogFile = $false
									$SyncHash.StartedWritingLogFile = $false
									
									$SyncHash.LogFileText += $LogWriteCache
									
									$LogWriteCache = ""
								}
									
								$SyncHash.LogFileText += ProcessInput $returndata

							}
						}
					}
					else
					{
						Write-host "Error: string is blank"
					}
					
				} else {
					Write-Host "ERROR: No data was received." -Foreground "red"
				}
			}
			$SyncHash.UDPServerSocket.Close()
			
	
	}) | Out-Null
	
	$handle = $powershell.BeginInvoke()
	
	$objServerThread.objRunspace = $runspace
	$objServerThread.objPowershell = $powershell
	$objServerThread.objHandle = $handle
	
	$startButton.Enabled = $false
	$stopButton.Enabled = $true
	$SyncHash.KeepNumberBox.Enabled = $false
	$SyncHash.rollNumberBox.Enabled = $false
})
$objForm.Controls.Add($startButton)

#Stop button ============================================================
$stopButton = New-Object System.Windows.Forms.Button
$stopButton.Location = New-Object System.Drawing.Size(150,430)
$stopButton.Size = New-Object System.Drawing.Size(100,23)
$stopButton.Text = "Stop"
$stopButton.tabIndex = 2
$stopButton.Anchor = [System.Windows.Forms.AnchorStyles]::Bottom
$stopButton.Add_Click(
{
	Write-host "Stop"

	$SyncHash.UDPServerSocket.Close()
	$objServerThread.objRunspace.Close()
	$objServerThread.objPowershell.Dispose()
	
	Write-Host "Killing GUI Thread."
	#Kill GUI Thread
	$objServerThreadLogging.objRunspaceLogging.Close()
	$objServerThreadLogging.objPowershellLogging.Dispose()	
	
	$SyncHash.FileNumber = 1
	$SyncHash.UDPServerSocket = $Null
	$SyncHash.LogText = ""
	$SyncHash.LogFileText = ""
	
	Write-Host "Socket Closed."
	$startButton.Enabled = $true
	$stopButton.Enabled = $false
	$SyncHash.KeepNumberBox.Enabled = $true
	$SyncHash.rollNumberBox.Enabled = $true
	
	$BrowseButton.Enabled = $true
	$SyncHash.FileLocationTextBox.Enabled = $true
	
	[System.GC]::Collect()
})
$objForm.Controls.Add($stopButton)

#Clear button ============================================================
$clearButton = New-Object System.Windows.Forms.Button
$clearButton.Location = New-Object System.Drawing.Size(270,430)
$clearButton.Size = New-Object System.Drawing.Size(100,23)
$clearButton.Text = "Clear"
$clearButton.TabStop = $false
$clearButton.Anchor = [System.Windows.Forms.AnchorStyles]::Bottom
$clearButton.Add_Click(
{
	$SyncHash.LogText = ""
	$SyncHash.InformationTextBox.Text = ""
	[System.GC]::Collect()
})
$objForm.Controls.Add($clearButton)


#Pause button ============================================================
$PauseButton = New-Object System.Windows.Forms.Button
$PauseButton.Location = New-Object System.Drawing.Size(380,430)
$PauseButton.Size = New-Object System.Drawing.Size(100,23)
$PauseButton.Text = "Pause"
$PauseButton.TabStop = $false
$PauseButton.Anchor = [System.Windows.Forms.AnchorStyles]::Bottom
$PauseButton.Add_Click(
{
	if($PauseButton.Text -eq "Pause")
	{
		$PauseButton.Text = "Un-Pause"
		$SyncHash.Paused = $true
		$SyncHash.ScrollPause = $SyncHash.LogText.length
	}
	elseif($PauseButton.Text -eq "Un-Pause")
	{
		$PauseButton.Text = "Pause"
		$SyncHash.Paused = $false
		$SyncHash.ScrollPause = 0
	}
})
$objForm.Controls.Add($PauseButton)


# Add the Open Firewall button ============================================================
$OpenFirewallButton = New-Object System.Windows.Forms.Button
$OpenFirewallButton.Location = New-Object System.Drawing.Size(490,430)
$OpenFirewallButton.Size = New-Object System.Drawing.Size(100,23)
$OpenFirewallButton.Text = "Firewall Closed"
$OpenFirewallButton.TabStop = $false
$OpenFirewallButton.Anchor = [System.Windows.Forms.AnchorStyles]::Bottom
$OpenFirewallButton.Add_Click(
{
	if($OpenFirewallButton.Text -eq "Open Firewall")
	{
		OpenFirewallButton
	}
	elseif($OpenFirewallButton.Text -eq "Close Firewall")
	{
		CloseFirewallButton
	}
	
	$Count = CheckFirewall
	if($Count -eq 0)
	{
		$OpenFirewallButton.Text = "Open Firewall"
	}
	else
	{
		$OpenFirewallButton.Text = "Close Firewall"
	}
}
)
$objForm.Controls.Add($OpenFirewallButton)



$DisplayFilterLabel = New-Object System.Windows.Forms.Label
$DisplayFilterLabel.Location = New-Object System.Drawing.Size(30,463) 
$DisplayFilterLabel.Size = New-Object System.Drawing.Size(75,15) 
$DisplayFilterLabel.Text = "Display Filter:"
$DisplayFilterLabel.TabStop = $False
$DisplayFilterLabel.Anchor = [System.Windows.Forms.AnchorStyles]::Bottom
$objForm.Controls.Add($DisplayFilterLabel)


#FilterBox box ============================================================
$SyncHash.DisplayFilterBox = new-object System.Windows.Forms.textbox
$SyncHash.DisplayFilterBox.location = new-object system.drawing.size(110,460)
$SyncHash.DisplayFilterBox.size= new-object system.drawing.size(400,15)
$SyncHash.DisplayFilterBox.text = ""   
$SyncHash.DisplayFilterBox.tabIndex = 3
$SyncHash.DisplayFilterBox.Anchor = [System.Windows.Forms.AnchorStyles]::Bottom
$objform.controls.add($SyncHash.DisplayFilterBox)


# Add DisableDisplayCheckBox ============================================================
$SyncHash.DisableDisplayCheckBox = New-Object System.Windows.Forms.Checkbox 
$SyncHash.DisableDisplayCheckBox.Location = New-Object System.Drawing.Size(585,460) 
$SyncHash.DisableDisplayCheckBox.Size = New-Object System.Drawing.Size(20,20)
$SyncHash.DisableDisplayCheckBox.tabIndex = 7
$SyncHash.DisableDisplayCheckBox.Anchor = [System.Windows.Forms.AnchorStyles]::Bottom
$objForm.Controls.Add($SyncHash.DisableDisplayCheckBox) 

$SyncHash.DisableDisplayCheckBox.Checked = $false

$SyncHash.DisableDisplayCheckBox.Add_CheckedChanged(
{
	if($SyncHash.DisableDisplayCheckBox.Checked)
	{
		$SyncHash.LogText = "<DISPLAY OFF>"
		$SyncHash.InformationTextBox.Text = "<DISPLAY OFF>"
	}
	else
	{
		$SyncHash.LogText = ""
		$SyncHash.InformationTextBox.Text = ""
	}
})

$DisableDisplayCheckBoxLabel = New-Object System.Windows.Forms.Label
$DisableDisplayCheckBoxLabel.Location = New-Object System.Drawing.Size(520,463) 
$DisableDisplayCheckBoxLabel.Size = New-Object System.Drawing.Size(60,15) 
$DisableDisplayCheckBoxLabel.Text = "Display Off"
$DisableDisplayCheckBoxLabel.TabStop = $False
$DisableDisplayCheckBoxLabel.Anchor = [System.Windows.Forms.AnchorStyles]::Bottom
$objForm.Controls.Add($DisableDisplayCheckBoxLabel)




$LogFilterLabel = New-Object System.Windows.Forms.Label
$LogFilterLabel.Location = New-Object System.Drawing.Size(30,493) 
$LogFilterLabel.Size = New-Object System.Drawing.Size(70,15) 
$LogFilterLabel.Text = "Log Filter:"
$LogFilterLabel.TabStop = $False
$LogFilterLabel.Anchor = [System.Windows.Forms.AnchorStyles]::Bottom
$objForm.Controls.Add($LogFilterLabel)


#FilterBox box ============================================================
$SyncHash.LogFilterBox = new-object System.Windows.Forms.textbox
$SyncHash.LogFilterBox.location = new-object system.drawing.size(110,490)
$SyncHash.LogFilterBox.size= new-object system.drawing.size(400,15)
$SyncHash.LogFilterBox.text = ""   
$SyncHash.LogFilterBox.tabIndex = 4
$SyncHash.LogFilterBox.Anchor = [System.Windows.Forms.AnchorStyles]::Bottom
$objform.controls.add($SyncHash.LogFilterBox)



$OutFileLabel = New-Object System.Windows.Forms.Label
$OutFileLabel.Location = New-Object System.Drawing.Size(30,523) 
$OutFileLabel.Size = New-Object System.Drawing.Size(70,15) 
$OutFileLabel.Text = "Log File:"
$OutFileLabel.TabStop = $False
$OutFileLabel.Anchor = [System.Windows.Forms.AnchorStyles]::Bottom
$objForm.Controls.Add($OutFileLabel)


#File Text box ============================================================
$SyncHash.FileLocationTextBox = New-Object System.Windows.Forms.TextBox
$SyncHash.FileLocationTextBox.location = new-object system.drawing.size(110,520)
$SyncHash.FileLocationTextBox.size = new-object system.drawing.size(300,23)
$SyncHash.FileLocationTextBox.tabIndex = 5
$SyncHash.FileLocationTextBox.text = $LogFilePath
$SyncHash.FileLocationTextBox.Anchor = [System.Windows.Forms.AnchorStyles]::Bottom  
$objform.controls.add($SyncHash.FileLocationTextBox)


#File Browse button
$BrowseButton = New-Object System.Windows.Forms.Button
$BrowseButton.Location = New-Object System.Drawing.Size(420,520)
$BrowseButton.Size = New-Object System.Drawing.Size(70,18)
$BrowseButton.Text = "Browse..."
$BrowseButton.tabIndex = 6
$BrowseButton.Anchor = [System.Windows.Forms.AnchorStyles]::Bottom
$BrowseButton.Add_Click(
{
	
	#File Dialog
	[string] $pathVar = "C:\"
	$Filter="All Files (*.*)|*.*"
	[System.Reflection.Assembly]::LoadWithPartialName("System.Windows.Forms") | Out-Null
	$objDialog = New-Object System.Windows.Forms.SaveFileDialog
	#$objDialog.InitialDirectory = 
	$objDialog.FileName = "PowerSyslog.txt"
	$objDialog.Filter = $Filter
	$objDialog.Title = "Export File Name"
	$objDialog.CheckFileExists = $false
	$Show = $objDialog.ShowDialog()
	if ($Show -eq "OK")
	{
		[string]$content = ""
		
		$fileName = $objDialog.FileName
		$SyncHash.FileLocationTextBox.text = $fileName
		
		#If the config file exists then add the LogFile setting to it...
		$ValidPath = Test-Path $SettingsFile
		if ($ValidPath -eq $True)
		{
			$contents = [IO.File]::ReadAllText(($SettingsFile)) 
						
			if($contents -match "LogFile\s*?=")
			{
				Write-Host "INFO: Found config file that contains LogFile setting. Updating existing setting with $fileName" -foreground "green"
				#$regex = ".*LogFile=`"(.*)`""
				$regex = '(?<=LogFile=")[^"]*'
				$outputContents = $contents -replace $regex, "$fileName"
				[IO.File]::WriteAllText($SettingsFile, $outputContents)
			}
			else
			{
				Write-Host "INFO: Found config file without a LogFile setting. Adding setting for LogFile: $fileName" -foreground "green"
				
				if($contents -notmatch '(?<=\r\n)\z')
				{
					$outputContents = "${contents}`r`nLogFile=`"$fileName`""
					[IO.File]::WriteAllText($SettingsFile, $outputContents)
				}
				else
				{
					$outputContents = "${contents}LogFile=`"$fileName`""
					[IO.File]::WriteAllText($SettingsFile, $outputContents)
				}
			}
		}
	}
	else
	{
		return
	}
})
$objForm.Controls.Add($BrowseButton)

# Add OutFileCheckBox ============================================================
$SyncHash.OutFileCheckBox = New-Object System.Windows.Forms.Checkbox 
$SyncHash.OutFileCheckBox.Location = New-Object System.Drawing.Size(500,520) 
$SyncHash.OutFileCheckBox.Size = New-Object System.Drawing.Size(20,20)
$SyncHash.OutFileCheckBox.tabIndex = 7
$SyncHash.OutFileCheckBox.Anchor = [System.Windows.Forms.AnchorStyles]::Bottom
$objForm.Controls.Add($SyncHash.OutFileCheckBox) 

$LogToFileLabel = New-Object System.Windows.Forms.Label
$LogToFileLabel.Location = New-Object System.Drawing.Size(517,523) 
$LogToFileLabel.Size = New-Object System.Drawing.Size(60,15) 
$LogToFileLabel.Text = "Log to File"
$LogToFileLabel.TabStop = $False
$LogToFileLabel.Anchor = [System.Windows.Forms.AnchorStyles]::Bottom
$objForm.Controls.Add($LogToFileLabel)


$RollFileLabel = New-Object System.Windows.Forms.Label
$RollFileLabel.Location = New-Object System.Drawing.Size(30,553) 
$RollFileLabel.Size = New-Object System.Drawing.Size(70,15) 
$RollFileLabel.Text = "Roll File:"
$RollFileLabel.TabStop = $False
$RollFileLabel.Anchor = [System.Windows.Forms.AnchorStyles]::Bottom
$objForm.Controls.Add($RollFileLabel)

$SyncHash.rollNumberBox = New-Object System.Windows.Forms.NumericUpDown
$SyncHash.rollNumberBox.Location = New-Object Drawing.Size(110,550) 
$SyncHash.rollNumberBox.Size = New-Object Drawing.Size(50,24)
$SyncHash.rollNumberBox.Minimum = 100
$SyncHash.rollNumberBox.Maximum = 10000
$SyncHash.rollNumberBox.Increment = 100
$SyncHash.rollNumberBox.Value = $RollFileDefault
$SyncHash.rollNumberBox.tabIndex = 8
$SyncHash.rollNumberBox.Anchor = [System.Windows.Forms.AnchorStyles]::Bottom
$objForm.Controls.Add($SyncHash.rollNumberBox)

$SyncHash.rollNumberBox.Add_ValueChanged(
{
	[string]$theSetting = $SyncHash.rollNumberBox.Value
	
	#If the config file exists then add the RollFile setting to it...
	$ValidPath = Test-Path $SettingsFile
	if ($ValidPath -eq $True)
	{
		$contents = [IO.File]::ReadAllText(($SettingsFile)) 
		if($contents -match "RollFile\s*?=")
		{
			Write-Host "INFO: Found config file that contains RollFile setting. Updating existing setting with $theSetting" -foreground "green"
			$regex = '(?<=RollFile=")[^"]*'
			$outputContents = $contents -replace $regex, "$theSetting"
			[IO.File]::WriteAllText($SettingsFile, $outputContents)
		}
		else
		{
			Write-Host "INFO: Found config file without a KeepFiles setting. Adding setting for RollFile: $theSetting" -foreground "green"
			if($contents -notmatch '(?<=\r\n)\z')
			{
				$outputContents = "${contents}`r`nRollFile=`"$theSetting`""
				[IO.File]::WriteAllText($SettingsFile, $outputContents)
			}
			else
			{
				$outputContents = "${contents}RollFile=`"$theSetting`""
				[IO.File]::WriteAllText($SettingsFile, $outputContents)
			}
		}
	}
})


$KeepFileLabel = New-Object System.Windows.Forms.Label
$KeepFileLabel.Location = New-Object System.Drawing.Size(200,554) 
$KeepFileLabel.Size = New-Object System.Drawing.Size(65,15) 
$KeepFileLabel.Text = "Keep Files:"
$KeepFileLabel.TabStop = $False
$KeepFileLabel.Anchor = [System.Windows.Forms.AnchorStyles]::Bottom
$objForm.Controls.Add($KeepFileLabel)

$SyncHash.KeepNumberBox = New-Object System.Windows.Forms.NumericUpDown
$SyncHash.KeepNumberBox.Location = New-Object Drawing.Size(265,550) 
$SyncHash.KeepNumberBox.Size = New-Object Drawing.Size(50,24)
$SyncHash.KeepNumberBox.Minimum = 1
$SyncHash.KeepNumberBox.Maximum = 1000
$SyncHash.KeepNumberBox.Increment = 1
$SyncHash.KeepNumberBox.Value = $KeepNumberDefault
$SyncHash.KeepNumberBox.tabIndex = 9
$SyncHash.KeepNumberBox.Anchor = [System.Windows.Forms.AnchorStyles]::Bottom
$objForm.Controls.Add($SyncHash.KeepNumberBox)


$SyncHash.KeepNumberBox.Add_ValueChanged(
{
	[string]$theSetting = $SyncHash.KeepNumberBox.Value
	
	#If the config file exists then add the KeepFiles setting to it...
	$ValidPath = Test-Path $SettingsFile
	if ($ValidPath -eq $True)
	{
		$contents = [IO.File]::ReadAllText(($SettingsFile)) 
		if($contents -match "KeepFiles\s*?=")
		{
			Write-Host "INFO: Found config file that contains KeepFiles setting. Updating existing setting with $theSetting" -foreground "green"
			$regex = '(?<=KeepFiles=")[^"]*'
			$outputContents = $contents -replace $regex, "$theSetting"
			[IO.File]::WriteAllText($SettingsFile, $outputContents)
		}
		else
		{
			Write-Host "INFO: Found config file without a KeepFiles setting. Adding setting for KeepFiles: $theSetting" -foreground "green"
			if($contents -notmatch '(?<=\r\n)\z')
			{
				$outputContents = "${contents}`r`nKeepFiles=`"$theSetting`""
				[IO.File]::WriteAllText($SettingsFile, $outputContents)
			}
			else
			{
				$outputContents = "${contents}KeepFiles=`"$theSetting`""
				[IO.File]::WriteAllText($SettingsFile, $outputContents)
			}
		}
	}
})

$RollFileKBLabel = New-Object System.Windows.Forms.Label
$RollFileKBLabel.Location = New-Object System.Drawing.Size(165,554) 
$RollFileKBLabel.Size = New-Object System.Drawing.Size(20,15) 
$RollFileKBLabel.Text = "KB"
$RollFileKBLabel.TabStop = $False
$RollFileKBLabel.Anchor = [System.Windows.Forms.AnchorStyles]::Bottom
$objForm.Controls.Add($RollFileKBLabel)



$FormatLabel = New-Object System.Windows.Forms.Label
$FormatLabel.Location = New-Object System.Drawing.Size(330,554) 
$FormatLabel.Size = New-Object System.Drawing.Size(45,15) 
$FormatLabel.Text = "Format:"
$FormatLabel.TabStop = $False
$FormatLabel.Anchor = [System.Windows.Forms.AnchorStyles]::Bottom
$objForm.Controls.Add($FormatLabel)


# Format Dropdown box ============================================================
$FormatDropDownBox = New-Object System.Windows.Forms.ComboBox 
$FormatDropDownBox.Location = New-Object System.Drawing.Size(376,550) 
$FormatDropDownBox.Size = New-Object System.Drawing.Size(110,20) 
$FormatDropDownBox.DropDownHeight = 70 
$FormatDropDownBox.tabIndex = 4
$FormatDropDownBox.DropDownStyle = [System.Windows.Forms.ComboBoxStyle]::DropDownList
$FormatDropDownBox.Anchor = [System.Windows.Forms.AnchorStyles]::Bottom
$objForm.Controls.Add($FormatDropDownBox) 

[void] $FormatDropDownBox.Items.Add("None")
[void] $FormatDropDownBox.Items.Add("AudioCodes")
[void] $FormatDropDownBox.Items.Add("SonusLX")
[void] $FormatDropDownBox.Items.Add("Level")
[void] $FormatDropDownBox.Items.Add("DateTime")
[void] $FormatDropDownBox.Items.Add("DateTimeLevel")
[void] $FormatDropDownBox.Items.Add("DateTimeLevelIP")

$FormatDropDownBox.SelectedIndex = $SyncHash.FormatOutput

$FormatDropDownBox.Add_SelectedIndexChanged(
{
	$SyncHash.FormatOutput = $FormatDropDownBox.SelectedIndex
	[string]$theSetting = $FormatDropDownBox.SelectedItem
	
	#If the config file exists then add the Format setting to it...
	$ValidPath = Test-Path $SettingsFile
	if ($ValidPath -eq $True)
	{
		$contents = [IO.File]::ReadAllText(($SettingsFile)) 
		if($contents -match "Format\s*?=")
		{
			Write-Host "INFO: Found config file that contains Format setting. Updating existing setting with $fileName" -foreground "green"
			$regex = '(?<=Format=")[^"]*'
			#$contents -replace $regex, "$fileName" | Set-Content $SettingsFile
			$outputContents = $contents -replace $regex, "$theSetting"
			[IO.File]::WriteAllText($SettingsFile, $outputContents)
		}
		else
		{
			Write-Host "INFO: Found config file without a Format setting. Adding setting for Format: $fileName" -foreground "green"
			if($contents -notmatch '(?<=\r\n)\z')
			{
				$outputContents = "${contents}`r`nFormat=`"$theSetting`""
				[IO.File]::WriteAllText($SettingsFile, $outputContents)
			}
			else
			{
				$outputContents = "${contents}Format=`"$theSetting`""
				[IO.File]::WriteAllText($SettingsFile, $outputContents)
			}
		}
	}
})




$MyLinkLabel = New-Object System.Windows.Forms.LinkLabel
$MyLinkLabel.Location = New-Object System.Drawing.Size(430,579)
$MyLinkLabel.Size = New-Object System.Drawing.Size(180,15)
$MyLinkLabel.DisabledLinkColor = [System.Drawing.Color]::Red
$MyLinkLabel.VisitedLinkColor = [System.Drawing.Color]::Blue
$MyLinkLabel.LinkBehavior = [System.Windows.Forms.LinkBehavior]::HoverUnderline
$MyLinkLabel.LinkColor = [System.Drawing.Color]::Navy
$MyLinkLabel.TabStop = $False
$MyLinkLabel.Text = "Created by: www.myskypelab.com"
$MyLinkLabel.Anchor = [System.Windows.Forms.AnchorStyles]::Bottom -bor [System.Windows.Forms.AnchorStyles]::Right
$MyLinkLabel.add_click(
{
	 [system.Diagnostics.Process]::start("http://www.myskypelab.com")
})
$objForm.Controls.Add($MyLinkLabel)

#Functions ==============================================================

$stopButton.Enabled = $false



		
function OpenFirewallButton
{
	
	if(([Security.Principal.WindowsPrincipal] [Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator))
	{
		$DefaultPortNumber = $SyncHash.SysLogPort
		$Ports = @("UDP,$DefaultPortNumber")
		
		foreach($Port in $Ports)
		{
			$PortSplit = $Port.Split(",")
			$protocol = $PortSplit[0]
			$portNumber = $PortSplit[1]
			$Result = Invoke-Expression "netsh advfirewall firewall add rule name=`"POWER SYSLOG SERVER ($protocol-in $portNumber)`" dir=in action=allow protocol=$protocol localport=$portNumber profile=any"
			Write-Host "Creating temp firewall rule `"POWER SYSLOG SERVER ($protocol-in $portNumber)`": $Result" -foreground "yellow"
		}
	}
	else
	{
		Write-Host "ERROR: Powershell is not running as Administrator. You need to Rus As Administrator to open Firewall ports." -foreground "red"
	}
}

function CloseFirewallButton
{
	if(([Security.Principal.WindowsPrincipal] [Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator))
	{
		$DefaultPortNumber = $SyncHash.SysLogPort
		$Ports = @("UDP,$DefaultPortNumber")
		
		foreach($Port in $Ports)
		{
			$PortSplit = $Port.Split(",")
			$protocol = $PortSplit[0]
			$portNumber = $PortSplit[1]
			$Result = Invoke-Expression "netsh advfirewall firewall delete rule name=`"POWER SYSLOG SERVER ($protocol-in $portNumber)`""
			Write-Host "Deleting temp firewall rule `"POWER SYSLOG SERVER ($protocol-in $portNumber)`": $Result" -foreground "yellow"
		}
	}
	else
	{
		Write-Host "ERROR: Powershell is not running as Administrator. You need to Rus As Administrator to open Firewall ports." -foreground "red"
	}
}

function CheckFirewall
{
	[string]$Result = Invoke-Expression "netsh advfirewall firewall show rule name=all"
	
	Write-host ""
	Write-host "Checking if firewall ports are open..."
	
	$DefaultPortNumber = $SyncHash.SysLogPort
	$Ports = @("UDP,$DefaultPortNumber")
	Write-host ""
	$Count = 0
	$WarningFlag = $false
	foreach($Port in $Ports)
	{
		$PortSplit = $Port.Split(",")
		$protocol = $PortSplit[0]
		$portNumber = $PortSplit[1]
		if($Result.Contains("POWER SYSLOG SERVER ($protocol-in $portNumber)"))
		{
			Write-host "Found Firewall Rule: POWER SYSLOG SERVER ($protocol-in $portNumber)" -foreground "green"
			$Count++
		}
		else
		{
			Write-host "Warning: Did not find firewall rule for ($protocol-in $portNumber)." -foreground "yellow"
			$WarningFlag = $true
		}
		
	}
	if($warningFlag)
	{
		Write-host "Warning: Did not find firewall rules. Use the Open Firewall button to temporarily open Listening ports." -foreground "yellow"
	}
	else
	{
		Write-host "Warning: Once you are finished testing, remember to close the temporary firewall ports." -foreground "yellow"
	}
	Write-host ""
	return $Count
}


$Count = CheckFirewall
if($Count -eq 0)
{
	$OpenFirewallButton.Text = "Open Firewall"
}
else
{
	$OpenFirewallButton.Text = "Close Firewall"
}

# Activate the form ============================================================
$objForm.Add_Shown({$objForm.Activate()})
$objForm.add_FormClosed({
	Write-Host "Exiting..."
	if(!$startButton.Enabled)
	{
		Write-host "Closing Socket..."
 
		$SyncHash.UDPServerSocket.Close()
		$objServerThread.objRunspace.Close()
		$objServerThread.objPowershell.Dispose()
		
		Write-Host "Killing GUI Thread."
		#Kill GUI Thread
		$objServerThreadLogging.objRunspaceLogging.Close()
		$objServerThreadLogging.objPowershellLogging.Dispose()		
		
		$SyncHash.FileNumber = 1
		$SyncHash.UDPServerSocket = $Null
		$SyncHash.LogText = ""
		$SyncHash.LogFileText = ""
	
		Write-Host "Socket Closed."
	}
	
})


[void] $objForm.ShowDialog()	


# SIG # Begin signature block
# MIIcZgYJKoZIhvcNAQcCoIIcVzCCHFMCAQExCzAJBgUrDgMCGgUAMGkGCisGAQQB
# gjcCAQSgWzBZMDQGCisGAQQBgjcCAR4wJgIDAQAABBAfzDtgWUsITrck0sYpfvNR
# AgEAAgEAAgEAAgEAAgEAMCEwCQYFKw4DAhoFAAQUKv67PkwtJ4RkF9xhwjR/YO5z
# 27yggheVMIIFHjCCBAagAwIBAgIQBqM5iX2/nFGN8MjuodKqbDANBgkqhkiG9w0B
# AQsFADByMQswCQYDVQQGEwJVUzEVMBMGA1UEChMMRGlnaUNlcnQgSW5jMRkwFwYD
# VQQLExB3d3cuZGlnaWNlcnQuY29tMTEwLwYDVQQDEyhEaWdpQ2VydCBTSEEyIEFz
# c3VyZWQgSUQgQ29kZSBTaWduaW5nIENBMB4XDTE3MDMwNjAwMDAwMFoXDTE4MDMx
# NDEyMDAwMFowWzELMAkGA1UEBhMCQVUxDDAKBgNVBAgTA1ZJQzEQMA4GA1UEBxMH
# TWl0Y2hhbTEVMBMGA1UEChMMSmFtZXMgQ3Vzc2VuMRUwEwYDVQQDEwxKYW1lcyBD
# dXNzZW4wggEiMA0GCSqGSIb3DQEBAQUAA4IBDwAwggEKAoIBAQCg8fMN/8rshNlQ
# 8Potedk7oUmxaYvNpCh0o+ikv1QgPaB8KaL2bUahLL8/uZmqK7pO3ANjQhh3SM/Q
# aURzhwk9cI096G3Hc9wIPf7qJPQk63cmErSsV1cHATPib34bEi4RjJPtesdUqFS0
# PzgR1x/fzZy8P5AgRJF/BzPXZK5L3UVHv4JYWbXcvPMtQ3wNNlFheZMRXMAbAJFr
# o7bHvpZdQVOIgFOPUtHgIkkun87HAuzr8RxKcir2rWPwz0E3Gv9iWVA/UVx6mScr
# JomojtkU8f5UqE2vrmHeiw4n+lgAOD8jDD7GFYMwucOStXqBkMOvYYdWVK+TO4vo
# Bl58b4/1AgMBAAGjggHFMIIBwTAfBgNVHSMEGDAWgBRaxLl7KgqjpepxA8Bg+S32
# ZXUOWDAdBgNVHQ4EFgQUA7w5BxjbNMvUcqd4V+o9YGLoXZowDgYDVR0PAQH/BAQD
# AgeAMBMGA1UdJQQMMAoGCCsGAQUFBwMDMHcGA1UdHwRwMG4wNaAzoDGGL2h0dHA6
# Ly9jcmwzLmRpZ2ljZXJ0LmNvbS9zaGEyLWFzc3VyZWQtY3MtZzEuY3JsMDWgM6Ax
# hi9odHRwOi8vY3JsNC5kaWdpY2VydC5jb20vc2hhMi1hc3N1cmVkLWNzLWcxLmNy
# bDBMBgNVHSAERTBDMDcGCWCGSAGG/WwDATAqMCgGCCsGAQUFBwIBFhxodHRwczov
# L3d3dy5kaWdpY2VydC5jb20vQ1BTMAgGBmeBDAEEATCBhAYIKwYBBQUHAQEEeDB2
# MCQGCCsGAQUFBzABhhhodHRwOi8vb2NzcC5kaWdpY2VydC5jb20wTgYIKwYBBQUH
# MAKGQmh0dHA6Ly9jYWNlcnRzLmRpZ2ljZXJ0LmNvbS9EaWdpQ2VydFNIQTJBc3N1
# cmVkSURDb2RlU2lnbmluZ0NBLmNydDAMBgNVHRMBAf8EAjAAMA0GCSqGSIb3DQEB
# CwUAA4IBAQBGvQDleLco72A/aFvQWtH7VwxaTCVK2SP0OQFi9mD/VdflJwKMOg1k
# ZpidEd9FlB1Dm/HfntfVTQGSSKbwOWmjX/gd0rfj1hYi/KgNWsoPZIGJHWa5KitU
# 92qYHhbOuLety4xqK4/94IjwhinavMsOqEqplAxzglCLAWI7Xhj4KR9J8cLbi/MR
# lAUsV96QHOiO6+JnLPyMaPGRH1PWNuXzp/1dum3enR77HjcEpPPjBO5CrCI2UFLJ
# ByhZRkQ7L1i6ZcHJNLA7X+OEnDhVir6gJnMxx0OORz1M3UxPALifVhZdKuAYmy4w
# JHzuO/vEu/C2kwA/BvYVL4ASMEh81sQlMIIFMDCCBBigAwIBAgIQBAkYG1/Vu2Z1
# U0O1b5VQCDANBgkqhkiG9w0BAQsFADBlMQswCQYDVQQGEwJVUzEVMBMGA1UEChMM
# RGlnaUNlcnQgSW5jMRkwFwYDVQQLExB3d3cuZGlnaWNlcnQuY29tMSQwIgYDVQQD
# ExtEaWdpQ2VydCBBc3N1cmVkIElEIFJvb3QgQ0EwHhcNMTMxMDIyMTIwMDAwWhcN
# MjgxMDIyMTIwMDAwWjByMQswCQYDVQQGEwJVUzEVMBMGA1UEChMMRGlnaUNlcnQg
# SW5jMRkwFwYDVQQLExB3d3cuZGlnaWNlcnQuY29tMTEwLwYDVQQDEyhEaWdpQ2Vy
# dCBTSEEyIEFzc3VyZWQgSUQgQ29kZSBTaWduaW5nIENBMIIBIjANBgkqhkiG9w0B
# AQEFAAOCAQ8AMIIBCgKCAQEA+NOzHH8OEa9ndwfTCzFJGc/Q+0WZsTrbRPV/5aid
# 2zLXcep2nQUut4/6kkPApfmJ1DcZ17aq8JyGpdglrA55KDp+6dFn08b7KSfH03sj
# lOSRI5aQd4L5oYQjZhJUM1B0sSgmuyRpwsJS8hRniolF1C2ho+mILCCVrhxKhwjf
# DPXiTWAYvqrEsq5wMWYzcT6scKKrzn/pfMuSoeU7MRzP6vIK5Fe7SrXpdOYr/mzL
# fnQ5Ng2Q7+S1TqSp6moKq4TzrGdOtcT3jNEgJSPrCGQ+UpbB8g8S9MWOD8Gi6CxR
# 93O8vYWxYoNzQYIH5DiLanMg0A9kczyen6Yzqf0Z3yWT0QIDAQABo4IBzTCCAckw
# EgYDVR0TAQH/BAgwBgEB/wIBADAOBgNVHQ8BAf8EBAMCAYYwEwYDVR0lBAwwCgYI
# KwYBBQUHAwMweQYIKwYBBQUHAQEEbTBrMCQGCCsGAQUFBzABhhhodHRwOi8vb2Nz
# cC5kaWdpY2VydC5jb20wQwYIKwYBBQUHMAKGN2h0dHA6Ly9jYWNlcnRzLmRpZ2lj
# ZXJ0LmNvbS9EaWdpQ2VydEFzc3VyZWRJRFJvb3RDQS5jcnQwgYEGA1UdHwR6MHgw
# OqA4oDaGNGh0dHA6Ly9jcmw0LmRpZ2ljZXJ0LmNvbS9EaWdpQ2VydEFzc3VyZWRJ
# RFJvb3RDQS5jcmwwOqA4oDaGNGh0dHA6Ly9jcmwzLmRpZ2ljZXJ0LmNvbS9EaWdp
# Q2VydEFzc3VyZWRJRFJvb3RDQS5jcmwwTwYDVR0gBEgwRjA4BgpghkgBhv1sAAIE
# MCowKAYIKwYBBQUHAgEWHGh0dHBzOi8vd3d3LmRpZ2ljZXJ0LmNvbS9DUFMwCgYI
# YIZIAYb9bAMwHQYDVR0OBBYEFFrEuXsqCqOl6nEDwGD5LfZldQ5YMB8GA1UdIwQY
# MBaAFEXroq/0ksuCMS1Ri6enIZ3zbcgPMA0GCSqGSIb3DQEBCwUAA4IBAQA+7A1a
# JLPzItEVyCx8JSl2qB1dHC06GsTvMGHXfgtg/cM9D8Svi/3vKt8gVTew4fbRknUP
# UbRupY5a4l4kgU4QpO4/cY5jDhNLrddfRHnzNhQGivecRk5c/5CxGwcOkRX7uq+1
# UcKNJK4kxscnKqEpKBo6cSgCPC6Ro8AlEeKcFEehemhor5unXCBc2XGxDI+7qPjF
# Emifz0DLQESlE/DmZAwlCEIysjaKJAL+L3J+HNdJRZboWR3p+nRka7LrZkPas7CM
# 1ekN3fYBIM6ZMWM9CBoYs4GbT8aTEAb8B4H6i9r5gkn3Ym6hU/oSlBiFLpKR6mhs
# RDKyZqHnGKSaZFHvMIIGajCCBVKgAwIBAgIQAwGaAjr/WLFr1tXq5hfwZjANBgkq
# hkiG9w0BAQUFADBiMQswCQYDVQQGEwJVUzEVMBMGA1UEChMMRGlnaUNlcnQgSW5j
# MRkwFwYDVQQLExB3d3cuZGlnaWNlcnQuY29tMSEwHwYDVQQDExhEaWdpQ2VydCBB
# c3N1cmVkIElEIENBLTEwHhcNMTQxMDIyMDAwMDAwWhcNMjQxMDIyMDAwMDAwWjBH
# MQswCQYDVQQGEwJVUzERMA8GA1UEChMIRGlnaUNlcnQxJTAjBgNVBAMTHERpZ2lD
# ZXJ0IFRpbWVzdGFtcCBSZXNwb25kZXIwggEiMA0GCSqGSIb3DQEBAQUAA4IBDwAw
# ggEKAoIBAQCjZF38fLPggjXg4PbGKuZJdTvMbuBTqZ8fZFnmfGt/a4ydVfiS457V
# WmNbAklQ2YPOb2bu3cuF6V+l+dSHdIhEOxnJ5fWRn8YUOawk6qhLLJGJzF4o9GS2
# ULf1ErNzlgpno75hn67z/RJ4dQ6mWxT9RSOOhkRVfRiGBYxVh3lIRvfKDo2n3k5f
# 4qi2LVkCYYhhchhoubh87ubnNC8xd4EwH7s2AY3vJ+P3mvBMMWSN4+v6GYeofs/s
# jAw2W3rBerh4x8kGLkYQyI3oBGDbvHN0+k7Y/qpA8bLOcEaD6dpAoVk62RUJV5lW
# MJPzyWHM0AjMa+xiQpGsAsDvpPCJEY93AgMBAAGjggM1MIIDMTAOBgNVHQ8BAf8E
# BAMCB4AwDAYDVR0TAQH/BAIwADAWBgNVHSUBAf8EDDAKBggrBgEFBQcDCDCCAb8G
# A1UdIASCAbYwggGyMIIBoQYJYIZIAYb9bAcBMIIBkjAoBggrBgEFBQcCARYcaHR0
# cHM6Ly93d3cuZGlnaWNlcnQuY29tL0NQUzCCAWQGCCsGAQUFBwICMIIBVh6CAVIA
# QQBuAHkAIAB1AHMAZQAgAG8AZgAgAHQAaABpAHMAIABDAGUAcgB0AGkAZgBpAGMA
# YQB0AGUAIABjAG8AbgBzAHQAaQB0AHUAdABlAHMAIABhAGMAYwBlAHAAdABhAG4A
# YwBlACAAbwBmACAAdABoAGUAIABEAGkAZwBpAEMAZQByAHQAIABDAFAALwBDAFAA
# UwAgAGEAbgBkACAAdABoAGUAIABSAGUAbAB5AGkAbgBnACAAUABhAHIAdAB5ACAA
# QQBnAHIAZQBlAG0AZQBuAHQAIAB3AGgAaQBjAGgAIABsAGkAbQBpAHQAIABsAGkA
# YQBiAGkAbABpAHQAeQAgAGEAbgBkACAAYQByAGUAIABpAG4AYwBvAHIAcABvAHIA
# YQB0AGUAZAAgAGgAZQByAGUAaQBuACAAYgB5ACAAcgBlAGYAZQByAGUAbgBjAGUA
# LjALBglghkgBhv1sAxUwHwYDVR0jBBgwFoAUFQASKxOYspkH7R7for5XDStnAs0w
# HQYDVR0OBBYEFGFaTSS2STKdSip5GoNL9B6Jwcp9MH0GA1UdHwR2MHQwOKA2oDSG
# Mmh0dHA6Ly9jcmwzLmRpZ2ljZXJ0LmNvbS9EaWdpQ2VydEFzc3VyZWRJRENBLTEu
# Y3JsMDigNqA0hjJodHRwOi8vY3JsNC5kaWdpY2VydC5jb20vRGlnaUNlcnRBc3N1
# cmVkSURDQS0xLmNybDB3BggrBgEFBQcBAQRrMGkwJAYIKwYBBQUHMAGGGGh0dHA6
# Ly9vY3NwLmRpZ2ljZXJ0LmNvbTBBBggrBgEFBQcwAoY1aHR0cDovL2NhY2VydHMu
# ZGlnaWNlcnQuY29tL0RpZ2lDZXJ0QXNzdXJlZElEQ0EtMS5jcnQwDQYJKoZIhvcN
# AQEFBQADggEBAJ0lfhszTbImgVybhs4jIA+Ah+WI//+x1GosMe06FxlxF82pG7xa
# FjkAneNshORaQPveBgGMN/qbsZ0kfv4gpFetW7easGAm6mlXIV00Lx9xsIOUGQVr
# NZAQoHuXx/Y/5+IRQaa9YtnwJz04HShvOlIJ8OxwYtNiS7Dgc6aSwNOOMdgv420X
# Ewbu5AO2FKvzj0OncZ0h3RTKFV2SQdr5D4HRmXQNJsQOfxu19aDxxncGKBXp2JPl
# VRbwuwqrHNtcSCdmyKOLChzlldquxC5ZoGHd2vNtomHpigtt7BIYvfdVVEADkitr
# wlHCCkivsNRu4PQUCjob4489yq9qjXvc2EQwggbNMIIFtaADAgECAhAG/fkDlgOt
# 6gAK6z8nu7obMA0GCSqGSIb3DQEBBQUAMGUxCzAJBgNVBAYTAlVTMRUwEwYDVQQK
# EwxEaWdpQ2VydCBJbmMxGTAXBgNVBAsTEHd3dy5kaWdpY2VydC5jb20xJDAiBgNV
# BAMTG0RpZ2lDZXJ0IEFzc3VyZWQgSUQgUm9vdCBDQTAeFw0wNjExMTAwMDAwMDBa
# Fw0yMTExMTAwMDAwMDBaMGIxCzAJBgNVBAYTAlVTMRUwEwYDVQQKEwxEaWdpQ2Vy
# dCBJbmMxGTAXBgNVBAsTEHd3dy5kaWdpY2VydC5jb20xITAfBgNVBAMTGERpZ2lD
# ZXJ0IEFzc3VyZWQgSUQgQ0EtMTCCASIwDQYJKoZIhvcNAQEBBQADggEPADCCAQoC
# ggEBAOiCLZn5ysJClaWAc0Bw0p5WVFypxNJBBo/JM/xNRZFcgZ/tLJz4FlnfnrUk
# FcKYubR3SdyJxArar8tea+2tsHEx6886QAxGTZPsi3o2CAOrDDT+GEmC/sfHMUiA
# fB6iD5IOUMnGh+s2P9gww/+m9/uizW9zI/6sVgWQ8DIhFonGcIj5BZd9o8dD3QLo
# Oz3tsUGj7T++25VIxO4es/K8DCuZ0MZdEkKB4YNugnM/JksUkK5ZZgrEjb7Szgau
# rYRvSISbT0C58Uzyr5j79s5AXVz2qPEvr+yJIvJrGGWxwXOt1/HYzx4KdFxCuGh+
# t9V3CidWfA9ipD8yFGCV/QcEogkCAwEAAaOCA3owggN2MA4GA1UdDwEB/wQEAwIB
# hjA7BgNVHSUENDAyBggrBgEFBQcDAQYIKwYBBQUHAwIGCCsGAQUFBwMDBggrBgEF
# BQcDBAYIKwYBBQUHAwgwggHSBgNVHSAEggHJMIIBxTCCAbQGCmCGSAGG/WwAAQQw
# ggGkMDoGCCsGAQUFBwIBFi5odHRwOi8vd3d3LmRpZ2ljZXJ0LmNvbS9zc2wtY3Bz
# LXJlcG9zaXRvcnkuaHRtMIIBZAYIKwYBBQUHAgIwggFWHoIBUgBBAG4AeQAgAHUA
# cwBlACAAbwBmACAAdABoAGkAcwAgAEMAZQByAHQAaQBmAGkAYwBhAHQAZQAgAGMA
# bwBuAHMAdABpAHQAdQB0AGUAcwAgAGEAYwBjAGUAcAB0AGEAbgBjAGUAIABvAGYA
# IAB0AGgAZQAgAEQAaQBnAGkAQwBlAHIAdAAgAEMAUAAvAEMAUABTACAAYQBuAGQA
# IAB0AGgAZQAgAFIAZQBsAHkAaQBuAGcAIABQAGEAcgB0AHkAIABBAGcAcgBlAGUA
# bQBlAG4AdAAgAHcAaABpAGMAaAAgAGwAaQBtAGkAdAAgAGwAaQBhAGIAaQBsAGkA
# dAB5ACAAYQBuAGQAIABhAHIAZQAgAGkAbgBjAG8AcgBwAG8AcgBhAHQAZQBkACAA
# aABlAHIAZQBpAG4AIABiAHkAIAByAGUAZgBlAHIAZQBuAGMAZQAuMAsGCWCGSAGG
# /WwDFTASBgNVHRMBAf8ECDAGAQH/AgEAMHkGCCsGAQUFBwEBBG0wazAkBggrBgEF
# BQcwAYYYaHR0cDovL29jc3AuZGlnaWNlcnQuY29tMEMGCCsGAQUFBzAChjdodHRw
# Oi8vY2FjZXJ0cy5kaWdpY2VydC5jb20vRGlnaUNlcnRBc3N1cmVkSURSb290Q0Eu
# Y3J0MIGBBgNVHR8EejB4MDqgOKA2hjRodHRwOi8vY3JsMy5kaWdpY2VydC5jb20v
# RGlnaUNlcnRBc3N1cmVkSURSb290Q0EuY3JsMDqgOKA2hjRodHRwOi8vY3JsNC5k
# aWdpY2VydC5jb20vRGlnaUNlcnRBc3N1cmVkSURSb290Q0EuY3JsMB0GA1UdDgQW
# BBQVABIrE5iymQftHt+ivlcNK2cCzTAfBgNVHSMEGDAWgBRF66Kv9JLLgjEtUYun
# pyGd823IDzANBgkqhkiG9w0BAQUFAAOCAQEARlA+ybcoJKc4HbZbKa9Sz1LpMUer
# Vlx71Q0LQbPv7HUfdDjyslxhopyVw1Dkgrkj0bo6hnKtOHisdV0XFzRyR4WUVtHr
# uzaEd8wkpfMEGVWp5+Pnq2LN+4stkMLA0rWUvV5PsQXSDj0aqRRbpoYxYqioM+Sb
# OafE9c4deHaUJXPkKqvPnHZL7V/CSxbkS3BMAIke/MV5vEwSV/5f4R68Al2o/vsH
# OE8Nxl2RuQ9nRc3Wg+3nkg2NsWmMT/tZ4CMP0qquAHzunEIOz5HXJ7cW7g/DvXwK
# oO4sCFWFIrjrGBpN/CohrUkxg0eVd3HcsRtLSxwQnHcUwZ1PL1qVCCkQJjGCBDsw
# ggQ3AgEBMIGGMHIxCzAJBgNVBAYTAlVTMRUwEwYDVQQKEwxEaWdpQ2VydCBJbmMx
# GTAXBgNVBAsTEHd3dy5kaWdpY2VydC5jb20xMTAvBgNVBAMTKERpZ2lDZXJ0IFNI
# QTIgQXNzdXJlZCBJRCBDb2RlIFNpZ25pbmcgQ0ECEAajOYl9v5xRjfDI7qHSqmww
# CQYFKw4DAhoFAKB4MBgGCisGAQQBgjcCAQwxCjAIoAKAAKECgAAwGQYJKoZIhvcN
# AQkDMQwGCisGAQQBgjcCAQQwHAYKKwYBBAGCNwIBCzEOMAwGCisGAQQBgjcCARUw
# IwYJKoZIhvcNAQkEMRYEFHdMhy9wcLZdMM2WWIsFzN/2bJoWMA0GCSqGSIb3DQEB
# AQUABIIBACOv2msaBYgKhwmYLuKjbXzyq7eUoL8qFiXq54BjCcVXG6BNVz6qQwIV
# v+v4/3XRy8Z8B0dj9FqDnA1tWR9KeIYokKim2Ig1HsG3KRth99NmycTr2BHpPE6J
# rqlah1XhQZi1DxPu1iIobgIcoIyog/tamJYGPfwBeh3p9BNBHFzbhtfTEjXe+XO1
# EsKsOTyiCKVYNnCq+2Ng69fQisI0yDi4AuGd+EcF4klp1docvPZ1k2AgNbLexAA2
# cyPkcr+rwJ6i2h3viQ2ZB4yUFPEFSlQKSxu/qfoI58Ov4oBSPUM7NCnJAyj1lyFL
# quz/+B4IGZIwpbPmOB8uinus5vcNo/uhggIPMIICCwYJKoZIhvcNAQkGMYIB/DCC
# AfgCAQEwdjBiMQswCQYDVQQGEwJVUzEVMBMGA1UEChMMRGlnaUNlcnQgSW5jMRkw
# FwYDVQQLExB3d3cuZGlnaWNlcnQuY29tMSEwHwYDVQQDExhEaWdpQ2VydCBBc3N1
# cmVkIElEIENBLTECEAMBmgI6/1ixa9bV6uYX8GYwCQYFKw4DAhoFAKBdMBgGCSqG
# SIb3DQEJAzELBgkqhkiG9w0BBwEwHAYJKoZIhvcNAQkFMQ8XDTE3MDgwOTA5NDUx
# OFowIwYJKoZIhvcNAQkEMRYEFPgqhGEEE0WavPgT+NE9A4UqDbwlMA0GCSqGSIb3
# DQEBAQUABIIBABu6JdljpSVpt5Wd49nm4ErAgq8YA4e1EWfoM/kyikPM81vOuehK
# Ixv6wbqXPQaOA9CwZHnMF6l938lxR/ZvarEy6Wk8pX4JTpYa/65Kgy5GnK62cf+M
# B7OwGeJU30Qa0UGLO+n0mbZlK9rSBrcEtGqtxWOc9qxRQ5vctkKC0kp1D6vUkPp6
# nNi3SEP3ihftt6LOJTsmwJ6L4Ein5ANumS1ZIu/eFm49hzk9xeK0+okD3pxgHkcv
# /J2hCTiBJj9qQj9mv1Z6XHvcng1AgGmfBpaEH78dn9BEGwh38E6rg0AHWiwhmEkb
# wc9glS2lLMKWJSgV0hT0Mob0UKBI7z8WBTw=
# SIG # End signature block
