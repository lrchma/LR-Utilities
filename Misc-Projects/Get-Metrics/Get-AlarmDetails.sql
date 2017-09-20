SELECT TOP 1 [AlarmID]
      ,entity.FullName AS Entity
      ,AlarmRule.Name
      ,[AlarmDate]
      ,Alarm.[DateInserted]
      ,Alarm.[DateUpdated]
      ,[AlarmStatus]
      ,Person.FullName AS Person   
  FROM [LogRhythm_Alarms].[dbo].[Alarm] Alarm
INNER JOIN [LogRhythmEMDB].[dbo].[entity] Entity 
       ON alarm.entityid = entity.entityid 
INNER JOIN [LogRhythmEMDB].[dbo].[alarmrule] AlarmRule
       ON alarmrule.AlarmRuleID= alarm.AlarmRuleID
LEFT JOIN [LogRhythmEMDB].[dbo].[Person] Person --person may not exist, i.e. be Null,, use left join
       ON person.PersonID = Alarm.LastPersonID
WHERE DateInserted >= DateAdd(mm, -1, GETUTCDATE())