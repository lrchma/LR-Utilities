$restoreDate = "2017"
$archive_count = get-childitem -recurse | where-object {$_.name -like "*$restoreDate*"} | measure-object 
$archive_size = @()
$avg_restoretime = 10 


$archives = get-childitem -recurse | where-object {$_.name -like "*$restoreDate*"} 
foreach($archive in $archives){
    $archive_size += ($archive.Length / 1Kb)
}

$avg_archive_size = $archive_size | Measure-Object -Sum

"For '$restoreDate' there are {0} archive files with an average size of {1:N2} Kb.  The estimated restore time for all files is {2} seconds, on assumption each archive takes 10 seconds to restore, and no filtering is taking place." -f $archive_count.Count, $($avg_archive_size.Sum / $archive_count.Count), $($avg_restoretime * $archive_count.Count)
