
param(
  [Parameter(Mandatory=$false)]
  [string]$serverName = '.',
  [Parameter(Mandatory=$false)]
  [string]$outFile = 'index.html',
  [Parameter(Mandatory=$false)]
  [string]$outFilePath = '  C:\nginx-1.13.2\html\' #Include trailing path, else be less of a lazy coder and run a check
)

#ISE Testing - used when testing with ISE to remove historical stuff
#Remove-Variable counter
#Remove-Variable LOCALTIME
#Remove-Variable UTCTIME

#Check SQL PoSH snapins are loaded, if not then load them.  These are needed to query LogMart and EMDB for LR metric
if ( (Get-PSSnapin -Name SqlServerCmdletSnapin100 -ErrorAction SilentlyContinue) -eq $null )
{   Add-PsSnapin SqlServerCmdletSnapin100  }

if ( (Get-PSSnapin -Name SqlServerProviderSnapin100 -ErrorAction SilentlyContinue) -eq $null )
{   Add-PsSnapin SqlServerProviderSnapin100  }


try  

{  

    
$LRInstallName = "Production 7.2.x"              #summary name for the LR environment, e.g., Prod or Test
$LOCALTIME = (get-date)                          #
$UTCTIME = (get-date).ToUniversalTime()          #
$outFilePath = "C:\nginx-1.13.2\html\"           #filename for the html weathermap
$outFile = "index.html"                          #path to write the html weathermap

#the output html weathermap file
$outPutFile = $outFilePath + $outFile

#if the weathermap exists, delete it
if (Test-Path -Path $outputfile){
    remove-item $outputfile}


### SQL Server - A dot represents the localhost.
$sqlServer = "."

### Authentication ###
# At this time auth uses Windows pass-thru, ensure account running scripts has connect and query permissions

### Used to increment unique Node IDs through the weathermap and for building relationships betweeen nodes and edges
$counter = 1


<#
PLATFORM MANAGER - Select only active PMs
#>

#Get PM Name & ID
$sqlQuery = @"
SELECT A.[HostID] AS HostID
	  ,H.[Name] AS Name
      ,[LastHeartbeat] AS LastHeartBeat
FROM [LogRhythmEMDB].[dbo].[ARM] AS A
INNER JOIN [LogRhythmEMDB].[dbo].[Host] AS H
ON H.HostID = A.HostID
WHERE A.[RecordStatus] = 1
"@

$ds = Invoke-Sqlcmd -Query $sqlQuery -ServerInstance $sqlServer 

#Get PM EPS & DP MPS
$sqlQuerya = @"
DECLARE @MINUTE DECIMAL(2)
SET @MINUTE = 60;
SELECT TOP 1 * From
(SELECT TOP 2 [StatsDeploymentCountsMinuteID]
	,[StatDate]
      ,CAST(ROUND([CountLogs] / @MINUTE,2) AS NUMERIC(36,2)) AS CountLogs
      ,CAST(ROUND([CountProcessedLogs] / @MINUTE,2) AS NUMERIC(36,2)) AS  CountProcessedLogs
      ,CAST(ROUND([CountIdentitfiedLogs] / @MINUTE,2) AS NUMERIC(36,2)) AS CountIdentifiedLogs
      ,CAST(ROUND([CountArchivedLogs] / @MINUTE,2) AS NUMERIC(36,2)) AS CountArchivedLogs
      ,CAST(ROUND([CountOnlineLogs] / @MINUTE,2) AS NUMERIC(36,2))AS CountOnlineLogs
      ,CAST(ROUND([CountEvents] / @MINUTE,2)  AS NUMERIC(36,2)) CountEvents
      ,CAST(ROUND([CountLogMart] / @MINUTE,2) AS NUMERIC(36,2)) AS CountLogMart
      ,CAST(ROUND([CountAlarms] / @MINUTE,2) AS NUMERIC(36,2)) AS CountAlarms
  FROM [LogRhythm_LogMart].[dbo].[StatsDeploymentCountsMinute]
  ORDER BY [StatsDeploymentCountsMinuteID] DESC) x                     
ORDER BY StatsDeploymentCountsMinuteID
"@

$dsa = Invoke-Sqlcmd -Query $sqlQuerya -ServerInstance $sqlServer 

$components = [ordered]@{}

foreach ($result in $ds){
    $tempComponentName = "PM_$counter"
    $tempHashTable = @{
            $tempComponentName = @{
            type = 'PM'
            id  = $counter
            hostid = $result.HostID
            name = $result.Name
            heartbeat = $result.LastHeartBeat
            eps = $dsa.CountEvents
            }
        }
    $components += $tempHashTable
    $counter = $counter + 1
}


<#
DATA PROCESSOR
Select only active DPs, i.e., not second look or retired
#>

$sqlQuery1 = @"

SELECT M.HostID AS HostID
      ,M.[Name] AS Name
      ,[LastHeartbeat] As LastHeartBeat
      ,[ClusterID] AS ClusterID
FROM [LogRhythmEMDB].[dbo].[Mediator] AS M
INNER JOIN [LogRhythmEMDB].[dbo].[Host] AS H
ON H.HostID = M.HostID
WHERE Status = 1 and Mode = 1

"@

$ds1 = Invoke-Sqlcmd -Query $sqlQuery1 -ServerInstance $sqlServer 

foreach ($result1 in $ds1){
    $tempComponentName = "DP_$counter"
    $tempHashTable1 = @{
            $tempComponentName = @{
            type = 'DP'
            id  = $counter
            hostid = $result.HostID
            name = $result.Name
            heartbeat = $result.LastHeartBeat
            mpsOnline = $dsa.CountOnlineLogs
            mpsCount = $dsa.CountLogs
            }
        }
    $components += $tempHashTable1
    $counter = $counter + 1
}


<#
SYSTEM MONITOR AGENTS
select only active SMs, i.g., not retired/unlicensed
#>
$sqlQuery2 = @"

DECLARE @MINUTE DECIMAL(2)
SET @MINUTE = 60;
SELECT [HostID] AS HostID
      ,[Name] AS Name
      ,SMS.LastHeartbeat AS LastHeartBeat
      ,CAST(ROUND(SMC.CountLogs / @MINUTE,2) AS NUMERIC(36,2)) AS CountLogs
  FROM [LogRhythmEMDB].[dbo].[SystemMonitor] AS S
  INNER JOIN [LogRhythmEMDB].[dbo].[SystemMonitorStatus] AS SMS
  ON S.SystemMonitorID = SMS.SystemMonitorID
  CROSS APPLY
  (
	SELECT TOP 1 [SystemMonitorID],[CountLogs]
	FROM [LogRhythm_LogMart].[dbo].[StatsSystemMonitorCountsMinute]
	WHERE [SystemMonitorID] = S.SystemMonitorID
  ) SMC
    WHERE SystemMonitorType = 1
    ORDER BY HostID ASC

"@


$ds2 = Invoke-Sqlcmd -Query $sqlQuery2 -ServerInstance $sqlServer 

foreach ($result2 in $ds2){
    $tempComponentName = "SM_$counter"
    $tempHashTable2 = @{
            $tempComponentName = @{
            type = 'SM'
            id  = $counter
            hostid = $result2.HostID
            name = $result2.Name
            heartbeat = $result2.LastHeartBeat
            lps = $result2.CountLogs 
            }
        }
    $components += $tempHashTable2
    $counter = $counter + 1
}


<#
LOG SOURCES
select only active log sources, i.e., exlude system/AIE log sources
#>

$sqlQuery3 = @"

SELECT M.[SystemMonitorID] AS HostID
	  ,SM.[Name]
	  ,MSD.[MaxLogDate] AS LastHeartBeat
	  ,M.[MsgSourceID]
      ,MST.Name AS MsgSourceType
      ,MSC.CountLogs 
  FROM [LogRhythmEMDB].[dbo].[MsgSource] AS M
  INNER JOIN [LogRhythmEMDB].[dbo].[SystemMonitor] AS SM
  ON SM.SystemMonitorID = M.SystemMonitorID
  INNER JOIN [LogRhythmEMDB].[dbo].[MsgSourceType] AS MST
  ON MST.MsgSourceTypeID = M.MsgSourceTypeID
  INNER JOIN [LogRhythmEMDB].[dbo].[MsgSourceMaxLogDate] AS MSD
  ON MSD.MsgSourceID = M.MsgSourceID
  CROSS APPLY
  (
	SELECT TOP 1 [MsgSourceID],[CountLogs]
	FROM [LogRhythm_LogMart].[dbo].[StatsMsgSourceCountsMinute]
	WHERE [MsgSourceID] = M.MsgSourceID
  ) MSC
    WHERE M.[Status] = 1  AND M.MsgSourceTypeID > 0

"@

$ds3 = Invoke-Sqlcmd -Query $sqlQuery3 -ServerInstance $sqlServer 

foreach ($result3 in $ds3){
    $tempComponentName = "LS_$counter"
    $tempHashTable3 = @{
            $tempComponentName = @{
            type = 'LS'
            id  = $counter
            hostid = $result3.HostID
            name = $result3.MsgSourceType
            heartbeat = $result3.LastHeartBeat
            lps = $result3.CountLogs
            }
        }
    $components += $tempHashTable3
    $counter = $counter + 1
}
















#the first block of html
$block1 = @"

<!doctype html>
<html>
<head>
  <title>LogRhythm Weather Map | $LRInstallName</title>

  <script type="text/javascript" src="vis.js"></script>
  <link href="vis-network.min.css" rel="stylesheet" type="text/css" />

  <style type="text/css">
    #mynetwork {
      width: 1600px;
      height: 800px;
      border: 1px solid lightgray;
      background-color:#111112;
    }
  </style>
