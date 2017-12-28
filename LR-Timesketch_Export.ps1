#requires -version 3
<#
.SYNOPSIS
  Formats LogRhythm WebUI CSV export into usable format by TimeSketch

.DESCRIPTION
  Formats LogRhythm WebUI CSV export into usable format by TimeSketch.  Does work on assumption you're using American style dates (which is to say, the least sensical date format that ever was).

.PARAMETER <Parameter_Name>
    -inputFile = LogRhythm WebUI CSV Export.  Metadata and Raw Log
    -outputFile = The TimeSketch formated CSV export

.INPUTS
    LogRhythm WebUI CSV Export, including raw logs AND metadata

.OUTPUTS
    TimeSketch CSV to user defined location

.NOTES
  Version:        1.0
  Author:         @chrismartinit
  Creation Date:  Dec 2017
  Purpose/Change: Initial script development
  
.EXAMPLE
  .\LR_TimeSketch_Export -inputFile "c:\temp\12_28_2017-LogRhythm_WebLogsExport.csv" -outputFile "c:\temp\lr-ts-12-28-2017.csv"

#>


[CmdletBinding()]
Param(
  [Parameter(Mandatory=$True,Position=1)]
   [string]$inputFile,
	
   [Parameter(Mandatory=$True,Position=2)]
   [string]$outputFile
)

#---------------------------------------------------------[Initialisations]--------------------------------------------------------

#Set Error Action to Silently Continue
$ErrorActionPreference = "SilentlyContinue"

#----------------------------------------------------------[Declarations]----------------------------------------------------------


#-----------------------------------------------------------[Execution]------------------------------------------------------------

$csvOutput = @()

if(test-path -Path $inputFile){

    write-debug "Input file successfully found."
    $tempCsv = Import-Csv $inputFile

}else{

    write-warning "Input file not found.  Exiting."
    exit
}


foreach($row in $tempCsv){
 
    #Convert from shortdate format to ISO8601 ish format
    $isoDateTime = [datetime]::ParseExact($row.'Log Date', "MM/dd/yyyy h:mm:ss tt", $null) | get-date -format s
    
    $thisRow = New-Object System.Object

    $thisRow | Add-Member -type NoteProperty -name message -value $row.'Log Message'
    $thisRow | Add-Member -type NoteProperty -name timestamp -value $row.'First Log Date'
    $thisRow | Add-Member -type NoteProperty -name datetime -value $isoDateTime
    $thisRow | Add-Member -type NoteProperty -name timestamp_desc -value "UTC Write Time"

    $thisRow | Add-Member -type NoteProperty -name classification -value $row.Classification
    $thisRow | Add-Member -type NoteProperty -name common_event -value $row.'Common Event'
    $thisRow | Add-Member -type NoteProperty -name mpe_regex_rule -value $row.'MPE Rule Name'

    $thisRow | Add-Member -type NoteProperty -name log_source_type -value $row.'Log Source Type'
    $thisRow | Add-Member -type NoteProperty -name log_source_name -value $row.'Log Source'

    $thisRow | Add-Member -type NoteProperty -name vendor_message_id -value $row.'Vendor Message ID'

    $thisRow | Add-Member -type NoteProperty -name user_origin -value $row.'User (Origin)'
    $thisRow | Add-Member -type NoteProperty -name user_impacted -value $row.'User (Impacted)'

    $thisRow | Add-Member -type NoteProperty -name host_origin -value $row.'Host (Origin)'
    $thisRow | Add-Member -type NoteProperty -name host_impacted -value $row.'Host (Impacted)'
    $thisRow | Add-Member -type NoteProperty -name ip_origin -value $row.'IP Address (Origin)'
    $thisRow | Add-Member -type NoteProperty -name ip_impacted -value $row.'IP Address (Impacted)'

    $thisRow | Add-Member -type NoteProperty -name location_origin -value $row.'Country (Origin)'
    $thisRow | Add-Member -type NoteProperty -name location_impacted -value $row.'Country (Impacted)'

    $csvOutput += $thisRow
       
}


$csvOutput | export-csv -Path $outputFile -NoTypeInformation

if(test-path -Path $outputFile){
    write-output "$inputFile successfully exported to $inputFile."
}