# ##############################
# Functions

function now(){
    get-date -Format s
}


# ##############################
# Variables

$debugMode = 1


# ##############################
# Main

if($debugMode -eq 1){$DebugPreference = "Continue"}else{$DebugPreference = "SilentlyContinue"}

<#

$MPERules = @("https://raw.githubusercontent.com/lrchma/LR-LogSources/master/MS%20Sysmon%20XML/MPE%20Rules/VMID%201%20-%20Process%20Create%20-%20Pattern%201%20.xml",
"https://raw.githubusercontent.com/lrchma/LR-LogSources/master/MS%20Sysmon%20XML/MPE%20Rules/VMID%201%20-%20Process%20Create%20-%20Pattern%202.xml",
"https://raw.githubusercontent.com/lrchma/LR-LogSources/master/MS%20Sysmon%20XML/MPE%20Rules/VMID%2010%20-%20Process%20Accesed.xml",
"https://raw.githubusercontent.com/lrchma/LR-LogSources/master/MS%20Sysmon%20XML/MPE%20Rules/VMID%2011%20-%20File%20Created.xml",
"https://raw.githubusercontent.com/lrchma/LR-LogSources/master/MS%20Sysmon%20XML/MPE%20Rules/VMID%2012%20-%20Registry%20Object%20Added%20or%20Deleted.xml",
"https://raw.githubusercontent.com/lrchma/LR-LogSources/master/MS%20Sysmon%20XML/MPE%20Rules/VMID%2013%20-%20Registry%20Value%20Set.xml"
"https://raw.githubusercontent.com/lrchma/LR-LogSources/master/MS%20Sysmon%20XML/MPE%20Rules/VMID%2014%20-%20Registry%20Object%20Renamed.xml",
"https://raw.githubusercontent.com/lrchma/LR-LogSources/master/MS%20Sysmon%20XML/MPE%20Rules/VMID%2015%20-%20File%20Stream%20Created.xml",
"https://raw.githubusercontent.com/lrchma/LR-LogSources/master/MS%20Sysmon%20XML/MPE%20Rules/VMID%2016%20-%20Sysmon%20Config%20State%20Changed.xml",
"https://raw.githubusercontent.com/lrchma/LR-LogSources/master/MS%20Sysmon%20XML/MPE%20Rules/VMID%2017%20-%20Named%20Pipe%20Created.xml",
"https://raw.githubusercontent.com/lrchma/LR-LogSources/master/MS%20Sysmon%20XML/MPE%20Rules/VMID%2018%20-%20Named%20Pipe%20Connected.xml",
"https://raw.githubusercontent.com/lrchma/LR-LogSources/master/MS%20Sysmon%20XML/MPE%20Rules/VMID%202%20-%20File%20Creation%20Time%20Changed.xml",
"https://raw.githubusercontent.com/lrchma/LR-LogSources/master/MS%20Sysmon%20XML/MPE%20Rules/VMID%203%20-%20Network%20connection%20detected.xml",
"https://raw.githubusercontent.com/lrchma/LR-LogSources/master/MS%20Sysmon%20XML/MPE%20Rules/VMID%204%20-%20Sysmon%20Service%20State%20Changed.xml",
"https://raw.githubusercontent.com/lrchma/LR-LogSources/master/MS%20Sysmon%20XML/MPE%20Rules/VMID%205%20-%20Process%20Terminated.xml",
"https://raw.githubusercontent.com/lrchma/LR-LogSources/master/MS%20Sysmon%20XML/MPE%20Rules/VMID%206%20-%20Driver%20Loaded.xml",
"https://raw.githubusercontent.com/lrchma/LR-LogSources/master/MS%20Sysmon%20XML/MPE%20Rules/VMID%207%20-%20Image%20Loaded.xml",
"https://raw.githubusercontent.com/lrchma/LR-LogSources/master/MS%20Sysmon%20XML/MPE%20Rules/VMID%208%20-%20Create%20RemoteThread%20Detected.xml",
"https://raw.githubusercontent.com/lrchma/LR-LogSources/master/MS%20Sysmon%20XML/MPE%20Rules/VMID%209%20-%20Raw%20Access%20Read.xml"
)

