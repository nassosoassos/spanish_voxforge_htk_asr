datapath=$1
rootpath=$2
pserimospath=$3

relpath=`echo $datapath | sed -e "s,$rootpath[/]*,,"`

for host in {kos,karpathos,symi,rodos,ro}
do  
    ssh $host "rm -rf /local/nassos/$relpath; mkdir -p /local/nassos/$relpath; scp -r pserimos:$pserimospath `dirname /local/nassos/$relpath`;"  &
done
