------------------------------------------------------------------------------
-- Titulo           : ordp302.4gl - Consulta de proveedores
-- Elaboracion      : 19-Ago-2002
-- Autor            : NPC
-- Formato Ejecucion: fglrun ordp302 base módulo compañía localidad
-- Ultima Correccion:
-- Motivo Correccion:
------------------------------------------------------------------------------
GLOBALS '../../../PRODUCCION/LIBRERIAS/fuentes/globales.4gl'

DEFINE rm_c10		RECORD LIKE ordt010.*
DEFINE vm_fecha_ini	DATE
DEFINE vm_fecha_fin	DATE
DEFINE vm_max_det       SMALLINT
DEFINE vm_nuevoprog     CHAR(600)
DEFINE rm_orden 	ARRAY[10] OF CHAR(4)
DEFINE vm_columna_1	SMALLINT
DEFINE vm_columna_2	SMALLINT
DEFINE rm_g13		RECORD LIKE gent013.*
DEFINE r_detalle	ARRAY [1000] OF RECORD
				p01_codprov	LIKE cxpt001.p01_codprov,
				p01_nomprov	LIKE cxpt001.p01_nomprov,
				c10_tot_compra	LIKE ordt010.c10_tot_compra
			END RECORD
DEFINE lin_menu		SMALLINT
DEFINE row_ini  	SMALLINT
DEFINE num_rows 	SMALLINT
DEFINE num_cols 	SMALLINT


MAIN

DEFER QUIT
DEFER INTERRUPT
CLEAR SCREEN

CALL startlog('../logs/errores')
--#CALL fgl_init4js()
CALL fl_marca_registrada_producto()
IF num_args() <> 4 THEN   -- Validar # parámetros correcto
        --CALL fgl_winmessage(vg_producto,'Número de parámetros incorrecto.','stop')
	CALL fl_mostrar_mensaje('Número de parámetros incorrecto.','stop')
        EXIT PROGRAM
END IF
LET vg_base     = arg_val(1)
LET vg_modulo   = arg_val(2)
LET vg_codcia   = arg_val(3)
LET vg_codloc   = arg_val(4)
LET vg_proceso = 'ordp302'
CALL fl_activar_base_datos(vg_base)
CALL fl_seteos_defaults()
--#CALL fgl_settitle(vg_proceso || ' - ' || vg_producto)
--CALL fl_validar_parametros()
CALL fl_cabecera_pantalla(vg_codcia, vg_codloc, vg_modulo, vg_proceso)
CALL fl_nivel_isolation()
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
OPEN WINDOW w_312 AT row_ini, 2 WITH num_rows ROWS, num_cols COLUMNS
    ATTRIBUTE(FORM LINE FIRST + 1, COMMENT LINE LAST, MENU LINE lin_menu,BORDER,
	      MESSAGE LINE LAST - 1)
IF vg_gui = 1 THEN
	OPEN FORM f_ordf302 FROM "../forms/ordf302_1"
ELSE
	OPEN FORM f_ordf302 FROM "../forms/ordf302_1c"
END IF
DISPLAY FORM f_ordf302
INITIALIZE vm_fecha_ini, vm_fecha_fin, rm_c10.c10_moneda TO NULL
LET vm_max_det 		= 1000
LET vm_fecha_ini	= TODAY
LET vm_fecha_fin	= TODAY
LET rm_c10.c10_moneda	= rg_gen.g00_moneda_base
WHILE TRUE
	CALL funcion_master()
END WHILE

END MAIN



FUNCTION funcion_master()
DEFINE r_c01		RECORD LIKE ordt001.*
DEFINE fecha_ini	DATE
DEFINE fecha_fin	DATE
DEFINE scr_lin 		SMALLINT
DEFINE i		SMALLINT

INITIALIZE r_c01.*, rm_c10.c10_tipo_orden TO NULL
CLEAR nom_moneda, tit_tipo, total_compra
--#LET scr_lin = fgl_scr_size('r_detalle')
IF vg_gui = 0 THEN
	LET scr_lin = 10
END IF
FOR i = 1 TO scr_lin
        INITIALIZE r_detalle[i].* TO NULL
        CLEAR r_detalle[i].*
