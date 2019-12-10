#!/usr/bin/env python

import matplotlib
import casatools as tools
import casatasks as tasks
import math
import sys

ref_freq = 80.0
output_freq = 47.0

def flux80_47(flux_hi, sp):
	# given a flux at 80 MHz and a sp_index,
	# return the flux at 47 MHz.
	return flux_hi * 10 ** (sp * math.log(output_freq/ref_freq, 10))

srcs = [{'label': 'CasA', 'flux': '16530', 'alpha': -0.72,
	 'position': 'J2000 23h23m24s +58d48m54s'},
        {'label': 'CygA', 'flux': '16300', 'alpha': -0.58,
	 'position': 'J2000 19h59m28.35663s +40d44m02.0970s'},
        {'label': 'TauA', 'flux': '1770', 'alpha': -0.27,
	 'position': 'J2000 05h34m31.94s +22d00m52.2s'},
        {'label': 'VirA', 'flux': '2400', 'alpha': -0.86,
	 'position': 'J2000 12h30m49.42338s +12d23m28.0439s'},
        {'label': 'Sun', 'flux': '16000', 'alpha': 2.2,
	 'position': 'SUN'}]

msfile = sys.argv[1]
if len(sys.argv) > 2:
	bcalfile = sys.argv[2]
else:
	bcalfile = msfile.replace('.ms', '.bcal')

tb = tools.table()
tb.open(msfile)
t0 = tb.getcell('TIME', 0)

me = tools.measures()
ovro = me.observatory('OVRO_MMA')
time = me.epoch('UTC', '%fs' % t0)
me.doframe(ovro)
me.doframe(time)

def conv_deg(dec):
	if 's' in dec:
		dec = dec.split('s')[0]
	if 'm' in dec:
		dec, ss = dec.split('m')
		if ss == '':
			ss = '0'
	dd, mm = dec.split('d')
	if dd.startswith('-'):
		neg = True
	else:
		neg = False
	deg = float(dd) + float(mm)/60 + float(ss)/3600
	return '%fdeg' % deg

for s in range(len(srcs)-1,-1,-1):
	coord = srcs[s]['position'].split()
	d0 = None
	if len(coord) == 1:
		d0 = me.direction(coord[0])
		d0_j2000 = me.measure(d0, 'J2000')
		srcs[s]['position'] = 'J2000 %frad %frad' % (d0_j2000['m0']['value'], d0_j2000['m1']['value'])
	elif len(coord) == 3:
		coord[2] = conv_deg(coord[2])
		d0 = me.direction(coord[0], coord[1], coord[2])
	else:
		raise "Unknown direction"
	d = me.measure(d0, 'AZEL')
	elev = d['m1']['value']
	if elev < 0:
		del srcs[s]
	else:
		scale = math.sin(elev) ** 1.6
		srcs[s]['flux'] = flux80_47(float(srcs[s]['flux']), srcs[s]['alpha']) * scale

cl = tools.componentlist()
clfile = msfile.replace('.ms', '.cl'))
cl.done()
for s in srcs:
	cl.addcomponent(flux=s['flux'], dir=s['position'], index=s['alpha'], spectrumtype='spectral index', freq='47MHz', label=s['label'])
cl.rename(clfile)
cl.done()

tasks.clearcal(msfile)
tasks.ft(msfile, complist=clfile)
tasks.bandpass(msfile, bcalfile)
tasks.applycal(msfile, gaintable=[bcalfile])
