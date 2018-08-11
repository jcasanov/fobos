------------------------------------------------------------------------------
-- Titulo           : cajp300.4gl - Consulta transacciones procesadas por caja
-- Elaboracion      : 20-dic-2001
-- Autor            : NPC
-- Formato Ejecucion: fglrun cajp300 base módulo compañía localidad
-- Ultima Correccion: 28-05-2002
-- Motivo Correccion: (RCA) Linea 133 se le corrigió del SELECT
--		      el parámetro 'E' de Eliminado
------------------------------------------------------------------------------
GLOBALS '../../../PRODUCCION/LIBRERIAS/fuentes/globales.4gl'

DEFINE rm_g05		RECORD LIKE gent005.*
DEFINE rm_caj		RECORD LIKE cajt010.*
DEFINE vm_max_det       SMALLINT
DEFINE vm_num_det       SMALLINT
DEFINE vm_fecha_ini	DATE
DEFINE vm_fecha_fin	DATE
DEFINE vm_total		DECIMAL(14,2)
DEFINE rm_orden 	ARRAY[10] OF CHAR(4)
DEFINE vm_columna_1	SMALLINT
DEFINE vm_columna_2	SMALLINT
DEFINE vm_size_arr	INTEGER
DEFINE rm_det		ARRAY [32766] OF RECORD
				j10_fecha_pro	DATE,
				j10_nomcli	LIKE cajt010.j10_nomcli,
				j10_tipo_destino LIKE cajt010.j10_tipo_destino,
				j10_num_destino	LIKE cajt010.j10_num_destino,
				j10_referencia	LIKE cajt010.j10_referencia,
				j11_codigo_pago	LIKE cajt011.j11_codigo_pago,
				j11_valor	LIKE cajt011.j11_valor
			END RECORD
DEFINE rm_cajs		ARRAY[32766] OF RECORD
				j10_compania	LIKE cajt010.j10_compania,
				j10_localidad	LIKE cajt010.j10_localidad,
				j10_tipo_fuente	LIKE cajt010.j10_tipo_fuente,
				j10_num_fuente	LIKE cajt010.j10_num_fuente,
				j10_codcli	LIKE cajt010.j10_codcli
			END RECORD

MAIN

DEFER QUIT 
DEFER INTERRUPT
CLEAR SCREEN
LET vg_proceso = arg_val(0)
CALL startlog('../logs/' || vg_proceso CLIPPED || '.err')
--#CALL fgl_init4js()
CALL fl_marca_registrada_producto()
IF num_args() <> 4 THEN   -- Validar # parámetros correcto
	CALL fl_mostrar_mensaje('Número de parámetros incorrecto.','stop')
	EXIT PROGRAM
END IF
LET vg_base     = arg_val(1)
LET vg_modulo   = arg_val(2)
LET vg_codcia   = arg_val(3)
LET vg_codloc   = arg_val(4)
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
LET vm_max_det = 32766
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
    ATTRIBUTE(FORM LINE FIRST + 1, COMMENT LINE LAST, MENU LINE lin_menu,BORDER,
	      MESSAGE LINE LAST - 1)
IF vg_gui = 1 THEN
        OPEN FORM f_caj FROM '../forms/cajf300_1'
ELSE
        OPEN FORM f_caj FROM '../forms/cajf300_1c'
END IF
DISPLAY FORM f_caj

CALL muestra_contadores_det(0, 0)
CALL borrar_cabecera()
CALL borrar_detalle()
CALL mostrar_cabecera_forma()
CALL control_consulta()

END FUNCTION



FUNCTION control_consulta()
DEFINE i, j, col	SMALLINT
DEFINE query		CHAR(600)
DEFINE expr_sql01	VARCHAR(200)
DEFINE expr_sql02	VARCHAR(100)
DEFINE expr_sql03	CHAR(600)
DEFINE cuantos		SMALLINT
DEFINE tipo_comp	LIKE ctbt012.b12_tipo_comp
DEFINE num_comp		LIKE ctbt012.b12_num_comp
DEFINE r_j02		RECORD LIKE cajt002.*

LET vm_fecha_ini = vg_fecha
LET vm_fecha_fin = vg_fecha
CALL fl_lee_usuario(vg_usuario) RETURNING rm_g05.*
IF rm_g05.g05_tipo = 'UF' THEN
	INITIALIZE r_j02.* TO NULL
	SELECT * INTO r_j02.*
		FROM cajt002
		WHERE j02_compania  = vg_codcia
		  AND j02_localidad = vg_codloc
		  AND j02_usua_caja = rm_g05.g05_usuario
	IF r_j02.j02_usua_caja IS NULL THEN
		CALL fl_mostrar_mensaje('Usted no es un usuario de caja.', 'stop')
		RETURN
	END IF
	LET rm_caj.j10_codigo_caja = r_j02.j02_codigo_caja
	DISPLAY BY NAME r_j02.j02_nombre_caja
