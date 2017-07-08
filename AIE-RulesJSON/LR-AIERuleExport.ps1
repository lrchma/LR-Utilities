$userId=1                        #this needs be the ID of the user logged in, e.g., 1 is logrhythmadmin
$aieRuleID=1200                     #the upper limit for AIE rules to check for.  In built rules go up to 1200 as of time of writing


for($i=1; $i -le $aieRuleID; $i++)
{
    try {
        $rs = Invoke-WebRequest -Uri http://localhost:8505/lr-services-host-api/actions/domainobject -ContentType "application/json" -Method POST -Body "{source : '',destination : 'DomainObjectService',messageType : 'GetObjectRequest',ver: 1, data: {objectType : 'AieRule', userId : 1, objectId : $i,}, }"
        $psObject = $rs.content | ConvertFrom-JSON
        
        write-output "--------------------------------------------------------------------------------"
        foreach($object in $psObject){
            "+ Rule Name: {0}" -f $object.alarmRule.name
            "`t- ID: {0}" -f $object.alarmRule.id
            "`t- Enabled: {0}" -f $object.alarmRule.enabled
            "`t- Group: {0}" -f $object.ruleGroup
            "`t- Description: `"{0}`"" -f $object.description
            "`t- Details: `"{0}`"" -f $object.details
            "`t- Suppression: {0}" -f $object.supression
            "`t- Alarm: {0}" -f $object.eventForwardingEnabled
            "`t- Risk Rating: {0}" -f $object.runtimePriority.id
            "`t- FPP: {0}" -f $object.falsePositiveProbability.id

            foreach($block in $object.blocks){
                "`t+ Block {0}:" -f $block.id
                "`t`t- Type: {0}" -f $block.blockType.name
                "`t`t- Source: {0}" -f $block.datasource  
                    
                    foreach($criteria in $block.primaryCriteria){
                        
                        write-output "`t`t+ Field Filters:"
                        foreach($value in $criteria.fieldFilters){
                            $value.values.ForEach{"`t`t`t- $($_.displayValue)"}
                            #$value.values.ForEach{"`t`t`t- $($_.displayValue), FilterType: $($_.filterType),  valueType: $($_.valueType), value: $($_.value),"}
                        }
                    }

                    foreach($filterIn in $block.filterIn){
                        write-output $fitlerIn
                    }


                    foreach($filterOut in $block.filterIn){
                        write-output $fitlerOut
                    }

                    ##GROUP BY FIELDS
                    write-output "`t`t+ Group By Fields:"
                    foreach($group in $block.groupByFields){
                        "`t`t`t- Field: {0}"   -f$group.name
                    }

                    write-output "`t`t+ Block Relationships"
                    foreach($relationship in $block.blockRelationship){
                        $relationship.fieldRelationships.ForEach{"`t`t`t- fieldName: $($_.currentBlockField.name)"}
                        #$relationship.fieldRelationships.ForEach{"`t`t`t- fieldName: $($_.currentBlockField.name), FilterType: $($_.fieldOperator.name),  valueType: $($_.prioerBlockType)"}
                    }
            }
            #Go easy on the API
            write-host $object.alarmRule.id
            start-sleep -m 100

        }

        #$rs.Content | convertfrom-json | convertto-json -depth 10 | Add-Content $outPutFile\$i-AIERule.json  
              
    }
    catch [System.Net.WebException]
    {
         #HTTP response code 500, i.e., no matching AIE Rule ID.   
    }
    catch{
        $_
    }
}

