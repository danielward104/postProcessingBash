# Read qstat and translate to usable format.
save_qstat () {
    {
    echo $(qstat)       # Pipes output of qstat to file.
    } > a.txt
    {
    sed -r 's/.{182}//' a.txt      # Removes header.
    } > b.txt

    rm a.txt    2>/dev/null

    while [ -s b.txt ]; do  # Forever iterating while loop, to be broken below.
        test=$(awk '{print $5}' b.txt)      # Tests for status.
        if [[ $test = 'qw' ]] || [[ $test = 'Eqw' ]] || [[ $test = 'hqw' ]]
        then
            {   # 8 entries in qstat when test is satisfied here.
                awk '{print $1" "$2" "$3" "$4" "$5" "$6" "$7" "$8 }' b.txt
            } >> a.txt
            cut -d " " -f 9- b.txt > c.txt  # Removes first 8 entries from file.
            mv c.txt b.txt

        elif [[ $test = 'r' ]] || [[ $test = 'dr' ]]
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
        head -n $counter a.txt  # Only save the recently submitted jobs.
        } > $1
    else
        mv a.txt $1
    fi
    rm a.txt b.txt      2>/dev/null
}

qstat

echo -n "This will remove ALL jobs from the queue, are you sure you wish to continue (y/n)? "
read answer
    if echo "$answer" | grep -iq "^y";then
    
        save_qstat "job_status.txt" 0

        input3="job_status.txt"
        while IFS=" " read -r job_id priority name user status date time cores remainder
        do
            qdel $job_id
        done < "$input3"

    else
        echo "Deletion aborted."
    fi

rm job_status.txt
qstat

