## ToDO ##
## Convert runtime to seconds, divide total matches/no matches by runtime, to get MPS
# Compare that MPS to run time

param(
  [Parameter(Mandatory=$false)]
  [string]$lpsfile = "",
  [Parameter(Mandatory=$false)]     #enable debug statements via console (for troubleshooting)
  [int]$debugmode = 0,
  [Parameter(Mandatory=$false)]
  [int]$lpsRuleMatchTotal = 1000,
  [Parameter(Mandatory=$false)]
  [int]$lpsRuleNoMatchTotal = 1000,
  [Parameter(Mandatory=$false)]
  [string]$outfile,
  [switch]$average,
  [switch]$help
)

Function validateFilePath {

       if (Test-Path $default_c) {$file_path = $default_c}
       elseif (Test-Path $default_d) {$file_path = $default_d}
       else {
             $file_path = Get-FileName "C:fso"
       }
       return $file_path
}

Function Get-FileName($initialDirectory)
{   
 [System.Reflection.Assembly]::LoadWithPartialName("System.windows.forms") |
Out-Null

$OpenFileDialog = New-Object System.Windows.Forms.OpenFileDialog
$OpenFileDialog.initialDirectory = $initialDirectory
$OpenFileDialog.filter = "lps_details (lps_details.log)| *.log"
$OpenFileDialog.ShowDialog() | Out-Null
$OpenFileDialog.filename
} 


if($debugmode -eq 1){
    $DebugPreference = "Continue"
}else{
    $DebugPreference = "SilentlyContinue"
}

# This script requires PowerShell 3.0 or higher
if ($PSVersionTable.PSVersion -lt [Version]"3.0") {
  write-output "PowerShell version " $PSVersionTable.PSVersion "not supported.  This script requires PowerShell 3.0 or greater."
  exit
}

if ($lpsfile){
	if ($lpsfile -eq "browse") {$default_c = Get-FileName}
	else {$default_c = $lpsfile}
	}
else{
    $default_c = "C:\Program Files\LogRhythm\LogRhythm Mediator Server\logs\lps_detail.log"
    $default_d = "D:\Program Files\LogRhythm\LogRhythm Mediator Server\logs\lps_detail.log"
}


Function LogMetaData ($lines) {
<# 
[0] LogRhythm Log Processing Report
[1] Copyright 2013 LogRhythm, Inc.
[2] Statistics Compiled on 08.16.2017 11:34 
[3] LogRhythm Lic ID 1269111
[4] KB Version       7.1.402.4
[5] Mediator ID      1
[6] Mediator Version 7.2.5.8006
[7] Stat Collection Start 08.16.2017 08:42 
[8] Stat Collection End   08.16.2017 11:34 
#>

	if (-not $lines.Length -eq 7){return $null}
	
	$global:licenceID = $lines[3].Split('ID')[-1].Trim()
	$global:kbVersion = $lines[4].Split('version')[-1].Trim()
	$global:mediatorVersion = $lines[6].Split('version')[-1].Trim()
	$global:logStart = $lines[7].Split('Start').Trim()[-1]
	$global:logEnd = $lines[8].Split('End').Trim()[-1]
	$global:totalSeconds = $(New-TimeSpan -Start $logStart -End $logEnd).TotalSeconds
	$global:totalDays = [math]::Round($($(New-TimeSpan -Start $logStart -End $logEnd).TotalDays), 2)
	return
	}

