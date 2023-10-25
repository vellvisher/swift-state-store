#!/bin/bash

success=0
failure=0
times=100

for (( i=1; i<=times; i++ ))
do
    if swift test
    then
        ((success++))
    else
        ((failure++))
    fi
done

echo "Successes: $success, Failures: $failure"
