<#

.SYNOPSIS
Collect Windows Event Log EVTX files into LogRhythm via Microsoft LogParser utility

.DESCRIPTION
LR-Evtx-Collector provides a wrapper around the Microsoft LogParser utility to collect and format Event Logs from a physical EVTX file into LogRhythm.  

.EXAMPLE
./LR-Evtx-Collector.ps1 -evtxFile "path\file.evtx" -outputFile "path\file.csv"

.PARAMETER
./LR-Evtx-Collector.ps1 [-logParser] <string[]> [-evtxFile] <string[]> [-evtxQuery] <string[]> [-outputFile] <string[]> [-debugMode <bool>]

.NOTES
 -- This script requires Microsoft's LogParser, download it here - https://www.microsoft.com/en-us/download/details.aspx?id=24659
 -- EVTX files under C:\Windows\System32\winevt\Logs cannot be read, they're locked by Windows.  If you need read these in copy them elsewhere first.

.REMARKS
 Known Bugs:
 -- EVTX files with a space in them will cause an exception.  At this time you'll need remove the space until it's fixed.

.LINK
@chrismartinit - https://github.com/lrchma

#>





#C:\Windows\System32\winevt\Logs

[CmdletBinding()]
param(
  [Parameter(Mandatory=$false)]
  [string]$logParser = "c:\program files (x86)\Log Parser 2.2\logparser.exe",

  [Parameter(Mandatory=$false)]
  [string]$evtxFile = "replaceme.evtx",
  
  [Parameter(Mandatory=$false)]
  [string]$evtxQuery = "`"SELECT TimeGenerated,ComputerName,SourceName,EventTypeName,EventID,EventLog,RecordNumber,Message from $evtxFile ORDER BY TimeGenerated DESC`"",

  [Parameter(Mandatory=$false)]
  [string]$outputFile = "out.csv",

  [Parameter(Mandatory=$false)]
  [bool]$debugMode = 0
)

trap [Exception] {
	write-error $("Exception: " + $_)
	exit 1
}


# ***************************************************
# FUNCTION(S)
# ***************************************************

#Used for output purposes to show ISO8601 date format
function Now(){
    $now = Get-Date -Format s
    return $now
}


# ***************************************************
# ERROR CHECKING
# ***************************************************


#Did user pass the -debugMode parameter?
if($debugMode){$DebugPreference = "Continue";write-debug "$(Now): Parameter -debugMode $true."}else{$DebugPreference = "SilentlyContinue"}

#Is LogParser installed?
if(Test-Path -path $logParser){write-debug "$(Now): LogParser found at $logParser"}else{write-output "ERROR: $(Now): LogParser was not found on this system.  Please specify the path using the -logParser parameter, or else download and install LogParser froom https://www.microsoft.com/en-us/download/details.aspx?id=24659"; break}

#Does the user specified Evtx file exist?
if(Test-Path -path $evtxFile){write-debug "$(Now): Event file found at $evtxFile"}else{write-output "ERROR: $(Now): Event log file not found, please check it exists or that the file is not currently in use."; break}


# ***************************************************
# MAIN
# ***************************************************

write-debug "$(now): Starting $logParser -i:EVT -o:CSV -q:ON $evtxQuery"
$resultSet = & $logParser -i:EVT -o:CSV -q:ON $evtxQuery

write-debug "$(now): Writing output to $outputFile"
$resultSet | Out-File $outputFile

write-output "$(now): Finished"
write-debug "$(now): Finished"



