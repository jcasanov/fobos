--------------------------------------------------------------------------------
-- Titulo           : cxcp206.4gl - Mantenimiento de cheques postfechados 
-- Elaboracion      : 12-dic-2001
-- Autor            : NPC
-- Formato Ejecucion: fglrun cxcp206 base módulo compañía localidad
--			[cliente] [banco] [numero_cuenta] [numero_cheque]
--			[[valor_cheque]] [[fecha_cobro]]
-- Ultima Correccion: 15-ago-2017
-- Motivo Correccion: 
--------------------------------------------------------------------------------
GLOBALS '../../../PRODUCCION/LIBRERIAS/fuentes/globales.4gl'

DEFINE rm_z26			RECORD LIKE cxct026.*
DEFINE vm_num_rows		SMALLINT
DEFINE vm_row_current	SMALLINT
DEFINE vm_max_rows		SMALLINT
DEFINE vm_r_rows		ARRAY[100] OF INTEGER
DEFINE rm_par			RECORD
							z26_codcli		LIKE cxct026.z26_codcli,
							tit_nombre_cli	LIKE cxct001.z01_nomcli,
							z26_banco		LIKE cxct026.z26_banco,
							tit_banco		LIKE gent008.g08_nombre,
							z26_num_cta		LIKE cxct026.z26_num_cta,
							z26_num_cheque	LIKE cxct026.z26_num_cheque,
							z26_valor		LIKE cxct026.z26_valor,
							z26_fecha_cobro	LIKE cxct026.z26_fecha_cobro
						END RECORD
DEFINE rm_detalle		ARRAY[10000] OF RECORD
							z26_tipo_doc		LIKE cxct026.z26_tipo_doc,
							z26_num_doc			LIKE cxct026.z26_num_doc,
							z26_dividendo		LIKE cxct026.z26_dividendo,
							z26_referencia		LIKE cxct026.z26_referencia,
							z20_fecha_vcto		LIKE cxct020.z20_fecha_vcto,
							z20_saldo_cap		LIKE cxct020.z20_saldo_cap,
							valor_che			LIKE cxct020.z20_valor_cap,
							sel_documento		CHAR(1)
						END RECORD
DEFINE rm_adi			ARRAY[10000] OF RECORD
							z20_valor_cap		LIKE cxct020.z20_valor_cap,
							areaneg				LIKE gent003.g03_areaneg
						END RECORD
DEFINE vm_max_det       SMALLINT
DEFINE vm_num_det       SMALLINT
DEFINE total_valor	DECIMAL(12,2)
DEFINE total_saldo	DECIMAL(12,2)



MAIN

DEFER QUIT 
DEFER INTERRUPT
CLEAR SCREEN
LET vg_proceso = arg_val(0)
CALL startlog('../logs/' || vg_proceso CLIPPED || '.err')
--#CALL fgl_init4js()
CALL fl_marca_registrada_producto()
IF num_args() <> 4 AND num_args() <> 8 AND num_args() <> 10 THEN
	-- Validar # parámetros correcto
	CALL fl_mostrar_mensaje('Número de parametros incorrecto.', 'stop')
	EXIT PROGRAM
END IF
LET vg_base    = arg_val(1)
LET vg_modulo  = arg_val(2)
LET vg_codcia  = arg_val(3)
LET vg_codloc  = arg_val(4)
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
OPEN WINDOW w_cxcf206_1 AT row_ini, 2 WITH num_rows ROWS, num_cols COLUMNS
	ATTRIBUTE(FORM LINE FIRST, COMMENT LINE LAST, MENU LINE lin_menu,
		  BORDER, MESSAGE LINE LAST) 
IF vg_gui = 1 THEN
	OPEN FORM f_cxcf206_1 FROM "../forms/cxcf206_1"
ELSE
	OPEN FORM f_cxcf206_1 FROM "../forms/cxcf206_1c"
END IF
DISPLAY FORM f_cxcf206_1
INITIALIZE rm_z26.* TO NULL
LET vm_num_rows    = 0
LET vm_row_current = 0
LET vm_max_rows	   = 100
LET vm_max_det     = 10000
IF num_args() = 8 THEN
	LET rm_z26.z26_codcli     = arg_val(5)
	LET rm_z26.z26_banco      = arg_val(6)
	LET rm_z26.z26_num_cta    = arg_val(7)
	LET rm_z26.z26_num_cheque = arg_val(8)
	CALL control_consulta(0)
	EXIT PROGRAM
END IF
CALL muestra_contadores(0, 0)
CALL borrar_cabecera()
CALL borrar_detalle()
CALL botones_cabecera_forma()
LET vm_num_det = 0
CALL control_master()
CLOSE WINDOW w_cxcf206_1
RETURN

END FUNCTION



FUNCTION borrar_cabecera()

INITIALIZE rm_par.* TO NULL
DISPLAY BY NAME rm_par.*

END FUNCTION



FUNCTION borrar_detalle()
DEFINE i  		SMALLINT

CALL muestra_contadores(0, 0)
FOR i = 1 TO fgl_scr_size('rm_detalle')
        INITIALIZE rm_detalle[i].*, rm_adi[i].* TO NULL
        CLEAR rm_detalle[i].*
END FOR
CLEAR z20_valor_cap, total_valor, total_saldo

END FUNCTION



FUNCTION botones_cabecera_forma()

--#DISPLAY "TD"				TO tit_col1
--#DISPLAY "Documento"		TO tit_col2
--#DISPLAY "DIV."			TO tit_col3
--#DISPLAY "Referencia"		TO tit_col4
--#DISPLAY "Fecha Vcto"		TO tit_col5
--#DISPLAY "Saldo Doc."		TO tit_col6
--#DISPLAY "Valor Che."		TO tit_col7
--#DISPLAY "C"				TO tit_col8

END FUNCTION



FUNCTION control_master()
DEFINE r_z01		RECORD LIKE cxct001.*
DEFINE r_g08		RECORD LIKE gent008.*

CALL fl_retorna_usuario()
INITIALIZE rm_z26.* TO NULL
LET rm_z26.z26_compania  = vg_codcia
LET rm_z26.z26_localidad = vg_codloc
LET rm_z26.z26_estado    = 'A'
LET rm_z26.z26_valor     = 0
LET rm_z26.z26_usuario   = vg_usuario
WHILE TRUE
	CALL borrar_detalle()
	CALL muestra_contadores(0, 0)
	IF num_args() <> 10 THEN
		CALL lee_parametros()
		IF int_flag THEN
			EXIT WHILE
		END IF
	ELSE
		LET rm_par.z26_codcli      = arg_val(5)
		LET rm_par.z26_banco       = arg_val(6)
		LET rm_par.z26_num_cta     = arg_val(7)
		LET rm_par.z26_num_cheque  = arg_val(8)
		LET rm_par.z26_valor       = arg_val(9)
		LET rm_par.z26_fecha_cobro = arg_val(10)
		CALL fl_lee_cliente_general(rm_par.z26_codcli) RETURNING r_z01.*
		CALL fl_lee_banco_general(rm_par.z26_banco) RETURNING r_g08.*
		LET rm_par.tit_nombre_cli  = r_z01.z01_nomcli
		LET rm_par.tit_banco       = r_g08.g08_nombre
		DISPLAY BY NAME rm_par.*
	END IF
	CALL cargar_detalle()
	IF vm_num_det = 0 THEN
		CALL fl_mensaje_consulta_sin_registros()
		IF num_args() <> 10 THEN
			CONTINUE WHILE
		ELSE
			EXIT WHILE
		END IF
	END IF
	WHILE TRUE
		CALL leer_detalle()
		IF int_flag THEN
			EXIT WHILE
		END IF
		CALL grabar_detalle()
	END WHILE
	IF num_args() = 10 THEN
		EXIT WHILE
	END IF
