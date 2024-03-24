#!/usr/bin/env python
import sys


fname1 = sys.argv[1]
fname2 = sys.argv[2]

words1 = set()
with open(fname1, 'r') as f:
	for line in f:
		word = line.strip()
		words1.add(word)

print('Words in %s that are not present in %s:' % (fname2, fname1))
with open(fname2, 'r') as f:
	for line in f:
		word = line.strip()
		if word not in words1:
			print(word)
