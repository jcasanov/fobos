--------------------------------------------------------------------------------
-- Titulo           : cxcp304.4gl - Consulta de cheques protestados
-- Elaboracion      : 15-dic-2001
-- Autor            : NPC
-- Formato Ejecucion: fglrun cxcp304 base módulo compañía localidad
-- Ultima Correccion: 
-- Motivo Correccion: 
--------------------------------------------------------------------------------
GLOBALS '../../../PRODUCCION/LIBRERIAS/fuentes/globales.4gl'

DEFINE vm_nuevoprog     CHAR(400)
DEFINE rm_caj		RECORD LIKE cajt012.*
DEFINE vm_max_det       SMALLINT
DEFINE vm_num_det       SMALLINT
DEFINE vm_scr_lin       SMALLINT
DEFINE localidad	LIKE gent002.g02_localidad
DEFINE vm_fecha_ini	DATE
DEFINE vm_fecha_fin	DATE
DEFINE vm_total         DECIMAL(12,2)
DEFINE rm_orden 	ARRAY[10] OF CHAR(4)
DEFINE vm_columna_1	SMALLINT
DEFINE vm_columna_2	SMALLINT
DEFINE rm_det		ARRAY [1000] OF RECORD
				z01_nomcli	LIKE cxct001.z01_nomcli,
				g08_nombre	LIKE gent008.g08_nombre,
				j12_num_cheque	LIKE cajt012.j12_num_cheque,
				j12_valor	LIKE cajt012.j12_valor
			END RECORD
DEFINE rm_che		ARRAY [1000] OF RECORD
				j12_codcli	LIKE cajt012.j12_codcli,
				j12_banco	LIKE cajt012.j12_banco,
				j12_num_cta	LIKE cajt012.j12_num_cta,
				j12_num_cheque	LIKE cajt012.j12_num_cheque,
				j12_secuencia	LIKE cajt012.j12_secuencia,
				j12_nd_interna	LIKE cajt012.j12_nd_interna
			END RECORD

MAIN

DEFER QUIT 
DEFER INTERRUPT
CLEAR SCREEN
CALL startlog('../logs/cxcp304.err')
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
LET vg_proceso = 'cxcp304'
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
OPEN WINDOW w_mas AT row_ini, 2 WITH num_rows ROWS, num_cols COLUMNS
	ATTRIBUTE(FORM LINE FIRST + 1, COMMENT LINE LAST, MENU LINE lin_menu,
		  BORDER, MESSAGE LINE LAST - 1) 
IF vg_gui = 1 THEN
	OPEN FORM f_cxc FROM "../forms/cxcf304_1"
ELSE
	OPEN FORM f_cxc FROM "../forms/cxcf304_1c"
END IF
DISPLAY FORM f_cxc
LET vm_scr_lin = 0
CALL muestra_contadores_det(0)
CALL borrar_cabecera()
CALL borrar_detalle()
CALL mostrar_cabecera_forma()
CALL control_consulta()

END FUNCTION



FUNCTION control_consulta()
DEFINE i,j,col		SMALLINT
DEFINE query		CHAR(1000)
DEFINE expr_sql         CHAR(600)
DEFINE r_mon		RECORD LIKE gent013.*
DEFINE expr_loc		VARCHAR(50)

LET vm_fecha_ini = TODAY
LET vm_fecha_fin = TODAY
LET rm_caj.j12_moneda = rg_gen.g00_moneda_base
CALL fl_lee_moneda(rm_caj.j12_moneda) RETURNING r_mon.*
IF r_mon.g13_moneda IS NULL THEN
	CALL fl_mostrar_mensaje('Moneda no existe moneda base.','stop')
        EXIT PROGRAM
