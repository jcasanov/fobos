------------------------------------------------------------------------------
-- Titulo           : repp301.4gl - Consulta de Utilidad de Facturas
-- Elaboracion      : 07-dic-2001
-- Autor            : GVA
-- Formato Ejecucion: fglrun repp301 base m�dulo compa��a localidad
-- Ultima Correccion: 1
-- Motivo Correccion: 1
------------------------------------------------------------------------------

GLOBALS '../../../PRODUCCION/LIBRERIAS/fuentes/globales.4gl'

DEFINE vm_demonios	VARCHAR(12)
DEFINE rm_r19		RECORD LIKE rept019.*
DEFINE rm_r20		RECORD LIKE rept020.*
DEFINE vm_max_det       SMALLINT
DEFINE vm_num_det       SMALLINT
DEFINE vm_scr_lin       SMALLINT
DEFINE vm_size_arr	INTEGER
DEFINE vm_fecha_desde	DATE
DEFINE vm_fecha_hasta	DATE
DEFINE utilidad_desde	DECIMAL(7,2)
DEFINE utilidad_hasta	DECIMAL(7,2)
DEFINE vm_tipo_tran	LIKE rept019.r19_cod_tran
DEFINE nom_cliente      LIKE cxct001.z01_nomcli
DEFINE nom_moneda       LIKE gent013.g13_nombre

DEFINE rm_orden 	ARRAY[10] OF CHAR(4)
DEFINE vm_columna_1	SMALLINT
DEFINE vm_columna_2	SMALLINT

DEFINE r_detalle	ARRAY [1000] OF RECORD
				fecha		DATE,
				tipo_tran	LIKE rept019.r19_cod_tran,
				num_tran	LIKE rept019.r19_num_tran,
				siglas_vend	LIKE rept001.r01_iniciales,
				tot_sin_impto	LIKE rept019.r19_tot_neto,
				tot_costo	LIKE rept019.r19_tot_neto,
				utilidad	DECIMAL(12,2)
			END RECORD

DEFINE vm_filas_pant 	SMALLINT


MAIN

DEFER QUIT 
DEFER INTERRUPT
CLEAR SCREEN
CALL startlog('../logs/errores')
--#CALL fgl_init4js()
CALL fl_marca_registrada_producto()

IF num_args() <> 4 THEN          -- Validar # par�metros correcto
	--CALL fgl_winmessage(vg_producto,'N�mero de par�metros incorrecto.','stop')
	CALL fl_mostrar_mensaje('N�mero de par�metros incorrecto.','stop')
	EXIT PROGRAM
END IF

LET vg_base     = arg_val(1)
LET vg_modulo   = arg_val(2)
LET vg_codcia   = arg_val(3)
LET vg_codloc   = arg_val(4)
LET vg_proceso = 'repp301'
CALL fl_activar_base_datos(vg_base)
CALL fl_seteos_defaults()	
--#CALL fgl_settitle(vg_proceso || ' - ' || vg_producto)
CALL fl_validar_parametros()
CALL fl_cabecera_pantalla(vg_codcia, vg_codloc, vg_modulo, vg_proceso)

CALL funcion_master()

END MAIN



FUNCTION funcion_master()
DEFINE i	 	SMALLINT
DEFINE r_g13		RECORD LIKE gent013.*
DEFINE lin_menu		SMALLINT
DEFINE row_ini  	SMALLINT
DEFINE num_rows 	SMALLINT
DEFINE num_cols 	SMALLINT

CALL fl_nivel_isolation()
CREATE TEMP TABLE tmp_consulta(
	fecha		DATE,
	tipo_tran	CHAR(2),
	num_tran	DECIMAL(15,0),
	siglas_vend	CHAR(3),
	tot_sin_impto	DECIMAL(12,2),
	tot_costo	DECIMAL(12,2),
	utilidad	DECIMAL(12,2)
)
LET vm_max_det  = 1000

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
OPEN WINDOW w_repp301 AT row_ini, 2 WITH num_rows ROWS, num_cols COLUMNS
	ATTRIBUTE(FORM LINE FIRST + 1, COMMENT LINE LAST, MENU LINE lin_menu,
		  MESSAGE LINE LAST - 1, BORDER) 
