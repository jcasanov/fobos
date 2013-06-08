------------------------------------------------------------------------------
-- Titulo           : repp316.4gl - Consulta de Stock a pedir
-- Elaboracion      : 26-Jul-2004
-- Autor            : NPC
-- Formato Ejecucion: fglrun repp316 base módulo compañía localidad
-- Ultima Correccion: 
-- Motivo Correccion: 
------------------------------------------------------------------------------
GLOBALS '../../../PRODUCCION/LIBRERIAS/fuentes/globales.4gl'

DEFINE vm_max_det       SMALLINT
DEFINE vm_num_det       SMALLINT
DEFINE vm_size_arr      SMALLINT
DEFINE vm_total		DECIMAL(14,2)
DEFINE rm_detalle	ARRAY [1000] OF RECORD
				r10_codigo	LIKE rept010.r10_codigo,
				r10_stock_max	LIKE rept010.r10_stock_max,
				r10_stock_min	LIKE rept010.r10_stock_min,
				r11_stock_act	LIKE rept011.r11_stock_act,
				cant_pedir	DECIMAL(8,2)
			END RECORD
DEFINE rm_orden 	ARRAY[10] OF CHAR(4)
DEFINE vm_columna_1	SMALLINT
DEFINE vm_columna_2	SMALLINT



MAIN

DEFER QUIT 
DEFER INTERRUPT
CLEAR SCREEN
CALL startlog('../logs/repp316.err')
--#CALL fgl_init4js()
CALL fl_marca_registrada_producto()
IF num_args() <> 4 THEN   -- Validar # parámetros correcto
	CALL fl_mostrar_mensaje('Número de parámetros incorrecto.', 'stop')
	EXIT PROGRAM
END IF
LET vg_base    = arg_val(1)
LET vg_modulo  = arg_val(2)
LET vg_codcia  = arg_val(3)
LET vg_codloc  = arg_val(4)
LET vg_proceso = 'repp316'
CALL fl_activar_base_datos(vg_base)
CALL fl_seteos_defaults()	
--#CALL fgl_settitle(vg_proceso || ' - ' || vg_producto)
CALL fl_validar_parametros()
CALL fl_cabecera_pantalla(vg_codcia, vg_codloc, vg_modulo, vg_proceso)
CALL funcion_master()

END MAIN



FUNCTION funcion_master()
DEFINE lin_menu		SMALLINT
DEFINE row_ini  	SMALLINT
DEFINE num_rows 	SMALLINT
DEFINE num_cols 	SMALLINT

CALL fl_nivel_isolation()
LET vm_max_det = 1000
LET lin_menu   = 0
LET row_ini    = 3
LET num_rows   = 22
LET num_cols   = 80
IF vg_gui = 0 THEN
	LET lin_menu = 1
	LET row_ini  = 4
	LET num_rows = 20
	LET num_cols = 78
END IF
OPEN WINDOW w_inv AT row_ini, 02 WITH num_rows ROWS, num_cols COLUMNS
	ATTRIBUTE(FORM LINE FIRST + 1, COMMENT LINE LAST, MENU LINE lin_menu,
		  MESSAGE LINE LAST - 1, BORDER) 
IF vg_gui = 1 THEN
	OPEN FORM f_repf316_1 FROM "../forms/repf316_1"
ELSE
	OPEN FORM f_repf316_1 FROM "../forms/repf316_1c"
END IF
DISPLAY FORM f_repf316_1
--CALL fl_lee_compania(vg_codcia) RETURNING rm_g01.*
LET vm_size_arr = 0
CALL mostrar_botones_cabecera()
LET lin_menu = fgl_getkey()

END FUNCTION



FUNCTION mostrar_botones_cabecera()

--#DISPLAY "Item"	TO tit_col1
--#DISPLAY "Stock Max"	TO tit_col2
--#DISPLAY "Stock Min"	TO tit_col3
--#DISPLAY "Stock Act"	TO tit_col4
--#DISPLAY "Cant. Ped"	TO tit_col5

END FUNCTION