END WHILE

END FUNCTION



FUNCTION lee_parametros()
DEFINE cod_aux			LIKE cxct002.z02_codcli
DEFINE nom_aux			LIKE cxct001.z01_nomcli
DEFINE codb_aux         LIKE gent008.g08_banco
DEFINE nomb_aux         LIKE gent008.g08_nombre
DEFINE fec_cob			LIKE cxct026.z26_fecha_cobro
DEFINE valor			LIKE cxct026.z26_valor
DEFINE r_z01			RECORD LIKE cxct001.*
DEFINE r_z02			RECORD LIKE cxct002.*
DEFINE r_z26			RECORD LIKE cxct026.*
DEFINE r_g08			RECORD LIKE gent008.*
DEFINE nom_est			VARCHAR(15)
DEFINE mensaje			VARCHAR(100)

LET int_flag = 0
INPUT BY NAME rm_par.*
	WITHOUT DEFAULTS
	ON KEY(INTERRUPT)
		LET int_flag = 1
		EXIT INPUT
	ON KEY(F2)
		IF INFIELD(z26_codcli) THEN
			CALL fl_ayuda_cliente_localidad_cobrar(vg_codcia, vg_codloc, 'D') 
				RETURNING cod_aux, nom_aux
			IF cod_aux IS NOT NULL THEN
				LET rm_par.z26_codcli     = cod_aux
				LET rm_par.tit_nombre_cli = nom_aux
				DISPLAY BY NAME rm_par.z26_codcli, rm_par.tit_nombre_cli
			END IF
		END IF
		IF INFIELD(z26_banco) THEN
			IF NOT tiene_cheque_postfechados_activo() THEN
				CALL fl_ayuda_bancos() RETURNING codb_aux, nomb_aux
				IF codb_aux IS NOT NULL THEN
					LET rm_par.z26_banco = codb_aux
					LET rm_par.tit_banco = nomb_aux
					DISPLAY BY NAME rm_par.z26_banco, rm_par.tit_banco
				END IF
			ELSE
				CALL fl_ayuda_cheques_postfechados(vg_codcia, vg_codloc,
													rm_par.z26_codcli)
					RETURNING r_z26.z26_banco, r_z26.z26_num_cheque,
								r_z26.z26_num_cta, r_z26.z26_valor,
								r_z26.z26_fecha_cobro
				IF r_z26.z26_banco IS NOT NULL THEN
					LET rm_par.z26_banco      = r_z26.z26_banco
					CALL fl_lee_banco_general(rm_par.z26_banco)
						RETURNING r_g08.*
					LET rm_par.tit_banco       = r_g08.g08_nombre
					LET rm_par.z26_num_cheque  = r_z26.z26_num_cheque
					LET rm_par.z26_num_cta     = r_z26.z26_num_cta
					LET rm_par.z26_valor       = NULL
					LET rm_par.z26_fecha_cobro = r_z26.z26_fecha_cobro
					SELECT NVL(SUM(z26_valor), 0)
						INTO rm_par.z26_valor
						FROM cxct026
						WHERE z26_compania   = vg_codcia
						  AND z26_localidad  = vg_codloc
						  AND z26_codcli     = rm_par.z26_codcli
						  AND z26_banco      = rm_par.z26_banco
						  AND z26_num_cta    = rm_par.z26_num_cta
						  AND z26_num_cheque = rm_par.z26_num_cheque
						  AND z26_estado     = 'A'
					IF rm_par.z26_valor IS NULL THEN
						LET rm_par.z26_valor = 0
					END IF
					DISPLAY BY NAME rm_par.*
				END IF
			END IF
		END IF
		LET int_flag = 0
	BEFORE INPUT
		--#CALL dialog.keysetlabel("F1","")
		--#CALL dialog.keysetlabel("CONTROL-W","")
	BEFORE FIELD z26_valor
		LET valor = rm_par.z26_valor
	BEFORE FIELD z26_fecha_cobro
		IF rm_par.z26_fecha_cobro IS NOT NULL THEN
			LET fec_cob = rm_par.z26_fecha_cobro
		ELSE
			LET fec_cob = vg_fecha
		END IF
	AFTER FIELD z26_codcli
		IF rm_par.z26_codcli IS NOT NULL THEN
			CALL fl_lee_cliente_general(rm_par.z26_codcli) RETURNING r_z01.*
			IF r_z01.z01_codcli IS NULL THEN
				CALL fl_mostrar_mensaje('Cliente no existe.','exclamation')
				NEXT FIELD z26_codcli
			END IF
			LET rm_par.tit_nombre_cli = r_z01.z01_nomcli
			IF r_z01.z01_estado = 'B' THEN
				CALL fl_mensaje_estado_bloqueado()
				NEXT FIELD z26_codcli
			END IF
			CALL fl_lee_cliente_localidad(vg_codcia, vg_codloc,
											rm_par.z26_codcli)
				RETURNING r_z02.*
			IF r_z02.z02_compania IS NULL THEN
				CALL fl_mostrar_mensaje('Cliente no esta activado para la compañía.','exclamation')
				NEXT FIELD z26_codcli
			END IF
		ELSE
			LET rm_par.tit_nombre_cli = NULL
		END IF
		DISPLAY BY NAME rm_par.tit_nombre_cli
	AFTER FIELD z26_banco
		IF rm_par.z26_banco IS NOT NULL THEN
			CALL fl_lee_banco_general(rm_par.z26_banco) RETURNING r_g08.*
			IF r_g08.g08_banco IS NULL THEN
				CALL fl_mostrar_mensaje('Banco no existe.','exclamation')
				NEXT FIELD z26_banco
			END IF
			LET rm_par.tit_banco = r_g08.g08_nombre
		ELSE
			LET rm_par.tit_banco = NULL
		END IF
		DISPLAY BY NAME rm_par.tit_banco
	AFTER FIELD z26_valor
		IF rm_par.z26_valor IS NULL THEN
			LET rm_par.z26_valor = valor
			DISPLAY BY NAME rm_par.z26_valor
		END IF
	AFTER FIELD z26_fecha_cobro 
		IF rm_par.z26_fecha_cobro IS NULL THEN
			LET rm_par.z26_fecha_cobro = fec_cob     
			DISPLAY BY NAME rm_par.z26_fecha_cobro
		END IF
		IF rm_par.z26_fecha_cobro < vg_fecha THEN
			CALL fl_mostrar_mensaje('La fecha de cobro no puede ser menor a la de hoy.','exclamation')
			NEXT FIELD z26_fecha_cobro
		END IF
	AFTER INPUT
		IF rm_par.z26_valor = 0 THEN
			CALL fl_mostrar_mensaje('El valor del cheque debe ser mayor a cero.','exclamation')
			NEXT FIELD z26_valor
		END IF
		CALL lee_cheque_postfechado() RETURNING r_z26.*
		IF r_z26.z26_compania IS NOT NULL THEN
			IF r_z26.z26_estado <> 'A' THEN
				CASE r_z26.z26_estado
					WHEN 'B' LET nom_est = "BLOQUEADO"
					WHEN 'C' LET nom_est = "COBRADO"
				END CASE
				LET mensaje = 'Este cheque se encuentra ', nom_est CLIPPED,
							' y no puede ser asignado nuevamente al cliente.'
				CALL fl_mostrar_mensaje(mensaje CLIPPED, 'exclamation')
				CONTINUE INPUT
			END IF
		END IF
