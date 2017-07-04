--------------------------------------------------------------------------------
-- Titulo           : cajp211.4gl - Modificacion Retenciones de Clientes
-- Elaboracion      : 28-feb-2008
-- Autor            : NPC
-- Formato Ejecucion: fglrun cajp211 base modulo compañía localidad
-- Ultima Correccion: 
-- Motivo Correccion: 
--------------------------------------------------------------------------------
GLOBALS '../../../PRODUCCION/LIBRERIAS/fuentes/globales.4gl'

DEFINE rm_orden 	ARRAY[10] OF CHAR(4)
DEFINE vm_columna_1	SMALLINT
DEFINE vm_columna_2	SMALLINT
DEFINE vm_size_arr	INTEGER
DEFINE rm_par 		RECORD
				fecha_ini	DATE,
				fecha_fin	DATE,
				tipo_fuente	LIKE cajt010.j10_tipo_fuente,
				num_destino	LIKE cajt010.j10_num_destino,
				num_sri		LIKE rept038.r38_num_sri,
				codcli		LIKE cxct001.z01_codcli,
				nomcli		LIKE cxct001.z01_nomcli
			END RECORD
DEFINE rm_detalle	ARRAY[20000] OF RECORD
				fecha		DATE,
				j10_num_destino	LIKE cajt010.j10_num_destino, 
				j10_nomcli	LIKE cajt010.j10_nomcli, 
				j11_codigo_pago	LIKE cajt011.j11_codigo_pago, 
				j11_num_ch_aut	LIKE cajt011.j11_num_ch_aut, 
				j11_valor	LIKE cajt011.j11_valor
			END RECORD
DEFINE rm_adi		ARRAY[20000] OF RECORD
				j10_codcli	LIKE cajt010.j10_codcli,
				j10_num_fuente	LIKE cajt010.j10_num_fuente,
				j10_tipo_fuente	LIKE cajt010.j10_tipo_fuente,
				j10_tipo_destino LIKE cajt010.j10_tipo_destino,
				j11_secuencia	LIKE cajt011.j11_secuencia
			END RECORD
DEFINE vm_cod_tran	LIKE rept019.r19_cod_tran
DEFINE vm_max_rows	SMALLINT
DEFINE vm_num_rows	SMALLINT
DEFINE rm_j10		RECORD LIKE cajt010.*
DEFINE rm_j14		RECORD LIKE cajt014.*
DEFINE rm_detret	ARRAY[50] OF RECORD
				j14_tipo_ret	LIKE cajt014.j14_tipo_ret,
				j14_porc_ret	LIKE cajt014.j14_porc_ret,
				j14_codigo_sri	LIKE cajt014.j14_codigo_sri,
				c03_concepto_ret LIKE ordt003.c03_concepto_ret,
				j14_base_imp	LIKE cajt014.j14_base_imp,
				j14_valor_ret	LIKE cajt014.j14_valor_ret
			END RECORD
DEFINE fec_ini_por	ARRAY[50] OF LIKE cajt014.j14_fec_ini_porc
DEFINE vm_num_ret	SMALLINT
DEFINE vm_max_ret	SMALLINT
DEFINE tot_base_imp	DECIMAL(12,2)
DEFINE tot_valor_ret	DECIMAL(12,2)



MAIN
	
DEFER QUIT
DEFER INTERRUPT
CLEAR SCREEN
CALL startlog('../logs/cajp211.err')
--#CALL fgl_init4js()
CALL fl_marca_registrada_producto()
IF num_args() <> 4 THEN          -- Validar # parámetros correcto
	CALL fl_mostrar_mensaje('Número de parámetros incorrecto.','stop')
	EXIT PROGRAM
END IF
LET vg_base    = arg_val(1)
LET vg_modulo  = arg_val(2)
LET vg_codcia  = arg_val(3)
LET vg_codloc  = arg_val(4)
LET vg_proceso = 'cajp211'
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
CREATE TEMP TABLE tmp_ret
	(
		cod_pago		CHAR(2),
		num_ret_sri		CHAR(16),
		autorizacion		VARCHAR(15,10),
		fecha_emi		DATE,
		tipo_ret		CHAR(1),
		porc_ret		DECIMAL(5,2),
		codigo_sri		CHAR(6),
		concepto_ret		VARCHAR(200,100),
		base_imp		DECIMAL(12,2),
		valor_ret		DECIMAL(12,2),
		fec_ini_porc		DATE,
		num_fac_sri		CHAR(16)
	)
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
OPEN WINDOW w_cajf211_1 AT row_ini, 02 WITH num_rows ROWS, num_cols COLUMNS
	ATTRIBUTE(FORM LINE FIRST, COMMENT LINE LAST, MENU LINE lin_menu,
		  BORDER, MESSAGE LINE LAST) 
IF vg_gui = 1 THEN
	OPEN FORM f_cajp211_1 FROM '../forms/cajf211_1'
ELSE
	OPEN FORM f_cajp211_1 FROM '../forms/cajf211_1c'
END IF
DISPLAY FORM f_cajp211_1
LET vm_cod_tran = 'FA'
LET vm_max_rows = 20000
--#DISPLAY 'Fecha Fact'		TO tit_col1
--#DISPLAY 'Factura'		TO tit_col2
--#DISPLAY 'C l i e n t e s'	TO tit_col3
--#DISPLAY 'TP'		 	TO tit_col4
--#DISPLAY 'No. Retencion'	TO tit_col5
--#DISPLAY 'Valor Ret.'		TO tit_col6
LET vm_size_arr = fgl_scr_size('rm_detalle')
INITIALIZE rm_j10.*, rm_j14.*, rm_par.* TO NULL
LET rm_par.fecha_ini   = TODAY
LET rm_par.fecha_fin   = TODAY
LET rm_par.tipo_fuente = 'PR'
WHILE TRUE
	CALL borrar_pantalla()
	CALL lee_parametros()
	IF int_flag THEN
		EXIT WHILE
	END IF
	IF rm_par.tipo_fuente <> 'SC' THEN
		--#DISPLAY 'Factura'  TO tit_col2
	ELSE
		--#DISPLAY 'Transac.' TO tit_col2
	END IF
	IF ejecutar_carga_datos_temp() THEN
		CALL muestra_consulta()
	END IF
END WHILE
LET int_flag = 0
CLOSE WINDOW w_cajf211_1
DROP TABLE tmp_ret
EXIT PROGRAM

END FUNCTION



FUNCTION borrar_pantalla()
DEFINE i		SMALLINT

LET vm_num_rows = 0
FOR i = 1 TO vm_size_arr 
	CLEAR rm_detalle[i].*
END FOR
CLEAR num_row, max_row, tot_valor

END FUNCTION



FUNCTION lee_parametros()
DEFINE r_z01		RECORD LIKE cxct001.*
DEFINE r_r19		RECORD LIKE rept019.*
DEFINE fec_ini		DATE
DEFINE fec_fin		DATE

LET int_flag = 0
INPUT BY NAME rm_par.*
	WITHOUT DEFAULTS
        ON KEY(INTERRUPT)
		LET int_flag = 1
		EXIT INPUT
        ON KEY(F1,CONTROL-W)
		CALL llamar_visor_teclas()
	ON KEY(F2)
		IF INFIELD(codcli) THEN
			CALL fl_ayuda_cliente_localidad(vg_codcia, vg_codloc)
				RETURNING r_z01.z01_codcli, r_z01.z01_nomcli
			IF r_z01.z01_codcli IS NOT NULL THEN
				LET rm_par.codcli = r_z01.z01_codcli
				LET rm_par.nomcli = r_z01.z01_nomcli
				DISPLAY BY NAME rm_par.codcli, rm_par.nomcli
			END IF
		END IF
		IF INFIELD(num_destino) THEN
			IF rm_par.tipo_fuente = 'SC' THEN
				CONTINUE INPUT
			END IF
			IF rm_par.tipo_fuente = 'PR' THEN
				CALL fl_ayuda_transaccion_rep(vg_codcia,
							vg_codloc, vm_cod_tran)
					RETURNING r_r19.r19_cod_tran,
							r_r19.r19_num_tran,
							r_r19.r19_nomcli 
			END IF
			IF rm_par.tipo_fuente = 'OT' THEN
				CALL fl_ayuda_facturas_tal(vg_codcia, vg_codloc,
							'F')
					RETURNING r_r19.r19_num_tran,
							r_r19.r19_nomcli
			END IF
		      	IF r_r19.r19_num_tran IS NOT NULL THEN
				LET rm_par.num_destino = r_r19.r19_num_tran
				CALL obtener_num_sri(rm_par.tipo_fuente,
							rm_par.num_destino, 1)
					RETURNING rm_par.num_sri
				DISPLAY BY NAME rm_par.num_destino,
						rm_par.num_sri
		      	END IF
		END IF
		LET int_flag = 0
	BEFORE INPUT
		--#CALL dialog.keysetlabel("F1","")
		--#CALL dialog.keysetlabel("CONTROL-W","")
	BEFORE FIELD fecha_ini
		LET fec_ini = rm_par.fecha_ini
	BEFORE FIELD fecha_fin
		LET fec_fin = rm_par.fecha_fin
	AFTER FIELD fecha_ini 
		IF rm_par.fecha_ini IS NOT NULL THEN
			IF rm_par.fecha_ini > TODAY THEN
				CALL fl_mostrar_mensaje('La fecha de inicio no puede ser mayor a la de hoy.','exclamation')
				NEXT FIELD fecha_ini
			END IF
		ELSE
			LET rm_par.fecha_ini = fec_ini     
			DISPLAY BY NAME rm_par.fecha_ini
		END IF
	AFTER FIELD fecha_fin 
		IF rm_par.fecha_fin IS NOT NULL THEN
			IF rm_par.fecha_fin > TODAY THEN
				CALL fl_mostrar_mensaje('La fecha de término no puede ser mayor a la de hoy.','exclamation')
				NEXT FIELD fecha_fin
			END IF
		ELSE
			LET rm_par.fecha_fin = fec_fin
			DISPLAY BY NAME rm_par.fecha_fin
		END IF
	AFTER FIELD codcli
		IF rm_par.codcli IS NOT NULL THEN
			CALL fl_lee_cliente_general(rm_par.codcli)
				RETURNING r_z01.*
			IF r_z01.z01_codcli IS NULL THEN
				CALL fl_mostrar_mensaje('Cliente no existe.', 'exclamation')
				NEXT FIELD codcli
			END IF
			IF r_z01.z01_estado = 'B' THEN
				CALL fl_mensaje_estado_bloqueado()
				NEXT FIELD codcli
			END IF
			LET rm_par.nomcli = r_z01.z01_nomcli
			DISPLAY BY NAME rm_par.nomcli
		ELSE
			LET rm_par.nomcli = NULL
			CLEAR nomcli
		END IF
	AFTER FIELD num_destino
		IF rm_par.tipo_fuente = 'SC' THEN
			LET rm_par.num_destino = NULL
			LET rm_par.num_sri     = NULL
			DISPLAY BY NAME rm_par.num_destino, rm_par.num_sri
			CONTINUE INPUT
		END IF
		IF rm_par.num_destino IS NOT NULL THEN
			CALL fl_lee_cabecera_transaccion_rep(vg_codcia,
						vg_codloc, vm_cod_tran,
						rm_par.num_destino)
				RETURNING r_r19.*
                	IF r_r19.r19_num_tran IS NULL THEN
				CALL fl_mostrar_mensaje('La Factura no existe en la Compañía.', 'exclamation')
                        	NEXT FIELD num_destino
			END IF
			IF r_r19.r19_tipo_dev IS NOT NULL THEN
				CALL fl_mostrar_mensaje('La Factura no se le puede digitar retenciones porque ha sido parcial o totalmente Devuelta/Anulada.', 'exclamation')
				NEXT FIELD num_destino
			END IF
			LET rm_par.num_destino = r_r19.r19_num_tran
			IF rm_par.tipo_fuente <> 'SC' THEN
				CALL obtener_num_sri(rm_par.tipo_fuente,
							rm_par.num_destino, 1)
					RETURNING rm_par.num_sri
			END IF
		ELSE
			LET rm_par.num_sri = NULL
			CLEAR num_sri
		END IF
	AFTER FIELD num_sri
		IF rm_par.tipo_fuente = 'SC' THEN
			LET rm_par.num_destino = NULL
			LET rm_par.num_sri     = NULL
			DISPLAY BY NAME rm_par.num_destino, rm_par.num_sri
			CONTINUE INPUT
		END IF
	AFTER INPUT
		IF rm_par.fecha_ini > rm_par.fecha_fin THEN
			CALL fl_mostrar_mensaje('Fecha inicial debe ser menor a fecha final.','exclamation')
			NEXT FIELD fecha_ini
		END IF
END INPUT

END FUNCTION



FUNCTION obtener_num_sri(tipo_fuente, num_fact, flag)
DEFINE tipo_fuente	LIKE cajt010.j10_tipo_fuente
DEFINE num_fact		LIKE rept019.r19_num_tran
DEFINE flag		SMALLINT
DEFINE r_r38		RECORD LIKE rept038.*
DEFINE query		CHAR(600)