END IF
WHILE TRUE
	LET vm_num_det = 0
	CALL borrar_detalle()
	CALL muestra_contadores_det(0, vm_num_det)
	CALL lee_parametros() RETURNING expr_sql01, expr_sql02, expr_sql03
	IF int_flag = 2 THEN
		CONTINUE WHILE
	END IF
	IF int_flag THEN
		EXIT WHILE
	END IF
	CALL ejecuta_query_consulta(expr_sql01, expr_sql02, expr_sql03)
	FOR i = 1 TO 10
		LET rm_orden[i] = '' 
	END FOR
	LET rm_orden[1]  = 'DESC'
	LET vm_columna_1 = 1
	LET vm_columna_2 = 4
	LET col          = 1
	WHILE TRUE
		LET query = 'SELECT * FROM tmp_caj ',
			' ORDER BY ', vm_columna_1, ' ', rm_orden[vm_columna_1],
			       	', ', vm_columna_2, ' ', rm_orden[vm_columna_2]
		PREPARE deto FROM query
		DECLARE q_deto CURSOR FOR deto
		LET vm_num_det = 1
		FOREACH q_deto INTO rm_det[vm_num_det].*, rm_cajs[vm_num_det].*
			LET vm_num_det = vm_num_det + 1
			IF vm_num_det > vm_max_det THEN
				EXIT FOREACH
			END IF
		END FOREACH
		LET vm_num_det = vm_num_det - 1
		IF vm_num_det = 0 THEN
			DROP TABLE tmp_caj
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
				IF rm_det[i].j10_tipo_destino <> 'EC' THEN
					CALL ver_forma_pago(i)
					LET int_flag = 0
				END IF
			ON KEY(F6)
				LET i = arr_curr()
				LET j = scr_line()
				IF rm_det[i].j10_tipo_destino = 'FA' OR 
				   rm_det[i].j10_tipo_destino = 'PG' OR
				   rm_det[i].j10_tipo_destino = 'PR' OR
				   rm_det[i].j10_tipo_destino = 'PA' OR
				   rm_det[i].j10_tipo_destino = 'EC' THEN
					CALL fl_ver_comprobantes_emitidos_caja(
						rm_cajs[i].j10_tipo_fuente, 
						rm_cajs[i].j10_num_fuente, 
					        rm_det[i].j10_tipo_destino, 
					        rm_det[i].j10_num_destino, 
					        rm_cajs[i].j10_codcli)
					LET int_flag = 0
				END IF
			ON KEY(F7)
				LET i = arr_curr()
				LET j = scr_line()
				CALL imprime_comprobante(
					rm_cajs[i].j10_tipo_fuente, 
					rm_cajs[i].j10_num_fuente) 
				LET int_flag = 0
			ON KEY(F8)
				LET i = arr_curr()
				LET j = scr_line()
				CALL mostrar_comp_contable(
						rm_cajs[i].j10_tipo_fuente, 
						rm_cajs[i].j10_num_fuente, 
				        	rm_det[i].j10_tipo_destino, 
				        	rm_det[i].j10_num_destino 
					) RETURNING tipo_comp, num_comp
				IF tipo_comp IS NOT NULL AND cuantos = 1 THEN
					CALL contabilizacion(tipo_comp, 
							     num_comp)
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
			--#BEFORE DISPLAY
				--#CALL dialog.keysetlabel('ACCEPT','')
				--#CALL dialog.keysetlabel("F1","")
				--#CALL dialog.keysetlabel("CONTROL-W","")
			--#BEFORE ROW
				--#LET i = arr_curr()
				--#LET j = scr_line()
				--#CALL muestra_contadores_det(i, vm_num_det)
				--#IF rm_det[i].j10_tipo_destino = 'EC' THEN
					--#CALL dialog.keysetlabel("F5", "")
				--#ELSE
					--#CALL dialog.keysetlabel("F5", "Forma de Pago")
				--#END IF
				--#IF rm_det[i].j10_tipo_destino = 'FA' OR 
				   --#rm_det[i].j10_tipo_destino = 'PG' OR
				   --#rm_det[i].j10_tipo_destino = 'PR' OR
				   --#rm_det[i].j10_tipo_destino = 'PA' OR
				   --#rm_det[i].j10_tipo_destino = 'EC' THEN
					--#CALL dialog.keysetlabel("F6", "Comprobante")
				--#ELSE
					--#CALL dialog.keysetlabel("F6","")
				--#END IF
				--#CALL contar_comprobantes(
						--#rm_cajs[i].j10_tipo_fuente,
						--#rm_cajs[i].j10_num_fuente, 
						--#rm_det[i].j10_tipo_destino,
						--#rm_det[i].j10_num_destino
					--#) RETURNING cuantos
							
				--#IF cuantos > 0 THEN
					--#CALL dialog.keysetlabel('F8', 'Contabilización')
				--#ELSE
					--#CALL dialog.keysetlabel('F8', '')
				--#END IF
				--#DISPLAY rm_det[i].j10_nomcli TO nomcli
				--#DISPLAY rm_det[i].j10_referencia TO referencia
			--#AFTER DISPLAY 
				--#CONTINUE DISPLAY
		END DISPLAY
		IF int_flag = 1 THEN
			LET int_flag = 0
			DROP TABLE tmp_caj
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



FUNCTION ejecuta_query_consulta(expr_sql01, expr_sql02, expr_sql03)
DEFINE expr_sql01	VARCHAR(200)
DEFINE expr_sql02	VARCHAR(100)
DEFINE expr_sql03	CHAR(600)
DEFINE query		CHAR(7000)
DEFINE expr_caj		VARCHAR(100)
DEFINE expr_fec		VARCHAR(200)
DEFINE expr_sql		CHAR(500)
DEFINE con_union	SMALLINT
DEFINE lim, pos		SMALLINT

LET expr_caj = NULL
IF rm_caj.j10_codigo_caja IS NOT NULL THEN
	LET expr_caj = '  AND j10_codigo_caja     = ', rm_caj.j10_codigo_caja