END INPUT

END FUNCTION



FUNCTION cargar_detalle()
DEFINE query		CHAR(1500)

LET query = 'SELECT z20_tipo_doc, z20_num_doc, z20_dividendo,',
					' (SELECT r38_num_sri ',
						'FROM rept019, rept038 ',
						'WHERE r19_compania    = z20_compania ',
						'  AND r19_localidad   = z20_localidad ',
						'  AND r19_cod_tran    = z20_cod_tran ',
						'  AND r19_num_tran    = z20_num_tran ',
						'  AND r38_compania    = r19_compania ',
						'  AND r38_localidad   = r19_localidad ',
						'  AND r38_tipo_fuente = "PR" ',
						'  AND r38_cod_tran    = r19_cod_tran ',
						'  AND r38_num_tran    = r19_num_tran) ',
						'AS z26_referencia,',
					' z20_fecha_vcto AS fecha_vcto,',
					' (z20_saldo_cap + z20_saldo_int) AS saldo_cap,',
					' NVL(z26_valor, 0) AS valor_che,',
					' CASE WHEN z26_valor IS NULL ',
						'THEN "N" ',
						'ELSE "S" ',
					' END AS sel_documento, ',
					' (z20_valor_cap + z20_valor_int) AS valor_cap,',
					' g03_areaneg ',
				' FROM cxct020, gent003, OUTER cxct026 ',
				' WHERE z20_compania    = ', vg_codcia,
				'   AND z20_localidad   = ', vg_codloc,
				'   AND z20_codcli      = ', rm_par.z26_codcli ,
				'   AND (z20_saldo_cap + z20_saldo_int) > 0 ',
				'   AND g03_compania    = z20_compania ',
				'   AND g03_areaneg     = z20_areaneg ',
				'   AND z26_compania    = z20_compania ',
				'   AND z26_localidad   = z20_localidad ',
				'   AND z26_codcli      = z20_codcli ',
				'   AND z26_tipo_doc    = z20_tipo_doc ',
				'   AND z26_num_doc     = z20_num_doc ',
				'   AND z26_dividendo   = z20_dividendo ',
				'   AND z26_banco       = ', rm_par.z26_banco,
				'   AND z26_num_cta     = "', rm_par.z26_num_cta, '"',
				'   AND z26_num_cheque  = "', rm_par.z26_num_cheque, '"',
			' INTO TEMP tmp_det '
PREPARE exec_query FROM query
EXECUTE exec_query
DECLARE q_det CURSOR FOR
		SELECT * FROM tmp_det
LET vm_num_det  = 1
FOREACH q_det INTO rm_detalle[vm_num_det].*, rm_adi[vm_num_det].*
	LET vm_num_det = vm_num_det + 1
	IF vm_num_det > vm_max_det THEN
		CALL fl_mensaje_arreglo_incompleto()
		EXIT FOREACH
	END IF
END FOREACH
LET vm_num_det = vm_num_det - 1
DROP TABLE tmp_det
CALL mostrar_totales()

END FUNCTION



FUNCTION leer_detalle()
DEFINE resp			CHAR(6)
DEFINE query		CHAR(800)
DEFINE cla_ve		VARCHAR(100)
DEFINE mensaje		VARCHAR(200)
DEFINE val_che		DECIMAL(12,2)
DEFINE val_asig		DECIMAL(12,2)
DEFINE tot_sal		DECIMAL(12,2)
DEFINE i, j			SMALLINT
DEFINE k, cont		SMALLINT
DEFINE referen		LIKE cxct026.z26_referencia

LET int_flag = 0
CALL set_count(vm_num_det)
INPUT ARRAY rm_detalle WITHOUT DEFAULTS FROM rm_detalle.*
	ON KEY(INTERRUPT)
		LET int_flag = 0
		CALL fl_mensaje_abandonar_proceso() RETURNING resp
		IF resp = 'Yes' THEN
			LET int_flag = 1
			EXIT INPUT
		END IF
	ON KEY(F1,CONTROL-W)
		CALL control_visor_teclas_caracter_1() 
	ON KEY(F5)
		LET i = arr_curr()
		IF rm_detalle[i].valor_che > 0 THEN
			CALL control_consulta(i)
			LET int_flag = 0
		END IF
	ON KEY(F6)
		LET i = arr_curr()
		CALL generar_solicitud_cobro(i)
		LET int_flag = 0
	BEFORE INPUT
		--#CALL dialog.keysetlabel("F1", "")
		--#CALL dialog.keysetlabel("CONTROL-W", "")
		--#CALL dialog.keysetlabel("INSERT", "")
		--#CALL dialog.keysetlabel("DELETE", "")
	BEFORE DELETE	
		--#CANCEL DELETE
	BEFORE INSERT
		--#CANCEL INSERT
	BEFORE ROW
		LET i          = arr_curr()
		LET j          = scr_line()
		LET vm_num_det = arr_count()
		IF i > vm_num_det THEN
			LET vm_num_det = vm_num_det + 1
		END IF
		CALL muestra_contadores(i, vm_num_det)
		DISPLAY BY NAME rm_adi[i].z20_valor_cap
		--#CALL dialog.keysetlabel("F6", "Autorización Cobro")
	BEFORE FIELD z26_referencia
		LET i = arr_curr()
		LET j = scr_line()
		LET referen = rm_detalle[i].z26_referencia
	BEFORE FIELD valor_che
		LET i = arr_curr()
		LET j = scr_line()
		LET val_che = rm_detalle[i].valor_che
		IF val_che IS NULL THEN
			LET val_che = 0
		END IF
	AFTER FIELD z26_referencia
		IF rm_detalle[i].z26_referencia IS NULL THEN
			LET rm_detalle[i].z26_referencia = referen
			DISPLAY rm_detalle[i].z26_referencia TO
					rm_detalle[j].z26_referencia
		END IF
	AFTER FIELD valor_che
		IF rm_detalle[i].valor_che IS NULL THEN
			LET rm_detalle[i].valor_che = val_che
			DISPLAY rm_detalle[i].valor_che TO rm_detalle[j].valor_che
		END IF
		IF rm_detalle[i].valor_che > rm_detalle[i].z20_saldo_cap THEN
			CALL fl_mostrar_mensaje('El valor que esta cargando al documento es mayor que el saldo del documento.', 'exclamation')
			NEXT FIELD valor_che
		END IF
		IF rm_detalle[i].valor_che > 0 THEN
			LET rm_detalle[i].sel_documento = 'S'
		ELSE
			LET rm_detalle[i].sel_documento = 'N'
		END IF
		DISPLAY rm_detalle[i].sel_documento TO rm_detalle[j].sel_documento
		CALL mostrar_totales()
	AFTER FIELD sel_documento
		IF rm_detalle[i].sel_documento = 'S' THEN
			LET val_asig = rm_par.z26_valor - total_valor
			IF val_asig > rm_detalle[i].z20_saldo_cap THEN
				LET rm_detalle[i].valor_che = rm_detalle[i].z20_saldo_cap
			ELSE
				LET rm_detalle[i].valor_che = val_asig
			END IF
		ELSE
			LET rm_detalle[i].valor_che = 0
		END IF
		DISPLAY rm_detalle[i].valor_che TO rm_detalle[j].valor_che
		CALL mostrar_totales()
	AFTER ROW
		CALL mostrar_totales()
	AFTER INPUT
		LET cont    = 0
		LET tot_sal = 0
		FOR k = 1 TO vm_num_det
			IF rm_detalle[k].sel_documento = 'N' THEN
				LET cont = cont + 1
			END IF
			LET tot_sal = tot_sal + rm_detalle[k].valor_che
		END FOR
		IF cont = vm_num_det THEN
			CALL fl_mostrar_mensaje('Debe al menos seleccionar un documento.', 'exclamation')
			CONTINUE INPUT
		END IF
		IF tot_sal <> rm_par.z26_valor THEN
			CALL fl_mostrar_mensaje('El valor cheque no esta distribuido entre el(los) documento(s) seleccionado(s) adecuadamente.', 'exclamation')
			CONTINUE INPUT
		END IF
		LET cont = 0
		FOR k = 1 TO vm_num_det
			IF rm_detalle[k].valor_che = 0 THEN
				CONTINUE FOR
			END IF
			LET val_che = NULL
			LET query = 'SELECT (z26_banco || TRIM(z26_num_cta) || ',
									'TRIM(z26_num_cheque)) AS clave, ',
								'NVL(SUM(z26_valor), 0) AS valor_che ',
						'FROM cxct026 ',
					'WHERE z26_compania    = ', vg_codcia,
					'  AND z26_localidad   = ', vg_codloc,
					'  AND z26_codcli      = ', rm_par.z26_codcli,
					'  AND z26_tipo_doc    = "', rm_detalle[k].z26_tipo_doc,'"',
					'  AND z26_num_doc     = "', rm_detalle[k].z26_num_doc, '"',
					'  AND z26_dividendo   = ', rm_detalle[k].z26_dividendo,
					'  AND z26_estado     <> "B" ',
					'GROUP BY 1 ',
					'INTO TEMP t1 '
			PREPARE exec_t1 FROM query
			EXECUTE exec_t1
			LET cla_ve = rm_par.z26_banco, rm_par.z26_num_cta CLIPPED,
							rm_par.z26_num_cheque CLIPPED
			SELECT NVL(SUM(valor_che), 0)
				INTO val_che
				FROM t1
				WHERE clave <> cla_ve
			DROP TABLE t1
			IF val_che IS NULL THEN
				LET val_che = 0
			END IF
			IF val_che >= rm_detalle[k].z20_saldo_cap THEN
				LET mensaje = 'El documento ', rm_detalle[k].z26_tipo_doc, '-',
								rm_detalle[k].z26_num_doc CLIPPED, '-',
								rm_detalle[k].z26_dividendo USING "&&&",
								' Tiene cargado su saldo restante en otro ',
								'cheque que esta ACTIVO.'
				CALL fl_mostrar_mensaje(mensaje, 'exclamation')
				LET cont = 1
				EXIT FOR
			END IF
		END FOR
		IF cont THEN
			CONTINUE INPUT
		END IF
