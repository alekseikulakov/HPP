#!/bin/bash

logfile="log.txt"

if [[ ! -f "$logfile" ]]; then
    echo "Error: $logfile not found!" >&2
    exit 1
fi

get_num() {
    echo "$1" | grep -oE '[0-9]+\.[0-9]+|[0-9]+' | head -1
}

cpu_events=""
cpu_total=""
cpu_latency=""
mem_ops=""
mem_mib=""
mem_latency=""
ssd_reads=""
ssd_writes=""
ssd_syncs=""
ssd_read_tput=""
ssd_write_tput=""
ssd_latency=""

while IFS= read -r line; do
    clean_line=$(echo "$line" | xargs)

    if [[ "$clean_line" == *"events per second:"* ]] && [[ -z "$cpu_events" ]]; then
        cpu_events=$(get_num "$clean_line")
    elif [[ "$clean_line" == *"total number of events:"* ]] && [[ -z "$cpu_total" ]]; then
        cpu_total=$(get_num "$clean_line")
    fi

    if [[ "$clean_line" == *"Total operations:"* ]] && [[ "$clean_line" == *"per second"* ]] && [[ -z "$mem_ops" ]]; then
        mem_ops=$(echo "$clean_line" | grep -o '([0-9.]* per second)' | grep -o '[0-9.]*')
    elif [[ "$clean_line" == *"MiB transferred"* ]] && [[ -z "$mem_mib" ]]; then
        mem_mib=$(get_num "$clean_line")
    fi

    if [[ "$clean_line" == *"reads/s:"* ]] && [[ -z "$ssd_reads" ]]; then
        ssd_reads=$(get_num "$clean_line")
    elif [[ "$clean_line" == *"writes/s:"* ]] && [[ -z "$ssd_writes" ]]; then
        ssd_writes=$(get_num "$clean_line")
    elif [[ "$clean_line" == *"fsyncs/s:"* ]] && [[ -z "$ssd_syncs" ]]; then
        ssd_syncs=$(get_num "$clean_line")
    elif [[ "$clean_line" == *"read, MiB/s:"* ]] && [[ -z "$ssd_read_tput" ]]; then
        ssd_read_tput=$(get_num "$clean_line")
    elif [[ "$clean_line" == *"written, MiB/s:"* ]] && [[ -z "$ssd_write_tput" ]]; then
        ssd_write_tput=$(get_num "$clean_line")
    fi

    if [[ "$clean_line" == *"avg:"* ]]; then
        val=$(get_num "$clean_line")
        if [[ -z "$cpu_latency" ]]; then
            cpu_latency="$val"
        elif [[ -z "$mem_latency" ]]; then
            mem_latency="$val"
        elif [[ -z "$ssd_latency" ]]; then
            ssd_latency="$val"
        fi
    fi

done < "$logfile"

[[ -n "$cpu_events" ]]    && echo "Score:Score:CPU events per second:$cpu_events:eps:HB:"
[[ -n "$cpu_total" ]]     && echo "Score:Score:CPU total number of events:$cpu_total:Events:HB:"
[[ -n "$cpu_latency" ]]   && echo "Score:Score:CPU Latency avg:$cpu_latency:ms:HB:"
[[ -n "$mem_ops" ]]       && echo "Score:Score:Memory Total operations per sec:$mem_ops:ops:HB:"
[[ -n "$mem_mib" ]]       && echo "Score:Score:Memory MiB transferred:$mem_mib:MiB:HB:"
[[ -n "$mem_latency" ]]   && echo "Score:Score:Memory Latency avg:$mem_latency:ms:HB:"
[[ -n "$ssd_reads" ]]     && echo "Score:Score:SSD reads/s:$ssd_reads:r/s:HB:"
[[ -n "$ssd_writes" ]]    && echo "Score:Score:SSD writes/s:$ssd_writes:w/s:HB:"
[[ -n "$ssd_syncs" ]]     && echo "Score:Score:SSD syncs/s:$ssd_syncs:s/s:HB:"
[[ -n "$ssd_read_tput" ]] && echo "Score:Score:SSD Throughput read, MiB/s:$ssd_read_tput:MiB/s:HB:"
[[ -n "$ssd_write_tput" ]]&& echo "Score:Score:SSD Throughput written, MiB/s:$ssd_write_tput:MiB/s:HB:"
[[ -n "$ssd_latency" ]]   && echo "Score:Score:SSD Latency avg:$ssd_latency:ms:HB:"
