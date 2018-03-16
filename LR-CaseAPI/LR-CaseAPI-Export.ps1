param(
  [Parameter(Mandatory=$false)]
  [string]$action = 'history',
  [Parameter(Mandatory=$false)]
  [string]$caseId = '1137',
  [Parameter(Mandatory=$false)]
  [string]$token = '<token here>',
  [Parameter(Mandatory=$false)]
  [string]$caseUrl = 'localhost:8505'
)



try{
    switch ($action)
    {
        "history"{

            $rs = Invoke-WebRequest -Uri http://$caseUrl/lr-case-api/cases/number/$caseId/history -Headers @{ "Authorization" = "Bearer $token" } -ContentType "application/json" -Method GET -UseBasicParsing

            if($rs.StatusCode -ne 200){
                write-output "Well that didn't go to plan!  An error occurred:"
                write-output "$rs"
                write-output "Exiting now.  Goodbye!"
                exit
            }

            $caseHistory = $rs.content | ConvertFrom-JSON
 
            foreach($entry in $caseHistory){
                switch($entry.action)
                {
                    AddCases{
                        #Chris Martin associated Case: 'XML Event Log' with Case: 'AIE: GPG-13: Logging Exception'
                        "{0}|{1}|{2} associated Case: {3} with Case: {4}" -f $entry.date, $entry.action, $entry.actor.name, $($entry.resources[0].DisplayName), $($entry.resources[1].DisplayName) 
                        #Note, the order of the Cases within resources is based on the GUID.  This could mean the order is wrong.  To fix you'd need test which is the parent and which is the child case.
                    }
                    AddCollaborators {
                        #Chris Martin added Charles Lindbergh as a collaborator to Case: 'AIE: GPG-13: Logging Exception'
                        "{0}|{1}|{2} added {3} as a collaborator to Case: {4}" -f $entry.date, $entry.action, $entry.actor.name, $($entry.resources | where {$_.type -eq "Person"} | select -ExpandProperty "DisplayName"), $($entry.resources | where {$_.type -eq "Case"} | select -ExpandProperty "DisplayName")
                        } 
                    AddTags {
                        #Chris Martin added tag #chris to Case: 'AIE: GPG-13: Logging Exception'
                         "{0}|{1}|{2} added tag {3} to Case: {4}" -f $entry.date, $entry.action, $entry.actor.name, $($entry.resources | where {$_.type -eq "Tag"} | select -ExpandProperty "DisplayName"), $($entry.resources | where {$_.type -eq "Case"} | select -ExpandProperty "DisplayName")
                        }
                    ChangeOwner{
                        #Chris Martin changed the owner of Case: 'AIE: GPG-13: Logging Exception' from Chris Martin to Charles 
                        "{0}|{1}|{2} changed the owner of Case: {3} from {4} to {5}" -f $entry.date, $entry.action, $entry.actor.name, $($entry.resources | where {$_.type -eq "Case"} | select -ExpandProperty "DisplayName"), $($entry.resources[1].DisplayName), $($entry.resources[2].DisplayName)
                    } 
                    ChangeStatus {
                        #Chris Martin changed the status of Case: 'AIE: GPG-13: Logging Exception' from Mitigated to Resolved
                        "{0}|{1}|{2} changed the status of Case: {3} from {4} to {5}"  -f $entry.date, $entry.action, $entry.actor.name, $($entry.resources[0].DisplayName), $($entry.resources.properties | where {$_.name -eq "statusName"} | select -ExpandProperty "from"), $($entry.resources.properties | where {$_.name -eq "statusName"} | select -ExpandProperty "to")

                    }
                    CreateAlarmEvidence {
                        #Chris Martin added an alarm to Case: 'AIE: GPG-13: Logging Exception' and updated the earliest evidence date from Unknown to 03/16/2018 6:40 am
                        "{0}|{1}|{2} added alarm {3} to Case: {4}" -f $entry.date, $entry.action, $entry.actor.name,  $($entry.resources.properties | where {$_.name -eq "alarm"} | select -ExpandProperty "to"), $($entry.resources | where {$_.type -eq "Case"} | select -ExpandProperty "DisplayName")
                        #Note, the Alarm is an Array
                    }
                    CreateCase {
                        #Chris Martin opened Case: 'AIE: GPG-13: Logging Exception'
                        "{0}|{1}|{2} opened Case: {3}"  -f $entry.date, $entry.action, $entry.actor.name, $($entry.resources[0].DisplayName) 
                    }
                    CreateLogEvidence {
                        #Chris Martin added log evidence to Case: 'AIE: GPG-13: Logging Exception' and updated the earliest evidence date from 03/16/2018 6:40 am to 03/16/2018 6:39 am
                        "{0}|{1}|{2} added {3} log(s) (`"{4}`") as evidence to Case {5} and updated the earliest evidence from {6} to {7}"  -f $entry.date, $entry.action, $entry.actor.name, $($entry.resources.properties | where {$_.name -eq "logCount"} | select -ExpandProperty "to"), $($entry.resources.properties | where {$_.name -eq "text"} | select -ExpandProperty "to"), $($entry.resources[0].DisplayName), $($entry.resources.properties | where {$_.name -eq "earliestEvidenceDate"} | select -ExpandProperty "from"), $($entry.resources.properties | where {$_.name -eq "earliestEvidenceDate"} | select -ExpandProperty "to")                        
                    }
                    CreateNoteEvidence {
                        #Chris Martin added a note to Case: 'AIE: GPG-13: Logging Exception'
                        "{0}|{1}|{2} added a note `"{3}`" to Case {4}"  -f $entry.date, $entry.action, $entry.actor.name, $($entry.resources.properties | where {$_.name -eq "text"} | select -ExpandProperty "to"), $($entry.resources[0].DisplayName) 
                    } 
                    UpdateCase {
                        switch($entry.resources.properties.name){
                            resolution { 
                                "{0}|{1}|{2} updated case {3} resolution to {4}"  -f $entry.date, $entry.action, $entry.actor.name, $($entry.resources[0].DisplayName), $($entry.resources.properties | where {$_.name -eq "resolution"} | select -ExpandProperty "to")
                            }
                            priority {
                                "{0}|{1}|{2} updated case {3} priority from {4} to {5}"  -f $entry.date, $entry.action, $entry.actor.name, $($entry.resources[0].DisplayName), $($entry.resources.properties | where {$_.name -eq "priority"} | select -ExpandProperty "from"), $($entry.resources.properties | where {$_.name -eq "priority"} | select -ExpandProperty "to")
                            }
                            dueDate {
                                "{0}|{1}|{2} updated case {3} due date from {4} to {5}"  -f $entry.date, $entry.action, $entry.actor.name, $($entry.resources[0].DisplayName), $($entry.resources.properties | where {$_.name -eq "dueDate"} | select -ExpandProperty "from"), $($entry.resources.properties | where {$_.name -eq "dueDate"} | select -ExpandProperty "to")
                            }
                            summary {
                                "{0}|{1}|{2} updated case {3} summary from `"{4}`" to `"{5}`""  -f $entry.date, $entry.action, $entry.actor.name, $($entry.resources[0].DisplayName), $($entry.resources.properties | where {$_.name -eq "summary"} | select -ExpandProperty "from"), $($entry.resources.properties | where {$_.name -eq "summary"} | select -ExpandProperty "to")
                            }
                        }
                    }
                    UploadFile {
                        #Chris Martin added a file as evidence to Case: 'AIE: GPG-13: Logging Exception'
                        "{0}|{1}|{2} added file `"{3}`" as evidence to Case {4}"  -f $entry.date, $entry.action, $entry.actor.name, $($entry.resources.properties | where {$_.name -eq "filename"} | select -ExpandProperty "to"), $($entry.resources[0].DisplayName) 
                    }
                     
                    default { $entry }
                    
                }

                
            }

        }
        
    }

 }
 catch{
        Write-Error "SmartResponse error.  Exception details: $ErrorMessage = $_.Exception.Message"
        exit 1
}