OPTIONS INPUT NO WRAP,
	ACCEPT KEY	F12
IF vg_gui = 1 THEN
	OPEN FORM f_repp301 FROM "../forms/repf301_1"
ELSE
	OPEN FORM f_repp301 FROM "../forms/repf301_1c"
END IF
DISPLAY FORM f_repp301

LET vm_num_det = 0
INITIALIZE rm_r19.*, utilidad_desde, utilidad_hasta, 
	   vm_fecha_desde, vm_fecha_hasta TO NULL

LET vm_fecha_hasta    = TODAY
LET rm_r19.r19_moneda = rg_gen.g00_moneda_base
LET vm_tipo_tran      = 'FA'
IF vg_gui = 0 THEN
	CALL muestra_tipotran(vm_tipo_tran)
END IF
CALL fl_lee_moneda(rm_r19.r19_moneda)
	RETURNING r_g13.* 
LET nom_moneda = r_g13.g13_nombre

WHILE TRUE
	FOR i = 1 TO vm_max_det
		INITIALIZE r_detalle[i].* TO NULL
	END FOR
	CLEAR FORM 
	--#DISPLAY "" AT 21, 2
	--#DISPLAY '0', " de ", '0' AT 21, 2
	DELETE FROM tmp_consulta
	CALL control_DISPLAY_botones()

	CALL control_lee_cabecera()
	IF INT_FLAG THEN
		CONTINUE WHILE
	END IF
	CALL control_consulta()
	IF vm_num_det = 0 THEN
		--CALL fgl_winmessage(vg_producto,'No se encontraron registros con el criterio indicado.','exclamation')
		CALL fl_mostrar_mensaje('No se encontraron registros con el criterio indicado.','exclamation')
		CONTINUE WHILE
	END IF
	CALL control_DISPLAY_array()
END WHILE

END FUNCTION



FUNCTION control_DISPLAY_botones()

--#DISPLAY 'Fecha'       	TO tit_col1
--#DISPLAY 'TP'			TO tit_col2
--#DISPLAY 'N�mero'       	TO tit_col3
--#DISPLAY 'Vend'     		TO tit_col4
--#DISPLAY 'Total sin Impto.'  	TO tit_col5
--#DISPLAY 'Total Costo' 	TO tit_col6
--#DISPLAY 'Utilidad' 		TO tit_col7

END FUNCTION