INITIALIZE r_r38.* TO NULL
LET query = 'SELECT r38_num_sri '
IF (vg_codloc = 2 OR vg_codloc = 4) THEN
	LET query = query CLIPPED,
		' FROM ', retorna_base_loc() CLIPPED, 'rept038'
ELSE
	LET query = query CLIPPED, ' FROM rept038'
END IF
LET query = query CLIPPED,
		' WHERE r38_compania     = ', vg_codcia,
		'   AND r38_localidad    = ', rm_j10.j10_localidad,
	  	'   AND r38_tipo_doc    IN ("FA", "NV") ',
		'   AND r38_tipo_fuente  = "', tipo_fuente, '"',
		'   AND r38_cod_tran     = "', vm_cod_tran, '"',
		'   AND r38_num_tran     = ', num_fact
PREPARE cons_r38_2 FROM query
DECLARE q_cons_r38_2 CURSOR FOR cons_r38_2
OPEN q_cons_r38_2
FETCH q_cons_r38_2 INTO r_r38.r38_num_sri
CLOSE q_cons_r38_2
FREE q_cons_r38_2
IF flag THEN
	DISPLAY BY NAME rm_par.num_sri
END IF
RETURN r_r38.r38_num_sri

END FUNCTION



FUNCTION ejecutar_carga_datos_temp()
DEFINE query		CHAR(3000)
DEFINE tabla		VARCHAR(15)
DEFINE expr_tip		VARCHAR(100)
DEFINE expr_cli		VARCHAR(100)
DEFINE expr_num		VARCHAR(100)
DEFINE expr_sri		CHAR(400)
DEFINE expr_fec		CHAR(200)
DEFINE cuantos		INTEGER

ERROR 'Generando consulta . . . espere por favor' ATTRIBUTE(NORMAL)
LET expr_tip = '   AND j10_tipo_fuente     IN ("PR", "OT") '
IF rm_par.tipo_fuente <> 'TT' THEN
	LET expr_tip = '   AND j10_tipo_fuente     = "', rm_par.tipo_fuente, '"'
END IF
LET expr_cli = NULL
IF rm_par.codcli IS NOT NULL THEN
	LET expr_cli = '   AND j10_codcli          = ', rm_par.codcli
END IF
LET expr_num = NULL
LET expr_fec = '   AND DATE(j10_fecha_pro) BETWEEN "', rm_par.fecha_ini, '"',
					     ' AND "', rm_par.fecha_fin, '"'
IF rm_par.num_destino IS NOT NULL THEN
	LET expr_num = '   AND j10_num_destino     = ', rm_par.num_destino
	LET expr_fec = NULL
END IF
LET tabla    = NULL
LET expr_sri = NULL
IF rm_par.num_sri IS NOT NULL THEN
	LET tabla    = ', rept038 '
	LET expr_sri = '   AND r38_compania        = j10_compania ',
			'   AND r38_localidad       = j10_localidad ',
			'   AND r38_tipo_doc       IN ("FA", "NV") ',
			'   AND r38_tipo_fuente     = j10_tipo_fuente ',
			'   AND r38_cod_tran        = j10_tipo_destino ',
			'   AND r38_num_tran        = j10_num_destino ',
			'   AND r38_num_sri         = "',
						rm_par.num_sri CLIPPED, '"'
END IF
LET query = ' SELECT UNIQUE DATE(j10_fecha_pro) fecha_fact, j10_num_destino,',
			' j10_nomcli, j11_codigo_pago, j11_num_ch_aut,',
			' j11_valor, j10_codcli, j10_num_fuente,',
			' j10_tipo_fuente, j10_tipo_destino, j11_secuencia ',
		' FROM cajt010, cajt011 ', tabla CLIPPED,
		' WHERE j10_compania        = ', vg_codcia,
		'   AND j10_localidad       = ', vg_codloc,
		expr_tip CLIPPED,
		'   AND j10_estado          = "P" ',
		expr_cli CLIPPED,
		expr_num CLIPPED,
		expr_fec CLIPPED,
		expr_sri CLIPPED,
		'   AND j11_compania        = j10_compania ',
		'   AND j11_localidad       = j10_localidad ',
		'   AND j11_tipo_fuente     = j10_tipo_fuente ',
		'   AND j11_num_fuente      = j10_num_fuente ',
		'   AND EXISTS (SELECT 1 FROM cajt001 ',
				' WHERE j01_compania     = j11_compania ',
				'   AND j01_codigo_pago  = j11_codigo_pago ',
				'   AND j01_cont_cred   IN ("C", "R") ',
				'   AND j01_retencion    = "S") ',
		' INTO TEMP tmp_det '
PREPARE exec_tmp FROM query
EXECUTE exec_tmp
ERROR ' ' ATTRIBUTE(NORMAL)
SELECT COUNT(*) INTO cuantos FROM tmp_det
IF cuantos = 0 THEN
	CALL fl_mensaje_consulta_sin_registros()
	DROP TABLE tmp_det
	RETURN 0
END IF
RETURN 1

END FUNCTION



FUNCTION muestra_consulta()
DEFINE r_j14		RECORD LIKE cajt014.*
DEFINE i, j, col	SMALLINT

FOR i = 1 TO 10
	LET rm_orden[i] = '' 
END FOR
LET col                    = 1
LET vm_columna_1           = col
LET vm_columna_2           = 2
LET rm_orden[vm_columna_1] = 'DESC'
LET rm_orden[vm_columna_2] = 'ASC'
WHILE TRUE
	CALL cargar_detalle()
	IF vg_gui = 0 THEN
		CALL muestra_contadores_det(1, vm_num_rows)
		IF rm_par.num_destino IS NOT NULL THEN
			CALL detalle_retenciones(1, 1, 1)
		END IF
	END IF
	LET int_flag = 0
	CALL set_count(vm_num_rows)
	DISPLAY ARRAY rm_detalle TO rm_detalle.*
		ON KEY(INTERRUPT)
			LET int_flag = 1
			EXIT DISPLAY
		ON KEY(RETURN)
			LET i = arr_curr()
			LET j = scr_line()
			CALL muestra_contadores_det(i, vm_num_rows)
	       	ON KEY(F1,CONTROL-W)
			CALL control_visor_teclas_caracter_1()
		ON KEY(F5)
			LET i = arr_curr()
			LET j = scr_line()
			CALL fl_ver_comprobantes_emitidos_caja(
						rm_adi[i].j10_tipo_fuente,
						rm_adi[i].j10_num_fuente, 
						rm_adi[i].j10_tipo_destino,
					        rm_detalle[i].j10_num_destino, 
					        rm_adi[i].j10_codcli)
			LET int_flag = 0
		ON KEY(F6)
			LET i = arr_curr()
			LET j = scr_line()
			CALL detalle_retenciones(i, j, 1)
			--#CALL lee_num_retencion(rm_detalle[i].j11_num_ch_aut)
				--#RETURNING r_j14.*
			--#IF r_j14.j14_compania IS NOT NULL THEN
				--#CALL dialog.keysetlabel("F7","Modificar Ret.")
			--#ELSE
				--#CALL dialog.keysetlabel("F7","")
			--#END IF
			LET int_flag = 0
		ON KEY(F7)
			LET i = arr_curr()
			LET j = scr_line()
			CALL lee_num_retencion(rm_detalle[i].j11_num_ch_aut)
				RETURNING r_j14.*
			IF r_j14.j14_compania IS NOT NULL THEN
				CALL detalle_retenciones(i, j, 0)
				LET int_flag = 0
			END IF
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
		--#BEFORE DISPLAY
			--#IF rm_par.num_destino IS NOT NULL THEN
				--#CALL detalle_retenciones(1, 1, 1)
			--#END IF
			--#CALL dialog.keysetlabel("ACCEPT","")
			--#CALL dialog.keysetlabel("INSERT","")
			--#CALL dialog.keysetlabel("DELETE","")
			--#CALL dialog.keysetlabel("F1","")
			--#CALL dialog.keysetlabel("CONTROL-W","")
		--#BEFORE ROW
			--#LET i = arr_curr()
			--#LET j = scr_line()
			--#CALL muestra_contadores_det(i, vm_num_rows)
			--#CALL lee_num_retencion(rm_detalle[i].j11_num_ch_aut)
				--#RETURNING r_j14.*
			--#IF r_j14.j14_compania IS NOT NULL THEN
				--#CALL dialog.keysetlabel("F7","Modificar Ret.")
			--#ELSE
				--#CALL dialog.keysetlabel("F7","")
			--#END IF
			--#IF rm_par.tipo_fuente = 'SC' THEN
				--#CALL dialog.keysetlabel("F5","Transaccion")
			--#ELSE
				--#CALL dialog.keysetlabel("F5","Factura")
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
DROP TABLE tmp_det

END FUNCTION



FUNCTION cargar_detalle()
DEFINE query		VARCHAR(200)

LET query = 'SELECT * FROM tmp_det ',
                ' ORDER BY ', vm_columna_1, ' ', rm_orden[vm_columna_1],
			', ', vm_columna_2, ' ', rm_orden[vm_columna_2] 
PREPARE cons_fac FROM query
DECLARE q_fact_c CURSOR FOR cons_fac
LET vm_num_rows = 1
FOREACH q_fact_c INTO rm_detalle[vm_num_rows].*, rm_adi[vm_num_rows].*
	LET vm_num_rows = vm_num_rows + 1
	IF vm_num_rows > vm_max_rows THEN
		EXIT FOREACH
	END IF
END FOREACH
LET vm_num_rows = vm_num_rows - 1
CALL calcular_total()

END FUNCTION



FUNCTION calcular_total()
DEFINE tot_valor	DECIMAL(14,2)
DEFINE i		SMALLINT

LET tot_valor = 0
FOR i = 1 TO vm_num_rows
	LET tot_valor = tot_valor + rm_detalle[i].j11_valor
END FOR
DISPLAY BY NAME tot_valor

END FUNCTION



FUNCTION muestra_contadores_det(num_row, max_row)
DEFINE num_row, max_row	SMALLINT

DISPLAY BY NAME num_row, max_row

END FUNCTION



FUNCTION detalle_retenciones(i, j, flag_l)
DEFINE i, j, flag_l	SMALLINT
DEFINE tipo_llamada	CHAR(1)
DEFINE num_ret		LIKE cajt014.j14_num_ret_sri

IF fl_determinar_si_es_retencion(vg_codcia, rm_detalle[i].j11_codigo_pago, 'R')
THEN
	INITIALIZE rm_j10.*, rm_j14.* TO NULL
	DECLARE q_j10 CURSOR FOR
		SELECT * FROM cajt010
			WHERE j10_compania      = vg_codcia
			  AND j10_localidad     = vg_codloc
			  AND j10_tipo_fuente  IN
			(SELECT a.j10_tipo_fuente
				FROM tmp_det a
				WHERE a.j10_num_destino =
					rm_detalle[i].j10_num_destino
				  AND a.j11_codigo_pago =
					rm_detalle[i].j11_codigo_pago
				  AND a.j11_num_ch_aut  =
					rm_detalle[i].j11_num_ch_aut)
			  AND j10_tipo_destino IN
			(SELECT a.j10_tipo_destino
				FROM tmp_det a
				WHERE a.j10_num_destino =
					rm_detalle[i].j10_num_destino
				  AND a.j11_codigo_pago =
					rm_detalle[i].j11_codigo_pago
				  AND a.j11_num_ch_aut  =
					rm_detalle[i].j11_num_ch_aut)
			  AND j10_num_destino   = rm_detalle[i].j10_num_destino
	OPEN q_j10
	FETCH q_j10 INTO rm_j10.*
	CLOSE q_j10
	FREE q_j10
	LET rm_j14.j14_num_ret_sri = rm_detalle[i].j11_num_ch_aut
	CALL lee_num_retencion(rm_j14.j14_num_ret_sri) RETURNING rm_j14.*
	LET tipo_llamada = 'I'
	IF rm_j14.j14_compania IS NOT NULL THEN
		LET tipo_llamada = 'C'
	END IF
	IF tipo_llamada = 'I' THEN
		DELETE FROM tmp_det
			WHERE j10_num_destino = rm_detalle[i].j10_num_destino
			  AND j11_codigo_pago = rm_detalle[i].j11_codigo_pago
			  AND j11_num_ch_aut  = rm_detalle[i].j11_num_ch_aut
		INSERT INTO tmp_det
			SELECT UNIQUE DATE(j10_fecha_pro) fecha_fact,
				j10_num_destino, j10_nomcli,
				j11_codigo_pago, j11_num_ch_aut,
				j11_valor, j10_codcli, j10_num_fuente,
				j10_tipo_fuente, j11_secuencia
			FROM cajt010, cajt011
			WHERE j10_compania     = rm_j10.j10_compania
			  AND j10_localidad    = rm_j10.j10_localidad
			  AND j10_tipo_fuente  = rm_j10.j10_tipo_fuente
			  AND j10_num_fuente   = rm_j10.j10_num_fuente
			  AND j11_compania     = j10_compania
			  AND j11_localidad    = j10_localidad
			  AND j11_tipo_fuente  = j10_tipo_fuente
			  AND j11_num_fuente   = j10_num_fuente
			  AND j11_codigo_pago IN
				(SELECT UNIQUE j01_codigo_pago
					FROM cajt001
					WHERE j01_compania    = j11_compania
					  AND j01_codigo_pago = j11_codigo_pago
					  AND j01_cont_cred   IN ('C', 'R')
					  AND j01_retencion   = 'S')
		CALL cargar_detalle()
		DISPLAY rm_detalle[i].* TO rm_detalle[j].*
		LET rm_j14.j14_num_ret_sri =rm_detalle[i].j11_num_ch_aut
		CALL lee_num_retencion(rm_j14.j14_num_ret_sri)
			RETURNING rm_j14.*
	END IF
	LET tipo_llamada = 'I'
	IF rm_j14.j14_compania IS NOT NULL THEN
		LET tipo_llamada = 'C'
	END IF
	IF tipo_llamada = 'I' OR NOT flag_l THEN
		IF NOT tiene_aux_cont_retencion(rm_detalle[i].j11_codigo_pago,
						'C', 1)
		THEN
			RETURN
		END IF
		BEGIN WORK
		WHENEVER ERROR CONTINUE
		DECLARE q_up CURSOR FOR
			SELECT * FROM cajt010
				WHERE j10_compania    = rm_j10.j10_compania
				  AND j10_localidad   = rm_j10.j10_localidad
				  AND j10_tipo_fuente = rm_j10.j10_tipo_fuente
				  AND j10_num_fuente  = rm_j10.j10_num_fuente
			FOR UPDATE
		OPEN q_up 
		FETCH q_up
		IF STATUS < 0 THEN
			ROLLBACK WORK
			CALL fl_mostrar_mensaje('La retencion de esta factura esta siendo modificada por otro usuario.', 'exclamation')
			WHENEVER ERROR STOP
			RETURN
		END IF
		IF STATUS = NOTFOUND THEN
			ROLLBACK WORK
			CALL fl_mostrar_mensaje('El registro de pago de esta factura ya no existe. POR FAVOR LLAME AL ADMINISTRADOR.', 'stop')
			WHENEVER ERROR STOP
			RETURN
		END IF
		WHENEVER ERROR STOP
	END IF
	IF NOT flag_l THEN
		LET tipo_llamada = 'M'
	END IF
	CALL control_retenciones(rm_detalle[i].j11_codigo_pago, tipo_llamada, i)
		RETURNING num_ret
	IF tipo_llamada = 'I' OR NOT flag_l THEN
		IF num_ret IS NOT NULL THEN
			COMMIT WORK
		ELSE
			ROLLBACK WORK
		END IF
	END IF
	IF num_ret IS NOT NULL THEN
		DISPLAY rm_detalle[i].j11_num_ch_aut TO
			rm_detalle[j].j11_num_ch_aut
	END IF
