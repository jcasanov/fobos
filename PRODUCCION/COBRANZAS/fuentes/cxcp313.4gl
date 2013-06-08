--------------------------------------------------------------------------------
-- Titulo           : cxcp313.4gl - Consulta autorización de crédito
-- Elaboracion      : 09-Ago-2005
-- Autor            : NPC
-- Formato Ejecucion: fglrun cxcp313 base módulo compañía localidad
-- Ultima Correccion: 
-- Motivo Correccion:
--------------------------------------------------------------------------------
GLOBALS '../../../PRODUCCION/LIBRERIAS/fuentes/globales.4gl'

DEFINE vm_usua_caja	LIKE cajt010.j10_usuario
DEFINE vm_fecha_ini	DATE
DEFINE vm_fecha_fin	DATE
DEFINE rm_detalle	ARRAY[20000] OF RECORD
				j10_codcli	LIKE cajt010.j10_codcli,
				j10_nomcli	LIKE cajt010.j10_nomcli,
				j10_fecing	LIKE cajt010.j10_fecing,
				r25_cod_tran	LIKE rept025.r25_cod_tran,
				r25_num_tran	LIKE rept025.r25_num_tran,
				r25_valor_cred	LIKE rept025.r25_valor_cred,
				j10_usuario	LIKE cajt010.j10_usuario
			END RECORD
DEFINE rm_aux		ARRAY[20000] OF LIKE cajt010.j10_tipo_fuente
DEFINE vm_max_det       SMALLINT
DEFINE vm_num_det       SMALLINT
DEFINE total_cre	DECIMAL(13,2)
DEFINE rm_orden 	ARRAY[10] OF CHAR(4)
DEFINE vm_columna_1	SMALLINT
DEFINE vm_columna_2	SMALLINT



MAIN
	
DEFER QUIT
DEFER INTERRUPT
CLEAR SCREEN
CALL startlog('../logs/cxcp313.err')
--#CALL fgl_init4js()
CALL fl_marca_registrada_producto()
IF num_args() <> 4 THEN          -- Validar # parámetros correcto
	CALL fl_mostrar_mensaje('Número de parámetros incorrecto', 'stop')
	EXIT PROGRAM
END IF
LET vg_base    = arg_val(1)
LET vg_modulo  = arg_val(2)
LET vg_codcia  = arg_val(3)
LET vg_codloc  = arg_val(4)
LET vg_proceso = 'cxcp313'
CALL fl_activar_base_datos(vg_base)
CALL fl_seteos_defaults()	
--#CALL fgl_settitle(vg_proceso || ' - ' || vg_producto)
CALL fl_validar_parametros()
CALL fl_cabecera_pantalla(vg_codcia, vg_codloc, vg_modulo, vg_proceso)
CALL funcion_master()

END MAIN



FUNCTION funcion_master()
DEFINE expr_sql		CHAR(600)

CALL fl_nivel_isolation()
OPEN WINDOW w_cxcp313 AT 3, 2 WITH 22 ROWS, 80 COLUMNS
	ATTRIBUTE(FORM LINE FIRST + 1, COMMENT LINE LAST, MENU LINE FIRST,
		  BORDER, MESSAGE LINE LAST) 
OPEN FORM f_cxcf313_1 FROM "../forms/cxcf313_1"
DISPLAY FORM f_cxcf313_1
INITIALIZE vm_usua_caja TO NULL
CALL mostrar_botones()
LET vm_max_det   = 20000
LET vm_fecha_ini = TODAY
LET vm_fecha_fin = TODAY
WHILE TRUE
	CALL borrar_detalle()
	CALL lee_parametros() RETURNING expr_sql
	IF int_flag THEN
		RETURN
	END IF
	CALL mostrar_consulta(expr_sql)
END WHILE

END FUNCTION



FUNCTION lee_parametros()
DEFINE r_j02		RECORD LIKE cajt002.*
DEFINE cod_aux		LIKE cajt002.j02_codigo_caja
DEFINE nom_aux		LIKE cajt002.j02_nombre_caja
DEFINE fecha_ini	DATE
DEFINE fecha_fin	DATE
DEFINE expr_sql		CHAR(600)

