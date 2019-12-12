#!/bin/bash

# Generates new set of BCAL tables in /lustre/mmanders/bufferdata/hourly/BCAL.
# Currently set to run once per day, on astm12, user mmanders crontab.

set -e

/home/mmanders/scripts/gen_caltables_kronjob/gen_caltables.sh > /home/mmanders/scripts/gen_caltables_kronjob/gen_caltables.txt
/home/mmanders/scripts/gen_caltables_kronjob/write_gen_caltables_toindividualscripts.sh

/home/mmanders/imaging_scripts/ipbs_taskfarm.py /home/mmanders/scripts/gen_caltables_kronjob/gen_caltables_exec.txt > /dev/null 2>&1
