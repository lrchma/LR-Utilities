<#
.NAME
LR-AIE-RecipeSelector

.SYNOPSIS
The following script contains coarse code and due to its content should not be viewed by anyone, ever.  But if you must, read on...

.DESCRIPTION
This script assumes you've already exported and imported a list of your available AIE rules into a local SQL server under the EMDB, in a table called dbo.aie.  If not, things wont end well...  

Assuming you have, then you can proceed to run this script with at minimum an argument of a a log source name, e.g., Windows, and it'll proceed to take that as a wildcarded argument and query the log source to get every possible Classification that can be generated.  It'll then take these results, and one by one query every AIE rule that can make use of those Clasifications.

Is this 100%?  No.  There could and are AIE rules that use Common Events only, or even MPE rules.  This won't work for those.  Also, while the Classifications may match between a log source and the AIE rule, this does not check that the Group By fields and MPE Rules for that log source extract the same fields.  But, it is better than nothing.

Oh, and yeah I didn't get the second parameterized SQL query bit working but this is a quick and dirty poc, so excuse that...

.EXAMPLE
./LR-AIE-RecipeSelector -LogSourceName "Cylance"
./LR-AIE-RecipeSelector -LogSourceName "Cylance" -AlarmRuleName "NIST"
./LR-AIE-RecipeSelector -LogSourceName "Cylance" -AlarmRuleName "NIST" -RBP 90
./LR-AIE-RecipeSelector -LogSourceName "Cylance" -AlarmRuleName "NIST" -RBP 90 -RuleGroup "Sec"

.PARAMETER
-LogSourceName = Wildcarded log source name
-AlarmRuleName = Wildcard match for the AIE rule name, useful for compliance modules
-RBP = Find Alarms over X RBP value
-RuleGroup = Filter the AIE rules description.  Note, while this is useful for Ops alarms, it doesn't really match up to content in the KB.  AlarmRuleName is more useful. 

#>

param(
  [Parameter(Mandatory=$true,Position=1)]
  [string]$LogSourceName,
  [Parameter(Mandatory=$false,Position=2)]
  [string]$RuleGroup ,
  [Parameter(Mandatory=$false,Position=3)]
  [string]$RBP = 0,
  [Parameter(Mandatory=$false,Position=4)]
  [string]$AlarmRuleName 
)

if ($PSVersionTable.PSVersion -lt [Version]"3.0") {
  write-output "PowerShell version " $PSVersionTable.PSVersion "not supported.  This script requires PowerShell 3.0 or greater." -ForegroundColor Red
  exit
}

if (!(Test-Path "C:\Program Files\LogRhythm\LogRhythm Alarming and Response Manager\scarm.exe")){
  # We are not on the PM so exit
  write-output "This Powershell/SmartResponse may only be run on the LogRhythm Platform Manager"
  Exit 20
}

function Select-ParameterizedSQLPS
{
    [cmdletbinding()]
    param (
        [string]$LogSourceName

    )
    #Push-Location; Import-Module SQLPS -DisableNameChecking; Pop-Location
    $sql1 = "N'SELECT
MSGSourceType.FullName AS LogSource,
Classification.[FullName] AS ClassificationType,
Classification.[Name] AS ClassificationName
FROM [LogRhythmEMDB].[dbo].[MsgClass] Classification
INNER JOIN [LogRhythmEMDB].[dbo].[CommonEvent] COMMONEVENT ON Classification.MsgClassID = COMMONEVENT.MsgClassID
INNER JOIN [LogRhythmEMDB].[dbo].[MPERule] MPE ON COMMONEVENT.CommonEventID = MPE.CommonEventID 
INNER JOIN [LogRhythmEMDB].[dbo].[MPERuleToPolicy] MPERuleToPolicy ON MPE.MPERuleID = MPERuleToPolicy.MPERuleID
INNER JOIN [LogRhythmEMDB].[dbo].[MPEPolicy] MPEPolicy ON MPERuleToPolicy.MPEPolicyID = MPEPolicy.MPEPolicyID
INNER JOIN [LogRhythmEMDB].[dbo].[MsgSourceType] MSGSourceType ON MPEPolicy.MsgSourceTypeID = MSGSourceType.MsgSourceTypeID
INNER JOIN [LogRhythmEMDB].[dbo].[MPERuleRegex] MPERegex ON MPE.MPERuleRegexID = MPERegex.MPERuleRegexID
WHERE MSGSourceType.FullName like @LogSourceName
GROUP BY MSGSourceType.FullName, Classification.[FullName], Classification.[Name]
ORDER BY MSGSourceType.FullName, Classification.FullName ASC'"
    #$sql1
    $Params1 = "N'@LogSourceName VARCHAR(100)'"
    $Query1 = "EXECUTE sp_executesql @stmt = $sql1, @params = $Params1, @LogSourceName = $LogSourceName;"

    Invoke-Sqlcmd -ServerInstance '.' -Database 'LogRhythmEMDB' -Query $Query1
}


function Select-ParameterizedSQLPS2
{
    [cmdletbinding()]
    param (
        [string]$Classification

    )
    #Push-Location; Import-Module SQLPS -DisableNameChecking; Pop-Location
    $sql2 = "N'SELECT * FROM [LogRhythmEMDB].[dbo].[aie] WHERE [@Classification] = 1'"
    #
    $Params2 = "N'@Classification VARCHAR(100)'"
    $Query2 = "EXECUTE sp_executesql @stmt = $sql2, @params = $Params2, @Classification = $Classification;"
    write-host $Query2
    Write-host $sql2
    Invoke-Sqlcmd -ServerInstance '.' -Database 'LogRhythmEMDB' -Query $Query2
}

try{
    $host.UI.RawUI.BufferSize = New-Object System.Management.Automation.Host.Size(2000,100)
    #Clear-Host
    $results1 = Select-ParameterizedSQLPS -LogSourceName "'%$LogSourceName%'"

    if($results1){

        write-output "-------------------------------------------------------"        
        write-output "$LogSourceName *may* trigger the following AIE rules:"
        write-output "-------------------------------------------------------"
        write-output $results1.ClassificationType #| Out-Default
        write-output "-------------------------------------------------------"

        foreach($result1 in $results1){
            
<#
            $results2 = Select-ParameterizedSQLPS2 -Classification "C_$Test1"
            write-host $results2
#>
            $sqlServer = "."

            $a = $result1.ClassificationName

            $sqlQuery = @"
            SELECT
            No, AlarmRule, RuleGroup, RBP, '$a' AS Classification
            FROM [LogRhythmEMDB].[dbo].[aie] WHERE [C_$a] = 1 AND RuleGroup like '%$RuleGroup%' AND RBP >= $RBP AND AlarmRule like '%$AlarmRuleName%'
"@

            $ds = Invoke-Sqlcmd -Query $sqlQuery -ServerInstance $sqlServer 
            
            $ds | ft 
#>

        }


    }else{
        write-output "No Results:`n"
        write-output "Somehow, someway, you managed to break this, and no results were found :\`n"
    }

}catch {
        Write-Output "Well, this is awkward...`n"
        Write-Output "Exception: $_.Exception.  Well, this is awkward... :(`n"
}