foreach($rule in $MPERules){
    $WebResponse=Invoke-WebRequest -Uri $Rule -Method Head
    Start-BitsTransfer -Source $WebResponse.BaseResponse.ResponseUri.AbsoluteUri.Replace("%20"," ") -Destination .
    Write-Debug "$(now), Downloaded $Rule"
}

#>

$sqlServer = "."   


# Top MPERuleID
$sqlQuery0a = "SELECT TOP (1) [MPERuleID]
  FROM [LogRhythmEMDB].[dbo].[MPERule]
  ORDER BY MPERuleID DESC"

$ds0a = Invoke-Sqlcmd -Query $sqlQuery0a -ServerInstance $sqlServer -Database "LogRhythmEMDB"

Write-Debug "$(now), MPERuleID:  $($ds0a.MPERuleID)"


# Top MPERuleRegexID
$sqlQuery0b = "SELECT TOP (1) [MPERuleRegexID]
  FROM [LogRhythmEMDB].[dbo].[MPERule]
  ORDER BY MPERuleRegexID DESC"

$ds0b = Invoke-Sqlcmd -Query $sqlQuery0b -ServerInstance $sqlServer -Database "LogRhythmEMDB"

Write-Debug "$(now), MPERuleRegexID: $($ds0b.MPERuleRegexID)"


# Top MsgSourceTypeID
$sqlQuery0c = "SELECT TOP (1) [MsgSourceTypeID]
FROM [LogRhythmEMDB].[dbo].[MPERuleToMsgSourceType]
WHERE MsgSourceTypeID = $($a.ChildNodes.MPERuleToMST.MsgSourceTypeID)
ORDER BY MsgSourceTypeID  DESC"

$ds0c = Invoke-Sqlcmd -Query $sqlQuery0c -ServerInstance $sqlServer -Database "LogRhythmEMDB"

if($ds0c.MsgSourceTypeID){write-debug "$(now), MsgSourceTypeID $($ds0c.MsgSourceTypeID) found."}else{write-debug "$(now), MsgSourceTypeID $($ds0c.MsgSourceTypeID) not found.  Treat as new Log Source"; break}


$NextMPERuleID = $ds0a.MPERuleID + 1
$NextMPERuleRegexID = $ds0b.MPERuleRegexID + 1 


[xml]$a =  Get-Content "C:\Users\Administrator\AppData\Local\Temp\a\VMID 1 - Process Create - Pattern 2.xml"

