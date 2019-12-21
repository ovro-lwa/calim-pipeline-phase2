#!/usr/bin/env bash

set -e

# set up environment
source /opt/astro/env.sh
source ~/code/calim-pipeline-phase2/env_pipeline.sh
source ~/code/calim-pipeline-phase2/gen_caltables.cfg

workdir="/lustre/pipeline/workdir"
dada=`~/code/calim-pipeline-phase2/get_BCALdada.py`
ms=${dada%.*}.ms

# set up dirs/files
mkdir -p $workdir
mkdir -p $outdir

cd $workdir
bash ~/code/calim-pipeline-phase2/gen_autos.sh ${dada_dir} ${dada} ${outdir}

# plot and write out pdf of autocorrelations
python ~/code/calim-pipeline-phase2/plot_autos_rescale.py $ms

# run script to generate antenna flags
python ~/code/calim-pipeline-phase2/flag_bad_ants.py $ms