END INPUT
CALL muestra_contadores(0, 0)

END FUNCTION



FUNCTION grabar_detalle()
DEFINE i, grabo		SMALLINT
DEFINE mensaje		VARCHAR(200)
DEFINE secue		LIKE cxct026.z26_secuencia
DEFINE fecha_actual DATETIME YEAR TO SECOND

BEGIN WORK
WHENEVER ERROR CONTINUE
SET LOCK MODE TO WAIT
	DELETE FROM cxct026
		WHERE z26_compania   = vg_codcia
		  AND z26_localidad  = vg_codloc
		  AND z26_codcli     = rm_par.z26_codcli
		  AND z26_banco      = rm_par.z26_banco
		  AND z26_num_cta    = rm_par.z26_num_cta
		  AND z26_num_cheque = rm_par.z26_num_cheque
		  AND z26_estado     = 'A'
	IF STATUS <> 0 THEN
		ROLLBACK WORK
		SET LOCK MODE TO NOT WAIT
		WHENEVER ERROR STOP
		LET mensaje = 'No se pudo eliminar el cheque del cliente ',
						rm_par.tit_nombre_cli CLIPPED, ' con fecha de cobro ',
						rm_par.z26_fecha_cobro USING "dd-mm-yyyy",
						'. Por favor llame al administrador.'
		CALL fl_mostrar_mensaje(mensaje, 'exclamation')
		RETURN
	END IF
	LET grabo = 1
	LET secue = 1
	FOR i = 1 TO vm_num_det
		IF rm_detalle[i].sel_documento = 'S' THEN
			LET fecha_actual = fl_current()
			INSERT INTO cxct026
			(z26_compania, z26_localidad, z26_codcli, z26_banco, z26_num_cta,
			 z26_num_cheque, z26_secuencia, z26_estado, z26_referencia,
			 z26_valor, z26_fecha_cobro, z26_areaneg, z26_tipo_doc,
			 z26_num_doc, z26_dividendo, z26_usuario, z26_fecing)
			VALUES (vg_codcia, vg_codloc, rm_par.z26_codcli, rm_par.z26_banco,
					rm_par.z26_num_cta, rm_par.z26_num_cheque, secue, 'A',
					rm_detalle[i].z26_referencia, rm_detalle[i].valor_che,
					rm_par.z26_fecha_cobro, rm_adi[i].areaneg,
					rm_detalle[i].z26_tipo_doc, rm_detalle[i].z26_num_doc,
					rm_detalle[i].z26_dividendo, vg_usuario, fecha_actual)
			IF STATUS <> 0 THEN
				ROLLBACK WORK
				WHENEVER ERROR STOP
				LET mensaje = 'No se pudo insertar el registro del cheque ',
								rm_par.z26_num_cheque USING "<<<<<&",
								'. Por favor llame al administrador.'
				CALL fl_mostrar_mensaje(mensaje, 'exclamation')
				LET grabo = 0
				EXIT FOR
			END IF
			LET secue = secue + 1
		END IF
	END FOR
	SET LOCK MODE TO NOT WAIT
	IF NOT grabo THEN
		RETURN
	END IF
WHENEVER ERROR STOP
COMMIT WORK
CALL fl_mensaje_registro_ingresado()

END FUNCTION



FUNCTION mostrar_totales()
DEFINE i			SMALLINT

LET total_valor = 0
LET total_saldo = 0
FOR i = 1 TO vm_num_det
	LET total_saldo = total_saldo + rm_detalle[i].z20_saldo_cap
	LET total_valor = total_valor + rm_detalle[i].valor_che
END FOR
DISPLAY BY NAME total_valor, total_saldo

END FUNCTION



FUNCTION tiene_cheque_postfechados_activo()
DEFINE resul		SMALLINT

LET resul = NULL
DECLARE q_cli_con_che CURSOR FOR
	SELECT 1 FROM cxct026
		WHERE z26_compania  = vg_codcia
		  AND z26_localidad = vg_codloc
		  AND z26_codcli    = rm_par.z26_codcli
		  AND z26_estado    = 'A'
