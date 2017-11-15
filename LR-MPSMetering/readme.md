# LR-MPS Metering
This is a collection of scripts & resources you can use to extract detailed MPS metrics out of the LogRhythm TLM platform.  The example setup here used to collect, store and present the MPS metering is just that, an example, and is not a supported LogRhythm solution.  

In this repository you'll find a SQL script to extract MPS data from LogMart, and for demonstration purposes I've used an ElasticStack to collect and visualize the results.  If you make use of this setup, you'll need customise:
* the LogStash JDBC collection inteval and SQL DateAdd parameters accordingly
** The recommendation is to not collect MPS metrics below 24 hours, but beyond that ou can query and retrieve results in time based buckets as you require.  
* the port used by Elastic, and again running an ElasticStack on any LogRhythm component is not a supported setup

Examples of the integration are as follows:

![LR MPS Metering](https://github.com/lrchma/LR-Utilities/blob/master/LR-MPSMetering/Screenshots/Kibana-Dashboard.png "LR MPS Dashboard")

![LR MPS Metering](https://github.com/lrchma/LR-Utilities/blob/master/LR-MPSMetering/Screenshots/Kibana-Discover.png "LR MPS Details")