END FOR
CALL fl_lee_moneda(rm_c10.c10_moneda) 	RETURNING rm_g13.* 
DISPLAY rm_g13.g13_nombre TO nom_moneda
--#DISPLAY 'Código'    TO tit_col1
--#DISPLAY 'Proveedor' TO tit_col2
--#DISPLAY 'Valor'     TO tit_col3
LET int_flag = 0
INPUT BY NAME rm_c10.c10_moneda, vm_fecha_ini, vm_fecha_fin,
	      rm_c10.c10_tipo_orden
	WITHOUT DEFAULTS
	ON KEY(INTERRUPT)
		IF NOT field_touched(rm_c10.c10_moneda, rm_c10.c10_tipo_orden,
			vm_fecha_ini, vm_fecha_fin)
		THEN
			EXIT PROGRAM
		ELSE
			RETURN
		END IF
        ON KEY(F1,CONTROL-W)
		CALL llamar_visor_teclas()
	ON KEY(F2)
		IF INFIELD(c10_moneda) THEN
			CALL fl_ayuda_monedas()
				RETURNING rm_g13.g13_moneda, rm_g13.g13_nombre,
					  rm_g13.g13_decimales
			IF rm_g13.g13_moneda IS NOT NULL THEN
				LET rm_c10.c10_moneda = rm_g13.g13_moneda
				DISPLAY BY NAME rm_c10.c10_moneda
				DISPLAY rm_g13.g13_nombre TO nom_moneda
			END IF
		END IF
		IF INFIELD(c10_tipo_orden) THEN
			CALL fl_ayuda_tipos_ordenes_compras('T')
				RETURNING r_c01.c01_tipo_orden,
				 	  r_c01.c01_nombre
			IF r_c01.c01_tipo_orden IS NOT NULL THEN
				LET rm_c10.c10_tipo_orden = r_c01.c01_tipo_orden
				DISPLAY BY NAME rm_c10.c10_tipo_orden
				DISPLAY r_c01.c01_nombre TO tit_tipo
			END IF
		END IF
		LET int_flag = 0
	BEFORE INPUT
		--#CALL dialog.keysetlabel("F1","")
		--#CALL dialog.keysetlabel("CONTROL-W","")
	BEFORE FIELD vm_fecha_fin
		LET fecha_fin = vm_fecha_fin
	BEFORE FIELD vm_fecha_ini
		LET fecha_ini = vm_fecha_ini
	AFTER FIELD c10_moneda
		IF rm_c10.c10_moneda IS NOT NULL THEN
			CALL fl_lee_moneda(rm_c10.c10_moneda)
				RETURNING rm_g13.*
			IF rm_g13.g13_moneda IS NULL THEN
				CLEAR nom_moneda 
				--CALL fgl_winmessage(vg_producto,'No existe la Moneda en la Compañia.','exclamation')
				CALL fl_mostrar_mensaje('No existe la Moneda en la Compañia.','exclamation')
				NEXT FIELD c10_moneda
			ELSE
				DISPLAY rm_g13.g13_nombre TO nom_moneda
			END IF
		ELSE
			LET rm_c10.c10_moneda	 = rg_gen.g00_moneda_base
			CALL fl_lee_moneda(rm_c10.c10_moneda)
				RETURNING rm_g13.*
			DISPLAY BY NAME rm_c10.c10_moneda
			DISPLAY rm_g13.g13_nombre TO nom_moneda
		END IF
	AFTER FIELD c10_tipo_orden
		IF rm_c10.c10_tipo_orden IS NOT NULL THEN
			CALL fl_lee_tipo_orden_compra(rm_c10.c10_tipo_orden)
				RETURNING r_c01.*
			IF r_c01.c01_tipo_orden IS NULL THEN
				--CALL fgl_winmessage(vg_producto,'No existe ese Tipo de Orden de Compra.','exclamation')
				CALL fl_mostrar_mensaje('No existe ese Tipo de Orden de Compra.','exclamation')
				NEXT FIELD c10_tipo_orden
			END IF
			DISPLAY r_c01.c01_nombre TO tit_tipo
		ELSE
			CLEAR tit_tipo
		END IF
	AFTER INPUT 
		IF vm_fecha_ini IS NULL THEN
			LET vm_fecha_ini = fecha_ini
		END IF
		IF vm_fecha_fin IS NULL THEN
			LET vm_fecha_fin = fecha_fin
		END IF
		IF vm_fecha_ini > vm_fecha_fin THEN
			--CALL fgl_winmessage(vg_producto,'La fecha inicial debe ser menor que la fecha final.','exclamation')
			CALL fl_mostrar_mensaje('La fecha inicial debe ser menor que la fecha final.','exclamation')
			NEXT FIELD vm_fecha_ini
		END IF
		CALL control_DISPLAY_array()
END INPUT

END FUNCTION




