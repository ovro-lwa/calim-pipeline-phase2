#!/bin/bash

# Generates new set of BCAL tables in /lustre/mmanders/bufferdata/hourly/BCAL.
# Currently set to run once per day, on astm12, user mmanders crontab.

set -e

./gen_caltables.sh > gen_caltables.txt
./write_gen_caltables_toindividualscripts.sh

./ipbs_taskfarm.py gen_caltables_exec.txt > /dev/null 2>&1