END IF
DELETE FROM tmp_ret

END FUNCTION



FUNCTION control_retenciones(codigo_pago, tipo_llamada, posi)
DEFINE codigo_pago	LIKE cajt001.j01_codigo_pago
DEFINE tipo_llamada	CHAR(1)
DEFINE posi		SMALLINT
DEFINE row_ini, col_ini	SMALLINT
DEFINE row_fin, col_fin	SMALLINT
DEFINE cuantos		INTEGER
DEFINE valor_bruto	DECIMAL(14,2)
DEFINE valor_impto	DECIMAL(14,2)
DEFINE subtotal		DECIMAL(14,2)
DEFINE flete		DECIMAL(14,2)
DEFINE valor_fact	DECIMAL(14,2)
DEFINE valor		DECIMAL(12,2)
DEFINE r_z01		RECORD LIKE cxct001.*
DEFINE r_r19		RECORD LIKE rept019.*
DEFINE r_t23		RECORD LIKE talt023.*
DEFINE tipo_doc		LIKE rept038.r38_tipo_doc
DEFINE num_sri		LIKE rept038.r38_num_sri
DEFINE codloc		LIKE rept019.r19_localidad
DEFINE cod_tran		LIKE rept019.r19_cod_tran
DEFINE num_tran		LIKE rept019.r19_num_tran

LET row_ini = 04
LET row_fin = 20
LET col_ini = 04
LET col_fin = 74
IF vg_gui = 0 THEN
	LET row_ini = 05
	LET row_fin = 18
	LET col_ini = 04
	LET col_fin = 74
END IF
OPEN WINDOW w_cajf203_2 AT row_ini, col_ini WITH row_fin ROWS, col_fin COLUMNS
	ATTRIBUTE(FORM LINE FIRST, COMMENT LINE LAST, MENU LINE 0, BORDER,
			MESSAGE LINE LAST) 
IF vg_gui = 1 THEN
	OPEN FORM f_cajf203_2 FROM '../forms/cajf203_2'
ELSE
	OPEN FORM f_cajf203_2 FROM '../forms/cajf203_2c'
END IF
DISPLAY FORM f_cajf203_2
LET vm_num_ret = 0
LET vm_max_ret = 50
CALL borrar_retenciones()
--#DISPLAY 'T'		 TO tit_col1
--#DISPLAY '%'		 TO tit_col2
--#DISPLAY 'Cod. SRI' 	 TO tit_col3
--#DISPLAY 'Descripcion' TO tit_col4
--#DISPLAY 'Base Imp.'	 TO tit_col5
--#DISPLAY 'Valor Ret.'	 TO tit_col6
CALL datos_factura() RETURNING cuantos, codloc, cod_tran, num_tran, valor
IF cuantos <= 1 THEN
	CASE rm_j10.j10_areaneg
		WHEN 1
			CALL lee_factura_inv(vg_codcia, codloc, cod_tran,
						num_tran)
				RETURNING r_r19.*
			LET valor_bruto = r_r19.r19_tot_bruto -
						r_r19.r19_tot_dscto
			LET valor_impto = r_r19.r19_tot_neto -
						r_r19.r19_tot_bruto +
						r_r19.r19_tot_dscto -
						r_r19.r19_flete
			LET subtotal    = valor_bruto + valor_impto
			LET flete       = r_r19.r19_flete
			LET valor_fact  = r_r19.r19_tot_neto
		WHEN 2
			CALL fl_lee_orden_trabajo(vg_codcia, vg_codloc,
							rm_j10.j10_num_fuente)
				RETURNING r_t23.*
			LET valor_bruto = r_t23.t23_tot_bruto -
						r_t23.t23_tot_dscto
			LET valor_impto = r_t23.t23_val_impto
			LET subtotal    = valor_bruto + valor_impto
			LET flete       = NULL
			LET valor_fact  = r_t23.t23_tot_neto
	END CASE
ELSE
	LET valor_bruto = valor
	LET valor_impto = 0
	LET subtotal    = valor_bruto
	LET flete       = NULL
	LET valor_fact  = subtotal
END IF
DISPLAY BY NAME rm_j10.j10_tipo_fuente, rm_j10.j10_num_fuente,rm_j10.j10_codcli,
		rm_j10.j10_nomcli, valor_bruto, valor_impto, subtotal, flete,
		valor_fact, rm_j10.j10_tipo_destino, rm_j10.j10_num_destino
LET tipo_doc = rm_j10.j10_tipo_destino
CALL fl_lee_cliente_general(rm_j10.j10_codcli) RETURNING r_z01.*
IF r_z01.z01_tipo_doc_id <> 'R' THEN
	LET tipo_doc = 'NV'
END IF
DECLARE q_j14_2 CURSOR FOR
	SELECT j14_num_fact_sri
		FROM cajt014
		WHERE j14_compania    = vg_codcia
		  AND j14_localidad   = rm_j10.j10_localidad
		  AND j14_tipo_fuente = rm_j10.j10_tipo_fuente
		  AND j14_num_fuente  = rm_j10.j10_num_fuente
		  AND j14_num_ret_sri = rm_detalle[posi].j11_num_ch_aut
		ORDER BY 1
OPEN q_j14_2
FETCH q_j14_2 INTO num_sri
CLOSE q_j14_2
FREE q_j14_2
DISPLAY BY NAME num_sri
IF tipo_llamada <> 'C' THEN
	CALL ingreso_modificacion_retenciones(codigo_pago, posi, tipo_llamada,
						valor_fact)
ELSE
	CALL consulta_retenciones(codigo_pago)
END IF
LET int_flag = 0
CLOSE WINDOW w_cajf203_2
RETURN rm_j14.j14_num_ret_sri

END FUNCTION



FUNCTION ingreso_modificacion_retenciones(codigo_pago, posi, tipo_llamada,
						valor_fact)
DEFINE codigo_pago	LIKE cajt001.j01_codigo_pago
DEFINE posi		SMALLINT
DEFINE tipo_llamada	CHAR(1)
DEFINE valor_fact	DECIMAL(14,2)
DEFINE i		SMALLINT

CASE tipo_llamada
	WHEN 'I' CALL cargar_retenciones(codigo_pago)
	WHEN 'M' CALL cargar_retenciones2(codigo_pago, 1)
END CASE
CALL lee_retenciones(codigo_pago, posi, tipo_llamada, valor_fact)
IF int_flag THEN
	IF registros_retenciones(codigo_pago) = 0 THEN
		INITIALIZE rm_j14.j14_num_ret_sri, tot_valor_ret TO NULL
		LET vm_num_ret = 0
	END IF
ELSE
	DELETE FROM tmp_ret WHERE cod_pago = codigo_pago
	FOR i = 1 TO vm_num_ret
		INSERT INTO tmp_ret
			VALUES(codigo_pago, rm_j14.j14_num_ret_sri,
				rm_j14.j14_autorizacion, rm_j14.j14_fecha_emi,
				rm_detret[i].*, fec_ini_por[i],
				rm_j14.j14_num_fact_sri)
	END FOR
	CALL grabar_detalle_retencion(codigo_pago, posi, tipo_llamada)
END IF

END FUNCTION



FUNCTION consulta_retenciones(codigo_pago)
DEFINE codigo_pago	LIKE cajt001.j01_codigo_pago
DEFINE i, j		SMALLINT

CALL cargar_retenciones2(codigo_pago, 0)
IF vm_num_ret = 0 THEN
	RETURN
END IF
DISPLAY BY NAME rm_j14.j14_num_ret_sri, rm_j14.j14_autorizacion,
		rm_j14.j14_fecha_emi
CALL calcular_tot_retencion(vm_num_ret)
CALL muestra_contadores_det(1, vm_num_ret)
CALL set_count(vm_num_ret)
DISPLAY ARRAY rm_detret TO rm_detret.*
	ON KEY(INTERRUPT)
		EXIT DISPLAY
       	ON KEY(F1,CONTROL-W)
		CALL llamar_visor_teclas()
	ON KEY(RETURN)
		LET i = arr_curr()
        	LET j = scr_line()
		CALL muestra_contadores_det(i, vm_num_ret)
	--#BEFORE DISPLAY
		--#CALL dialog.keysetlabel("F1","")
		--#CALL dialog.keysetlabel("CONTROL-W","")
                --#CALL dialog.keysetlabel('ACCEPT', '')
		--#CALL dialog.keysetlabel('RETURN','')
	--#BEFORE ROW
		--#LET i = arr_curr()
		--#LET j = scr_line()
		--#CALL muestra_contadores_det(i, vm_num_ret)
        --#AFTER DISPLAY
                --#CONTINUE DISPLAY
END DISPLAY
CALL muestra_contadores_det(0, vm_num_ret)

END FUNCTION



FUNCTION borrar_retenciones()
DEFINE i		SMALLINT

INITIALIZE rm_j14.* TO NULL
FOR i = 1 TO fgl_scr_size('rm_detret')
	CLEAR rm_detret[i].*
END FOR
FOR i = 1 TO vm_max_ret
	INITIALIZE rm_detret[i].* TO NULL
END FOR
CLEAR j14_num_ret_sri, j14_autorizacion, j14_fecha_emi, num_row, max_row,
	tot_base_imp, tot_valor_ret, j10_codcli, j10_nomcli, valor_bruto,
	valor_impto, subtotal, flete, j10_tipo_fuente, j10_num_fuente,
	j10_tipo_destino, j10_num_destino, num_sri

END FUNCTION



FUNCTION cargar_retenciones(codigo_pago)
DEFINE codigo_pago	LIKE cajt001.j01_codigo_pago
DEFINE query		CHAR(6000)

IF registros_retenciones(codigo_pago) = 0 THEN
	CALL query_principal_retenciones(codigo_pago) RETURNING query
ELSE
	LET query = 'SELECT num_ret_sri, autorizacion, fecha_emi, tipo_ret,',
			' porc_ret, codigo_sri, concepto_ret, base_imp,',
			' valor_ret, fec_ini_porc ',
			' FROM tmp_ret ',
			' WHERE cod_pago = "', codigo_pago, '"'
END IF
PREPARE cons_ret FROM query
DECLARE q_cons_ret CURSOR FOR cons_ret
LET vm_num_ret = 1
FOREACH q_cons_ret INTO rm_j14.j14_num_ret_sri, rm_j14.j14_autorizacion,
			rm_j14.j14_fecha_emi, rm_detret[vm_num_ret].*,
			fec_ini_por[vm_num_ret]
	IF registros_retenciones(codigo_pago) = 0 THEN
		IF LENGTH(rm_detret[vm_num_ret].j14_codigo_sri) < 2 THEN
			INITIALIZE rm_j14.* TO NULL
			LET rm_detret[vm_num_ret].j14_codigo_sri   = NULL
			LET rm_detret[vm_num_ret].c03_concepto_ret = NULL
		END IF
	END IF
	LET vm_num_ret = vm_num_ret + 1
	IF vm_num_ret > vm_max_ret THEN
		EXIT FOREACH
	END IF
