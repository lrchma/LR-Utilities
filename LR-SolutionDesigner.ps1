param(
  [Parameter(Mandatory=$false)] #user required MPS, taken from LADD
  [int]$mps ,
  [Parameter(Mandatory=$false)] #minimum days online (TTL) required
  [int]$ttl = 10,
  [Parameter(Mandatory=$false)] #the LogRhythm average raw log size default is 400 bytes
  [int]$raw_log_size = 400,
  [Parameter(Mandatory=$false)] #number of agents required, does not distinguish between lite or pro but does check against the DP check
  [int]$agent_count = 0,
  [Parameter(Mandatory=$false)] #the number of DX nodes required for a cluster
  [int]$dx_node_count = 1,
  [Parameter(Mandatory=$false)] #the number of DPs required for pinned or cluster mode
  [int]$dp_count = 1,
  [Parameter(Mandatory=$false)] #enable debug statements via console (for troubleshooting)
  [int]$debugmode = 0,
  [Parameter(Mandatory=$false)] #RESCOL OUTPUT
  [string]$ProspectName = "ACME",
  [Parameter(Mandatory=$false)] #RECSOL OUPUT
  [string]$BusinessCase = "Security",
  [Parameter(Mandatory=$false)] #RECSOL OUPUT
  [string]$QuantityDevice = "unspecified",
  [Parameter(Mandatory=$false)] #RECSOL OUPUT
  [string]$PreparedBy = "LogRhythm Recsol Generator"
)



<########## TODO LIST ##########

* Add PS3 version check
* use debug statements and remove write-hosts
* Remove Min_Processing_Rate as its not used
* Change Variables Hash Table to a table and add calcualted fields then remove ordered
* Remove sizing coeffecient?
* Add parameter error checking, e.g., someone adds an incorrect input value

##########>

clear

<#
<10K MPS
Standalone XM, XM + DX, PM5450 with up to 2 DPS and 2 DXs
No HA, DR or Netmon or Software Solution

#>

$variables = @{
    'DX Max Disk Utilization %' = 0.80                #should not be changed from 80%, this is an Elastic best practice setting
    'Cluster Index Efficiency %' = 0.60               #should not be changed from 60%
    'Seconds Per Day' = 86400
    'Gigabyte' = 1073741824
    'DX Replica Count' = 1                            #logrhythm use a replica value of 1 by default, and a maximum ES cluster size of 10
    'DX Max Index Days Supported' = 90                #As of LogRhythm 7.3 90 days online (TTL) is the maximum supported retention period

    'Archive Compression' = 0.10
    'Archive Retention' = 365
    'Minimum Days Online' =  $ttl
    'Log Overhead %' =  0.86
    'Raw Log Size' = $raw_log_size
    'Online Rate %' =  1.0
    'Messages Per Second' =  $mps
    'Sizing Coefficient %' = 0.8                      #by default sizes an appliance to 100% of its sustained indexing rate, but can be used to ensure an appliance not be sized at more than 80% utilization
    'Max Event Rate $' =  0.02
    'High Availability Penalty %' = -0.10
    'Agent Count' =  $agent_count
    'DX Cluster Node Count' = $dx_node_count
}

# add the following calculated elements to the hashtable after its been instantiated
$variables.add("Archives Per Day",0)
$variables.add("Archives Per Month",0)
$variables.add("Average Indexed Row Size",( $variables.Item("Raw Log Size") + ( $variables.Item("Raw Log Size") * $variables.Item("Log Overhead %") ) ) )
$variables.add("Messages Per Day",( $variables.Item("Messages Per Second") * $variables.Item("Seconds Per Day") ) )
$variables.add("Online Logs Per Day GB", ( ( ( ( $variables.Item("Average Indexed Row Size") * $variables.Item("Messages Per Day") ) * $variables.Item("Online Rate %" ) ) / $variables.Item("Gigabyte") ) ) )

        


<############################## 
    APPLIANCE HASH TABLES
##############################>


<########## All in one (XMs) ##########>

