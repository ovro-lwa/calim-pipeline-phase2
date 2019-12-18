#!/bin/bash
# copied from /pipedata/workdir/sb/best_as_of_Nov19/tt_ppipe2.sh

set -e

#PYTHONPATH=/opt/astro/pyrap-1.1.0/python:/lustre/mmanders/LWA/modules:$PYTHONPATH
. /opt/astro/env.sh;

. ~/code/calim-pipeline-phase2/gen_caltables.cfg

workdir="/lustre/claw/workdir"

dada=`~/code/calim-pipeline-phase2/get_BCALdada.py`

mkdir -p $workdir
mkdir -p $outdir
cp ~/code/calim-pipeline-phase2/gen_caltables.cfg $outdir

for band in ${spws}; do
    i=1
    ti=`printf "T%cal" ${i}`            # T1cal
    basename=${band}-${ti}              # 00-T1cal
    ms=${basename}.ms                   # 00-T1cal.ms
    bcal=${basename}.bcal               # 00-T1cal.bcal
    Df0=${basename}.Df0                 # 00-T1cal.bcal
    bcalamps=/lustre/mmanders/bufferdata/sGRB/170112A/BCAL2/bandpass/${basename}-spec.bcal
    #kcross=${basename}.kcross           # 00-T1cal.kcross
    #xy0=${basename}.xy0amb              # 00-T1cal.xy0amb
    #bcal=/lustre/mmanders/buffer_obs/20170112a/BCAL/bandpass/subband_modifiedcmplist/${basename}.bcal
    #bcal=/lustre/mmanders/bufferdata/sGRB/170112A/BCAL/${basename}.bcal
    #bcalamps=/lustre/mmanders/buffer_obs/20170112a/BCAL/bandpass/subband_modifiedcmplist/${basename}-spec.bcal
    #bcalamps=/lustre/mmanders/bufferdata/sGRB/170112A/BCAL/${basename}-spec.bcal
    tt=${basename}.tt                   # 00-T1cal.tt
    work_subdir=${workdir}/${basename}  # /lustre/mmanders/gen_caltables/00-T1cal

    # run dada2ms
    echo -n "mkdir -p $work_subdir;"
    echo -n "cd $work_subdir;"
    echo -n "ln -s /opt/astro/dada2ms/share/dada2ms/dada2ms.cfg.fiber dada2ms.cfg;"
    echo -n "ln -s ~/code/calim-pipeline-phase2/sources_resolved.json sources.json;"
    if [ -s $removerfi ]; then
        echo -n "ln -s ${removerfi} sources_rfi.json;"
    fi
    echo -n "dada2ms-tst3 ${dada_dir}/${band}/${dada} ${ms};"
    #echo -n "chgcentre ${ms} `cat ra_dec.txt`; "

    # Swap lines
    if $do_pol_swap; then
        echo -n "swap_polarizations_from_delay_bug ${ms};"
    fi
    # Swap lines
    if $exp_line_swap; then
        echo -n "/home/mmanders/scripts/swap_polarizations_expansion_201708/swap_polarizations_expansion ${ms};"
    fi
    # Antenna line swap
    #echo -n "/home/mmanders/scripts/antenna_line_swap.py ${ms};"

    # apply flags to MS
    if [ ! -z $antflag_dir ]; then