END IF
DISPLAY r_mon.g13_nombre TO tit_moneda
WHILE TRUE
	LET vm_num_det = 0
	CALL borrar_detalle()
	CALL muestra_contadores_det(0)
	CALL lee_parametros()
	IF int_flag THEN
		EXIT WHILE
	END IF
	IF rm_caj.j12_codcli IS NOT NULL THEN
		LET expr_sql = '  AND j12_codcli = ', rm_caj.j12_codcli
	ELSE
		INITIALIZE expr_sql TO NULL
	END IF
	LET expr_loc = ' '
	IF localidad IS NOT NULL THEN
		LET expr_loc = '  AND j12_localidad = ', localidad
	END IF
	FOR i = 1 TO 10
		LET rm_orden[i] = '' 
	END FOR
	LET rm_orden[1]  = 'ASC'
	LET vm_columna_1 = 1
	LET vm_columna_2 = 2
	LET col          = 1
	WHILE TRUE
		LET query = 'SELECT z01_nomcli, g08_nombre, j12_num_cheque, ',
			'j12_valor, j12_codcli, j12_banco, ',
			'j12_num_cta, j12_num_cheque, j12_secuencia, ',
			'j12_nd_interna ',
			'FROM cajt012, cxct001, gent008 ',
			'WHERE j12_compania    = ', vg_codcia,
			expr_loc CLIPPED,
			expr_sql CLIPPED, 
			'  AND j12_moneda      = "', rm_caj.j12_moneda, '"',
			'  AND DATE(j12_fecing) BETWEEN "', vm_fecha_ini,
			'" AND "', vm_fecha_fin, '"',
			'  AND j12_codcli      = z01_codcli ',
			'  AND j12_banco       = g08_banco ',
			" ORDER BY ", vm_columna_1, ' ', rm_orden[vm_columna_1],
			       	', ', vm_columna_2, ' ', rm_orden[vm_columna_2]
		PREPARE deto FROM query
		DECLARE q_deto CURSOR FOR deto
		LET vm_num_det = 1
		FOREACH q_deto INTO rm_det[vm_num_det].*, rm_che[vm_num_det].*
			LET vm_num_det = vm_num_det + 1
			IF vm_num_det > vm_max_det THEN
				EXIT FOREACH
			END IF
		END FOREACH
		LET vm_num_det = vm_num_det - 1
		IF vm_num_det = 0 THEN
			CALL fl_mensaje_consulta_sin_registros()
			EXIT WHILE
		END IF
		CALL sacar_total()
		CALL set_count(vm_num_det)
		LET int_flag = 0
		DISPLAY ARRAY rm_det TO rm_det.*
			ON KEY(INTERRUPT)
				LET int_flag = 1
				EXIT DISPLAY
        		ON KEY(F1,CONTROL-W)
				CALL control_visor_teclas_caracter_1() 
			ON KEY(F5)
				LET i = arr_curr()
				LET j = scr_line()
				CALL ver_cheque(i)
				LET int_flag = 0
			ON KEY(F6)
				LET i = arr_curr()
				LET j = scr_line()
				CALL ver_documento('ND', i)
				LET int_flag = 0
			ON KEY(F7)
				LET i = arr_curr()
				LET j = scr_line()
				CALL ver_documento('DO', i)
				LET int_flag = 0
			ON KEY(F8)
				LET i = arr_curr()
				LET j = scr_line()
				CALL ver_estado_cuenta(i)
				LET int_flag = 0
			ON KEY(F9)
				LET i = arr_curr()
				LET j = scr_line()
				CALL imprimir_documentos('ND', i)
				LET int_flag = 0
			ON KEY(F10)
				LET i = arr_curr()
				LET j = scr_line()
				CALL imprimir_documentos('DO', i)
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
			--#BEFORE DISPLAY
				--#CALL dialog.keysetlabel('ACCEPT','')
				--#CALL dialog.keysetlabel('RETURN','')
				--#CALL dialog.keysetlabel("F1","")
				--#CALL dialog.keysetlabel("CONTROL-W","")
			--#BEFORE ROW
				--#LET i = arr_curr()
				--#LET j = scr_line()
				--#CALL muestra_contadores_det(i)
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
END WHILE

END FUNCTION



