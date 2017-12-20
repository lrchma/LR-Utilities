$vendorMessageID = "4321"
$timeInterval = "5"
$canaryName = "AIE: LR Canary Test"
$deadParrot = $false
$global:output = @()

function parrot(){

write-output @"
,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,
,,,,,,,,,,,,,,,,,,,,,,,,,,,,+++:,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,
,,,,,,,,,,,,,,,,,,,,,,.,,=ZNMM7M,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,
,,,,,,,,,,,,,,,,,,,,,MMMMZ?+7DMM,,,,,,,,,,,,,,,,,,,,,,:?NNNNN$,,,,,,,,,,,,,,,,,,
,,,,,,,,,,,,,,,,,,,,.DM???MO7,,,,,,,,,,,,,,,,,,,,,,,:MM=?????+M:,,,,,,,,,,,,,,,,
,,,,,,,,,,,,,,,,,,,,,,,MN?M7,,,,,,,,,,,,,,,,,,,,,,,,,,,M7?????IM?=,,,,,,,,,,,,,,
,,,,,,,,,,,,,,,,,,,,,,,NM?MMM,,,,,,,,,,,,,,,?NDMMMMMMMMMMZ888O8`$I7MM:,,,,,,,,,,,
,,,,,,,,,,,,,,,,,,,,,,,.M+I?DMMMN???MMMMMMMMD`$Z+++7888`$ZZZ7.....M`$Z`$MZ,,,,,,,,,,
,,,,,,,,,,,,,,,,,,,,,,,,.MO8OIII77??????`$ZZZZZ`$7$+++88ZZZ+MMMN=M+IZZZMM,,,,,,,,,
,,,,,,,,,,,,,,,,,,,,,,,,,,MO8OZZZ`$Z`$7`$OOZZZZZZZZ`$`$ZO88ZZZ....MMMM,Z`$ZZM:,,,,,,,,
,,,,,,,,,,,.+DOODDNDDDDDNNMN7ZZZ7`$ZZ`$8888OZZZZZZ`$Z`$88ZZZZ~..8M...=ZZZZMN,,,,,,,,
,DMMMMMDNNNDOZZZZZZZZZZZZZZZZZZZZZZ`$7O8888ZZZ`$`$`$`$+IOOZZZZZ=.`$...~ZOOZMM,,,,,,,,,
MMMMMMMDZZZZZZZZZZZZZZZ`$ZZZZZZZZZZ`$ZOO8O8ZZZ`$ZZ`$OO888OZZZZZZZZZZZZOMM~,,,,,,,,,,
MMMMMMMMMMMMMOO8D8N88D8NO8ON8~+?IIIIII7Z`$`$Z`$`$`$`$`$`$ZO8O8O8ZZZZZZ`$OMMM?,,,,,,,,,,,,
,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,`$7MMMMMMMMMMMMMMMMMD,,,,,,,,,,,,,,,,,
,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,
,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,
"@

}

function now(){
get-date -Format s
}


function log($message){
$zz = write-output "$(now) - $message"
$global:output += $zz
return $zz

}

function warning($warning){
$zz = write-warning "$(now) - $warning"
$global:output += $zz
return $zz

}


function email($results){

$param = @{
    SmtpServer = '<CHANGEME>'
    Port = 587
    UseSsl = $true
    From = '<CHANGEME>'
    To = '<CHANGEME>
    Subject = 'I wish to complain about this Parrot...'
    Body = "<em>Look, matey, I know a dead parrot when I see one, and I'm looking at one right now.</em><br />
    <p>PS, You may wish check out your LogRhythm installation as one or more Canary tests have recently failed.<br /><br />
    $(foreach($result in $global:output){write-output "$result<br />"})"
    Priority = "High"
}

<# - This is horrible, but for testing it works, but you should do something betterer in prod
$login = '<CHANGEME>'
$Password = "<CHANGEME>" | Convertto-SecureString -AsPlainText -Force
$credentials = New-Object System.Management.Automation.Pscredential -Argumentlist $login,$password
#>

Send-MailMessage @param -BodyAsHtml -Credential $credentials

}

function writeCanary(){

$fortunes = @(
    "186,282 miles per second: It isn't just a good idea, it's the law!",
    "3rd Law of Computing: Anything that can go wr
    fortune: Segmentation violation -- Core dumped",
    "The smallest interval of time known to man is that which occurs in Manhattan between the traffic signal turning green and the taxi driver behind you blowing his horn."
)

Write-EventLog -LogName Application -Source Application -EventId $vendorMessageID -Message "$(get-date -format s): $($fortunes[(Get-Random -Maximum ([array]$fortunes).count)])"

}



function testDX(){

$today = get-date -format yyyy-MM-dd
$Uri = "http://localhost:9200/logs-$today/_search?&pretty"

#Don't indent me
$body = @"
{
  "query": {
    "bool" : {
      "must" : {
        "term" : { "vendorMessageId" : "$vendorMessageID" }
      },
      "filter" : {
        "range" : {
          "normalDate" : {
            "gt" : "now-$($timeInterval)m"
            }
        }
      }
    }
  }
}

"@

$response = Invoke-WebRequest -Method Post -Uri $Uri -ContentType 'application/json' -Body $body | convertfrom-json
return $response.hits.total
}


function testPM(){

$sqlServer = "."

# Query AIE Events from the Events DB.  We're using UTC and Normal Msg Date
# SQLi much
$sqlQuery = @"
SELECT  [MsgID]
      ,[MediatorSessionID]
	  ,B.Name As CommonEvent
      ,[MsgDate]
      ,[NormalMsgDate]
      ,[Priority]
      ,C.VendorMsgIdentifier
  FROM [LogRhythm_Events].[dbo].[Msg] A
  INNER JOIN [LogRhythmEMDB].dbo.CommonEvent B 
  ON A.CommonEventID = B.CommonEventID
  INNER JOIN [LogRhythmEMDB].dbo.VendorMsgIdentifier C
  ON A.VendorMsgIdentifierID = C.VendorMsgIdentifierID
  WHERE NormalMsgDate >= DATEADD(minute, -$timeInterval, GETUTCDATE()) AND B.Name = '$canaryName'
"@

$ds = Invoke-Sqlcmd -Query $sqlQuery -ServerInstance $sqlServer 

return $ds

}

# ###########

parrot

log("I wish to register a complaint.")

log("Is the Parrot dead? $(if($deadParrot -eq $false){'There, he moved!'}else{'Stone dead!'} )")

# MAIN
log("Canary Test with vendorMessageID=$vendorMessageID")

# Write to Windows Event Log with unique Event ID
writeCanary
log("Canary deployed")

# We wait 60 seconds for the agent to collect, transports, and then DP process, and DX store
log("Resting for 60 seconds")

sleep 60

# Test DX by calling ES API
log("Testing DX...")

$a4 = testDX

if($a4 -eq 0){ 
    warning("Canary not found, the Parrot is stone dead") 
    $deadParrot = $true
} else { 
    log("Canary found with $a4 result(s)")
}

# Probably don't need wait here tbh, but we're in no rush
log("Resting for 10 seconds")

sleep 10

# Test the AIE Event made it into the PM
log("Testing PM...")

$a9 = testPM
$a10 = $($a9 | measure-object).Count

if($a10 -eq 0){ 
    warning("Canary not found, the Parrot is stone dead")
    $deadParrot = $true 
} else { 
    log("Canary found|$($a10) result(s)") 
}

log("Is the Parrot dead? $(if($deadParrot -eq $false){'E`''stunned!'}else{'Stone dead!'}) )")

log("I never wanted to do this in the first place. I wanted to be... a lumberjack!")


# If anything component was dead, email results
if($deadParrot -eq $true){email($global:output)}else{''}