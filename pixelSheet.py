#!/usr/bin/env python

# ldconfig -m /usr/local/lib/libreoffice/ure/lib/
# libreoffice "--accept=socket,host=localhost,port=2002;urp;"
# pixelSheet.py image.png

import os
import sys
import Image
import itertools
sys.path.append('/usr/local/lib/libreoffice/basis3.4/program/')
os.putenv('URE_BOOTSTRAP','vnd.sun.star.pathname:/usr/local/lib/libreoffice/basis3.4/program/fundamentalbasisrc')
import uno

localContext=uno.getComponentContext()
resolver=localContext.ServiceManager.createInstanceWithContext("com.sun.star.bridge.UnoUrlResolver", localContext )
ctx=resolver.resolve("uno:socket,host=localhost,port=2002;urp;StarOffice.ComponentContext")
smgr=ctx.ServiceManager
desktop=smgr.createInstanceWithContext("com.sun.star.frame.Desktop",ctx)
calc=desktop.loadComponentFromURL("private:factory/scalc", "_blank", 0, () )

sheet=calc.getSheets().getByIndex(0)

im = Image.open(sys.argv[1]).convert("RGB")
width,height=im.size

sheet.getRows().Height=500
sheet.getColumns().Width=500

for c, r in itertools.product(xrange(width), xrange(height)):
	cell=sheet.getCellByPosition(c, r)
	clr=im.getpixel((c,r))
	cell.CellBackColor=clr[0]*65536+clr[1]*256+clr[2]