OPEN q_cli_con_che
FETCH q_cli_con_che INTO resul
CLOSE q_cli_con_che
FREE q_cli_con_che
IF resul IS NULL THEN
	LET resul = 0
END IF
RETURN resul

END FUNCTION



FUNCTION control_consulta(i)
DEFINE i			SMALLINT
DEFINE query		CHAR(800)
DEFINE expr_sql		CHAR(600)
DEFINE num_reg		INTEGER
DEFINE lin_menu		SMALLINT
DEFINE row_ini  	SMALLINT
DEFINE num_rows 	SMALLINT
DEFINE num_cols 	SMALLINT

LET lin_menu = 0
LET row_ini  = 4
LET num_rows = 20
LET num_cols = 80
IF vg_gui = 0 THEN
	LET lin_menu = 1
	LET row_ini  = 4
	LET num_rows = 20
	LET num_cols = 78
END IF
OPEN WINDOW w_cxcf206_2 AT row_ini, 2 WITH num_rows ROWS, num_cols COLUMNS
	ATTRIBUTE(FORM LINE FIRST, COMMENT LINE LAST, MENU LINE lin_menu,
		  BORDER, MESSAGE LINE LAST) 
IF vg_gui = 1 THEN
	OPEN FORM f_cxcf206_2 FROM "../forms/cxcf206_2"
ELSE
	OPEN FORM f_cxcf206_2 FROM "../forms/cxcf206_2c"
END IF
DISPLAY FORM f_cxcf206_2
CLEAR FORM
LET vm_num_rows    = 0
LET vm_row_current = 0
CALL muestra_contadores(vm_row_current, vm_num_rows)
IF i = 0 THEN
	LET expr_sql = ' z26_codcli     = ', rm_z26.z26_codcli,
			   ' AND z26_banco      = ', rm_z26.z26_banco,
			   ' AND z26_num_cta    = "', rm_z26.z26_num_cta, '"',
			   ' AND z26_num_cheque = "', rm_z26.z26_num_cheque, '"'
ELSE
	LET expr_sql = ' z26_codcli     = ', rm_par.z26_codcli,
				' AND z26_tipo_doc  = "', rm_detalle[i].z26_tipo_doc, '"',
				' AND z26_num_doc   = "', rm_detalle[i].z26_num_doc, '"',
				' AND z26_dividendo = ', rm_detalle[i].z26_dividendo
END IF
LET query = 'SELECT *, ROWID FROM cxct026 ' ||
		'WHERE z26_compania   = ' || vg_codcia ||
		'  AND z26_localidad  = ' || vg_codloc ||
		'  AND ' || expr_sql CLIPPED||
		' ORDER BY 3, 4, 5, 6'
PREPARE cons FROM query	
DECLARE q_cons CURSOR FOR cons
LET vm_num_rows = 0
FOREACH q_cons INTO rm_z26.*, num_reg
	LET vm_num_rows = vm_num_rows + 1
	IF vm_num_rows > vm_max_rows THEN
	LET vm_num_rows = vm_num_rows - 1
		EXIT FOREACH
	END IF
	LET vm_r_rows[vm_num_rows] = num_reg
END FOREACH
IF vm_num_rows = 0 THEN
	LET int_flag = 0
	CALL fl_mensaje_consulta_sin_registros()
	CLEAR FORM
	LET vm_row_current = 0
	CALL muestra_contadores(vm_row_current, vm_num_rows)
ELSE  
	LET vm_row_current = 1
	CALL muestra_contadores(vm_row_current, vm_num_rows)
	CALL mostrar_registro(vm_r_rows[vm_row_current])
END IF
MENU 'OPCIONES'
	BEFORE MENU
		HIDE OPTION 'Avanzar'
		HIDE OPTION 'Retroceder'
		HIDE OPTION 'Imprimir'
		HIDE OPTION 'Documento'
		IF vm_num_rows <= 1 THEN
			HIDE OPTION 'Avanzar'
			HIDE OPTION 'Retroceder'
		ELSE
			SHOW OPTION 'Avanzar'
			SHOW OPTION 'Documento'
			SHOW OPTION 'Imprimir'
		END IF
		IF vm_row_current <= 1 THEN
			HIDE OPTION 'Retroceder'
		END IF
		IF vm_num_rows > 0 THEN
			SHOW OPTION 'Imprimir'
			SHOW OPTION 'Documento'
		ELSE
			HIDE OPTION 'Imprimir'
			HIDE OPTION 'Documento'
		END IF
	COMMAND KEY('D') 'Documento' 'Muestra el documento deudor.'
		CALL ver_documento_deudor()
	COMMAND KEY('P') 'Imprimir' 'Imprime el registro . '
		CALL control_imprimir()
	COMMAND KEY('A') 'Avanzar' 'Ver siguiente registro. '
		CALL muestra_siguiente_registro()
		IF vm_row_current = vm_num_rows THEN
			HIDE OPTION 'Avanzar'
			SHOW OPTION 'Retroceder'
			NEXT OPTION 'Retroceder'
		ELSE
			SHOW OPTION 'Avanzar'
			SHOW OPTION 'Retroceder'
		END IF
	COMMAND KEY('R') 'Retroceder'  'Ver anterior registro. '
		CALL muestra_anterior_registro()
		IF vm_row_current = 1 THEN
			HIDE OPTION 'Retroceder'
			SHOW OPTION 'Avanzar'
			NEXT OPTION 'Avanzar'
		ELSE
			SHOW OPTION 'Avanzar'
			SHOW OPTION 'Retroceder'
		END IF
	COMMAND KEY('S') 'Salir' 'Salir del programa. '
		EXIT MENU
END MENU
LET int_flag = 0
CLOSE WINDOW w_cxcf206_2
RETURN

END FUNCTION



FUNCTION muestra_siguiente_registro()

IF vm_row_current < vm_num_rows THEN
	LET vm_row_current = vm_row_current + 1
END IF
CALL muestra_contadores(vm_row_current, vm_num_rows)
CALL mostrar_registro(vm_r_rows[vm_row_current])

END FUNCTION



FUNCTION muestra_anterior_registro()

IF vm_row_current > 1 THEN
	LET vm_row_current = vm_row_current - 1
END IF
CALL muestra_contadores(vm_row_current, vm_num_rows)
CALL mostrar_registro(vm_r_rows[vm_row_current])

END FUNCTION



FUNCTION muestra_contadores(num_row, max_row)
DEFINE num_row, max_row	SMALLINT

DISPLAY BY NAME num_row, max_row

END FUNCTION



FUNCTION mostrar_registro(num_registro)
DEFINE num_registro	INTEGER
DEFINE r_g03		RECORD LIKE gent003.*
DEFINE r_g08		RECORD LIKE gent008.*
DEFINE r_z01		RECORD LIKE cxct001.*
DEFINE r_z04		RECORD LIKE cxct004.*
DEFINE r_z20		RECORD LIKE cxct020.*
DEFINE saldo		DECIMAL(14,2)

IF vm_num_rows < 1 THEN
	RETURN
END IF
SELECT * INTO rm_z26.* FROM cxct026 WHERE ROWID = num_registro
IF STATUS = NOTFOUND THEN
	CALL fl_mostrar_mensaje('No existe registro con índice: ' || vm_row_current, 'exclamation')
	RETURN
