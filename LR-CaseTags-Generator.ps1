
#Mitre Attack Matrix
$_Types = @(
"Persistence",
"Privilege Escalation",
"Credential Access",
"Discovery",
"Lateral Movement",
"Execution",
"Collection",
"Exfiltration",
"C2"
)

$_ClassificationTypes = @(
"Audit",
"Operations",
"Security"
)

$_Classifications = @(
"Authentication Success",
"Authentication Failure",
"Access Success",
"Access Failure",
"Account Created",
"Account Deleted",
"Other Audit Success",
"Account Modified",
"Access Granted",
"Access Revoked",
"Startup and Shutdown",
"Policy",
"Configuration",
"Other Audit Failure",
"Other",
"Reconnaissance",
"Suspicious",
"Misuse",
"Attack",
"Malware",
"Denial of Service",
"Compromise",
"Vulnerability",
"Failed Attack",
"Failed Denial of Service",
"Failed Malware",
"Failed Suspicious",
"Failed Misuse",
"Failed Activity",
"Activity",
"Other",
"Critical",
"Error",
"Warning",
"Information",
"Network Allow",
"Network Deny",
"Network Traffic",
"Other"
)

$PersonID = -100
$RecordStatus = 1
$now = get-date -format s

try  

{  
    # ************************************
    # ******** Mitre Attack Types ********
    # ************************************
    foreach($type in $_Types){
        $a = "(N'_T:{0}',{1},{2},N'{3}')," -f $type, $PersonID, $RecordStatus, $now
        $b += $a
    }

    #Last VALUES group for insert will have trailing comma which we need strip off
    write-output "/* INSERT Mitre Case Types */"
    write-output "INSERT INTO [LogRhythm_CMDB].[dbo].[Tag] VALUES $($b.Substring(0,$b.Length-1))"
    write-output "`n"

    # *************************************
    # ***** LogRhythm Classifications *****
    # *************************************
    foreach($classification in $_Classifications){
        $c = "(N'_c:{0}',{1},{2},N'{3}')," -f $classification, $PersonID, $RecordStatus, $now
        $d += $c
    }

    #Last VALUES group for insert will have trailing comma which we need strip off
    write-output "/* INSERT LogRhythm Classifications */"
    write-output "INSERT INTO [LogRhythm_CMDB].[dbo].[Tag] VALUES $($d.Substring(0,$d.Length-1))"
    write-output "`n"

    # ******************************************
    # ***** LogRhythm Classification Types *****
    # ******************************************
    foreach($classificationType in $_ClassificationTypes){
        $e = "(N'_ct:{0}',{1},{2},N'{3}')," -f $classificationType, $PersonID, $RecordStatus, $now
        $f += $e
    }

    #Last VALUES group for insert will have trailing comma which we need strip off
    write-output "/* INSERT LogRhythm Classification Types */"
    write-output "INSERT INTO [LogRhythm_CMDB].[dbo].[Tag] VALUES $($f.Substring(0,$f.Length-1))"
    write-output "`n"


    <#
    #The above output has deliberately not been automated, but if you wanted to do so the below is a good starting point.
    #Switch the write-output statements above into your sqlQuery and go from there

    $sqlServer = "."

    $sqlQuery = @"
      INSERT INTO [LogRhythm_CMDB].[dbo].[Tag] VALUES $($b.Substring(0,$b.Length-0))
    "@

    $ds = Invoke-Sqlcmd -Query $sqlQuery -ServerInstance $sqlServer 
    #>

}
    catch [System.SystemException] {
    $_ 
}


#Todo - should have the above a function, and passed the array to that function, but quick and dirty is as quick and dirty does!