$sqlQuery1 = "SET XACT_ABORT ON 
GO
SET ARITHABORT ON
GO
BEGIN TRANSACTION 
INSERT INTO [dbo].[MPERule] ([MPERuleID], [MPERuleRegexID], [CommonEventID], [Name], [FullName], [BaseRule], [ShortDesc], [LongDesc], [DefMsgTTL], [DefMsgArchiveMode], [DefForwarding], [DefFalseAlarmRating], [DefLogMartMode], [MapTag1], [MapTag2], [MapTag3], [MapTag4], [MapTag5], [MapTag6], [MapTag7], [MapTag8], [MapTag9], [MapTag10], [MapVMID], [MapSIP], [MapDIP], [MapSName], [MapDName], [MapSPort], [MapDPort], [MapProtocolID], [MapLogin], [MapAccount], [MapGroup], [MapDomain], [MapSession], [MapProcess], [MapObject], [MapURL], [MapSender], [MapRecipient], [MapSubject], [MapBytesIn], [MapBytesOut], [MapItemsIn], [MapItemsOut], [MapDuration], [MapAmount], [MapQuantity], [MapRate], [MapSize], [RecordStatus], [InheritTech], [DateUpdated], [SortOrder], [SHostIs], [DHostIs], [ServiceIs], [HostContext], [PrefixBaseRuleName], [RuleStatus], [SupportLevel], [VersionMajor], [VersionMinor], [MapUCF_A], [MapUCF_B], [MapUCF_C], [MapUCF_D], [MapUCF_E], [MapUCF_F], [MapUCF_G], [MapUCF_H], [MapUCF_I], [MapUCF_J], [MapUC50_A], [MapUC50_B], [MapUC50_C], [MapUC50_D], [MapUC50_E], [MapUC50_F], [MapUC50_G], [MapUC50_H], [MapUC50_I], [MapUC50_J], [MapUC100_A], [MapUC100_B], [MapUC100_C], [MapUC100_D], [MapUC100_E], [MapUC100_F], [MapUC100_G], [MapUC100_H], [MapUC100_I], [MapUC100_J], [MapUC255_A], [MapUC255_B], [MapUC255_C], [MapUC255_D], [MapUC255_E], [MapUC1000_A], [MapUC1000_B], [MapUC1000_C], [MapUC1000_D], [MapUC1000_E], [MapSMAC], [MapDMAC], [MapSNATIP], [MapDNATIP], [MapSInterface], [MapDInterface], [MapPID], [MapSeverity], [MapVersion], [MapCommand], [MapObjectName], [MapSNATPort], [MapDNATPort], [MapDomainOrigin], [MapHash], [MapPolicy], [MapVendorInfo], [MapResult], [MapObjectType], [MapCVE], [MapUserAgent], [MapParentProcessId], [MapParentProcessName], [MapParentProcessPath], [MapSerialNumber], [MapReason], [MapStatus], [MapThreatId], [MapThreatName], [MapSessionType], [MapAction], [MapResponseCode], [MPERuleIdealRegexId], [Notes]) 
VALUES ($NextMPERuleID, $NextMPERuleRegexID, {0},'{1}','{2}',{3},'{4}','{5}',{6},{7},{8},{9},{10},{11},{12},{13},{14},{15},{16},{17},{18},{19},{20},{21},{22},{23},{24},{25},{26},{27},{28},{29},{30},{31},{32},{33},{34},{35},{36},{37},{38},{39},{40},{41},{42},{43},{44},{45},{46},{47},{48},{49},{50},'{51}',{52},{53},{54},{55},{56},{57},{58},{59},{60},{61},{62},{63},{64},{65},{66},{67},{68},{69},{70},{71},{72},{73},{74},{75},{76},{77},{78},{79},{80},{81},{82},{83},{84},{85},{86},{87},{88},{89},{90},{91},{92},{93},{94},{95},{96},{97},{98},{99},{100},{101},{102},{103},{104},{105},{106},{107},{108},{109},{110},{111},{112},{113},{114},{115},{116},{117},{118},{119},{120},{121},{122},{123},{124},{125},{126},{127},{128},{129},{130},{131},{132},{133},{134},{135});
COMMIT TRANSACTION
GO
" -f $a.ChildNodes.MPERule.CommonEventID, 
$a.ChildNodes.MPERule.Name, 
$a.ChildNodes.MPERule.FullName, 
$a.ChildNodes.MPERule.BaseRule, 
$a.ChildNodes.MPERule.ShortDesc,
$a.ChildNodes.MPERule.LongDesc, 
$a.ChildNodes.MPERule.DefMsgTTL,
$a.ChildNodes.MPERule.DefMsgArchiveMode,
$a.ChildNodes.MPERule.DefForwarding,
$a.ChildNodes.MPERule.DefFalseAlarmRating,
$a.ChildNodes.MPERule.DefLogMartMode,
$(if($a.ChildNodes.MPERule.MapTag1){'1'}else{'0'}),
$(if($a.ChildNodes.MPERule.MapTag2){'1'}else{'0'}),
$(if($a.ChildNodes.MPERule.MapTag3){'1'}else{'0'}),
$(if($a.ChildNodes.MPERule.MapTag4){'1'}else{'0'}),
$(if($a.ChildNodes.MPERule.MapTag5){'1'}else{'0'}),
$(if($a.ChildNodes.MPERule.MapTag6){'1'}else{'0'}),
$(if($a.ChildNodes.MPERule.MapTag7){'1'}else{'0'}),
$(if($a.ChildNodes.MPERule.MapTag8){'1'}else{'0'}),
$(if($a.ChildNodes.MPERule.MapTag9){'1'}else{'0'}),
$(if($a.ChildNodes.MPERule.MapTag10){'1'}else{'0'}),
$(if($a.ChildNodes.MPERule.MapVMID){'1'}else{'0'}),
$(if($a.ChildNodes.MPERule.MapSIP){'1'}else{'0'}),
$(if($a.ChildNodes.MPERule.MapDIP){'1'}else{'0'}),
$(if($a.ChildNodes.MPERule.MapSName){'1'}else{'0'}),
$(if($a.ChildNodes.MPERule.MapDName){'1'}else{'0'}),
$(if($a.ChildNodes.MPERule.MapSPort){'1'}else{'0'}),
$(if($a.ChildNodes.MPERule.MapDPort){'1'}else{'0'}), 
$(if($a.ChildNodes.MPERule.MapProtocolID){'1'}else{'0'}),
$(if($a.ChildNodes.MPERule.MapLogin){'1'}else{'0'}),
$(if($a.ChildNodes.MPERule.MapAccount){'1'}else{'0'}),
$(if($a.ChildNodes.MPERule.MapGroup){'1'}else{'0'}),
$(if($a.ChildNodes.MPERule.MapDomain){'1'}else{'0'}),
$(if($a.ChildNodes.MPERule.MapSession){'1'}else{'0'}),
$(if($a.ChildNodes.MPERule.MapProcess){'1'}else{'0'}),
$(if($a.ChildNodes.MPERule.MapObject){'1'}else{'0'}),
$(if($a.ChildNodes.MPERule.MapURL){'1'}else{'0'}),
$(if($a.ChildNodes.MPERule.MapSender){'1'}else{'0'}),
$(if($a.ChildNodes.MPERule.MapRecipient){'1'}else{'0'}),
$(if($a.ChildNodes.MPERule.MapSubject){'1'}else{'0'}),
$(if($a.ChildNodes.MPERule.MapBytesIn){'1'}else{'0'}),
$(if($a.ChildNodes.MPERule.MapBytesOut){'1'}else{'0'}),
$(if($a.ChildNodes.MPERule.MapItemsIn){'1'}else{'0'}),
$(if($a.ChildNodes.MPERule.MapItemsOut){'1'}else{'0'}),
$(if($a.ChildNodes.MPERule.MapDuration){'1'}else{'0'}),
$(if($a.ChildNodes.MPERule.MapAmount){'1'}else{'0'}),
$(if($a.ChildNodes.MPERule.MapQuantity){'1'}else{'0'}),
$(if($a.ChildNodes.MPERule.MapRate){'1'}else{'0'}),
$(if($a.ChildNodes.MPERule.MapSize){'1'}else{'0'}),
$a.ChildNodes.MPERule.RecordStatus,
$a.ChildNodes.MPERule.InheritTech,
$a.ChildNodes.MPERule.DateUpdated,
$a.ChildNodes.MPERule.SortOrder,
$a.ChildNodes.MPERule.SHostIs,
$a.ChildNodes.MPERule.DHostIs,
$a.ChildNodes.MPERule.ServiceIs,
$a.ChildNodes.MPERule.HostContext,
$a.ChildNodes.MPERule.PrefixBaseRuleName,
$a.ChildNodes.MPERule.RuleStatus,
$(if(!$a.ChildNodes.MPERule.SupportLevel){'1'}else{$a.ChildNodes.MPERule.SupportLevel}), 
$a.ChildNodes.MPERule.VersionMajor,
$a.ChildNodes.MPERule.VersionMinor,
$(if($a.ChildNodes.MPERule.MapUCF_A){'1'}else{'0'}),
$(if($a.ChildNodes.MPERule.MapUCF_B){'1'}else{'0'}),
$(if($a.ChildNodes.MPERule.MapUCF_C){'1'}else{'0'}),
$(if($a.ChildNodes.MPERule.MapUCF_D){'1'}else{'0'}),
$(if($a.ChildNodes.MPERule.MapUCF_E){'1'}else{'0'}),
$(if($a.ChildNodes.MPERule.MapUCF_F){'1'}else{'0'}),
$(if($a.ChildNodes.MPERule.MapUCF_G){'1'}else{'0'}),
$(if($a.ChildNodes.MPERule.MapUCF_H){'1'}else{'0'}),
$(if($a.ChildNodes.MPERule.MapUCF_I){'1'}else{'0'}),
$(if($a.ChildNodes.MPERule.MapUCF_J){'1'}else{'0'}),
$(if($a.ChildNodes.MPERule.MapUC50_A){'1'}else{'0'}),
$(if($a.ChildNodes.MPERule.MapUC50_B){'1'}else{'0'}),
$(if($a.ChildNodes.MPERule.MapUC50_C){'1'}else{'0'}),
$(if($a.ChildNodes.MPERule.MapUC50_D){'1'}else{'0'}),
$(if($a.ChildNodes.MPERule.MapUC50_E){'1'}else{'0'}), 
$(if($a.ChildNodes.MPERule.MapUC50_F){'1'}else{'0'}),
$(if($a.ChildNodes.MPERule.MapUC50_G){'1'}else{'0'}),
$(if($a.ChildNodes.MPERule.MapUC50_H){'1'}else{'0'}),
$(if($a.ChildNodes.MPERule.MapUC50_I){'1'}else{'0'}),
$(if($a.ChildNodes.MPERule.MapUC50_J){'1'}else{'0'}),
$(if($a.ChildNodes.MPERule.MapUC100_A){'1'}else{'0'}),
$(if($a.ChildNodes.MPERule.MapUC100_B){'1'}else{'0'}),
$(if($a.ChildNodes.MPERule.MapUC100_C){'1'}else{'0'}),
$(if($a.ChildNodes.MPERule.MapUC100_D){'1'}else{'0'}),
$(if($a.ChildNodes.MPERule.MapUC100_E){'1'}else{'0'}),
$(if($a.ChildNodes.MPERule.MapUC100_F){'1'}else{'0'}),
$(if($a.ChildNodes.MPERule.MapUC100_G){'1'}else{'0'}),
$(if($a.ChildNodes.MPERule.MapUC100_H){'1'}else{'0'}),
$(if($a.ChildNodes.MPERule.MapUC100_I){'1'}else{'0'}),
$(if($a.ChildNodes.MPERule.MapUC100_J){'1'}else{'0'}),
$(if($a.ChildNodes.MPERule.MapUC255_A){'1'}else{'0'}),
$(if($a.ChildNodes.MPERule.MapUC255_B){'1'}else{'0'}),
$(if($a.ChildNodes.MPERule.MapUC255_C){'1'}else{'0'}),
$(if($a.ChildNodes.MPERule.MapUC255_D){'1'}else{'0'}),
$(if($a.ChildNodes.MPERule.MapUC255_E){'1'}else{'0'}),
$(if($a.ChildNodes.MPERule.MapUC1000_A){'1'}else{'0'}),
$(if($a.ChildNodes.MPERule.MapUC1000_B){'1'}else{'0'}),
$(if($a.ChildNodes.MPERule.MapUC1000_C){'1'}else{'0'}),
$(if($a.ChildNodes.MPERule.MapUC1000_D){'1'}else{'0'}),
$(if($a.ChildNodes.MPERule.MapUC1000_E){'1'}else{'0'}),
$(if($a.ChildNodes.MPERule.MapSMAC){'1'}else{'0'}),
$(if($a.ChildNodes.MPERule.MapDMAC){'1'}else{'0'}),
$(if($a.ChildNodes.MPERule.MapSNATIP){'1'}else{'0'}),
$(if($a.ChildNodes.MPERule.MapDNATIP){'1'}else{'0'}),
$(if($a.ChildNodes.MPERule.MapSInterface){'1'}else{'0'}),
$(if($a.ChildNodes.MPERule.MapDInterface){'1'}else{'0'}),
$(if($a.ChildNodes.MPERule.MapPID){'1'}else{'0'}),
$(if($a.ChildNodes.MPERule.MapSeverity){'1'}else{'0'}),
$(if($a.ChildNodes.MPERule.MapVersion){'1'}else{'0'}),
$(if($a.ChildNodes.MPERule.MapCommand){'1'}else{'0'}),
$(if($a.ChildNodes.MPERule.MapObjectName){'1'}else{'0'}),
$(if($a.ChildNodes.MPERule.MapSNATPort){'1'}else{'0'}),
$(if($a.ChildNodes.MPERule.MapDNATPort){'1'}else{'0'}),
$(if($a.ChildNodes.MPERule.MapDomainOrigin){'1'}else{'0'}),
$(if($a.ChildNodes.MPERule.MapHash){'1'}else{'0'}),
$(if($a.ChildNodes.MPERule.MapPolicy){'1'}else{'0'}),
$(if($a.ChildNodes.MPERule.MapVendorInfo){'1'}else{'0'}),
$(if($a.ChildNodes.MPERule.MapResult){'1'}else{'0'}),
$(if($a.ChildNodes.MPERule.MapObjectType){'1'}else{'0'}),
$(if($a.ChildNodes.MPERule.MapCVE){'1'}else{'0'}),
$(if($a.ChildNodes.MPERule.MapUserAgent){'1'}else{'0'}),
$(if($a.ChildNodes.MPERule.MapParentProcessId){'1'}else{'0'}), 
$(if($a.ChildNodes.MPERule.MapParentProcessName){'1'}else{'0'}),
$(if($a.ChildNodes.MPERule.MapParentProcessPath){'1'}else{'0'}),
$(if($a.ChildNodes.MPERule.MapSerialNumber){'1'}else{'0'}),
$(if($a.ChildNodes.MPERule.MapReason){'1'}else{'0'}),
$(if($a.ChildNodes.MPERule.MapStatus){'1'}else{'0'}),
$(if($a.ChildNodes.MPERule.MapThreatId){'1'}else{'0'}),
$(if($a.ChildNodes.MPERule.MapThreatName){'1'}else{'0'}),
$(if($a.ChildNodes.MPERule.MapSessionType){'1'}else{'0'}),
$(if($a.ChildNodes.MPERule.MapAction){'1'}else{'0'}),
$(if($a.ChildNodes.MPERule.MapResponseCode){'1'}else{'0'}),
$(if($a.ChildNodes.MPERule.MPERuleIdealRegexId){$a.ChildNodes.MPERule.MPERuleIdealRegexId}else{'NULL'}), 
$(if($a.ChildNodes.MPERule.Notes){$a.ChildNodes.MPERule.Notes}else{'NULL'})

