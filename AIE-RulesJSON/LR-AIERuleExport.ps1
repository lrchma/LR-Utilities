param(
  [Parameter(Mandatory=$false)]
  [int]$userId = 1,
  [Parameter(Mandatory=$false)]
  [int]$aieStartRuleNo = 1,
  [Parameter(Mandatory=$false)]
  [int]$aieStopRuleNo = 1200
)


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

for($i=$aieStartRuleNo; $i -le $aieStopRuleNo; $i++)
{
    try {
        $rs = Invoke-WebRequest -Uri http://localhost:8505/lr-services-host-api/actions/domainobject -ContentType "application/json" -Method POST -Body "{source : '',destination : 'DomainObjectService',messageType : 'GetObjectRequest',ver: 1, data: {objectType : 'AieRule', userId : 1, objectId : $i,}, }"
        $psObject = $rs.content | ConvertFrom-JSON
        
        write-output "--------------------------------------------------------------------------------"
        foreach($object in $psObject){
            "+ Rule Name: {0}" -f $object.alarmRule.name
            "`t- ID: {0}" -f $object.id
            "`t- Enabled: {0}" -f $object.alarmRule.enabled
            "`t- Group: {0}" -f $object.ruleGroup
            "`t- Description: `"{0}`"" -f $object.description
            "`t- Details: `"{0}`"" -f $object.details
            "`t- Suppression: {0}" -f $object.supression -replace ".{3}$"
            "`t- Alarm: {0}" -f $object.eventForwardingEnabled
            "`t- Risk Rating: {0}" -f $object.commonEvent.riskRating
            "`t- FPP: {0}" -f $object.falsePositiveProbability.id
            "`t- Estimated RBP: {0}" -f (CalcRBP $object.commonEvent.riskRating $object.falsePositiveProbability.name)

            foreach($block in $object.blocks){
                "`t+ Block {0}:" -f $block.id
                "`t`t- Type: {0}" -f $block.blockType.name
                "`t`t- Source: {0}" -f $block.datasource  
                    
                    foreach($criteria in $block.primaryCriteria){
                        
                        write-output "`t`t+ Field Filters:"
                        foreach($value in $criteria.fieldFilters){
                            $value.values.ForEach{"`t`t`t- $($value.name) : $($_.displayValue)"}
                        }
                    }

                    #Needs testing, yet to find default AIE rules that use include/excludes
                    foreach($filterIn in $block.filterIn){
                        write-output $fitlerIn
                    }


                    #Needs testing, yet to find default AIE rules that use include/excludes
                    foreach($filterOut in $block.filterIn){
                        write-output $filterOut
                    }

                    ##GROUP BY FIELDS
                    write-output "`t`t+ Group By Fields:"
                    foreach($group in $block.groupByFields){
                        "`t`t`t- Field: {0}"   -f$group.name
                    }

                    write-output "`t`t+ Threshold Values:"
                    write-output $block.values.ForEach{"`t`t`t- Field: $($_.field.name) => $($_.count)"}

                    write-output "`t`t+ Block Relationships"
                    foreach($relationship in $block.blockRelationship){
                        $relationship.fieldRelationships.ForEach{"`t`t`t- fieldName: $($_.currentBlockField.name)"}
                    }
            }
            #Go easy on the API, not really needed, and echo the current rule to see how far along things are
            write-host $object.id
            start-sleep -m 100

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