END IF
DISPLAY BY NAME rm_z26.z26_codcli, rm_z26.z26_banco, rm_z26.z26_num_cta,
		rm_z26.z26_num_cheque, rm_z26.z26_valor,
		rm_z26.z26_fecha_cobro, rm_z26.z26_referencia,
		rm_z26.z26_areaneg, rm_z26.z26_tipo_doc,
		rm_z26.z26_num_doc, rm_z26.z26_dividendo,
		rm_z26.z26_usuario, rm_z26.z26_fecing
CALL fl_lee_cliente_general(rm_z26.z26_codcli) RETURNING r_z01.*
DISPLAY r_z01.z01_nomcli TO tit_nombre_cli
CALL fl_lee_tipo_doc(rm_z26.z26_tipo_doc) RETURNING r_z04.* 
DISPLAY r_z04.z04_nombre TO tit_tipo_doc
CALL fl_lee_area_negocio(vg_codcia,rm_z26.z26_areaneg) RETURNING r_g03.*
DISPLAY r_g03.g03_nombre TO tit_area
CALL fl_lee_banco_general(rm_z26.z26_banco) RETURNING r_g08.*
DISPLAY r_g08.g08_nombre TO tit_banco
CALL fl_lee_documento_deudor_cxc(vg_codcia, vg_codloc, rm_z26.z26_codcli,
									rm_z26.z26_tipo_doc, rm_z26.z26_num_doc,
									rm_z26.z26_dividendo)
	RETURNING r_z20.*
LET saldo = r_z20.z20_saldo_cap + r_z20.z20_saldo_int
DISPLAY saldo TO tit_saldo
CALL muestra_estado()

END FUNCTION



FUNCTION retorna_estado()
DEFINE estado		VARCHAR(15)

CASE rm_z26.z26_estado
	WHEN 'A' LET estado = 'ACTIVO'
	WHEN 'B' LET estado = 'BLOQUEADO'
	WHEN 'C' LET estado = 'COBRADO'
END CASE
RETURN estado

END FUNCTION



FUNCTION muestra_estado()
DEFINE tit_estado_che	VARCHAR(15)

LET tit_estado_che = retorna_estado()
DISPLAY BY NAME rm_z26.z26_estado, tit_estado_che

END FUNCTION



FUNCTION ver_documento_deudor()
DEFINE run_prog		CHAR(10)
DEFINE param		VARCHAR(100)

IF rm_z26.z26_tipo_doc IS NULL THEN
	CALL fl_mostrar_mensaje('Ingrese primero el tipo de documento.','exclamation')
	RETURN
END IF
IF rm_z26.z26_num_doc IS NULL THEN
	CALL fl_mostrar_mensaje('Ingrese el número de documento.','exclamation')
	RETURN
END IF
IF rm_z26.z26_dividendo IS NULL THEN
	CALL fl_mostrar_mensaje('Ingrese el dividendo de documento.','exclamation')
	RETURN
END IF
LET param = ' ', rm_z26.z26_codcli, ' ', rm_z26.z26_tipo_doc, ' ',
			rm_z26.z26_num_doc, ' ', rm_z26.z26_dividendo
CALL fl_ejecuta_comando('COBRANZAS', vg_modulo, 'cxcp200', param, 1)

END FUNCTION



FUNCTION control_imprimir()
DEFINE comando		VARCHAR(100)
DEFINE i		SMALLINT

CALL fl_control_reportes() RETURNING comando
IF int_flag THEN
	RETURN
END IF
START REPORT reporte_cheque_postfechado TO PIPE comando
OUTPUT TO REPORT reporte_cheque_postfechado()
FINISH REPORT reporte_cheque_postfechado

END FUNCTION



REPORT reporte_cheque_postfechado()
DEFINE r_g01		RECORD LIKE gent001.*
DEFINE r_g03		RECORD LIKE gent003.*
DEFINE r_g08		RECORD LIKE gent008.*
DEFINE r_g50		RECORD LIKE gent050.*
DEFINE r_z01		RECORD LIKE cxct001.*
DEFINE r_z04		RECORD LIKE cxct004.*
DEFINE r_z20		RECORD LIKE cxct020.*
DEFINE saldo		DECIMAL(14,2)
DEFINE usuario		VARCHAR(20)
DEFINE modulo		VARCHAR(20)
DEFINE escape		SMALLINT
DEFINE act_comp		SMALLINT
DEFINE desact_comp	SMALLINT
DEFINE act_10cpi	SMALLINT

OUTPUT
	TOP MARGIN	1
	LEFT MARGIN	0
	RIGHT MARGIN	132
	BOTTOM MARGIN	4
	PAGE LENGTH	44

FORMAT

PAGE HEADER
	LET escape	= 27		# Iniciar sec. impresión
	LET act_comp	= 15		# Activar Comprimido.
	LET desact_comp	= 18		# Cancelar Comprimido.
	LET act_10cpi	= 80		# Comprimido 10 CPI.
	CALL fl_lee_modulo(vg_modulo) RETURNING r_g50.*
	LET modulo      = "MODULO: ", r_g50.g50_nombre[1, 19] CLIPPED
	LET usuario     = "USUARIO: ", vg_usuario
	CALL fl_justifica_titulo('D', usuario, 19) RETURNING usuario
	CALL fl_lee_compania(vg_codcia) RETURNING r_g01.*
	CALL fl_lee_cliente_general(rm_z26.z26_codcli) RETURNING r_z01.*
	CALL fl_lee_banco_general(rm_z26.z26_banco) RETURNING r_g08.*
	print ASCII escape;
	print ASCII act_comp;
	print ASCII escape;
	print ASCII act_10cpi
	PRINT COLUMN 001, r_g01.g01_razonsocial
	SKIP 2 LINES
	PRINT COLUMN 001, modulo CLIPPED,
	      COLUMN 052, "COMPROBANTE CHEQUE POSTFECHADO" CLIPPED,
	      COLUMN 125, UPSHIFT(vg_proceso) CLIPPED
	SKIP 3 LINES
	PRINT COLUMN 001, "FECHA IMPRESION: ", vg_fecha USING "dd-mm-yyyy",
 		1 SPACES, TIME,
	      COLUMN 113, usuario
	PRINT "------------------------------------------------------------------------------------------------------------------------------------"
	SKIP 1 LINES
	PRINT COLUMN 114, "ESTADO: ",  rm_z26.z26_estado, " ", retorna_estado()
	SKIP 1 LINES
	PRINT COLUMN 001, "CLIENTE       : ", rm_z26.z26_codcli USING "&&&&&&",
	      COLUMN 024, r_z01.z01_nomcli CLIPPED
	SKIP 1 LINES
	PRINT COLUMN 001, "BANCO         : ", rm_z26.z26_banco USING "&&&&",
	      COLUMN 024, r_g08.g08_nombre CLIPPED
	SKIP 1 LINES
	PRINT COLUMN 001, "CUENTA        : ", rm_z26.z26_num_cta,
	      COLUMN 090, "No. CHEQUE   : ", rm_z26.z26_num_cheque
	SKIP 1 LINES
	PRINT COLUMN 001, "VALOR CHEQUE  : ",
			rm_z26.z26_valor USING "###,##&.##",
	      COLUMN 090, "FECHA COBRO  : ",
			rm_z26.z26_fecha_cobro USING "dd-mm-yyyy"
	SKIP 1 LINES
	PRINT "------------------------------------------------------------------------------------------------------------------------------------"