#$ds1 = Invoke-Sqlcmd -Query $sqlQuery1 -ServerInstance $sqlServer -Database "LogRhythmEMDB"

		
<#
SET XACT_ABORT ON
GO
SET ARITHABORT ON
GO
BEGIN TRANSACTION

PRINT(N'Add 1 row to [dbo].[MPERule]')
INSERT INTO [dbo].[MPERule] ([MPERuleID], [MPERuleRegexID], [CommonEventID], [Name], [FullName], [BaseRule], [ShortDesc], [LongDesc], [DefMsgTTL], [DefMsgArchiveMode], [DefForwarding], [DefFalseAlarmRating], 
[DefLogMartMode], [MapTag1], [MapTag2], [MapTag3], [MapTag4], [MapTag5], [MapTag6], [MapTag7], [MapTag8], [MapTag9], [MapTag10], [MapVMID], [MapSIP], [MapDIP], [MapSName], [MapDName], [MapSPort], [MapDPort], 
[MapProtocolID], [MapLogin], [MapAccount], [MapGroup], [MapDomain], [MapSession], [MapProcess], [MapObject], [MapURL], [MapSender], [MapRecipient], [MapSubject], [MapBytesIn], [MapBytesOut], [MapItemsIn], [MapItemsOut], 
[MapDuration], [MapAmount], [MapQuantity], [MapRate], [MapSize], [RecordStatus], [InheritTech], [DateUpdated], [SortOrder], [SHostIs], [DHostIs], [ServiceIs], [HostContext], [PrefixBaseRuleName], [RuleStatus], [SupportLevel], 
[VersionMajor], [VersionMinor], [MapUCF_A], [MapUCF_B], [MapUCF_C], [MapUCF_D], [MapUCF_E], [MapUCF_F], [MapUCF_G], [MapUCF_H], [MapUCF_I], [MapUCF_J], [MapUC50_A], [MapUC50_B], [MapUC50_C], [MapUC50_D], [MapUC50_E], 
[MapUC50_F], [MapUC50_G], [MapUC50_H], [MapUC50_I], [MapUC50_J], [MapUC100_A], [MapUC100_B], [MapUC100_C], [MapUC100_D], [MapUC100_E], [MapUC100_F], [MapUC100_G], [MapUC100_H], [MapUC100_I], [MapUC100_J], [MapUC255_A], 
[MapUC255_B], [MapUC255_C], [MapUC255_D], [MapUC255_E], [MapUC1000_A], [MapUC1000_B], [MapUC1000_C], [MapUC1000_D], [MapUC1000_E], [MapSMAC], [MapDMAC], [MapSNATIP], [MapDNATIP], [MapSInterface], [MapDInterface], [MapPID], 
[MapSeverity], [MapVersion], [MapCommand], [MapObjectName], [MapSNATPort], [MapDNATPort], [MapDomainOrigin], [MapHash], [MapPolicy], [MapVendorInfo], [MapResult], [MapObjectType], [MapCVE], [MapUserAgent], [MapParentProcessId], 
[MapParentProcessName], [MapParentProcessPath], [MapSerialNumber], [MapReason], [MapStatus], [MapThreatId], [MapThreatName], [MapSessionType], [MapAction], [MapResponseCode], [MPERuleIdealRegexId], [Notes]) 
VALUES (1000000001, 1000000001, 10404, 'VMID 1 - Process Create', 'VMID 1 - Process Create', 1, 'Process creation rules are written on basis that SHA1 has been chosen as the Sysmon hashing mechanism.  If a different mechanism has been configured the regex will require updating accordingly.', NULL, 32, 2, 1, 0, 13627389, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, 1, 1, '2017-12-14 16:19:31.773', 1, 0, 1, 0, 0, 0, 3, 1, 6, 1, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL)
COMMIT TRANSACTION
GO

