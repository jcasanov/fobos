--------------------------------------------------------------------------------
-- Titulo           : cxcp303.4gl - Consulta de cheques postfechados
-- Elaboracion      : 13-dic-2001
-- Autor            : NPC
-- Formato Ejecucion: fglrun cxcp303 base módulo compañía localidad
-- Ultima Correccion: 
-- Motivo Correccion: 
--------------------------------------------------------------------------------
GLOBALS '../../../PRODUCCION/LIBRERIAS/fuentes/globales.4gl'

DEFINE vm_nuevoprog     CHAR(400)
DEFINE rm_z20		RECORD LIKE cxct020.*
DEFINE rm_z26		RECORD LIKE cxct026.*
DEFINE localidad	LIKE gent002.g02_localidad
DEFINE tipo_fecha	CHAR(1)
DEFINE vm_fecha_ini	DATE
DEFINE vm_fecha_fin	DATE
DEFINE vm_num_det       SMALLINT
DEFINE vm_max_det       SMALLINT
DEFINE vm_scr_lin       SMALLINT
DEFINE vm_total         DECIMAL(12,2)
DEFINE rm_det		ARRAY[10000] OF RECORD
				z01_nomcli	LIKE cxct001.z01_nomcli,
				z26_localidad	LIKE cxct026.z26_localidad,
				g08_nombre	LIKE gent008.g08_nombre,
				z26_num_cheque	LIKE cxct026.z26_num_cheque,
				z26_fecha_cobro	LIKE cxct026.z26_fecha_cobro,
				z26_valor	LIKE cxct026.z26_valor
			END RECORD
DEFINE rm_che		ARRAY[10000] OF RECORD
				z26_codcli	LIKE cxct026.z26_codcli,
				z26_banco	LIKE cxct026.z26_banco,
				z26_num_cta	LIKE cxct026.z26_num_cta,
				z26_num_cheque	LIKE cxct026.z26_num_cheque,
				z26_tipo_doc	LIKE cxct026.z26_tipo_doc,
				z26_num_doc	LIKE cxct026.z26_num_doc,
				z26_dividendo	LIKE cxct026.z26_dividendo
			END RECORD
DEFINE rm_orden 	ARRAY[10] OF CHAR(4)
DEFINE vm_columna_1	SMALLINT
DEFINE vm_columna_2	SMALLINT



MAIN

DEFER QUIT 
DEFER INTERRUPT
CLEAR SCREEN
CALL startlog('../logs/cxcp303.err')
--#CALL fgl_init4js()
CALL fl_marca_registrada_producto()
IF num_args() <> 4 THEN   -- Validar # parámetros correcto
	CALL fl_mostrar_mensaje('Número de parametros incorrecto.','stop')
	EXIT PROGRAM
END IF
LET vg_base    = arg_val(1)
LET vg_modulo  = arg_val(2)
LET vg_codcia  = arg_val(3)
LET vg_codloc  = arg_val(4)
LET vg_proceso = 'cxcp303'
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
LET vm_max_det = 10000
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
OPEN WINDOW w_mas AT row_ini, 2 WITH num_rows ROWS, num_cols COLUMNS
	ATTRIBUTE(FORM LINE FIRST + 1, COMMENT LINE LAST, MENU LINE lin_menu,
		  BORDER, MESSAGE LINE LAST - 1) 
IF vg_gui = 1 THEN
	OPEN FORM f_cxc FROM "../forms/cxcf303_1"
ELSE
	OPEN FORM f_cxc FROM "../forms/cxcf303_1c"
END IF
DISPLAY FORM f_cxc
LET vm_scr_lin = 0
CALL muestra_contadores_det(0, 0)
CALL borrar_cabecera()
CALL borrar_detalle()
CALL mostrar_cabecera_forma()
CALL control_consulta()

END FUNCTION



FUNCTION control_consulta()
DEFINE r_g13		RECORD LIKE gent013.*

LET vm_fecha_ini      = TODAY
LET tipo_fecha        = 'C'
LET rm_z26.z26_estado = 'A'
LET rm_z20.z20_moneda = rg_gen.g00_moneda_base
CALL fl_lee_moneda(rm_z20.z20_moneda) RETURNING r_g13.*
IF r_g13.g13_moneda IS NULL THEN
	CALL fl_mostrar_mensaje('Moneda no existe moneda base.','stop')
        EXIT PROGRAM