$xm4411 = @{
    Type = 'XM'
    Name = 'XM4411'
    SKU = 'LR-SW-XM4411'
    License_Rate = '250'
    Max_Indexing_Sustained_Rate = '1000'
    Max_Processing_Sustained_Rate = '1000'
    Storage = '1376'
    Max_Agent = '250'
    Price = '27000'
}
$xm4411.add("Indexing_Sustained_Rate", $variables.Item("Sizing Coefficient %") * $xm4411.Item("Max_Indexing_Sustained_Rate") ) 
$xm4411.add("Processing_Sustained_Rate", $variables.Item("Sizing Coefficient %") * $xm4411.Item("Max_Processing_Sustained_Rate") ) 

$xm4431 = @{
    Type = 'XM'
    Name = 'XM4431'
    SKU = 'LR-SW-XM4311'
    Max_Indexing_Sustained_Rate = '1000'
    License_Rate = '500'
    Max_Processing_Sustained_Rate = '1000'
    Storage = '1376'
    Max_Agent = '250'
    Price = '34500'
}
$xm4431.add("Indexing_Sustained_Rate", $variables.Item("Sizing Coefficient %") * $xm4431.Item("Max_Indexing_Sustained_Rate") ) 
$xm4431.add("Processing_Sustained_Rate", $variables.Item("Sizing Coefficient %") * $xm4431.Item("Max_Processing_Sustained_Rate") ) 

$xm4441 = @{
    Type = 'XM'
    Name = 'XM4441'
    SKU = 'LR-SW-XM4411'
    Max_Indexing_Sustained_Rate = '1000'
    License_Rate = '750'
    Max_Processing_Sustained_Rate = '1000'
    Storage = '1376'
    Max_Agent = '250'
    Price = '40000'
}
$xm4441.add("Indexing_Sustained_Rate", $variables.Item("Sizing Coefficient %") * $xm4441.Item("Max_Indexing_Sustained_Rate") ) 
$xm4441.add("Processing_Sustained_Rate", $variables.Item("Sizing Coefficient %") * $xm4441.Item("Max_Processing_Sustained_Rate") ) 

$xm4451 = @{
    Type = 'XM'
    Name = 'XM4451'
    SKU = 'LR-SW-XM4511'
    Max_Indexing_Sustained_Rate = '1000'
    License_Rate = '1000'
    Max_Processing_Sustained_Rate = '1000'
    Storage = '1376'
    Max_Agent = '250'
    Price = '46500'
}
$xm4451.add("Indexing_Sustained_Rate", $variables.Item("Sizing Coefficient %") * $xm4451.Item("Max_Indexing_Sustained_Rate") ) 
$xm4451.add("Processing_Sustained_Rate", $variables.Item("Sizing Coefficient %") * $xm4451.Item("Max_Processing_Sustained_Rate") ) 

$xm6411 = @{
    Type = 'XM'
    Name = 'XM6411'
    SKU = 'LR-SW-XM6411'
    Max_Indexing_Sustained_Rate = '5000'
    License_Rate = '1000'
    Max_Processing_Sustained_Rate = '1000'
    Storage = '9099'
    Max_Agent = '1000'
    Price = '66000'
}
$xm6411.Add("Indexing_Sustained_Rate", $variables.Item("Sizing Coefficient %") * $xm6411.Item("Max_Indexing_Sustained_Rate") )
$xm6411.Add("Processing_Sustained_Rate", $variables.Item("Sizing Coefficient %") * $xm6411.Item("Max_Processing_Sustained_Rate") )


$xm6431 = @{
    Type = 'XM'
    Name = 'XM6431'
    SKU = 'LR-SW-XM6431'
    Max_Indexing_Sustained_Rate = '5000'
    License_Rate = '2500'
    Max_Processing_Sustained_Rate = '1000'
    Storage = '9099'
    Max_Agent = '1000'
    Price = '77000'
}
$xm6431.Add("Indexing_Sustained_Rate", $variables.Item("Sizing Coefficient %") * $xm6431.Item("Max_Indexing_Sustained_Rate") )
$xm6431.Add("Processing_Sustained_Rate", $variables.Item("Sizing Coefficient %") * $xm6431.Item("Max_Processing_Sustained_Rate") )


