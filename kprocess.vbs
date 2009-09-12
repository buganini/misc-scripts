Dim name_window,windowname,wshshell,pipe,bag
Set wshshell = WScript.CreateObject ( "WScript.Shell" )
Set bag = GetObject ( "winmgmts:\\.\root\cimv2" )
name_window = Array ( "counter-strike","half-life","gamania","zBOT","cstrike" )
Do
	For Each windowname In name_window
		If WshShell.AppActivate ( windowname ) = True Then
			WshShell.SendKeys "%{F4}"
		End if
	Next
	Set pipe = bag.Execquery ( "select * from win32_process where name = 'hl.exe' or name = 'cstrike.exe'")
	For Each process In pipe
		process.terminate()
	Next
	wscript.sleep 1000
Loop
