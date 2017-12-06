<#

.SYNOPSIS
PowerShell Shim for LogRhythm SmartResponse.

.DESCRIPTION
The LogRhythm Shim SmartResponse sits between LogRhythm and any existing PowerShell scripts you may have, enabling you to modify and create new scripts without having to re-compile or alter AIE rules. 

.EXAMPLE
\LR-SR-Shim.ps1 -paramCount 1 -param1 "param1"
\LR-SR-Shim.ps1 -paramCount 2 -param1 "param1" -param2 "param 2" -debugMode 1

.NOTES
The LogRhythm Shim SmartResponse enables you to call any PowerShell script with up to 9 arguments via the Invoke-Expression cmdlet.  The advantage of using this approach is that you can make changes to your scripts without need to recompile or edit your SmartResponse or AI Engine Alarms.  The disadvantage to this approach is your scripts will not be automatically copied to the host executing the SmartResponse, but this just requires you specify the full path, a UNC path, or else you can look to include the scripts being called by the Shim within the Shim SmartResponse.  Finally, while every effort is made for security, this script does use the invoke-expression cmdlet which has security concerns - please consider or review this to ensure that's acceptable for you before using.

Note, This isn't an official LogRhythm SmartResponse.

.LINK
@chrismartinit - https://github/lrchma

#>

[CmdletBinding()]
Param(
  [Parameter(Mandatory=$True,Position=1)]
   [string]$targetScript,

  [Parameter(Mandatory=$True,Position=2)]
   [int]$paramCount,
	
   [Parameter(Mandatory=$false)]
   [string]$param1,

   [Parameter(Mandatory=$false)]
   [string]$param2,
    
   [Parameter(Mandatory=$false)]
   [string]$param3,

   [Parameter(Mandatory=$false)]
   [string]$param4,
    
   [Parameter(Mandatory=$false)]
   [string]$param5,

   [Parameter(Mandatory=$false)]
   [string]$param6,   
    
   [Parameter(Mandatory=$false)]
   [string]$param7,

   [Parameter(Mandatory=$false)]
   [string]$param8,

   [Parameter(Mandatory=$false)]
   [string]$param9,

   [Parameter(Mandatory=$false)]
   [string]$debugMode                    #Ideally this would be a bool... however, the way powershell is executed causes this to be read in as a string and it all goes pete tong
)


trap [Exception] {
	write-error $("Exception: " + $_)
	exit 1
}


if($debugMode -eq 1){$DebugPreference = "Continue"}else{$DebugPreference = "SilentlyContinue"}

$z = "targetScript:{0} -paramCount:{1} -param1:{2} -param2:{3} -param3:{4} -param4:{5} -param5:{6} -param6:{7} -param7:{8} -param8:{9} -param9:{10}" -f $targetScript, $paramCount, $param1, $param2, $param3, $param4, $param5, $param5, $param6, $param7, $param8, $param9
write-debug $z

<#
LogRhythm SmartResponse will automatically add any parameter as defined in the actions.xml.  
Adding a blank parameter will however prevent cmd.exe calling powershell.
Workaround is specifying the number of parameters, switching the count, carefully encapsulating the arguments and finally invoking.

#>
switch ($paramCount)
    {
      0 {$command = "$targetScript"; Invoke-Expression $command; write-debug $command; "{0},{1}" -f (get-date), $command | Out-File 'c:\temp\debug.log'}
      1 {$command = "$targetScript `"$param1`""; Invoke-Expression $command; write-debug $command; "{0},{1}" -f (get-date), $command | Out-File 'c:\temp\debug.log'}
      2 {$command = "$targetScript `"$param1`" `"$param2`""; Invoke-Expression $command; write-debug $command; "{0},{1}" -f (get-date), $command | Out-File 'c:\temp\debug.log'}
      3 {$command = "$targetScript `"$param1`" `"$param2`" `"$param3`""; Invoke-Expression $command; write-debug $command; "{0},{1}" -f (get-date), $command | Out-File 'c:\temp\debug.log'}
      4 {$command = "$targetScript `"$param1`" `"$param2`" `"$param3`" `"$param4`""; Invoke-Expression $command; write-debug $command; "{0},{1}" -f (get-date), $command | Out-File 'c:\temp\debug.log'}
      5 {$command = "$targetScript `"$param1`" `"$param2`" `"$param3`" `"$param4`" `"$param5`""; Invoke-Expression $command; write-debug $command; "{0},{1}" -f (get-date), $command | Out-File 'c:\temp\debug.log'}
      6 {$command = "$targetScript `"$param1`" `"$param2`" `"$param3`" `"$param4`" `"$param5`" `"$param6`""; Invoke-Expression $command; write-debug $command; "{0},{1}" -f (get-date), $command | Out-File 'c:\temp\debug.log'}
      7 {$command = "$targetScript `"$param1`" `"$param2`" `"$param3`" `"$param4`" `"$param5`" `"$param6`" `"$param7`""; Invoke-Expression $command; write-debug $command; "{0},{1}" -f (get-date), $command | Out-File 'c:\temp\debug.log'}
      8 {$command = "$targetScript `"$param1`" `"$param2`" `"$param3`" `"$param4`" `"$param5`" `"$param6`" `"$param7`" `"$param8`""; Invoke-Expression $command; write-debug $command; "{0},{1}" -f (get-date), $command | Out-File 'c:\temp\debug.log'}
      9 {$command = "$targetScript `"$param1`" `"$param2`" `"$param3`" `"$param4`" `"$param5`" `"$param6`" `"$param7`" `"$param8`" `"$param9`""; Invoke-Expression $command; write-debug $command; "{0},{1}" -f (get-date), $command | Out-File 'c:\temp\debug.log'}
      default {"Valid param count is 1 through 9."}
    }


