#job-ID  prior   name       user         state submit/start at     queue                          slots ja-task-ID
#-----------------------------------------------------------------------------------------------------------------

# Read qstat and translate to usable format.  Only works as long as there aren't two numbers at the end of qstat.  Which I don't think I'll ever have but who knows...
record_qstat () {
    {
    echo $(qstat)       # Pipes output of qstat to file.
    } > a.txt
    {
    sed -r 's/.{182}//' a.txt
    } > b.txt

    rm a.txt    2>/dev/null

    while [ -s b.txt ]; do
        test=$(awk '{print $5}' b.txt)
        if [[ $test = 'qw' ]] || [[ $test = 'Eqw' ]] || [[ $test = 'hqw' ]]
        then
            echo $test
            {
                awk '{print $1" "$2" "$3" "$4" "$5" "$6" "$7" "$8 }' b.txt
            } >> a.txt
            cut -d " " -f 9- b.txt > c.txt
            mv c.txt b.txt

        elif [ $test = 'r' ] || [ $test = 'dr' ]
        then
            echo $test
            {
                awk '{print $1" "$2" "$3" "$4" "$5" "$6" "$7" "$8" "$9 }' b.txt
            } >> a.txt
            cut -d " " -f 10- b.txt > c.txt
            mv c.txt b.txt
        else
            break
        fi
    done
}

record_qstat "job_status.txt"