END IF
LET expr_fec = '  AND DATE(j10_fecha_pro) BETWEEN "', vm_fecha_ini, '"',
					' AND "', vm_fecha_fin, '"'
LET expr_sql = NULL
IF expr_sql01 IS NOT NULL THEN
	LET expr_sql = '  AND ', expr_sql01 CLIPPED
END IF
LET con_union = 1
IF expr_sql02 <> ' 1=1' THEN
	LET lim = LENGTH(expr_sql02)
	LET pos = lim - 4
	IF expr_sql02[pos, lim] = "EC" THEN
		LET con_union = 0
	END IF
END IF
LET query = NULL
IF con_union THEN
	LET query = 'SELECT DATE(j10_fecha_pro) AS fec_pro, ',
			'j10_nomcli AS nomcli, ',
			'j10_tipo_destino AS tip_des, ',
			'j10_num_destino, ',
			'j10_referencia, ',
			'j11_codigo_pago, ',
			'j11_valor, ',
			'j10_compania AS cia, ',
			'j10_localidad AS loc, ',
			'j10_tipo_fuente AS tip_fue, ',
			'j10_num_fuente AS num_fue, ',
			'j10_codcli AS codcli ',
		'FROM cajt010, cajt011 ',
		'WHERE j10_compania         = ', vg_codcia,
		'  AND j10_localidad        = ', vg_codloc,
		'  AND j10_tipo_fuente     <> "EC" ',
		'  AND j10_estado           = "P" ',
		expr_caj CLIPPED,
		expr_fec CLIPPED,
		expr_sql CLIPPED,
		'  AND ', expr_sql02 CLIPPED,
		'  AND j11_compania         = j10_compania ',
		'  AND j11_localidad        = j10_localidad ',
		'  AND j11_tipo_fuente      = j10_tipo_fuente ',
		'  AND j11_num_fuente       = j10_num_fuente ',
		' UNION ALL'
END IF
LET query = query CLIPPED,
		' SELECT DATE(j10_fecha_pro) AS fec_pro, ',
			'j10_nomcli AS nomcli, ',
			'j10_tipo_destino AS tip_des, ',
			'j10_num_destino, ',
			'j10_referencia, ',
			'j11_codigo_pago, ',
			'SUM(j11_valor * (-1)) AS j11_valor, ',
			'j10_compania AS cia, ',
			'j10_localidad AS loc, ',
			'j10_tipo_fuente AS tip_fue, ',
			'j10_num_fuente AS num_fue, ',
			'j10_codcli AS codcli ',
		'FROM cajt010, cajt011 ',
		'WHERE j10_compania         = ', vg_codcia,
		'  AND j10_localidad        = ', vg_codloc,
		'  AND j10_tipo_fuente      = "EC" ',
		'  AND j10_estado           = "P" ',
		'  AND j10_valor            > 0 ',
		expr_caj CLIPPED,
		expr_fec CLIPPED,
		expr_sql CLIPPED,
		'  AND ', expr_sql02 CLIPPED,
		'  AND j11_compania         = j10_compania ',
		'  AND j11_localidad        = j10_localidad ',
		'  AND j11_num_egreso       = j10_num_fuente ',
		' GROUP BY 1, 2, 3, 4, 5, 6, 8, 9, 10, 11, 12 ',
		' UNION ALL',
		' SELECT DATE(j10_fecha_pro) AS fec_pro, ',
			'j10_nomcli AS nomcli, ',
			'j10_tipo_destino AS tip_des, ',
			'j10_num_destino, ',
			'j10_referencia, ',
			'CASE WHEN (j10_tipo_fuente = "EC" AND j10_valor > 0) ',
				'THEN "EF" ',
			     'WHEN (j10_tipo_fuente = "EC" AND j10_valor = 0) ',
				'THEN ',
				'(SELECT UNIQUE j11_codigo_pago ',
				'FROM cajt011 ',
				'WHERE j11_compania   = j10_compania ',
				'  AND j11_localidad  = j10_localidad ',
				'  AND j11_num_egreso = j10_num_fuente) ',
			'END AS j11_codigo_pago, ',
			'CASE WHEN (j10_tipo_fuente = "EC" AND j10_valor > 0) ',
				'THEN j10_valor * (-1) ',
			     'WHEN (j10_tipo_fuente = "EC" AND j10_valor = 0) ',
				'THEN ',
				'NVL((SELECT SUM(j11_valor * (-1)) ',
				'FROM cajt011 ',
				'WHERE j11_compania   = j10_compania ',
				'  AND j11_localidad  = j10_localidad ',
				'  AND j11_num_egreso = j10_num_fuente), 0) ',
			'END AS j11_valor, ',
			'j10_compania AS cia, ',
			'j10_localidad AS loc, ',
			'j10_tipo_fuente AS tip_fue, ',
			'j10_num_fuente AS num_fue, ',
			'j10_codcli AS codcli ',
		'FROM cajt010 ',
		'WHERE j10_compania        = ', vg_codcia,
		'  AND j10_localidad       = ', vg_codloc,
		'  AND j10_estado          = "P" ',
		expr_caj CLIPPED,
		expr_fec CLIPPED,
		expr_sql CLIPPED,
		'  AND ', expr_sql02 CLIPPED,
		'  AND NOT EXISTS ',
			'(SELECT 1 FROM cajt011 ',
				'WHERE j11_compania    = j10_compania ',
				'  AND j11_localidad   = j10_localidad ',
				'  AND j11_tipo_fuente = j10_tipo_fuente ',
				'  AND j11_num_fuente  = j10_num_fuente) ',
		' INTO TEMP t1 '
