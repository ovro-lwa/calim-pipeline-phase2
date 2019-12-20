#!/bin/bash

# Append all subbands for a single integration into one .ms
# then run plot_autos.py

if [ $# -ne 3 ]; then
    echo "Usage: $0 <datadir> <dadafile> <workdir>"
    exit 1
fi

datadir=$1
dadafile=$2
workdir=$3
#datadir="/lustre/mmanders/buffer_obs/20170112a/BCAL"
#datadir="/lustre/data/2017-02-17_24hour_run"
#datadir="/lustre/data/2018-02-08_actests"
#datadir="/lustre/mmanders/2018-02-16_feeofftests/data/BCAL"
#dadafile="2016-12-12-00:32:18_0023601616625664.000000.dada"
#dadafile="2017-02-11-02:36:59_0005085191921664.000000.dada"
#dadafile="2018-02-08-17:34:40_0000001843003392.000000.dada"
#dadafile="2018-02-15-21:35:33_0000663250845696.000000.dada"
#workdir="/lustre/mmanders/bufferdata/sGRB/170112A/BCAL"
#workdir="/lustre/mmanders/28hourrun"
#workdir="/lustre/mmanders/2018-02-16_feeofftests"
ms=${dadafile%.*}.ms

mkdir -p ${workdir}
cd ${workdir}
if [ ! -e dada2ms.cfg ]; then ln -s /opt/astro/dada2ms/share/dada2ms/dada2ms.cfg.fiber dada2ms.cfg; fi

dada2ms-tst3 ${datadir}/00/${dadafile} $ms
echo 00

for band in {01..21}; do
	dada2ms-tst3 --append --addspw ${datadir}/${band}/${dadafile} $ms
    echo ${band}
done

# plot and write out pdf of autocorrelations
plot_autos_rescale.py $ms

# run script to generate antenna flags
flag_bad_ants.py $ms

#for flagfile in /home/mmanders/antflags/bad_*.ants; do
#	ms_flag_ants.sh ${ms} `cat $flagfile`
#done

#ms_select_autos.sh ${ms} ${ms%.*}_autos.ms

#echo vis=\"\\\\\"${ms%.*}_autos.ms\"\\\\\" > casaplotms.py;
#echo \"plotms(vis, xaxis=\'amp\', yaxis=\'freq\', coloraxis=\'antenna1\')\" >> casaplotms.py;
#casapy --nologger --log2term -c casaplotms.py;
