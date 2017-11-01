
param(
  [Parameter(Mandatory=$false)]
  [string]$serverName = '.',
  [Parameter(Mandatory=$false)]
  [string]$outFile = 'c:\temp\sm.csv'
)


#Check SQL PoSH snapins are loaded, if not then load them
if ( (Get-PSSnapin -Name SqlServerCmdletSnapin100 -ErrorAction SilentlyContinue) -eq $null )
{
    Add-PsSnapin SqlServerCmdletSnapin100
}

if ( (Get-PSSnapin -Name SqlServerProviderSnapin100 -ErrorAction SilentlyContinue) -eq $null )
{
    Add-PsSnapin Add-PSSnapin SqlServerProviderSnapin100

}


try  

{  

$sqlQuery = @"
/****** Script for SelectTopNRows command from SSMS  ******/
SELECT TOP 100 [StatsSystemMonitorCountsMinuteID]
      ,[StatDate]
      ,B.Name AS Mediator
      ,A.Name AS SystemMonitor
      ,[CountLogs]
      ,[CountProcessedLogs]
      ,[CountOnlineLogs]
      ,[HostsCollectedFrom]
  FROM [LogRhythm_LogMart].[dbo].[StatsSystemMonitorCountsMinute]
  INNER JOIN [LogRhythmEMDB].[dbo].[SystemMonitor] AS A
	ON [LogRhythm_LogMart].[dbo].[StatsSystemMonitorCountsMinute].[SystemMonitorID] = A.SystemMonitorID
  INNER JOIN [LogRhythmEMDB].[dbo].[Mediator] AS B
	ON [LogRhythm_LogMart].[dbo].[StatsSystemMonitorCountsMinute].[MediatorID] = B.MediatorID
  WHERE StatDate > DATEADD(minute, -2, GETUTCDATE()) 
  ORDER BY StatsSystemMonitorCountsMinuteID DESC
"@

$sqlServer = "."


$ds = Invoke-Sqlcmd -Query $sqlQuery -ServerInstance $sqlServer 

$ds | Export-Csv $outFile -NoType


}
catch [System.SystemException] {
$_ 
}