PREPARE exec_tmp FROM query
EXECUTE exec_tmp
LET query = 'SELECT fec_pro, nomcli, tip_des, ',
			'CAST(j10_num_destino AS INTEGER) AS num_des, ',
			'j10_referencia AS referencia, ',
			'j11_codigo_pago AS cod_pag, j11_valor AS val_trn, ',
			'cia, loc, tip_fue, num_fue, codcli ',
		'FROM t1 ',
		'WHERE ', expr_sql03 CLIPPED,
		' INTO TEMP tmp_caj '
PREPARE exec_tmp02 FROM query
EXECUTE exec_tmp02
DROP TABLE t1

END FUNCTION



FUNCTION lee_parametros()
DEFINE r_caj		RECORD LIKE cajt002.*
DEFINE cod_aux		LIKE cajt002.j02_codigo_caja
DEFINE nom_aux		LIKE cajt002.j02_nombre_caja
DEFINE fecha_ini	DATE
DEFINE fecha_fin	DATE
DEFINE expr_sql01	VARCHAR(200)
DEFINE expr_sql02	VARCHAR(100)
DEFINE expr_sql03	CHAR(600)

OPTIONS INPUT NO WRAP
INITIALIZE cod_aux, expr_sql01, expr_sql02, expr_sql03 TO NULL
LET int_flag = 0
INPUT BY NAME rm_caj.j10_codigo_caja, vm_fecha_ini, vm_fecha_fin
	WITHOUT DEFAULTS
	ON KEY(INTERRUPT)
		LET int_flag = 1
		EXIT INPUT
        ON KEY(F1,CONTROL-W)
		CALL llamar_visor_teclas()
	ON KEY(F2)
		IF rm_g05.g05_tipo = 'UF' THEN
			CONTINUE INPUT
		END IF
		IF INFIELD(j10_codigo_caja) THEN
			CALL fl_ayuda_cajas(vg_codcia, vg_codloc)
				RETURNING cod_aux, nom_aux
			OPTIONS INPUT NO WRAP
			LET int_flag = 0
			IF cod_aux IS NOT NULL THEN
				LET rm_caj.j10_codigo_caja = cod_aux
				DISPLAY BY NAME rm_caj.j10_codigo_caja 
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
	BEFORE FIELD j10_codigo_caja
		{--
		IF rm_g05.g05_tipo = 'UF' THEN
			LET r_caj.j02_codigo_caja = rm_caj.j10_codigo_caja
		END IF
		--}
	AFTER FIELD j10_codigo_caja
		{--
		IF rm_g05.g05_tipo = 'UF' THEN
			LET rm_caj.j10_codigo_caja = r_caj.j02_codigo_caja
			CALL fl_lee_codigo_caja_caja(vg_codcia, vg_codloc,
							rm_caj.j10_codigo_caja)
                        	RETURNING r_caj.*
			DISPLAY BY NAME rm_caj.j10_codigo_caja,
					r_caj.j02_nombre_caja
			CONTINUE INPUT
		END IF
		--}
		IF rm_caj.j10_codigo_caja IS NOT NULL THEN
			CALL fl_lee_codigo_caja_caja(vg_codcia, vg_codloc,
							rm_caj.j10_codigo_caja)
                        	RETURNING r_caj.*
			IF r_caj.j02_compania IS NULL THEN
				CALL fl_mostrar_mensaje('Código de Caja no existe.','exclamation')
				NEXT FIELD j10_codigo_caja
			END IF
			DISPLAY BY NAME r_caj.j02_nombre_caja
		ELSE
			CLEAR j02_nombre_caja
		END IF
	AFTER FIELD vm_fecha_ini 
		IF vm_fecha_ini IS NOT NULL THEN
			IF vm_fecha_ini > vg_fecha THEN
				CALL fl_mostrar_mensaje('La fecha de inicio no puede ser mayor a la de hoy.','exclamation')
				NEXT FIELD vm_fecha_ini
			END IF
		ELSE
			LET vm_fecha_ini = fecha_ini
			DISPLAY BY NAME vm_fecha_ini
		END IF
	AFTER FIELD vm_fecha_fin 
		IF vm_fecha_fin IS NOT NULL THEN
			IF vm_fecha_fin > vg_fecha THEN
				CALL fl_mostrar_mensaje('La fecha de término no puede ser mayor a la de hoy.','exclamation')
				NEXT FIELD vm_fecha_fin
			END IF
		ELSE
			LET vm_fecha_fin = fecha_fin
			DISPLAY BY NAME vm_fecha_fin
		END IF
	AFTER INPUT
		IF vm_fecha_ini > vm_fecha_fin THEN
			CALL fl_mostrar_mensaje('Fecha inicial debe ser menor a fecha final.','exclamation')
			NEXT FIELD vm_fecha_ini
		END IF
END INPUT
IF int_flag THEN
	RETURN expr_sql01, expr_sql02, expr_sql03
END IF
CONSTRUCT BY NAME expr_sql01 ON j10_nomcli
	ON KEY(INTERRUPT)
		LET int_flag = 2
		EXIT CONSTRUCT
        ON KEY(F1,CONTROL-W)
		CALL llamar_visor_teclas()
	BEFORE CONSTRUCT
		--#CALL dialog.keysetlabel("F1","")
		--#CALL dialog.keysetlabel("CONTROL-W","")
END CONSTRUCT
IF int_flag THEN
	RETURN expr_sql01, expr_sql02, expr_sql03
