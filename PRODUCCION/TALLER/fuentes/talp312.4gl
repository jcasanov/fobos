--------------------------------------------------------------------------------
-- Titulo           : talp312.4gl - Consulta de Refacturaci�n Taller
-- Elaboracion      : 17-mar-2006
-- Autor            : NPC
-- Formato Ejecucion: fglrun talp312 base modulo compa��a localidad
-- Ultima Correccion: 
-- Motivo Correccion: 
--------------------------------------------------------------------------------
GLOBALS '../../../PRODUCCION/LIBRERIAS/fuentes/globales.4gl'

DEFINE rm_orden 	ARRAY[10] OF CHAR(4)
DEFINE vm_columna_1	SMALLINT
DEFINE vm_columna_2	SMALLINT
DEFINE vm_size_arr	INTEGER
DEFINE vm_fecha_ini	DATE
DEFINE vm_fecha_fin	DATE
DEFINE vm_cliente	LIKE cxct001.z01_codcli
DEFINE tit_cliente	LIKE cxct001.z01_nomcli
DEFINE rm_refact	ARRAY[10000] OF RECORD
				t60_fac_nue	LIKE talt060.t60_fac_nue,
				t60_ot_nue	LIKE talt060.t60_ot_nue,
				t60_fac_ant	LIKE talt060.t60_fac_ant,
				t60_ot_ant	LIKE talt060.t60_ot_ant,
				t60_fecing	DATE,
				t60_nomcli_nue	LIKE talt060.t60_nomcli_nue,
				total_fact	LIKE talt023.t23_tot_neto
			END RECORD
DEFINE t60_motivo_refact ARRAY[10000] OF LIKE talt060.t60_motivo_refact
DEFINE vm_max_rows	SMALLINT
DEFINE vm_num_rows	SMALLINT
DEFINE rm_g01		RECORD LIKE gent001.*
DEFINE total_gen	DECIMAL(14,2)



MAIN
	
DEFER QUIT
DEFER INTERRUPT
CLEAR SCREEN
CALL startlog('../logs/talp312.err')
--#CALL fgl_init4js()
CALL fl_marca_registrada_producto()
IF num_args() <> 4 THEN          -- Validar # par�metros correcto
	CALL fl_mostrar_mensaje('N�mero de par�metros incorrecto.','stop')
	EXIT PROGRAM
END IF
LET vg_base    = arg_val(1)
LET vg_modulo  = arg_val(2)
LET vg_codcia  = arg_val(3)
LET vg_codloc  = arg_val(4)
LET vg_proceso = 'talp312'
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

CALL fl_lee_compania(vg_codcia) RETURNING rm_g01.*
LET lin_menu = 0
LET row_ini  = 3
LET num_rows = 22
LET num_cols = 80
IF vg_gui = 0 THEN
	LET lin_menu = 1
	LET row_ini  = 4
	LET num_rows = 20
	LET num_cols = 78
END IF
OPEN WINDOW w_talf312_1 AT row_ini, 02 WITH num_rows ROWS, num_cols COLUMNS
	ATTRIBUTE(FORM LINE FIRST + 1, COMMENT LINE LAST, MENU LINE lin_menu,
		  BORDER, MESSAGE LINE LAST) 
IF vg_gui = 1 THEN
	OPEN FORM f_talf312_1 FROM '../forms/talf312_1'
ELSE
	OPEN FORM f_talf312_1 FROM '../forms/talf312_1c'
END IF
DISPLAY FORM f_talf312_1
LET vm_max_rows = 10000
--#DISPLAY 'FA Nu.'		TO tit_col1
--#DISPLAY 'OT Nu.'		TO tit_col2
--#DISPLAY 'FA O.'		TO tit_col3
--#DISPLAY 'OT D.'		TO tit_col4
--#DISPLAY 'Fecha Ref.'		TO tit_col5
--#DISPLAY 'Cliente'		TO tit_col6
--#DISPLAY 'Total'		TO tit_col7
--#LET vm_size_arr = fgl_scr_size('rm_refact')
IF vg_gui = 0 THEN
	LET vm_size_arr = 13
END IF
INITIALIZE vm_cliente, tit_cliente TO NULL
LET vm_fecha_ini = MDY(MONTH(TODAY), 01, YEAR(TODAY))
LET vm_fecha_fin = TODAY
WHILE TRUE
	CALL inicializar_detalle()
	CALL lee_parametros()
	IF int_flag THEN
		RETURN
	END IF
	CALL muestra_consulta()
