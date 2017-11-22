param(
  [Parameter(Mandatory=$false)]
  [int]$userId = 1,
  [Parameter(Mandatory=$false)]
  [int]$aieStartRuleNo = 1,
  [Parameter(Mandatory=$false)]
  [int]$aieStopRuleNo = 1400
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

$headers = "#, AlarmRule, Enabled, RuleGroup, Supression, EventForwarding, RiskRating, FPP, RBP, RB_Type, RB_DataSource, RB_Classification, RB_Classification2, RB_Classification3, RB_Classification4, RB_Classification5, RB_Classification6, RB_Classification7, RB_Classification8, RB_Classification9, RB_Classification10, RB_CommonEvent1,RB_CommonEvent2,RB_CommonEvent3,RB_CommonEvent4,RB_CommonEvent5,RB_CommonEvent6,RB_CommonEvent7,RB_CommonEvent8,RB_CommonEvent9,RB_CommonEvent10," 
add-content aie.csv $headers

for($i=$aieStartRuleNo; $i -le $aieStopRuleNo; $i++)
{
    try {
        $rs = Invoke-WebRequest -Uri http://localhost:8505/lr-services-host-api/actions/domainobject -ContentType "application/json" -Method POST -Body "{source : '',destination : 'DomainObjectService',messageType : 'GetObjectRequest',ver: 1, data: {objectType : 'AieRule', userId : 1, objectId : $i,}, }"
        $psObject = $rs.content | ConvertFrom-JSON
        

        foreach($object in $psObject){
            $aa = "{0},`"{1}`",{2},{3},{4},{5},{6},{7},{8}" -f $object.id, `
                                                    $object.alarmRule.name, `
                                                    $object.alarmRule.enabled, `
                                                    $object.ruleGroup, `
                                                    $object.supression, ` #-replace ".{3}$", ` 
                                                    $object.eventForwardingEnabled, `
                                                    $object.commonEvent.riskRating, `
                                                    $object.falsePositiveProbability.id,
                                                    (CalcRBP $object.commonEvent.riskRating $object.falsePositiveProbability.name)



            foreach($block in $object.blocks){
             $bb = "{0},{1},{2}," -f $block.id, $block.blockType.name, $block.datasource
                    
                    #Find the total number of Classifications found in the field filters, any remainders we'll pad out with blanks
                    #$bbb = $block.primaryCriteria.fieldFilters.values.Count
                    $cc = For ($ii=0; $ii -le 10; $ii++) {
                                if($block.primaryCriteria.fieldFilters.values[$ii].filterType -eq "10"){
                                   "{0}," -f $block.primaryCriteria.fieldFilters.values[$ii].displayValue
                                } else {
                                    ","
                                }
                    }

                    #$ddd = $bbb = $block.primaryCriteria.fieldFilters.values.Count
                    $ee = For ($ii=0; $ii -le 10; $ii++) {
                                if($block.primaryCriteria.fieldFilters.values[$ii].filterType -eq "11"){
                                   "{0}," -f $block.primaryCriteria.fieldFilters.values[$ii].displayValue
                                } else {
                                    ","
                                }
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
                    $z =  $aa + $bb + $cc + $ee # + $d + $e + $f
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