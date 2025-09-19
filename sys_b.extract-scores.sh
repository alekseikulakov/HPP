#!/bin/bash

tail -n +5 phoronix-sysbench.stdout | head -n -2 > sysbench-pts_cleaned.stdout
log_file="sysbench-pts_cleaned.stdout"


test_num=0
inside_test=0
test_data=""

print_test_data() {
  local block="$1"
  ((test_num++))
  echo "Тест$test_num:"

  case $test_num in
    1)
      echo "$block" | awk '
        /events per second:/       { print "events per second:", $NF }
        /total number of events:/  { print "total number of events:", $NF }
        /^ *avg:/                  { print "avg:", $2 }
        /^ *max:/                  { print "max:", $2 }
        /^ *sum:/                  { print "sum:", $2 }
        /events \(avg\/stddev\):/  { print "events (avg/stddev):", $3 }
      '
      ;;
    2)
      echo "$block" | awk '
        /Total operations:/ {
          gsub(/\(/, "", $(NF-2))
          print "Total operations per second:", $(NF-2)
        }
        /transferred/ {
          for (i=1; i<=NF; i++) {
            if ($i ~ /transferred/) {
              print "MiB transferred:", $(i-1)
              break
            }
          }
        }
        /total number of events:/  { print "total number of events:", $NF }
        /^ *avg:/                  { print "avg:", $2 }
        /^ *max:/                  { print "max:", $2 }
        /^ *sum:/                  { print "sum:", $2 }
        /events \(avg\/stddev\):/  { print "events (avg/stddev):", $3 }
      '
      ;;
    3)
      echo "$block" | awk '
        /reads\/s:/                { print "reads/s:", $2 }
        /writes\/s:/               { print "writes/s:", $2 }
        /fsyncs\/s:/               { print "fsyncs/s:", $2 }
        /total number of events:/  { print "total number of events:", $NF }
        /^ *avg:/                  { print "avg:", $2 }
        /^ *max:/                  { print "max:", $2 }
        /^ *sum:/                  { print "sum:", $2 }
        /events \(avg\/stddev\):/  { print "events (avg/stddev):", $3 }
      '
      ;;
    4|5)
      echo "$block" | awk '
        /total number of events:/  { print "total number of events:", $NF }
        /^ *avg:/                  { print "avg:", $2 }
        /^ *max:/                  { print "max:", $2 }
        /^ *sum:/                  { print "sum:", $2 }
        /events \(avg\/stddev\):/  { print "events (avg/stddev):", $3 }
      '
      ;;
    *)
      echo "(Неизвестный тест)"
      ;;
  esac

  echo ""
}

process_block() {
 local block="$1"

  if echo "$block" | grep -q -E "Creating files for the test|Removing test files"; then
    return
  fi

  print_test_data "$block"
}

while IFS= read -r line; do
  if [[ "$line" == "sysbench 1.0.20-191968ab7 (using bundled LuaJIT 2.1.0-beta2)" ]]; then
    if [[ $inside_test -eq 1 ]]; then
      process_block "$test_data"
    fi
    test_data=""
    inside_test=1
  fi

  if [[ $inside_test -eq 1 ]]; then
    test_data+="$line"$'\n'
  fi
done < "$log_file"

if [[ -n "$test_data" ]]; then
  process_block "$test_data"
fi
