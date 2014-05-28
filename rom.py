import os
import sys
import re

init=chr(0xff)
#mtdparts="128k:tuboot.bin,1792k:ap121-2.6.31-squashfs,1024k:vmlinux.lzma.uImage,64k:NVRAM:,29696k:ap121-2.6.31-jffs2,64k:art.bin"
mtdparts="128k:tuboot.bin,1792k:ap121-2.6.31-squashfs,1024k:vmlinux.lzma.uImage,64k:NVRAM:,1024k:ap121-2.6.31-jffs2,64k:art2.bin"

parts=mtdparts.split(",")
for i, part in enumerate(parts):
	parts[i]=part.split(":")
	sz,bs=re.match("([0-9]+)([kmg]?)", parts[i][0], re.I).groups()
	sz=int(sz)
	bs={"k":1024,"m":1024**2,"g":1024**3}[bs.lower()]
	parts[i][0]=sz*bs
	parts[i]=(parts[i][0], parts[i][1])

total=0
romfile=open(sys.argv[1]+".bin", "wb")
for sz, imgfile in parts:
	total+=sz
	if os.path.exists(imgfile):
		img=open(imgfile).read()
		romfile.write(img)
		print imgfile, len(img)
		rest=sz-len(img)
		if rest<0:
			print "ERROR"
			sys.exit(1)
	else:
		print imgfile, "(SKIPPED)"
		rest=sz
	if rest>0:
		print "fill", rest
		romfile.write(init*rest)
romfile.close()
print "Total:", total