END WHILE

END FUNCTION



FUNCTION lee_parametros()
DEFINE r_z01		RECORD LIKE cxct001.*
DEFINE fec_ini, fec_fin	DATE

LET int_flag = 0
INPUT BY NAME vm_fecha_ini, vm_fecha_fin, vm_cliente
	WITHOUT DEFAULTS
        ON KEY(INTERRUPT)
		LET int_flag = 1
		--#RETURN
		EXIT INPUT
        ON KEY(F1,CONTROL-W)
		CALL llamar_visor_teclas()
	ON KEY(F2)
		IF INFIELD(vm_cliente) THEN
			CALL fl_ayuda_cliente_localidad(vg_codcia, vg_codloc)
				RETURNING r_z01.z01_codcli,
					  r_z01.z01_nomcli
			IF r_z01.z01_codcli IS NOT NULL THEN
				LET vm_cliente  = r_z01.z01_codcli
				LET tit_cliente = r_z01.z01_nomcli 
				DISPLAY BY NAME vm_cliente, tit_cliente
			END IF
		END IF
		LET int_flag = 0
	BEFORE INPUT
		--#CALL dialog.keysetlabel("F1","")
		--#CALL dialog.keysetlabel("CONTROL-W","")
	BEFORE FIELD vm_fecha_ini
		LET fec_ini = vm_fecha_ini
	BEFORE FIELD vm_fecha_fin
		LET fec_fin = vm_fecha_fin
	AFTER FIELD vm_fecha_ini
		IF vm_fecha_ini IS NULL THEN
			LET fec_ini = vm_fecha_ini
			DISPLAY BY NAME vm_fecha_ini
		END IF
		IF vm_fecha_ini > TODAY THEN
			CALL fl_mostrar_mensaje('La Fecha Inicial no puede ser mayor a la fecha de hoy.', 'exclamation')
			NEXT FIELD vm_fecha_ini
		END IF
	AFTER FIELD vm_fecha_fin
		IF vm_fecha_fin IS NULL THEN
			LET fec_fin = vm_fecha_fin
			DISPLAY BY NAME vm_fecha_fin
		END IF
		IF vm_fecha_fin > TODAY THEN
			CALL fl_mostrar_mensaje('La Fecha Final no puede ser mayor a la fecha de hoy.', 'exclamation')
			NEXT FIELD vm_fecha_fin
		END IF
	AFTER FIELD vm_cliente
		IF vm_cliente IS NOT NULL THEN
			CALL fl_lee_cliente_general(vm_cliente)
				RETURNING r_z01.*
			IF r_z01.z01_codcli IS NULL THEN
				CALL fl_mostrar_mensaje('Cliente no existe.', 'exclamation')
				NEXT FIELD vm_cliente
			END IF 
			LET vm_cliente  = r_z01.z01_codcli
			LET tit_cliente = r_z01.z01_nomcli
			DISPLAY BY NAME vm_cliente, tit_cliente
		ELSE
			CLEAR vm_cliente, tit_cliente
			INITIALIZE vm_cliente, tit_cliente TO NULL
		END IF 
	AFTER INPUT
		IF vm_fecha_ini > vm_fecha_fin THEN
			CALL fl_mostrar_mensaje('La Fecha Inicial no puede ser mayor a la Fecha Final.', 'exclamation')
			NEXT FIELD vm_fecha_ini
		END IF
END INPUT

END FUNCTION



FUNCTION muestra_consulta()
DEFINE fec_i, fec_f	LIKE talt060.t60_fecing
DEFINE i, col		SMALLINT
DEFINE query		CHAR(800)
DEFINE expr_cli		VARCHAR(100)

LET fec_i = EXTEND(vm_fecha_ini, YEAR TO SECOND)
LET fec_f = EXTEND(vm_fecha_fin, YEAR TO SECOND) + 23 UNITS HOUR +
		59 UNITS MINUTE + 59 UNITS SECOND  
LET expr_cli = NULL
IF vm_cliente IS NOT NULL THEN
	LET expr_cli = '   AND t60_codcli_nue = ', vm_cliente
END IF
FOR i = 1 TO 10
	LET rm_orden[i] = '' 