END FOREACH
LET vm_num_ret = vm_num_ret - 1
CALL mostrar_detalle()

END FUNCTION



FUNCTION cargar_retenciones2(codigo_pago, flag)
DEFINE codigo_pago	LIKE cajt001.j01_codigo_pago
DEFINE sec		LIKE cajt014.j14_sec_ret
DEFINE flag		SMALLINT

DECLARE q_ret3 CURSOR FOR
	SELECT j14_num_ret_sri, j14_autorizacion, j14_fecha_emi, j14_tipo_ret,
		j14_porc_ret, j14_codigo_sri, c03_concepto_ret, j14_base_imp,
		j14_valor_ret, j14_sec_ret, j14_fec_ini_porc, j14_num_fact_sri
		FROM cajt014, ordt003
		WHERE j14_compania    = vg_codcia
		  AND j14_localidad   = vg_codloc
		  AND j14_tipo_fuente = rm_j10.j10_tipo_fuente
		  AND j14_num_fuente  = rm_j10.j10_num_fuente
		  AND j14_codigo_pago = codigo_pago
		  AND c03_compania    = j14_compania
		  AND c03_tipo_ret    = j14_tipo_ret
		  AND c03_porcentaje  = j14_porc_ret
		  AND c03_codigo_sri  = j14_codigo_sri
		  AND c03_fecha_ini_porc = j14_fec_ini_porc
		ORDER BY j14_sec_ret
LET vm_num_ret = 1
FOREACH q_ret3 INTO rm_j14.j14_num_ret_sri, rm_j14.j14_autorizacion,
			rm_j14.j14_fecha_emi, rm_detret[vm_num_ret].*, sec,
			fec_ini_por[vm_num_ret], rm_j14.j14_num_fact_sri
	IF flag THEN
		INSERT INTO tmp_ret
			VALUES(codigo_pago, rm_j14.j14_num_ret_sri,
				rm_j14.j14_autorizacion, rm_j14.j14_fecha_emi,
				rm_detret[vm_num_ret].*,fec_ini_por[vm_num_ret],
				rm_j14.j14_num_fact_sri)
	END IF
	LET vm_num_ret = vm_num_ret + 1
	IF vm_num_ret > vm_max_ret THEN
		EXIT FOREACH
	END IF
END FOREACH
LET vm_num_ret = vm_num_ret - 1
CALL mostrar_detalle()

END FUNCTION



FUNCTION mostrar_detalle()
DEFINE i, lim		INTEGER

IF vm_num_ret = 0 THEN
	RETURN
END IF
IF rm_j14.j14_num_ret_sri IS NULL THEN
	RETURN
END IF
LET lim = vm_num_ret
IF lim > fgl_scr_size('rm_detret') THEN
	LET lim = fgl_scr_size('rm_detret')
END IF
FOR i = 1 TO lim
	DISPLAY rm_detret[i].* TO rm_detret[i].*
END FOR
CALL calcular_tot_retencion(lim)

END FUNCTION



FUNCTION query_principal_retenciones(codigo_pago)
DEFINE codigo_pago	LIKE cajt001.j01_codigo_pago
DEFINE tipo_fue		LIKE ordt002.c02_tipo_fuente
DEFINE query		CHAR(6000)

CASE rm_j10.j10_tipo_fuente
	WHEN "PR" LET tipo_fue = 'B'
	WHEN "OT" LET tipo_fue = 'S'
END CASE
LET query = 'SELECT "", "", "", z08_tipo_ret, z08_porcentaje,',
		' "", "",',
		' CASE WHEN "', rm_j10.j10_tipo_fuente, '" = "PR" THEN',
		' (SELECT r23_tot_bruto - r23_tot_dscto ',
			'FROM rept023 ',
			'WHERE r23_compania  = z08_compania ',
			'  AND r23_localidad = ', rm_j10.j10_localidad,
			'  AND r23_numprev   = ', rm_j10.j10_num_fuente,
			')',
			'      WHEN "', rm_j10.j10_tipo_fuente, '" = "OT" THEN',
		' (SELECT t23_tot_bruto - t23_tot_dscto ',
			'FROM talt023 ',
			'WHERE t23_compania  = z08_compania ',
			'  AND t23_localidad = ', rm_j10.j10_localidad,
			'  AND t23_orden     = ', rm_j10.j10_num_fuente,
			')',
		' ELSE 0 ',
		' END, ',
		' CASE WHEN "', rm_j10.j10_tipo_fuente, '" = "PR" THEN',
		' (SELECT r23_tot_bruto - r23_tot_dscto ',
			'FROM rept023 ',
			'WHERE r23_compania  = z08_compania ',
			'  AND r23_localidad = ', rm_j10.j10_localidad,
			'  AND r23_numprev   = ', rm_j10.j10_num_fuente,
			')',
			'      WHEN "', rm_j10.j10_tipo_fuente, '" = "OT" THEN',
		' (SELECT t23_tot_bruto - t23_tot_dscto ',
			'FROM talt023 ',
			'WHERE t23_compania  = z08_compania ',
			'  AND t23_localidad = ', rm_j10.j10_localidad,
			'  AND t23_orden     = ', rm_j10.j10_num_fuente,
			')',
		' ELSE 0 ',
		' END * (c02_porcentaje / 100), z08_fecha_ini_porc ',
		' FROM cxct008, ordt003, ordt002, cajt091 ',
		' WHERE z08_compania    = ', vg_codcia,
		'   AND z08_codcli      = ', rm_j10.j10_codcli,
		'   AND z08_defecto     = "S" ',
		'   AND c03_compania    = z08_compania ',
		'   AND c03_tipo_ret    = z08_tipo_ret ',
		'   AND c03_porcentaje  = z08_porcentaje ',
		'   AND c03_codigo_sri  = z08_codigo_sri ',
		'   AND c03_fecha_ini_porc = z08_fecha_ini_porc ',
		'   AND c03_estado      = "A" ',
		'   AND c02_compania    = c03_compania ',
		'   AND c02_tipo_ret    = c03_tipo_ret ',
		'   AND c02_porcentaje  = c03_porcentaje ',
		'   AND c02_estado      = "A" ',
		'   AND j91_compania    = c02_compania ',
		'   AND j91_codigo_pago = "', codigo_pago, '"',
		'   AND j91_cont_cred   = "C" ',
		'   AND j91_tipo_ret    = c02_tipo_ret ',
		'   AND j91_porcentaje  = c02_porcentaje ',
	' UNION ',
	' SELECT "", "", "", z08_tipo_ret, z08_porcentaje,',
		' c03_codigo_sri, c03_concepto_ret,',
		' CASE WHEN "', rm_j10.j10_tipo_fuente, '" = "PR" THEN',
		' (SELECT r23_flete ',
			'FROM rept023 ',
			'WHERE r23_compania  = z08_compania ',
			'  AND r23_localidad = ', rm_j10.j10_localidad,
			'  AND r23_numprev   = ', rm_j10.j10_num_fuente,
			')',
		' ELSE 0 ',
		' END, ',
		' CASE WHEN "', rm_j10.j10_tipo_fuente, '" = "PR" THEN',
		' (SELECT r23_flete ',
			'FROM rept023 ',
			'WHERE r23_compania  = z08_compania ',
			'  AND r23_localidad = ', rm_j10.j10_localidad,
			'  AND r23_numprev   = ', rm_j10.j10_num_fuente,
			')',
		' ELSE 0 ',
		' END * (c02_porcentaje / 100), z08_fecha_ini_porc ',
		' FROM cxct008, ordt003, ordt002, cajt091 ',
		' WHERE z08_compania    = ', vg_codcia,
		'   AND z08_codcli      = ', rm_j10.j10_codcli,
		'   AND z08_flete       = "S" ',
		'   AND c03_compania    = z08_compania ',
		'   AND c03_tipo_ret    = z08_tipo_ret ',
		'   AND c03_porcentaje  = z08_porcentaje ',
		'   AND c03_codigo_sri  = z08_codigo_sri ',
		'   AND c03_fecha_ini_porc = z08_fecha_ini_porc ',
		'   AND c03_estado      = "A" ',
		'   AND c02_compania    = c03_compania ',
		'   AND c02_tipo_ret    = c03_tipo_ret ',
		'   AND c02_porcentaje  = c03_porcentaje ',
		'   AND c02_estado      = "A" ',
		'   AND j91_compania    = c02_compania ',
		'   AND j91_codigo_pago = "', codigo_pago, '"',
		'   AND j91_cont_cred   = "C" ',
		'   AND j91_tipo_ret    = c02_tipo_ret ',
		'   AND j91_porcentaje  = c02_porcentaje ',
		'   AND EXISTS (SELECT 1 FROM rept023 ',
			'WHERE r23_compania  = z08_compania ',
			'  AND r23_localidad = ', rm_j10.j10_localidad,
			'  AND r23_numprev   = ', rm_j10.j10_num_fuente,
			'  AND r23_flete     > 0) ',
	' UNION ',
	' SELECT "", "", "", z08_tipo_ret, z08_porcentaje,',
		' c03_codigo_sri, c03_concepto_ret,',
		' CASE WHEN "', rm_j10.j10_tipo_fuente, '" = "PR" THEN',
		' (SELECT r23_tot_neto - r23_tot_bruto + ',
					'r23_tot_dscto - r23_flete ',
			'FROM rept023 ',
			'WHERE r23_compania  = z08_compania ',
			'  AND r23_localidad = ', rm_j10.j10_localidad,
			'  AND r23_numprev   = ', rm_j10.j10_num_fuente,
			')',
		'      WHEN "', rm_j10.j10_tipo_fuente, '" = "OT" THEN',
		' (SELECT t23_val_impto ',
			'FROM talt023 ',
			'WHERE t23_compania  = z08_compania ',
			'  AND t23_localidad = ', rm_j10.j10_localidad,
			'  AND t23_orden     = ', rm_j10.j10_num_fuente,
			')',
		' ELSE 0 ',
		' END, ',
		' CASE WHEN "', rm_j10.j10_tipo_fuente, '" = "PR" THEN',
		' (SELECT r23_tot_neto - r23_tot_bruto + ',
				'r23_tot_dscto - r23_flete ',
			'FROM rept023 ',
			'WHERE r23_compania  = z08_compania ',
			'  AND r23_localidad = ', rm_j10.j10_localidad,
			'  AND r23_numprev   = ', rm_j10.j10_num_fuente,
			')',
		'      WHEN "', rm_j10.j10_tipo_fuente, '" = "OT" THEN',
		' (SELECT t23_val_impto ',
			'FROM talt023 ',
			'WHERE t23_compania  = z08_compania ',
			'  AND t23_localidad = ', rm_j10.j10_localidad,
			'  AND t23_orden     = ', rm_j10.j10_num_fuente,
			')',
		' ELSE 0 ',
		' END * (c02_porcentaje / 100), z08_fecha_ini_porc ',
		' FROM cxct008, ordt003, ordt002, cajt091 ',
		' WHERE z08_compania    = ', vg_codcia,
		'   AND z08_codcli      = ', rm_j10.j10_codcli,
		'   AND z08_tipo_ret    = "I" ',
		'   AND c03_compania    = z08_compania ',
		'   AND c03_tipo_ret    = z08_tipo_ret ',
		'   AND c03_porcentaje  = z08_porcentaje ',
		'   AND c03_codigo_sri  = z08_codigo_sri ',
		'   AND c03_fecha_ini_porc = z08_fecha_ini_porc ',
		'   AND c03_estado      = "A" ',
		'   AND c02_compania    = c03_compania ',
		'   AND c02_tipo_ret    = c03_tipo_ret ',
		'   AND c02_porcentaje  = c03_porcentaje ',
		'   AND c02_estado      = "A" ',
		'   AND c02_tipo_fuente = "', tipo_fue, '"',
		'   AND j91_compania    = c02_compania ',
		'   AND j91_codigo_pago = "', codigo_pago, '"',
		'   AND j91_cont_cred   = "C" ',
		'   AND j91_tipo_ret    = c02_tipo_ret ',
		'   AND j91_porcentaje  = c02_porcentaje '
RETURN query

END FUNCTION



FUNCTION lee_retenciones(codigo_pago, posi, tipo_llamada, valor_fact)
DEFINE codigo_pago	LIKE cajt001.j01_codigo_pago
DEFINE posi		SMALLINT
DEFINE tipo_llamada	CHAR(1)
DEFINE valor_fact	DECIMAL(14,2)
DEFINE salir		SMALLINT

LET salir = 0
WHILE NOT salir
	CALL lee_cabecera_ret(posi, tipo_llamada)
	IF int_flag THEN
		OPTIONS INPUT WRAP
		EXIT WHILE
	END IF
	OPTIONS INPUT WRAP
	CALL lee_detalle_ret(codigo_pago, posi, valor_fact) RETURNING salir
	IF int_flag THEN
		EXIT WHILE
	END IF
