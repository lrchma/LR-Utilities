<#                                                                                                                                                                            .NAME
LR-AIE-RecipeSelector

.SYNOPSIS
Determine LogRhythm supported Log Sources that can fire off LogRhythm AI Engine Alarms and Events

.DESCRIPTION
Used to find matches for a given or partial match of a log source name, and print results in CSV format.

There are two input files require for this to work, and in the following format:

1) AIE Rule Export.  To generate the AIE CSV Export use the following script:
https://github.com/lrchma/LR-Utilities/blob/master/AIE-RulesJSON/9-LR-AIE-CSV-Export.ps1

2) MDI Export.  To generate the MDI export run the below SQL query and save to CSV.

SELECT
MSGSourceType.FullName AS LogSource,
Classification.[FullName] AS ClassificationType,
Classification.[Name] AS ClassificationName,
CommonEvent.[Name] AS CommonEvent 
FROM [LogRhythmEMDB].[dbo].[MsgClass] Classification
INNER JOIN [LogRhythmEMDB].[dbo].[CommonEvent] COMMONEVENT ON Classification.MsgClassID = COMMONEVENT.MsgClassID
INNER JOIN [LogRhythmEMDB].[dbo].[MPERule] MPE ON COMMONEVENT.CommonEventID = MPE.CommonEventID 
INNER JOIN [LogRhythmEMDB].[dbo].[MPERuleToPolicy] MPERuleToPolicy ON MPE.MPERuleID = MPERuleToPolicy.MPERuleID
INNER JOIN [LogRhythmEMDB].[dbo].[MPEPolicy] MPEPolicy ON MPERuleToPolicy.MPEPolicyID = MPEPolicy.MPEPolicyID
INNER JOIN [LogRhythmEMDB].[dbo].[MsgSourceType] MSGSourceType ON MPEPolicy.MsgSourceTypeID = MSGSourceType.MsgSourceTypeID
INNER JOIN [LogRhythmEMDB].[dbo].[MPERuleRegex] MPERegex ON MPE.MPERuleRegexID = MPERegex.MPERuleRegexID
--WHERE MSGSourceType.FullName like @LogSourceName
GROUP BY MSGSourceType.FullName, Classification.[FullName], Classification.[Name], CommonEvent.[Name]
ORDER BY MSGSourceType.FullName, Classification.FullName ASC


.EXAMPLE
./LR-AIE-RecipeSelector -LogSource "AWS" -debugMode "false" -aieInputFile "aie.csv" -mdiInputFile "LogSource2MDI.csv"

.PARAMETER
-LogSource = Log Source Name.  Supports partial matches.
-DebugMode = For troubleshooting.  Enables write-debug output.  This slows down script execution.

.NOTES
March 2018 @chrismartin

.LINK
https://github.com/lrchma/

#>

param(
  [Parameter(Mandatory=$true)]
  [string]$debugMode = "false",

  [Parameter(Mandatory=$false)]
  [string]$aieInputFile = "aie.csv",

  [Parameter(Mandatory=$false)]
  [string]$mdiInputFile = "LogSource2MDI_2.csv"
)


if($debugMode -eq "true"){
    $DebugPreference = "Continue" 
}

$kbVersion = "7.1.434.1"


Write-Debug "$(get-date) Init"
Write-Debug "$(get-date) KB Version used for export: $kbVersion"
Write-Debug "$(get-date) debugMode = $debugMode"

Write-Debug "$(get-date) Importing AIE Rules"
$csvAie = import-csv "C:\Users\Administrator\Documents\WindowsPowerShell\aie.csv"

Write-Debug "$(get-date) Importing MDI Mapping"
$csvMdi = import-csv "C:\Users\Administrator\Documents\WindowsPowerShell\LogSource2MDI_2.csv"


write-output "LogSource,Classification,AIERuleID,AIERuleName,AIERuleGroup,AIERuleBlockNo"

