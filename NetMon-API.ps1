<#

.NAME
NetMon-API

.SYNOPSIS
Wrapper for interacting with the LogRhythm NetMon API

.DESCRIPTION


.EXAMPLE
LIST APPLICATIONS
.\NetMon.ps1 -path "/applications" -method "GET" 

DOWNLOAD PCAP
.\NetMon.ps1 -path "/pcap/action/download" -method "POST" -Outfile "test2" -session "577c3ef6-cca3-41d7-a4cd-81783dfbd292" 

RESTART NETMON SERVICES
.\NetMon.ps1 -path "/services/actions/restart" -method "PUT" 

GET CAPTURE STATE
.\NetMon.ps1 -path "/services/capture" -method "GET"

GET SESSION
.\NetMon.ps1 -path "/session/577c3ef6-cca3-41d7-a4cd-81783dfbd292" -session "577c3ef6-cca3-41d7-a4cd-81783dfbd292" -method "GET"

GET SESSION FILES
.\NetMon.ps1 -path "/session/577c3ef6-cca3-41d7-a4cd-81783dfbd292/files" -session "577c3ef6-cca3-41d7-a4cd-81783dfbd292" -method "GET" -outFile "files.zip"

.PARAMETER action


.NOTES
June 2017 @chrismartin

.LINK
https://github.com/lrchma/

#>



param(

[Parameter(Mandatory=$false)]
[string]$acctname = '',

[Parameter(Mandatory=$false)]
[string]$password = '',

[Parameter(Mandatory=$false)]
[string]$url = '',

[Parameter(Mandatory=$false)]
[string]$path ='',

[Parameter(Mandatory=$false)]
[string]$method = '',

[Parameter(Mandatory=$false)]
[string]$session = '',

#Not currently used.  Think on this as otherwise changes require two SRs.
[Parameter(Mandatory=$false)]
[string]$applychangesnow = 'false',

[Parameter(Mandatory=$false)]
[string]$application = '',

[Parameter(Mandatory=$false)]
[string]$outFile = '',

[Parameter(Mandatory=$false)]
[string]$ignoreCert = 'true'

)


#This script use Invoke-RestMethod which only comes with PowerShell 3.0 of higher.
if ($PSVersionTable.PSVersion -lt [Version]"3.0") {
  write-host "PowerShell version " $PSVersionTable.PSVersion "not supported.  This script requires PowerShell 3.0 or greater." -ForegroundColor Red
  exit
}

#Required for ignorning seld certs and suppressing error messages
function Ignore-SelfSignedCerts
{
    try
    {
        Write-Host "Adding TrustAllCertsPolicy type." -ForegroundColor White
        Add-Type -TypeDefinition  @"
        using System.Net;
        using System.Security.Cryptography.X509Certificates;
        public class TrustAllCertsPolicy : ICertificatePolicy
        {
             public bool CheckValidationResult(
             ServicePoint srvPoint, X509Certificate certificate,
             WebRequest request, int certificateProblem)
             {
                 return true;
            }
        }
"@
        Write-Host "TrustAllCertsPolicy type added." -ForegroundColor White
      }
    catch
    {
        Write-Host $_ -ForegroundColor "Yellow"
    }
    [System.Net.ServicePointManager]::CertificatePolicy = New-Object TrustAllCertsPolicy
}