$xm6451 = @{
    Type = 'XM'
    Name = 'XM6451'
    SKU = 'LR-SW-XM6451'
    Max_Indexing_Sustained_Rate = '5000'
    License_Rate = '5000'
    Max_Processing_Sustained_Rate = '1000'
    Storage = '9099'
    Max_Agent = '1000'
    Price = '88500'
}
$xm6451.Add("Indexing_Sustained_Rate", $variables.Item("Sizing Coefficient %") * $xm6451.Item("Max_Indexing_Sustained_Rate") )
$xm6451.Add("Processing_Sustained_Rate", $variables.Item("Sizing Coefficient %") * $xm6451.Item("Max_Processing_Sustained_Rate") )


$xm8410 = @{
    Type = 'XM'
    Name = 'XM8410'
    SKU = 'LR-SW-XM8410'
    Max_Indexing_Sustained_Rate = '10000'
    License_Rate = '5000'
    Max_Processing_Sustained_Rate = '10000'
    Storage = '18022'
    Max_Agent = '2000'
    Price = '156100'
}
$xm8410.Add("Indexing_Sustained_Rate", $variables.Item("Sizing Coefficient %") * $xm8410.Item("Max_Indexing_Sustained_Rate") )
$xm8410.Add("Processing_Sustained_Rate", $variables.Item("Sizing Coefficient %") * $xm8410.Item("Max_Processing_Sustained_Rate") )


$xm8430 = @{
    Type = 'XM'
    Name = 'XM8430'
    SKU = 'LR-SW-XM8430'
    Max_Indexing_Sustained_Rate = '10000'
    License_Rate = '7500'
    Max_Processing_Sustained_Rate = '10000'
    Storage = '18022'
    Max_Agent = '2000'
    Price = '263100'
}
$xm8430.Add("Indexing_Sustained_Rate", $variables.Item("Sizing Coefficient %") * $xm8430.Item("Max_Indexing_Sustained_Rate") )
$xm8430.Add("Processing_Sustained_Rate", $variables.Item("Sizing Coefficient %") * $xm8430.Item("Max_Processing_Sustained_Rate") )


$xm8450 = @{
    Type = 'XM'
    Name = 'XM8450'
    SKU = 'LR-SW-XM8450'
    Max_Indexing_Sustained_Rate = '10000'
    License_Rate = '10000'
    Max_Processing_Sustained_Rate = '10000'
    Storage = '18022'
    Max_Agent = '2000'
    Price = '381100'
}
$xm8450.Add("Indexing_Sustained_Rate", $variables.Item("Sizing Coefficient %") * $xm8450.Item("Max_Indexing_Sustained_Rate") )
$xm8450.Add("Processing_Sustained_Rate", $variables.Item("Sizing Coefficient %") * $xm8450.Item("Max_Processing_Sustained_Rate") )


<########## Platform Managers (PM) ##########>

$pm5450 = @{
    Type = 'PM'
    Name = 'PM5450'
    SKU = 'LR-SW-PM5450'
    AIE_License = '10000'
}

$pm7450 = @{
    Type = 'PM'
    Name = 'PM7450'
    SKU = 'LR-SW-PM7450'
    AIE_License = '20000'
}

<########## Data Processors (DP) ##########>

$dp5410 = @{
    Type = 'DP'
    Name = 'DP5410'
    SKU = 'LR-SW-DP5410'
    Max_Processing_Sustained_Rate = '5000'
    License_Rate = '1000'
    Max_Agent = '2000'
}
$dp5410.Add("Processing_Sustained_Rate", $variables.Item("Sizing Coefficient %") * $dp5410.Item("Max_Processing_Sustained_Rate") )

$dp5450 = @{
    Type = 'DP'
    Name = 'DP5450'
    SKU = 'LR-SW-DP5450'
    Max_Processing_Sustained_Rate = '5000'
    License_Rate = '5000'
    Max_Agent = '2000'
}
$dp5450.Add("Processing_Sustained_Rate", $variables.Item("Sizing Coefficient %") * $dp5450.Item("Max_Processing_Sustained_Rate") )