## **PYTHON BINARY ISSUE?
#        echo -n "~/code/calim-pipeline-phase2/apply_chanspecific_ant_flags.py ~/code/calim-pipeline-phase2/flagfiles/baseline/antFreqFlags.npy ${ms} ${band};"
#        echo -n "~/code/calim-pipeline-phase2/apply_chanspecific_ant_flags.py ~/code/calim-pipeline-phase2/flagfiles/baseline/antFreqFlagsAbs.npy ${ms} ${band};"
## **PYTHON BINARY ISSUE?
        # antenna flags
        echo -n "ms_flag_ants.sh ${ms} `cat ${antflag_dir}/all.antflags`;"
        # baseline flags
        echo -n "/home/sb/bin/flag_nov25.sh ${ms} < ${antflag_dir}/all.blflags;"
        # channel flags
        echo -n "apply_sb_flags_single_band_ms2.py ${antflag_dir}/all.chanflags ${ms} ${band};"
    else # use the old 3-day run September flags
        echo -n "apply_sb_flags_single_band_ms2.py ~/code/calim-pipeline-phase2/flagfiles/chanflags/T1.sb.flags ${ms} ${band};"
        echo -n "apply_sb_flags_single_band_ms2.py ~/code/calim-pipeline-phase2/flagfiles/chanflags/T2.sb.flags ${ms} ${band};"
        echo -n "apply_sb_flags_single_band_ms2.py /opt/astro/utils/share/ryan_flags_sb.txt ${ms} ${band};"
        echo -n "apply_sb_flags_single_band_ms2.py /opt/astro/utils/share/sb_flags.txt ${ms} ${band};"
        echo -n "apply_sb_flags_single_band_ms2.py /home/sb/chan_flags_nov24.txt ${ms} ${band};"
        echo -n "/home/sb/bin/flag_nov25.sh ${ms} < /home/sb/tflags.hiflux;"
        echo -n "apply_sb_flags_single_band_ms2.py /home/sb/diff_flags.txt ${ms} ${band};"
        for flagfile in ~/code/calim-pipeline-phase2/flagfiles/antflags/bad_*.ants; do
            echo -n "ms_flag_ants.sh ${ms} `cat $flagfile`;"
        done
    fi

    # flag with AOFlagger
    if $aoflag; then
        echo -n "aoflagger ${ms};"
    fi

    # Frequency shift
    if $do_frq_offset; then
        echo -n "freq-offset_fix.py ${ms};"
    fi

    if $usettcal; then
    	echo -n "echo vis=\\\"\"${ms}\"\\\" > ccal.py;"
        echo -n "echo \"flagdata(vis, uvrange='<3lambda', flagbackup=False)\" >> ccal.py;"
    	echo -n "casapy --nogui --nologger --log2term -c ccal.py;"
        
        echo -n "~/scripts/gen_sourcesjson.py ${ms} >> sources_${band}.json;"
        echo -n "cp sources_${band}.json ${outdir};"
        echo -n "ttcal-0.3.0 gaincal ${ms} ${tt} sources_${band}.json --beam constant --minuvw 10 --maxiter 30 --tolerance 1e-4;"
        echo -n "ttcal-0.3.0 applycal ${ms} ${tt} --corrected;"
    else
    	echo -n "echo vis=\\\"\"${ms}\"\\\" > ccal.py;"
    	echo -n "echo bcal=\\\"\"${bcal}\"\\\" >> ccal.py;"
    	echo -n "echo bcalamps=\\\"\"${bcalamps}\"\\\" >> ccal.py;"
        echo -n "echo Df0=\\\"\"${Df0}\"\\\" >> ccal.py;"
    	echo -n "echo cmplst=\\\"\"${basename}.cl\"\\\" >> ccal.py;"
        if $stokes_cal; then
            echo -n "gen_model_ms_stokes.py ${ms} >> ccal.py;"
        else
            echo -n "gen_model_ms.py ${ms} >> ccal.py;"
        fi
        echo -n "echo \"flagdata(vis, uvrange='<3lambda', flagbackup=False)\" >> ccal.py;"
    	echo -n "echo \"clearcal(vis, addmodel=True)\" >> ccal.py;"
    	echo -n "echo \"ft(vis, complist=cmplst, usescratch=True)\" >> ccal.py;"
    	echo -n "echo \"bandpass(vis, bcal, refant='34', uvrange='>15lambda', fillgaps=1)\" >> ccal.py;"
        if $stokes_cal; then
            echo -n "echo \"polcal(vis, Df0, poltype='Dflls', gaintable=[bcal], refant='')\" >> ccal.py;"
            #echo -n "echo \"polcal(vis, Df0, poltype='Dflls', gaintable=[bcal,bcalamps], refant='')\" >> ccal.py;"
            echo -n "echo \"applycal(vis, gaintable=[bcal,Df0], calwt=[T,F], flagbackup=False)\" >> ccal.py;"
        else
            echo -n "echo \"applycal(vis, gaintable=[bcal], flagbackup=False)\" >> ccal.py;"
            #echo -n "echo \"applycal(vis, gaintable=[bcal,bcalamps], flagbackup=False)\" >> ccal.py;"
        fi
    	echo -n "casapy --nogui --nologger --log2term -c ccal.py;"
    
    	# Clean up after Casa (casaviewer.wrapped-svr process still around)
    	#echo -n "for pid in \`pgrep -P \$\$\`;do"
    	#echo -n "	kill -9 \${pid};"
    	#echo -n "done;"
    fi

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
    if [ -s $removerfi ]; then
        echo -n "ttcal-0.2.0 shave --input ${ms} --sources sources_rfi.json --beam constant --minuvw 10 --maxiter 30 --tolerance 1e-4;"
    fi
    if $bandpass; then
        echo -n "JULIA_PKGDIR=/opt/astro/mwe/ttcal-0.3.0/julia-packages/ julia-0.4.6 /home/mmanders/scripts/peel_restore.jl \"${ms}\";"
    fi

    echo -n "~/code/calim-pipeline-phase2/flag_bad_chans.20180206.py ${ms} ${band};" 

    if $zest; then
        echo -n "wsclean -tempdir /dev/shm/mmanders -pol I,V -size 4096 4096 -scale 0.03125 -weight briggs 0 -name ${basename} ${ms};"
        #echo -n "wsclean -tempdir /dev/shm/mmanders -size 4096 4096 -scale 0.03125 -weight briggs 0 -name ${basename} ${ms};"
    else
        #echo -n "wsclean -channelsout 109 -tempdir /dev/shm/mmanders -size 4096 4096 -scale 0.03125 -weight briggs 0 -name ${basename} ${ms};"
        if $stokes_cal; then
            echo -n "wsclean -tempdir /dev/shm/mmanders -pol I,V -size 4096 4096 -scale 0.03125 -weight briggs 0 -name ${basename} ${ms};"
        else
            echo -n "wsclean -tempdir /dev/shm/mmanders -size 4096 4096 -scale 0.03125 -weight briggs 0 -name ${basename} ${ms};"
        fi
    fi

    echo -n "rm -rf ${outdir}/${ms};"
    echo -n "rm -rf ${outdir}/${bcal};"
    echo -n "rm -rf ${outdir}/${basename}*-dirty.fits;"
	echo -n "cp -r ${ms} ${bcal} ${basename}*-dirty.fits ${outdir};"
	echo -n "rm -rf $work_subdir;"
	echo
	i=$(($i + 1))
done
