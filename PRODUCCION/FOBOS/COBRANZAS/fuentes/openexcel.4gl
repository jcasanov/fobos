define p_text		varchar(400)
define err_flag		integer
define comando		varchar(400)
define archivo		varchar(100)
main
call fgl_init4js()
--C:\\\\Archivos de programa\Microsoft Office\OFFICE11
LET archivo = "c:\\\\libro1.xls"
LET comando = "Range(\\\"A2\\\").Select; ActiveCell.FormulaR1C1 = \\\"Prueba de DDE con Excel\\\"" 
CALL WinExec("C:\\\\Archivos de programa\\\\Microsoft Office\\\\OFFICE11\\\\EXCEL.EXE c:\\\\libro1.xls")
RETURNING err_flag
if err_flag <> 0 THEN
	display 'error1 ', err_flag
end if
CALL fgl_strtosend(archivo CLIPPED) RETURNING err_flag
CALL fgl_winmessage("LL",archivo,"info")
CALL DDEConnect("EXCEL",archivo) RETURNING err_flag
	display 'error2 ', err_flag
LET err_flag  = DDEExecute("EXCEL", archivo, comando)
	display 'error3 ', err_flag
LET p_text = "Esto es una prueba"
call DDEPoke("EXCEL", archivo,"L1C1",p_text) RETURNING err_flag
CALL DDEFinishAll()
end main
