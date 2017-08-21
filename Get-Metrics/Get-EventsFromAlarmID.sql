-- Returns the associated Events for a given Alarm ID
WITH resultsas 
( 
           SELECT     m.msgid, 
                      m.mediatormsgid, 
                      m.mediatorsessionid, 
                      m.msgsourceid, 
                      m.commoneventid, 
                      m.msgclassid, 
                      m.mperuleid, 
                      m.[Priority], 
                      m.msgdate, 
                      m.normalmsgdate, 
                      m.riskrating, 
                      m.falsealarmrating, 
                      m.direction, 
                      m.shostid, 
                      m.dhostid, 
                      m.serviceid, 
                      m.snameid, 
                      m.sip, 
                      m.sport, 
                      m.dnameid, 
                      m.dip, 
                      m.dport, 
                      m.protocolid, 
                      m.loginid, 
                      m.accountid, 
                      m.senderid, 
                      m.recipientid, 
                      m.[Subject], 
                      m.objectid, 
                      m.bytesin, 
                      m.bytesout, 
                      m.itemsin, 
                      m.itemsout, 
                      m.duration, 
                      m.amount, 
                      m.quantity, 
                      m.rate, 
                      m.size, 
                      m.groupid, 
                      m.domainid, 
                      m.[Session], 
                      m.processid, 
                      m.urlid, 
                      vendormsgid = m.vendormsgidentifierid, 
                      m.dateinserted, 
                      m.slocationkey, 
                      m.dlocationkey, 
                      m.snetworkid, 
                      m.dnetworkid, 
                      m.snatport, 
                      m.dnatport, 
                      m.smac_id, 
                      m.dmac_id, 
                      m.sinterfaceid, 
                      m.dinterfaceid, 
                      m.severityid, 
                      m.versionid, 
                      m.commandid, 
                      m.objectnameid, 
                      m.snatip, 
                      m.dnatip, 
                      m.pid, 
                      m.entityid, 
                      m.domainorigin, 
                      m.[Hash], 
                      m.policyid, 
                      m.vendorinfo, 
                      m.resultid, 
                      m.objecttypeid, 
                      m.cveid, 
                      m.useragent, 
                      m.parentprocessid, 
                      m.parentprocessnameid, 
                      m.parentprocesspathid, 
                      m.serialnumberid, 
                      m.reason, 
                      m.statusid, 
                      m.threatid, 
                      m.threatname, 
                      m.sessiontypeid, 
                      m.actionid, 
                      m.responsecodeid, 
                      m.msg, 
                      rownumber = row_number() OVER (ORDER BY normalmsgdate ASC) 
           FROM       dbo.msg m WITH (INDEX = pk_msg, nolock) 
           INNER JOIN dbo.alarmtomarcmsg x WITH (INDEX = alarmtomarcmsg_pk, nolock) 
           ON         m.msgid = x.marcmsgid 
           WHERE      x.alarmid = 3)SELECT          r.msgid, 		--Alarm ID can be changed
                r.mediatormsgid, 
                r.mediatorsessionid, 
                r.msgsourceid, 
                r.commoneventid, 
                r.msgclassid, 
                r.mperuleid, 
                r.[Priority], 
                r.msgdate, 
                r.normalmsgdate, 
                r.riskrating, 
                r.falsealarmrating, 
                r.direction, 
                r.shostid, 
                r.dhostid, 
                r.serviceid, 
                sname, 
                r.sip, 
                r.sport, 
                dname, 
                r.dip, 
                r.dport, 
                r.protocolid, 
                [Login], 
                account, 
                sender, 
                recipient, 
                r.[Subject], 
                [Object] = o.[Object], 
                r.bytesin, 
                r.bytesout, 
                r.itemsin, 
                r.itemsout, 
                r.duration, 
                r.amount, 
                r.quantity, 
                r.rate, 
                r.size, 
                [Group] = g.[Group], 
                domain = d.domain, 
                r.[Session], 
                process =     p.process, 
                url =         u.url, 
                vendormsgid = v.vendormsgidentifier, 
                r.dateinserted, 
                r.normalmsgdate, 
                r.slocationkey, 
                r.dlocationkey, 
                r.snetworkid, 
                r.dnetworkid, 
                r.snatport, 
                r.dnatport, 
                smac =       ms.mac, 
                dmac =       md.mac, 
                sinterface = si.interface, 
                dinterface = di.interface, 
                severity =   se.severity, 
                [Version] = ve.[Version], 
                command = c.command, 
                objectname = obn.[Object], 
                r.snatip, 
                r.dnatip, 
                r.pid, 
                r.entityid, 
                r.domainorigin, 
                r.[Hash], 
                po.policy, 
                r.vendorinfo, 
                rt.result, 
                ot.objecttype, 
                cv.cve, 
                r.useragent, 
                r.parentprocessid, 
                pn.parentprocessname, 
                pp.parentprocesspath, 
                sr.serialnumber, 
                r.reason, 
                st.status, 
                r.threatid, 
                r.threatname, 
                stp.sessiontype, 
                ac.[Action], 
                rs.responsecode , 
                r.msgfrom results r 