OPTIONS INPUT NO WRAP
INITIALIZE cod_aux, expr_sql TO NULL
LET int_flag = 0
INPUT BY NAME vm_usua_caja, vm_fecha_ini, vm_fecha_fin
	WITHOUT DEFAULTS
	ON KEY(INTERRUPT)
		LET int_flag = 1
		EXIT INPUT
        ON KEY(F1,CONTROL-W)
		CALL llamar_visor_teclas()
	ON KEY(F2)
		IF INFIELD(vm_usua_caja) THEN
			CALL fl_ayuda_cajas(vg_codcia, vg_codloc)
				RETURNING cod_aux, nom_aux
			OPTIONS INPUT NO WRAP
			LET int_flag = 0
			IF cod_aux IS NOT NULL THEN
				CALL fl_lee_codigo_caja_caja(vg_codcia,
							vg_codloc, cod_aux)
                        		RETURNING r_j02.*
				LET vm_usua_caja = r_j02.j02_usua_caja
				DISPLAY BY NAME vm_usua_caja 
				DISPLAY nom_aux TO j02_nombre_caja
			END IF 
		END IF
	BEFORE INPUT
		--#CALL dialog.keysetlabel("F1","")
		--#CALL dialog.keysetlabel("CONTROL-W","")
	BEFORE FIELD vm_fecha_ini
		LET fecha_ini = vm_fecha_ini
	BEFORE FIELD vm_fecha_fin
		LET fecha_fin = vm_fecha_fin
	AFTER FIELD vm_usua_caja
		IF vm_usua_caja IS NOT NULL THEN
			CALL fl_retorna_caja(vg_codcia, vg_codloc, vm_usua_caja)
                        	RETURNING r_j02.*
			IF r_j02.j02_compania IS NULL THEN
				CALL fl_mostrar_mensaje('Usuario de Caja no existe.','exclamation')
				--NEXT FIELD vm_usua_caja
			END IF
			DISPLAY BY NAME r_j02.j02_nombre_caja
		ELSE
			CLEAR j02_nombre_caja
		END IF
	AFTER FIELD vm_fecha_ini 
		IF vm_fecha_ini IS NOT NULL THEN
			IF vm_fecha_ini > TODAY THEN
				CALL fl_mostrar_mensaje('La Fecha Inicial no puede ser mayor a la fecha de hoy.','exclamation')
				NEXT FIELD vm_fecha_ini
			END IF
		ELSE
			LET vm_fecha_ini = fecha_ini
			DISPLAY BY NAME vm_fecha_ini
		END IF
	AFTER FIELD vm_fecha_fin 
		IF vm_fecha_fin IS NOT NULL THEN
			IF vm_fecha_fin > TODAY THEN
				CALL fl_mostrar_mensaje('La Fecha Final no puede ser mayor a la fecha de hoy.','exclamation')
				NEXT FIELD vm_fecha_fin
			END IF
		ELSE
			LET vm_fecha_fin = fecha_fin
			DISPLAY BY NAME vm_fecha_fin
		END IF
	AFTER INPUT
		IF vm_fecha_ini > vm_fecha_fin THEN
			CALL fl_mostrar_mensaje('La Fecha Inicial debe ser menor a la Fecha Final.','exclamation')
			NEXT FIELD vm_fecha_ini
		END IF
END INPUT
IF int_flag THEN
	RETURN expr_sql
END IF
OPTIONS INPUT WRAP
CONSTRUCT BY NAME expr_sql ON j10_codcli, j10_nomcli--, r25_num_tran, r25_valor_cred
	ON KEY(INTERRUPT)
		LET int_flag = 2
		EXIT CONSTRUCT
        ON KEY(F1,CONTROL-W)
		CALL llamar_visor_teclas()
	BEFORE CONSTRUCT
		--#CALL dialog.keysetlabel("F1","")
		--#CALL dialog.keysetlabel("CONTROL-W","")
END CONSTRUCT
RETURN expr_sql CLIPPED

END FUNCTION



