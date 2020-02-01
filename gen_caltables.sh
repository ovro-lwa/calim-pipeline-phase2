#!/usr/bin/env bash

set -e

# set up environment
source /opt/astro/env.sh
source ~/code/calim-pipeline-phase2/env_pipeline.sh
source ~/code/calim-pipeline-phase2/gen_caltables.cfg

datestr=`date -u +'%y%m%d'`

# set up paths
workdir="/lustre/pipeline/${datestr}/workdir"
dada=`~/code/calim-pipeline-phase2/get_BCALdada.py`
if $multiint; then
    dadafiles=`~/code/calim-pipeline-phase2/get_BCALdada_10minutes.py`
fi

# set up dirs/files
mkdir -p $workdir
mkdir -p $outdir
cp ~/code/calim-pipeline-phase2/gen_caltables.cfg $outdir

# generate antenna flags from autocorrelations
#bash ~/code/calim-pipeline-phase2/gen_autos.sh ${dada_dir} ${dada} ${outdir} > /dev/null 2>&1

for band in ${spws}; do
    i=1
    ti=`printf "T%cal" ${i}`            # T1al
    basename=${band}-${ti}              # 00-T1al
    ms=${basename}.ms                   # 00-T1al.ms
    bcal=${basename}.bcal               # 00-T1al.bcal
    dcal=${basename}.dcal               # 00-T1al.dcal
    Xcal=${basename}.X                  # 00-T1al.X
    tt=${basename}.tt                   # 00-T1al.tt
    work_subdir=${workdir}/${basename}  # /lustre/pipeline/${datestr}/workdir/00-T1al

    # set up environment in each line of gen_caltables.txt
    echo -n "source /opt/astro/env.sh;"
    echo -n "source ~/code/calim-pipeline-phase2/env_pipeline.sh;"
    # run dada2ms
    echo -n "mkdir -p $work_subdir;"
    echo -n "cd $work_subdir;"
    echo -n "ln -s /opt/astro/dada2ms/share/dada2ms/dada2ms.cfg.fiber dada2ms.cfg;"
    echo -n "ln -s ~/code/calim-pipeline-phase2/sources_resolved.json sources.json;"
    echo -n "dada2ms-tst3 ${dada_dir}/${band}/${dada} ${ms};"
    if $multiint; then
        echo -n "echo vis=[] > concat.py;"
	echo -n "phasecenter=\`~/code/calim-pipeline-phase2/ms_zenith.py ${ms}\`;"
        for dadafile in ${dadafiles}; do
            echo -n "dada2ms-tst3 ${dada_dir}/${band}/${dadafile} ${dadafile%.*}.ms;"
	    echo -n "chgcentre ${dadafile%.*}.ms ${phasecenter};"
            echo -n "echo vis.append\\(\"\\\"${dadafile%.*}.ms\"\\\"\\) >> concat.py;"
        done
        echo -n "rm -r ${ms};"
        echo -n "echo concatvis=\\\"\"${ms}\"\\\" >> concat.py;"
        echo -n "echo \"concat(vis, concatvis=concatvis)\" >> concat.py;"
        echo -n "casapy --nogui --nologger --log2term -c concat.py;"
    fi

    # apply flags to MS
    # antenna flags
    echo -n "ms_flag_ants.sh ${ms} `cat ${outdir}/flag_bad_ants.ants`;"
    # baseline flags
    echo -n "/home/sb/bin/flag_nov25.sh ${ms} < ${antflag_dir}/flagsRyan_adjacent.bl;"
    # channel flags
    #echo -n "apply_sb_flags_single_band_ms2.py ${antflag_dir}/all.chanflags ${ms} ${band};"

    # calibration steps
    # define variable names
    echo -n "echo vis=\\\"\"${ms}\"\\\" > ccal.py;"
    echo -n "echo bcal=\\\"\"${bcal}\"\\\" >> ccal.py;"
    echo -n "echo dcal=\\\"\"${dcal}\"\\\" >> ccal.py;"
    echo -n "echo Xcal=\\\"\"${Xcal}\"\\\" >> ccal.py;"
    echo -n "echo cmplst=\\\"\"${basename}.cl\"\\\" >> ccal.py;"
    # generate model component list and visibilities
    if $stokes_cal; then
        echo -n "gen_model_ms_stokes.py ${ms} >> ccal.py;"
    else
        echo -n "gen_model_ms.py ${ms} >> ccal.py;"
    fi
    echo -n "echo \"flagdata(vis, uvrange='<3lambda', flagbackup=False)\" >> ccal.py;"
    echo -n "echo \"clearcal(vis, addmodel=True)\" >> ccal.py;"
    echo -n "echo \"ft(vis, complist=cmplst, usescratch=True)\" >> ccal.py;"
    # find calibration solutions and apply
    echo -n "echo \"bandpass(vis, bcal, refant='34', uvrange='>15lambda', combine='scan,field,obs', fillgaps=1)\" >> ccal.py;"
    if $stokes_cal; then
        echo -n "echo \"polcal(vis, Xcal, poltype='Xf', gaintable=[bcal], refant='', combine='scan,field,obs')\" >> ccal.py;"
        echo -n "echo \"polcal(vis, dcal, poltype='Dflls', gaintable=[bcal,Xcal], refant='', combine='scan,field,obs')\" >> ccal.py;"
        echo -n "echo \"applycal(vis, gaintable=[bcal,Xcal,dcal], flagbackup=False)\" >> ccal.py;"
    else
        echo -n "echo \"applycal(vis, gaintable=[bcal], flagbackup=False)\" >> ccal.py;"
    fi
    echo -n "casapy --nogui --nologger --log2term -c ccal.py;"

 
    # peeling
    if $peel; then
        echo -n "ttcal-0.2.0 peel --input ${ms} --sources sources.json --beam sine --minuvw 10 --maxiter 30 --tolerance 1e-4;"
    elif $zest; then
        echo -n "~/scripts/gen_sourcesjson_resolved.py ${ms} >> sources_${band}.json;"
        echo -n "cp sources_${band}.json ${outdir};"
        echo -n "ttcal-0.3.0 zest ${ms} sources_${band}.json --beam constant --minuvw 10 --maxiter 30 --tolerance 1e-4;"
    fi
    if $shave; then
        echo -n "ttcal-0.2.0 shave --input ${ms} --sources sources_rfi.json --beam constant --minuvw 10 --maxiter 30 --tolerance 1e-4;"
    elif $prune; then
        echo -n "ttcal-0.3.0 prune ${ms} /lustre/mmanders/4dayrun/4hours/sources_rfi.json --beam constant --minuvw 2 --maxiter 30 --tolerance 1e-4;"
    fi
    if $bandpass; then
        echo -n "JULIA_PKGDIR=/opt/astro/mwe/ttcal-0.3.0/julia-packages/ julia-0.4.6 /home/mmanders/scripts/peel_restore.jl \"${ms}\";"
    fi

    # Automated channel flagging
    echo -n "~/code/calim-pipeline-phase2/flag_bad_chans.20180206.py ${ms} ${band};" 

    # Imaging
    if $stokes_cal; then
        echo -n "wsclean -pol I,V -size 4096 4096 -scale 0.03125 -weight briggs 0 -name ${basename} ${ms};"
    else
        echo -n "wsclean -size 4096 4096 -scale 0.03125 -weight briggs 0 -name ${basename} ${ms};"
    fi

    # Move pipeline output files to final resting place
    echo -n "cp -r ${ms} ${bcal} ${dcal} ${Xcal} ${basename}*-dirty.fits ${outdir};"
    echo -n "rm -rf $work_subdir;"
    echo
    i=$(($i + 1))
done

echo "ln -f -n -s ${outdir} /lustre/pipeline/current"