INNER JOIN 
                ( 
                       SELECT sname = hostname, 
                              hostnameid 
                       FROM   dbo.hostname WITH (nolock)) hs 
ON              hs.hostnameid = r.snameid 
INNER JOIN 
                ( 
                       SELECT dname = hostname, 
                              hostnameid 
                       FROM   dbo.hostname WITH (nolock)) hd 
ON              hd.hostnameid = r.dnameid 
INNER JOIN 
                ( 
                       SELECT [Login] = [User], 
                              userid 
                       FROM   dbo.[User] WITH (nolock)) ul 
ON              ul.userid = r.loginid 
INNER JOIN 
                ( 
                       SELECT account = [User], 
                              userid 
                       FROM   dbo.[User] WITH (nolock)) ua 
ON              ua.userid = r.accountid 
INNER JOIN 
                ( 
                       SELECT sender = [Address], 
                              addressid 
                       FROM   dbo.[Address] WITH (nolock)) sa 
ON              sa.addressid = r.senderid 
INNER JOIN 
                ( 
                       SELECT recipient = [Address], 
                              addressid 
                       FROM   dbo.[Address] WITH (nolock)) ar 
ON              ar.addressid = r.recipientid 
INNER JOIN      dbo.[Object] o WITH (nolock) 
ON              o.objectid = r.objectid 
INNER JOIN      dbo.[Group] g WITH (nolock) 
ON              g.groupid = r.groupid 
INNER JOIN      dbo.domain d WITH (nolock) 
ON              d.domainid = r.domainid 
INNER JOIN      dbo.process p WITH (nolock) 
ON              p.processid = r.processid 
INNER JOIN      dbo.url u WITH (nolock) 
ON              u.urlid = r.urlid 
INNER JOIN      dbo.vendormsgidentifier v WITH (nolock) 
ON              v.vendormsgidentifierid = r.vendormsgid 
LEFT OUTER JOIN dbo.mac ms WITH (nolock) 
ON              ms.macid = r.smac_id 
LEFT OUTER JOIN dbo.mac md WITH (nolock) 
ON              md.macid = r.dmac_id 
LEFT OUTER JOIN dbo.interface si WITH (nolock) 
ON              si.interfaceid = r.sinterfaceid 
LEFT OUTER JOIN dbo.interface di WITH (nolock) 
ON              di.interfaceid = r.dinterfaceid 
LEFT OUTER JOIN dbo.severity se WITH (nolock) 
ON              se.severityid = r.severityid 
LEFT OUTER JOIN dbo.[Version] ve WITH (nolock) 
ON              ve.versionid = r.versionid 
LEFT OUTER JOIN dbo.command c WITH (nolock) 
ON              c.commandid = r.commandid 
LEFT OUTER JOIN dbo.[Object] obn WITH (nolock) 
ON              obn.objectid = r.objectnameid 
LEFT OUTER JOIN dbo.[Action] ac WITH (nolock) 
ON              ac.actionid = r.actionid 
LEFT OUTER JOIN dbo.cve cv WITH (nolock) 
ON              cv.cveid = r.cveid 
LEFT OUTER JOIN dbo.objecttype_sn ot WITH (nolock) 
ON              ot.objecttypeid = r.objecttypeid 
LEFT OUTER JOIN dbo.parentprocessname pn WITH (nolock) 
ON              pn.parentprocessnameid = r.parentprocessnameid 
LEFT OUTER JOIN dbo.parentprocesspath pp WITH (nolock) 
ON              pp.parentprocesspathid = r.parentprocesspathid 
LEFT OUTER JOIN dbo.policy po WITH (nolock) 
ON              po.policyid = r.policyid 
LEFT OUTER JOIN dbo.responsecode rs WITH (nolock) 
ON              rs.responsecodeid = r.responsecodeid 
LEFT OUTER JOIN dbo.result rt WITH (nolock) 
ON              rt.resultid = r.resultid 
LEFT OUTER JOIN dbo.serialnumber sr WITH (nolock) 
ON              sr.serialnumberid = r.serialnumberid 
LEFT OUTER JOIN dbo.sessiontype stp WITH (nolock) 
ON              stp.sessiontypeid = r.sessiontypeid 
LEFT OUTER JOIN dbo.[Status] st WITH (nolock) 
ON              st.statusid = r.statusidwhere r.rownumber BETWEEN 1 AND 1