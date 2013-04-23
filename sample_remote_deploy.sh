REMOTE_USER=hadoop
remote_host=$SPARK_CLUSTER
current_user=$USER

if [ -z "$SPARK_CLUSTER"]
    then
    echo "Must supply a remote cluster"
    exit 1
fi


tmp_name=`date +"%Y%m%d--%H-%M-%S"`
tmp_dir=$(mktemp -d -t Spark-tmp-XXXXXX)


checkout_root="$( cd -P "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
remote_storage="~${REMOTE_USER}/deploys/${current_user}/${tmp_name}"
ssh_options="-a"

ssh $ssh_options ${REMOTE_USER}@${remote_host} -- "mkdir -p $remote_storage"
rsync -e "ssh $ssh_options" -aP --exclude 'target' --exclude '*.log' \
    --exclude 'tmp' \
    $checkout_root/* ${REMOTE_USER}@${remote_host}:${remote_storage}



cat >"$tmp_dir/run.sh" <<EOF
!#/bin/bash
#Allow the usage of a REMOTE_USER env var
export REMOTE_USER=$USER
sudo apt-get install -y screen time
DEPLOY_DIR=$remote_storage

cd $remote_storage && sbt/sbt package && sbt/sbt assembly && sbt/sbt run 2> $remote_storage/stderr.log > $remote_storage/stdout.log

echo "hit enter to exit..."
sleep 91231412332 # For some reason a read here to block wasn't working in some AMI's

EOF
chmod +x "$tmp_dir/run.sh"

rsync -e "ssh $ssh_options" -aP $tmp_dir/run.sh ${REMOTE_USER}@${remote_host}:${remote_storage}


ssh   $ssh_options ${REMOTE_USER}@${remote_host} -- sudo apt-get install -y screen
ssh   $ssh_options ${REMOTE_USER}@${remote_host} -- screen -S $USER -d -m $remote_storage/run.sh
