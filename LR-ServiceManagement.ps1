[CmdletBinding()]
Param (
    [Parameter(Position=0)]
    [string]$action
)

$services = "lrjobmgr","scarm","LRAIEComMgr","LRAIEEngine","scmedsvr","scsm","LogRhythmServiceRegistry","lrtfsvc","LogRhythmWebConsoleAPI","LogRhythmWebConsoleUI","LogRhythmWebIndexer","LogRhythmWebServicesHostAPI"

if( $action -eq "stop" -Or $action -eq "restart") {
	Write-Host "Stopping the LogRhythm services..."
	# Stop LogRhythm services
	$ScriptBlock = {
		param($s)
		$service = Get-Service $s
		if($service.Status -eq "Running") {
			Stop-Service $s
		}
	}
	foreach($s in $services) { Start-Job $ScriptBlock -ArgumentList $s | out-null}

	$KeepRunning = $true
	$i = 0
	While ($KeepRunning)
	{
		
		$jobs = Get-Job -State "Running" | out-null
		if($jobs.ChildJobs.count -gt 0) {
			Write-Progress -Activity "Stopping LogRhythm Services" -Status "Stopping services" -percentComplete ($i)
		$i = $i + 15
		} else {
			$KeepRunning = $false}
		Start-Sleep -s 1
	}


	$all_stopped = $false
	$timer = 0
	$sleep_seconds = 5
	$timer_max = 60
	while($timer -lt $timer_max -AND -NOT $all_stopped)
	{
		$i = 0
		if($timer -eq 0)
		{
			Write-Host "Checking status of the LogRhythm services..."
		}
		else
		{
			Write-Host "Checking status of the LogRhythm services, waiting $timer of $timer_max seconds..."
		}
		foreach($s in $services) 
		{
			$status = (Get-Service | Where-Object { $_.Name -eq $s} ).status
			# Write-Host "$s status is: $status"
			if( $status -eq "Pending" -OR $status -eq "StopPending" )
			{
				$all_stopped = $false
				Write-Host -ForegroundColor Yellow " $s is still stopping..."
			}
			elseif($status -eq "Stopped")
			{
				if($i -eq 0)
				{
					$all_stopped = $true
				}
				Write-Host -ForegroundColor Green " $s is stopped!"
			}
			elseif($timer -ge $timer_max - $sleep_seconds )
			{
				$all_stopped = $false
			}
			elseif($status -eq "Running")
			{
				$all_stopped = $false
				Write-Host -ForegroundColor Yellow " $s is still running."
			}
			else
			{
				$all_stopped = $false
				Write-Host -ForegroundColor Yellow " $s is in status: $status"
			}
			$i = $i + 1
		}
		$timer = $timer + $sleep_seconds
		Start-Sleep -s $sleep_seconds
	}
	if($all_stopped)
	{
		Write-Host -ForegroundColor Green "Successfully stopped all of the LogRhythm services!"
		Start-Sleep -s $sleep_seconds
	}
	else
	{
		Write-Host -ForegroundColor Red "$s has not yet stopped & this script has run out of patience!"
		Write-Host -ForegroundColor Red "Please make sure this service is stopped before continuing."
		$message = "Would you like to continue?"
		$result = $Host.UI.PromptForChoice($caption,$message,$choices,0)
		if($result -eq 1) { exit }
	}
	
	$dxTools="C:\Program Files\LogRhythm\Data Indexer\tools\stop-all-services.bat"
	if (Test-Path $dxTools){
	  $a = Start-Process -FilePath $dxTools -Wait -passthru;
	  if ($a.ExitCode -eq 0) {
		Write-Host -ForegroundColor Green "Successfully stopped all of the DX services!"
	  } else {
		Write-Host -ForegroundColor Red "Error stopping the DX services!"
	  }
	} else{
	  Write-Host "Can't find the DX tools; DX Services are not being stopped."
	}
}

if( $action -eq "start" -Or $action -eq "restart") {
	Write-Host "Starting the LogRhythm services..."
	# Start LogRhythm services
	$ScriptBlock = {
		param($s)
		$service = Get-Service $s
		if($service.Status -eq "Stopped") {
			Start-Service $s
		}
	}
	foreach($s in $services) { Start-Job $ScriptBlock -ArgumentList $s | out-null}

	$KeepRunning = $true
	$i = 0
	While ($KeepRunning)
	{
		
		$jobs = Get-Job -State "Running" | out-null
		if($jobs.ChildJobs.count -gt 0) {
			Write-Progress -Activity "Starting LogRhythm Services" -Status "Starting services" -percentComplete ($i)
		$i = $i + 15
		} else {
			$KeepRunning = $false}
	}


	$all_started= $false
	$timer = 0
	$sleep_seconds = 5
	$timer_max = 60
	while($timer -lt $timer_max -AND -NOT $all_started)
	{
		if($timer -eq 0)
		{
			Write-Host "Checking status of the LogRhythm Services..."
		}
		else
		{
			Write-Host "Checking status of the LogRhythm services, waiting $timer of $timer_max seconds..."
		  
		}
		foreach($s in $services) 
		{
			$i = 0
			$status = (Get-Service | Where-Object { $_.Name -eq $s} ).status
			if($status -eq "StartPending") {
				#Write-Host "service $s status: $status"
				Write-Host -ForegroundColor Yellow " $s is still starting..."
				$all_started = $false
			}
			elseif($status -eq "Running")
			{
				if($i -eq 0)
				{
					$all_started = $true
				}
				Write-Host -ForegroundColor Green " $s has started!"
			}
			elseif($timer -ge $timer_max - $sleep_seconds )
			{
				$all_started=$false
				
			}
			elseif($status -eq "Stopped")
			{
				 Write-Host -ForegroundColor Yellow " $s is still stopped."
				 $all_started = $false
			}
			
			else
			{
				$all_started=$false
				Write-Host -ForegroundColor Yellow " $s is in status: $status"
			}
			$i = $i + 1
		}
		$timer = $timer + $sleep_seconds
		Start-Sleep -s $sleep_seconds
	}
	if($all_started)
	{
		Write-Host -ForegroundColor Green "Successfully started all of the LogRhythm services!"
	}
	else
	{
		Write-Host -ForegroundColor Red "$s has not yet started & this script has run out of patience!"
		Write-Host -ForegroundColor Red " Please ensure the service has started."
	}
	
	$dxTools="C:\Program Files\LogRhythm\Data Indexer\tools\start-all-services.bat"
	if (Test-Path $dxTools){
	  $a = Start-Process -FilePath $dxTools -Wait -passthru;
	  if ($a.ExitCode -eq 0) {
		Write-Host -ForegroundColor Green "Successfully started all of the DX services!"
	  } else {
		Write-Host -ForegroundColor Red "Error starting the DX services!"
	  }
	} else{
	  Write-Host "Can't find the DX tools; DX Services are not being started."
	}
}