Function LogSource($blob) {             
       $lst_blob_lines = $blob -split [environment]::NewLine
       $rule_object_list = @()
       $log_source_runtime_dict = @{}
       $header = $null
       $ls_name = $null
       $lst_average_match_mps = $null
       $lst_fastest_match_rule = $null
       $lst_slowest_match_rule = $null
       $lst_slowest_match_rule_name = $null
       $lst_average_no_match_mps = $null
       $lst_fastest_no_match_rule = $null
       $lst_slowest_no_match_rule = $null
       $lst_slowest_no_match_rule_name = $null
       $mpe_policy = $null
       $total_compares = $null
       $log_source_type = $null   
       $lps_policy_total = $null
	   
       
       Function parseBlob {
             # If we have a header object, shrink the array
             if ($lst_blob_lines -Contains 'LogRhythm Log Processing Report') {
					# This blob contains some decent information, which we can pull out and work with, to determine interesting metadata
					logMetaData $lst_blob_lines
                    return 
             }			 
			$rule_object_list = @()
			$mpe_policy = $lst_blob_lines[4].Split(':')[-1].Trim()
			$total_compares = $lst_blob_lines[5].Split(':')[-1].Trim().Replace(',', '').Replace("'", '')
			$log_source_type = $lst_blob_lines[3].Split(':')[-1].Trim()
			$lps_policy_total = $lst_blob_lines[6].Split(':')[-1].Trim()
			if ([int]$total_compares -gt 0) {
				$average_MPS_for_log_source = [math]::Round($([int]$total_compares / [int]$global:totalSeconds), 2)
			} else {$average_MPS_for_log_source = 0}
			# iterate through blob array
             foreach ($rule in $lst_blob_lines[8..$lst_blob_lines.Length]) {
                    # if the string is empty, or just spaces, move on
                    if (-not $rule -or $rule -match '^\s+$' -or $rule -match '^\s*-+') 							
                           {}
					else {
                    $ss = $rule -split '\s{2,}'
                    $rule_object_list += @{"logSourceType" = $log_source_type; "name" = $ss[0]; "ruleID" = $ss[16]; "attempts" = $ss[5].Trim().Replace(',', '').Replace("'", ''); "regexID" = $ss[17]; "sortOrder" = $ss[1];
															"totalMatch" = $ss[7]; "lpsRuleMatchTotal" = $ss[13].Replace(',', '').Replace("'", ''); "lpsRuleNoMatchTotal" = $ss[14].Replace(',', '').Replace("'", ''); 
															"totalMPS" = $average_MPS_for_log_source; "totalCompares" = $total_compares}
						}
					}			
             return $rule_object_list
       }
       
       Function calculateRuntime {

       $matchTotals = @{}
       $noMatchTotals = @{}
       
       # Get each rule's match and no-match stats. Add to hashtable
       foreach ($rule in $rule_object_list) {
             $matchTotals.Add($rule.name, $rule.lpsRuleMatchTotal)
             $noMatchTotals.Add($rule.name, $rule.lpsRuleNoMatchTotal)
       
       $m = $matchTotals.Length
       if ($m -eq 0 -or $m -eq 1) {
             $lst_fastest_match_rule = $matchTotals.Values
             $lst_slowest_match_rule = $noMatchTotals.Values
       

       } else {
             $total = 0
             foreach ($m in $matchTotals.Values) {
                    $total += $m
             }
                           
             $lst_fastest_match_rule = $matchTotals.Values | measure -Maximum
             # build array of non-zero noMatches
             $_temp = @()
             foreach ($i in $noMatchTotals.Values) {if ($i -gt 0) {$_temp += $i}}
             $lst_fastest_match_rule = $(if ($_temp) {$_temp | measure -Minimum} else {0})
       
       }
       
       $m = $noMatchTotals.Length
       if ($m -eq 0 -or $m -eq 1) {
             $lst_fastest_match_rule = $($matchTotals.GetEnumerator() | Select -first 1).Value
             $lst_slowest_match_rule = $($noMatchTotals.GetEnumerator() | Select -first 1).Value           
       

       } else {
             $total = 0
             foreach ($m in $matchTotals.Values) {
                    $total += $m
             }
                           
             $lst_fastest_match_rule = $matchTotals.Values | measure -Maximum
             # build array of non-zero noMatches
             $_temp = @()
             foreach ($i in $noMatchTotals.Values) {if ($i -gt 0) {$_temp += $i}}
             $lst_fastest_no_match_rule = $(if ($_temp) {$_temp | measure -Minimum} else {0})
       
             }
                    
             }      
       }
       return parseBlob
}

