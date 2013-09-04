# Does a single iteration of HERest training.
#
# This handles the parallel splitting and recombining
# of the accumulator files.  This is neccessary to 
# prevent inccuracies and eventual failure with large
# amounts of training data.
#
# According to Phil Woodland, one accumulator file 
# should be generated for about each hour of training
# data.
#
# Parameters:
#   $1 - root directory (where HMM directories are, tiedlist, wintri.mlf)
#   $2 - name of existing HMM directory
#   $3 - name of new output HMM directory
#   $4 - name of model list (tiedlist or monophones1)
#   $5 - training mlf (wintri.mlf or aligned2.mlf)
#   $6 - minimum examples -m switch for HERest
#   $7 - "text" if we want text output of HMM
#
# Environment variable $8 should be set to how 
# many chunks to split the training data into.
#
# This is a version that can split up the work amoung multiple
# processors/cores on the same machine.  The environment variable
# $9 controls the number of threads.  
# Thanks to Mikel Penagarikano.

# Delete any existing log file
rm -f $1/$3.log

# Make sure we have a place to put things
mkdir -p $1/$3

/home/nassos/bin/HERest.pl -B -m $6 -A -T 1 -s $1/$3/stats_$3 -C common/config -I $1/$5 -t 250.0 150.0 2000.0 -S train_temp_split_$T.scp -H $1/$2/macros -H $1/$2/hmmdefs -M $1/$3 $1/$4 

# Create all the accumulator files, parallaize over $9 workers
for ((I=1,J=0;I<=$8;)); do
    for ((T=0;T<$9&I<=$8;T++,I++,J++)); do
        perl $TRAIN_SCRIPTS/OutputEvery.pl train.scp $8 $J > train_temp_split_$T.scp

        HERest -B -m $6 -A -T 1 -p $I -s $1/$3/stats_$3 -C $TRAIN_COMMON/config -I $1/$5 -t 250.0 150.0 2000.0 -S train_temp_split_$T.scp -H $1/$2/macros -H $1/$2/hmmdefs -M $1/$3 $1/$4 > THREAD_$T.log &
    done
    wait
    for ((t=0;t<$T;t++)); do cat THREAD_$t.log >> $1/$3.log; rm THREAD_$t.log ; done
done

ls -1 $1/$3/HER*.acc >acc_files.txt

# Now combine them all and create the new HMM definition
if [[ $7 != "text" ]]
then
HERest -B -m $6 -A -T 1 -p 0 -s $1/$3/stats_$3 -C $TRAIN_COMMON/config -I $1/$5 -t 250.0 150.0 2000.0 -S acc_files.txt -H $1/$2/macros -H $1/$2/hmmdefs -M $1/$3 $1/$4 >>$1/$3.log
else
HERest -m $6 -A -T 1 -p 0 -s $1/$3/stats_$3 -C $TRAIN_COMMON/config -I $1/$5 -t 250.0 150.0 2000.0 -S acc_files.txt -H $1/$2/macros -H $1/$2/hmmdefs -M $1/$3 $1/$4 >>$1/$3.log
fi

rm -f train_temp_split.scp acc_files.txt
rm -f $1/$3/HER*.acc