END FOR
LET col                    = 1
LET vm_columna_1           = col
LET vm_columna_2           = 5
LET rm_orden[vm_columna_1] = 'DESC'
LET rm_orden[vm_columna_2] = 'DESC'
WHILE TRUE
	LET query = 'SELECT t60_fac_nue, t60_ot_nue, t60_fac_ant, t60_ot_ant, ',
			' DATE(t60_fecing), t60_nomcli_nue, t23_tot_neto, ',
			' t60_motivo_refact ',
			' FROM talt060, talt023 ',
			' WHERE t60_compania    = ', vg_codcia,
			'   AND t60_localidad   = ', vg_codloc,
			expr_cli CLIPPED,
			'   AND t60_fecing      BETWEEN "', fec_i,
						 '" AND "', fec_f, '"',
			'   AND t23_compania    = t60_compania ',
			'   AND t23_localidad   = t60_localidad ',
			'   AND t23_num_factura = t60_fac_nue ',
			' ORDER BY ',
				vm_columna_1, ' ', rm_orden[vm_columna_1], ', ',
				vm_columna_2, ' ', rm_orden[vm_columna_2] 
	PREPARE crep FROM query
	DECLARE q_crep CURSOR FOR crep 
	LET i         = 1
	LET total_gen = 0
	FOREACH q_crep INTO rm_refact[i].*, t60_motivo_refact[i]
		LET total_gen = total_gen + rm_refact[i].total_fact
		LET i         = i + 1
		IF i > vm_max_rows THEN
			EXIT FOREACH
		END IF
	END FOREACH
	LET vm_num_rows = i - 1
	IF vm_num_rows = 0 THEN
		CALL fl_mensaje_consulta_sin_registros()
		EXIT WHILE
	END IF
	IF vg_gui = 0 THEN
		CALL muestra_contadores_det(1, vm_num_rows)
		DISPLAY BY NAME t60_motivo_refact[1]
	END IF
	DISPLAY BY NAME total_gen
	LET int_flag = 0
	CALL set_count(vm_num_rows)
	DISPLAY ARRAY rm_refact TO rm_refact.*
		ON KEY(INTERRUPT)
			LET int_flag = 1
			EXIT DISPLAY
		ON KEY(RETURN)
			LET i = arr_curr()
			CALL muestra_contadores_det(i, vm_num_rows)
			DISPLAY BY NAME t60_motivo_refact[i]
        	ON KEY(F1,CONTROL-W)
			CALL control_visor_teclas_caracter_1()
		ON KEY(F5)
			LET i = arr_curr()
			CALL control_ver_factura(rm_refact[i].t60_fac_nue)
			LET int_flag = 0
		ON KEY(F6)
			LET i = arr_curr()
			CALL control_ver_factura(rm_refact[i].t60_fac_ant)
			LET int_flag = 0
		ON KEY(F7)
			LET i = arr_curr()
			CALL ver_refacturacion(i)
			LET int_flag = 0
		ON KEY(F8)
			CALL control_imprimir()
			LET int_flag = 0
		ON KEY(F15)
			LET col = 1
			EXIT DISPLAY
		ON KEY(F16)
			LET col = 2
			EXIT DISPLAY
		ON KEY(F17)
			LET col = 3
			EXIT DISPLAY
		ON KEY(F18)
			LET col = 4
			EXIT DISPLAY
		ON KEY(F19)
			LET col = 5
			EXIT DISPLAY
		ON KEY(F20)
			LET col = 6
			EXIT DISPLAY
		ON KEY(F21)
			LET col = 7
			EXIT DISPLAY
		--#BEFORE ROW
			--#LET i = arr_curr()
			--#CALL muestra_contadores_det(i, vm_num_rows)
			--#DISPLAY BY NAME t60_motivo_refact[i]
		--#BEFORE DISPLAY
			--#CALL dialog.keysetlabel("ACCEPT","")
			--#CALL dialog.keysetlabel("F1","")
			--#CALL dialog.keysetlabel("CONTROL-W","")
			--#CALL dialog.keysetlabel("RETURN","")
		--#AFTER DISPLAY
			--#CONTINUE DISPLAY
	END DISPLAY
	IF int_flag = 1 THEN
		EXIT WHILE
	END IF
	IF col <> vm_columna_1 THEN
		LET vm_columna_2           = vm_columna_1 
		LET rm_orden[vm_columna_2] = rm_orden[vm_columna_1]
		LET vm_columna_1           = col 
	END IF
	IF rm_orden[vm_columna_1] = 'ASC' THEN
		LET rm_orden[vm_columna_1] = 'DESC'
	ELSE
		LET rm_orden[vm_columna_1] = 'ASC'
	END IF