$dp7410 = @{
    Type = 'DP'
    Name = 'DP7410'
    SKU = 'LR-SW-DP7410'
    Max_Processing_Sustained_Rate = '5000'
    License_Rate = '5000'
    Max_Agent = '5000'
}
$dp7410.Add("Processing_Sustained_Rate", $variables.Item("Sizing Coefficient %") * $dp7410.Item("Max_Processing_Sustained_Rate") )

$dp7450 = @{
    Type = 'DP'
    Name = 'DP7450'
    SKU = 'LR-SW-DP7450'
    Max_Processing_Sustained_Rate = '15000'
    License_Rate = '15000'
    Max_Agent = '5000'
}

$dp7450.Add("Processing_Sustained_Rate", $variables.Item("Sizing Coefficient %") * $dp7450.Item("Max_Processing_Sustained_Rate") )

<########## Data Indexers (DX) ##########>

$dx5411 = @{
    Type = 'DX'
    Name = 'DX5411'
    SKU = 'LR-SW-DX5411'
    Max_Indexing_Sustained_Rate = '5000'
    Storage = '6404'
}
$dx5411.Add("Indexing_Sustained_Rate", $variables.Item("Sizing Coefficient %") * $dx5411.Item("Max_Indexing_Sustained_Rate") )


$dx7411 = @{
    Type = 'DX'
    Name = 'DX7411'
    SKU = 'LR-SW-D7411'
    Max_Indexing_Sustained_Rate = '10000'
    Storage = '23768'
}
$dx7411.Add("Indexing_Sustained_Rate", $variables.Item("Sizing Coefficient %") * $dx7411.Item("Max_Indexing_Sustained_Rate") )


# the ordered hashtable is used to ensure appliances are tested in order of capability/cost

$appliances = [ordered]@{}
$appliances.Add($xm4411.Item("Name"),$xm4411)
$appliances.Add($xm4431.Item("Name"),$xm4431)
$appliances.Add($xm4441.Item("Name"),$xm4441)
$appliances.Add($xm4451.Item("Name"),$xm4451)
$appliances.Add($xm6411.Item("Name"),$xm6411)
$appliances.Add($xm6431.Item("Name"),$xm6431)
$appliances.Add($xm6451.Item("Name"),$xm6451)
$appliances.Add($xm8410.Item("Name"),$xm8410)
$appliances.Add($xm8430.Item("Name"),$xm8430)
$appliances.Add($xm8450.Item("Name"),$xm8450)

$appliances.Add($pm5450.Item("Name"),$pm5450)
$appliances.Add($pm7450.Item("Name"),$pm7450)

$appliances.Add($dp5410.Item("Name"),$dp5410)
$appliances.Add($dp5450.Item("Name"),$dp5450)
$appliances.Add($dp7410.Item("Name"),$dp7410)
$appliances.Add($dp7450.Item("Name"),$dp7450)

$appliances.Add($dx5411.Item("Name"),$dx5411)
$appliances.Add($dx7411.Item("Name"),$dx7411)



<##########

 FUNCTIONS

##########> 


<#
1. DP_Pinned_Mode
2. DX_Cluster_TTL
3. DX_Pinned_TTL
#>



function DX_Pinned_TTL ($dx_count, $min_ttl_required){
# check a DX in Pinned mode, i.e., 1 to 1 mapping with a DP

    foreach($appliance in $appliances){        
        foreach($model in $appliance.Values){
            if($model.Type -eq 'DX'){

                #need to explicitly cast the Sum variables as int, else Powershell treats as string values and chaos ensues
                if( [single]$variables.Item("Messages Per Second") -le ( [int]$dx_count * [single]$model.Max_Indexing_Sustained_Rate * [single]$variables.Item("Messages Per Second") ) ){
                            
                    $r = ( [int]$dx_count * [int]$model.storage * [single]$variables.Item("DX Max Disk Utilization %") ) / [single]$variables.Item("Online Logs Per Day GB")
                        
                    if($r -le $min_ttl_required ){
                        "NO MATCH: {0} does not meet minimum TTL ({1:N2})." -f $model.Name, $min_ttl_required
                    }
                    elseif($r -ge $variables.Item("DX Max Index Days Supported") ){
                        "MATCH: {0} provides 90 days or greater TTL ({1:N2})." -f $model.Name, $r 
                    }
                    else{
                        "MATCH: {0} provides {1:N2} days TTL." -f $model.Name, $r 
                    }
                }else{
                    write-output "No Match: No Viable Solution Could Be Found." -fore red
                }
            }
        }
    }
}