END IF
DISPLAY r_g13.g13_nombre TO tit_moneda
IF vg_gui = 0 THEN
	CALL muestra_estado(rm_z26.z26_estado)
	CALL muestra_tipo_fec(tipo_fecha)
END IF
WHILE TRUE
	LET vm_num_det = 0
	CALL borrar_detalle()
	CALL muestra_contadores_det(0, 0)
	CALL lee_parametros()
	IF int_flag THEN
		EXIT WHILE
	END IF
	CALL muestra_consulta()
END WHILE

END FUNCTION



FUNCTION muestra_consulta()
DEFINE i, j, col	SMALLINT
DEFINE query		CHAR(1200)
DEFINE expr_sql         VARCHAR(100)
DEFINE expr_estado      VARCHAR(100)
DEFINE expr_loc		VARCHAR(100)
DEFINE expr_fecha	VARCHAR(100)

LET expr_sql = NULL
IF rm_z26.z26_codcli IS NOT NULL THEN
	LET expr_sql = '   AND z26_codcli      = ', rm_z26.z26_codcli
END IF
LET expr_estado = NULL
IF rm_z26.z26_estado <> 'T' THEN
	LET expr_estado = '   AND z26_estado      = "', rm_z26.z26_estado, '"'
END IF
LET expr_loc = NULL
IF localidad IS NOT NULL THEN
	LET expr_loc = '   AND z26_localidad   = ', localidad
END IF
LET expr_fecha = NULL
IF tipo_fecha = 'C' THEN
	IF vm_fecha_ini IS NOT NULL THEN
		IF vm_fecha_fin IS NOT NULL THEN
			LET expr_fecha = '   AND z26_fecha_cobro BETWEEN "',
						vm_fecha_ini,
						 '" AND "', vm_fecha_fin, '"'
		ELSE
			LET expr_fecha = '   AND z26_fecha_cobro >= "',
						vm_fecha_ini, '"'
		END IF
	ELSE
		IF vm_fecha_fin IS NOT NULL THEN
			LET expr_fecha = '   AND z26_fecha_cobro <= "',
						vm_fecha_fin, '"'
		END IF
	END IF
ELSE
	IF vm_fecha_ini IS NOT NULL THEN
		IF vm_fecha_fin IS NOT NULL THEN
			LET expr_fecha = '   AND DATE(z26_fecing) BETWEEN "',
						vm_fecha_ini,
						 '" AND "', vm_fecha_fin, '"'
		ELSE
			LET expr_fecha = '   AND DATE(z26_fecing) >= "',
						vm_fecha_ini, '"'
		END IF
	ELSE
		IF vm_fecha_fin IS NOT NULL THEN
			LET expr_fecha = '   AND DATE(z26_fecing) <= "',
						vm_fecha_fin, '"'
		END IF
	END IF
END IF
FOR i = 1 TO 10
	LET rm_orden[i] = ' ' 
END FOR
LET col           = 5
LET vm_columna_1  = col
LET vm_columna_2  = 1
LET rm_orden[col] = 'DESC'
WHILE TRUE
	LET query = 'SELECT z01_nomcli, z26_localidad, g08_nombre, ',
			'z26_num_cheque, z26_fecha_cobro, z26_valor, ',
			'z26_codcli, z26_banco, z26_num_cta, ',
			'z26_num_cheque, z26_tipo_doc, z26_num_doc, ',
			'z26_dividendo ',
			' FROM cxct026, cxct001, gent008 ',
			' WHERE z26_compania    = ', vg_codcia,
			expr_loc CLIPPED,
			expr_sql CLIPPED, 
			expr_estado CLIPPED,
			expr_fecha CLIPPED,
			'  AND z01_codcli       = z26_codcli ',
			'  AND g08_banco        = z26_banco ',
			' ORDER BY ', vm_columna_1, ' ', rm_orden[vm_columna_1],
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
		ON KEY(RETURN)
			LET i = arr_curr()
			CALL muestra_contadores_det(i, vm_num_det)
			DISPLAY rm_det[i].z01_nomcli TO tit_cliente
		ON KEY(F5)
			LET i = arr_curr()
			CALL ver_cheque(i)
			LET int_flag = 0
		ON KEY(F6)
			LET i = arr_curr()
			CALL ver_documento_deudor(i)
			LET int_flag = 0
		ON KEY(F7)
			LET i = arr_curr()
			CALL ver_estado_cuenta(i)
			LET int_flag = 0
		ON KEY(F8)
			CALL imprimir_listado()
			LET int_flag = 0
		ON KEY(F15)
			LET col = 1
			EXIT DISPLAY
		ON KEY(F16)
			IF localidad IS NULL THEN
				LET col = 2
				EXIT DISPLAY
			END IF
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
		--#BEFORE DISPLAY
			--#CALL dialog.keysetlabel('ACCEPT','')
			--#CALL dialog.keysetlabel("RETURN","")
			--#CALL dialog.keysetlabel("F1","")
			--#CALL dialog.keysetlabel("CONTROL-W","")
		--#BEFORE ROW
			--#LET i = arr_curr()
			--#CALL muestra_contadores_det(i, vm_num_det)
			--#DISPLAY rm_det[i].z01_nomcli TO tit_cliente
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