#Force TLS1.2 as that's needed but used by default
[Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12


#Disable Certificate validation
if($ignoreCert = "true"){
    Ignore-SelfSignedCerts
}

##########################################################################################
<#
Each PUT or POST method requires a custom Body payload for the matching Object type
#>

#addCapturedApplications
$addCapturedApplications = @{
    "addToCaptureList" = 
    @(
        "$application"
    )
}


#addExcludedApplications
$addExcludedApplications = @{
    "addToExcludeList" = 
    @(
        "$application"
    )
}

#removeCapturedApplications
$removeCapturedApplications = @{
    "removeFromCaptureList" = 
    @(
        "$application"
    )
}


#removeExcludedApplications
$removeExcludedApplications = @{
    "removeFromExcludeList" = 
    @(
        "$application"
    )
}

#ConfigureCapture
$capture = @{
    "captureAll" = 
    @(
        "True"
    )
}

#ListOfServicesToRestart
$services = @{
    "services" = 
    @(
       "probereader", "probelogger"
    )
}

#SessionList (Download PCAP)
$sessions = @{
    "sessions" = 
    @(
       "$session"
    )
}

##############################################################################################
<#
Call API
#>

try{

#Params passes across arguments to the Invoke-RestMethod.  If using a HTTP POST method then includes custom Message body
$params = @{uri = $url + $path;
                    Method = $method;
                    Headers = @{Authorization = 'Basic ' + [Convert]::ToBase64String([Text.Encoding]::ASCII.GetBytes("$($acctname):$($password)"));};
                    ContentType =  'application/json';
                    Body = switch ($path) { 
                                "/services/capture/actions/addCapturedApplications" 
                                    {ConvertTo-Json $addCapturedApplications} 
                                "/services/capture/actions/addExcludedApplications"
                                    {ConvertTo-Json $addExcludedApplications} 
                                "/services/capture/actions/removeCapturedApplications"
                                    {ConvertTo-Json $removeCapturedApplications} 
                                "/services/capture/actions/removeExcludedApplications"
                                    {ConvertTo-Json $removeExcludedApplications}
                                "/pcap/action/download"
                                    {ConvertTo-Json $sessions}
                                "/services/actions/restart"
                                    {ConvertTo-Json $services}
                                
                                "/services/capture"
                                    {
                                    switch ($method)
                                                {
                                                    "get" {
                                                    }
                                                    "put" {
                                                      ConvertTo-Json $capture                                                     }
                                                    }
               
                                    }
                                    "default" {}
                                 }
                 
            } 


write-host "Calling: " $url$path


$var = invoke-restmethod @params 

#Switch block used to handle the output from each API call, and format output accordingly
switch ($path)
{
    #GET - WORKING
    "/applications" 
        {write-host $method $path; write-host $var -ForegroundColor "Green"; write-host "Applications: " $var.applications};
    
    #GET/PUT - WORKING/NOT WORKING (true is no acceptabed as Boolean?)
    "/services/capture" 
        {
            switch ($method)
            {
                "get" {
                    write-host $method $path; write-host $var -ForegroundColor "Green"; write-host "Capture all: " $var.captureAll; write-host "Captured applications: "$var.capturedApplications; write-host "Excluded applications: "$var.excludedApplications;
                }
                "put" {
                    write-host $method $path; write-host $var -ForegroundColor "Green"; write-host "Capture all: " $var.captureAll; write-host "Captured applications: "$var.capturedApplications; write-host "Excluded applications: "$var.excludedApplications;
                }
            }
        }
    
   
    #GET - WORKING
    "/session/$session/files" 
        {$var = invoke-restmethod @params -outfile "$outFile"; 
        write-host $method $path; 
        write-host '{"statuscode":200, "message":"OK"}' -ForegroundColor "Green";}

    #GET - WORKING
    "/session/$session" 
        {write-host $method $path; 
         write-host $var -ForegroundColor "Green";}

    
    #GET - WORKING
    "/systemInfo" 
        {write-host $method $path; write-host $var -ForegroundColor "Green"; }  
    
    #POST - WORKING
    "/pcap/action/download" 
        {$var = invoke-restmethod @params -outfile "$outFile"; 
        write-host $method $path; 
        write-host '{"statuscode":200, "message":"OK"}' -ForegroundColor "Green";
    }

    #PUT - WORKING
    "/services/capture/actions/addCapturedApplications" 
        {write-host $method $path; write-host $var -ForegroundColor "Green"; write-host "Capture all: " $var.captureAll; write-host "Captured applications: "$var.capturedApplications; write-host "Excluded applications: "$var.excludedApplications;}

    "/services/capture/actions/addExcludedApplications" 
        {write-host $method $path; write-host $var -ForegroundColor "Green"; write-host "Capture all: " $var.captureAll; write-host "Captured applications: "$var.capturedApplications; write-host "Excluded applications: "$var.excludedApplications;}

    "/services/capture/actions/removeCapturedApplications" 
        {write-host $method $path; write-host $var -ForegroundColor "Green"; write-host "Capture all: " $var.captureAll; write-host "Captured applications: "$var.capturedApplications; write-host "Excluded applications: "$var.excludedApplications;}

    "/services/capture/actions/removeExcludedApplications" 
        {write-host $method $path; write-host $var -ForegroundColor "Green"; write-host "Capture all: " $var.captureAll; write-host "Captured applications: "$var.capturedApplications; write-host "Excluded applications: "$var.excludedApplications;}
    
    #PUT - WORKING
    "/services/actions/restart" 
        {write-host $method $path; write-host $var -ForegroundColor "Green"; write-host "Message: " $var.message}

    #PUT - WORKING (SUPER HIDDEN API CALL)
    "/application" 
        {write-host $method $path; write-host $var -ForegroundColor "Green";}

    "default" {}
}

#Exception catches all HTTP error responses
}catch{
    Write-Host $_.ToString() -ForegroundColor "Red"
}








