#!/bin/bash

if [ $# -ne 1 ]; then
        echo "Usage: $0 <MS>"
	echo "Flags in the form ant1&ant2 on stdin"
        exit 0
fi

MS=$1

while read line; do
	#IFS='&' read -ra ant <<<$line
	ant=(${line//&/ })
	taql "update $MS set FLAG=True where ANTENNA1=${ant[0]} && ANTENNA2=${ant[1]}"
done < /dev/stdin