function DP($dp_model,$dp_count){

    foreach($appliance in $appliances){
        foreach($model in $appliance.Values){
            if($model.Name -eq $dp_model){

                [int]$r = ( [int]$dp_count * [int]$model.License_Rate )
                write-debug $r

                if( [int]$variables.Item("Messages Per Second") -le [int]$r ){
                    $z = "MATCH: {0} x {1} meets {2:N0} MPS" -f $dp_count, $model.Name, $variables.Item("Messages Per Second") 

                    $result = "Result: Match"
                    $details = "$z"
                    return $result, $details

                                          
                }else{
                    $z = "NO MATCH: {0} MPS exceeds {1} x {2} ({3:N0})" -f $variables.Item("Messages Per Second"), $dp_count, $model.Name, ( [int]$model.License_Rate * [int]$dp_count )
                    $result = "Result: No Match"
                    $details = "$z"
                    return $result, $details

                }
            }
        }
    }
}


function DP2($dp_model,$dp_count){

    foreach($appliance in $appliances){
        foreach($model in $appliance.Values){
            if($model.Name -eq $dp_model){

                [int]$r = ( [int]$dp_count * [int]$model.License_Rate )
                write-debug $r

                if( [int]$variables.Item("Messages Per Second") -le [int]$r ){
                    $z = "MATCH: {0} x {1} meets {2:N0} MPS" -f $dp_count, $model.Name, $variables.Item("Messages Per Second") 

                    $result = "Result: Match"
                    $details = "$z"
                    return $result, $details

                                          
                }else{
                    $z = "NO MATCH: {0} MPS exceeds {1} x {2} ({3:N0})" -f $variables.Item("Messages Per Second"), $dp_count, $model.Name, ( [int]$model.License_Rate * [int]$dp_count )
                    $result = "Result: No Match"
                    $details = "$z"
                    return $result, $details

                }
            }
        }
    }
}

function DX_Cluster_TTL($dx_count, $min_ttl_required){        
    foreach($appliance in $appliances){
        foreach($model in $appliance.Values){
            if($model.Type -eq 'DX'){

                #need to explicitly cast the sum parts as int else Powershell treats as string values and chaos ensues
                if( [single]$variables.Item("Messages Per Day") -le ( [single]$model.Max_Indexing_Sustained_Rate * $variables.Item("Seconds Per Day") * $dx_count * [single]$variables.Item("Cluster Index Efficiency %") ) ){
                            
                    $r = ( ( [int]$model.storage * [single]$variables.Item("DX Max Disk Utilization %") / [single]$variables.Item("Online Logs Per Day GB") ) * [int]$dx_count / ( 1 + [int]$variables.Item("DX Replica Count") ) )

                    if($r -le $min_ttl_required ){
                        "NO MATCH.  {0} x {1} nodes does not meet minimum TTL ({2:N2}) at {3:N0} sustained indexing rate." -f $model.Name, $dx_count, $min_ttl_required, ([int]$dx_count * [int]$model.Indexing_Sustained_Rate * [single]$variables.Item("Cluster Index Efficiency %"))
                    }
                    elseif($r -ge $variables.Item("DX Max Index Days Supported") ){
                        "MATCH.  {0} x {1} provides 90 days or greater TTL ({2:N2}) at {3:N0} sustained indexing rate." -f $model.Name, $dx_count, $r, ([int]$dx_count * [int]$model.Indexing_Sustained_Rate * [single]$variables.Item("Cluster Index Efficiency %") )
                        }
                    else{
                        "MATCH.  {0} x {1} provides {2:N2} days TTL at {3:N0} sustained indexing rate." -f $model.Name, $dx_count, $r, ([int]$dx_count * [int]$model.Indexing_Sustained_Rate * [single]$variables.Item("Cluster Index Efficiency %")) 
                    }

                }else{
                    $z = $model.Name
                    $y = $variables.Item("Messages Per Second")
                    write-host "NO MATCH: $y MPS exceeds $z x $dx_count." -fore red
                }
            }
        }
    }
}


