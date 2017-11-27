param(
  [Parameter(Mandatory=$false)]
  [int]$userId = 1,
  [Parameter(Mandatory=$false)]
  [int]$aieStartRuleNo = 1000000004,
  [Parameter(Mandatory=$false)]
  [int]$aieStopRuleNo = 1000000004
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



#CSV Headers

$headers = "No,AlarmRule,Enabled,RuleGroup,Supression,EventForwarding,RiskRating,FPP,RBP,RB_Type,RB_DataSource,RB_Class1,RB_Class2,RB_Class3,RB_Class4,RB_Class5,RB_Class6,RB_Class7,RB_Class8,RB_Class9,RB_Class10,RB_CE1,RB_CE2,RB_CE3,RB_CE4,RB_CE5,RB_CE6,RB_CE7,RB_CE8,RB_CE9,RB_CE10,RB_MPE1,RB_MPE2,RB_MPE3,RB_MPE4,RB_MPE5,RB_MPE6,RB_MPE7,RB_MPE8,RB_MPE9,RB_MPE10,MF_Account,MF_Action,MF_Command,MF_CE,MF_CVE,MF_DEntity,MF_Destination,MF_DHostName,MF_DInterface,MF_DIP,MF_Direction,MF_DLocationCity,MF_DLocationRegion,MF_DMAC,MF_DNATIP,MF_DNATPort,MF_DNetwork,MF_Domain,MF_DomainOrigin,MF_DPort,MF_DZone,MF_Entity,MF_Group,MF_Hash,MF_KnownDHost,MF_KnownService,MF_KnownSHost,MF_Login,MF_MPERule,MF_MsgClass,MF_MsgSource,MF_MsgSourceHost,MF_Object,MF_ObjectName,MF_ObjectType,MF_ParentProcessId,MF_ParentProcessName,MF_ParentProcessPath,MF_PID,MF_Policy,MF_Process,MF_Protocol,MF_Reason,MF_Recipient,MF_RecipientIdentityID,MF_ResponseCode,MF_Result,MF_RootEntity,MF_Sender,MF_SenderIdentityID,MF_SEntity,MF_SerialNumber,MF_Service,MF_Session,MF_SessionType,MF_Severity,MF_SHostName,MF_SInterface,MF_SIP,MF_SLocationCity,MF_SLocationRegion,MF_SMAC,MF_SNATIP,MF_SNATPort,MF_SNetwork,MF_Source,MF_SPort,MF_Status,MF_Subject,MF_SZone,MF_ThreatId,MF_ThreatName,MF_URL,MF_UserAgent,MF_UserImpactedIdentityID,MF_UserOriginIdentityID,MF_VendorInfo,MF_VendorMessageID,MF_Version" 
add-content aie.csv $headers

for($i=$aieStartRuleNo; $i -le $aieStopRuleNo; $i++)
{
    try {
        $rs = Invoke-WebRequest -Uri http://localhost:8505/lr-services-host-api/actions/domainobject -ContentType "application/json" -Method POST -Body "{source : '',destination : 'DomainObjectService',messageType : 'GetObjectRequest',ver: 1, data: {objectType : 'AieRule', userId : 1, objectId : $i,}, }"
        $psObject = $rs.content | ConvertFrom-JSON
        

        foreach($object in $psObject){
            $aa = "{0},`"{1}`",{2},{3},{4},{5},{6},{7},{8}" -f $object.id, `
                                                    ($object.alarmRule.name -replace ",", " "), ` #replace any commas in the Alarm Rule name
                                                    $object.alarmRule.enabled, `
                                                    $object.ruleGroup, `
                                                    ($object.supression -replace ".{3}$"), ` #truncate the extra three zeros on the suppresion
                                                    $object.eventForwardingEnabled, `
                                                    $object.commonEvent.riskRating, `
                                                    $object.falsePositiveProbability.id,
                                                    (CalcRBP $object.commonEvent.riskRating $object.falsePositiveProbability.name)



            foreach($block in $object.blocks){
             $bb = "{0},{1},{2}," -f $block.id, $block.blockType.name, $block.datasource
                    
                    #Find the total number of Classifications found in the field filters, any remainders we'll pad out with blanks
                    
                    #Primary Filter: Classifications (Type 10)
                    $cc = For ($ii=0; $ii -le 9; $ii++) {
                                if($block.primaryCriteria.fieldFilters.values[$ii].filterType -eq "10"){
                                   "{0}," -f $block.primaryCriteria.fieldFilters.values[$ii].displayValue
                                } else {
                                    ","
                                }
                    }

                    #Primary Filter: Common Events (Type 11)
                    $ee = For ($ii=0; $ii -le 9; $ii++) {
                                if($block.primaryCriteria.fieldFilters.values[$ii].filterType -eq "11"){
                                   "{0}," -f $block.primaryCriteria.fieldFilters.values[$ii].displayValue
                                } else {
                                    ","
                                }
                    }

                    #Primary Filter: MPE Rule (Type 12) - Note, increase this to at least 30
                    $ff = For ($ii=0; $ii -le 9; $ii++) {
                                if($block.primaryCriteria.fieldFilters.values[$ii].filterType -eq "12"){
                                   "{0}," -f $block.primaryCriteria.fieldFilters.values[$ii].displayValue
                                } else {
                                    ","
                                }
                    }

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

<#
                    ##GROUP BY FIELDS
                    $d = foreach($group in $block.groupByFields){
                        "GroupByField={0}," -f $group.name
                    }

                    ##THRESHOLD VALUES
                    $e = foreach($field in $block.values){
                        "ThresholdValue={0}," -f $field.name
                    }

                    ##BLOCK RELATIONSHIPS
                    $f = foreach($relationship in $block.blockRelationship){
                        "RelationShip={0}," -f $relationship.fieldRelationships.currentBlockField.name
                    }

#>
                    
                    $zz = $groupby.Values.ForEach({"$_$($groupby.$_)"}) -join ','

                    $z =  $aa + $bb + $cc + $ee + $ff + $zz #+ $f
                    $z
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