END WHILE

END FUNCTION



FUNCTION lee_cabecera_ret(posi, tipo_llamada)
DEFINE posi		SMALLINT
DEFINE tipo_llamada	CHAR(1)
DEFINE r_j14		RECORD LIKE cajt014.*
DEFINE num_ret		LIKE cajt014.j14_num_ret_sri
DEFINE fec_emi		LIKE cajt014.j14_fecha_emi
DEFINE resp		CHAR(6)
DEFINE fecha		DATE
DEFINE fecha_min	DATE
DEFINE fecha_tope	DATE
DEFINE mensaje		VARCHAR(200)
DEFINE dias_tope, lim	SMALLINT

OPTIONS INPUT NO WRAP
LET rm_j14.j14_num_ret_sri = rm_detalle[posi].j11_num_ch_aut
IF tipo_llamada = 'I' THEN
	IF rm_j14.j14_fecha_emi IS NULL THEN
		LET rm_j14.j14_fecha_emi   = TODAY
	END IF
END IF
LET num_ret                = NULL
LET fec_emi                = NULL
IF tipo_llamada = 'M' THEN
	LET num_ret = rm_j14.j14_num_ret_sri
	LET fec_emi = rm_j14.j14_fecha_emi
END IF
LET int_flag = 0
INPUT BY NAME rm_j14.j14_num_ret_sri, rm_j14.j14_autorizacion,
	rm_j14.j14_fecha_emi
	WITHOUT DEFAULTS
	ON KEY(INTERRUPT)
		IF NOT FIELD_TOUCHED(j14_num_ret_sri, j14_autorizacion,
					j14_fecha_emi)
		THEN
			LET int_flag = 1
			EXIT INPUT
		END IF
		LET int_flag = 0
		CALL fl_mensaje_abandonar_proceso() RETURNING resp
		IF resp = 'Yes' THEN
			LET int_flag = 1
			EXIT INPUT
		END IF
       	ON KEY(F1,CONTROL-W)
		CALL llamar_visor_teclas()
	BEFORE INPUT
		--#CALL dialog.keysetlabel("F1","")
		--#CALL dialog.keysetlabel("CONTROL-W","")
	BEFORE FIELD j14_autorizacion
		IF rm_j14.j14_autorizacion IS NULL THEN
			DECLARE q_aut CURSOR FOR
				SELECT autorizacion
					FROM tmp_ret
			OPEN q_aut
			FETCH q_aut INTO rm_j14.j14_autorizacion
			DISPLAY BY NAME rm_j14.j14_autorizacion
			CLOSE q_aut
			FREE q_aut
		END IF
	BEFORE FIELD j14_fecha_emi
		LET fecha = rm_j14.j14_fecha_emi
	AFTER FIELD j14_num_ret_sri
		IF LENGTH(rm_j14.j14_num_ret_sri) < 14 THEN
			CALL fl_mostrar_mensaje('El número del documento ingresado es incorrecto.', 'exclamation')
			NEXT FIELD j14_num_ret_sri
		END IF
		IF rm_j14.j14_num_ret_sri[4, 4] <> '-' OR
		   rm_j14.j14_num_ret_sri[8, 8] <> '-'
		THEN
			CALL fl_mostrar_mensaje('Faltan los guiones.', 'exclamation')
			NEXT FIELD j14_num_ret_sri
		END IF
		IF rm_j14.j14_num_ret_sri[1, 3] = '000' OR
		   rm_j14.j14_num_ret_sri[5, 7] = '000'
		THEN
			CALL fl_mostrar_mensaje('Los prefijos son incorrectos. No pueden ser 000.', 'exclamation')
			NEXT FIELD j14_num_ret_sri
		END IF
		IF LENGTH(rm_j14.j14_num_ret_sri[1, 7]) <> 7 THEN
			CALL fl_mostrar_mensaje('Digite correctamente el punto de venta o el punto de emision.', 'exclamation')
			NEXT FIELD j14_num_ret_sri
		END IF
		{--
		LET lim = LENGTH(rm_j14.j14_num_ret_sri)
		IF NOT fl_solo_numeros(rm_j14.j14_num_ret_sri[9, lim]) THEN
			CALL fl_mostrar_mensaje('Digite solo numeros para el numero del comprobante.', 'exclamation')
			NEXT FIELD j14_num_ret_sri
		END IF
		--}
		IF NOT fl_valida_numeros(rm_j14.j14_num_ret_sri[1, 3]) THEN
			NEXT FIELD j14_num_ret_sri
		END IF
		IF NOT fl_valida_numeros(rm_j14.j14_num_ret_sri[5, 7]) THEN
			NEXT FIELD j14_num_ret_sri
		END IF
		LET lim = LENGTH(rm_j14.j14_num_ret_sri)
		IF NOT fl_valida_numeros(rm_j14.j14_num_ret_sri[9, lim]) THEN
			NEXT FIELD j14_num_ret_sri
		END IF
		IF num_ret IS NULL OR num_ret <> rm_j14.j14_num_ret_sri THEN
			CALL lee_num_retencion(rm_j14.j14_num_ret_sri)
				RETURNING r_j14.*
			IF r_j14.j14_compania IS NOT NULL THEN
				CALL fl_mostrar_mensaje('Este numero de retencion ya ha sido ingresado.', 'exclamation')
				NEXT FIELD j14_num_ret_sri
			END IF
		END IF
	AFTER FIELD j14_autorizacion
		IF LENGTH(rm_j14.j14_autorizacion) <> 10 THEN
			CALL fl_mostrar_mensaje('El numero de la autorizacion ingresado es incorrecto.', 'exclamation')
			NEXT FIELD j14_autorizacion
		END IF
		IF rm_j14.j14_autorizacion[1, 1] <> '1' THEN
			CALL fl_mostrar_mensaje('Numero de Autorizacion es incorrecto.', 'exclamation')
			NEXT FIELD j14_autorizacion
		END IF
		IF NOT fl_valida_numeros(rm_j14.j14_autorizacion) THEN
			NEXT FIELD j14_autorizacion
		END IF
	AFTER FIELD j14_fecha_emi
		IF rm_j14.j14_fecha_emi IS NULL THEN
			LET rm_j14.j14_fecha_emi = fecha
			DISPLAY BY NAME rm_j14.j14_fecha_emi
		END IF
		IF tipo_llamada = 'I' THEN
			IF rm_j14.j14_fecha_emi < TODAY THEN
				CALL fl_mostrar_mensaje('La fecha de emision del comprobante no puede ser menor que la fecha de hoy.', 'exclamation')
				NEXT FIELD j14_fecha_emi
			END IF
		ELSE
			IF rm_j14.j14_fecha_emi < fec_emi THEN
				LET mensaje = 'La fecha de emision del ',
						'comprobante no puede ser ',
						'menor que la fecha del ',
						fec_emi USING "dd-mm-yyyy", '.'
				CALL fl_mostrar_mensaje(mensaje, 'exclamation')
				NEXT FIELD j14_fecha_emi
			END IF
		END IF
		LET fecha_min  = DATE(rm_j10.j10_fecha_pro)
		LET dias_tope  = 45
		--LET fecha_tope = fecha_min + (dias_tope + 1) UNITS DAY
		LET fecha_tope = (MDY(MONTH(fecha_min), 01, YEAR(fecha_min))
				+ 1 UNITS MONTH - 1 UNITS DAY)
				+ (dias_tope + 1) UNITS DAY
		IF rm_j14.j14_fecha_emi < fecha_min THEN
			LET mensaje = 'La fecha de emision del comprobante no',
					' puede ser menor que la fecha de',
					' factura (',
					fecha_min USING "dd-mm-yyyy", ').'
			CALL fl_mostrar_mensaje(mensaje, 'exclamation')
			NEXT FIELD j14_fecha_emi
		END IF
		IF (MDY(MONTH(fecha_min), 01, YEAR(fecha_min)) + 1 UNITS MONTH
			- 1 UNITS DAY) < (TODAY - (dias_tope + 1) UNITS DAY)
		THEN
			LET mensaje = 'No se puede cargar retenciones a una ',
					'factura con fecha de mas de ',
					dias_tope + 1 USING "<<&", ' dias.'
			CALL fl_mostrar_mensaje(mensaje, 'exclamation')
			NEXT FIELD j14_fecha_emi
		END IF
		IF rm_j14.j14_fecha_emi > fecha_tope THEN
			LET mensaje = 'La fecha de emision del comprobante no',
					' puede ser mayor que la fecha ',
					fecha_tope USING "dd-mm-yyyy", '.'
			CALL fl_mostrar_mensaje(mensaje, 'exclamation')
			NEXT FIELD j14_fecha_emi
		END IF
END INPUT

END FUNCTION



FUNCTION lee_detalle_ret(codigo_pago, posi, valor_fact)
DEFINE codigo_pago	LIKE cajt001.j01_codigo_pago
DEFINE posi		SMALLINT
DEFINE valor_fact	DECIMAL(14,2)
DEFINE r_z09		RECORD LIKE cxct009.*
DEFINE r_c02		RECORD LIKE ordt002.*
DEFINE r_c03		RECORD LIKE ordt003.*
DEFINE base_imp		LIKE cajt014.j14_base_imp
DEFINE resp		CHAR(6)
DEFINE i, j, l, k	SMALLINT
DEFINE salir, flag_c	SMALLINT
DEFINE max_row, resul	SMALLINT

IF vm_num_ret > 0 THEN
	CALL calcular_tot_retencion(vm_num_ret)
ELSE
	LET vm_num_ret = 1
