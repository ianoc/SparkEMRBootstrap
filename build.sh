ORIG_DIR="$( cd -P "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
source $ORIG_DIR/config.sh
if [ -z $SPARK_VERSION ]
then
    SPARK_VERSION="v0.7.0"
    SCALA_VERSION="2.9.2"
fi


if [ -z $SCALA_VERSION ]
then
    SCALA_VERSION="2.9.2"
fi

if [ -z $NAME ]
then
NAME="spark-${SPARK_VERSION}"
fi

if [ -z $DEB_HOST ]
then
echo "DEB_HOST has no defaults and must be defined"
exit 1
fi

SCALA_HOST=http://www.scala-lang.org/downloads/distrib/files/

echo "Clearing out old dir..."
cd $ORIG_DIR
rm -rf work
mkdir work
cd work 

echo "Building installer file"
cat>"install-${NAME}.sh"<<EOF
#!/bin/bash
export DEB_HOST="$DEB_HOST"
export NAME="$NAME"
EOF

cat $ORIG_DIR/install.sh.template >> install-${NAME}.sh
    
echo "Building control file..."
mkdir -p debian/DEBIAN
cat >"debian/DEBIAN/control" <<EOF
Package: spark
Version: 1.0
Section: cluster 
Priority: optional
Architecture: all
Essential: no
Maintainer: spark@ianoc.net
Description: install spark-mesos 
EOF

echo "populating init scripts..."
mkdir -p debian/etc/init.d

cat > "debian/etc/init.d/mesos-master.sh" <<EOF
#!/bin/bash

function start {
	/usr/local/sbin/mesos-daemon.sh mesos-master
}

function stop {
    killall -9 mesos-master
}

function reload {
    stop
    start
}

function status {
    log_warning_msg "Status is not supported"
}

case \$1 in
    'start' )
        start
        ;;
    'stop' )
        stop
        ;;
    'restart' )
        stop
        start
        ;;
    'force-reload' )
        reload
        ;;
    'status' )
        status
        ;;
    *)
        echo "usage: `basename $0` {start|stop|status}"
esac

exit 0
EOF

cat > "debian/etc/init.d/mesos-slave.sh" <<EOF
#!/bin/bash

function start {
	/usr/local/sbin/mesos-daemon.sh mesos-slave
}

function stop {
    killall -9 mesos-slave
}

function reload {
    stop
    start
}

function status {
    log_warning_msg "Status is not supported"
}

case \$1 in
    'start' )
        start
        ;;
    'stop' )
        stop
        ;;
    'restart' )
        stop
        start
        ;;
    'force-reload' )
        reload
        ;;
    'status' )
        status
        ;;
    *)
        echo "usage: `basename $0` {start|stop|status}"
esac

exit 0
EOF

echo "Copying mesos deb file into place"
mkdir -p debian/tmp
cp $ORIG_DIR/mesos_0.9.0-1_amd64.deb debian/tmp

echo "Copy base mesos config into place"
mkdir -p debian/usr/local/var/mesos/conf
cat > "debian/usr/local/var/mesos/conf/mesos.conf"<<EOF
failover_timeout=1
log_dir=/mnt/var/log/hadoop
master=
EOF

echo "Fetch and install scala version requested"
mkdir -p debian/home/hadoop
cd debian/home/hadoop
SCALA_RLS_NAME=scala-${SCALA_VERSION}
curl -O ${SCALA_HOST}/${SCALA_RLS_NAME}.tgz
tar zxvf ${SCALA_RLS_NAME}.tgz
mv ${SCALA_RLS_NAME} scala
touch scala/${SCALA_VERSION}
rm ${SCALA_RLS_NAME}.tgz
cd $ORIG_DIR/work

echo "Build spark.."
git clone https://github.com/mesos/spark debian/home/hadoop/spark
cd debian/home/hadoop/spark
git checkout $SPARK_VERSION
touch $SPARK_VERSION
rm -rf .git
cp project/SparkBuild.scala /tmp/
cat /tmp/SparkBuild.scala | sed -e 's/\s*val HADOOP_VERSION.*/val HADOOP_VERSION="0.20.205.0"/g' > project/SparkBuild.scala
time sbt/sbt package

cd $ORIG_DIR/work

dpkg-deb --build debian && mv debian.deb ${NAME}.deb

rm -rf $ORIG_DIR/work/debian