#>

$sqlQuery2 = "SET XACT_ABORT ON
GO
SET ARITHABORT ON
GO
BEGIN TRANSACTION
INSERT INTO [dbo].[MPERuleRegex] ([MPERuleRegexID], [RegexTagged], [IgnoreCase], [Multiline], [RecordStatus], [DateUpdated], [PerfMonMode], [VersionMajor], [VersionMinor], [DevRegex]) 
VALUES ({0},'{1}',{2},{3},{4},'{5}',{6},{7},{8},{9});
COMMIT TRANSACTION
GO
" -f $NextMPERuleRegexID, 
$a.ChildNodes.MPERuleRegex.RegexTagged.Replace("'","''"), #replace single quotes with two single quotes.  This may need expansion as there are maybe other reserved characters
$a.ChildNodes.MPERuleRegex.IgnoreCase, 
$a.ChildNodes.MPERuleRegex.Multiline, 
$a.ChildNodes.MPERuleRegex.RecordStatus, 
$a.ChildNodes.MPERuleRegex.DateUpdated, 
$a.ChildNodes.MPERuleRegex.PerfMonMode, 
$a.ChildNodes.MPERuleRegex.VersionMajor, 
$a.ChildNodes.MPERuleRegex.VersionMinor,
$a.ChildNodes.MPERuleRegex.DevRegex  #Add IF STATEMENT