END IF
LET salir    = 0
LET int_flag = 0
CALL set_count(vm_num_ret)
INPUT ARRAY rm_detret WITHOUT DEFAULTS FROM rm_detret.*
	ON KEY(INTERRUPT)
		LET int_flag = 0
		CALL fl_mensaje_abandonar_proceso() RETURNING resp
		IF resp = 'Yes' THEN
			LET int_flag = 1
			EXIT INPUT
		END IF
       	ON KEY(F1,CONTROL-W)
		CALL llamar_visor_teclas()
	ON KEY(F2)
		IF INFIELD(j14_porc_ret) THEN
			CALL fl_ayuda_retenciones(vg_codcia, codigo_pago, 'A')
				RETURNING r_c02.c02_tipo_ret,
					  r_c02.c02_porcentaje, r_c02.c02_nombre
			IF r_c02.c02_tipo_ret IS NOT NULL THEN
				LET rm_detret[i].j14_tipo_ret =
							r_c02.c02_tipo_ret
				LET rm_detret[i].j14_porc_ret =
							r_c02.c02_porcentaje
				IF rm_detret[i].j14_codigo_sri IS NULL THEN
					CALL codigo_sri_defecto(vg_codcia,
						rm_j10.j10_codcli,
						rm_detret[i].j14_tipo_ret,
						rm_detret[i].j14_porc_ret)
					RETURNING rm_detret[i].j14_codigo_sri
				END IF
				CALL fl_lee_codigos_sri(vg_codcia,
						rm_detret[i].j14_tipo_ret,
						rm_detret[i].j14_porc_ret,
						rm_detret[i].j14_codigo_sri,
						fec_ini_por[i])
					RETURNING r_c03.*
				LET rm_detret[i].c03_concepto_ret =
							r_c03.c03_concepto_ret
				DISPLAY rm_detret[i].* TO rm_detret[j].*
			END IF
		END IF
		IF INFIELD(j14_codigo_sri) THEN
			CALL fl_ayuda_codigos_sri(vg_codcia,
					rm_detret[i].j14_tipo_ret,
					rm_detret[i].j14_porc_ret, 'A',
					rm_j10.j10_codcli, 'C')
				RETURNING r_c03.c03_codigo_sri,
					  r_c03.c03_concepto_ret,
					  r_c03.c03_fecha_ini_porc
			IF r_c03.c03_codigo_sri IS NOT NULL THEN
				LET rm_detret[i].j14_codigo_sri =
							r_c03.c03_codigo_sri
				LET fec_ini_por[i] = r_c03.c03_fecha_ini_porc
				LET rm_detret[i].c03_concepto_ret =
							r_c03.c03_concepto_ret
				DISPLAY rm_detret[i].* TO rm_detret[j].*
			END IF
		END IF
		LET int_flag = 0
	ON KEY(F5)
		LET int_flag = 0
		EXIT INPUT
	BEFORE INPUT
		--#CALL dialog.keysetlabel("F1","")
		--#CALL dialog.keysetlabel("CONTROL-W","")
		--#CALL dialog.keysetlabel("F5","Cabecera")
	BEFORE ROW
		LET i = arr_curr()
		LET j = scr_line()
		LET max_row = arr_count()
		IF i > max_row THEN
			LET max_row = max_row + 1
		END IF
		CALL muestra_contadores_det(i, max_row)
		CALL calcular_tot_retencion(max_row)
	AFTER FIELD j14_porc_ret
		SELECT UNIQUE j91_tipo_ret
			INTO rm_detret[i].j14_tipo_ret
			FROM cajt091
			WHERE j91_compania    = vg_codcia
			  AND j91_codigo_pago = codigo_pago
			  AND j91_cont_cred   = 'C'
		IF rm_detret[i].j14_porc_ret IS NOT NULL THEN
			CALL fl_lee_tipo_retencion(vg_codcia,
						rm_detret[i].j14_tipo_ret,
						rm_detret[i].j14_porc_ret)
				RETURNING r_c02.*
			IF r_c02.c02_compania IS NULL THEN
				CALL fl_mostrar_mensaje('No existe configurado este porcentaje de retencion.', 'exclamation')
				NEXT FIELD j14_porc_ret
			END IF
			IF r_c02.c02_estado <> 'A' THEN
				CALL fl_mostrar_mensaje('El porcentaje de retencion esta bloqueado.', 'exclamation')
				NEXT FIELD j14_porc_ret
			END IF
			IF rm_detret[i].j14_codigo_sri IS NULL THEN
				CALL codigo_sri_defecto(vg_codcia,
						rm_j10.j10_codcli,
						rm_detret[i].j14_tipo_ret,
						rm_detret[i].j14_porc_ret)
					RETURNING rm_detret[i].j14_codigo_sri
			END IF
			CALL fl_lee_codigos_sri(vg_codcia,
						rm_detret[i].j14_tipo_ret,
						rm_detret[i].j14_porc_ret,
						rm_detret[i].j14_codigo_sri,
						fec_ini_por[i])
				RETURNING r_c03.*
			LET rm_detret[i].c03_concepto_ret =
							r_c03.c03_concepto_ret
			DISPLAY rm_detret[i].* TO rm_detret[j].*
		ELSE
			LET rm_detret[i].j14_tipo_ret = NULL
		END IF
		DISPLAY rm_detret[i].j14_tipo_ret TO rm_detret[j].j14_tipo_ret
	AFTER FIELD j14_codigo_sri
		IF rm_detret[i].j14_codigo_sri IS NOT NULL THEN
			CALL fl_lee_codigos_sri(vg_codcia,
						rm_detret[i].j14_tipo_ret,
						rm_detret[i].j14_porc_ret,
						rm_detret[i].j14_codigo_sri,
						fec_ini_por[i])
				RETURNING r_c03.*
			IF r_c03.c03_compania IS NULL THEN
				CALL fl_mostrar_mensaje('No existe configurado este codigo del SRI.', 'exclamation')
				NEXT FIELD j14_codigo_sri
			END IF
			IF r_c03.c03_estado <> 'A' THEN
				CALL fl_mostrar_mensaje('El codigo del SRI esta bloqueado.', 'exclamation')
				NEXT FIELD j14_codigo_sri
			END IF
			LET rm_detret[i].c03_concepto_ret =
							r_c03.c03_concepto_ret
			IF NOT tiene_aux_cont_retencion(codigo_pago, 'C', 0)
			THEN
				CALL fl_lee_det_retencion_cli(vg_codcia,
						rm_j10.j10_codcli,
						rm_detret[i].j14_tipo_ret,
						rm_detret[i].j14_porc_ret,
						rm_detret[i].j14_codigo_sri,
						fec_ini_por[i],codigo_pago, 'C')
					RETURNING r_z09.*
				IF r_z09.z09_aux_cont IS NULL THEN
					CALL fl_mostrar_mensaje('No existe auxiliar contable para este codigo de SRI en este tipo de retencion.', 'exclamation')
					NEXT FIELD j14_codigo_sri
				END IF
			END IF
		ELSE
			LET rm_detret[i].c03_concepto_ret = NULL
		END IF
		DISPLAY rm_detret[i].c03_concepto_ret TO
			rm_detret[j].c03_concepto_ret
		LET flag_c = 0
		IF rm_detret[i].j14_base_imp <> base_imp THEN
			LET flag_c = 1
		END IF
		CALL calcular_retencion(i, j, flag_c)
		CALL calcular_tot_retencion(max_row)
	AFTER FIELD j14_base_imp
		LET flag_c = 0
		IF rm_detret[i].j14_base_imp <> base_imp THEN
			LET flag_c = 1
		END IF
		CALL calcular_retencion(i, j, flag_c)
		CALL calcular_tot_retencion(max_row)
	AFTER FIELD j14_valor_ret
		CALL calcular_retencion(i, j, 0)
		CALL calcular_tot_retencion(max_row)
	AFTER DELETE
		LET max_row = max_row - 1
		IF max_row <= 0 THEN
			LET max_row = 1
		END IF
		CALL calcular_tot_retencion(max_row)
	AFTER INPUT
		LET vm_num_ret = arr_count()
		CALL calcular_tot_retencion(vm_num_ret)
		FOR l = 1 TO vm_num_ret - 1
			FOR k = l + 1 TO vm_num_ret
				IF (rm_detret[l].j14_tipo_ret =
				    rm_detret[k].j14_tipo_ret) AND
				   (rm_detret[l].j14_porc_ret =
				    rm_detret[k].j14_porc_ret) AND
				   (rm_detret[l].j14_codigo_sri =
				    rm_detret[k].j14_codigo_sri) AND
				   (fec_ini_por[l] = fec_ini_por[k])
				THEN
					CALL fl_mostrar_mensaje('Existen un mismo tipo de porcentaje y codigo del SRI mas de una vez en el detalle.', 'exclamation')
					CONTINUE INPUT
				END IF
			END FOR
		END FOR
		IF tot_base_imp > valor_fact THEN
			CALL fl_mostrar_mensaje('El total de la base imponible no puede ser mayor que el valor de la factura.', 'exclamation')
			CONTINUE INPUT
		END IF
		IF tot_valor_ret > rm_detalle[posi].j11_valor THEN
			CALL fl_mostrar_mensaje('El total del valor de retencion no puede ser mayor que el valor de retencion cargado a la factura.', 'exclamation')
			CONTINUE INPUT
		END IF
		LET resul = 0
		FOR l = 1 TO vm_num_ret
			IF rm_detret[l].j14_codigo_sri IS NULL OR
			   fec_ini_por[l] IS NULL
			THEN
				LET resul = 1
				EXIT FOR
			END IF
		END FOR
		IF resul THEN
			CONTINUE INPUT
		END IF
		LET salir = 1
END INPUT
RETURN salir

END FUNCTION



FUNCTION calcular_retencion(i, j, flag)
DEFINE i, j, flag	SMALLINT

IF rm_detret[i].j14_valor_ret IS NOT NULL AND NOT flag THEN
	RETURN
END IF
IF rm_detret[i].j14_valor_ret > 0 AND NOT flag THEN
	RETURN
END IF
LET rm_detret[i].j14_valor_ret = rm_detret[i].j14_base_imp *
				(rm_detret[i].j14_porc_ret / 100)
DISPLAY rm_detret[i].j14_base_imp  TO rm_detret[i].j14_base_imp
DISPLAY rm_detret[i].j14_valor_ret TO rm_detret[i].j14_valor_ret

END FUNCTION



FUNCTION calcular_tot_retencion(lim)
DEFINE i, lim		SMALLINT

LET tot_base_imp  = 0
LET tot_valor_ret = 0
FOR i = 1 TO lim
	LET tot_base_imp  = tot_base_imp  + rm_detret[i].j14_base_imp
	LET tot_valor_ret = tot_valor_ret + rm_detret[i].j14_valor_ret
END FOR
DISPLAY BY NAME tot_base_imp, tot_valor_ret

END FUNCTION



FUNCTION lee_num_retencion(num_ret)
DEFINE num_ret		LIKE cajt014.j14_num_ret_sri
DEFINE r_j14		RECORD LIKE cajt014.*
DEFINE query		CHAR(600)
DEFINE expr_cli		VARCHAR(100)

INITIALIZE r_j14.* TO NULL
LET expr_cli = NULL
IF rm_par.codcli IS NOT NULL THEN
	LET expr_cli = '   AND j10_codcli       = ', rm_par.codcli
END IF
LET query = 'SELECT cajt014.* ',
		' FROM cajt014, cajt010 ',
		' WHERE j14_compania     = ', vg_codcia,
		'   AND j14_localidad    = ', vg_codloc,
		'   AND j14_tipo_fuente  = "', rm_par.tipo_fuente, '"',
		'   AND j14_num_ret_sri  = "', num_ret CLIPPED, '"',
		'   AND j10_compania     = j14_compania ',
		'   AND j10_localidad    = j14_localidad ',
		'   AND j10_tipo_fuente  = j14_tipo_fuente ',
		'   AND j10_num_fuente   = j14_num_fuente ',
		expr_cli CLIPPED
PREPARE cons_j14 FROM query
DECLARE q_j14 CURSOR FOR cons_j14
OPEN q_j14
FETCH q_j14 INTO r_j14.*
CLOSE q_j14
FREE q_j14
RETURN r_j14.*

END FUNCTION



FUNCTION registros_retenciones(codigo_pago)
DEFINE codigo_pago	LIKE cajt001.j01_codigo_pago
DEFINE cuantos		INTEGER

SELECT COUNT(*) INTO cuantos FROM tmp_ret WHERE cod_pago = codigo_pago
RETURN cuantos

END FUNCTION



FUNCTION tiene_aux_cont_retencion(codigo_pago, cont_cred, flag)
DEFINE codigo_pago	LIKE cajt001.j01_codigo_pago
DEFINE cont_cred	LIKE cajt001.j01_cont_cred
DEFINE flag		SMALLINT
DEFINE r_b10		RECORD LIKE ctbt010.*
DEFINE r_b42		RECORD LIKE ctbt042.*
DEFINE r_j01		RECORD LIKE cajt001.*
DEFINE r_j91		RECORD LIKE cajt091.*
DEFINE tipo_ret		LIKE cajt091.j91_tipo_ret
DEFINE porc_ret		LIKE cajt091.j91_porcentaje
DEFINE resul		SMALLINT

INITIALIZE r_b42.* TO NULL
SELECT * INTO r_b42.*
	FROM ctbt042
	WHERE b42_compania    = vg_codcia
	  AND b42_localidad   = vg_codloc
CALL fl_lee_cuenta(r_b42.b42_compania, r_b42.b42_retencion) RETURNING r_b10.*
LET resul = 1
IF vg_codloc = 2 OR vg_codloc = 4 THEN
	RETURN resul
END IF
IF r_b10.b10_compania IS NULL THEN
	SELECT UNIQUE j91_tipo_ret
		INTO tipo_ret
		FROM cajt091
		WHERE j91_compania    = vg_codcia
		  AND j91_codigo_pago = codigo_pago
		  AND j91_cont_cred   = cont_cred
	CALL fl_lee_det_tipo_ret_caja(vg_codcia, codigo_pago, cont_cred,
					tipo_ret, porc_ret)
		RETURNING r_j91.*
	IF r_j91.j91_aux_cont IS NULL THEN
		CALL fl_lee_tipo_pago_caja(vg_codcia, codigo_pago,
						cont_cred)
			RETURNING r_j01.*
		IF r_j01.j01_aux_cont IS NULL THEN
			LET resul = 0
		END IF
	END IF
END IF
IF NOT resul AND flag THEN
	CALL fl_mostrar_mensaje('No existen auxiliares contables para este tipo de forma de pago. LLAME AL ADMINISTRADOR.', 'exclamation')
END IF
RETURN resul

END FUNCTION



FUNCTION codigo_sri_defecto(codcia, codcli, tipo_ret, porc_ret)
DEFINE codcia		LIKE cxct008.z08_compania
DEFINE codcli		LIKE cxct008.z08_codcli
DEFINE tipo_ret		LIKE cxct008.z08_tipo_ret
DEFINE porc_ret		LIKE cxct008.z08_porcentaje
DEFINE cod_sri		LIKE cxct008.z08_codigo_sri
DEFINE query		CHAR(1000)

INITIALIZE cod_sri TO NULL
LET query = 'SELECT c03_codigo_sri, ',
		' CASE WHEN z08_codcli IS NOT NULL ',
			' THEN "S" ',
			' ELSE "N" ',
		' END defecto ',
		' FROM ordt003, OUTER cxct008 ',
		' WHERE c03_compania   = ', codcia,
		'   AND c03_tipo_ret   = "', tipo_ret, '"',
		'   AND c03_porcentaje = ', porc_ret,
		'   AND c03_estado     = "A"',
		'   AND z08_compania   = c03_compania ',
		'   AND z08_codcli     = ', codcli,
		'   AND z08_tipo_ret   = c03_tipo_ret ',
		'   AND z08_porcentaje = c03_porcentaje ',
		'   AND z08_codigo_sri = c03_codigo_sri ',
		'   AND z08_fecha_ini_porc = c03_fecha_ini_porc ',
		' INTO TEMP t1 '
PREPARE exec_t1 FROM query
EXECUTE exec_t1
DECLARE q_sri2 CURSOR FOR
	SELECT c03_codigo_sri
		FROM t1 WHERE defecto = "S"
OPEN q_sri2
FETCH q_sri2 INTO cod_sri
CLOSE q_sri2
FREE q_sri2
DROP TABLE t1
RETURN cod_sri

END FUNCTION