function XM($xm_model){

    foreach($appliance in $appliances){

        foreach($model in $appliance.Values){
              
            if($model.Name -eq $xm_model){
  
                #Is the user entered MPS lower than the license rate of the solution?
                if($variables.Item("Messages Per Second") -le $model.License_Rate){

                    #Is the user entered MPS lower than the maximum sustained indexing rate of the solution?
                    if($variables.Item("Messages Per Second") -le $model.Indexing_Sustained_Rate){

                        #Is the user entered TTL greater than the estimated Solution TTL?
                        if($variables.Item("Minimum Days Online") -le ( $variables.Item("DX Max Disk Utilization %") * $model.Storage / $variables.Item("Online Logs Per Day GB") ) ){

                            #Is the user entered number of Agents greater than the Solution can support?
                            if($variables.Item("Agent Count") -le $model.Max_Agent){
                                $z =  "MATCH | Model {0} | MPS: {1:N0} | License Rate: {2:N0} |" -f $model.Name, $variables.Item("Messages Per Second"), $model.License_Rate
                                #"`tIndexing Sustained Rate Pass!  Model: {0}, MPS: {1}, Indexing Sustained Rate: {2}" -f $model.Name, $variables.Item("Messages Per Second"), $model.Indexing_Sustained_Rate
                                #"`tTTL Pass!  Model: {0}, Requested TTL: {1}, Estimated TTL: {2}" -f $model.Name, $variables.Item("Minimum Days Online"), ( $variables.Item("DX Max Disk Utilization %") * $model.Storage / $variables.Item("Online Logs Per Day GB") )
                                #"`tAgent Count Pass!  Model: {0}, Agent Count: {1}, Max Agent: {2}" -f $model.Name, $variables.Item("Agent Count"), $model.Max_Agent

                                $result = "Result: Match"
                                $details = "$z"
                                return $result, $details
                            }
                            else{
                                #Agent Count Exceeded
                                $z = "Details: License MPS, Sustained Indexing, and TTL met but Max Agent Count Exceeded: {0:N}" -f $model.Name

                                $result = "Result: No Match"
                                $details = "$z"
                                return $result, $details

                            }

                        }
                        else{
                            #TTL Not Met
                            $z = "License MPS and Sustained Indexing Met, but not TTL : {0:N0}" -f $model.Name

                            $result = "Result: No Match"
                            $details = "$z"
                            return $result, $details
                        }

                    }
                    else{
                        #Sustained Index Failure

                        $z = "License MPS Met, but Sustained Indexing Exceeded: {0:N0}" -f $model.Name

                        $result = "Result: No Match"
                        $details = "$z"
                        return $result, $details
                    }

                }
                else{
                    #MPS exceeds license rate
                    
                    $z = "License Rate Exceeded: {0:N0}" -f $model.Name

                    $result = "Result: No Match"
                    $details = "$z"
                    return $result, $details
                }

            }
        
        }

    }

}

<##############################
     MAIN PROGRAM EXECUTION
##############################>

if($debugmode -eq 1){
    $DebugPreference = "Continue"
}else{
    $DebugPreference = "SilentlyContinue"
}

Write-Debug "Starting Main Program Exection."

$results_xm = [ordered]@{}
$results_i = 0

Write-Debug "Finding XM Minimal Viable Solution."