END IF
OPTIONS INPUT NO WRAP
CONSTRUCT BY NAME expr_sql02 ON j10_tipo_destino
	ON KEY(INTERRUPT)
		LET int_flag = 2
		EXIT CONSTRUCT
        ON KEY(F1,CONTROL-W)
		CALL llamar_visor_teclas()
	BEFORE CONSTRUCT
		--#CALL dialog.keysetlabel("F1","")
		--#CALL dialog.keysetlabel("CONTROL-W","")
END CONSTRUCT
IF int_flag THEN
	RETURN expr_sql01, expr_sql02, expr_sql03
END IF
OPTIONS INPUT WRAP
CONSTRUCT BY NAME expr_sql03 ON j10_num_destino, j10_referencia,
				j11_codigo_pago, j11_valor
	ON KEY(INTERRUPT)
		LET int_flag = 2
		EXIT CONSTRUCT
        ON KEY(F1,CONTROL-W)
		CALL llamar_visor_teclas()
	BEFORE CONSTRUCT
		--#CALL dialog.keysetlabel("F1","")
		--#CALL dialog.keysetlabel("CONTROL-W","")
END CONSTRUCT
RETURN expr_sql01, expr_sql02, expr_sql03

END FUNCTION



FUNCTION borrar_cabecera()

CLEAR vm_fecha_ini, vm_fecha_fin, j10_codigo_caja, j02_nombre_caja
INITIALIZE rm_caj.*, vm_fecha_ini, vm_fecha_fin TO NULL

END FUNCTION



FUNCTION borrar_detalle()
DEFINE i  		SMALLINT

CALL muestra_contadores_det(0, 0)
CALL retorna_arreglo()
FOR i = 1 TO vm_size_arr   
        INITIALIZE rm_det[i].*, rm_cajs[i].* TO NULL
        CLEAR rm_det[i].*
END FOR
CLEAR nomcli, referencia, vm_total

END FUNCTION



FUNCTION muestra_contadores_det(num_row, max_row)
DEFINE num_row, max_row	SMALLINT

DISPLAY BY NAME num_row, max_row

END FUNCTION


 
FUNCTION mostrar_cabecera_forma()

--#DISPLAY 'Fecha'              TO tit_col1
--#DISPLAY 'Cliente/Descripción' TO tit_col2
--#DISPLAY 'CT'                 TO tit_col3
--#DISPLAY 'Número'             TO tit_col4
--#DISPLAY 'Referencia'		TO tit_col5
--#DISPLAY 'FP'                 TO tit_col6
--#DISPLAY 'Valor'              TO tit_col7

END FUNCTION



FUNCTION ver_forma_pago(i)
DEFINE i		SMALLINT
DEFINE prog		CHAR(10)
DEFINE run_prog		CHAR(10)
DEFINE nuevoprog     CHAR(400)

IF rm_det[i].j10_tipo_destino <> 'OI' THEN
	LET prog = 'cajp203'
ELSE
	LET prog = 'cajp206'
END IF
LET run_prog = '; fglrun '
IF vg_gui = 0 THEN
	LET run_prog = '; fglgo '
END IF
LET nuevoprog = 'cd ..', vg_separador, '..', vg_separador, 'CAJA',
	vg_separador, 'fuentes', vg_separador, run_prog, prog, ' ', vg_base,
	' ', vg_modulo, ' ', rm_cajs[i].j10_compania, ' ',
	rm_cajs[i].j10_localidad, ' ', '"', rm_cajs[i].j10_tipo_fuente, '"',
	' ', rm_cajs[i].j10_num_fuente
RUN nuevoprog

END FUNCTION



FUNCTION imprime_comprobante(tipo_fuente, num_fuente)
DEFINE comando          VARCHAR(250)
DEFINE tipo_fuente	LIKE cajt010.j10_tipo_fuente
DEFINE num_fuente	LIKE cajt010.j10_num_fuente
DEFINE r_r23            RECORD LIKE rept023.*   -- Preventa Repuestos
DEFINE r_v26            RECORD LIKE veht026.*   -- Preventa Vehiculos
DEFINE r_t23            RECORD LIKE talt023.*   -- Orden de Trabajo
DEFINE r_z24            RECORD LIKE cxct024.*   -- Solicitud Cobro Clientes
DEFINE run_prog		CHAR(10)

INITIALIZE comando TO NULL
LET run_prog = '; fglrun '
IF vg_gui = 0 THEN
	LET run_prog = '; fglgo '