FUNCTION grabar_detalle_retencion(codigo_pago, posi, tipo_llamada)
DEFINE codigo_pago	LIKE cajt001.j01_codigo_pago
DEFINE posi		SMALLINT
DEFINE tipo_llamada	CHAR(1)
DEFINE i		SMALLINT
DEFINE mensaje		CHAR(300)
DEFINE varusu		VARCHAR(100)
DEFINE resp		CHAR(6)
DEFINE cuantos		INTEGER
DEFINE valor		DECIMAL(12,2)
DEFINE r_j14		RECORD LIKE cajt014.*
DEFINE r_z01		RECORD LIKE cxct001.*
DEFINE r_r19		RECORD LIKE rept019.*
DEFINE r_t23		RECORD LIKE talt023.*
DEFINE usuario		LIKE gent005.g05_usuario
DEFINE codloc		LIKE rept019.r19_localidad
DEFINE cod_tran		LIKE rept019.r19_cod_tran
DEFINE num_tran		LIKE rept019.r19_num_tran

IF registros_retenciones(codigo_pago) = 0 THEN
	RETURN
END IF
DECLARE q_ret2 CURSOR FOR
	SELECT num_ret_sri, autorizacion, fecha_emi, tipo_ret, porc_ret,
		codigo_sri, concepto_ret, base_imp, valor_ret, fec_ini_porc
		FROM tmp_ret
		WHERE cod_pago = codigo_pago
SELECT j14_sec_ret sec_r, j14_num_fact_sri num_fr, j14_fec_emi_fact fec_ef,
	j14_tipo_fue tf, j14_num_tran num_t
	FROM cajt014
	WHERE j14_compania    = vg_codcia
	  AND j14_localidad   = rm_j10.j10_localidad
	  AND j14_tipo_fuente = rm_j10.j10_tipo_fuente
	  AND j14_num_fuente  = rm_j10.j10_num_fuente
	  AND j14_codigo_pago = rm_detalle[posi].j11_codigo_pago
	  AND j14_num_ret_sri = rm_detalle[posi].j11_num_ch_aut
	INTO TEMP tmp_t1
IF tipo_llamada = 'M' THEN
	SET LOCK MODE TO WAIT 1
	WHENEVER ERROR CONTINUE
	WHILE TRUE
		DELETE FROM cajt014
			WHERE j14_compania    = vg_codcia
			  AND j14_localidad   = rm_j10.j10_localidad
			  AND j14_tipo_fuente = rm_j10.j10_tipo_fuente
			  AND j14_num_fuente  = rm_j10.j10_num_fuente
			  AND j14_codigo_pago = rm_detalle[posi].j11_codigo_pago
			  AND j14_num_ret_sri = rm_detalle[posi].j11_num_ch_aut
		IF STATUS = 0 THEN
			EXIT WHILE
		END IF
		DECLARE q_blo2 CURSOR FOR
			SELECT UNIQUE s.username
				FROM sysmaster:syslocks l,
					sysmaster:syssessions s
				WHERE type    = "U"
				  AND sid     <> DBINFO('sessionid')
				  AND owner   = sid
				  AND tabname = 'cajt014'
				  AND rowidlk =
				(SELECT ROWID FROM cajt014
				WHERE j14_compania    = vg_codcia
				  AND j14_localidad   = vg_codloc
				  AND j14_tipo_fuente = rm_j10.j10_tipo_fuente
				  AND j14_num_fuente  = rm_j10.j10_num_fuente
				  AND j14_codigo_pago =
						rm_detalle[posi].j11_codigo_pago
				  AND j14_num_ret_sri  =
						rm_detalle[posi].j11_num_ch_aut)
		LET varusu = NULL
		FOREACH q_blo2 INTO usuario
			IF varusu IS NULL THEN
				LET varusu = UPSHIFT(usuario) CLIPPED
			ELSE
				LET varusu = varusu CLIPPED, ' ',
						UPSHIFT(usuario) CLIPPED
			END IF
		END FOREACH
		LET mensaje = 'La factura ', rm_j10.j10_tipo_destino CLIPPED,
				'-', rm_j10.j10_num_destino USING "<<<<<<&",
			' esta siendo bloqueado por el usuario ',varusu CLIPPED,
			'. Desea intentar nuevamente con la actualizacion',
			'de la Factura ?'
		CALL fl_hacer_pregunta(mensaje, 'Yes') RETURNING resp
		IF resp = 'Yes' THEN
			CONTINUE WHILE
		END IF
		ROLLBACK WORK
		WHENEVER ERROR STOP
		LET mensaje = 'No se ha podido actualizar el numero de la',
				' retencion. Esta bloqueado por el usuario ',
			UPSHIFT(usuario) CLIPPED, '. LLAME AL ADMINISTRADOR.'
		CALL fl_mostrar_mensaje(mensaje, 'stop')
		EXIT PROGRAM
	END WHILE
	WHENEVER ERROR STOP
	SET LOCK MODE TO NOT WAIT
END IF
LET i = 1
FOREACH q_ret2 INTO r_j14.j14_num_ret_sri, r_j14.j14_autorizacion,
			r_j14.j14_fecha_emi, rm_detret[i].*, fec_ini_por[i]
	LET r_j14.j14_compania     = vg_codcia
	LET r_j14.j14_localidad    = rm_j10.j10_localidad
	LET r_j14.j14_tipo_fuente  = rm_j10.j10_tipo_fuente
	LET r_j14.j14_num_fuente   = rm_j10.j10_num_fuente
	LET r_j14.j14_secuencia    = rm_adi[posi].j11_secuencia
	LET r_j14.j14_codigo_pago  = codigo_pago
	LET r_j14.j14_sec_ret      = i
	CALL fl_lee_cliente_general(rm_j10.j10_codcli) RETURNING r_z01.*
	LET r_j14.j14_cedruc       = r_z01.z01_num_doc_id
	LET r_j14.j14_razon_social = rm_j10.j10_nomcli
	CALL datos_factura()
		RETURNING cuantos, codloc, cod_tran, num_tran, valor
	IF cod_tran IS NOT NULL THEN
		CASE rm_j10.j10_areaneg
			WHEN 1
				CALL lee_factura_inv(vg_codcia, codloc,
							cod_tran, num_tran)
					RETURNING r_r19.*
				CALL obtener_num_sri('PR', r_r19.r19_num_tran,0)
					RETURNING r_j14.j14_num_fact_sri
				LET r_j14.j14_fec_emi_fact =
							DATE(r_r19.r19_fecing)
			WHEN 2
				CALL fl_lee_orden_trabajo(vg_codcia, vg_codloc,
							rm_j10.j10_num_fuente)
					RETURNING r_t23.*
				CALL obtener_num_sri('OT',r_t23.t23_num_factura,
							0)
					RETURNING r_j14.j14_num_fact_sri
				LET r_j14.j14_fec_emi_fact =
						DATE(r_t23.t23_fec_factura)
		END CASE
	ELSE
		SELECT num_fr, fec_ef
			INTO r_j14.j14_num_fact_sri, r_j14.j14_fec_emi_fact
			FROM tmp_t1
			WHERE sec_r = r_j14.j14_sec_ret
	END IF
	LET r_j14.j14_tipo_ret     = rm_detret[i].j14_tipo_ret
	LET r_j14.j14_porc_ret     = rm_detret[i].j14_porc_ret
	LET r_j14.j14_codigo_sri   = rm_detret[i].j14_codigo_sri
	LET r_j14.j14_fec_ini_porc = fec_ini_por[i]
	LET r_j14.j14_base_imp     = rm_detret[i].j14_base_imp
	LET r_j14.j14_valor_ret    = rm_detret[i].j14_valor_ret
	IF rm_j10.j10_tipo_fuente <> 'SC' THEN
		CASE rm_j10.j10_areaneg
			WHEN 1 LET r_j14.j14_cont_cred = r_r19.r19_cont_cred
			WHEN 2 LET r_j14.j14_cont_cred = r_t23.t23_cont_cred
		END CASE
	ELSE
		LET r_j14.j14_cont_cred = 'R'
		SELECT tf, num_t
			INTO r_j14.j14_tipo_fue, r_j14.j14_num_tran
			FROM tmp_t1
			WHERE sec_r = r_j14.j14_sec_ret
	END IF
	LET r_j14.j14_tipo_doc = 'FA'
	IF r_z01.z01_tipo_doc_id <> 'R' THEN
		LET r_j14.j14_tipo_doc = 'NV'
	END IF
	IF rm_j10.j10_tipo_fuente <> 'SC' THEN
		LET r_j14.j14_tipo_fue = rm_par.tipo_fuente
		CASE rm_j10.j10_areaneg
			WHEN 1 LET r_j14.j14_num_tran = r_r19.r19_num_tran
			WHEN 2 LET r_j14.j14_num_tran = r_t23.t23_num_factura
		END CASE
	END IF
	LET r_j14.j14_cod_tran     = vm_cod_tran
	CASE rm_j10.j10_areaneg
		WHEN 1
			SELECT r40_tipo_comp, r40_num_comp
				INTO r_j14.j14_tipo_comp, r_j14.j14_num_comp
				FROM rept040, ctbt012
				WHERE r40_compania  = vg_codcia
				  AND r40_localidad = vg_codloc
				  AND r40_cod_tran  = r_r19.r19_cod_tran
				  AND r40_num_tran  = r_r19.r19_num_tran
				  AND b12_compania  = r40_compania
				  AND b12_tipo_comp = r40_tipo_comp
				  AND b12_num_comp  = r40_num_comp
				  AND b12_subtipo   = 8
		WHEN 2
			SELECT t50_tipo_comp, t50_num_comp
				INTO r_j14.j14_tipo_comp, r_j14.j14_num_comp
				FROM talt050, ctbt012
				WHERE t50_compania  = vg_codcia
				  AND t50_localidad = vg_codloc
				  AND t50_orden     = r_t23.t23_orden
				  AND t50_factura   = r_t23.t23_num_factura
				  AND b12_compania  = t50_compania
				  AND b12_tipo_comp = t50_tipo_comp
				  AND b12_num_comp  = t50_num_comp
				  AND b12_subtipo   = 41
	END CASE
	LET r_j14.j14_usuario      = vg_usuario
	LET r_j14.j14_fecing       = CURRENT
	INSERT INTO cajt014 VALUES (r_j14.*)
	LET i = i + 1
END FOREACH
DROP TABLE tmp_t1
SET LOCK MODE TO WAIT 1
WHENEVER ERROR CONTINUE
WHILE TRUE
	UPDATE cajt011
		SET j11_num_ch_aut = r_j14.j14_num_ret_sri
		WHERE j11_compania    = vg_codcia
		  AND j11_localidad   = vg_codloc
		  AND j11_tipo_fuente = rm_j10.j10_tipo_fuente
		  AND j11_num_fuente  = rm_j10.j10_num_fuente
		  AND j11_codigo_pago = rm_detalle[posi].j11_codigo_pago
		  AND j11_num_ch_aut  = rm_detalle[posi].j11_num_ch_aut
	IF STATUS = 0 THEN
		EXIT WHILE
	END IF
	DECLARE q_blo CURSOR FOR
		SELECT UNIQUE s.username
			FROM sysmaster:syslocks l, sysmaster:syssessions s
			WHERE type    = "U"
			  AND sid     <> DBINFO('sessionid')
			  AND owner   = sid
			  AND tabname = 'cajt011'
			  AND rowidlk =
			(SELECT ROWID FROM cajt011
				WHERE j11_compania    = vg_codcia
				  AND j11_localidad   = vg_codloc
				  AND j11_tipo_fuente = rm_j10.j10_tipo_fuente
				  AND j11_num_fuente  = rm_j10.j10_num_fuente
				  AND j11_codigo_pago =
						rm_detalle[posi].j11_codigo_pago
				  AND j11_num_ch_aut  =
						rm_detalle[posi].j11_num_ch_aut)
	LET varusu = NULL
	FOREACH q_blo INTO usuario
		IF varusu IS NULL THEN
			LET varusu = UPSHIFT(usuario) CLIPPED
		ELSE
			LET varusu = varusu CLIPPED, ' ',
					UPSHIFT(usuario) CLIPPED
		END IF
	END FOREACH
	LET mensaje = 'La factura ', rm_j10.j10_tipo_destino CLIPPED, '-',
			rm_j10.j10_num_destino USING "<<<<<<&",
			' esta siendo bloqueado por el usuario ',varusu CLIPPED,
			'. Desea intentar nuevamente con la actualizacion',
			'de la Factura ?'
	CALL fl_hacer_pregunta(mensaje, 'Yes') RETURNING resp
	IF resp = 'Yes' THEN
		CONTINUE WHILE
	END IF
	ROLLBACK WORK
	WHENEVER ERROR STOP
	LET mensaje = 'No se ha podido actualizar el numero de la retencion.',
			' Esta bloqueado por el usuario ',
			UPSHIFT(usuario) CLIPPED, '. LLAME AL ADMINISTRADOR.'
	CALL fl_mostrar_mensaje(mensaje, 'stop')
	EXIT PROGRAM
END WHILE
WHENEVER ERROR STOP
SET LOCK MODE TO NOT WAIT
UPDATE tmp_det
	SET j11_num_ch_aut = r_j14.j14_num_ret_sri
	WHERE j10_num_destino = rm_detalle[posi].j10_num_destino
	  AND j11_codigo_pago = rm_detalle[posi].j11_codigo_pago
	  AND j11_num_ch_aut  = rm_detalle[posi].j11_num_ch_aut
