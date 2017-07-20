SELECT (SUM(Stats.CountLogs) / 3600) AS Count, Stats.StatDate, Entity.Name
FROM [LogRhythm_LogMart].[dbo].[StatsSystemMonitorCountsHour] Stats
INNER JOIN [LogRhythmEMDB].[dbo].[SystemMonitor] SM
ON SM.SystemMonitorID = Stats.SystemMonitorID
INNER JOIN [LogRhythmEMDB].[dbo].[Host] Host
ON Host.HostID = SM.HostID
INNER JOIN [LogRhythmEMDB].[dbo].[Entity] Entity
ON Host.EntityID = Entity.EntityID
WHERE Stats.StatDate > DATEADD(minute, -3600, GETUTCDATE())
GROUP BY Stats.StatDate, Entity.Name
ORDER BY Stats.StatDate DESC