END WHILE

END FUNCTION



FUNCTION muestra_contadores_det(num_row, max_row)
DEFINE num_row, max_row	SMALLINT

DISPLAY BY NAME num_row, max_row

END FUNCTION



FUNCTION control_imprimir()
DEFINE comando		VARCHAR(100)
DEFINE i		SMALLINT

CALL fl_control_reportes() RETURNING comando
IF int_flag THEN
	RETURN
END IF
START REPORT reporte_refact TO PIPE comando
FOR i = 1 TO vm_num_rows
	OUTPUT TO REPORT reporte_refact(i)
END FOR
FINISH REPORT reporte_refact

END FUNCTION



REPORT reporte_refact(i)
DEFINE i		SMALLINT
DEFINE r_g50		RECORD LIKE gent050.*
DEFINE usuario		VARCHAR(19,15)
DEFINE modulo		VARCHAR(40)
DEFINE escape		SMALLINT
DEFINE act_comp		SMALLINT
DEFINE desact_comp	SMALLINT
DEFINE act_10cpi	SMALLINT
DEFINE act_neg, des_neg	SMALLINT

OUTPUT
	TOP MARGIN	1
	LEFT MARGIN	0
	RIGHT MARGIN	80
	BOTTOM MARGIN	4
	PAGE LENGTH	66

FORMAT

PAGE HEADER
	LET escape	= 27		# Iniciar sec. impresi�n
	LET act_comp	= 15		# Activar Comprimido.
	LET desact_comp	= 18		# Cancelar Comprimido.
	LET act_neg	= 71		# Activar negrita.
	LET des_neg	= 72		# Desactivar negrita.
	LET act_10cpi	= 80		# Comprimido 10 CPI.
	CALL fl_lee_modulo(vg_modulo) RETURNING r_g50.*
	LET modulo      = "MODULO: ", r_g50.g50_nombre[1, 19] CLIPPED
	LET usuario     = "USUARIO: ", vg_usuario
	CALL fl_justifica_titulo('D', usuario, 19) RETURNING usuario
	print ASCII escape;
	print ASCII desact_comp;
	print ASCII escape;
	print ASCII act_10cpi;
	PRINT COLUMN 005, rm_g01.g01_razonsocial,
  	      COLUMN 074, "PAGINA: ", PAGENO USING "&&&"
	PRINT COLUMN 001, modulo CLIPPED,
	      COLUMN 028, "DETALLE DE REFACTURACION",
	      COLUMN 074, UPSHIFT(vg_proceso) CLIPPED
	SKIP 1 LINES
	PRINT COLUMN 015, "** RANGO FECHAS  : ",
	      COLUMN 035, vm_fecha_ini USING "dd-mm-yyyy", "  -  ",
	      COLUMN 050, vm_fecha_fin USING "dd-mm-yyyy"
	IF vm_cliente IS NOT NULL THEN
		PRINT COLUMN 015, "** CLIENTE       : ",
		      COLUMN 035, vm_cliente USING "<<<&&&", ' ',
			tit_cliente[1, 35] CLIPPED
	ELSE
		PRINT 1 SPACES
	END IF
	SKIP 1 LINES
	PRINT COLUMN 001, "FECHA IMPRESION: ", TODAY USING "dd-mm-yyyy",
 		1 SPACES, TIME,
	      COLUMN 062, usuario
	PRINT "--------------------------------------------------------------------------------"
	PRINT COLUMN 001, "FA NU.",
	      COLUMN 008, "OT NU.",
	      COLUMN 015, "FA O.",
	      COLUMN 022, "OT D.",
	      COLUMN 029, "FECHA REF.",
	      COLUMN 047, "C L I E N T E S",
	      COLUMN 070, "      TOTAL"
	PRINT "--------------------------------------------------------------------------------"