LET rm_detalle[posi].j11_num_ch_aut = r_j14.j14_num_ret_sri
IF tipo_llamada = 'I' THEN
	CALL fl_mostrar_mensaje('Detalle de Retenciones Ingresado OK.', 'info')
ELSE
	CALL fl_mostrar_mensaje('Detalle de Retenciones Modificado OK.', 'info')
END IF

END FUNCTION



{--
FUNCTION control_imprimir()
DEFINE comando		VARCHAR(100)
DEFINE i		SMALLINT

CALL fl_control_reportes() RETURNING comando
IF int_flag THEN
	RETURN
END IF
START REPORT reporte_items TO PIPE comando
FOR i = 1 TO vm_num_rows
	OUTPUT TO REPORT reporte_items(i)
END FOR
FINISH REPORT reporte_items

END FUNCTION



REPORT reporte_items(i)
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
	print ASCII escape;
	print ASCII desact_comp;
	print ASCII escape;
	print ASCII act_10cpi;
	PRINT COLUMN 005, rm_g01.g01_razonsocial,
  	      COLUMN 074, "PAGINA: ", PAGENO USING "&&&"
	PRINT COLUMN 001, modulo CLIPPED,
	      COLUMN 029, "DETALLE DE ITEMS PENDIENTES",
	      COLUMN 074, UPSHIFT(vg_proceso) CLIPPED
	SKIP 1 LINES
	IF rm_par.r10_linea IS NOT NULL THEN
		PRINT COLUMN 005, "** DIVISION: ",
		      COLUMN 025, rm_par.r10_linea CLIPPED,
		      COLUMN 027, rm_par.r03_nombre CLIPPED;
	ELSE
		PRINT 1 SPACES;
	END IF
	IF rm_par.pend_falta = 'S' THEN
		IF rm_par.r10_linea IS NOT NULL THEN
			PRINT COLUMN 059, "PENDIENTES FALTA STOCK"
		ELSE
			PRINT COLUMN 028, "PENDIENTES FALTA STOCK"
		END IF
	ELSE
		PRINT COLUMN 059, 1 SPACES
	END IF
	IF rm_par.r10_sub_linea IS NOT NULL THEN
		PRINT COLUMN 005, "** LINEA   : ",
		      COLUMN 024, rm_par.r10_sub_linea CLIPPED,
		      COLUMN 027, rm_par.r70_desc_sub CLIPPED;
	ELSE
		PRINT 1 SPACES;
	END IF
	IF rm_par.pendientes = 'S' THEN
		IF rm_par.r10_linea IS NOT NULL OR
		   rm_par.r10_sub_linea IS NOT NULL
		THEN
			PRINT COLUMN 066, "SOLO PENDIENTES"
		ELSE
			IF rm_par.pend_falta = 'S' THEN
				PRINT COLUMN 031, "SOLO  PENDIENTES"
			ELSE
				PRINT COLUMN 033, "SOLO PENDIENTES"
			END IF
		END IF
	ELSE
		PRINT COLUMN 066, 1 SPACES
	END IF
	IF rm_par.r10_cod_grupo IS NOT NULL THEN
		PRINT COLUMN 005, "** GRUPO   : ",
		      COLUMN 022, fl_justifica_titulo('D',
						rm_par.r10_cod_grupo, 4),
		      COLUMN 027, rm_par.r71_desc_grupo
	ELSE
		PRINT 1 SPACES
	END IF
	IF rm_par.r10_cod_clase IS NOT NULL THEN
		PRINT COLUMN 005, "** CLASE   : ",
		      COLUMN 018, fl_justifica_titulo('D',
						rm_par.r10_cod_clase, 8),
		      COLUMN 027, rm_par.r72_desc_clase
	ELSE
		PRINT 1 SPACES
	END IF
	IF rm_par.r10_marca IS NOT NULL THEN
		PRINT COLUMN 005, "** MARCA   : ",
		      COLUMN 020, fl_justifica_titulo('D', rm_par.r10_marca, 6),
		      COLUMN 027, rm_par.r73_desc_marca
	ELSE
		PRINT 1 SPACES
	END IF
	SKIP 1 LINES
	PRINT COLUMN 001, "FECHA IMPRESION: ", TODAY USING "dd-mm-yyyy",
 		1 SPACES, TIME,
	      COLUMN 062, usuario
	PRINT "--------------------------------------------------------------------------------"
	PRINT COLUMN 001, "ITEM",
	      COLUMN 009, "D E S C R I P C I O N",
	      COLUMN 033, "STOCK PEN.",
	      COLUMN 044, "STOCK TOTAL",
	      COLUMN 056, "STOCK LOCAL",
	      COLUMN 068, "MAXIMO",
	      COLUMN 075, "MINIMO"
	PRINT "--------------------------------------------------------------------------------"

ON EVERY ROW
	NEED 3 LINES
	PRINT COLUMN 001, rm_item[i].r10_codigo		USING "######",
	      COLUMN 008, rm_item[i].r10_nombre[1, 24],
	      COLUMN 033, rm_item[i].stock_pend		USING "###,##&.##",
	      COLUMN 044, rm_item[i].stock_total	USING "####,##&.##",
	      COLUMN 056, rm_item[i].stock_local	USING "####,##&.##",
	      COLUMN 068, rm_item[i].r10_stock_max	USING "#####&",
	      COLUMN 075, rm_item[i].r10_stock_min	USING "#####&"
	
ON LAST ROW
	NEED 2 LINES
	print ASCII escape;
	print ASCII act_neg;
	PRINT COLUMN 035, "----------",
	      COLUMN 046, "-----------",
	      COLUMN 058, "-----------"
	PRINT COLUMN 020, "TOTALES ==>  ",
	      COLUMN 033, SUM(rm_item[i].stock_pend)	USING "###,##&.##",
	      COLUMN 044, SUM(rm_item[i].stock_total)	USING "####,##&.##",
	      COLUMN 056, SUM(rm_item[i].stock_local)	USING "####,##&.##";
	print ASCII escape;
	print ASCII des_neg;
	print ASCII escape;
	print ASCII act_comp

END REPORT
--}



FUNCTION datos_factura()
DEFINE r_z21		RECORD LIKE cxct021.*
DEFINE r_z22		RECORD LIKE cxct022.*
DEFINE codloc		LIKE rept019.r19_localidad
DEFINE cod_tran		LIKE rept019.r19_cod_tran
DEFINE num_tran		LIKE rept019.r19_num_tran
DEFINE cuantos		INTEGER
DEFINE valor		DECIMAL(12,2)

LET cuantos  = 0
LET codloc   = rm_j10.j10_localidad
LET cod_tran = rm_j10.j10_tipo_destino
LET num_tran = rm_j10.j10_num_destino
IF rm_par.tipo_fuente = 'SC' THEN
	CASE rm_j10.j10_tipo_destino
		WHEN 'PG'
			SELECT COUNT(*)
				INTO cuantos
				FROM cxct023
				WHERE z23_compania  = vg_codcia
				  AND z23_localidad = rm_j10.j10_localidad
				  AND z23_codcli    = rm_j10.j10_codcli
				  AND z23_tipo_trn  = rm_j10.j10_tipo_destino
				  AND z23_num_trn   = rm_j10.j10_num_destino
		WHEN 'PR'
			SELECT COUNT(*)
				INTO cuantos
				FROM cxct021
				WHERE z21_compania  = vg_codcia
				  AND z21_localidad = rm_j10.j10_localidad
				  AND z21_codcli    = rm_j10.j10_codcli
				  AND z21_tipo_doc  = rm_j10.j10_tipo_destino
				  AND z21_num_doc   = rm_j10.j10_num_destino
	END CASE
	IF cuantos = 1 THEN
		CASE rm_j10.j10_tipo_destino
			WHEN 'PG'
				SELECT z23_localidad, z23_tipo_doc, z23_num_doc
					INTO codloc, cod_tran, num_tran
					FROM cxct023
					WHERE z23_compania  = vg_codcia
					  AND z23_localidad =
							rm_j10.j10_localidad
					  AND z23_codcli    = rm_j10.j10_codcli
					  AND z23_tipo_trn  =
							rm_j10.j10_tipo_destino
					  AND z23_num_trn   =
							rm_j10.j10_num_destino
			WHEN 'PR'
				SELECT z23_localidad, z20_cod_tran, z20_num_tran
					INTO codloc, cod_tran, num_tran
					FROM cxct023, cxct020
					WHERE z23_compania  = vg_codcia
					  AND z23_localidad =
							rm_j10.j10_localidad
					  AND z23_codcli    = rm_j10.j10_codcli
					  AND z23_tipo_favor =
							rm_j10.j10_tipo_destino
					  AND z23_doc_favor =
							rm_j10.j10_num_destino
					  AND z20_compania  = z23_compania
					  AND z20_localidad = z23_localidad
					  AND z20_codcli    = z23_codcli
					  AND z20_tipo_doc  = z23_tipo_doc
					  AND z20_num_doc   = z23_num_doc
					  AND z20_dividendo = z23_div_doc
		END CASE
	ELSE
		LET codloc   = NULL
		LET cod_tran = NULL
		LET num_tran = NULL
		LET valor    = NULL
		IF rm_j10.j10_tipo_destino = 'PG' THEN
			CALL fl_lee_transaccion_cxc(vg_codcia,
						rm_j10.j10_localidad,
						rm_j10.j10_codcli,
						rm_j10.j10_tipo_destino,
						rm_j10.j10_num_destino)
				RETURNING r_z22.*
			LET valor = r_z22.z22_total_cap
		END IF
	END IF
END IF
RETURN cuantos, codloc, cod_tran, num_tran, valor

END FUNCTION



FUNCTION lee_factura_inv(codcia, codloc, cod_tran, num_tran)
DEFINE codcia		LIKE rept019.r19_compania
DEFINE codloc		LIKE rept019.r19_localidad
DEFINE cod_tran		LIKE rept019.r19_cod_tran
DEFINE num_tran		LIKE rept019.r19_num_tran
DEFINE r_r19		RECORD LIKE rept019.*

CALL fl_lee_cabecera_transaccion_rep(codcia, codloc, cod_tran, num_tran)
	RETURNING r_r19.*
IF r_r19.r19_compania IS NULL THEN
	CALL lee_cabecera_transaccion_loc(codcia, codloc, cod_tran, num_tran)
		RETURNING r_r19.*
END IF
RETURN r_r19.*

END FUNCTION



FUNCTION lee_cabecera_transaccion_loc(codcia, codloc, cod_tran, num_tran)
DEFINE codcia		LIKE rept019.r19_compania
DEFINE codloc		LIKE rept019.r19_localidad
DEFINE cod_tran		LIKE rept019.r19_cod_tran
DEFINE num_tran		LIKE rept019.r19_num_tran
DEFINE r_r19		RECORD LIKE rept019.*
DEFINE query		CHAR(400)

INITIALIZE r_r19.* TO NULL
IF NOT (codloc = 2 OR codloc = 4) THEN
	RETURN r_r19.*
END IF
IF cod_tran IS NULL AND num_tran IS NULL THEN
	RETURN r_r19.*
END IF
LET query = 'SELECT * FROM ', retorna_base_loc() CLIPPED, 'rept019 ',
		' WHERE r19_compania  = ', codcia,
		'   AND r19_localidad = ', codloc,
		'   AND r19_cod_tran  = "', cod_tran, '"',
		'   AND r19_num_tran  = ', num_tran
PREPARE cons_f_loc FROM query
DECLARE q_cons_f_loc CURSOR FOR cons_f_loc
OPEN q_cons_f_loc
FETCH q_cons_f_loc INTO r_r19.*
CLOSE q_cons_f_loc
FREE q_cons_f_loc
RETURN r_r19.*

END FUNCTION



FUNCTION retorna_base_loc()
DEFINE base_loc		VARCHAR(10)

LET base_loc = NULL
IF NOT (vg_codloc = 2 OR vg_codloc = 4) THEN
	RETURN base_loc CLIPPED
END IF
SELECT g56_base_datos INTO base_loc
	FROM gent056
	WHERE g56_compania  = vg_codcia
	  AND g56_localidad = vg_codloc
IF base_loc IS NOT NULL THEN
	LET base_loc = base_loc CLIPPED, ':'
END IF
RETURN base_loc CLIPPED

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
DISPLAY '<F5>      Ver Factura'              AT a,2
DISPLAY  'F5' AT a,3 ATTRIBUTE(REVERSE)
LET a = a + 1
DISPLAY '<F6>      Retenciones'              AT a,2
DISPLAY  'F6' AT a,3 ATTRIBUTE(REVERSE)
LET a = a + 1
DISPLAY '<F7>      Modificar Retenciones'    AT a,2
DISPLAY  'F7' AT a,3 ATTRIBUTE(REVERSE)
LET a = a + 1
DISPLAY '<F8>      Imprimir'                 AT a,2
DISPLAY  'F8' AT a,3 ATTRIBUTE(REVERSE)
LET a = fgl_getkey()
CLOSE WINDOW w_tf

END FUNCTION