FUNCTION control_lee_cabecera()
DEFINE i,j,l,col	SMALLINT
DEFINE r_g13		RECORD LIKE gent013.*

	DISPLAY BY NAME nom_moneda,     rm_r19.r19_moneda, vm_tipo_tran,
			vm_fecha_desde, vm_fecha_hasta

	IF vg_gui = 0 THEN
		CALL muestra_tipotran(vm_tipo_tran)
	END IF

	LET INT_FLAG   = 0
	INPUT BY NAME rm_r19.r19_moneda, vm_tipo_tran, vm_fecha_desde, 
		      vm_fecha_hasta, utilidad_desde, utilidad_hasta
		      WITHOUT DEFAULTS

	ON KEY(INTERRUPT)
		IF NOT FIELD_TOUCHED(r19_moneda,     vm_fecha_desde, 
				     vm_fecha_hasta, vm_tipo_tran)
		   THEN
			EXIT PROGRAM
		END IF
		LET INT_FLAG = 1 
		RETURN

        ON KEY(F1,CONTROL-W)
		CALL llamar_visor_teclas()
	ON KEY(F2)
		IF INFIELD(r19_moneda) THEN
			CALL fl_ayuda_monedas()
				RETURNING r_g13.g13_moneda,
					  r_g13.g13_nombre,
					  r_g13.g13_decimales
			IF r_g13.g13_moneda IS NOT NULL THEN
				LET rm_r19.r19_moneda = r_g13.g13_moneda
				DISPLAY BY NAME rm_r19.r19_moneda 
				DISPLAY r_g13.g13_nombre TO nom_moneda
			END IF 
		END IF
		LET INT_FLAG = 0

	BEFORE INPUT
		--#CALL dialog.keysetlabel("F1","")
		--#CALL dialog.keysetlabel("CONTROL-W","")
	AFTER FIELD r19_moneda 
		IF rm_r19.r19_moneda IS NOT NULL THEN
			CALL fl_lee_moneda(rm_r19.r19_moneda)
				RETURNING r_g13.* 
			IF r_g13.g13_moneda IS NULL  THEN
				--CALL fgl_winmessage(vg_producto,'Moneda no existe.','exclamation')
				CALL fl_mostrar_mensaje('Moneda no existe.','exclamation')
				NEXT FIELD r19_moneda
			END IF
			LET nom_moneda = r_g13.g13_nombre
			DISPLAY BY NAME nom_moneda
		ELSE
			CLEAR nom_moneda
			NEXT FIELD r19_moneda
		END IF

	AFTER FIELD vm_fecha_desde 
		IF vm_fecha_desde IS NOT NULL THEN
			IF vm_fecha_desde > TODAY THEN
				--CALL fgl_winmessage(vg_producto,'La fecha de inicio no puede ser mayor a la de hoy.','exclamation')
				CALL fl_mostrar_mensaje('La fecha de inicio no puede ser mayor a la de hoy.','exclamation')
				NEXT FIELD vm_fecha_desde
			END IF
			IF vm_fecha_desde < '01-01-1990' THEN
				--CALL fgl_winmessage(vg_producto,'Debe ingresa fechas mayores a las del a�o 1989.','exclamation')	
				CALL fl_mostrar_mensaje('Debe ingresa fechas mayores a las del a�o 1989.','exclamation')	
				NEXT FIELD vm_fecha_desde
			END IF
				
		ELSE 
			NEXT FIELD vm_fecha_desde
		END IF

	AFTER FIELD vm_fecha_hasta 
		IF vm_fecha_hasta IS NOT NULL THEN
			IF vm_fecha_hasta > TODAY THEN
				--CALL fgl_winmessage(vg_producto,'La fecha de t�rmino no puede ser mayor a la de hoy.','exclamation')
				CALL fl_mostrar_mensaje('La fecha de t�rmino no puede ser mayor a la de hoy.','exclamation')
				NEXT FIELD vm_fecha_hasta
			END IF
			IF vm_fecha_hasta < '01-01-1990' THEN
				--CALL fgl_winmessage(vg_producto,'Debe ingresa fechas mayores a las del a�o 1989.','exclamation')	
				CALL fl_mostrar_mensaje('Debe ingresa fechas mayores a las del a�o 1989.','exclamation')	
				NEXT FIELD vm_fecha_hasta
			END IF
		ELSE
			NEXT FIELD vm_fecha_hasta
		END IF

	AFTER FIELD vm_tipo_tran
		IF vg_gui = 0 THEN
			IF vm_tipo_tran IS NOT NULL THEN
				CALL muestra_tipotran(vm_tipo_tran)
			ELSE
				CLEAR tit_tipo_tran
			END IF
		END IF

	AFTER INPUT
		IF utilidad_desde > utilidad_hasta THEN
			--CALL fgl_winmessage(vg_producto,'La el procentaje de ulidad inicial debe ser menor al porcentaje de la utilidad final.','exclamation')
			CALL fl_mostrar_mensaje('La el procentaje de ulidad inicial debe ser menor al porcentaje de la utilidad final.','exclamation')
			NEXT FIELD utilidad_desde
		END IF
		IF vm_fecha_desde IS NULL OR
		   vm_fecha_hasta IS NULL
		   THEN
			CONTINUE INPUT 
		END IF
		IF utilidad_desde IS NULL AND utilidad_hasta IS NOT NULL THEN
			--CALL fgl_winmessage(vg_producto,'No ha ingresado la utilidad inicial. Debe ingresar las dos rangos de utilidad o si quiere ver todo blanque los dos campos de rangos de utilidad.','exclamation')
			CALL fl_mostrar_mensaje('No ha ingresado la utilidad inicial. Debe ingresar las dos rangos de utilidad o si quiere ver todo blanque los dos campos de rangos de utilidad.','exclamation')
			CONTINUE INPUT 
		END IF
		IF utilidad_hasta IS NULL AND utilidad_desde IS NOT NULL THEN
			--CALL fgl_winmessage(vg_producto,'No ha ingresado la utilidad final. Debe ingresar las dos rangos de utilidad o si quiere ver todo blanque los dos campos de rangos de utilidad.','exclamation')
			CALL fl_mostrar_mensaje('No ha ingresado la utilidad final. Debe ingresar las dos rangos de utilidad o si quiere ver todo blanque los dos campos de rangos de utilidad.','exclamation')
			CONTINUE INPUT 
		END IF
		IF utilidad_desde IS NULL AND utilidad_hasta IS NULL THEN
			EXIT INPUT
		END IF

