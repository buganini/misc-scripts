import bsdconv
import os
import fnmatch

c=bsdconv.Bsdconv("UTF-8:WIDTH:NULL")


files=[]
for root, dirnames, filenames in os.walk('.'):
	for filename in fnmatch.filter(filenames, '*.php'):
		files.append(os.path.join(root, filename))

for f in files:
	fp=open(f)
	for l in fp:
		c.conv(l)
		info=c.counter()
		if info["FULL"]+info["AMBI"]>0:
			print f, l.rstrip()
	fp.close()
