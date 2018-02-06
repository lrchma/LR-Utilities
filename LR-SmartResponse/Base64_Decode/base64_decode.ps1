param(
  [Parameter(Mandatory=$false)]
  [string]$action = 'decode',
  [Parameter(Mandatory=$false)]
  [string]$value = "dGhpcyBpcyBhIHRlc3Qgb2YgYmFzZTY0IGVuY29kaW5nIGFuZCBkZWNvZGluZw==",
  [Parameter(Mandatory=$false)]
  [string]$jsonMode = $true				#JSON mode removes additional backslashes in the base64 string 
)


Function Base64Decode($value) 
{
	if($jsonMode = $True){
		$value = $value.replace("\=","=");
	}
		
    if($value -match "(.*\s|^)(?<base64>(?:[A-Za-z0-9+/]{4})*(?:[A-Za-z0-9+/]{2}==|[A-Za-z0-9+/]{3}=)?)($|'|\s.+)"){
        $result = [System.Text.Encoding]::UNICODE.GetString([System.Convert]::FromBase64String($matches.base64))
    }else{
        $result = "No base64 encoded strings found."
    }    

    
    if($result.Length -lt 4096){
        return $result
    }else{
        return $result.substring(0,4095)
    }
}


try{
    switch ($action)
    {
        "decode"  {
            Base64Decode($value)
        }  
    }

 }
 catch{
        Write-Error "SmartResponse error.  Exception details: $ErrorMessage = $_.Exception.Message"
        exit 1
}