END INPUT

END FUNCTION



FUNCTION control_consulta()
DEFINE query         	CHAR(500)
DEFINE tipo_tran_1   	LIKE rept019.r19_cod_tran
DEFINE tipo_tran_2	LIKE rept019.r19_cod_tran
DEFINE r_r01		RECORD LIKE rept001.*
DEFINE r_r19		RECORD LIKE rept019.*
DEFINE util_aux		DECIMAL(12,2)
DEFINE i		SMALLINT
DEFINE fec_ini, fec_fin	LIKE rept019.r19_fecing
DEFINE expr_tipo	CHAR(40)

LET fec_ini = EXTEND(vm_fecha_desde, YEAR TO SECOND)
LET fec_fin = EXTEND(vm_fecha_hasta, YEAR TO SECOND) + 23 UNITS HOUR +
	      59 UNITS MINUTE + 59 UNITS SECOND
IF vm_tipo_tran = 'TO' THEN
	LET expr_tipo = ' r19_cod_tran IN ("FA","RQ") '
ELSE
	LET expr_tipo = ' r19_cod_tran = "', vm_tipo_tran, '"'
END IF
LET query = 'INSERT INTO tmp_consulta ',
		' SELECT r19_fecing, r19_cod_tran, r19_num_tran, ',
		'   r01_iniciales, r19_tot_bruto - r19_tot_dscto, ',
		'   r19_tot_costo, 0 FROM rept019, rept001 ',
		' WHERE r19_compania  = ',vg_codcia,
		'   AND r19_localidad = ',vg_codloc,
		'   AND ', expr_tipo CLIPPED,
		'   AND r19_fecing ',
		'BETWEEN "', fec_ini, '" AND "', fec_fin, '"',
		'  AND r19_moneda   = "',rm_r19.r19_moneda, '" ',
		'  AND r19_compania = r01_compania ',
		'  AND r19_vendedor = r01_codigo '
PREPARE in_cons FROM query
EXECUTE in_cons
UPDATE tmp_consulta SET utilidad = ((tot_sin_impto - tot_costo) / tot_costo) 
				   * 100
	WHERE tot_costo > 0
IF utilidad_desde IS NOT NULL THEN
	DELETE FROM tmp_consulta 
		WHERE utilidad < utilidad_desde OR utilidad > utilidad_hasta 
END IF
SELECT COUNT(*) INTO vm_num_det FROM tmp_consulta

END FUNCTION



FUNCTION control_DISPLAY_array()
DEFINE query 		CHAR(300)
DEFINE i,j,m,col 	SMALLINT
DEFINE r_r19		RECORD LIKE rept019.*

FOR i = 1 TO 10
	LET rm_orden[i] = '' 
END FOR
LET rm_orden[1]  = 'ASC'
LET vm_columna_1 = 2
LET vm_columna_2 = 3
LET col          = 2

--#LET vm_size_arr = fgl_scr_size('r_detalle')
IF vg_gui = 0 THEN
	LET vm_size_arr = 10
END IF
LET vm_filas_pant  = vm_size_arr