FUNCTION lee_parametros()
DEFINE r_g02		RECORD LIKE gent002.*
DEFINE r_g13		RECORD LIKE gent013.*
DEFINE r_z01		RECORD LIKE cxct001.*
DEFINE mone_aux         LIKE gent013.g13_moneda
DEFINE nomm_aux         LIKE gent013.g13_nombre
DEFINE deci_aux         LIKE gent013.g13_decimales
DEFINE codcli		LIKE cxct026.z26_codcli
DEFINE nomcli		LIKE cxct001.z01_nomcli
DEFINE fecha_ini	DATE
DEFINE fecha_fin	DATE

INITIALIZE mone_aux, codcli TO NULL
LET int_flag = 0
INPUT BY NAME rm_z26.z26_estado, rm_z20.z20_moneda, tipo_fecha, vm_fecha_ini,
	vm_fecha_fin, rm_z26.z26_codcli, localidad
	WITHOUT DEFAULTS
	ON KEY(INTERRUPT)
		LET int_flag = 1
		RETURN
        ON KEY(F1,CONTROL-W)
		CALL llamar_visor_teclas()
	ON KEY(F2)
		IF INFIELD(z20_moneda) THEN
               		CALL fl_ayuda_monedas()
                       		RETURNING mone_aux, nomm_aux, deci_aux
       		      	LET int_flag = 0
                      	IF mone_aux IS NOT NULL THEN
                              	LET rm_z20.z20_moneda = mone_aux
                               	DISPLAY BY NAME rm_z20.z20_moneda
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
		IF INFIELD(z26_codcli) THEN
			IF localidad IS NULL THEN
                     		CALL fl_ayuda_cliente_general()
					RETURNING codcli, nomcli
			ELSE
				CALL fl_ayuda_cliente_localidad(vg_codcia,
								localidad)
					RETURNING codcli, nomcli
			END IF
                       	IF codcli IS NOT NULL THEN
                             	LET rm_z26.z26_codcli = codcli
                               	DISPLAY BY NAME rm_z26.z26_codcli
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
	AFTER FIELD z20_moneda
               	IF rm_z20.z20_moneda IS NOT NULL THEN
                       	CALL fl_lee_moneda(rm_z20.z20_moneda)
                               	RETURNING r_g13.*
                       	IF r_g13.g13_moneda IS NULL THEN
				CALL fl_mostrar_mensaje('Moneda no existe.','exclamation')
                               	NEXT FIELD z20_moneda
                       	END IF
               	ELSE
                       	LET rm_z20.z20_moneda = rg_gen.g00_moneda_base
                       	CALL fl_lee_moneda(rm_z20.z20_moneda)
				RETURNING r_g13.*
                       	DISPLAY BY NAME rm_z20.z20_moneda
               	END IF
               	DISPLAY r_g13.g13_nombre TO tit_moneda
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
	AFTER FIELD z26_codcli
               	IF rm_z26.z26_codcli IS NOT NULL THEN
                       	CALL fl_lee_cliente_general(rm_z26.z26_codcli)
                     		RETURNING r_z01.*
                        IF r_z01.z01_codcli IS NULL THEN
				CALL fl_mostrar_mensaje('Cliente no existe.','exclamation')
                               	NEXT FIELD z26_codcli
                        END IF
			DISPLAY r_z01.z01_nomcli TO tit_nombre_cli
		ELSE
			CLEAR tit_nombre_cli
                END IF
	AFTER FIELD vm_fecha_ini 
		IF vm_fecha_ini IS NOT NULL THEN
			IF vm_fecha_ini < MDY(01, 01, 2003) THEN
				CALL fl_mostrar_mensaje('La Fecha Inicial no puede ser menor a la Fecha de arranque del Sistema.','exclamation')
				NEXT FIELD vm_fecha_ini
			END IF
		END IF
	AFTER FIELD vm_fecha_fin 
		IF vm_fecha_fin IS NOT NULL THEN
			IF vm_fecha_fin < MDY(01, 01, 2003) THEN
				CALL fl_mostrar_mensaje('La Fecha Final no puede ser menor a la Fecha de arranque del Sistema.','exclamation')
				NEXT FIELD vm_fecha_ini
			END IF
		END IF
	AFTER FIELD z26_estado
		IF vg_gui = 0 THEN
			IF rm_z26.z26_estado IS NOT NULL THEN
				CALL muestra_estado(rm_z26.z26_estado)
			ELSE
				CLEAR tit_estado
			END IF
		END IF
	AFTER FIELD tipo_fecha
		IF vg_gui = 0 THEN
			IF tipo_fecha IS NOT NULL THEN
				CALL muestra_tipo_fec(tipo_fecha)
			ELSE
				CLEAR tit_tipo_fecha
			END IF
		END IF
	AFTER INPUT
		IF vm_fecha_ini IS NOT NULL THEN
			IF vm_fecha_fin IS NOT NULL THEN
				IF vm_fecha_ini > vm_fecha_fin THEN
					CALL fl_mostrar_mensaje('La Fecha Inicial debe ser menor a la Fecha Final.','exclamation')
					NEXT FIELD vm_fecha_ini
				END IF
			END IF
		END IF