</head>
<body>

<p>
$LRInstallName Weathermap - UTC: $UTCTIME - localtime: $LOCALTIME.
</p>

<div id="mynetwork" class="centered"></div>

<script type="text/javascript">
  // create an array with nodes
  var nodes = new vis.DataSet([


"@



$block2 = @"

 ]);

  // create an array with edges
  var edges = new vis.DataSet([


"@



$block3 = @"

  ]);

  // create a network
  var container = document.getElementById('mynetwork');
  var data = {
    nodes: nodes,
    edges: edges
  };

var options = {
        nodes: {
            shadow:{
              enabled: true,
              color: '#d7d7d7',
              size:5,
              x:1,
              y:1
            },
            borderWidth: 2,
            font: { size: 20},
            shape: 'box'
		},
		layout: {
          hierarchical: {
            sortMethod: "hubsize"
          }
        },
        physics: {
            enabled: true,
            hierarchicalRepulsion: {
                centralGravity: 0.0,
                springLength: 250,
                springConstant: 0.01,
                nodeDistance: 225,
                damping: 0.09
            },
            solver: 'hierarchicalRepulsion'
        },
        edges: {
          smooth: true,
          arrows: {to : false },
            shadow:{
              enabled: true,
              color: '#255A82',
              size:5,
              x:1,
              y:1
            }
        }
      };
  

  
  var network = new vis.Network(container, data, options);
