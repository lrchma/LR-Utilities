SELECT Stats.StatDate
	   ,Entity.FullName
       ,(SUM(Stats.CountLogs) / 3600) AS MPS
FROM [LogRhythm_LogMart].[dbo].[StatsMsgSourceCounts] Stats
INNER JOIN [LogRhythmEMDB].[dbo].[MsgSource] Msg
ON Msg.MsgSourceID = Stats.MsgSourceID
INNER JOIN [LogRhythmEMDB].[dbo].[Host] Host
ON Host.HostID = Msg.HostID
INNER JOIN [LogRhythmEMDB].[dbo].[Entity] Entity
ON Host.EntityID = Entity.EntityID
WHERE Stats.StatDate > '2017-01-01 00:00:00' AND Stats.StatDate < '2017-01-06 00:00:00' 
GROUP BY Stats.StatDate, Entity.FullName, DAY(Stats.StatDate)
ORDER BY Stats.StatDate DESC