FUNCTION lee_parametros()
DEFINE r_g02		RECORD LIKE gent002.*
DEFINE r_mon		RECORD LIKE gent013.*
DEFINE r_cli		RECORD LIKE cxct001.*
DEFINE mone_aux         LIKE gent013.g13_moneda
DEFINE nomm_aux         LIKE gent013.g13_nombre
DEFINE deci_aux         LIKE gent013.g13_decimales
DEFINE codcli		LIKE cajt012.j12_codcli
DEFINE nomcli		LIKE cxct001.z01_nomcli
DEFINE fecha_ini	DATE
DEFINE fecha_fin	DATE

INITIALIZE mone_aux, codcli TO NULL
LET int_flag = 0
INPUT BY NAME rm_caj.j12_moneda, vm_fecha_ini, vm_fecha_fin, localidad,
	rm_caj.j12_codcli
	WITHOUT DEFAULTS
	ON KEY(INTERRUPT)
		LET int_flag = 1
		RETURN
        ON KEY(F1,CONTROL-W)
		CALL llamar_visor_teclas()
	ON KEY(F2)
		IF INFIELD(j12_moneda) THEN
               		CALL fl_ayuda_monedas()
                       		RETURNING mone_aux, nomm_aux, deci_aux
       		      	LET int_flag = 0
                      	IF mone_aux IS NOT NULL THEN
                              	LET rm_caj.j12_moneda = mone_aux
                               	DISPLAY BY NAME rm_caj.j12_moneda
                               	DISPLAY nomm_aux TO tit_moneda
                       	END IF
                END IF
		IF INFIELD(localidad) THEN
			CALL fl_ayuda_localidad(vg_codcia)
				RETURNING r_g02.g02_localidad, r_g02.g02_nombre
			IF r_g02.g02_localidad IS NOT NULL THEN
				LET localidad = r_g02.g02_localidad
				DISPLAY BY NAME localidad
				DISPLAY r_g02.g02_nombre TO tit_localidad
			END IF
		END IF
		IF INFIELD(j12_codcli) THEN
			IF localidad IS NULL THEN
                     		CALL fl_ayuda_cliente_general()
					RETURNING codcli, nomcli
			ELSE
				CALL fl_ayuda_cliente_localidad(vg_codcia,
								localidad)
					RETURNING codcli, nomcli
			END IF
                       	IF codcli IS NOT NULL THEN
                             	LET rm_caj.j12_codcli = codcli
                               	DISPLAY BY NAME rm_caj.j12_codcli
                               	DISPLAY nomcli TO tit_nombre_cli
                        END IF
                END IF
		LET int_flag = 0
	BEFORE INPUT
		--#CALL dialog.keysetlabel("F1","")
		--#CALL dialog.keysetlabel("CONTROL-W","")
	BEFORE FIELD vm_fecha_ini
		LET fecha_ini = vm_fecha_ini
	BEFORE FIELD vm_fecha_fin
		LET fecha_fin = vm_fecha_fin
	AFTER FIELD j12_moneda
               	IF rm_caj.j12_moneda IS NOT NULL THEN
                       	CALL fl_lee_moneda(rm_caj.j12_moneda)
                               	RETURNING r_mon.*
                       	IF r_mon.g13_moneda IS NULL THEN
                               	--CALL fgl_winmessage(vg_producto,'Moneda no existe.','exclamation')
				CALL fl_mostrar_mensaje('Moneda no existe.','exclamation')
                               	NEXT FIELD j12_moneda
                       	END IF
               	ELSE
                       	LET rm_caj.j12_moneda = rg_gen.g00_moneda_base
                       	CALL fl_lee_moneda(rm_caj.j12_moneda)
				RETURNING r_mon.*
                       	DISPLAY BY NAME rm_caj.j12_moneda
               	END IF
               	DISPLAY r_mon.g13_nombre TO tit_moneda
	AFTER FIELD localidad
		IF localidad IS NOT NULL THEN
			CALL fl_lee_localidad(vg_codcia, localidad)
				RETURNING r_g02.*
			IF r_g02.g02_compania IS NULL THEN
				CALL fl_mostrar_mensaje('Localidad no existe.','exclamation')
				NEXT FIELD localidad
			END IF
			IF r_g02.g02_estado = 'B' THEN
				CALL fl_mensaje_estado_bloqueado()
				NEXT FIELD localidad
			END IF
			DISPLAY r_g02.g02_nombre TO tit_localidad
		ELSE
			CLEAR tit_localidad
		END IF
	AFTER FIELD j12_codcli
               	IF rm_caj.j12_codcli IS NOT NULL THEN
                       	CALL fl_lee_cliente_general(rm_caj.j12_codcli)
                     		RETURNING r_cli.*
                        IF r_cli.z01_codcli IS NULL THEN
                               	--CALL fgl_winmessage(vg_producto,'Cliente no existe.','exclamation')
				CALL fl_mostrar_mensaje('Cliente no existe.','exclamation')
                               	NEXT FIELD j12_codcli
                        END IF
			DISPLAY r_cli.z01_nomcli TO tit_nombre_cli
		ELSE
			CLEAR tit_nombre_cli
                END IF
	AFTER FIELD vm_fecha_ini 
		IF vm_fecha_ini IS NOT NULL THEN
			IF vm_fecha_ini > TODAY THEN
				--CALL fgl_winmessage(vg_producto,'La fecha de inicio no puede ser mayor a la de hoy.','exclamation')
				CALL fl_mostrar_mensaje('La fecha de inicio no puede ser mayor a la de hoy.','exclamation')
				NEXT FIELD vm_fecha_ini
			END IF
		END IF
	AFTER FIELD vm_fecha_fin 
		IF vm_fecha_fin IS NOT NULL THEN
			IF vm_fecha_fin > TODAY THEN
				--CALL fgl_winmessage(vg_producto,'La fecha de término no puede ser mayor a la de hoy.','exclamation')
				CALL fl_mostrar_mensaje('La fecha de término no puede ser mayor a la de hoy.','exclamation')
				NEXT FIELD vm_fecha_fin
			END IF
		ELSE
			LET vm_fecha_fin = fecha_fin
			DISPLAY BY NAME vm_fecha_fin
		END IF
	AFTER INPUT
		IF vm_fecha_ini > vm_fecha_fin THEN
			--CALL fgl_winmessage(vg_producto,'Fecha inicial debe ser menor a fecha final.','exclamation')
			CALL fl_mostrar_mensaje('Fecha inicial debe ser menor a fecha final.','exclamation')
			NEXT FIELD vm_fecha_ini
		END IF
