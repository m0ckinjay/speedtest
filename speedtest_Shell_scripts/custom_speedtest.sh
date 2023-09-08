#!/bin/bash
# These values can be overwritten with env variables
LOOP="${LOOP:-false}"
LOOP_DELAY="${LOOP_DELAY:-60}"
_SAVE="${_SAVE:-false}"


run_speedtest()
{
    DATE=$(date +%s)
    HOSTNAME=$(hostname)

    # Start speed test
    echo "Running a Speed Test..."
    JSON=$(speedtest --accept-license --accept-gdpr -f json)
    DOWNLOAD="$(echo $JSON | jq -r '.download.bandwidth')"
    UPLOAD="$(echo $JSON | jq -r '.upload.bandwidth')"
    PING="$(echo $JSON | jq -r '.ping.latency')"
    echo "Your download speed is $(($DOWNLOAD  / 125000 )) Mbps ($DOWNLOAD Bytes/s)."
    echo "Your upload speed is $(($UPLOAD  / 125000 )) Mbps ($UPLOAD Bytes/s)."
    echo "Your ping is $PING ms."

    # Save results in a file
    if $_SAVE; 
    then
        echo "Saving values to file..."
        echo "download,host=$HOSTNAME value=$DOWNLOAD $DATE" >> /opt/speedtest/speedtest_results.txt
        echo "upload,host=$HOSTNAME value=$UPLOAD $DATE" >> /opt/speedtest/speedtest_results.txt
        echo "ping,host=$HOSTNAME value=$PING $DATE" >> /opt/speedtest/speedtest_results.txt
        echo "Values saved."
    fi
}
#executes python file that writes speedtest_result file to db
write_file_to_db(){
    /opt/speedtest/influx_write_venv/bin/python3 /opt/speedtest/influx_write/influx_db_write.py
    
        
}

#set count to 0, when get's to five, write to db
count=0

if $LOOP;
then
   

    while :
    do
        #increment count
        count=$(expr $count + 1)

        run_speedtest
        echo "Running next test in ${LOOP_DELAY}s..."
        echo ""
        sleep $LOOP_DELAY

        echo "Count is $count"

        if [[ $count = 1 ]]
        then
            if write_file_to_db;
            then
                echo "Values saved to db, deleting previous records"
                echo > /opt/speedtest/speedtest_results.txt
                if [[ $? = 0 ]]
                then
                echo "Previous records deleted"
                count=0
                else
                echo "Failed to delete previous records"
                fi
            else
                echo "Failed to save to db"
            fi

        fi
    done
else
    run_speedtest   
fi
