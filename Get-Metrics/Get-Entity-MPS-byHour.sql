-- Get MPS for last hour, in hourly bucket, in UTC timezone 
SELECT stats.statdate AS Date, 
       entity.name AS Entity, 
       ( Sum(Stats.countlogs) / 3600 ) AS Count 
FROM   [LogRhythm_LogMart].[dbo].[statssystemmonitorcountshour] Stats 
       INNER JOIN [LogRhythmEMDB].[dbo].[systemmonitor] SM 
               ON SM.systemmonitorid = Stats.systemmonitorid 
       INNER JOIN [LogRhythmEMDB].[dbo].[host] Host 
               ON host.hostid = SM.hostid 
       INNER JOIN [LogRhythmEMDB].[dbo].[entity] Entity 
               ON host.entityid = entity.entityid 
WHERE  Stats.statdate > Dateadd(minute, -61, Getutcdate()) --use 120 as the latest hourly bucket may not be availble if =<60
GROUP  BY Stats.statdate, 
          entity.NAME 
ORDER  BY Stats.statdate DESC 

/**

Date	Entity	Count
2017-08-21 15:00:00	LR Ops	1
2017-08-21 15:00:00	LR SDE	48
2017-08-21 15:00:00	POS	0

**/