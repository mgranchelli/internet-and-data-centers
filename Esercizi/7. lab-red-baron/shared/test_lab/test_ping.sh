#!/bin/bash

awk '{print $1}' < "$1.txt" | while read ip; do
    if ping -c1 $ip >/dev/null 2>&1; then
        printf "%-20s IS UP\n" $ip
    else
        echo ------- $ip IS DOWN -------
    fi
done