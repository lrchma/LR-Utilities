param(

[Parameter(Mandatory=$true)]
[string]$nmScript = '',

[Parameter(Mandatory=$true)]
[string]$csvInput = '',

[Parameter(Mandatory=$true)]
[string]$path ='',

[Parameter(Mandatory=$true)]
[string]$method = ''

)


$validPaths = @(
    "/applications",
    "/systemInfo",
    "/services/capture/actions/addCapturedApplications",
    "/services/capture/actions/addExcludedApplications" ,
    "/services/capture/actions/removeCapturedApplications",
    "/services/capture/actions/removeExcludedApplications",
    "/services/actions/restart",
    "/services/capture"
)


$global:supportedPath = $false

foreach($validPath in $validPaths){
    if($path -eq $validPath){
        $supportedPath = $true
    }
}

if($supportedPath -eq $false){
   write-output "No valid or supported Netmon API path was found.  Exiting"
   exit
}

$csv = import-csv -Path $csvInput

foreach($netmon in $csv){

    write-output "`nConnecting to $($netmon.host) with credentials $($netmon.user)"
    Invoke-Expression "$nmScript -path `"$($path)`" -method `"$($method)`" -url `"https://$($netmon.host)/api`" -username `"$($netmon.user)`" -password `"$($netmon.password)`" " 
}
