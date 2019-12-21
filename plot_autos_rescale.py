#!/usr/bin/env python

import numpy as np
#import pylab
import matplotlib
matplotlib.use('Agg')
import matplotlib.pyplot as plt
import pyrap.tables as pt
import sys,os
from matplotlib.backends.backend_pdf import PdfPages
import pdb

if len(sys.argv) != 2:
    print >> sys.stderr, 'Usage: %s <MS>' % sys.argv[0]
    sys.exit()

# open MS tables
t    = pt.table(sys.argv[1])
tspw = pt.table(os.path.abspath(sys.argv[1])+'/SPECTRAL_WINDOW')
# initialize figure and pdf file
pdf  = PdfPages(sys.argv[1][:-4]+'_autos.pdf')
plt.figure(figsize=(15,10),edgecolor='Black')
plt.clf()
ax1  = plt.subplot(211)
ax2  = plt.subplot(212)
ax1.set_color_cycle(['blue','green','red','cyan','magenta','brown','black','orange'])
ax2.set_color_cycle(['blue','green','red','cyan','magenta','brown','black','orange'])
legendstr = []
# select autos from MS table
tautos = t.query('ANTENNA1=ANTENNA2')
# iterate over antennas
for antind,tant in enumerate(tautos.iter("ANTENNA1")):
    ampXallbands = np.zeros(22*109)
    ampYallbands = np.copy(ampXallbands)
    freqallbands = np.copy(ampXallbands)
    tmpind = 0
    # iterate over subbands
    # (the tedious if statements are to correct for missing subbands in the ms file)
    for ind,tband in enumerate(tant):
        if ind != 0:
            if tspw[ind]['REF_FREQUENCY'] == tspw[ind-1]['REF_FREQUENCY']:
                continue
            elif tspw[ind]['REF_FREQUENCY'] != (tspw[ind-1]['REF_FREQUENCY'] + tspw[ind-1]['TOTAL_BANDWIDTH']):
                numpad = (tspw[ind]['REF_FREQUENCY'] - tspw[ind-1]['REF_FREQUENCY'])/tspw[ind-1]['TOTAL_BANDWIDTH'] - 1
                amppad = np.zeros(109 * numpad) * np.nan
                frqpadstart = tspw[ind-1]['REF_FREQUENCY'] + tspw[ind-1]['TOTAL_BANDWIDTH'] + tspw[ind-1]['EFFECTIVE_BW'][0]/2.
                frqpadend   = frqpadstart + (tspw[ind-1]['TOTAL_BANDWIDTH'] * numpad)
                frqpad = np.linspace(frqpadstart, frqpadend + tspw[ind-1]['EFFECTIVE_BW'][0]/2., tspw[ind-1]['NUM_CHAN']*numpad)
                ampXallbands[tmpind*109:109*(tmpind+numpad)] = amppad
                ampYallbands[tmpind*109:109*(tmpind+numpad)] = amppad
                freqallbands[tmpind*109:109*(tmpind+numpad)] = frqpad
                tmpind += numpad
        ampX = np.absolute(tband["DATA"][:,0])
        ampY = np.absolute(tband["DATA"][:,3])
        freq = tspw[ind]['CHAN_FREQ']
        ampXallbands[tmpind*109:109*(tmpind+1)] = ampX
        ampYallbands[tmpind*109:109*(tmpind+1)] = ampY
        freqallbands[tmpind*109:109*(tmpind+1)] = freq
        tmpind += 1
    legendstr.append('%03d' % (antind+1))
    #ax1.plot(freqallbands/1.e6,ampXallbands)
    #ax2.plot(freqallbands/1.e6,ampYallbands)
    ax1.plot(freqallbands/1.e6,10*np.log10(ampXallbands))
    ax2.plot(freqallbands/1.e6,10*np.log10(ampYallbands))
    # plot by ARX groupings
    if (np.mod(antind+1,8) == 0) and (antind != 0):
        plt.xlabel('Frequency [MHz]')
        #ax1.set_xticks(np.arange(20,90,2),minor=True)
        ax1.set_xticks(np.arange(0,100,2),minor=True)
        #ax1.set_ylabel('Amp')
        ax1.set_ylabel('Power [dB]')
        ax1.set_title('X',fontsize=18)
        ax1.set_ylim([40,100])
        #ax2.set_xticks(np.arange(20,90,2),minor=True)
        ax2.set_xticks(np.arange(0,100,2),minor=True)
        #plt.ylabel('Amp')
        plt.ylabel('Power [dB]')
        ax2.set_title('Y',fontsize=18)
        ax2.set_ylim([40,100])
        ax1.legend(legendstr)
        ax2.legend(legendstr)
        if antind+1 in [64,128,192,248]:
            ax1.set_title('X -- fiber antennas',fontsize=18)
            ax2.set_title('Y -- fiber antennas',fontsize=18)
        elif antind+1 == 256:
            ax1.set_title('X -- leda antennas',fontsize=18)
            ax2.set_title('Y -- leda antennas',fontsize=18)
        elif antind+1 == 240:
            ax1.set_title('X -- fiber antennas 239,240',fontsize=18)
            ax2.set_title('Y -- fiber antennas 239,240',fontsize=18)
        pdf.savefig()
        # reiniatilize for new set of plots
        plt.close()
        plt.figure(figsize=(15,10),edgecolor='Black')
        ax1 = plt.subplot(211)
        ax2 = plt.subplot(212)
        ax1.set_color_cycle(['blue','green','red','cyan','magenta','brown','black','orange'])
        ax2.set_color_cycle(['blue','green','red','cyan','magenta','brown','black','orange'])
        legendstr = []
pdf.close()