ON EVERY ROW
	CALL fl_lee_tipo_doc(rm_z26.z26_tipo_doc) RETURNING r_z04.* 
	CALL fl_lee_area_negocio(vg_codcia,rm_z26.z26_areaneg) RETURNING r_g03.*
	CALL fl_lee_documento_deudor_cxc(vg_codcia, vg_codloc,rm_z26.z26_codcli,
					rm_z26.z26_tipo_doc, rm_z26.z26_num_doc,
					rm_z26.z26_dividendo)
		RETURNING r_z20.*
	LET saldo = r_z20.z20_saldo_cap + r_z20.z20_saldo_int
	SKIP 2 LINES
	PRINT COLUMN 001, "REFERENCIA    : ", rm_z26.z26_referencia CLIPPED
	SKIP 1 LINES
	PRINT COLUMN 001, "AREA NEGOCIO  : ", rm_z26.z26_areaneg USING "<<<&",
	      COLUMN 024, r_g03.g03_nombre CLIPPED
	SKIP 1 LINES
	PRINT COLUMN 001, "TIPO DOCUMENTO: ", rm_z26.z26_tipo_doc,
	      COLUMN 024, r_z04.z04_nombre CLIPPED,
	      COLUMN 090, "No. DOCUMENTO: ", rm_z26.z26_num_doc
	SKIP 1 LINES
	PRINT COLUMN 001, "DIVIDENDO     : ",rm_z26.z26_dividendo USING "<<<&&",
	      COLUMN 090, "SALDO        : ", saldo USING "----,--&.##"
	SKIP 7 LINES

PAGE TRAILER
	SKIP 2 LINES
	PRINT COLUMN 029, "------------------------",
	      COLUMN 081, "------------------------"
	PRINT COLUMN 029, "    RECIBI  CONFORME",
	      COLUMN 081, "   ENTREGUE  CONFORME";
	print ASCII escape;
	print ASCII desact_comp

END REPORT



FUNCTION generar_solicitud_cobro(i)
DEFINE i			SMALLINT
DEFINE r_z02		RECORD LIKE cxct002.*
DEFINE r_z24		RECORD LIKE cxct024.*
DEFINE r_z25		RECORD LIKE cxct025.*
DEFINE r_z26		RECORD LIKE cxct026.*
DEFINE r_j10		RECORD LIKE cajt010.*
DEFINE r_j11		RECORD LIKE cajt011.*
DEFINE orden, j		LIKE cxct025.z25_orden
DEFINE mensaje		VARCHAR(200)
DEFINE grabo		SMALLINT
DEFINE resp			CHAR(6)

CALL lee_cheque_postfechado() RETURNING r_z26.*
IF r_z26.z26_compania IS NULL THEN
	CALL fl_mostrar_mensaje('Este cheque todavia no se ha registrado y no se puede hacer Autorización de Cobro.', 'exclamation')
	RETURN
END IF
IF rm_par.z26_fecha_cobro > vg_fecha THEN
	CALL fl_mostrar_mensaje('Este cheque todavia no se lo puede cobrar.', 'exclamation')
	RETURN
END IF
INITIALIZE r_z24.* TO NULL
DECLARE q_numsol CURSOR FOR
	SELECT * FROM cxct024
		WHERE z24_compania  = vg_codcia
		  AND z24_localidad = vg_codloc
		  AND z24_codcli    = rm_par.z26_codcli
		  AND z24_estado    = 'A'
OPEN q_numsol
FETCH q_numsol INTO r_z24.*
IF r_z24.z24_compania IS NOT NULL THEN
	CALL fl_mostrar_mensaje('Este cliente ya tiene generado una Autorización de Cobro que esta ACTIVA. Por favor procesela primero.', 'exclamation')
	CALL mostrar_solicitud_cobro(r_z24.z24_numero_sol)
	RETURN
END IF
CLOSE q_numsol
FREE q_numsol
LET int_flag = 0
CALL fl_hacer_pregunta('Esta seguro de generar esta Autorización de Cobro ?', 'Yes')
	RETURNING resp
IF resp <> 'Yes' THEN
	RETURN