END IF
CASE tipo_fuente
        WHEN 'PV'
		CALL fl_mostrar_mensaje('Opcion no habilitada.','exclamation')

        WHEN 'PR'
                CALL fl_lee_preventa_rep(vg_codcia, vg_codloc,
                        num_fuente) RETURNING r_r23.*

                LET comando = 'cd ..', vg_separador, '..', vg_separador,
                              'REPUESTOS', vg_separador, 'fuentes',
                              vg_separador, run_prog, 'repp410 ', vg_base, ' ',
                              'RE', vg_codcia, ' ', vg_codloc, ' "',
                              r_r23.r23_cod_tran, '" ', r_r23.r23_num_tran
        WHEN 'OT'
                CALL fl_lee_orden_trabajo(vg_codcia, vg_codloc,
                        num_fuente) RETURNING r_t23.*

                LET comando = 'cd ..', vg_separador, '..', vg_separador,
                              'TALLER', vg_separador, 'fuentes',
                              vg_separador, run_prog, 'talp403 ', vg_base, ' ',
                              'TA', ' ', vg_codcia, ' ', vg_codloc, ' ',
				r_t23.t23_num_factura
        WHEN 'SC'
                CALL fl_lee_solicitud_cobro_cxc(vg_codcia, vg_codloc,
                                                num_fuente)
                                                RETURNING r_z24.*
                IF r_z24.z24_tipo = 'A' THEN
                        LET comando = 'cd ..', vg_separador, '..', vg_separador,
                                      'CAJA', vg_separador, 'fuentes',
                                      vg_separador, run_prog, 'cajp401 ',
                                      vg_base, ' ', 'CG', vg_codcia, ' ',
                                      vg_codloc, ' ', r_z24.z24_numero_sol
                ELSE
                        LET comando = 'cd ..', vg_separador, '..', vg_separador,
                                      'CAJA', vg_separador, 'fuentes',
                                      vg_separador, run_prog, 'cajp400 ',
                                      vg_base, ' ', 'CG', vg_codcia, ' ',
                                      vg_codloc, ' ', r_z24.z24_numero_sol
                END IF
        WHEN 'OI'
        	LET comando = 'cd ..', vg_separador, '..', vg_separador,
                              'CAJA', vg_separador, 'fuentes',
                              vg_separador, run_prog, 'cajp403 ',
                              vg_base, ' ', 'CG', vg_codcia, ' ',
                              vg_codloc, ' ', num_fuente             
        WHEN 'EC'
        	LET comando = 'cd ..', vg_separador, '..', vg_separador,
                              'CAJA', vg_separador, 'fuentes',
                              vg_separador, run_prog, 'cajp404 ',
                              vg_base, ' ', 'CG', vg_codcia, ' ',
                              vg_codloc, ' ', num_fuente             
END CASE

IF comando IS NOT NULL THEN
        RUN comando
	IF tipo_fuente = 'OT' THEN
		LET comando = 'cd ..', vg_separador, '..', vg_separador,
 			      'TALLER', vg_separador, 'fuentes', 
			      vg_separador, run_prog, 'talp408 ', vg_base, ' ',
			      'TA', ' ', vg_codcia, ' ', vg_codloc, ' ',
			      r_t23.t23_orden
		RUN comando
	END IF 
END IF

END FUNCTION



FUNCTION contabilizacion(tipo_comp, num_comp)
DEFINE comando 		VARCHAR(255)
DEFINE tipo_comp	LIKE ctbt012.b12_tipo_comp
DEFINE num_comp		LIKE ctbt012.b12_num_comp
DEFINE run_prog		CHAR(10)

LET run_prog = '; fglrun '
IF vg_gui = 0 THEN
	LET run_prog = '; fglgo '
END IF
LET comando = 'cd ..', vg_separador, '..', vg_separador,
	      'CONTABILIDAD', vg_separador, 'fuentes', 
	      vg_separador, run_prog, 'ctbp201 ', vg_base CLIPPED, ' ',
	      'CB ', vg_codcia, ' ', tipo_comp, ' ', num_comp

RUN comando

END FUNCTION



FUNCTION contar_comprobantes(tipo_fuente, num_fuente, tipo_destino, num_destino)

DEFINE tipo_fuente	LIKE cajt010.j10_tipo_fuente
DEFINE num_fuente	LIKE cajt010.j10_num_fuente
DEFINE tipo_destino	LIKE cajt010.j10_tipo_destino
DEFINE num_destino	LIKE cajt010.j10_num_destino
DEFINE cuantos		SMALLINT

DEFINE r_j10		RECORD LIKE cajt010.*

LET cuantos = 0
CASE tipo_fuente
	WHEN 'PV'
		SELECT COUNT(*) INTO cuantos FROM veht050 
			WHERE v50_compania  = vg_codcia
			  AND v50_localidad = vg_codloc
			  AND v50_cod_tran  = tipo_destino
			  AND v50_num_tran  = num_destino
	WHEN 'PR'
		SELECT COUNT(*) INTO cuantos FROM rept040 
			WHERE r40_compania  = vg_codcia
			  AND r40_localidad = vg_codloc
			  AND r40_cod_tran  = tipo_destino
			  AND r40_num_tran  = num_destino
	WHEN 'SC'
		CALL fl_lee_cabecera_caja(vg_codcia, vg_codloc, tipo_fuente, 
					  num_fuente) RETURNING r_j10.*
		SELECT COUNT(*) INTO cuantos FROM cxct040 
			WHERE z40_compania  = vg_codcia
			  AND z40_localidad = vg_codloc
			  AND z40_codcli    = r_j10.j10_codcli 
			  AND z40_tipo_doc  = tipo_destino
			  AND z40_num_doc   = num_destino
	WHEN 'OT'
		SELECT COUNT(*) INTO cuantos FROM talt050
			WHERE t50_compania  = vg_codcia
			  AND t50_localidad = vg_codloc
			  AND t50_orden     = num_fuente
			  AND t50_factura   = num_destino
	WHEN 'EC'
		SELECT COUNT(*) INTO cuantos FROM cajt010
			WHERE j10_compania  = vg_codcia
			  AND j10_localidad = vg_codloc
			  AND j10_tipo_destino = tipo_destino
			  AND j10_num_destino  = num_destino 
	WHEN 'OI'
		SELECT COUNT(*) INTO cuantos FROM cajt010
			WHERE j10_compania  = vg_codcia
			  AND j10_localidad = vg_codloc
			  AND j10_tipo_destino = tipo_destino
			  AND j10_num_destino  = num_destino 