FUNCTION mostrar_consulta(expr_sql)
DEFINE expr_sql		CHAR(600)
DEFINE query		CHAR(2000)
DEFINE expr_caj		CHAR(100)
DEFINE i, j, col	SMALLINT
DEFINE fec_ini, fec_fin	LIKE cajt010.j10_fecing

LET expr_caj = NULL
IF vm_usua_caja IS NOT NULL THEN
	LET expr_caj = '   AND j10_usuario     = "', vm_usua_caja, '"'
END IF
LET fec_ini = EXTEND(vm_fecha_ini, YEAR TO SECOND)
LET fec_fin = EXTEND(vm_fecha_fin, YEAR TO SECOND) + 23 UNITS HOUR +
			59 UNITS MINUTE + 59 UNITS SECOND  
FOR i = 1 TO 10
	LET rm_orden[i] = '' 
END FOR
LET col                    = 5
LET vm_columna_1           = col
LET rm_orden[col]          = 'DESC'
LET vm_columna_2           = 2
LET rm_orden[vm_columna_2] = 'ASC'
WHILE TRUE
	LET query = 'SELECT j10_codcli, j10_nomcli, j10_fecing, r25_cod_tran, ',
				'r25_num_tran, r25_valor_cred, j10_usuario, ',
				'j10_tipo_fuente ',
			' FROM cajt010, rept025 ',
			' WHERE j10_compania    = ', vg_codcia,
			'   AND j10_localidad   = ', vg_codloc,
			'   AND j10_tipo_fuente = "PR" ',
			'   AND j10_estado      = "P" ',
			'   AND j10_valor       = 0 ',
			expr_caj CLIPPED,
			'   AND j10_fecing      BETWEEN "', fec_ini,
						 '" AND "', fec_fin, '" ',
			'   AND r25_compania    = j10_compania ',
			'   AND r25_localidad   = j10_localidad ',
			'   AND r25_numprev     = j10_num_fuente ',
			'   AND ', expr_sql CLIPPED,
		' UNION ',
		' SELECT j10_codcli, j10_nomcli, j10_fecing, "FA", ',
				't23_num_factura, t25_valor_cred, j10_usuario,',
				' j10_tipo_fuente ',
			' FROM cajt010, talt025, talt023 ',
			' WHERE j10_compania    = ', vg_codcia,
			'   AND j10_localidad   = ', vg_codloc,
			'   AND j10_tipo_fuente = "OT" ',
			'   AND j10_estado      = "P" ',
			'   AND j10_valor       = 0 ',
			expr_caj CLIPPED,
			'   AND j10_fecing      BETWEEN "', fec_ini,
						 '" AND "', fec_fin, '" ',
			'   AND t25_compania    = j10_compania ',
			'   AND t25_localidad   = j10_localidad ',
			'   AND t25_orden       = j10_num_fuente ',
			'   AND t23_compania    = t25_compania ',
			'   AND t23_localidad   = t25_localidad ',
			'   AND t23_orden       = t25_orden ',
			'   AND ', expr_sql CLIPPED,
			' ORDER BY ', vm_columna_1, ' ', rm_orden[vm_columna_1],
			       	', ', vm_columna_2, ' ', rm_orden[vm_columna_2]
	PREPARE cons_cre FROM query
	DECLARE q_cre CURSOR FOR cons_cre
	LET vm_num_det = 1
	LET total_cre  = 0
	FOREACH q_cre INTO rm_detalle[vm_num_det].*, rm_aux[vm_num_det]
		LET total_cre  = total_cre +
					rm_detalle[vm_num_det].r25_valor_cred
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
	DISPLAY BY NAME total_cre
	CALL set_count(vm_num_det)
	LET int_flag = 0
	DISPLAY ARRAY rm_detalle TO rm_detalle.*
		ON KEY(INTERRUPT)
			LET int_flag = 1
			EXIT DISPLAY
		ON KEY(F5)
			LET i = arr_curr()
			CALL ver_factura(i)
			LET int_flag = 0
		ON KEY(F6)
			LET i = arr_curr()
			CALL detalle_aprobacion(i)
			LET int_flag = 0
		ON KEY(F7)
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
		--#BEFORE DISPLAY
			--#CALL dialog.keysetlabel('ACCEPT','')
			--#CALL dialog.keysetlabel("F1","")
			--#CALL dialog.keysetlabel("CONTROL-W","")
		--#BEFORE ROW
			--#LET i = arr_curr()
			--#LET j = scr_line()
			--#CALL muestra_contadores_det(i, vm_num_det)
			--#DISPLAY rm_detalle[i].j10_nomcli TO tit_cliente
			--#IF rm_aux[i] = 'PR' THEN
				--#DISPLAY "INVENTARIO" TO tit_area
			--#ELSE
				--#DISPLAY "TALLER"     TO tit_area
			--#END IF
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



