#!/usr/bin/env python

# Task farming utility. 
# Uses ssh and bash to execute tasks.
#
# Originally written to work within PBS (and use pbsdsh) but
# can be used without PBS by setting PBS_NODEFILE to a textfile
# containing a list of compute nodes
#
# Stephen Bourke, Aug 2012.

import sys
import os
import time

# Make a list of nodes (work_nodes)
work_nodes = []
try:
	nodef = open(os.environ['PBS_NODEFILE'])
except KeyError:
	print >> sys.stderr, 'Error opening PBS_NODEFILE. Exiting.'
	sys.exit()
for line in nodef:
	node = line.strip()
	work_nodes.append(node)
nodef.close()

def wait(taskinfo):
	global failed_tasks
	"""Wait on a process to finish and report on it's exit."""
	pid, status = os.wait()
	signal = status & 0xFF
	exit = status >> 8
	node = taskinfo[pid]['node']
	if exit != 0:
		print >> sys.stderr, "'%s' exit status: %d" % (taskinfo[pid]['task'], exit)
		failed_tasks.append( taskinfo[pid]['task'].replace('ssh '+node+' bash -c "','')[:-1] )
		if signal != 0:
			print >> sys.stderr, "'%s' killed by signal: %d" % (taskinfo[pid]['task'], signal)
	del taskinfo[pid]
	return node

def run_tasks(tasklist):
	taskinfo = {}
	global failed_tasks
	failed_tasks = []
	for task in tasklist:
		task = task.rstrip('\n')
		if len(work_nodes) == 0:
			# Wait for a task (invocation of ssh) to finish.
			work_nodes.append(wait(taskinfo))
		# Run task
		node = work_nodes[0]
		del work_nodes[0]
		command = 'ssh %s bash -c "%s"' % (node, task)
		pid = os.spawnlp(os.P_NOWAIT, 'ssh', 'ssh', node, 'bash', '-c', '"' + task + '"')
		taskinfo[pid] = {'node': node, 'task': command}
	
	# All tasks have been started. Wait for all to finish.
	while len(taskinfo) > 0:
		work_nodes.append(wait(taskinfo))

	return failed_tasks

if __name__ == '__main__':
	if len(sys.argv) != 2:
		print >> sys.stderr, 'Usage: %s <taskfile>' % sys.argv[0]
		sys.exit()
	taskfile = sys.argv[1]

	timeStart = time.time()

	failed_tasks = run_tasks(open(taskfile).readlines())
	# Deal with failed ssh sessions
	if len(failed_tasks):
		print failed_tasks
		print 'Re-running %d failed task(s)'%len(failed_tasks)
		# Try 5 more times before giving up
		NTry = 5
		for iTry in range(NTry):
			if len(failed_tasks):
				print 'Trying again: %d/%d'%(iTry+1,NTry)
				failed_tasks = run_tasks(failed_tasks)
			else:
				break

	print 'Runtime: %.02f hours' % ((time.time() - timeStart) / 3600.)