#look through all XM types in our appliance hashtable foreach call the XM function, if the result matches we then add these to another hash table call results.  
#This is ordered and the first result is assumed the best, least cost minimal viable solution match
foreach($appliance in $appliances){

    foreach($model in $appliance.Values){
              
        if($model.Type -eq 'XM'){

            $a, $b = XM $model.Name
            
            if($a -eq 'Result: Match'){
                write-debug "$b"
                $results_xm.add($results_i, $model.Name)
                $results_i = $results_i + 1
            }
        }
    }
}


if($results_xm.Contains(0)){  #at least one entry in the results hashtable

    foreach($appliance in $appliances){

        foreach($model in $appliance.Values){
              
            if($model.Name -eq $results_xm.Item(0)){
            
"Your LogRhythm Recommended Minimal Viable Solution (MVS) is a {0} 
Prospect Name: {1}
Business Driver: {2}
Estimated MPS (Sustained): {3:N0}
Estimated MPS (Peak): {4:N0}
Device Quantity: {5}
MVS License MPS: {6:N0}
MVS Maximum Architecture MPS: {7:N0}
List Price: {8:C2}
Prepared By {9} on {10}

" -f $results_xm.Item(0), $ProspectName, $BusinessCase, $variables.Item("Messages Per Second"), ( $variables.Item("Messages Per Second") * 1.5 ), $QuantityDevice, [int]$model.License_Rate, [int]$model.Max_Indexing_Sustained_Rate, [int]$model.Price, $PreparedBy, (get-Date -format r)

            }
        }
    }
}else{
    write-debug "No Minimal Viable XM Solution found :("
}


Write-Debug "Finding Pinned DP-DX Minimal Viable Solution."

$results_dpx = [ordered]@{}
$results_j = 0

#look through all XM types in our appliance hashtable foreach call the XM function, if the result matches we then add these to another hash table call results.  
#This is ordered and the first result is assumed the best, least cost minimal viable solution match
foreach($appliance in $appliances){

    foreach($model in $appliance.Values){
          
        if($model.Type -eq 'DP'){
                
            $a, $b = DP $model.Name $dp_count            #a = result status, b = result details
            
            if($a -eq 'Result: Match'){
                
                [string]$x = "{0}-{1}" -f $results_J, $results_J 

                $results_dpx.add($results_j, $model.Name)
                $results_dpx.add($x, $dp_count)
                $results_j = $results_j + 1
            }
        }
    }
}


if($results_dpx.Contains(0)){  #at least one entry in the results hashtable

    foreach($appliance in $appliances){

        foreach($model in $appliance.Values){
             
            if($model.Name -eq $results_dpx.Item(0)){
        
"Your LogRhythm Recommended Minimal Viable Solution (MVS) is {0} x {1} 
Prospect Name: {2}
Business Driver: {3}
Estimated MPS (Sustained): {4:N0}
Estimated MPS (Peak): {5:N0}
Device Quantity: {6}
MVS License MPS: {7:N0}
MVS Maximum Architecture MPS: {8:N0}
Prepared By {9} on {10}

" -f $results_dpx.Item(1), $results_dpx.Item(0), $ProspectName, $BusinessCase, $variables.Item("Messages Per Second"), ( $variables.Item("Messages Per Second") * 1.5 ), $QuantityDevice, ( [int]$model.License_Rate * $results_dpx.Item(1) ), ([int]$model.Max_Processing_Sustained_Rate * $results_dpx.Item(1) ), $PreparedBy, (get-Date -format r)

            }
        }
    }
}else{
    write-debug "No Minimal Viable DPX Solution Found :("
}
        
<# WORD OUTPUT TEST
    $z = "Your LogRhythm Recommended Minimal Viable Solution (MVS) is a {0}" -f $results.Item(0)
    $Word = New-Object -ComObject Word.Application
    $Document = $Word.Documents.Add()
    $Selection = $Word.Selection
    $Selection.TypeParagraph()
    $Selection.TypeText("$z")
    [Enum]::GetNames([microsoft.office.interop.word.WdSaveFormat])
    $Report = 'C:\Temp\mailmerge\3.doc'
    $Document.SaveAs([ref]$Report,[ref]$SaveFormat::wdFormatDocument)
    $word.Quit()
