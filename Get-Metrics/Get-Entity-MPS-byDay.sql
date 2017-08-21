-- Get MPS in hourly buckets for the last 24 hours, in UTC (not local timezone)
SELECT Stats.statdate, 
       entity.fullname, 
       ( Sum(Stats.countlogs) / 3600 ) AS MPS 
FROM   [LogRhythm_LogMart].[dbo].[statsmsgsourcecounts] Stats 
       INNER JOIN [LogRhythmEMDB].[dbo].[msgsource] Msg 
               ON Msg.msgsourceid = Stats.msgsourceid 
       INNER JOIN [LogRhythmEMDB].[dbo].[host] Host 
               ON host.hostid = Msg.hostid 
       INNER JOIN [LogRhythmEMDB].[dbo].[entity] Entity 
               ON host.entityid = entity.entityid 
WHERE Stats.statdate >= DateAdd(hh, -24, GETUTCDATE()) 
GROUP  BY Stats.statdate, 
          entity.fullname, 
          Day(Stats.statdate) 
ORDER  BY Stats.statdate DESC 

/**

statdate	fullname	MPS
2017-08-21 14:00:00	POS	4
2017-08-21 14:00:00	Primary Site/LR Ops	999
2017-08-21 14:00:00	Primary Site/LR SDE	1
2017-08-21 13:00:00	POS	4
2017-08-21 13:00:00	Primary Site/LR Ops	1046
2017-08-21 13:00:00	Primary Site/LR SDE	0
2017-08-21 12:00:00	POS	4
2017-08-21 12:00:00	Primary Site/LR Ops	1045
2017-08-21 12:00:00	Primary Site/LR SDE	0
2017-08-21 11:00:00	POS	4
2017-08-21 11:00:00	Primary Site/LR Ops	1046
2017-08-21 11:00:00	Primary Site/LR SDE	0
2017-08-21 10:00:00	POS	4
2017-08-21 10:00:00	Primary Site/LR Ops	1053
2017-08-21 10:00:00	Primary Site/LR SDE	0
2017-08-21 09:00:00	POS	5
2017-08-21 09:00:00	Primary Site/LR Ops	1046
2017-08-21 09:00:00	Primary Site/LR SDE	0
2017-08-21 08:00:00	POS	4
2017-08-21 08:00:00	Primary Site/LR Ops	1044
2017-08-21 08:00:00	Primary Site/LR SDE	0
2017-08-21 07:00:00	POS	4
2017-08-21 07:00:00	Primary Site/LR Ops	1047
2017-08-21 07:00:00	Primary Site/LR SDE	0
2017-08-21 06:00:00	POS	4
2017-08-21 06:00:00	Primary Site/LR Ops	1045
2017-08-21 06:00:00	Primary Site/LR SDE	0
2017-08-21 05:00:00	POS	4
2017-08-21 05:00:00	Primary Site/LR Ops	1052
2017-08-21 05:00:00	Primary Site/LR SDE	0
2017-08-21 04:00:00	POS	4
2017-08-21 04:00:00	Primary Site/LR Ops	1045
2017-08-21 04:00:00	Primary Site/LR SDE	0
2017-08-21 03:00:00	POS	4
2017-08-21 03:00:00	Primary Site/LR Ops	1041
2017-08-21 03:00:00	Primary Site/LR SDE	0
2017-08-21 02:00:00	POS	4
2017-08-21 02:00:00	Primary Site/LR Ops	1045
2017-08-21 02:00:00	Primary Site/LR SDE	0
2017-08-21 01:00:00	POS	4
2017-08-21 01:00:00	Primary Site/LR Ops	1048
2017-08-21 01:00:00	Primary Site/LR SDE	0
2017-08-21 00:00:00	POS	4
2017-08-21 00:00:00	Primary Site/LR Ops	1044
2017-08-21 00:00:00	Primary Site/LR SDE	0
2017-08-20 23:00:00	POS	4
2017-08-20 23:00:00	Primary Site/LR Ops	1047
2017-08-20 23:00:00	Primary Site/LR SDE	0
2017-08-20 22:00:00	POS	4
2017-08-20 22:00:00	Primary Site/LR Ops	1048
2017-08-20 22:00:00	Primary Site/LR SDE	0
2017-08-20 21:00:00	POS	4
2017-08-20 21:00:00	Primary Site/LR Ops	1060
2017-08-20 21:00:00	Primary Site/LR SDE	1
2017-08-20 20:00:00	POS	4
2017-08-20 20:00:00	Primary Site/LR Ops	1043
2017-08-20 20:00:00	Primary Site/LR SDE	0
2017-08-20 19:00:00	POS	4
2017-08-20 19:00:00	Primary Site/LR Ops	1046
2017-08-20 19:00:00	Primary Site/LR SDE	0
2017-08-20 18:00:00	POS	6
2017-08-20 18:00:00	Primary Site/LR Ops	1054
2017-08-20 18:00:00	Primary Site/LR SDE	0
2017-08-20 17:00:00	POS	4
2017-08-20 17:00:00	Primary Site/LR Ops	1048
2017-08-20 17:00:00	Primary Site/LR SDE	0
2017-08-20 16:00:00	POS	4
2017-08-20 16:00:00	Primary Site/LR Ops	1046
2017-08-20 16:00:00	Primary Site/LR SDE	0
2017-08-20 15:00:00	POS	5
2017-08-20 15:00:00	Primary Site/LR Ops	1050
2017-08-20 15:00:00	Primary Site/LR SDE	0

**/