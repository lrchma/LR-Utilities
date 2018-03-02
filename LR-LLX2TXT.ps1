param(
  [Parameter(Mandatory=$false)]
  [string]$llxFile = "C:\Users\chris.martin\Desktop\LLX2TXT\pan_SubmittedLogs_109374_20090724_15582080.llx.txt"
)


if(!(test-path -Path $llxFile)){
    write-output "Input file not found - $llxFile"
    exit
}

if(!(test-path -Path strings.exe)){
    write-output "strings.exe not found.  Download from - https://docs.microsoft.com/en-us/sysinternals/downloads/strings"
    exit
}else{
    .\strings.exe -accepteula -nobanner | out-null
    $tempFile = .\strings.exe $llxFile
}

$tempTempFile = @()

#Remove most fluff, and that'll leave us with 18 header rows and remainder raw logs
foreach($line in $tempFile){
    if($line.Length -ge 10){
        $tempTempFile += $line
    }
}

#With the above pruning the raw logs will always start from line 18 onwards
for ($counter=0; $counter -lt $tempTempFile.Length; $counter++){
    if($counter -ge 18){
        write-output $tempTempFile[$counter] 
    }
}

#Hey, it's crude but it works!