FUNCTION ver_factura(i)
DEFINE i		SMALLINT
DEFINE expr		VARCHAR(60)

CASE rm_aux[i]
	WHEN 'PR'
		CALL fl_ver_transaccion_rep(vg_codcia, vg_codloc,
						rm_detalle[i].r25_cod_tran,
						rm_detalle[i].r25_num_tran)
	WHEN 'OT'
		LET expr = rm_detalle[i].r25_num_tran
		CALL fl_ejecuta_comando('TALLER', 'TA', 'talp308', expr, 1)
END CASE

END FUNCTION



FUNCTION detalle_aprobacion(i)
DEFINE i		SMALLINT
DEFINE numprev		LIKE rept023.r23_numprev

SELECT r23_numprev
	INTO numprev
	FROM rept023
	WHERE r23_compania  = vg_codcia
	  AND r23_localidad = vg_codloc
	  AND r23_cod_tran  = rm_detalle[i].r25_cod_tran
	  AND r23_num_tran  = rm_detalle[i].r25_num_tran
CALL fl_ejecuta_comando('REPUESTOS', 'RE', 'repp210', numprev, 1)

END FUNCTION



FUNCTION muestra_contadores_det(num_rows, max_rows)
DEFINE num_rows, max_rows	SMALLINT

DISPLAY BY NAME num_rows, max_rows

END FUNCTION



FUNCTION mostrar_botones()

DISPLAY "Código"	TO tit_col1
DISPLAY "Cliente"	TO tit_col2
DISPLAY "Fecha"		TO tit_col3
DISPLAY "TP"		TO tit_col4
DISPLAY "Número"	TO tit_col5
DISPLAY "Valor Apr."	TO tit_col6
DISPLAY "Usuario Ap."	TO tit_col7

END FUNCTION



FUNCTION borrar_detalle()
DEFINE i		SMALLINT

FOR i = 1 TO vm_num_det
	INITIALIZE rm_detalle[i].*, rm_aux[i] TO NULL
END FOR
FOR i = 1 TO fgl_scr_size('rm_detalle')
	CLEAR rm_detalle[i].*
END FOR
CLEAR num_rows, max_rows, total_cre, tit_cliente, tit_area

END FUNCTION



FUNCTION control_imprimir()
DEFINE comando		VARCHAR(100)
DEFINE i		SMALLINT

CALL fl_control_reportes() RETURNING comando
IF int_flag THEN
	RETURN
END IF
START REPORT reporte_aprobacion_credito TO PIPE comando
FOR i = 1 TO vm_num_det
	OUTPUT TO REPORT reporte_aprobacion_credito(i)
END FOR
FINISH REPORT reporte_aprobacion_credito

END FUNCTION



