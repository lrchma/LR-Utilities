<#
.NAME
LR-ServiceManagement

.SYNOPSIS
Utility to manage LogRhythm Services

.DESCRIPTION
Used to set LR services to start automatically, and either start or stop all LogRhythm services.  During first install, or after upgrades, LogRhythm services can be set back to manual.  This script helps fix that quickly rather than doing it one by one.
100% unofficial.  If it were possible to have more than 100% it'd be in that range!

.EXAMPLE
./LR-Services -action startall
./LR-Services -action stopall
./LR-Services -action autostartup

.PARAMETER action

.NOTES
June 2017 @chrismartin

.LINK
https://github.com/lrchma/

#>
    
param(
  [Parameter(Mandatory=$true)]
  [string]$action
)


################################################################################
# MAIN
################################################################################


$lrservices = @("LRAIEComMgr","LRAIEEngine","lr-allconf","lr-anubis","lr-bulldozer","lr-carpenter","lr-columbo","lr-configserver","lr-consul-template","lr-denorm","lr-elasticsearch","lr-godispatch","lr-gomaintain","lr-grafana","lr-heartthrob","lr-influxdb","lrjobmgr","lr-spawn","lr-transporter","lr-vitals","lr-watchtower","LogRhythmAdminAPI","LogRhythmAIEngineCacheDrilldown","LogRhythmAPIGateway","LogRhythmAuthenticationAPI","LogRhythmCaseAPI","LogRhythmNotificationService","LogRhythmServiceRegistry","LogRhythmSQLService","LogRhythmThreatIntelligenceAPI","LogRhythmWebConsoleAPI","LogRhythmWebConsoleUI","LogRhythmWebIndexer","LogRhythmWebServicesHostAPI","LogRhythmWindowsAuthenticationService","scmedsvr","scarm")

try{

    switch ($action){
     startall
      {
        foreach ($service in $lrservices){
         Start-Service $service
         "{0} started" -f $service
        }
      }
      stopall
      {
        foreach ($service in $lrservices){
         Stop-Service $service
         "{0} stopped" -f $service
        }
      }
      autostartup
      {
        foreach ($service in $lrservices){
            Set-Service $service -startuptype "automatic"
            "{0} set to start-up type automatic" -f $service
        }
      }
 
    }
}catch{
    $ErrorMessage = $_.Exception.Message
    write-output $ErrorMessage 
}