END INPUT

END FUNCTION



FUNCTION sacar_total()
DEFINE i		SMALLINT

LET vm_total = 0
FOR i = 1 TO vm_num_det
	LET vm_total = vm_total + rm_det[i].j12_valor
END FOR
DISPLAY vm_total TO tit_total

END FUNCTION



FUNCTION borrar_cabecera()

CLEAR localidad, tit_localidad, j12_moneda, tit_moneda, vm_fecha_ini,
	vm_fecha_fin, j12_codcli, tit_nombre_cli
INITIALIZE localidad, rm_caj.*, vm_fecha_ini, vm_fecha_fin TO NULL

END FUNCTION



FUNCTION borrar_detalle()
DEFINE i  		SMALLINT

CALL muestra_contadores_det(0)
LET vm_scr_lin = fgl_scr_size('rm_det')
FOR i = 1 TO vm_scr_lin
        INITIALIZE rm_det[i].*, rm_che[i] TO NULL
        CLEAR rm_det[i].*
END FOR
CLEAR tit_total

END FUNCTION



FUNCTION muestra_contadores_det(cor)
DEFINE cor	           SMALLINT

IF vg_gui = 1 THEN
	DISPLAY "" AT 6, 62
	DISPLAY cor, " de ", vm_num_det AT 6, 66
END IF

END FUNCTION


 
FUNCTION mostrar_cabecera_forma()

