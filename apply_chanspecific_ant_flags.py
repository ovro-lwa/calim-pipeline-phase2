#!/usr/bin/env python

from pyrap.tables import table
import numpy as np
import sys
import os.path

def flag_wide(flags, msname, band):
    flagmat = np.load(flags)
    tab     = table(msname, readonly=False, ack=False)
    curr_flags = tab.getcol('FLAG')
    ant1       = tab.getcol('ANTENNA1')
    ant2       = tab.getcol('ANTENNA2')
    for ant in range(0,256):
        antsp_frqflags = flagmat[ant,band*109:109*(band+1)]
        if np.sum(antsp_frqflags) == 0:
            continue
        else:
            inds = np.where((ant1 == ant) | (ant2 == ant))
            curr_flags[inds,:,0] |= antsp_frqflags
            curr_flags[inds,:,1] |= antsp_frqflags
            curr_flags[inds,:,2] |= antsp_frqflags
            curr_flags[inds,:,3] |= antsp_frqflags
    tab.putcol('FLAG', curr_flags)

def main():
    if len(sys.argv) < 4:
        print >> sys.stderr, 'Usage: %s <flags.npy> <msname> <band>' % sys.argv[0]
        sys.exit(1)
    flag_wide(sys.argv[1], sys.argv[2], int(sys.argv[3]))

if __name__ == "__main__":
    main()
