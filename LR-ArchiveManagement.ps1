<#

.NAME
Get-LR-Archives



.SYNOPSIS
Utility to manage LogRhythm Archives files



.DESCRIPTION
LogRhythm, by default, doesn't delete Inactive Archives, ever!  For storage or compliance reasons you may wish to automatically delete or move InactiveArchives after a certain period. 

The Get-LR-Archives function enables you to do just that.   

This should be run on the XM, DP or SAN that stores archives.  The default location for Archives is "C:\LogRhythmArchives\Inactive" and days to delete is 1 year.

Archive Naming Convention: 20131114_3_1_1_635199840557441540.lca

20131114               < Year, Month, Day
_3                     < Log Source ID
_1                     < Agent ID
_1                     < Mediator
_635199840557441540    < Probably Means Something
.lca                   < File Extension



.EXAMPLE
Delete InactiveArchives older than 365 days
.\ArchiveManagement.ps1 -action dryrun -inactive_archives_location "C:\LogRhythmArchives\Inactive" -archives_older_than "10" -filter "*2017*"

Delete InactiveArchives for 2015 
.\ArchiveManagement.ps1 -action dryrun -inactive_archives_location "C:\LogRhythmArchives\Inactive" -archives_older_than "9999" -filter "2015****_"

Delete InactiveArchives for LogSource ID 2 from 2017
.\ArchiveManagement.ps1 -action dryrun -inactive_archives_location "C:\LogRhythmArchives\Inactive" -archives_older_than "9999" -filter "2017****_2_*"

Size InactiveArchives for all log sources over 9999 days
.\ArchiveManagement.ps1 -action size -inactive_archives_location "C:\LogRhythmArchives\Inactive" -archives_older_than 9999



.PARAMETER action

Dryrun = Test without making changes, a good place to start
Delete = Delete archives, be really sure you want do this!
Move = Move archives, note you need include the trailing \ on your new path or will error
Size = Calculates the size of InactiveArchive files in MB



.NOTES
June 2017 @chrismartin



.LINK
https://github.com/lrchma/

#>
    
param(
  [Parameter(Mandatory=$true)]
  [string]$action,
  [Parameter(Mandatory=$true)]
  [string]$inactive_archives_location = 'C:\LogRhythmArchives\Inactive',
  [Parameter(Mandatory=$true)]
  [int]$archives_older_than = 365,
    [Parameter(Mandatory=$false)]
  [string]$filter = '*',
  [Parameter(Mandatory=$false)]
  [string]$new_inactive_archives_location = ''
)


################################################################################
# MAIN
################################################################################

try
{

# Set the date of archives to be deleted, defaults to 1 year
$then = (get-date).AddDays($archives_older_than).ToString("yyyMMdd")

    switch ($action)
    {
        delete 
              {
                  $choice = ""
                    while ($choice -notmatch "[y|n]"){
                        $choice = read-host "This action will permanently delete data, are you sure you want to continue? (Y/N)"
                        }

                    if ($choice -eq "y"){
                        Get-ChildItem $inactive_archives_location -recurse -filter $filter| ForEach {
                                if ($_.name.split("_")[0] -lt $then) #wish I could remember why I wrote this, but sure it does something
                                    {
                                        Remove-Item $_.FullName -whatif
                                        Remove-Item $_.FullName -Force
                                    }
                            }
                        }
                    else {
                        exit
                    }
                }
        dryrun 
               {
                Get-ChildItem $inactive_archives_location -recurse -filter $filter | ForEach {
                        if ($_.name.split("_")[0] -lt $then)
                            {
                                Remove-Item $_.FullName -whatif
                            }
                    }
               }
        move
               {
                Get-ChildItem $inactive_archives_location -recurse -filter $filter | ForEach {
                        if ($_.name.split("_")[0] -lt $then)
                            {
                                Move-Item $inactive_archives_location\$_ $new_inactive_archives_location
                            }
                    }
               }
        size
               {
                Get-ChildItem $inactive_archives_location -recurse -filter $filter| ForEach {
                        if ($_.name.split("_")[0] -lt $then)
                            {
                                 foreach ($file in Get-ChildItem $inactive_archives_location\$_ -Recurse) 
                                    { 
                                        "File:{0},Size:{1}" -f $file.ToString(), ((Measure-Object -inputObject $file -Property Length -Sum -ErrorAction Stop).Sum / 1MB) 
                                    }
                            }
                    }
               }
        }
}
   catch
   {
            $ErrorMessage = $_.Exception.Message
            write-host $ErrorMessage 
    }