REPORT reporte_aprobacion_credito(i)
DEFINE i		SMALLINT
DEFINE r_j02		RECORD LIKE cajt002.*
DEFINE r_g01		RECORD LIKE gent001.*
DEFINE r_g50		RECORD LIKE gent050.*
DEFINE usuario		VARCHAR(19,15)
DEFINE modulo		VARCHAR(40)
DEFINE factura		VARCHAR(15)
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
	LET escape	= 27		# Iniciar sec. impresión
	LET act_comp	= 15		# Activar Comprimido.
	LET desact_comp	= 18		# Cancelar Comprimido.
	LET act_neg	= 71		# Activar negrita.
	LET des_neg	= 72		# Desactivar negrita.
	LET act_10cpi	= 80		# Comprimido 10 CPI.
	CALL fl_lee_modulo(vg_modulo) RETURNING r_g50.*
	LET modulo      = "MODULO: ", r_g50.g50_nombre[1, 19] CLIPPED
	LET usuario     = "USUARIO: ", vg_usuario
	CALL fl_justifica_titulo('D', usuario, 19) RETURNING usuario
	CALL fl_lee_compania(vg_codcia) RETURNING r_g01.*
	CALL fl_retorna_caja(vg_codcia, vg_codloc, vm_usua_caja)
		RETURNING r_j02.*
	print ASCII escape;
	print ASCII act_neg;
	print ASCII escape;
	print ASCII desact_comp;
	print ASCII escape;
	print ASCII act_10cpi;
	PRINT COLUMN 007, r_g01.g01_razonsocial,
  	      COLUMN 076, "PAGINA: ", PAGENO USING "&&&"
	SKIP 1 LINES
	PRINT COLUMN 001, modulo CLIPPED,
	      COLUMN 031, "LISTADO APROBACION CREDITO",
	      COLUMN 074, UPSHIFT(vg_proceso) CLIPPED
	PRINT COLUMN 031, "--------------------------"
	SKIP 1 LINES
	IF vm_usua_caja IS NOT NULL THEN
		PRINT COLUMN 018, "** USUARIO CAJA  : ",
			vm_usua_caja CLIPPED, " (",
			r_j02.j02_nombre_caja CLIPPED, ")"
	END IF
	PRINT COLUMN 018, "** FECHA INICIAL : ", vm_fecha_ini
							USING "dd-mm-yyyy"
	PRINT COLUMN 018, "** FECHA FINAL   : ", vm_fecha_fin
							USING "dd-mm-yyyy"
	SKIP 1 LINES
	PRINT COLUMN 001, "FECHA IMPRESION: ", TODAY USING "dd-mm-yyyy",
 		1 SPACES, TIME,
	      COLUMN 062, usuario
	PRINT "--------------------------------------------------------------------------------"
	PRINT COLUMN 001, "CODIGO",
	      COLUMN 009, "C L I E N T E S",
	      COLUMN 027, "FECHA CREDITO",
	      COLUMN 047, "TP",
	      COLUMN 050, "NUMERO",
	      COLUMN 059, "VALOR APRO.",
	      COLUMN 071, "USUARIO AP"
	PRINT "--------------------------------------------------------------------------------";
	print ASCII escape;
	print ASCII des_neg

ON EVERY ROW
	NEED 3 LINES
	LET factura = rm_detalle[i].r25_num_tran
	CALL fl_justifica_titulo('I', factura, 8) RETURNING factura
	PRINT COLUMN 001, rm_detalle[i].j10_codcli	USING "<<&&&&",
	      COLUMN 008, rm_detalle[i].j10_nomcli[1, 18] CLIPPED,
	      COLUMN 027, rm_detalle[i].j10_fecing,
	      COLUMN 047, rm_detalle[i].r25_cod_tran,
	      COLUMN 050, factura,
	      COLUMN 059, rm_detalle[i].r25_valor_cred	USING "####,##&.##",
	      COLUMN 071, rm_detalle[i].j10_usuario CLIPPED
	
ON LAST ROW
	NEED 2 LINES
	print ASCII escape;
	print ASCII act_neg;
	PRINT COLUMN 059, "-----------"
	PRINT COLUMN 048, "TOTAL ==>  ", total_cre USING "####,##&.##"
	print ASCII escape;
	print ASCII des_neg;
	print ASCII escape;
	print ASCII act_comp

END REPORT



FUNCTION llamar_visor_teclas()
DEFINE a		CHAR(1)

IF vg_gui = 0 THEN
	CALL fl_visor_teclas_caracter() RETURNING int_flag 
	LET a = fgl_getkey()
	CLOSE WINDOW w_tf
	LET int_flag = 0
END IF

END FUNCTION