Write-Debug "$(get-date) Eval Matched Log Sources MDI to AIE Rules"
     
    #Store unique matching Classifications per log source
    $matchingClassifications = @()

    foreach($logSourceType in $csvMdi){
        $matchedLogSource = $logSourceType.LogSource

        foreach ($classification in $csvMdi | Where-Object {$_.LogSource -eq $matchedLogSource})
        {
                foreach($aierule in $csvAie){
                    
                    switch($classification.ClassificationName){
                        "Authentication Success"{if($aierule.'Authentication Success' -eq 1){"{0}, {1}, {2}, {3}, {4}, {5}, {5}" -f $matchedLogSource, $classification.ClassificationName, $aierule.no, $aierule.AlarmRule, $aierule.AlarmKB, $aierule.rb_blockid}}
                        "Authentication Failure"{if($aierule.'Authentication Failure' -eq 1){"{0}, {1}, {2}, {3}, {4}, {5}, {5}" -f $matchedLogSource, $classification.ClassificationName, $aierule.no, $aierule.AlarmRule, $aierule.AlarmKB, $aierule.rb_blockid}}
                        "Access Success"{if($aierule.'Access Success' -eq 1){"{0}, {1}, {2}, {3}, {4}, {5}, {5}" -f $matchedLogSource, $classification.ClassificationName, $aierule.no, $aierule.AlarmRule, $aierule.AlarmKB, $aierule.rb_blockid}}
                        "Access Failure"{if($aierule.'Access Failure' -eq 1){"{0}, {1}, {2}, {3}, {4}, {5}, {5}" -f $matchedLogSource, $classification.ClassificationName, $aierule.no, $aierule.AlarmRule, $aierule.AlarmKB, $aierule.rb_blockid}}
                        "Account Created"{if($aierule.'Account Created' -eq 1){"{0}, {1}, {2}, {3}, {4}, {5}" -f $matchedLogSource, $classification.ClassificationName, $aierule.no, $aierule.AlarmRule, $aierule.AlarmKB, $aierule.rb_blockid}}
                        "Account Deleted"{if($aierule.'Account Deleted' -eq 1){"{0}, {1}, {2}, {3}, {4}, {5}" -f $matchedLogSource, $classification.ClassificationName, $aierule.no, $aierule.AlarmRule, $aierule.AlarmKB, $aierule.rb_blockid}}
                        "Other Audit Success"{if($aierule.'Other Audit Success' -eq 1){"{0}, {1}, {2}, {3}, {4}, {5}" -f $matchedLogSource, $classification.ClassificationName, $aierule.no, $aierule.AlarmRule, $aierule.AlarmKB, $aierule.rb_blockid}}
                        "Account Modified"{if($aierule.'Account Modified' -eq 1){"{0}, {1}, {2}, {3}, {4}, {5}" -f $matchedLogSource, $classification.ClassificationName, $aierule.no, $aierule.AlarmRule, $aierule.AlarmKB, $aierule.rb_blockid}}
                        "Access Granted"{if($aierule.'Access Granted' -eq 1){"{0}, {1}, {2}, {3}, {4}, {5}" -f $matchedLogSource, $classification.ClassificationName, $aierule.no, $aierule.AlarmRule, $aierule.AlarmKB, $aierule.rb_blockid}}
                        "Access Revoked"{if($aierule.'Access Revoked' -eq 1){"{0}, {1}, {2}, {3}, {4}, {5}" -f $matchedLogSource, $classification.ClassificationName, $aierule.no, $aierule.AlarmRule, $aierule.AlarmKB, $aierule.rb_blockid}}
                        "Startup and Shutdown"{if($aierule.'Startup and Shutdown' -eq 1){"{0}, {1}, {2}, {3}, {4}, {5}" -f $matchedLogSource, $classification.ClassificationName, $aierule.no, $aierule.AlarmRule, $aierule.AlarmKB, $aierule.rb_blockid}}
                        "Policy"{if($aierule.'Policy' -eq 1){"{0}, {1}, {2}, {3}, {4}, {5}" -f $matchedLogSource, $classification.ClassificationName, $aierule.no, $aierule.AlarmRule, $aierule.AlarmKB, $aierule.rb_blockid}}
                        "Configuration"{if($aierule.'Configuration' -eq 1){"{0}, {1}, {2}, {3}, {4}, {5}" -f $matchedLogSource, $classification.ClassificationName, $aierule.no, $aierule.AlarmRule, $aierule.AlarmKB, $aierule.rb_blockid}}
                        "Other Audit Failure"{if($aierule.'Other Audit Failure' -eq 1){"{0}, {1}, {2}, {3}, {4}, {5}" -f $matchedLogSource, $classification.ClassificationName, $aierule.no, $aierule.AlarmRule, $aierule.AlarmKB, $aierule.rb_blockid}}
                        "Other Audit"{if($aierule.'Other Audit' -eq 1){"{0}, {1}, {2}, {3}, {4}, {5}" -f $matchedLogSource, $classification.ClassificationName, $aierule.no, $aierule.AlarmRule, $aierule.AlarmKB, $aierule.rb_blockid}}
                        "Reconnaissance"{if($aierule.'Reconnaissance' -eq 1){"{0}, {1}, {2}, {3}, {4}, {5}" -f $matchedLogSource, $classification.ClassificationName, $aierule.no, $aierule.AlarmRule, $aierule.AlarmKB, $aierule.rb_blockid}}
                        "Suspicious"{if($aierule.'Suspicious' -eq 1){"{0}, {1}, {2}, {3}, {4}, {5}" -f $matchedLogSource, $classification.ClassificationName, $aierule.no, $aierule.AlarmRule, $aierule.AlarmKB, $aierule.rb_blockid}}
                        "Misuse"{if($aierule.'Misuse' -eq 1){"{0}, {1}, {2}, {3}, {4}, {5}" -f $matchedLogSource, $classification.ClassificationName, $aierule.no, $aierule.AlarmRule, $aierule.AlarmKB, $aierule.rb_blockid}}
                        "Attack"{if($aierule.'Attack' -eq 1){"{0}, {1}, {2}, {3}, {4}, {5}" -f $matchedLogSource, $classification.ClassificationName, $aierule.no, $aierule.AlarmRule, $aierule.AlarmKB, $aierule.rb_blockid}}
                        "Malware"{if($aierule.'Malware' -eq 1){"{0}, {1}, {2}, {3}, {4}, {5}" -f $matchedLogSource, $classification.ClassificationName, $aierule.no, $aierule.AlarmRule, $aierule.AlarmKB, $aierule.rb_blockid}}
                        "Denial Of Service"{if($aierule.'Denial Of Service' -eq 1){"{0}, {1}, {2}, {3}, {4}, {5}" -f $matchedLogSource, $classification.ClassificationName, $aierule.no, $aierule.AlarmRule, $aierule.AlarmKB, $aierule.rb_blockid}}
                        "Compromise"{if($aierule.'Compromise' -eq 1){"{0}, {1}, {2}, {3}, {4}, {5}" -f $matchedLogSource, $classification.ClassificationName, $aierule.no, $aierule.AlarmRule, $aierule.AlarmKB, $aierule.rb_blockid}}
                        "Vulnerability"{if($aierule.'Vulnerability' -eq 1){"{0}, {1}, {2}, {3}, {4}, {5}" -f $matchedLogSource, $classification.ClassificationName, $aierule.no, $aierule.AlarmRule, $aierule.AlarmKB, $aierule.rb_blockid}}
                        "Failed Attack"{if($aierule.'Failed Attack' -eq 1){"{0}, {1}, {2}, {3}, {4}, {5}" -f $matchedLogSource, $classification.ClassificationName, $aierule.no, $aierule.AlarmRule, $aierule.AlarmKB, $aierule.rb_blockid}}
                        "Failed Denial of Service"{if($aierule.'Failed Denial of Service' -eq 1){"{0}, {1}, {2}, {3}, {4}, {5}" -f $matchedLogSource, $classification.ClassificationName, $aierule.no, $aierule.AlarmRule, $aierule.AlarmKB, $aierule.rb_blockid}}
                        "Failed Malware"{if($aierule.'Failed Malware' -eq 1){"{0}, {1}, {2}, {3}, {4}, {5}" -f $matchedLogSource, $classification.ClassificationName, $aierule.no, $aierule.AlarmRule, $aierule.AlarmKB, $aierule.rb_blockid}}
                        "Failed Suspicious"{if($aierule.'Failed Suspicious' -eq 1){"{0}, {1}, {2}, {3}, {4}, {5}" -f $matchedLogSource, $classification.ClassificationName, $aierule.no, $aierule.AlarmRule, $aierule.AlarmKB, $aierule.rb_blockid}}
                        "Failed Misuse"{if($aierule.'Failed Misuse' -eq 1){"{0}, {1}, {2}, {3}, {4}, {5}" -f $matchedLogSource, $classification.ClassificationName, $aierule.no, $aierule.AlarmRule, $aierule.AlarmKB, $aierule.rb_blockid}}
                        "Failed Activity"{if($aierule.'Failed Activity' -eq 1){"{0}, {1}, {2}, {3}, {4}, {5}" -f $matchedLogSource, $classification.ClassificationName, $aierule.no, $aierule.AlarmRule, $aierule.AlarmKB, $aierule.rb_blockid}}
                        "Activity"{if($aierule.'Activity' -eq 1){"{0}, {1}, {2}, {3}, {4}, {5}" -f $matchedLogSource, $classification.ClassificationName, $aierule.no, $aierule.AlarmRule, $aierule.AlarmKB, $aierule.rb_blockid}}
                        "Other Security"{if($aierule.'Other Security' -eq 1){"{0}, {1}, {2}, {3}, {4}, {5}" -f $matchedLogSource, $classification.ClassificationName, $aierule.no, $aierule.AlarmRule, $aierule.AlarmKB, $aierule.rb_blockid}}
                        "Critical"{if($aierule.'Critical' -eq 1){"{0}, {1}, {2}, {3}, {4}, {5}" -f $matchedLogSource, $classification.ClassificationName, $aierule.no, $aierule.AlarmRule, $aierule.AlarmKB, $aierule.rb_blockid}}
                        "Error"{if($aierule.'Error' -eq 1){"{0}, {1}, {2}, {3}, {4}, {5}" -f $matchedLogSource, $classification.ClassificationName, $aierule.no, $aierule.AlarmRule, $aierule.AlarmKB, $aierule.rb_blockid}}
                        "Warning"{if($aierule.'Warning' -eq 1){"{0}, {1}, {2}, {3}, {4}, {5}" -f $matchedLogSource, $classification.ClassificationName, $aierule.no, $aierule.AlarmRule, $aierule.AlarmKB, $aierule.rb_blockid}}
                        "Information"{if($aierule.'Information' -eq 1){"{0}, {1}, {2}, {3}, {4}, {5}" -f $matchedLogSource, $classification.ClassificationName, $aierule.no, $aierule.AlarmRule, $aierule.AlarmKB, $aierule.rb_blockid}}
                        "Network Allow"{if($aierule.'Network Allow' -eq 1){"{0}, {1}, {2}, {3}, {4}, {5}" -f $matchedLogSource, $classification.ClassificationName, $aierule.no, $aierule.AlarmRule, $aierule.AlarmKB, $aierule.rb_blockid}}
                        "Network Deny"{if($aierule.'Network Deny' -eq 1){"{0}, {1}, {2}, {3}, {4}, {5}" -f $matchedLogSource, $classification.ClassificationName, $aierule.no, $aierule.AlarmRule, $aierule.AlarmKB, $aierule.rb_blockid}}
                        "Network Traffic"{if($aierule.'Network Traffic' -eq 1){"{0}, {1}, {2}, {3}, {4}, {5}" -f $matchedLogSource, $classification.ClassificationName, $aierule.no, $aierule.AlarmRule, $aierule.AlarmKB, $aierule.rb_blockid}}
                        "Other Operations"{if($aierule.'Other Operations' -eq 1){"{0}, {1}, {2}, {3}, {4}, {5}" -f $matchedLogSource, $classification.ClassificationName, $aierule.no, $aierule.AlarmRule, $aierule.AlarmKB, $aierule.rb_blockid}}
                    } 
                } 
            } 
        }
    
    