WHILE TRUE

	LET query = 'SELECT * FROM tmp_consulta ',
			' ORDER BY ', vm_columna_1, ' ', rm_orden[vm_columna_1],
			        ', ', vm_columna_2, ' ', rm_orden[vm_columna_2]
	PREPARE consulta_2 FROM query
	DECLARE q_consulta_2 CURSOR FOR consulta_2

	LET m = 1
	FOREACH q_consulta_2 INTO r_detalle[m].*
		LET m = m + 1
		IF m > vm_max_det THEN
			EXIT FOREACH
		END IF
	END FOREACH
	LET vm_num_det = m - 1
	CALL set_count(vm_num_det)
	LET int_flag = 0
	DISPLAY ARRAY r_detalle TO r_detalle.*

		--#BEFORE DISPLAY
			--#CALL dialog.keysetlabel('ACCEPT','')
			--#CALL dialog.keysetlabel("F1","")
			--#CALL dialog.keysetlabel("CONTROL-W","")

		--#BEFORE ROW
			--#LET i = arr_curr()
			--#LET j = scr_line()
			--#CALL muestra_contadores_det(i)
			--#CALL fl_lee_cabecera_transaccion_rep(vg_codcia, 
							    --# vg_codloc,
							--#r_detalle[i].tipo_tran,
							--#r_detalle[i].num_tran)
				--#RETURNING r_r19.*
			--#DISPLAY r_r19.r19_nomcli TO nom_cliente

		--#AFTER DISPLAY 
			--#CONTINUE DISPLAY

		ON KEY(INTERRUPT)
			LET int_flag = 1
			EXIT DISPLAY
        	ON KEY(F1,CONTROL-W)
			CALL control_visor_teclas_caracter_1() 

		ON KEY(F5)
			LET i = arr_curr()
			LET j = scr_line()
			IF r_detalle[i].tipo_tran = 'FA' THEN
				CALL control_ver_factura(i)
			ELSE
				CALL control_ver_requisicion(i)
			END IF
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



FUNCTION muestra_contadores_det(i)
DEFINE i           SMALLINT

IF vg_gui = 1 THEN
	DISPLAY "" AT 21, 2
	DISPLAY i, " de ", vm_num_det AT 21,2
END IF

END FUNCTION



FUNCTION control_ver_factura(i)
DEFINE i		SMALLINT
DEFINE command_run	CHAR(300)
DEFINE run_prog		CHAR(10)

{-- ESTO PARA LLAMAR AL PROGRAMA SEG�N SEA EL AMBIENTE --}
LET run_prog = '; fglrun '
IF vg_gui = 0 THEN
	LET run_prog = '; fglgo '
END IF
{--- ---}
LET command_run = 'cd ..', vg_separador, '..', vg_separador, 'REPUESTOS',
	vg_separador, 'fuentes', vg_separador, run_prog, 'repp308 ', vg_base,
	' ', vg_modulo, ' ', vg_codcia, ' ', vg_codloc, ' ',
	r_detalle[i].tipo_tran, ' ', r_detalle[i].num_tran
RUN command_run

END FUNCTION



FUNCTION control_ver_requisicion(i)
DEFINE i		SMALLINT
DEFINE command_run	CHAR(300)
DEFINE run_prog		CHAR(10)

{-- ESTO PARA LLAMAR AL PROGRAMA SEG�N SEA EL AMBIENTE --}
LET run_prog = '; fglrun '
IF vg_gui = 0 THEN
	LET run_prog = '; fglgo '
END IF
{--- ---}
LET command_run = 'cd ..', vg_separador, '..', vg_separador, 'REPUESTOS',
	vg_separador, 'fuentes', vg_separador, run_prog, 'repp215 ', vg_base,
	' ', vg_modulo, ' ', vg_codcia, ' ', vg_codloc, ' ',
	r_detalle[i].tipo_tran, ' ', r_detalle[i].num_tran
RUN command_run

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
DISPLAY '<F5>      Ver Comprobante'         AT a,2
DISPLAY  'F5' AT a,3 ATTRIBUTE(REVERSE)
LET a = fgl_getkey()
CLOSE WINDOW w_tf

END FUNCTION



FUNCTION muestra_tipotran(tipotran)
DEFINE tipotran		CHAR(2)

CASE tipotran
	WHEN 'FA'
		DISPLAY 'FACTURA' TO tit_tipo_tran
	WHEN 'RQ'
		DISPLAY 'REQUISICION' TO tit_tipo_tran
	WHEN 'TO'
		DISPLAY 'T O D A S' TO tit_tipo_tran
	OTHERWISE
		CLEAR vm_tipo_tran, tit_tipo_tran
END CASE

END FUNCTION
