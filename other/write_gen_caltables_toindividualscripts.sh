#!/bin/bash

. ~/calim-pipeline-phase2/gen_caltables.cfg
cp ~/calim-pipeline-phase2/gen_caltables.txt ${outdir}

if [ -e ~/calim-pipeline-phase2/gen_caltables_exec.txt ]; then rm ~/calim-pipeline-phase2/gen_caltables_exec.txt; fi
FILE=~/calim-pipeline-phase2/gen_caltables.txt
j=0
while read line; do
    num=`printf "%02d" $j`
    cmds=$(IFS=\;; set -- $line; printf "%s\n" "$@")
    echo "$cmds" > ~/calim-pipeline-phase2/gen_caltables.${num}.sh
    echo "PYTHONPATH=/opt/astro/pyrap-1.1.0/python:/lustre/mmanders/LWA/modules:\$PYTHONPATH; PATH=/opt/astro/wsclean-1.11-gcc4.8.5_cxx11/bin:\$PATH:/opt/astro/aoflagger-2.7.1-gcc4.8.5_cxx11/bin; . /opt/astro/env.sh; bash ~/calim-pipeline-phase2/gen_caltables.${num}.sh" >> ~/calim-pipeline-phase2/gen_caltables_exec.txt
    ((j++))
done < $FILE
