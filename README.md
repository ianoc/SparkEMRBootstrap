SparkEMRBootstrap
=================

Based on the work for:
http://aws.amazon.com/articles/4926593393724923

Trimmed back for the moment not to include shark and just be spark specific.
The guide above had gotten quite out of date, and there are multiple versions of spark or settings one might like to use.
I tweaked some settings around where to place temp files on nodes with a /mnt but no /mnt1 (2XL's).

To use:

1. Start small EMR cluster (1 worker is sufficent) such that you have a machine available with the right environment
2. SSH to that machine
3. Clone this repo
4. Edit the config.sh to put in a URL to an S3 bucket or other HTTP host that is available from the launched EMR nodes.
  You should place the generated .deb file at this path. The other defaults will give the 0.7.0 release of spark.
5. Run the ./build.sh
6. Use the *deb and *sh file in the work folder that are produced



* if using the elastic mapreduce command from the command line, the installer script I place in the same bucket often and should be referenced like..
   --bootstrap-action s3://\<Your bucket>/\<folder structure>/\<generated script name>.sh 
* I've tested the generated deb's with XL, 2XL's and cc2.xlarge. The cluster compute nodes appear to be unstable in testing, but this looks to be unrelated.
* when the cluster launches its worth tunneling to the mesos page
   ssh -L5050:localhost:5050 hadoop@EMR_master
* Tested with AMI's v 2.0 and 2.2



#Sample remote deploy

This is just a simple script that will copy over the code from the local workspace. Build an assembly jar on what is presumed to be your master node, and then run it in a screen session.
