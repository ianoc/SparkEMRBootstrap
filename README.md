SparkEMRBootstrap
=================

Based on the work for:
http://aws.amazon.com/articles/4926593393724923

Trimmed back for the moment not to include shark and just be spark specific.
The guide above had gotten quite out of date, and there are multiple versions of spark or settings one might like to use.
I tweaked some settings around where to place temp files on nodes with a /mnt but no /mnt1 (2XL's).

to use

edit the config.sh to put in a URL to an S3 bucket or other HTTP host that is available from the launched EMR nodes.
You should place the generated .deb file at this path. The other defaults will give the 0.7.0 release of spark.

The installer script I place in the same bucket often and should be referenced like..
--bootstrap-action s3://<Your bucket>/<folder structure>/<generated script name>.sh 

if using the elastic mapreduce command from the command line.


when the cluster launches its worth tunneling to the mesos page

ssh -L5050:localhost:5050 hadoop@EMR_master