#> 








<#
Write-Host "`nDP_Pinned_Mode" -ForegroundColor Cyan
DP_Pinned_Mode $dp_count

Write-Host "`nDX_Pinned_TTL" -ForegroundColor Cyan
DX_Pinned_TTL $variables.Item("DX Cluster Node Count") $variables.Item("Minimum Days Online")

Write-Host "`nDX_Cluster_TTL" -ForegroundColor Cyan
DX_Cluster_TTL $variables.Item("DX Cluster Node Count") $variables.Item("Minimum Days Online")
#>





<# PINNED MODE

foreach($appliance in $appliances){

        foreach($model in $appliance.Values){

                if($model.Type -eq 'DP'){

                    for($i=1;$i -le 10; $i++){
                        
                        $a = ($i * $model.License_Rate)
                        if($variables.Item("Messages Per Second") -le $a ){
                            "{0} x {1} = {2}" -f $i, $model.Name, $a
                        }

                    }

                }


                if($model.Type -eq 'DX'){

                    for($i=1;$i -le 10; $i++){
                        
                        $b = ($i * $model.Max_Indexing_Sustained_Rate)
                        if($variables.Item("Messages Per Second") -le $b ){
                        
                            "{0} x {1} = {2}" -f $i, $model.Name, $b
                        }

                    }

                }

        }
}

#>

<# XM 
foreach($appliance in $appliances){

    foreach($model in $appliance.Values){
        
        write-output "`n"       
        
        if($model.Type -eq 'XM'){
   
            #Is the user entered MPS lower than the license rate of the solution?
            if($variables.Item("Messages Per Second") -le $model.License_Rate){# * $variables.Item("Seconds Per Day")

                #Is the user entered MPS lower than the maximum sustained indexing rate of the solution?
                if($variables.Item("Messages Per Second") -le $model.Indexing_Sustained_Rate){# * $variables.Item("Seconds Per Day")

                    #Is the user entered TTL greater than the estimated Solution TTL?
                    if($variables.Item("Minimum Days Online") -le ( $variables.Item("DX Max Disk Utilization %") * $model.Storage / $variables.Item("Online Logs Per Day GB") ) ){# * $variables.Item("Seconds Per Day")

                        #Is the user entered number of Agents greater than the Solution can support?
                        if($variables.Item("Agent Count") -le $model.Max_Agent){
                            "License Rate Pass!  Model: {0}, MPS: {1}, License Rate: {2}" -f $model.Name, $variables.Item("Messages Per Second"), $model.License_Rate
                            "Indexing Sustained Rate Pass!  Model: {0}, MPS: {1}, Indexing Sustained Rate: {2}" -f $model.Name, $variables.Item("Messages Per Second"), $model.Indexing_Sustained_Rate
                            "TTL Pass!  Model: {0}, Requested TTL: {1}, Estimated TTL: {2}" -f $model.Name, $variables.Item("Minimum Days Online"), ( $variables.Item("DX Max Disk Utilization %") * $model.Storage / $variables.Item("Online Logs Per Day GB") )
                            "Agent Count Pass!  Model: {0}, Agent Count: {1}, Max Agent: {2}" -f $model.Name, $variables.Item("Agent Count"), $model.Max_Agent
                        }
                        else{
                            #TTL fail
                            "No Bueno - License MPS, Sustained Indexing, and TTL met but Max Agent Count Exceeded: {0}" -f $model.Name
                        }

                    }
                    else{
                        #TTL fail
                        "No Bueno - License MPS and Sustained Indexing Met, but not TTL : {0}" -f $model.Name
                    }

                }
                else{
                    #Sustained Index Failure
                    "No Bueno - License MPS Met, but Sustained Indexing Exceeded: {0}" -f $model.Name
                }

            }
            else{
                #MPS exceeds license rate
                "No Bueno - License Rate Exceeded: {0}" -f $model.Name
            }

        }else{
            
            "Not evaluated: {0}" -f $model.Name
        }
    
    }

}

#>






<###################

Scratch Pad

###################>