END INPUT

END FUNCTION



FUNCTION sacar_total()
DEFINE i		SMALLINT

LET vm_total = 0
FOR i = 1 TO vm_num_det
	LET vm_total = vm_total + rm_det[i].z26_valor
END FOR
DISPLAY vm_total TO tit_total

END FUNCTION



FUNCTION borrar_cabecera()

CLEAR localidad, tit_localidad,z26_estado, z20_moneda, tit_moneda, vm_fecha_ini,
	vm_fecha_fin, z26_codcli, tit_nombre_cli, tit_cliente, tipo_fecha
INITIALIZE localidad, rm_z26.*, rm_z20.*, vm_fecha_ini, vm_fecha_fin, tipo_fecha
	TO NULL

END FUNCTION



FUNCTION borrar_detalle()
DEFINE i  		SMALLINT

CALL muestra_contadores_det(0, 0)
LET vm_scr_lin = fgl_scr_size('rm_det')
FOR i = 1 TO vm_scr_lin
        INITIALIZE rm_det[i].*, rm_che[i] TO NULL
        CLEAR rm_det[i].*
END FOR
CLEAR tit_total

END FUNCTION



FUNCTION muestra_contadores_det(num_row, max_row)
DEFINE num_row, max_row	SMALLINT

DISPLAY BY NAME num_row, max_row

END FUNCTION


 
FUNCTION mostrar_cabecera_forma()

--#DISPLAY 'Cliente'		TO tit_col1
--#DISPLAY 'LC'			TO tit_col2
--#DISPLAY 'Banco'		TO tit_col3
--#DISPLAY 'No. Cheque'		TO tit_col4
--#IF tipo_fecha = 'C' THEN
	--#DISPLAY 'Fecha Cob.' TO tit_col5
--#ELSE
	--#DISPLAY 'Fecha Ing.' TO tit_col5
--#END IF
--#DISPLAY 'Valor Cheque'	TO tit_col6

END FUNCTION



FUNCTION muestra_estado(estado)
DEFINE estado		CHAR(1)

CASE estado
	WHEN 'A'
		DISPLAY 'POR COBRAR' TO tit_estado
	WHEN 'B'
		DISPLAY 'COBRADOS'   TO tit_estado
	WHEN 'T'
		DISPLAY 'T O D O S'  TO tit_estado
	OTHERWISE
		CLEAR z26_estado, tit_estado
END CASE

END FUNCTION



FUNCTION muestra_tipo_fec(tipo)
DEFINE tipo		CHAR(1)

CASE tipo
	WHEN 'I'
		DISPLAY 'FECHA INGRESO' TO tit_tipo_fecha
	WHEN 'C'
		DISPLAY 'FECHA COBRO'   TO tit_tipo_fecha
	OTHERWISE
		CLEAR tipo_fecha, tit_tipo_fecha
END CASE

END FUNCTION