Function splitToLST ($fileObject){
       $fo = Get-Content $fileObject -Raw
       $fs = $fo -Split '(?=Base-rule)'
       return $fs
}


Function validateFileIntegrity ($fo) {	
	
	$occurrences = $(Select-String $fo -Pattern 'LogRhythm Log Processing Report').Length
	if ($occurrences -ne 1) {
		return $occurrences
	}
	return $null
}

function displayUsage {
	# Display script parameters, then bail
	cls
	write-host "`n`n`t---===LogRhythm lpsParser Usage===---`n" -f "cyan"
	write-host "-help" -f "Green" -nonewline; write-host "`t`t`t- Display this help message and exit" -f "yellow"
	write-host "-lpsfile" -f "Green" -nonewline; write-host "`t`t- Specify file to parse" -f "yellow"
	write-host "-debugmode" -f "Green" -nonewline; write-host "`t`t- Enable Debug Mode" -f "yellow"
	write-host "-lpsRuleMatchTotal" -f "Green" -nonewline; write-host "`t- Specify the minimum match MPS a rule must meet, before being considered 'poor'" -f "yellow"
	write-host "-lpsRuleNoMatchTotal" -f "Green" -nonewline; write-host "`t- Specify the minimum no-match MPS a rule must meet, before being considered 'poor'" -f "yellow"
	write-host "-outfile" -f "Green" -nonewline; write-host "`t`t- Specify file to which we should write our output. Otherwise writes to stdout" -f "yellow"
	write-host "-average" -f "Green" -nonewline; write-host "`t`t- Calculates the average runtime of the Log Source Type, and uses this as a baseline for performance comparison" -f "yellow"
	write-host "`nUsage:" 
	write-host ".\lpsParser.ps1 -average" -f "Cyan"
	write-host ".\lpsParser.ps1 -lpsRuleMatchTotal 500 -lpsRuleNoMatchTotal 1000" -f "Cyan"
	write-host ".\lpsParser.ps1 -average -outfile 'c:\temp\blah.txt' " -f "Cyan"
	write-host ".\lpsParser.ps1 -lpsfile 'c:\temp\lps_detail.log'`n`n" -f "Cyan"
	exit
}