<#
SET XACT_ABORT ON
GO
SET ARITHABORT ON
GO
BEGIN TRANSACTION

PRINT(N'Add 1 row to [dbo].[MPERuleRegex]')
INSERT INTO [dbo].[MPERuleRegex] ([MPERuleRegexID], [RegexTagged], [IgnoreCase], [Multiline], [RecordStatus], [DateUpdated], [PerfMonMode], [VersionMajor], [VersionMinor], [DevRegex]) 
VALUES (1000000001, 
'(?<vmid>1)</eventid>.*?<level>(?<severity>[^<]+)</level>.*?<computer>(?<dname>[^<]+)</computer>[^>]+>[^>]+><EventData>[^>]+>[^>]+><Data Name=''ProcessGuid''>{(?<session>[^}]+)}</Data><Data Name=''ProcessId''>(?<processid>[^<]+)</Data><Data Name=''Image''>(?<object>.*\\)?(?<process>[^<]+)</Data><Data Name=''CommandLine''>(?<command>[^<]+)</Data><Data Name=''CurrentDirectory''>[^<]+</Data><Data Name=''User''>((?<domainorigin>[^\\]+)\\)?(?<login>[^<]+)</Data><Data Name=''LogonGuid''>{(?<group>[^}]+)}</Data><Data Name=''LogonId''>(?<tag3>[^<]+)</Data><Data Name=''TerminalSessionId''>[^<]+</Data><Data Name=''IntegrityLevel''>(?<sessiontype>[^<]+)</Data><Data Name=''Hashes''>*SHA1=(?<hash>[^<]+)</Data><Data Name=''ParentProcessGuid''>[^<]+</Data><Data Name=''ParentProcessId''>(?<parentprocessid>[^<]+)</Data><Data Name=''ParentImage''>(?<parentprocesspath>.*\\)?(?<parentprocessname>[^<]+)</Data><Data Name=''ParentCommandLine''>[^<]*</Data></EventData></Event>', 
1, 0, 1, '2017-12-14 16:19:31.783', 1, 6, 1, NULL)
COMMIT TRANSACTION
GO
#>