</script>


</body>
</html>


"@


$block1 | Add-Content $outputfile


#GENERATE ARRAY NODES

foreach($id in $components.keys){
    $component = $components[$id]
    
    #for each component type, write out the Node entries in ordered (PM, DP, SM, LS).  Use temp variable and formatted strings to write each vis.js entry (qwirk with powershell writing out data type rather than value otherwise)
    switch ($component.type)
        {
            PM {  
                if ($component.heartbeat -gt $utctime.AddMinutes(-5)) { #Heartbeat OK
                    $a = "`{{id: {0}, label: '{1}:{2} \n Event Rate: {3}', color: '#8DA05C', font: '24px arial #F7F7F6', level: '0', group: 0, title: '{4}'}}," -f $component.id, $component.type, $component.name, $component.eps, $component.heartbeat
                    Add-Content $outputfile $a
                }elseif($component.heartbeat -gt $utctime.AddMinutes(-10)){ #Hearbeat late
                    $a = "`{{id: {0}, label: '{1}:{2} \n Event Rate: {3}', color: '#DBAE65', font: '24px arial #F7F7F6', level: '0', group: 0, title: '{4}'}}," -f $component.id, $component.type, $component.name, $component.eps, $component.heartbeat
                    Add-Content $outputfile $atctim
                }
                else{ #heartbeat error
                    $a = "`{{id: {0}, label: '{1}:{2} \n Event Rate: {3}', color: '#B45034', font: '24px arial #F7F7F6', level: '0', group: 0, title: '{4}'}}," -f $component.id, $component.type, $component.name, $component.eps, $component.heartbeat
                    Add-Content $outputfile $a
                }

                }           
            DP {  
                $a = "{{id: {0}, label: '{1}:{2} \n Index Rate: {3} \n Receive Rate: {4}', color: '#8DA05C', font: '24px arial #F7F7F6', level: '1', group: 1, title:'{5}'}}," -f $component.id,$component.type,$component.name,$component.mpsOnline,$component.mpsCount, $component.heartbeat
                Add-Content $outputfile $a 
                }

            SM {
                if ($component.heartbeat -gt $utctime.AddMinutes(-5)) { #Heartbeat OK
                $a = "{{id: {0}, label: '{1}:{2} \n Recieve Rate: {3}', color: '#8DA05C', font: '20px arial #F7F7F6', level: '2', group: 2, title:'{4}'}}," -f $component.id,$component.type,$component.name,$component.lps, $component.heartbeat
                Add-Content $outputfile $a
                }elseif($component.heartbeat -gt $utctime.AddMinutes(-10)){ #Hearbeat late
                $a = "{{id: {0}, label: '{1}:{2} \n Recieve Rate: {3}', color: '#DBAE65', font: '20px arial #F7F7F6', level: '2', group: 2, title:'{4}'}}," -f $component.id,$component.type,$component.name,$component.lps, $component.heartbeat
                Add-Content $outputfile $a
                }
                else{ #heartbeat error
                $a = "{{id: {0}, label: '{1}:{2} \n Recieve Rate: {3}', color: '#B45034', font: '20px arial #F7F7F6', level: '2', group: 2, title:'{4}'}}," -f $component.id,$component.type,$component.name,$component.lps, $component.heartbeat
                Add-Content $outputfile $a
                }



                } 
            #LS {  
            #    write-host "{id: "$component.id", label: '" $component.type"\n"$component.name"\n"$component.lps"LPS', color: '#007DC3', shape: 'box', level: '3', group: 3}," 
            #    }           
        }
}

