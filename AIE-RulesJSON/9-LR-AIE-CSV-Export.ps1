<#                                                                                                                                                                            .NAME
LR-AIE-CSV Export

.SYNOPSIS
The following script contains coarse code and due to its content should not be viewed by anyone, ever.  But if you must, read on...

.DESCRIPTION
Script utilises the LogRhythm Host API.  This is not an officially supported public API, but rather an intenal only API at this time.  In order to call the API you'll need run it from the WebUI server, and already be logged into the WebUI.  No response most likley means you're not logged in, or else on the wrong host, and definetely means I didn't add error handling.  

.EXAMPLE
./LR-AIE-CSV-Export -userid 1 -aiestartruleno 1 -aiestopruleno 1400

.PARAMETER
-userid = user you're logged into WebUI as
-aiestartruleno = the first AIE rule ID to start parsing
-aiestartruleno = the last AIE rule ID to start parsing

.NOTES
Nov 2017 @chrismartin

.LINK
https://github.com/lrchma/

#>

param(
  [Parameter(Mandatory=$false)]
  [int]$userId = 1,
  [Parameter(Mandatory=$false)]
  [long]$aieStartRuleNo = 1,
  [Parameter(Mandatory=$false)]
  [long]$aieStopRuleNo = 1500#00000000
)

#Simple Risk calculation based on the default risk and false positive levels.  
#Does not account for variables like entity or host values
function CalcRBP($risk,$fpp){

    switch($risk){
        1 { $b = 37 }
        2 { $b = 44 }
        3 { $b = 52 }
        4 { $b = 60 }
        5 { $b = 68 }
        6 { $b = 76 }
        7 { $b = 84 }
        8 { $b = 92 }
        9 { $b = 100 }
    }

    switch($fpp){
        'None' { $a = 0 }
        'LowLow' { $a = 3 }
        'LowMedium' { $a = 6 }
        'LowHigh' { $a = 9 }
        'MediumLow' { $a = 1 }
        'MediumMedium' { $a = 15 }
        'MediumHigh' { $a = 18 }
        'HighLow' { $a = 21 }
        'HighMedium' { $a = 24 }
        'HighHigh' { $a = 27 }
    }

$result = $b - $a
return "$result"
}


$FileName = "aie.csv"
if (Test-Path $FileName) 
{
  Remove-Item $FileName
}

#CSV Headers
$headers = "No,AlarmRule,Enabled,AlarmKB,RuleGroup,Supression,EventForwarding,RiskRating,FPP,RBP,RB_BlockID,RB_Type,RB_DataSource,Access Failure,Access Granted,Access Revoked,Access Success,Account Created,Account Deleted,Account Modified,Activity,Attack,Authentication Failure,Authentication Success,Compromise,Configuration,Critical,Denial Of Service,Error,Failed Activity,Failed Attack,Failed Denial of Service,Failed Malware,Failed Misuse,Failed Suspicious,Information,Malware,Misuse,Network Allow,Network Deny,Network Traffic,Other Audit,Other Audit Failure,Other Audit Success,Other Operations,Other Security,Policy,Reconnaissance,Startup and Shutdown,Suspicious,Vulnerability,Warning,RB_CE1,RB_CE2,RB_CE3,RB_CE4,RB_CE5,RB_CE6,RB_CE7,RB_CE8,RB_CE9,RB_CE10,RB_MPE1,RB_MPE2,RB_MPE3,RB_MPE4,RB_MPE5,RB_MPE6,RB_MPE7,RB_MPE8,RB_MPE9,RB_MPE10,GB_Account,GB_Action,GB_Command,GB_CE,GB_CVE,GB_DEntity,GB_Destination,GB_DHostName,GB_DInterface,GB_DIP,GB_Direction,GB_DLocationCity,GB_DLocationRegion,GB_DMAC,GB_DNATIP,GB_DNATPort,GB_DNetwork,GB_Domain,GB_DomainOrigin,GB_DPort,GB_DZone,GB_Entity,GB_Group,GB_Hash,GB_KnownDHost,GB_KnownService,GB_KnownSHost,GB_Login,GB_MPERule,GB_MsgClass,GB_MsgSource,GB_MsgSourceHost,GB_Object,GB_ObjectName,GB_ObjectType,GB_ParentProcessId,GB_ParentProcessName,GB_ParentProcessPath,GB_PID,GB_Policy,GB_Process,GB_Protocol,GB_Reason,GB_Recipient,GB_RecipientIdentityID,GB_ResponseCode,GB_Result,GB_RootEntity,GB_Sender,GB_SenderIdentityID,GB_SEntity,GB_SerialNumber,GB_Service,GB_Session,GB_SessionType,GB_Severity,GB_SHostName,GB_SInterface,GB_SIP,GB_SLocationCity,GB_SLocationRegion,GB_SMAC,GB_SNATIP,GB_SNATPort,GB_SNetwork,GB_Source,GB_SPort,GB_Status,GB_Subject,GB_SZone,GB_ThreatId,GB_ThreatName,GB_URL,GB_UserAgent,GB_UserImpactedIdentityID,GB_UserOriginIdentityID,GB_VendorInfo,GB_VendorMessageID,GB_Version" 
add-content aie.csv $headers