--#DISPLAY 'Cliente'      TO tit_col1
--#DISPLAY 'Banco'        TO tit_col2
--#DISPLAY 'No. Cheque'   TO tit_col3
--#DISPLAY 'Valor Cheque' TO tit_col4

END FUNCTION



FUNCTION ver_cheque(i)
DEFINE i		SMALLINT
DEFINE run_prog		CHAR(10)

IF localidad IS NULL THEN
	RETURN
END IF
{-- ESTO PARA LLAMAR AL PROGRAMA SEGÚN SEA EL AMBIENTE --}
LET run_prog = '; fglrun '
IF vg_gui = 0 THEN
	LET run_prog = '; fglgo '
END IF
{--- ---}
LET vm_nuevoprog = 'cd ..', vg_separador, '..', vg_separador, 'COBRANZAS',
	vg_separador, 'fuentes', vg_separador, run_prog, 'cxcp207 ', vg_base,
	' ', vg_modulo, ' ', vg_codcia, ' ', localidad, ' ',
	rm_che[i].j12_banco, ' ', '"', rm_che[i].j12_num_cta, '"', ' ',
	'"', rm_che[i].j12_num_cheque, '"', ' ', rm_che[i].j12_secuencia
RUN vm_nuevoprog

END FUNCTION



FUNCTION ver_estado_cuenta(i)
DEFINE i		SMALLINT
DEFINE run_prog		CHAR(10)
DEFINE fecha		DATE
DEFINE codloc		LIKE gent002.g02_localidad

{-- ESTO PARA LLAMAR AL PROGRAMA SEGÚN SEA EL AMBIENTE --}
LET run_prog = '; fglrun '
IF vg_gui = 0 THEN
	LET run_prog = '; fglgo '
END IF
{--- ---}
LET codloc = 0
IF localidad IS NOT NULL THEN
	LET codloc = localidad
END IF
{--
LET vm_nuevoprog = 'cd ..', vg_separador, '..', vg_separador, 'COBRANZAS',
	vg_separador, 'fuentes', vg_separador, run_prog, 'cxcp305 ', vg_base,
	' ', vg_modulo, ' ', vg_codcia, ' ', codloc, ' ',
	rm_che[i].j12_codcli, ' ', rm_caj.j12_moneda
--}
LET fecha = TODAY
IF vm_fecha_fin IS NOT NULL THEN
	LET fecha = vm_fecha_fin
END IF
LET vm_nuevoprog = 'fglrun cxcp314 ', vg_base, ' ', vg_modulo, ' ', vg_codcia,
			' ', vg_codloc, ' ', rm_caj.j12_moneda, ' ', fecha, ' ',
			' "T" 0.01 "N" ', codloc, ' ', rm_che[i].j12_codcli
RUN vm_nuevoprog

END FUNCTION



FUNCTION ver_documento(tipo_doc, i)
DEFINE tipo_doc		LIKE cxct020.z20_tipo_doc
DEFINE num_doc		LIKE cxct020.z20_num_doc
DEFINE r_z42		RECORD LIKE cxct042.*
DEFINE i		SMALLINT
DEFINE run_prog		CHAR(10)

IF localidad IS NULL THEN
	CALL fl_mostrar_mensaje('Digite la localidad.', 'exclamation')
	RETURN
END IF
{-- ESTO PARA LLAMAR AL PROGRAMA SEGÚN SEA EL AMBIENTE --}
LET run_prog = '; fglrun '
IF vg_gui = 0 THEN
	LET run_prog = '; fglgo '
END IF
{--- ---}
LET num_doc = rm_che[i].j12_nd_interna
IF tipo_doc = 'ND' THEN
	INITIALIZE r_z42.* TO NULL
	SELECT * INTO r_z42.*
		FROM cxct042
		WHERE z42_compania   = vg_codcia
		  AND z42_localidad  = vg_codloc
		  AND z42_banco      = rm_che[i].j12_banco
		  AND z42_num_cta    = rm_che[i].j12_num_cta
		  AND z42_num_cheque = rm_che[i].j12_num_cheque
		  AND z42_secuencia  = rm_che[i].j12_secuencia
	LET num_doc = r_z42.z42_num_doc
	IF r_z42.z42_compania IS NULL THEN
		CALL fl_mostrar_mensaje('No hay nota de débito.', 'exclamation')
		RETURN
	END IF
