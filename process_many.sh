## Reads from list of files to process.
cwd=$(pwd)
rm dirs.txt    2>/dev/null
num_process=0

runscript='plumeOutline'

if [ $runscript == 'plumeOutline' ]
then
    # Switch to plumeOutline script.
    sed -i "s/switch =.*#/switch = 1      #/" ./postProcess.py
elif [ $runscript == 'makeVideo' ]
then
    # Switch to makeVideo script.
    sed -i "s/switch =.*#/switch = 2      #/" ./postProcess.py
fi

# Runs through every line in file.
while IFS="," read -r numelz jump sval simulation remainder
do
    echo Processing in "$simulation".
    echo Numelz = "$numelz".

    # Go to root simulation directory.
    cd $simulation
    # Save all sub-directories in dirs.txt.
    ls >> ${cwd}/dirs.txt
    # Run through loop of all sub-directories.
    while IFS= read -r folders
    do
        cd $folders
        cp ${cwd}/postProcess.py .
        cp ${cwd}/run_python.sh .
        # Replace value of jump in postProcess.py.
        sed -i "s/jump =.*#/jump = $jump      #/" ./postProcess.py
        # Replace value of numelz in postProcess.py.
        sed -i "s/numelz =.*#/numelz = $numelz      #/" ./postProcess.py
        # Replace value of s-value in postProcess.py.
        sed -i "s/s-value =.*#/s-value = $sval      #/" ./postProcess.py

        qsub run_python.sh
        ((num_process=num_process+1))

        cd ..
    done < "${cwd}/dirs.txt"
    rm ${cwd}/dirs.txt    

    echo
 
done < <(tail -n +2 "list_to_process.txt")   # Skips the first line of input.

cd $cwd

echo "$num_process" processes submitted.
echo 

## Moves data after simulations are complete.

# Read qstat and translate to usable format.  Only works as long as there aren't two numbers at the end of qstat.  Which I don't think I'll ever have but who knows...
record_qstat () {
    {
    echo $(qstat)       # Pipes output of qstat to file.
    } > a.txt
    {
    sed -r 's/.{182}//' a.txt      # Removes header.
    } > b.txt

    rm a.txt    2>/dev/null

    while [ -s b.txt ]; do  # Forever iterating while loop, to be broken below.
        test=$(awk '{print $5}' b.txt)      # Tests for status.
        if [[ $test = 'qw' ]] || [[ $test = 'Eqw' ]] || [[ $test = 'hqw' ]] || [[ $test = 't' ]]
        then
            {   # 8 entries in qstat when test is satisfied here.
                awk '{print $1" "$2" "$3" "$4" "$5" "$6" "$7" "$8 }' b.txt
            } >> a.txt
            cut -d " " -f 9- b.txt > c.txt  # Removes first 8 entries from file.
            mv c.txt b.txt

        elif [[ $test = 'r' ]] || [[ $test = 'dr' ]] || [[ $test = 'dt' ]]
        then
            {   # 8 entries in qstat when test is satisfied here.
                awk '{print $1" "$2" "$3" "$4" "$5" "$6" "$7" "$8" "$9 }' b.txt
            } >> a.txt
            cut -d " " -f 10- b.txt > c.txt # Removes first 9 entries from file.
            mv c.txt b.txt
        else
            break
        fi
    done
    if [[ $2 -eq 1 ]]
    then
        {
        tail -n $num_process a.txt  # Only save the recently submitted jobs.
        } > $1
    else
        mv a.txt $1
    fi
    rm a.txt b.txt      2>/dev/null
}

record_qstat "job_status.txt" 1

job_list=()
while IFS=" " read -r job_id remainder
do
    job_list+=($job_id)
done < "job_status.txt"

# Check whether 'tester' exists in 'job_list'.  If so check = 0, if not check = 1.
contains() {
    check=0
    arr=("$@")
    contains_count=0
    vals=$(seq 1 1 $num_process)
    for x in $vals
    do
        if [ "${arr[$x]}" == $1 ]
        then
            check=0
            break
        else
            ((contains_count=contains_count+1))
        fi
    done
    if [ $contains_count -eq $num_process ]
    then
        check=1
    fi

#    if [ $check -eq 0 ]
#    then
#        echo "Test does exist in the list."
#    elif [ $check -eq 1 ]
#    then
#        echo "Test does not exist in the list."
#    else
#        echo "Some other error"
#    fi

}   

#tester=${job_list[0]}
#tester=9383842

#contains $tester ${job_list[@]}

finished_jobs=0
while [ $finished_jobs -lt $num_process ]
do
    record_qstat "tester.txt" 0

    test_list=()
    while IFS=" " read -r job_id remainder
    do
        test_list+=($job_id)
    done < "tester.txt"

    #echo Job list :  "${job_list[@]}"
    #echo Test list: "${test_list[@]}"

    finished_jobs=0
    for original in ${job_list[@]}
    do
        contains $original ${test_list[@]}
        if [ $check -eq 1 ]
        then
            ((finished_jobs=finished_jobs+1))
        fi
    done

    echo "$finished_jobs" of the jobs have finished.

    rm "tester.txt"     2>/dev/null

    sleep 30m

done

rm job_status.txt

## Moves all data to '/nobackup/scdrw/processing/rise_heights' and renames for easy-viewing.
# Runs through every line in file.
while IFS="," read -r numelz jump simulation Re Res remainder
do
    echo Copying from "$simulation".

    # Go to root simulation directory.
    cd $simulation
    # Save all sub-directories in dirs.txt.
    ls >> ${cwd}/dirs.txt
    repeats=1
    # Run through loop of all sub-directories.
    while IFS= read -r folders
    do
        cd $folders

        cp *.file /nobackup/scdrw/processing/rise_heights
        cd /nobackup/scdrw/processing/rise_heights
        ./rename_script.sh $Re $Res $repeats

        ((repeats=repeats+1))

        cd $simulation

    done < "${cwd}/dirs.txt"
    rm ${cwd}/dirs.txt

    echo

done < <(tail -n +2 "list_to_process.txt")   # Skips the first line of input.

# Also include s-value.
# Also include which script to run (e.g. makeVideo or computeOutline).