END CASE 

RETURN cuantos

END FUNCTION



FUNCTION mostrar_comp_contable(tipo_fuente, num_fuente, tipo_destino, 
			       num_destino)
DEFINE tipo_fuente	LIKE cajt010.j10_tipo_fuente
DEFINE num_fuente	LIKE cajt010.j10_num_fuente
DEFINE tipo_destino	LIKE cajt010.j10_tipo_destino
DEFINE num_destino	LIKE cajt010.j10_num_destino
DEFINE r_det 		ARRAY[50] OF RECORD
				tipo_comp	LIKE ctbt012.b12_tipo_comp,
				num_comp	LIKE ctbt012.b12_num_comp,
				fecha		LIKE ctbt012.b12_fec_proceso,
				subtipo		LIKE ctbt004.b04_nombre
			END RECORD
DEFINE r_j10		RECORD LIKE cajt010.*
DEFINE query 		CHAR(800)
DEFINE i, max_rows	SMALLINT
DEFINE lin_menu		SMALLINT
DEFINE row_ini  	SMALLINT
DEFINE num_rows 	SMALLINT
DEFINE num_cols 	SMALLINT

LET max_rows = 50
INITIALIZE query TO NULL
CASE tipo_fuente
	WHEN 'PR'
		LET query = 'SELECT r40_tipo_comp, r40_num_comp, ',
				'   b12_fec_proceso, b04_nombre ',
			    '	FROM rept040, ctbt012, OUTER ctbt004 ',
			    '	WHERE r40_compania  = ', vg_codcia,
			    '     AND r40_localidad = ', vg_codloc, 
			    '     AND r40_cod_tran  = "', tipo_destino, '"',
			    '     AND r40_num_tran  = "', num_destino, '"',
		  	    '     AND b12_compania  = r40_compania ',
		            '     AND b12_tipo_comp = r40_tipo_comp ',
		            '     AND b12_num_comp  = r40_num_comp ',
		            '     AND b04_compania  = b12_compania ',
		            '     AND b04_subtipo   = b12_subtipo '
	WHEN 'PV'
		LET query = 'SELECT v50_tipo_comp, v50_num_comp, ',
				'   b12_fec_proceso, b04_nombre ',
			    '	FROM veht050, ctbt012, OUTER ctbt004 ',
			    '	WHERE v50_compania  = ', vg_codcia,
			    '     AND v50_localidad = ', vg_codloc, 
			    '     AND v50_cod_tran  = "', tipo_destino, '"',
			    '     AND v50_num_tran  = "', num_destino, '"',
		  	    '     AND b12_compania  = v50_compania ',
		            '     AND b12_tipo_comp = v50_tipo_comp ',
		            '     AND b12_num_comp  = v50_num_comp ',
		            '     AND b04_compania  = b12_compania ',
		            '     AND b04_subtipo   = b12_subtipo '
	WHEN 'OT'
		LET query = 'SELECT t50_tipo_comp, t50_num_comp, ',
				'   b12_fec_proceso, b04_nombre ',
			    '	FROM talt050, ctbt012, OUTER ctbt004 ',
			    '	WHERE t50_compania  = ', vg_codcia,
			    '     AND t50_localidad = ', vg_codloc, 
			    '     AND t50_orden     = "', num_fuente, '"',
			    '     AND t50_factura   = "', num_destino, '"',
		  	    '     AND b12_compania  = t50_compania ',
		            '     AND b12_tipo_comp = t50_tipo_comp ',
		            '     AND b12_num_comp  = t50_num_comp ',
		            '     AND b04_compania  = b12_compania ',
		            '     AND b04_subtipo   = b12_subtipo '
	WHEN 'SC'
		CALL fl_lee_cabecera_caja(vg_codcia, vg_codloc, tipo_fuente, 
					  num_fuente) RETURNING r_j10.*
		LET query = 'SELECT z40_tipo_comp, z40_num_comp, ',
				'   b12_fec_proceso, b04_nombre ',
			    '	FROM cxct040, ctbt012, OUTER ctbt004 ',
			    '	WHERE z40_compania  = ', vg_codcia,
			    '	  AND z40_localidad = ', vg_codloc,
			    '     AND z40_codcli    = ', r_j10.j10_codcli,
			    '     AND z40_tipo_doc  = "', tipo_destino, '"',
			    '     AND z40_num_doc   = "', num_destino,  '"',
		  	    '     AND b12_compania  = z40_compania ',
		            '     AND b12_tipo_comp = z40_tipo_comp ',
		            '     AND b12_num_comp  = z40_num_comp ',
		            '     AND b04_compania  = b12_compania ',
		            '     AND b04_subtipo   = b12_subtipo '
	WHEN 'EC'
		LET query = 'SELECT j10_tip_contable, j10_num_contable, ',
				'   b12_fec_proceso, b04_nombre ',
			    '	FROM cajt010, ctbt012, OUTER ctbt004 ',
			    ' 	WHERE j10_compania     = ', vg_codcia,
			    '	  AND j10_localidad    = ', vg_codloc,
			    '	  AND j10_tipo_destino = "', tipo_destino, '"',
			    '     AND j10_num_destino  = "', num_destino,  '"',
		  	    '     AND b12_compania     = j10_compania ',
		            '     AND b12_tipo_comp    = j10_tip_contable ',
		            '     AND b12_num_comp     = j10_num_contable ',
		            '     AND b04_compania     = b12_compania ',
		            '     AND b04_subtipo      = b12_subtipo '
	WHEN 'OI'
		LET query = 'SELECT j10_tip_contable, j10_num_contable, ',
				'   b12_fec_proceso, b04_nombre ',
			    '	FROM cajt010, ctbt012, OUTER ctbt004 ',
			    ' 	WHERE j10_compania  = ', vg_codcia,
			    '	  AND j10_localidad = ', vg_codloc,
			    '	  AND j10_tipo_destino = "', tipo_destino, '"',
			    '     AND j10_num_destino  = "', num_destino,  '"',
		  	    '     AND b12_compania  = j10_compania ',
		            '     AND b12_tipo_comp = j10_tip_contable ',
		            '     AND b12_num_comp  = j10_num_contable ',
		            '     AND b04_compania  = b12_compania ',
		            '     AND b04_subtipo   = b12_subtipo '
