#!/usr/bin/env python

import os
import glob
from datetime import datetime
from orca.transform import imaging, peeling, dada2ms
from orca.metadata.pathsmanagers import OfflinePathsManager
#from orca.proj.boilerplate import run_dada2ms, run_chgcentre, peel, apply_a_priori_flags, flag_chans

# get last minute of data
now = datetime.now()
start_time = now.replace(hour=now.hour-1)
end_time = now.replace(second=start_time.second+13)

buffer = '7day_buffer'  # choose a buffer

#outdir = '/lustre/claw/{0}'.format(start_time.strftime("%y%m%d"))
outdir = '/lustre/claw/'
if not os.path.exists(outdir):
    os.mkdir(outdir)

pm = OfflinePathsManager(utc_times_txt_path='/lustre/data/7day_buffer/utc_times.txt', 
                         dadafile_dir='/lustre/data/{0}'.format(buffer), 
                         msfile_dir=outdir,
                         bcal_dir='/lustre/mmanders/bufferdata/hourly/BCAL_stripe3',
                         flag_npy_path='/home/yuping/100-hr-a-priori-flags/20191125-consolidated-flags/20191125-consolidated-flags.npy')

spw = '21'
for time in pm.utc_times_mapping:
    if start_time <= time < end_time:
        dada2ms.run_dada2ms(dada_file=pm.get_dada_path(spw, time), out_ms=pm.get_ms_path(time, spw), gaintable=pm.get_gaintable_path(spw))
        msfiles = glob.glob(pm.msfile_dir + '/*/*/*ms')
        for msfile in msfiles:
            peeling.peel_with_ttcal(msfile, '/home/claw/code/calim-pipeline-phase2/sources.json')
            imaging.make_image([msfile], date_times_string=start_time.strftime("%y%m%d"), out_dir='/lustre/claw/'+start_time.strftime("%y%m%d"))
