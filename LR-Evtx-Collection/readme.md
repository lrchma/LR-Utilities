# LR-Evtx-Collector

PowerShell wrapper around Microsoft LogParser for reading raw EVTX files into LogRhythm.

## Usage
./LR-Evtx-Collector.ps1 -evtxFile "path\file.evtx" -outputFile "path\file.csv"


## Example

./LR-Evtx-Collector.ps1 [-logParser] <string[]> [-evtxFile] <string[]> [-evtxQuery] <string[]> [-outputFile] <string[]> [-debugMode <bool>]

## Setup in LogRhythm

* Import the MPE rule within this repository
* Optionally, add a timestamp filter as below
** Log Source Timestamp Format = Windows EVTX (^<YY>-<M>-<d> <h>:<m>:<s>,)
** If your EVTX files have logs older than 90 days, you may wish to omit the timestamp as otherwise the logs will be dropped and not indexed.

## Notes
* script requires Microsoft's LogParser, download it here - https://www.microsoft.com/en-us/download/details.aspx?id=24659
* EVTX files under C:\Windows\System32\winevt\Logs cannot be read, they're locked by Windows.  If you need read these in copy them elsewhere first.
* EVTX files with a space in them will cause an exception.  At this time you'll need remove the space until it's fixed.


