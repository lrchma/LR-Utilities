
# ********************************
# File Watcher Setup
# ********************************

$folder = 'c:\lr-alarms\' # Enter the root path you want to monitor. 
$filter = '*.csv'  # You can enter a wildcard filter here. 
$global:lastlog

$fsw = New-Object IO.FileSystemWatcher $folder, $filter -Property @{IncludeSubdirectories = $false;NotifyFilter = [IO.NotifyFilters]'FileName, LastWrite'} 

Register-ObjectEvent $fsw Changed -SourceIdentifier FileChanged -Action { 
$name = $Event.SourceEventArgs.Name 
$changeType = $Event.SourceEventArgs.ChangeType 
$timeStamp = $Event.TimeGenerated 
Write-Host "The file '$name' was $changeType at $timeStamp" -fore yellow
$global:lastlog = Get-Content $folder$name | Select-Object -last 1 
Write-Host $global:lastlog -fore yellow
SendAlert("chris.martin@lab.local")
}

#Unregister-Event FileChanged


# ********************************
# Email Setup & Parsing
# - this will only work if using all Alarm notification fields, and in the default order
# ********************************

Function SendAlert ($emailTo) 
{ 

$a_Fields = $global:lastlog.split(",")
$a_id = $a_Fields[0]
$a_time = $a_Fields[1]
$a_name = $a_Fields[6].Replace("`"","")
$a_rbp = $a_Fields[7].Substring(0, $a_Fields[7].IndexOf('.'))  #remove the floating point value in RBP, which is a good point cause in the history of alarms there's never been one with floating point value...
$a_hostnameo = $a_Fields[8].Replace("`"","")
$a_hostnamei = $a_Fields[9].Replace("`"","")
$a_url = $a_Fields[12].Replace("`"","")
$a_description = $a_Fields[14].Replace("`"","")
$a_cve = $a_Fields[19].Replace("`"","")
$a_entityi = $a_Fields[23].Replace("`"","")
$a_entityo = $a_Fields[24].Replace("`"","")
$a_rawlog= $a_Fields[35]

#find the RBP of alarm and set email priority accordingly
switch ($a_rbp)
{
  {$_ -ge 0 -and $_ -le 50} {$priority = "low"}
  {$_ -ge 51 -and $_ -le 89} {$priority = "normal"}
  {$_ -ge 90 -and $_ -le 100} {$priority = "high"}
}

#change alarm date from RFC1123 patter into something human readable
$tempDate = [datetime]$a_time 
$alarmDate = Get-Date $tempDate -f F

if (!$a_description) { $a_description = "No description available." }
if (!$a_hostnameo) { $a_hostnameo = "n/a" }
if (!$a_hostnamei) { $a_hostnamei = "n/a" }

 switch -wildcard ($a_name)
{
"AIE:*" {
  $message = @" 

<p>The LogRhythm AI Engine alarm <b>$a_name</b> triggered at <b>$alarmDate</b>.</p>
<p>LogRhythm has calculated a risk rating of <b>$a_rbp</b> for alarm ID <b>$a_id</b>, which impacted hosts <b>$a_hostnameo -> $a_hostnamei</b>, in or between entities <b>$a_entityo -> $a_entityi</b>.</p>
<p>$a_name description:</br>
<em>$a_description</em></p>
<p>The raw log(s) associated with alarm ID <b>$a_id</b> are:
<pre>$a_rawlog</pre>
</p>
<p>Click the following link to access the Alarm within LogRhythm: <a href=$a_url>$a_url</a></p>

"@
  }
"AIE: Vulnerability: Remote Service" {

$cve_query = invoke-webrequest https://www.cvedetails.com/cve/CVE-2013-2566/
$cve_results = $query.AllElements | where Class -eq cvedetailssummary | Select -First 1 -ExpandProperty innerText

  $message = @" 

<p>The LogRhythm AI Engine alarm <b>$a_name</b> triggered at <b>$alarmDate</b>.</p>
<p>LogRhythm has calculated a risk rating of <b>$a_rbp</b> for alarm ID <b>$a_id</b>, which impacted hosts <b>$a_hostnameo -> $a_hostnamei</b>, in or between entities <b>$a_entityo -> $a_entityi</b>.</p>
<p>$a_name description:</br>
<em>$a_description</em></p>
<p>The raw log(s) associated with alarm ID <b>$a_id</b> are:
<pre>$a_rawlog</pre>
</p>
<p>Click the following link to access the Alarm within LogRhythm: <a href=$a_url>$a_url</a></p>
<h4>Additional Resources for Alarm: $a_name</h4>
<p></p>
<p><a href=https://www.cvedetails.com/cve/$a_cve/>https://www.cvedetails.com/cve/$a_cve/</a></p>
<p>$cve_results</p>

"@
  }

  "AIE: Malware: C2 Threat List Communication" {
  $message = @" 

<p>The LogRhythm AI Engine alarm <b>$a_name</b> triggered at <b>$alarmDate</b>.</p>
<p>LogRhythm has calculated a risk rating of <b>$a_rbp</b> for alarm ID <b>$a_id</b>, which impacted hosts <b>$a_hostnameo -> $a_hostnamei</b>, in or between entities <b>$a_entityo -> $a_entityi</b>.</p>
<p>$a_name description:</br>
<em>$a_description</em></p>
<p>The raw log(s) associated with alarm ID <b>$a_id</b> are:
<pre>$a_rawlog</pre>
</p>
<p>Click the following link to access the Alarm within LogRhythm: <a href=$a_url>$a_url</a></p>
<h4>Additional Resources for Alarm: $a_name</h4>
<p><a href=https://www.sophos.com/en-us/threat-center/ip-lookup.aspx?ip=$a_hostnamei>https://www.sophos.com/en-us/threat-center/ip-lookup.aspx?ip=$a_hostnamei</a></p>
<h4>Suggested PlayBook Response for Alarm: $a_name</h4>
<p>
<table style="width:50%">
  <tr>
    <th style="text-align: left;">Item</th>
    <th style="text-align: left;">Type</th> 
    <th style="text-align: left;">Details</th>
    <th style="text-align: left;">TLM Stage</th>
  </tr>
  <tr>
    <td>1</td>
    <td>Question</td> 
    <td>Was the communication to the C2 allowed or denied?</td>
    <td>Qualify</td>
  </tr>
  <tr>
    <td>2</td>
    <td>Action</td> 
    <td>Run LogRhythm SmartResponse Isolate Host to block C2 IP</td>
    <td>Neutralize</td>
  </tr>
    <tr>
    <td>3</td>
    <td>Question</td> 
    <td>Have any other hosts communicated with this C2 IP?</td>
    <td>Discover</td>
  </tr>
  <tr>
    <td>4</td>
    <td>Action</td> 
    <td>Run historical search and confirm/deny prior activity</td>
    <td>Qualify</td>
  </tr>
    <tr>
    <td>5</td>
    <td>Action</td> 
    <td>Create LogRhythm Case and attach alarm, logs, and above detail</td>
    <td>Recover</td>
  </tr>
  </table>
</p>


"@
  }
default {
$message = @" 

<p>The LogRhythm alarm <b>$a_name</b> triggered at <b>$alarmDate</b>.</p>
<p>LogRhythm has calculated a risk rating of <b>$a_rbp</b> for alarm ID <b>$a_id</b>, which impacted hosts <b>$a_hostnameo -> $a_hostnamei</b>, in or between entities <b>$a_entityo -> $a_entityi</b>.</p>
<p>$a_name description:</br>
<em>$a_description</em></p>
<p>The raw log(s) associated with alarm ID <b>$a_id</b> are:
<pre>$a_rawlog</pre>
</p>
<p>Click the following link to access the Alarm within LogRhythm: <a href=$a_url>$a_url</a></p>

"@ 
 }
}

$emailFrom = "LogRhythm Alerts <logrhythm@lab.local>"
$subject = "ID:{0}, RBP:{1}, Name:{2}, Entity:{3}->{4}" -f $a_id, $a_rbp, $a_name, $a_entityo, $a_entityi  
$smtpserver="<CHANGEME>" 
Send-MailMessage -SmtpServer $smtpserver -To $emailTo -From $emailFrom -Subject $subject -body $message -BodyAsHtml -Priority $priority

write-host $message
write-host $subject
} 

#https://gallery.technet.microsoft.com/scriptcenter/Simple-Powershell-function-8e826d7c




# ********************************
# Ideas to make betterer
# - Read in the Alarms CSV Header to determine columns names
# - Use array of common event names, to determine email template 