END IF
LET vm_nuevoprog = 'cd ..', vg_separador, '..', vg_separador, 'COBRANZAS',
	vg_separador, 'fuentes', vg_separador, run_prog, 'cxcp200 ', vg_base,
	' ', vg_modulo, ' ', vg_codcia, ' ', localidad, ' ',
	rm_che[i].j12_codcli, ' "', tipo_doc, '" ', num_doc, ' ', 1
RUN vm_nuevoprog

END FUNCTION



FUNCTION imprimir_documentos(tipo_doc, i)
DEFINE tipo_doc		LIKE cxct020.z20_tipo_doc
DEFINE num_doc		LIKE cxct020.z20_num_doc
DEFINE r_z42		RECORD LIKE cxct042.*
DEFINE i		SMALLINT
DEFINE run_prog		CHAR(10)

IF localidad IS NULL THEN
	CALL fl_mostrar_mensaje('Digite la localidad.', 'exclamation')
	RETURN
END IF
{-- ESTO PARA LLAMAR AL PROGRAMA SEGÚN SEA EL AMBIENTE --}
LET run_prog = '; fglrun '
IF vg_gui = 0 THEN
	LET run_prog = '; fglgo '
END IF
{--- ---}
LET num_doc = rm_che[i].j12_nd_interna
IF tipo_doc = 'ND' THEN
	INITIALIZE r_z42.* TO NULL
	SELECT * INTO r_z42.*
		FROM cxct042
		WHERE z42_compania   = vg_codcia
		  AND z42_localidad  = vg_codloc
		  AND z42_banco      = rm_che[i].j12_banco
		  AND z42_num_cta    = rm_che[i].j12_num_cta
		  AND z42_num_cheque = rm_che[i].j12_num_cheque
		  AND z42_secuencia  = rm_che[i].j12_secuencia
	LET num_doc = r_z42.z42_num_doc
	IF r_z42.z42_compania IS NULL THEN
		CALL fl_mostrar_mensaje('No hay nota de débito.', 'exclamation')
		RETURN
	END IF
END IF
LET vm_nuevoprog = 'cd ..', vg_separador, '..', vg_separador, 'COBRANZAS',
	vg_separador, 'fuentes', vg_separador, run_prog, 'cxcp415 ', vg_base,
	' ', vg_modulo, ' ', vg_codcia, ' ', localidad, ' ',
	rm_che[i].j12_codcli, ' "', tipo_doc, '" ', num_doc, ' 1' 
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
DISPLAY '<F5>      Cheque'                   AT a,2
DISPLAY  'F5' AT a,3 ATTRIBUTE(REVERSE)
LET a = a + 1
DISPLAY '<F6>      Nota de Débito'           AT a,2
DISPLAY  'F6' AT a,3 ATTRIBUTE(REVERSE)
LET a = a + 1
DISPLAY '<F7>      Documento'                AT a,2
DISPLAY  'F7' AT a,3 ATTRIBUTE(REVERSE)
LET a = a + 1
DISPLAY '<F8>      Estado Cuenta'            AT a,2
DISPLAY  'F8' AT a,3 ATTRIBUTE(REVERSE)
LET a = a + 1
DISPLAY '<F9>      Imprimir N/D'             AT a,2
DISPLAY  'F9' AT a,3 ATTRIBUTE(REVERSE)
LET a = a + 1
DISPLAY '<F10>      Imprimir Documento'      AT a,2
DISPLAY  'F10' AT a,3 ATTRIBUTE(REVERSE)
LET a = fgl_getkey()
CLOSE WINDOW w_tf

END FUNCTION
