#!/usr/bin/env python

import numpy as np
import sys,re,argparse
import coords
import datetime,time
import pdb

# current UTC time
utcnow = datetime.datetime.utcnow().strftime('%Y-%m-%d %H:%M:%S')
jdnow  = coords.utc2jd(*filter(None,re.split('[-: ]',utcnow)))

# array of UTC vals from /lustre/data/current/utc_times.txt
utctimes = np.genfromtxt('/lustre/data/current/utc_times.txt', dtype='str')
utctimesarray = np.asarray([utcdate+' '+utctime for utcdate,utctime in zip(utctimes[:,0],utctimes[:,1])])
dadafilearray = np.asarray(utctimes[:,2])
# convert to array of JDs
jdarr = np.asarray([coords.utc2jd(*filter(None,re.split('[-: ]',utctime))) for utctime in utctimesarray])
# convert to array of LSTs
lstarr = np.asarray([coords.jd2lst(jdval) for jdval in jdarr])

# select most recent LST where CygA is closest to zenith, +/- 5 minutes
CygARA      = 19.99  # in hours
CygARAminus = CygARA-5./60.
CygARAplus  = CygARA+5./60.

zenindarr   = np.where( (np.abs(lstarr-CygARA) < 2.) & (np.abs(jdnow-jdarr) < 1.) )
zenind      = zenindarr[0][np.where( (np.abs(lstarr[zenindarr]-CygARA)+np.abs(jdnow-jdarr[zenindarr])) == np.min(np.abs(lstarr[zenindarr]-CygARA)+np.abs(jdnow-jdarr[zenindarr])) )]
zenindminus = zenindarr[0][np.where( (np.abs(lstarr[zenindarr]-CygARAminus)+np.abs(jdnow-jdarr[zenindarr])) == np.min(np.abs(lstarr[zenindarr]-CygARAminus)+np.abs(jdnow-jdarr[zenindarr])) )]
zenindplus  = zenindarr[0][np.where( (np.abs(lstarr[zenindarr]-CygARAplus)+np.abs(jdnow-jdarr[zenindarr])) == np.min(np.abs(lstarr[zenindarr]-CygARAplus)+np.abs(jdnow-jdarr[zenindarr])) )]
BCALdadafiles = dadafilearray[range(zenindminus,zenindplus+1)]

for BCALdadafile in BCALdadafiles: print BCALdadafile
