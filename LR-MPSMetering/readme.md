# LR-MPS Metering
This is a setup of scripts & resources you can use to extract detailed MPS metrics out of the LogRhythm TLM platform.  The example setup here used to collect, store and present the MPS metering is using ElasticStack 6.  Please note, this is not a supported LogRhythm solution, and is such just an example of how you can use the data available to you.

You'll need to customise the LogStash JDBC collection inteval and SQL DateAdd parameters accordingly.  The recommendation is to not collect MPS metrics below 24 hours, but beyond that ou can query and retrieve results in time based buckets as you require.

![LR MPS Metering](https://github.com/lrchma/LR-Utilities/blob/master/LR-MPSMetering/Screenshots/Kibana-Dashboard.png "LR MPS Dashboard")

![LR MPS Metering](https://github.com/lrchma/LR-Utilities/blob/master/LR-MPSMetering/Screenshots/Kibana-Discover.png "LR MPS Details")
