param(
  [Parameter(Mandatory=$false)]
  [string]$action = 'list',
  [Parameter(Mandatory=$false)]
  [string]$caseGUID = ''
)

#Variables
$token = "Case API token goes here"
$caseUrl = "localhost:8505"

#LIST Action Variables
$casesToRetrieve = 25						#default is 25, increase as needed
#Other filters are available, but not implemented in this example.  See http://localhost:8505/lr-case-api/docs#operation/listCases for more details.

write-output @"

----------------------------------------------------------------------------------------------------------------------------------------------------------------
LogRhythm Case API Demo.
----------------------------------------------------------------------------------------------------------------------------------------------------------------

This script is a proof of concept for using the LogRhythm Case API.  

You'll need a valid Case API bearer token.  For more detail on generating one, see the Help Guide.

For more detail on using the Case API please see http://localhost:8505/lr-case-api/docs#section/Authentication


"@


try{
    switch ($action)
    {
        "list"  {

            $rs = Invoke-WebRequest -Uri http://$caseUrl/lr-case-api/cases/ -Headers @{ "Authorization" = "Bearer $token"; count = $casesToRetrieve } -ContentType "application/json" -Method GET -UseBasicParsing
            $caseResults = $rs.content | ConvertFrom-JSON

            "Total no. of Cases: {0}" -f $caseResults.Count

            foreach($case in $caseResults){
                "{0}, {1}" -f $case.id, $case.name
            }

        }  
        "export"  {

            $caseId = $caseGUID

            $rs = Invoke-WebRequest -Uri http://$caseUrl/lr-case-api/cases/$caseId -Headers @{ "Authorization" = "Bearer $token" } -ContentType "application/json" -Method GET -UseBasicParsing
            $caseResults = $rs.content | ConvertFrom-JSON

            write-output "`nSUMMARY`n----------------------------------------"
            "Case Name: {0}" -f $caseResults.name
            "Case ID: {0}" -f $caseResults.number
            "Status: {0}" -f $caseResults.status.name
            #"Status ID: {0}" -f $caseResults.status.number
            "Owner: {0}" -f $caseResults.owner.name
            #"Owner ID: {0} -f "$caseResults.owner.number
            "Date Created: {0}" -f $caseResults.dateCreated
            "Date Due: {0}" -f $caseResults.dueDate
            "Summary: `"{0}`"" -f $caseResults.summary

            write-output "`nCOLLABORATORS`n----------------------------------------"
            #TEST this likley needs be an array
            if($caseResults.collaborators){
                    "Collaborators: {0}" -f $caseResults.collaborators.name
            }else{
                write-output "`nNo Case collaborators."
            }

            write-output "`nRESOLUTION`n----------------------------------------"
            if($caseResults){
                "Resolution: {0}" -f $caseResults.resolution
                "Date Updated: {0}" -f $caseResults.resolutionDateUpdated
                "Last Updated By: {0}" -f $caseResults.resolutionLastUpdatedBy.name
            }else{
                write-output "No Case resolution."
            }

 
            $rs = Invoke-WebRequest -Uri http://$caseUrl/lr-case-api/cases/$caseId/evidence/ -Headers @{ "Authorization" = "Bearer $token" } -ContentType "application/json" -Method GET -UseBasicParsing
            $caseEvidence = $rs.content | ConvertFrom-JSON
            
            write-output "`nEVIDENCE`n----------------------------------------"
            if($caseEvidence){
                foreach($clue in $caseEvidence){
                "Type: {0}" -f $clue.type
                "Date Created: {0}" -f $clue.dateCreated
                "Date Updated: {0}" -f $clue.dateUpdated
                "Created By: {0}" -f $clue.createdBy.name
                "Last Updated By: {0}" -f $clue.lastUpdatedBy.name
                if($clue.type -eq "note"){"Text: {0}" -f $clue.text; "Pinned: {0}" -f $clue.pinned}
                if($clue.type -eq "log"){"Log Count: {0}" -f $clue.logs.logCount}
                if($clue.type -eq "alarm"){"Alarm ID: {0}" -f $clue.alarm.alarmid; "Alarm Date: {0}" -f $clue.alarm.date; "Alarm Rule Name: {0}" -f $clue.alarm.alarmRuleName; "Alarm RBP: {0}" -f $clue.alarm.riskBasedPriorityMax;}
                write-output "`n"
                }
            }else{
                write-output "No evidence in case."
            }


            $rs = Invoke-WebRequest -Uri http://$caseUrl/lr-case-api/cases/$caseId/associated/ -Headers @{ "Authorization" = "Bearer $token" } -ContentType "application/json" -Method GET -UseBasicParsing
            $associatedCases = $rs.content | ConvertFrom-JSON

            write-output "`nASSOCIATED CASES`n----------------------------------------"
            if($associatedCases){
                foreach($case in $associatedCases){
                        #iterate through associated cases here
                    }
            }else{
                     write-output "No associated cases."

            }


            $rs = Invoke-WebRequest -Uri http://$caseUrl/lr-case-api/cases/$caseId/metrics/ -Headers @{ "Authorization" = "Bearer $token" } -ContentType "application/json" -Method GET -UseBasicParsing
            $caseMetrics = $rs.content | ConvertFrom-JSON

            write-output "`nMETRICS`n----------------------------------------"
            "Created: {0}" -f $caseMetrics.created.date
            "Completed: {0}" -f $caseMetrics.completed.date
            "Incident: {0}" -f $caseMetrics.incident.date
            "Mitigated: {0}" -f $caseMetrics.mitigated.date
            "Resolved: {0}" -f $caseMetrics.resolved.date
            "Evidence: {0}" -f $caseMetrics.earliestEvidence.date
        } 

    }

 }
 catch{
        Write-Error "SmartResponse error.  Exception details: $ErrorMessage = $_.Exception.Message"
        exit 1
}