FUNCTION ver_cheque(i)
DEFINE i		SMALLINT
DEFINE run_prog		CHAR(10)

{-- ESTO PARA LLAMAR AL PROGRAMA SEGÚN SEA EL AMBIENTE --}
LET run_prog = '; fglrun '
IF vg_gui = 0 THEN
	LET run_prog = '; fglgo '
END IF
{--- ---}
LET vm_nuevoprog = 'cd ..', vg_separador, '..', vg_separador, 'COBRANZAS',
	vg_separador, 'fuentes', vg_separador, run_prog, 'cxcp206 ', vg_base,
	' ', vg_modulo, ' ', vg_codcia, ' ', rm_det[i].z26_localidad, ' ',
	rm_che[i].z26_codcli, ' ', rm_che[i].z26_banco, ' ',
	rm_che[i].z26_num_cta, ' ', rm_che[i].z26_num_cheque
RUN vm_nuevoprog

END FUNCTION



FUNCTION ver_documento_deudor(i)
DEFINE i		SMALLINT
DEFINE run_prog		CHAR(10)

{-- ESTO PARA LLAMAR AL PROGRAMA SEGÚN SEA EL AMBIENTE --}
LET run_prog = '; fglrun '
IF vg_gui = 0 THEN
	LET run_prog = '; fglgo '
END IF
{--- ---}
LET vm_nuevoprog = 'cd ..', vg_separador, '..', vg_separador, 'COBRANZAS',
	vg_separador, 'fuentes', vg_separador, run_prog, 'cxcp200 ', vg_base,
	' ', vg_modulo, ' ', vg_codcia, ' ', rm_det[i].z26_localidad, ' ',
	rm_che[i].z26_codcli, ' ', rm_che[i].z26_tipo_doc, ' ',
	rm_che[i].z26_num_doc, ' ', rm_che[i].z26_dividendo
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
	' ', vg_modulo, ' ', vg_codcia, ' ', codloc, ' ', rm_che[i].z26_codcli,
	' ', rm_z20.z20_moneda
--}
LET fecha = TODAY
IF vm_fecha_ini IS NOT NULL THEN
	LET fecha = vm_fecha_ini
END IF
LET vm_nuevoprog = 'fglrun cxcp314 ', vg_base, ' ', vg_modulo, ' ', vg_codcia,
			' ', vg_codloc, ' ', rm_z20.z20_moneda, ' ', fecha, ' ',
			' "T" 0.01 "N" ', codloc, ' ', rm_che[i].z26_codcli
RUN vm_nuevoprog

END FUNCTION



FUNCTION imprimir_listado()
DEFINE i		SMALLINT
DEFINE run_prog		CHAR(10)
DEFINE codloc		LIKE gent002.g02_localidad
DEFINE codcli		LIKE cxct001.z01_codcli

LET codloc = 0
IF localidad IS NOT NULL THEN
	LET codloc = localidad
END IF
LET codcli = 0
IF rm_z26.z26_codcli IS NOT NULL THEN
	LET codcli = rm_z26.z26_codcli
END IF
{-- ESTO PARA LLAMAR AL PROGRAMA SEGÚN SEA EL AMBIENTE --}
LET run_prog = '; fglrun '
IF vg_gui = 0 THEN
	LET run_prog = '; fglgo '
END IF
{--- ---}
LET vm_nuevoprog = 'cd ..', vg_separador, '..', vg_separador, 'COBRANZAS',
	vg_separador, 'fuentes', vg_separador, run_prog, 'cxcp408 ', vg_base,
	' ', vg_modulo, ' ', vg_codcia, ' ', vg_codloc, ' "', rm_z26.z26_estado,
	'" "', rm_z20.z20_moneda, '" ', codcli, ' ', codloc, ' "', vm_fecha_ini,
	'" "', vm_fecha_fin, '" "', tipo_fecha, '"'
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
DISPLAY '<F6>      Documento'                AT a,2
DISPLAY  'F6' AT a,3 ATTRIBUTE(REVERSE)
LET a = a + 1
DISPLAY '<F7>      Estado Cuenta'            AT a,2
DISPLAY  'F7' AT a,3 ATTRIBUTE(REVERSE)
LET a = a + 1
DISPLAY '<F8>      Imprimir Listado'         AT a,2
DISPLAY  'F8' AT a,3 ATTRIBUTE(REVERSE)
LET a = fgl_getkey()
CLOSE WINDOW w_tf

END FUNCTION