END CASE

PREPARE stmnt1 FROM query
DECLARE q_cursor1 CURSOR FOR stmnt1 

LET i = 1
FOREACH q_cursor1 INTO r_det[i].*
	LET i = i + 1
	IF i > max_rows THEN
		EXIT FOREACH
	END IF
END FOREACH

LET i = i - 1
IF i = 1 THEN
	RETURN r_det[1].tipo_comp, r_det[1].num_comp
END IF

IF vg_gui = 0 THEN
	LET num_rows = 12
END IF
LET lin_menu = 0
LET row_ini  = 10
LET num_rows = 9
LET num_cols = 60
IF vg_gui = 0 THEN
	LET lin_menu = 1
	LET row_ini  = 9
	LET num_rows = 11
	LET num_cols = 61
END IF
OPEN WINDOW w_300_2 AT row_ini, 10 WITH num_rows ROWS, num_cols COLUMNS
    ATTRIBUTE(FORM LINE FIRST, COMMENT LINE LAST, MENU LINE lin_menu,BORDER,
	      MESSAGE LINE LAST - 1)
IF vg_gui = 1 THEN
        OPEN FORM f_302_2 FROM '../forms/cajf300_2'
ELSE
        OPEN FORM f_302_2 FROM '../forms/cajf300_2c'
END IF
DISPLAY FORM f_302_2

--#DISPLAY 'Comprobante' TO bt_tipo_comp
--#DISPLAY 'Fecha'       TO bt_fecha    
--#DISPLAY 'Subtipo'     TO bt_subtipo  

IF i = 0 THEN
	CALL fl_mensaje_consulta_sin_registros()
	CLOSE WINDOW w_300_2
	INITIALIZE r_det[1].* TO NULL
	RETURN r_det[1].tipo_comp, r_det[1].num_comp
END IF

CALL set_count(i)
DISPLAY ARRAY r_det TO r_det.*
	ON KEY(INTERRUPT)
		EXIT DISPLAY
       	ON KEY(F1,CONTROL-W)
		CALL control_visor_teclas_caracter_2() 
	ON KEY(F5)
		LET i = arr_curr()
		CALL contabilizacion(r_det[i].tipo_comp, r_det[i].num_comp)	
	--#BEFORE DISPLAY
		--#CALL dialog.keysetlabel('ACCEPT', '')
		--#CALL dialog.keysetlabel("F1","")
		--#CALL dialog.keysetlabel("CONTROL-W","")
	--#BEFORE ROW
		--#LET i = arr_curr()
	--#AFTER DISPLAY
		--#CONTINUE DISPLAY
END DISPLAY

CLOSE WINDOW w_300_2
RETURN r_det[1].tipo_comp, r_det[1].num_comp

END FUNCTION


FUNCTION retorna_arreglo()

--#LET vm_size_arr = fgl_scr_size('rm_det')
IF vg_gui = 0 THEN
        LET vm_size_arr = 11
END IF

END FUNCTION



FUNCTION sacar_total()
DEFINE i		SMALLINT

LET vm_total = 0
FOR i = 1 TO vm_num_det
	IF rm_det[i].j11_valor IS NOT NULL THEN
		LET vm_total = vm_total + rm_det[i].j11_valor
	END IF
END FOR
DISPLAY BY NAME vm_total

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
DISPLAY '<F5>      Ver Forma de Pago'        AT a,2
DISPLAY  'F5' AT a,3 ATTRIBUTE(REVERSE)
LET a = a + 1
DISPLAY '<F6>      Comprobante Emitido por Caja' AT a,2
DISPLAY  'F6' AT a,3 ATTRIBUTE(REVERSE)
LET a = a + 1
DISPLAY '<F7>      Imprime Comprobante'      AT a,2
DISPLAY  'F7' AT a,3 ATTRIBUTE(REVERSE)
LET a = a + 1
DISPLAY '<F8>      Contabilización'          AT a,2
DISPLAY  'F8' AT a,3 ATTRIBUTE(REVERSE)
LET a = fgl_getkey()
CLOSE WINDOW w_tf

END FUNCTION



FUNCTION control_visor_teclas_caracter_2() 
DEFINE a, fila		INTEGER

CALL fl_visor_teclas_caracter() RETURNING fila
LET a = fila + 2
DISPLAY 'Teclas exclusivas de este proceso:' AT a,2 ATTRIBUTE(REVERSE)	
LET a = a + 1
DISPLAY '<F5>      Ver Comprobante'          AT a,2
DISPLAY  'F5' AT a,3 ATTRIBUTE(REVERSE)
LET a = fgl_getkey()
CLOSE WINDOW w_tf

END FUNCTION