ON EVERY ROW
	NEED 3 LINES
	PRINT COLUMN 001, rm_refact[i].t60_fac_nue	USING "<<<<<&",
	      COLUMN 008, rm_refact[i].t60_ot_nue	USING "<<<<<&",
	      COLUMN 015, rm_refact[i].t60_fac_ant	USING "<<<<<&",
	      COLUMN 022, rm_refact[i].t60_ot_ant	USING "<<<<<&",
	      COLUMN 029, rm_refact[i].t60_fecing	USING "dd-mm-yyyy",
	      COLUMN 040, rm_refact[i].t60_nomcli_nue[1, 29] CLIPPED,
	      COLUMN 070, rm_refact[i].total_fact	USING "####,##&.##"
	
ON LAST ROW
	NEED 2 LINES
	PRINT COLUMN 070, "-----------"
	PRINT COLUMN 059, "TOTAL ==>  ", total_gen	USING "####,##&.##"
	print ASCII escape;
	print ASCII act_comp

END REPORT



FUNCTION inicializar_detalle()
DEFINE i		SMALLINT

LET vm_num_rows = 0
FOR i = 1 TO vm_size_arr 
	CLEAR rm_refact[i].*
END FOR
CLEAR t60_motivo_refact, total_gen, num_row, max_row
FOR i = 1 TO vm_max_rows
	INITIALIZE rm_refact[i].* TO NULL
END FOR

END FUNCTION



FUNCTION control_ver_factura(num_fact)
DEFINE num_fact		LIKE talt023.t23_num_factura
DEFINE comando		CHAR(255)
DEFINE run_prog		CHAR(10)

{-- ESTO PARA LLAMAR AL PROGRAMA SEGÚN SEA EL AMBIENTE --}
LET run_prog = '; fglrun '
IF vg_gui = 0 THEN
	LET run_prog = '; fglgo '
END IF
{--- ---}
LET comando = 'cd ..', vg_separador, '..', vg_separador, 'TALLER',
	vg_separador, 'fuentes', vg_separador, run_prog, 'talp308 ', vg_base,
	' ', vg_modulo, ' ', vg_codcia, ' ', vg_codloc, ' ', num_fact
RUN comando	

END FUNCTION



FUNCTION ver_refacturacion(i)
DEFINE i		SMALLINT
DEFINE comando		CHAR(255)
DEFINE run_prog		CHAR(10)

{-- ESTO PARA LLAMAR AL PROGRAMA SEGÚN SEA EL AMBIENTE --}
LET run_prog = '; fglrun '
IF vg_gui = 0 THEN
	LET run_prog = '; fglgo '
END IF
{--- ---}
LET comando = 'cd ..', vg_separador, '..', vg_separador, 'TALLER',
	vg_separador, 'fuentes', vg_separador, run_prog, 'talp214 ', vg_base,
	' ', vg_modulo, ' ', vg_codcia, ' ', vg_codloc, ' ',
	rm_refact[i].t60_fac_ant
RUN comando	

END FUNCTION



FUNCTION llamar_visor_teclas()
DEFINE a		CHAR(1)

IF vg_gui = 0 THEN
	CALL fl_visor_teclas_caracter() RETURNING int_flag 
	LET a = fgl_getkey()
	CLOSE WINDOW w_tf
	LET int_flag = 0
END IF

END FUNCTION



FUNCTION control_visor_teclas_caracter_1() 
DEFINE a, fila		INTEGER

CALL fl_visor_teclas_caracter() RETURNING fila
LET a = fila + 2
DISPLAY 'Teclas exclusivas de este proceso:' AT a,2 ATTRIBUTE(REVERSE)	
LET a = a + 1
DISPLAY '<F5>      Factura Nueva'            AT a,2
DISPLAY  'F5' AT a,3 ATTRIBUTE(REVERSE)
LET a = a + 1
DISPLAY '<F6>      Factura Origen'           AT a,2
DISPLAY  'F6' AT a,3 ATTRIBUTE(REVERSE)
LET a = a + 1
DISPLAY '<F7>      Refacturaci�n'            AT a,2
DISPLAY  'F7' AT a,3 ATTRIBUTE(REVERSE)
LET a = a + 1
DISPLAY '<F8>      Imprimir Listado'         AT a,2
DISPLAY  'F8' AT a,3 ATTRIBUTE(REVERSE)
LET a = fgl_getkey()
CLOSE WINDOW w_tf

END FUNCTION