END IF
INITIALIZE r_z24.*, r_z25.*, r_j10.*, r_j11.* TO NULL
BEGIN WORK
WHENEVER ERROR CONTINUE
	LET r_z24.z24_compania   = vg_codcia
	LET r_z24.z24_localidad  = vg_codloc
	SELECT NVL(MAX(z24_numero_sol), 1)
		INTO r_z24.z24_numero_sol
		FROM cxct024
		WHERE z24_compania  = r_z24.z24_compania
		  AND z24_localidad = r_z24.z24_localidad
	IF r_z24.z24_numero_sol IS NULL THEN
		LET r_z24.z24_numero_sol = 1
	ELSE
		LET r_z24.z24_numero_sol = r_z24.z24_numero_sol + 1
	END IF
	LET r_z24.z24_areaneg    = rm_adi[i].areaneg
											-- OJO: NPC
	LET r_z24.z24_linea      = 'VTASI'		-- No poner en duro, ver como se
											-- puede arreglar
	LET r_z24.z24_codcli     = rm_par.z26_codcli
	LET r_z24.z24_tipo       = 'P'
	LET r_z24.z24_estado     = 'A'
	LET r_z24.z24_referencia = 'APLICACION CHEQUE POSTFECHADO'
	LET r_z24.z24_moneda     = rg_gen.g00_moneda_base
	CALL calcula_paridad(r_z24.z24_moneda, rg_gen.g00_moneda_base)
		RETURNING r_z24.z24_paridad 
	LET r_z24.z24_tasa_mora  = 0
	LET r_z24.z24_total_int  = 0
	LET r_z24.z24_total_cap  = rm_par.z26_valor
	LET r_z24.z24_total_mora = 0
	LET r_z24.z24_zona_cobro = 1
	LET r_z24.z24_subtipo    = 1
	LET r_z24.z24_usuario    = vg_usuario
	LET r_z24.z24_fecing     = fl_current()
	INSERT INTO cxct024 VALUES (r_z24.*)
	IF STATUS <> 0 THEN
		WHENEVER ERROR STOP
		ROLLBACK WORK
		CALL fl_mostrar_mensaje('No se pudo crear la Autorización de Cobro. Por favor llame al Administrador.', 'exclamation')
		RETURN
	END IF
	LET grabo = 1
	LET orden = 1
	FOR j = 1 TO vm_num_det
		IF rm_detalle[j].sel_documento = 'N' THEN
			CONTINUE FOR
		END IF
		LET r_z25.z25_compania   = r_z24.z24_compania
		LET r_z25.z25_localidad  = r_z24.z24_localidad
		LET r_z25.z25_numero_sol = r_z24.z24_numero_sol
		LET r_z25.z25_orden      = orden
		LET r_z25.z25_codcli     = r_z24.z24_codcli
		LET r_z25.z25_tipo_doc   = rm_detalle[j].z26_tipo_doc
		LET r_z25.z25_num_doc    = rm_detalle[j].z26_num_doc
		LET r_z25.z25_dividendo  = rm_detalle[j].z26_dividendo
		LET r_z25.z25_valor_cap  = rm_detalle[j].valor_che
		LET r_z25.z25_valor_int  = 0
		LET r_z25.z25_valor_mora = 0
		INSERT INTO cxct025 VALUES (r_z25.*)
		IF STATUS <> 0 THEN
			LET grabo = 0
			WHENEVER ERROR STOP
			ROLLBACK WORK
			LET mensaje = 'No se pudo grabar el documento ',
							r_z25.z25_tipo_doc, '-', r_z25.z25_num_doc CLIPPED,
							'-', r_z25.z25_dividendo USING "&&&",
							'. Por favor llame al Administrador.'
			CALL fl_mostrar_mensaje(mensaje, 'exclamation')
			EXIT FOR
		END IF
		LET orden = orden + 1
	END FOR 
	IF NOT grabo THEN
		RETURN
	END IF
	LET r_j10.j10_compania    = r_z24.z24_compania
	LET r_j10.j10_localidad   = r_z24.z24_localidad
	LET r_j10.j10_tipo_fuente = 'SC'
	LET r_j10.j10_num_fuente  = r_z24.z24_numero_sol
	LET r_j10.j10_areaneg     = r_z24.z24_areaneg
	LET r_j10.j10_estado      = 'A'
	LET r_j10.j10_codcli      = r_z24.z24_codcli
	LET r_j10.j10_nomcli      = rm_par.tit_nombre_cli
	LET r_j10.j10_moneda      = r_z24.z24_moneda
	LET r_j10.j10_valor       = r_z24.z24_total_cap + r_z24.z24_total_int
	LET r_j10.j10_fecha_pro   = fl_current()
	INITIALIZE r_j10.j10_codigo_caja, r_j10.j10_tipo_destino,
				r_j10.j10_num_destino, r_j10.j10_referencia, r_j10.j10_banco,
				r_j10.j10_numero_cta, r_j10.j10_tip_contable,
				r_j10.j10_num_contable
		TO NULL    
	LET r_j10.j10_usuario     = vg_usuario 
	LET r_j10.j10_fecing      = r_j10.j10_fecha_pro
	INSERT INTO cajt010 VALUES(r_j10.*)
	IF STATUS <> 0 THEN
		WHENEVER ERROR STOP
		ROLLBACK WORK
		CALL fl_mostrar_mensaje('No se pudo crear el registro en Caja. Por favor llame al Administrador.', 'exclamation')
		RETURN
	END IF
	LET r_j11.j11_compania     = r_j10.j10_compania
	LET r_j11.j11_localidad    = r_j10.j10_localidad
	LET r_j11.j11_tipo_fuente  = r_j10.j10_tipo_fuente
	LET r_j11.j11_num_fuente   = r_j10.j10_num_fuente
	LET r_j11.j11_secuencia    = 1
	LET r_j11.j11_codigo_pago  = 'CP'
	LET r_j11.j11_moneda       = r_z24.z24_moneda
	LET r_j11.j11_paridad      = r_z24.z24_paridad
	LET r_j11.j11_valor        = r_j10.j10_valor
	LET r_j11.j11_cod_bco_tarj = rm_par.z26_banco
	LET r_j11.j11_num_ch_aut   = rm_par.z26_num_cheque
	LET r_j11.j11_num_cta_tarj = rm_par.z26_num_cta
	LET r_j11.j11_protestado   = 'N'
	INSERT INTO cajt011 VALUES(r_j11.*)
	IF STATUS <> 0 THEN
		WHENEVER ERROR STOP
		ROLLBACK WORK
		CALL fl_mostrar_mensaje('No se pudo crear el registro de detalle en Caja. Por favor llame al Administrador.', 'exclamation')
		RETURN
	END IF
	CALL fl_lee_cliente_localidad(vg_codcia, vg_codloc, r_z24.z24_codcli)
		RETURNING r_z02.*
	IF r_z02.z02_zona_cobro IS NULL THEN
		DECLARE q_z02 CURSOR FOR
			SELECT * FROM cxct002
				WHERE z02_compania  = vg_codcia
				  AND z02_localidad = vg_codloc
				  AND z02_codcli    = r_z02.z02_codcli
			FOR UPDATE
		OPEN q_z02
		FETCH q_z02 INTO r_z02.*
		UPDATE cxct002
			SET z02_zona_cobro = r_z24.z24_zona_cobro
			WHERE CURRENT OF q_z02
		IF STATUS <> 0 THEN
			WHENEVER ERROR STOP
			ROLLBACK WORK
			CALL fl_mostrar_mensaje('No se pudo actualizar la zona de cobro en el cliente. Por favor llame al Administrador.', 'exclamation')
			RETURN
		END IF
		CLOSE q_z02
		FREE q_z02
	END IF
WHENEVER ERROR STOP
COMMIT WORK
CALL fl_mostrar_mensaje('Autorización de Cobro generada OK.', 'info')
CALL mostrar_solicitud_cobro(r_z24.z24_numero_sol)

END FUNCTION



FUNCTION mostrar_solicitud_cobro(numero_sol)
DEFINE numero_sol	LIKE cxct024.z24_numero_sol
DEFINE resp			CHAR(6)
DEFINE param		VARCHAR(60)

LET int_flag = 0
CALL fl_hacer_pregunta('Desea ver esa Autorización de Cobro ?', 'No')
	RETURNING resp
IF resp = 'Yes' THEN
	LET param = ' ', numero_sol
	CALL fl_ejecuta_comando('COBRANZAS', vg_modulo, 'cxcp204', param, 1)
END IF

END FUNCTION



FUNCTION calcula_paridad(moneda_ori, moneda_dest)
DEFINE moneda_ori	LIKE veht036.v36_moneda
DEFINE moneda_dest	LIKE veht036.v36_moneda
DEFINE paridad		LIKE veht036.v36_paridad_mb
DEFINE r_g14		RECORD LIKE gent014.*

IF moneda_ori = moneda_dest THEN
	LET paridad = 1 
ELSE
	CALL fl_lee_factor_moneda(moneda_ori, moneda_dest) RETURNING r_g14.*
	IF r_g14.g14_serial IS NULL THEN
		INITIALIZE paridad TO NULL
		CALL fl_mostrar_mensaje('No existe factor de conversión para esta moneda.','exclamation')
	ELSE
		LET paridad = r_g14.g14_tasa 
	END IF
END IF
RETURN paridad

END FUNCTION



FUNCTION lee_cheque_postfechado()
DEFINE r_z26		RECORD LIKE cxct026.*

INITIALIZE r_z26.* TO NULL
DECLARE q_cheque CURSOR FOR
	SELECT * FROM cxct026
		WHERE z26_compania   = vg_codcia
		  AND z26_localidad  = vg_codloc
		  AND z26_codcli     = rm_par.z26_codcli
		  AND z26_banco      = rm_par.z26_banco
		  AND z26_num_cta    = rm_par.z26_num_cta
		  AND z26_num_cheque = rm_par.z26_num_cheque
		ORDER BY z26_secuencia
OPEN q_cheque
FETCH q_cheque INTO r_z26.*
CLOSE q_cheque
FREE q_cheque
RETURN r_z26.*

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
DISPLAY '<F5>           Ver Detalle'         AT a,2
DISPLAY  'F5' AT a,3 ATTRIBUTE(REVERSE)
LET a = a + 1
DISPLAY '<F6>    Autorización Cobro'         AT a,2
DISPLAY  'F6' AT a,3 ATTRIBUTE(REVERSE)
LET a = fgl_getkey()
CLOSE WINDOW w_tf

END FUNCTION
