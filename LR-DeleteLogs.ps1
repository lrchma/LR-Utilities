<#
.NAME
LR-DeleteLogs


.SYNOPSIS
LogRhythm generated log files can consume a large amount of disk space.  To ensure they don't consume all the available disk you can use this script manually or via a scheduled task to keep them disks full of space.


.DESCRIPTION
100% unofficial.  If it were possible to have more than 100% it'd be in that range!

#>

param(
  [Parameter(Mandatory=$false)]
  [string]$testMode = "true",
  [Parameter(Mandatory=$true)]
  [int]$deleteFilesOlderThan = -30
)

#ISE Testing
#remove-variable tempFileSize
#remove-variable totalSpaceReclaimed

#This script use Invoke-RestMethod which only comes with PowerShell 3.0 of higher.
if ($PSVersionTable.PSVersion -lt [Version]"3.0") {
  write-host "PowerShell version " $PSVersionTable.PSVersion "not supported.  This script requires PowerShell 3.0 or greater." -ForegroundColor Red
  exit
}


$logFiles = @(
"C:\Program Files\LogRhythm\logs"
"C:\Program Files\LogRhythm\LogRhythm AI Engine\logs"
"C:\Program Files\LogRhythm\LogRhythm Alarming and Response Manager\logs"
"C:\Program Files\LogRhythm\LogRhythm Common\logs"
"C:\Program Files\LogRhythm\LogRhythm Console\logs"
"C:\Program Files\LogRhythm\LogRhythm Job Manager\logs"
"C:\Program Files\LogRhythm\LogRhythm Mediator Server\logs"
"C:\Program Files\LogRhythm\LogRhythm System Monitor\logs"
"C:\Program Files\LogRhythm\LogRhythm Threat Intelligence Service\logs"
"C:\Program Files\LogRhythm\LogRhythm Web Console\logs"
"C:\Program Files\LogRhythm\LogRhythm Web Console UI\logs"
"C:\Program Files\LogRhythm\LogRhythm Web Services\logs"
"C:\Program Files\LogRhythm\Data Indexer\Denorm"
"C:\Program Files\LogRhythm\LogRhythm Console"
)

try  
{ 

if($testMode -eq "true"){

    #Test Mode - Don't delete files
    foreach ($logFile in $logFiles){
        if (Test-Path $logFile){
                $itemsToDelete = dir $logFile -Recurse -File *.log | Where LastWriteTime -lt ((get-date).AddDays($deleteFilesOlderThan)) 
        
                foreach($item in $itemsToDelete){
                    $tempFileSize = ((Measure-Object -inputObject $item -Property Length -Sum -ErrorAction Stop).Sum / 1MB) 
                    $totalSpaceReclaimed = $totalSpaceReclaimed + $tempFileSize
                    ("{0}\{1}" -f $item.DirectoryName, $item.Name) | Remove-Item -Verbose -WhatIf
                }
        }else
        {
            write-host "$logFile not found"
        }

}
                if ($totalSpaceReclaimed){
                        write-host "Total disk space reclaimed (MB): $totalSpaceReclaimed"
                }else{
                        write-host "Looks like no files met criteria."
                }
             }
             else{

     #Live Mode - Delete Files
     foreach ($logFile in $logFiles){
            if (Test-Path $logFile){
                $itemsToDelete = dir $logFile -Recurse -File *.log | Where LastWriteTime -lt ((get-date).AddDays($deleteFilesOlderThan)) 
    
                foreach($item in $itemsToDelete){
                        $tempFileSize = ((Measure-Object -inputObject $item -Property Length -Sum -ErrorAction Stop).Sum / 1MB) 
                        $totalSpaceReclaimed = $totalSpaceReclaimed + $tempFileSize
                        ("{0}\{1}" -f $item.DirectoryName, $item.Name) | Remove-Item -Verbose 
                    }   
            }else
            {
                write-host "$logFile not found"
            }
        }
        if ($totalSpaceReclaimed){
                write-host "Total disk space reclaimed (MB): $totalSpaceReclaimed"
        }else{
                write-host "Looks like no files met criteria."
        }
    }
}
 catch [System.UnauthorizedAccessException]
    {
        Write-Output "Unauthorized Access Exception: $logFile.  You shouldn't be here, but perhaps the folder path doesn't exist."
        Continue
    }
catch [System.IO.IOException]
{
        Write-Output "File In Use Exception: $item.Name.  Processes happen."
        Continue
}
catch {
        Write-Output "Exception: $_.Exception.  Well, this is awkward..."
}
Finally
{
}