#Main
for($i=$aieStartRuleNo; $i -le $aieStopRuleNo; $i++)
{
    try {
        $rs = Invoke-WebRequest -Uri http://127.0.0.1:8505/lr-services-host-api/actions/domainobject -ContentType "application/json" -Method POST -Body "{source : '',destination : 'DomainObjectService',messageType : 'GetObjectRequest',ver: 1, data: {objectType : 'AieRule', userId : 1, objectId : $i,}, }"
        $psObject = $rs.content | ConvertFrom-JSON
        
        #AIE Rule Settings
        foreach($object in $psObject){
            $aa = "{0},`"{1}`",{2},`"{3}`",{4},{5},{6},{7},{8},{9}," -f $object.id, `
                                                    ($object.alarmRule.name -replace "(^AIE: |,)", "") , ` #replace any commas in the Alarm Rule name
                                                    $object.alarmRule.enabled, `
                                                    (($object.alarmRule.name -replace "(^AIE: |,)", "") | %{ $_ -replace ":(?=\s).*$"}), `   #generate AIE group names
                                                    $object.ruleGroup, `
                                                    ($object.supression -replace ".{3}$"), ` #truncate the extra three zeros on the suppresion
                                                    $object.eventForwardingEnabled, `
                                                    $object.commonEvent.riskRating, `
                                                    $object.falsePositiveProbability.id,
                                                    (CalcRBP $object.commonEvent.riskRating $object.falsePositiveProbability.name)
                                                    

            #AIE Rule Block Settings
            foreach($block in $object.blocks){
             $bb = "{0},{1},{2}," -f $block.id, $block.blockType.name, $block.datasource
                    
                    $classification = [ordered]@{
                        "Access Failure"=0;
                        "Access Granted"=0;
                        "Access Revoked"=0;
                        "Access Success"=0;
                        "Account Created"=0;
                        "Account Deleted"=0;
                        "Account Modified"=0;
                        "Activity"=0;
                        "Attack"=0;
                        "Authentication Failure"=0;
                        "Authentication Success"=0;
                        "Compromise"=0;
                        "Configuration"=0;
                        "Critical"=0;
                        "Denial Of Service"=0;
                        "Error"=0;
                        "Failed Activity"=0;
                        "Failed Attack"=0;
                        "Failed Denial of Service"=0;
                        "Failed Malware"=0;
                        "Failed Misuse"=0;
                        "Failed Suspicious"=0;
                        "Information"=0;
                        "Malware"=0;
                        "Misuse"=0;
                        "Network Allow"=0;
                        "Network Deny"=0;
                        "Network Traffic"=0;
                        "Other Audit"=0;
                        "Other Audit Failure"=0;
                        "Other Audit Success"=0;
                        "Other Operations"=0;
                        "Other Security"=0;
                        "Policy"=0;
                        "Reconnaissance"=0;
                        "Startup and Shutdown"=0;
                        "Suspicious"=0;
                        "Vulnerability"=0;
                        "Warning"=0;
                    }


                     
                    #Primary Filter: Classifications (Type 10)
                    #Currently grabs first 10, there could be more!


                    #Primary Filter: Common Events (Type 11)
                    #Currently grabs first 10, there could be more!
                    $ee_ce = For ($ii=0; $ii -le 9; $ii++) {
                                if($block.primaryCriteria.fieldFilters.values[$ii].filterType -eq "11"){
                                   "{0}," -f ($block.primaryCriteria.fieldFilters.values[$ii].displayValue -replace ",", " ")
                                } else {
                                    ","
                                }
                    }

                    #Primary Filter: MPE Rule (Type 12)
                    #Currently grabs first 10, there could be more!
                    $ff_mpe = For ($ii=0; $ii -le 9; $ii++) {
                                if($block.primaryCriteria.fieldFilters.values[$ii].filterType -eq "12"){
                                   "{0}," -f ($block.primaryCriteria.fieldFilters.values[$ii].displayValue -replace ",", " ")
                                } else {
                                    ","
                                }
                    }

                    #Hash table to store group by fields used
                    #Note, these names do not match up to that in the GUI elsewhere in Logrhythm, but the CSV headers should match (ish)
                    $groupby = [ordered]@{
                        "Account"=0;
                        "Action"=0;
                        "Command"=0;
                        "CommonEvent"=0;
                        "CVE"=0;
                        "DEntity"=0;
                        "Destination"=0;
                        "DHostName"=0;
                        "DInterface"=0;
                        "DIP"=0;
                        "Direction"=0;
                        "DLocationCity"=0;
                        "DLocationRegion"=0;
                        "DMAC"=0;
                        "DNATIP"=0;
                        "DNATPort"=0;
                        "DNetwork"=0;
                        "Domain"=0;
                        "DomainOrigin"=0;
                        "DPort"=0;
                        "DZone"=0;
                        "Entity"=0;
                        "Group"=0;
                        "Hash"=0;
                        "KnownDHost"=0;
                        "KnownService"=0;
                        "KnownSHost"=0;
                        "Login"=0;
                        "MPERule"=0;
                        "MsgClass"=0;
                        "MsgSource"=0;
                        "MsgSourceHost"=0;
                        "Object"=0;
                        "ObjectName"=0;
                        "ObjectType"=0;
                        "ParentProcessId"=0;
                        "ParentProcessName"=0;
                        "ParentProcessPath"=0;
                        "PID"=0;
                        "Policy"=0;
                        "Process"=0;
                        "Protocol"=0;
                        "Reason"=0;
                        "Recipient"=0;
                        "RecipientIdentityID"=0;
                        "ResponseCode"=0;
                        "Result"=0;
                        "RootEntity"=0;
                        "Sender"=0;
                        "SenderIdentityID"=0;
                        "SEntity"=0;
                        "SerialNumber"=0;
                        "Service"=0;
                        "Session"=0;
                        "SessionType"=0;
                        "Severity"=0;
                        "SHostName"=0;
                        "SInterface"=0;
                        "SIP"=0;
                        "SLocationCity"=0;
                        "SLocationRegion"=0;
                        "SMAC"=0;
                        "SNATIP"=0;
                        "SNATPort"=0;
                        "SNetwork"=0;
                        "Source"=0;
                        "SPort"=0;
                        "Status"=0;
                        "Subject"=0;
                        "SZone"=0;
                        "ThreatId"=0;
                        "ThreatName"=0;
                        "URL"=0;
                        "UserAgent"=0;
                        "UserImpactedIdentityID"=0;
                        "UserOriginIdentityID"=0;
                        "VendorInfo"=0;
                        "VendorMessageID"=0;
                        "Version"=0;
                      }
                    
                    #loop through each group by field
                    For ($ii=0; $ii -le 78; $ii++) {

                        if($block.groupByFields[$ii].name -eq "Account"){$groupby["Account"] = 1}   
                        if($block.groupByFields[$ii].name -eq "Action"){$groupby["Action"] = 1}   
                        if($block.groupByFields[$ii].name -eq "Command"){$groupby["Command"] = 1}   
                        if($block.groupByFields[$ii].name -eq "CommonEvent"){$groupby["CommonEvent"] = 1}   
                        if($block.groupByFields[$ii].name -eq "CVE"){$groupby["CVE"] = 1}   
                        if($block.groupByFields[$ii].name -eq "DEntity"){$groupby["DEntity"] = 1}   
                        if($block.groupByFields[$ii].name -eq "Destination"){$groupby["Destination"] = 1}   
                        if($block.groupByFields[$ii].name -eq "DHostName"){$groupby["DHostName"] = 1}   
                        if($block.groupByFields[$ii].name -eq "DInterface"){$groupby["DInterface"] = 1}   
                        if($block.groupByFields[$ii].name -eq "DIP"){$groupby["DIP"] = 1}   
                        if($block.groupByFields[$ii].name -eq "Direction"){$groupby["Direction"] = 1}   
                        if($block.groupByFields[$ii].name -eq "DLocationCity"){$groupby["DLocationCity"] = 1}   
                        if($block.groupByFields[$ii].name -eq "DLocationRegion"){$groupby["DLocationRegion"] = 1}   
                        if($block.groupByFields[$ii].name -eq "DMAC"){$groupby["DMAC"] = 1}   
                        if($block.groupByFields[$ii].name -eq "DNATIP"){$groupby["DNATIP"] = 1}   
                        if($block.groupByFields[$ii].name -eq "DNATPort"){$groupby["DNATPort"] = 1}   
                        if($block.groupByFields[$ii].name -eq "DNetwork"){$groupby["DNetwork"] = 1}   
                        if($block.groupByFields[$ii].name -eq "Domain"){$groupby["Domain"] = 1}   
                        if($block.groupByFields[$ii].name -eq "DomainOrigin"){$groupby["DomainOrigin"] = 1}   
                        if($block.groupByFields[$ii].name -eq "DPort"){$groupby["DPort"] = 1}   
                        if($block.groupByFields[$ii].name -eq "DZone"){$groupby["DZone"] = 1}   
                        if($block.groupByFields[$ii].name -eq "Entity"){$groupby["Entity"] = 1}   
                        if($block.groupByFields[$ii].name -eq "Group"){$groupby["Group"] = 1}   
                        if($block.groupByFields[$ii].name -eq "Hash"){$groupby["Hash"] = 1}   
                        if($block.groupByFields[$ii].name -eq "KnownDHost"){$groupby["KnownDHost"] = 1}   
                        if($block.groupByFields[$ii].name -eq "KnownService"){$groupby["KnownService"] = 1}   
                        if($block.groupByFields[$ii].name -eq "KnownSHost"){$groupby["KnownSHost"] = 1}   
                        if($block.groupByFields[$ii].name -eq "Login"){$groupby["Login"] = 1}   
                        if($block.groupByFields[$ii].name -eq "MPERule"){$groupby["MPERule"] = 1}   
                        if($block.groupByFields[$ii].name -eq "MsgClass"){$groupby["MsgClass"] = 1}   
                        if($block.groupByFields[$ii].name -eq "MsgSource"){$groupby["MsgSource"] = 1}   
                        if($block.groupByFields[$ii].name -eq "MsgSourceHost"){$groupby["MsgSourceHost"] = 1}   
                        if($block.groupByFields[$ii].name -eq "Object"){$groupby["Object"] = 1}   
                        if($block.groupByFields[$ii].name -eq "ObjectName"){$groupby["ObjectName"] = 1}   
                        if($block.groupByFields[$ii].name -eq "ObjectType"){$groupby["ObjectType"] = 1}   
                        if($block.groupByFields[$ii].name -eq "ParentProcessId"){$groupby["ParentProcessId"] = 1}   
                        if($block.groupByFields[$ii].name -eq "ParentProcessName"){$groupby["ParentProcessName"] = 1}   
                        if($block.groupByFields[$ii].name -eq "ParentProcessPath"){$groupby["ParentProcessPath"] = 1}   
                        if($block.groupByFields[$ii].name -eq "PID"){$groupby["PID"] = 1}   
                        if($block.groupByFields[$ii].name -eq "Policy"){$groupby["Policy"] = 1}   
                        if($block.groupByFields[$ii].name -eq "Process"){$groupby["Process"] = 1}   
                        if($block.groupByFields[$ii].name -eq "Protocol"){$groupby["Protocol"] = 1}   
                        if($block.groupByFields[$ii].name -eq "Reason"){$groupby["Reason"] = 1}   
                        if($block.groupByFields[$ii].name -eq "Recipient"){$groupby["Recipient"] = 1}   
                        if($block.groupByFields[$ii].name -eq "RecipientIdentityID"){$groupby["RecipientIdentityID"] = 1}   
                        if($block.groupByFields[$ii].name -eq "ResponseCode"){$groupby["ResponseCode"] = 1}   
                        if($block.groupByFields[$ii].name -eq "Result"){$groupby["Result"] = 1}   
                        if($block.groupByFields[$ii].name -eq "RootEntity"){$groupby["RootEntity"] = 1}   
                        if($block.groupByFields[$ii].name -eq "Sender"){$groupby["Sender"] = 1}   
                        if($block.groupByFields[$ii].name -eq "SenderIdentityID"){$groupby["SenderIdentityID"] = 1}   
                        if($block.groupByFields[$ii].name -eq "SEntity"){$groupby["SEntity"] = 1}   
                        if($block.groupByFields[$ii].name -eq "SerialNumber"){$groupby["SerialNumber"] = 1}   
                        if($block.groupByFields[$ii].name -eq "Service"){$groupby["Service"] = 1}   
                        if($block.groupByFields[$ii].name -eq "Session"){$groupby["Session"] = 1}   
                        if($block.groupByFields[$ii].name -eq "SessionType"){$groupby["SessionType"] = 1}   
                        if($block.groupByFields[$ii].name -eq "Severity"){$groupby["Severity"] = 1}   
                        if($block.groupByFields[$ii].name -eq "SHostName"){$groupby["SHostName"] = 1}   
                        if($block.groupByFields[$ii].name -eq "SInterface"){$groupby["SInterface"] = 1}   
                        if($block.groupByFields[$ii].name -eq "SIP"){$groupby["SIP"] = 1}   
                        if($block.groupByFields[$ii].name -eq "SLocationCity"){$groupby["SLocationCity"] = 1}   
                        if($block.groupByFields[$ii].name -eq "SLocationRegion"){$groupby["SLocationRegion"] = 1}   
                        if($block.groupByFields[$ii].name -eq "SMAC"){$groupby["SMAC"] = 1}   
                        if($block.groupByFields[$ii].name -eq "SNATIP"){$groupby["SNATIP"] = 1}   
                        if($block.groupByFields[$ii].name -eq "SNATPort"){$groupby["SNATPort"] = 1}   
                        if($block.groupByFields[$ii].name -eq "SNetwork"){$groupby["SNetwork"] = 1}   
                        if($block.groupByFields[$ii].name -eq "Source"){$groupby["Source"] = 1}   
                        if($block.groupByFields[$ii].name -eq "SPort"){$groupby["SPort"] = 1}   
                        if($block.groupByFields[$ii].name -eq "Status"){$groupby["Status"] = 1}   
                        if($block.groupByFields[$ii].name -eq "Subject"){$groupby["Subject"] = 1}   
                        if($block.groupByFields[$ii].name -eq "SZone"){$groupby["SZone"] = 1}   
                        if($block.groupByFields[$ii].name -eq "ThreatId"){$groupby["ThreatId"] = 1}   
                        if($block.groupByFields[$ii].name -eq "ThreatName"){$groupby["ThreatName"] = 1}   
                        if($block.groupByFields[$ii].name -eq "URL"){$groupby["URL"] = 1}   
                        if($block.groupByFields[$ii].name -eq "UserAgent"){$groupby["UserAgent"] = 1}   
                        if($block.groupByFields[$ii].name -eq "UserImpactedIdentityID"){$groupby["UserImpactedIdentityID"] = 1}   
                        if($block.groupByFields[$ii].name -eq "UserOriginIdentityID"){$groupby["UserOriginIdentityID"] = 1}   
                        if($block.groupByFields[$ii].name -eq "VendorInfo"){$groupby["VendorInfo"] = 1}   
                        if($block.groupByFields[$ii].name -eq "VendorMessageID"){$groupby["VendorMessageID"] = 1}   
                        if($block.groupByFields[$ii].name -eq "Version"){$groupby["Version"] = 1}   

                    }

                    #output the contents of the hash table to a CSV single line                    
                    $zz_groupby = $groupby.Values.ForEach({"$_$($groupby.$_)"}) -join ','


                    foreach($group in $block.primaryCriteria.fieldFilters.values.Where({$_.filterType -eq "10"})){

                        if($group.displayvalue -eq "Access Failure"){$classification["Access Failure"] = 1}
                        if($group.displayvalue -eq "Access Granted"){$classification["Access Granted"] = 1}
                        if($group.displayvalue -eq "Access Revoked"){$classification["Access Revoked"] = 1}
                        if($group.displayvalue -eq "Access Success"){$classification["Access Success"] = 1}
                        if($group.displayvalue -eq "Account Created"){$classification["Account Created"] = 1}
                        if($group.displayvalue -eq "Account Deleted"){$classification["Account Deleted"] = 1}
                        if($group.displayvalue -eq "Account Modified"){$classification["Account Modified"] = 1}
                        if($group.displayvalue -eq "Activity"){$classification["Activity"] = 1}
                        if($group.displayvalue -eq "Attack"){$classification["Attack"] = 1}
                        if($group.displayvalue -eq "Authentication Failure"){$classification["Authentication Failure"] = 1}
                        if($group.displayvalue -eq "Authentication Success"){$classification["Authentication Success"] = 1}
                        if($group.displayvalue -eq "Compromise"){$classification["Compromise"] = 1}
                        if($group.displayvalue -eq "Configuration"){$classification["Configuration"] = 1}
                        if($group.displayvalue -eq "Critical"){$classification["Critical"] = 1}
                        if($group.displayvalue -eq "Denial Of Service"){$classification["Denial Of Service"] = 1}
                        if($group.displayvalue -eq "Error"){$classification["Error"] = 1}
                        if($group.displayvalue -eq "Failed Activity"){$classification["Failed Activity"] = 1}
                        if($group.displayvalue -eq "Failed Attack"){$classification["Failed Attack"] = 1}
                        if($group.displayvalue -eq "Failed Denial of Service"){$classification["Failed Denial of Service"] = 1}
                        if($group.displayvalue -eq "Failed Malware"){$classification["Failed Malware"] = 1}
                        if($group.displayvalue -eq "Failed Misuse"){$classification["Failed Misuse"] = 1}
                        if($group.displayvalue -eq "Failed Suspicious"){$classification["Failed Suspicious"] = 1}
                        if($group.displayvalue -eq "Information"){$classification["Information"] = 1}
                        if($group.displayvalue -eq "Malware"){$classification["Malware"] = 1}
                        if($group.displayvalue -eq "Misuse"){$classification["Misuse"] = 1}
                        if($group.displayvalue -eq "Network Allow"){$classification["Network Allow"] = 1}
                        if($group.displayvalue -eq "Network Deny"){$classification["Network Deny"] = 1}
                        if($group.displayvalue -eq "Network Traffic"){$classification["Network Traffic"] = 1}
                        if($group.displayvalue -eq "Other Audit"){$classification["Other Audit"] = 1}
                        if($group.displayvalue -eq "Other Audit Failure"){$classification["Other Audit Failure"] = 1}
                        if($group.displayvalue -eq "Other Audit Success"){$classification["Other Audit Success"] = 1}
                        if($group.displayvalue -eq "Other Operations"){$classification["Other Operations"] = 1}
                        if($group.displayvalue -eq "Other Security"){$classification["Other Security"] = 1}
                        if($group.displayvalue -eq "Policy"){$classification["Policy"] = 1}
                        if($group.displayvalue -eq "Reconnaissance"){$classification["Reconnaissance"] = 1}
                        if($group.displayvalue -eq "Startup and Shutdown"){$classification["Startup and Shutdown"] = 1}
                        if($group.displayvalue -eq "Suspicious"){$classification["Suspicious"] = 1}
                        if($group.displayvalue -eq "Vulnerability"){$classification["Vulnerability"] = 1}
                        if($group.displayvalue -eq "Warning"){$classification["Warning"] = 1}
                    }

                    $zz_class = $classification.Values.ForEach({"$_$($classification.$_)"}) -join ','                    

                    #ewwwww, dont look at this
                    $z =  $aa + $bb + $zz_class + "," + $ee_ce + " " + $ff_mpe + $zz_groupby
                    #$z
                    $z | add-content aie.csv

            }

        }

             
    }
    catch [System.Net.WebException]
    {
         #HTTP response code 500, i.e., no matching AIE Rule ID 
    }
    catch{
        $_
    }
}