FUNCTION control_DISPLAY_array()
DEFINE expr_sql 	CHAR(1000)
DEFINE total_compra	LIKE ordt010.c10_tot_compra
DEFINE i,j,col 		SMALLINT
DEFINE expr_tipo 	VARCHAR(100)
DEFINE tipo		LIKE ordt010.c10_tipo_orden

--#DISPLAY 'Código'    TO tit_col1
--#DISPLAY 'Proveedor' TO tit_col2
--#DISPLAY 'Valor'     TO tit_col3
LET expr_tipo = NULL
LET tipo      = 0
IF rm_c10.c10_tipo_orden IS NOT NULL THEN
	LET expr_tipo = '  AND c10_tipo_orden = ', rm_c10.c10_tipo_orden
	LET tipo      = rm_c10.c10_tipo_orden
END IF
FOR i = 1 TO 10
	LET rm_orden[i] = '' 
END FOR
LET vm_columna_1 		= 3
LET vm_columna_2 		= 1
LET rm_orden[vm_columna_1]  	= 'DESC'
LET col          		= 3
WHILE TRUE
	LET expr_sql = 'SELECT p01_codprov, p01_nomprov, SUM(c10_tot_compra) ',
			'FROM ordt010, cxpt001 ',
			'WHERE c10_compania   = ', vg_codcia,
			'  AND c10_localidad  = ', vg_codloc,
			expr_tipo CLIPPED,
			'  AND c10_estado     = "C"',
			'  AND c10_moneda     = "', rm_c10.c10_moneda, '"',
			'  AND p01_codprov    = c10_codprov ',
			'  AND c10_fecha_fact BETWEEN "',vm_fecha_ini,'"',
			'  AND "',vm_fecha_fin,'"',
			' GROUP BY 1, 2 ',                
			" ORDER BY ", vm_columna_1, ' ', rm_orden[vm_columna_1],
			        ', ', vm_columna_2, ' ', rm_orden[vm_columna_2]
	PREPARE consulta FROM expr_sql
	DECLARE q_consulta CURSOR FOR consulta
	LET total_compra = 0
	LET i = 1
	FOREACH q_consulta INTO r_detalle[i].*
		LET total_compra = total_compra + r_detalle[i].c10_tot_compra
		LET i = i + 1
		IF i > vm_max_det THEN
			EXIT FOREACH
		END IF
	END FOREACH
	LET i = i - 1
	IF i = 0 THEN
		CALL fl_mensaje_consulta_sin_registros()
		RETURN
	END IF
	CALL set_count(i)
	DISPLAY ARRAY r_detalle TO r_detalle.*
		--#BEFORE DISPLAY 
			--#CALL dialog.keysetlabel('ACCEPT','')
			--#CALL dialog.keysetlabel("F1","")
			--#CALL dialog.keysetlabel("CONTROL-W","")
		--#BEFORE ROW
			--#LET j = arr_curr()
			--#DISPLAY '' AT 06,1
			--#DISPLAY j, ' de ', i AT 06,60  
			--#DISPLAY BY NAME total_compra
		ON KEY(INTERRUPT)
			--#DISPLAY '' AT 06,1
			LET int_flag = 1
			RETURN
        	ON KEY(F1,CONTROL-W)
			CALL control_visor_teclas_caracter_1() 
		ON KEY(F5)
			LET j = arr_curr()
			CALL ver_detalle(tipo, j)
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



FUNCTION ver_detalle(tipo_orden, i)
DEFINE tipo_orden	LIKE ordt010.c10_tipo_orden
DEFINE i		SMALLINT
DEFINE run_prog		CHAR(10)

{-- ESTO PARA LLAMAR AL PROGRAMA SEGÚN SEA EL AMBIENTE --}
LET run_prog = '; fglrun '
IF vg_gui = 0 THEN
	LET run_prog = '; fglgo '
END IF
{--- ---}
LET vm_nuevoprog = 'cd ..', vg_separador, '..', vg_separador, 'COMPRAS',
	vg_separador, 'fuentes', vg_separador, run_prog, 'ordp300 ', vg_base,
	' ', vg_modulo, ' ', vg_codcia, ' ', vg_codloc, ' ', tipo_orden, 
	' ', vm_fecha_ini, ' ', vm_fecha_fin, ' ', r_detalle[i].p01_codprov
RUN vm_nuevoprog

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
DISPLAY '<F5>      Detalle'                  AT a,2
DISPLAY  'F5' AT a,3 ATTRIBUTE(REVERSE)
LET a = fgl_getkey()
CLOSE WINDOW w_tf

END FUNCTION
