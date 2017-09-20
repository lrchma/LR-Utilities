Usage: lrarchiveutil.exe <options>
                Valid parameter forms: {-,/,--}param{ ,=,:}((",')value(",'))
                Parameters are case sensitive

General options:
                -?,-help Prints command help
                -o <filepath> Write log to file <filepath>

Event Manager database connection options:
                -S <server> Connect to the event manager server <server> (defalut localhost)
                -I <instancename> Connect to the event manager on sql server instance <instancename> (default instance if not specified)
                -E Connect to the event manager database with integrated security
                -U <username> Connect to the event manager database as <username> (must be combined with the -P option)
                -P <password> Connect to the event manager database with <password> (must be combined with the -U option)
                -T <#> Command timeout for event manager database queries in seconds

Archive directory options:
                -s <path> The source archive directory for the specified archive operation
                -d <path> The destination directory for the specified archive operation

Archive conversion operations:
                -cT Convert specified archives to text format (must be combined with -s and -d options)
                -In Include LogRhythm NormalMsgDate with converted logs
                -Ih Include header line in each converted archive
                -gz Gzip converted log files

Archive information operations:
                -r <archivefilepath> Report archive info for archive <archivefilepath>
                -v Verify archives (must be combined with -s option)
                -p Parallelize archive verification

Archive repair operations:
                -rH Recalculate archives hashes (must be combined with -s option)