function Main {     
	   #if -help switch is specified, display script usage and exit 
	   if ($help) {displayUsage}
       # Confirm either default location, or prompt
       $f = validateFilePath
	   # Ensure file contains precisely one occurrence of 
	   $g = validateFileIntegrity $f	   	   
	   if ($g -or $g -eq 0) {
			if ($g -eq 0) {
				Write-Host "File '$f' does not appear to be a valid lps_detail.log" -f "Red"
			} else {
				$l = $g
				Write-Host "lps_detail.log appears to contain $l concatonated reports. lpsParser supports one report, per file." -f "red"	
			}
			exit
	   }
	   
	   # if outfile is specified, make sure it's either a valid file, or we can write to it
	   if ($outfile) {
			if (-not $(Test-Path $outfile)) {
				try {
					echo $null >> $outfile
				} catch {
					Write-Host "Unable to craete file $outfile"
				}			
			}
	   }
	   
       # Split entire file to blobs
       $blobArray = SplitToLST $f
	   $logSourceObjectArray = @()
       # Loop through blobs, parse each to an object
       foreach ($blob in $blobArray) {
			$logSourceObjectArray += $(LogSource $blob)    
       }  	   	          
		write-host "`nLicence ID:`t`t  " 			-nonewline -f "Cyan"; Write-Host $licenceID -f "Green"
		write-host "Log Start:`t`t  "  				-nonewline -f "Cyan"; Write-Host $logStart -f "Green"
		write-host "Log End:`t`t  "  				-nonewline -f "Cyan"; Write-Host $logEnd -f "Green"
		write-host "Log Active:`t`t  " 				-nonewline -f "Cyan"; Write-Host "$totalSeconds Seconds   ($totalDays Days)" -f "Green"
		write-host "Mediator Version:`t  " 			-nonewline -f "Cyan"; Write-Host $mediatorVersion -f "Green"
		write-host "KnowledgeBase Version:`t  " 	-nonewline -f "Cyan"; Write-Host $kbVersion  -f "Green"					   
	   
       $len = $logSourceObjectArray.Length
       $counter = 0	   
	   foreach ($l in $logSourceObjectArray) {
			if ($average) {
				$testMatch = $l.totalMPS
				$testNoMatch = $l.totalMPS
				$banner = "`n***Rule Performing Below Source Average MPS***"
			} else {
				$testMatch = $lpsRuleMatchTotal
				$testNoMatch = $lpsRuleNoMatchTotal
				$banner = "`n***Rule Performing Below Designated Thresholds (Match: $lpsRuleMatchTotal || No Match: $lpsRuleNoMatchTotal)***"			
			}
			if ($l -and ([int]$l.lpsRuleMatchTotal -gt 0 -and [int]$l.lpsRuleMatchTotal -lt $testMatch) -or ([int]$l.lpsRuleNoMatchTotal -gt 0 -and [int]$l.lpsRuleNoMatchTotal -lt $testNoMatch)){
				if (-not $outfile) {            
                    Write-Host $banner -f "Red"
                    Write-Host "Log Source Type: "  -nonewline -f "yellow" ; Write-Host  $l.logSourceType
                    Write-Host "Total Compares:  "  -nonewline -f "yellow" ; Write-Host  $l.totalCompares
					Write-Host "Rule Name:`t "      -nonewline -f "yellow" ; Write-Host  $l.name
                    Write-Host "Rule ID:`t "        -nonewline -f "yellow" ; Write-Host  $l.ruleID
                    Write-Host "Rule Attempts:   "  -nonewline -f "yellow" ; Write-Host  $l.attempts
					Write-Host "Log Source MPS:`t " -nonewline -f "yellow" ; Write-Host  $l.totalMPS                    
                    Write-Host "Match MPS:`t "      -nonewline -f "yellow" ; Write-Host  $l.lpsRuleMatchTotal
                    Write-Host "No-Match MPS:`t "   -nonewline -f "yellow" ; Write-Host  $l.lpsRuleNoMatchTotal
					$counter += 1
                    }            
				else {
					'{{"Action":"Poorly Performing Rule","Log Source Type":"{0}","Total Compares":"{1}""Rule Name":"{2}""Rule ID":"{3}""Rule Attempts":"{4}""Log Source MPS":"{5}""Match MPS":"{6}""No-Match MPS":"{7}"}}' -f $l.logSourceType, $l.totalCompares, $l.name, $l.ruleID, $l.attempts, $l.totalMPS, $l.lpsRuleMatchTotal, $l.lpsRuleNoMatchTotal | Out-file $outfile
					$counter += 1
				}
             }
       }
		if (-not $outfile) {
			if ($counter -eq 0) {Write-Host "Found $counter poorly performing rules." -f "Green"}
			else {
            if ($counter -eq 1) {$r = "rule"} else {$r = "rules"}
				Write-Host "`nFound $counter poorly performing $r.`n`n" -f "Red"
			 }
       }else{
			if ($counter -eq 0) {"Found $counter poorly performing rules." | Out-File $outfile}
			else {
            if ($counter -eq 1) {$r = "rule"} else {$r = "rules"}
				Write-Host "Found $counter poorly performing $r."  | Out-File $outfile
				
			 }
	   }
	}

try { 
    Main
       }
catch [System.Management.Automation.RuntimeException]
{
	if ($debug){write-host $_}
    # capture int division errors   
}
catch {
    write-host $_
} 