$sqlQuery3 = "SET XACT_ABORT ON
GO
SET ARITHABORT ON
GO
BEGIN TRANSACTION
INSERT INTO [dbo].[MPERuleToMsgSourceType] ([MsgSourceTypeID], [MPERuleRegexID], [SortOrder], [AutoSort], [SortAbove], [CustomSortAbove], [SortAboveSystem]) 
VALUES ({0},{1},{2},{3},{4},{5},{6})
COMMIT TRANSACTION" -f $a.ChildNodes.MPERuleToMST.MsgSourceTypeID, 
$NextMPERuleRegexID, 
$a.ChildNodes.MPERuleToMST.SortOrder, 
$a.ChildNodes.MPERuleToMST.AutoSort, 
$(if(!$a.ChildNodes.MPERuleToMST.SortAboveSystem){'0'}else{'1'}), #Value only exported when present.  Validate the actual values could be (always 0 in DB samples to date)
$(if(!$a.ChildNodes.MPERuleToMST.CustomSortAbove){'NULL'}else{$a.ChildNodes.MPERuleToMST.CustomSortAbove}),
$(if(!$a.ChildNodes.MPERuleToMST.SortAboveSystem){'0'}else{$a.ChildNodes.MPERuleToMST.SortAboveSystem})


<#
SET XACT_ABORT ON
GO
SET ARITHABORT ON
GO
BEGIN TRANSACTION


PRINT(N'Add 1 row to [dbo].[MPERuleToMsgSourceType]')
INSERT INTO [dbo].[MPERuleToMsgSourceType] ([MsgSourceTypeID], [MPERuleRegexID], [SortOrder], [AutoSort], [SortAbove], [CustomSortAbove], [SortAboveSystem]) VALUES (1000639, 1000000001, 34, 0, NULL, NULL, 0)
COMMIT TRANSACTION
#>

if(test-path -Path $outfile){remove-item -Path $outfile}
$outfile = "outfile.txt"

$sqlQuery1 | Add-Content -Path $outfile
$sqlQuery2 | Add-Content -Path $outfile
$sqlQuery3 | Add-Content -Path $outfile


<#
For ($i=0; $i -le 136; $i++) {
 $b = $b + "{$i},"
 write-host $b
}

#>