#!/bin/bash

logfile="sysbench.log"

if [[ ! -f "$logfile" ]]; then
    echo "Error: Log file '$logfile' not found!" >&2
    exit 1
fi

if [[ ! -r "$logfile" ]]; then
    echo "Error: Cannot read log file '$logfile'!" >&2
    exit 1
fi

output=()

test_counter=0

current_test=""

while IFS= read -r line; do
    if [[ "$line" == sysbench*"(using bundled LuaJIT"* ]]; then
        ((test_counter++))

        case $test_counter in
            1)
                current_test="cpu"
                ;;
            2)
                current_test="memory"
                ;;
            3)
                current_test="fileio"
                ;;
            *)
                current_test="other"
                ;;
        esac

        continue
    fi

     case "$current_test" in
        "cpu")
            if [[ "$line" == *"CPU events per second"* ]]; then
                value=$(echo "$line" | awk '{for(i=1;i<=NF;i++) if ($i ~ /^[0-9.]+$/) {print $i; exit}}')
                output+=("Score:Score:CPU events per second:$value:eps:HB:")
            elif [[ "$line" == *"CPU total number of events"* ]]; then
                value=$(echo "$line" | awk '{for(i=1;i<=NF;i++) if ($i ~ /^[0-9.]+$/) {print $i; exit}}')
                output+=("Score:Score:CPU total number of events:$value:Events:HB:")
            elif [[ "$line" == *"CPU Latency avg"* ]]; then
                value=$(echo "$line" | awk '{for(i=1;i<=NF;i++) if ($i ~ /^[0-9.]+$/) {print $i; exit}}')
                output+=("Score:Score:CPU Latency avg:$value:ms:HB:")
            fi
            ;;

        "memory")
            if [[ "$line" == *"Memory operations per second"* ]] || [[ "$line" == *"Memory Total operations per sec"* ]]; then
                value=$(echo "$line" | awk '{for(i=1;i<=NF;i++) if ($i ~ /^[0-9.]+$/) {print $i; exit}}')
                output+=("Score:Score:Memory Total operations per sec:$value:ops:HB:")
            elif [[ "$line" == *"Memory MiB transferred"* ]]; then
                value=$(echo "$line" | awk '{for(i=1;i<=NF;i++) if ($i ~ /^[0-9.]+$/) {print $i; exit}}')
                output+=("Score:Score:Memory MiB transferred:$value:MiB:HB:")
            elif [[ "$line" == *"Memory Latency avg"* ]]; then
                value=$(echo "$line" | awk '{for(i=1;i<=NF;i++) if ($i ~ /^[0-9.]+$/) {print $i; exit}}')
                output+=("Score:Score:Memory Latency avg:$value:ms:HB:")
            fi
            ;;

        "fileio")
            if [[ "$line" == *"reads/s:"* ]] && [[ "$line" != *"initializing"* ]]; then
                value=$(echo "$line" | awk '{for(i=1;i<=NF;i++) if ($i ~ /^[0-9.]+$/) {print $i; exit}}')
                output+=("Score:Score:SSD reads/s:$value:r/s:HB:")
            elif [[ "$line" == *"writes/s:"* ]]; then
                value=$(echo "$line" | awk '{for(i=1;i<=NF;i++) if ($i ~ /^[0-9.]+$/) {print $i; exit}}')
                output+=("Score:Score:SSD writes/s:$value:w/s:HB:")
            elif [[ "$line" == *"syncs/s:"* ]]; then
                value=$(echo "$line" | awk '{for(i=1;i<=NF;i++) if ($i ~ /^[0-9.]+$/) {print $i; exit}}')
                output+=("Score:Score:SSD syncs/s:$value:s/s:HB:")
            elif [[ "$line" == *"Throughput read, MiB/s:"* ]]; then
                value=$(echo "$line" | awk '{for(i=1;i<=NF;i++) if ($i ~ /^[0-9.]+$/) {print $i; exit}}')
                output+=("Score:Score:SSD Throughput read, MiB/s:$value:MiB/s:HB:")
            elif [[ "$line" == *"Throughput written, MiB/s:"* ]]; then
                value=$(echo "$line" | awk '{for(i=1;i<=NF;i++) if ($i ~ /^[0-9.]+$/) {print $i; exit}}')
                output+=("Score:Score:SSD Throughput written, MiB/s:$value:MiB/s:HB:")
            elif [[ "$line" == *"Latency avg"* ]]; then
                value=$(echo "$line" | awk '{for(i=1;i<=NF;i++) if ($i ~ /^[0-9.]+$/) {print $i; exit}}')
                output+=("Score:Score:SSD Latency avg:$value:ms:HB:")
            fi
            ;;
        "other")
           
            ;;
    esac

done < "$logfile"

for result in "${output[@]}"; do
    echo "$result"
done