#these comments are used as an anchor for finding and replacing the trailing comma on the javascript array
Add-Content $outputfile "//End of Node Array"


#GENERATE EDGES
$block2 | Add-Content $outputfile

foreach($id in $components.keys){
    $component = $components[$id]
    
    switch ($component.type)
        {
            PM {  
                    $PM = $component.id
                    foreach($id in $components.keys){
                        $component = $components[$id]                   
                            switch ($component.type) {
                                DP {
                                        $DP = $component.id
                                        $dpMPS = $component.mpsOnline
                                        write-output "{from: $PM, to: $DP,  dashes:[5,5], value: $dpMPS, color: '#007DC3' }," | Add-Content $outputfile
                                     }
                            }
                    }
                }

            DP {  
                    $DP = $component.id
                    foreach($id in $components.keys){
                        $component = $components[$id]                   
                            switch ($component.type) {
                                SM {
                                        $SM = $component.id
                                        $smLPS = $component.lps
                                        write-output "{from: $DP, to: $SM,  dashes:[5,5], value: $smLPS, color: '#007DC3'}," | Add-Content $outputfile
                                     }
                            }


                    }
                     
                }
        #RENAME BACK TO SM TO MAKE WORK
            SMA {  
                    $SM = $component.id
                    foreach($id in $components.keys){
                        $component = $components[$id]                   
                            switch ($component.type) {
                                LS {
                                        $LS = $component.id
                                        $lsLPD = $component.lps
                                        write-output "{from: $SM, to: $LS,  value: $lsLPD}," | Add-Content $outputfile
                                     }
                            }


                    }
                     
                }

        }

}

Add-Content $outputfile "//End of Edge Array"

$block3 | Add-Content $outputfile


sleep 1

#remove trailing comma at Node Array block, its crude but works
$a = Get-Content -Path $outputfile
$b = dir $outFilePath -filter *.html -recurse | select-string -Pattern '//End of Node Array' | select Line,LineNumber,Filename
[int]$c = $b.LineNumber
$d = ($c -2)
$e = Get-Content $outputfile | Select -Index ($d) 
$f  = $e.TrimEnd(',')
$a[$d] = $f
$a | Set-Content -Path $outputfile

sleep 1

#remove trailing comma at Edge Array block, its crude but works
$a = Get-Content -Path $outputfile
$b = dir $outFilePath -filter *.html -recurse | select-string -Pattern '//End of Edge Array' | select Line,LineNumber,Filename
[int]$c = $b.LineNumber
$d = ($c -2)
$e = Get-Content $outputfile | Select -Index ($d) 
$f  = $e.TrimEnd(',')
$a[$d] = $f
$a | Set-Content -Path $outputfile


write-host "done"






}
catch [System.SystemException] {
$_ 
}


