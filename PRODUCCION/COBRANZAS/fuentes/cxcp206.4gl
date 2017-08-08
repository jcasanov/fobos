--------------------------------------------------------------------------------
-- Titulo           : cxcp206.4gl - Mantenimiento de cheques postfechados 
-- Elaboracion      : 12-dic-2001
-- Autor            : NPC
-- Formato Ejecucion: fglrun cxcp206 base módulo compañía localidad
--			[cliente] [banco] [numero_cuenta] [numero_cheque]
-- Ultima Correccion: 
-- Motivo Correccion: 
--------------------------------------------------------------------------------
GLOBALS '../../../PRODUCCION/LIBRERIAS/fuentes/globales.4gl'

DEFINE vm_nuevoprog		CHAR(400)
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
							areaneg				LIKE gent003.g03_nombre,
							z20_valor_cap		LIKE cxct020.z20_valor_cap,
							z20_saldo_cap		LIKE cxct020.z20_saldo_cap,
							sel_documento		CHAR(1)
						END RECORD
DEFINE rm_areaneg		ARRAY[10000] OF LIKE gent003.g03_areaneg
DEFINE vm_max_det       SMALLINT
DEFINE vm_num_det       SMALLINT



MAIN

DEFER QUIT 
DEFER INTERRUPT
CLEAR SCREEN
CALL startlog('../logs/cxcp206.err')
--#CALL fgl_init4js()
CALL fl_marca_registrada_producto()
IF num_args() <> 4 AND num_args() <> 8 THEN  -- Validar # parámetros correcto
	CALL fl_mostrar_mensaje('Número de parámetros incorrecto.', 'stop')
	EXIT PROGRAM
END IF
LET vg_base    = arg_val(1)
LET vg_modulo  = arg_val(2)
LET vg_codcia  = arg_val(3)
LET vg_codloc  = arg_val(4)
LET vg_proceso = 'cxcp206'
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
	CALL control_consulta()
	IF vm_num_rows = 0 THEN
		--CALL control_imprimir()
		EXIT PROGRAM
	END IF
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
        INITIALIZE rm_detalle[i].*, rm_areaneg[i] TO NULL
        CLEAR rm_detalle[i].*
END FOR
CLEAR total_valor, total_saldo

END FUNCTION



FUNCTION botones_cabecera_forma()

--#DISPLAY "TD"				TO tit_col1
--#DISPLAY "Documento"		TO tit_col2
--#DISPLAY "DIV."			TO tit_col3
--#DISPLAY "Referencia"		TO tit_col4
--#DISPLAY "Areaneg"		TO tit_col5
--#DISPLAY "Valor Doc."		TO tit_col6
--#DISPLAY "Saldo Doc."		TO tit_col7
--#DISPLAY "C"				TO tit_col8

END FUNCTION



FUNCTION control_master()

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
	CALL lee_parametros()
	IF int_flag THEN
		EXIT WHILE
	END IF
	CALL cargar_detalle()
	IF vm_num_det = 0 THEN
		CALL fl_mensaje_consulta_sin_registros()
		CONTINUE WHILE
	END IF
	WHILE TRUE
		CALL leer_detalle()
		IF int_flag THEN
			EXIT WHILE
		END IF
		CALL grabar_detalle()
	END WHILE
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
			CALL fl_ayuda_cliente_localidad(vg_codcia, vg_codloc)
				RETURNING cod_aux, nom_aux
			IF cod_aux IS NOT NULL THEN
				LET rm_par.z26_codcli     = cod_aux
				LET rm_par.tit_nombre_cli = nom_aux
				DISPLAY BY NAME rm_par.z26_codcli, rm_par.tit_nombre_cli
			END IF
		END IF
		IF INFIELD(z26_banco) THEN
			CALL fl_ayuda_bancos() RETURNING codb_aux, nomb_aux
			IF codb_aux IS NOT NULL THEN
				LET rm_par.z26_banco = codb_aux
				LET rm_par.tit_banco = nomb_aux
				DISPLAY BY NAME rm_par.z26_banco, rm_par.tit_banco
			END IF
		END IF
		LET int_flag = 0
	BEFORE INPUT
		--#CALL dialog.keysetlabel("F1","")
		--#CALL dialog.keysetlabel("CONTROL-W","")
	BEFORE FIELD z26_valor
		LET valor = rm_par.z26_valor
	BEFORE FIELD z26_fecha_cobro
		LET fec_cob = rm_par.z26_fecha_cobro
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
		IF rm_par.z26_fecha_cobro < TODAY THEN
			CALL fl_mostrar_mensaje('La fecha de cobro no puede ser menor a la de hoy.','exclamation')
			NEXT FIELD z26_fecha_cobro
		END IF
	AFTER INPUT
		IF rm_par.z26_valor = 0 THEN
			CALL fl_mostrar_mensaje('El valor del cheque debe ser mayor a cero.','exclamation')
			NEXT FIELD z26_valor
		END IF
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
DEFINE total_valor	DECIMAL(12,2)
DEFINE total_saldo	DECIMAL(12,2)

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
					' g03_nombre AS areaneg,',
					' (z20_valor_cap + z20_valor_int) AS valor_cap,',
					' (z20_saldo_cap + z20_saldo_int) AS saldo_cap,',
					' "N" AS sel_documento, g03_areaneg ',
				' FROM cxct020, gent003 ',
				' WHERE z20_compania    = ', vg_codcia,
				'   AND z20_localidad   = ', vg_codloc,
				'   AND z20_codcli      = ', rm_par.z26_codcli ,
				'   AND (z20_saldo_cap + z20_saldo_int) > 0 ',
				'   AND g03_compania    = z20_compania ',
				'   AND g03_areaneg     = z20_areaneg ',
			' INTO TEMP tmp_det '
PREPARE exec_query FROM query
EXECUTE exec_query
DECLARE q_det CURSOR FOR
		SELECT * FROM tmp_det
LET vm_num_det  = 1
LET total_valor = 0
LET total_saldo = 0
FOREACH q_det INTO rm_detalle[vm_num_det].*, rm_areaneg[vm_num_det]
	LET total_valor = total_valor + rm_detalle[vm_num_det].z20_valor_cap
	LET total_saldo = total_saldo + rm_detalle[vm_num_det].z20_saldo_cap
	LET vm_num_det = vm_num_det + 1
	IF vm_num_det > vm_max_det THEN
		CALL fl_mensaje_arreglo_incompleto()
		EXIT FOREACH
	END IF
END FOREACH
LET vm_num_det = vm_num_det - 1
DROP TABLE tmp_det
DISPLAY BY NAME total_valor, total_saldo

END FUNCTION



FUNCTION leer_detalle()
DEFINE i, j			SMALLINT
DEFINE k, cont		SMALLINT
DEFINE tot_sal		DECIMAL(12,2)
DEFINE resp			CHAR(6)
DEFINE referen		LIKE cxct026.z26_referencia

OPTIONS 
	INSERT KEY F30,
	DELETE KEY F31
CALL set_count(vm_num_det)
LET int_flag = 0
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
	BEFORE FIELD z26_referencia
		LET i = arr_curr()
		LET j = scr_line()
		LET referen = rm_detalle[i].z26_referencia
	AFTER FIELD z26_referencia
		IF rm_detalle[i].z26_referencia IS NULL THEN
			LET rm_detalle[i].z26_referencia = referen
			DISPLAY rm_detalle[i].z26_referencia TO
					rm_detalle[j].z26_referencia
		END IF
	AFTER INPUT
		LET cont    = 0
		LET tot_sal = 0
		FOR k = 1 TO vm_num_det
			IF rm_detalle[k].sel_documento = 'N' THEN
				LET cont = cont + 1
			ELSE
				LET tot_sal = tot_sal + rm_detalle[k].z20_saldo_cap
			END IF
		END FOR
		IF cont = vm_num_det THEN
			CALL fl_mostrar_mensaje('Debe al menos seleccionar un documento.', 'exclamation')
			CONTINUE INPUT
		END IF
		IF tot_sal > rm_par.z26_valor THEN
			CALL fl_mostrar_mensaje('El saldo total de los documento seleccionados es mayor que el valor del cheque.', 'info')
			--CONTINUE INPUT
		END IF
END INPUT

END FUNCTION



FUNCTION grabar_detalle()
DEFINE i, grabo		SMALLINT
DEFINE secue		LIKE cxct026.z26_secuencia

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
	IF STATUS <> 0 THEN
		ROLLBACK WORK
		SET LOCK MODE TO NOT WAIT
		WHENEVER ERROR STOP
		CALL fl_mostrar_mensaje('No se pudo eliminar el cheque del cliente ' || rm_par.tit_nombre_cli CLIPPED || ' con fecha de cobro ' || rm_par.z26_fecha_cobro USING "dd-mm-yyyy" || '. Por favor llame al administrador.', 'exclamation')
		RETURN
	END IF
	LET grabo = 1
	LET secue = 1
	FOR i = 1 TO vm_num_det
		IF rm_detalle[i].sel_documento = 'S' THEN
			INSERT INTO cxct026
			(z26_compania, z26_localidad, z26_codcli, z26_banco, z26_num_cta,
			 z26_num_cheque, z26_secuencia, z26_estado, z26_referencia,
			 z26_valor, z26_fecha_cobro, z26_areaneg, z26_tipo_doc,
			 z26_num_doc, z26_dividendo, z26_usuario, z26_fecing)
			VALUES (vg_codcia, vg_codloc, rm_par.z26_codcli, rm_par.z26_banco,
					rm_par.z26_num_cta, rm_par.z26_num_cheque, secue, 'A',
					rm_detalle[i].z26_referencia, rm_par.z26_valor,
					rm_par.z26_fecha_cobro, rm_areaneg[i],
					rm_detalle[i].z26_tipo_doc, rm_detalle[i].z26_num_doc,
					rm_detalle[i].z26_dividendo, vg_usuario, CURRENT)
			IF STATUS <> 0 THEN
				ROLLBACK WORK
				WHENEVER ERROR STOP
				CALL fl_mostrar_mensaje('No se pudo insertar el registro del cheque ' || rm_par.z26_num_cheque USING "<<<<<&" || '. Por favor llame al administrador.', 'exclamation')
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



FUNCTION control_ingreso()

CALL muestra_estado()
CALL leer_datos('I')
IF NOT int_flag THEN
	LET rm_z26.z26_fecing = CURRENT
	INSERT INTO cxct026 VALUES (rm_z26.*)
	IF vm_num_rows = vm_max_rows THEN
		LET vm_num_rows = 1
	ELSE
		LET vm_num_rows = vm_num_rows + 1
	END IF
	DISPLAY BY NAME rm_z26.z26_fecing
	LET vm_row_current = vm_num_rows
	LET vm_r_rows[vm_row_current] = SQLCA.SQLERRD[6] 
	CALL muestra_contadores(vm_row_current, vm_num_rows)
	CALL mostrar_registro(vm_r_rows[vm_num_rows])	
	CALL fl_mensaje_registro_ingresado()
ELSE
	CLEAR FORM
	CALL muestra_contadores(vm_row_current, vm_num_rows)
	IF vm_row_current > 0 THEN
		CALL mostrar_registro(vm_r_rows[vm_row_current])
	END IF
END IF

END FUNCTION



FUNCTION control_modificacion()
DEFINE done 		SMALLINT
DEFINE i    		SMALLINT

IF vm_num_rows = 0 THEN   
	CALL fl_mensaje_consultar_primero()
	RETURN
END IF
CALL mostrar_registro(vm_r_rows[vm_row_current])
IF rm_z26.z26_estado = 'B' THEN
	CALL fl_mensaje_estado_bloqueado()
	RETURN
END IF
BEGIN WORK
WHENEVER ERROR CONTINUE
DECLARE q_upd CURSOR FOR
	SELECT * FROM cxct026 WHERE ROWID = vm_r_rows[vm_row_current]
	FOR UPDATE
OPEN q_upd
FETCH q_upd INTO rm_z26.*
IF STATUS < 0 THEN
	ROLLBACK WORK
	CALL fl_mensaje_bloqueo_otro_usuario()
	WHENEVER ERROR STOP
	RETURN
END IF  
WHENEVER ERROR STOP
CALL leer_datos('M')
IF int_flag THEN
	ROLLBACK WORK
	CALL mostrar_registro(vm_r_rows[vm_row_current])
	RETURN
END IF 
UPDATE cxct026 SET * = rm_z26.* WHERE CURRENT OF q_upd
COMMIT WORK
CALL mostrar_registro(vm_r_rows[vm_row_current])
CALL fl_mensaje_registro_modificado()

END FUNCTION



FUNCTION control_consulta()
DEFINE cod_aux		LIKE cxct002.z02_codcli
DEFINE nom_aux		LIKE cxct001.z01_nomcli
DEFINE codb_aux         LIKE gent008.g08_banco
DEFINE nomb_aux         LIKE gent008.g08_nombre
DEFINE tipo_aux         LIKE gent009.g09_tipo_cta
DEFINE num_aux          LIKE gent009.g09_numero_cta
DEFINE codt_aux		LIKE cxct004.z04_tipo_doc
DEFINE nomt_aux		LIKE cxct004.z04_nombre
DEFINE coda_aux		LIKE gent003.g03_areaneg
DEFINE noma_aux		LIKE gent003.g03_nombre
DEFINE r_cxc		RECORD LIKE cxct026.*
DEFINE saldo		LIKE cxct020.z20_saldo_cap
DEFINE mone		LIKE cxct020.z20_moneda
DEFINE abrevia		LIKE gent003.g03_abreviacion
DEFINE query		CHAR(800)
DEFINE expr_sql		CHAR(600)
DEFINE num_reg		INTEGER

CLEAR FORM
INITIALIZE cod_aux, codb_aux, codt_aux, coda_aux, r_cxc.* TO NULL
LET int_flag = 0
IF num_args() = 4 THEN
	CONSTRUCT BY NAME expr_sql ON z26_estado, z26_codcli, z26_banco,
	z26_num_cta, z26_num_cheque, z26_valor, z26_fecha_cobro, z26_referencia,
	z26_areaneg, z26_tipo_doc, z26_num_doc, z26_dividendo, z26_usuario
        ON KEY(F1,CONTROL-W)
		CALL llamar_visor_teclas()
	ON KEY(F2)
		IF INFIELD(z26_codcli) THEN
			CALL fl_ayuda_cliente_localidad(vg_codcia,vg_codloc)
				RETURNING cod_aux, nom_aux
			LET int_flag = 0
			IF cod_aux IS NOT NULL THEN
				DISPLAY cod_aux TO z26_codcli 
				DISPLAY nom_aux TO tit_nombre_cli
			END IF 
		END IF
		IF INFIELD(z26_banco) THEN
                        CALL fl_ayuda_bancos()
                                RETURNING codb_aux, nomb_aux
                        LET int_flag = 0
                        IF codb_aux IS NOT NULL THEN
                                DISPLAY codb_aux TO z26_banco
                                DISPLAY nomb_aux TO tit_banco
                        END IF
                END IF
		IF INFIELD(z26_areaneg) THEN
			CALL fl_ayuda_areaneg(vg_codcia)
				RETURNING coda_aux, noma_aux
			LET int_flag = 0
			IF coda_aux IS NOT NULL THEN
				DISPLAY coda_aux TO z26_areaneg
				DISPLAY noma_aux TO tit_area
			END IF 
		END IF
		IF INFIELD(z26_tipo_doc) THEN
			CALL fl_ayuda_tipo_documento_cobranzas('D')
				RETURNING codt_aux, nomt_aux
			LET int_flag = 0
			IF codt_aux IS NOT NULL THEN
				DISPLAY codt_aux TO z26_tipo_doc
				DISPLAY nomt_aux TO tit_tipo_doc
			END IF 
		END IF
		IF INFIELD(z26_num_doc) THEN
			CALL fl_ayuda_doc_deudores_cob(vg_codcia, vg_codloc,
					coda_aux, cod_aux, codt_aux)
				RETURNING nom_aux, r_cxc.z26_tipo_doc,
					r_cxc.z26_num_doc, r_cxc.z26_dividendo,
					saldo, mone, abrevia
			LET int_flag = 0
			IF r_cxc.z26_num_doc IS NOT NULL THEN
				DISPLAY BY NAME r_cxc.z26_dividendo
				DISPLAY BY NAME r_cxc.z26_num_doc
				DISPLAY saldo TO tit_saldo
			END IF 
		END IF
		BEFORE CONSTRUCT
			--#CALL dialog.keysetlabel("F1","")
			--#CALL dialog.keysetlabel("CONTROL-W","")
	END CONSTRUCT
	IF int_flag THEN
		IF vm_row_current > 0 THEN
			CALL muestra_contadores(vm_row_current, vm_num_rows)
			CALL mostrar_registro(vm_r_rows[vm_row_current])
		ELSE
			CLEAR FORM
		END IF
		RETURN
	END IF
ELSE
	LET expr_sql = ' z26_codcli     = ' || arg_val(5) ||
		   ' AND z26_banco      = ' || arg_val(6) ||
		   ' AND z26_num_cta    = ' || '"' || arg_val(7) || '"' ||
		   ' AND z26_num_cheque = ' || '"' || arg_val(8) || '"'
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

END FUNCTION



FUNCTION leer_datos(flag)
DEFINE resp		CHAR(6)
DEFINE r_cxc_aux	RECORD LIKE cxct026.*
DEFINE r_doc		RECORD LIKE cxct020.*
DEFINE r_cli		RECORD LIKE cxct002.*
DEFINE r_cli_gen	RECORD LIKE cxct001.*
DEFINE r_bco_gen	RECORD LIKE gent008.*
DEFINE r_tip		RECORD LIKE cxct004.*
DEFINE r_are		RECORD LIKE gent003.*
DEFINE cod_aux		LIKE cxct002.z02_codcli
DEFINE nom_aux		LIKE cxct001.z01_nomcli
DEFINE codb_aux         LIKE gent008.g08_banco
DEFINE nomb_aux         LIKE gent008.g08_nombre
DEFINE tipo_aux         LIKE gent009.g09_tipo_cta
DEFINE num_aux          LIKE gent009.g09_numero_cta
DEFINE codt_aux		LIKE cxct004.z04_tipo_doc
DEFINE nomt_aux		LIKE cxct004.z04_nombre
DEFINE coda_aux		LIKE gent003.g03_areaneg
DEFINE noma_aux		LIKE gent003.g03_nombre
DEFINE r_cxc		RECORD LIKE cxct026.*
DEFINE saldo		LIKE cxct020.z20_saldo_cap
DEFINE mone		LIKE cxct020.z20_moneda
DEFINE abrevia		LIKE gent003.g03_abreviacion
DEFINE valor		LIKE cxct026.z26_valor
DEFINE flag		CHAR(1)

INITIALIZE r_cxc_aux.*, r_cli.*, r_cli_gen.*, r_bco_gen, r_tip.*, r_are.*,
	cod_aux, codb_aux, codt_aux, coda_aux, r_cxc.* TO NULL
DISPLAY BY NAME rm_z26.z26_usuario, rm_z26.z26_fecing
LET int_flag = 0
INPUT BY NAME rm_z26.z26_codcli, rm_z26.z26_banco, rm_z26.z26_num_cta,
	rm_z26.z26_num_cheque, rm_z26.z26_valor, rm_z26.z26_fecha_cobro,
	rm_z26.z26_referencia, rm_z26.z26_areaneg, rm_z26.z26_tipo_doc,
	rm_z26.z26_num_doc, rm_z26.z26_dividendo
	WITHOUT DEFAULTS
	ON KEY(INTERRUPT)
	        IF field_touched(rm_z26.z26_codcli, rm_z26.z26_banco,
			rm_z26.z26_num_cta, rm_z26.z26_num_cheque,
			rm_z26.z26_valor, rm_z26.z26_fecha_cobro,
			rm_z26.z26_referencia, rm_z26.z26_areaneg,
			rm_z26.z26_tipo_doc, rm_z26.z26_num_doc,
			rm_z26.z26_dividendo)
	        THEN
	               	LET int_flag = 0
			CALL fl_mensaje_abandonar_proceso()
                		RETURNING resp
	              	IF resp = 'Yes' THEN
				LET int_flag = 1
                	       	CLEAR FORM
                       		RETURN
	                END IF
		ELSE
			RETURN
		END IF
	ON KEY(F1,CONTROL-W)
		CALL control_visor_teclas_caracter_1() 
	ON KEY(F2)
		IF INFIELD(z26_codcli) THEN
			CALL fl_ayuda_cliente_localidad(vg_codcia,vg_codloc)
				RETURNING cod_aux, nom_aux
			LET int_flag = 0
			IF cod_aux IS NOT NULL THEN
				LET rm_z26.z26_codcli = cod_aux
				DISPLAY BY NAME rm_z26.z26_codcli 
				DISPLAY nom_aux TO tit_nombre_cli
			END IF 
		END IF
		IF INFIELD(z26_banco) THEN
                        CALL fl_ayuda_bancos()
                                RETURNING codb_aux, nomb_aux
                        LET int_flag = 0
                        IF codb_aux IS NOT NULL THEN
				LET rm_z26.z26_banco = codb_aux
                                DISPLAY BY NAME rm_z26.z26_banco
                                DISPLAY nomb_aux TO tit_banco
                        END IF
                END IF
		IF INFIELD(z26_areaneg) THEN
			CALL fl_ayuda_areaneg(vg_codcia)
				RETURNING coda_aux, noma_aux
			LET int_flag = 0
			IF coda_aux IS NOT NULL THEN
				LET rm_z26.z26_areaneg = coda_aux
				DISPLAY BY NAME rm_z26.z26_areaneg
				DISPLAY noma_aux TO tit_area
			END IF 
		END IF
		IF INFIELD(z26_tipo_doc) THEN
			CALL fl_ayuda_tipo_documento_cobranzas('D')
				RETURNING codt_aux, nomt_aux
			LET int_flag = 0
			IF codt_aux IS NOT NULL THEN
				LET rm_z26.z26_tipo_doc = codt_aux
				DISPLAY BY NAME rm_z26.z26_tipo_doc
				DISPLAY nomt_aux TO tit_tipo_doc
			END IF 
		END IF
		IF INFIELD(z26_num_doc) THEN
			CALL fl_ayuda_doc_deudores_cob(vg_codcia, vg_codloc,
					rm_z26.z26_areaneg, rm_z26.z26_codcli,
					rm_z26.z26_tipo_doc)
				RETURNING nom_aux, r_cxc.z26_tipo_doc,
					r_cxc.z26_num_doc, r_cxc.z26_dividendo,
					saldo, mone, abrevia
			LET int_flag = 0
			IF r_cxc.z26_num_doc IS NOT NULL THEN
				LET rm_z26.z26_num_doc = r_cxc.z26_num_doc
				LET rm_z26.z26_dividendo = r_cxc.z26_dividendo
				DISPLAY BY NAME rm_z26.z26_dividendo
				DISPLAY BY NAME rm_z26.z26_num_doc
				DISPLAY saldo TO tit_saldo
			END IF 
		END IF
	ON KEY(F5)
		CALL ver_documento_deudor()
	BEFORE INPUT
		--#CALL dialog.keysetlabel("F1","")
		--#CALL dialog.keysetlabel("CONTROL-W","")
	BEFORE FIELD z26_valor
		LET valor = rm_z26.z26_valor
	AFTER FIELD z26_codcli
		IF rm_z26.z26_codcli IS NOT NULL THEN
			CALL fl_lee_cliente_general(rm_z26.z26_codcli)
		 		RETURNING r_cli_gen.*
			IF r_cli_gen.z01_codcli IS NULL THEN
				--CALL fgl_winmessage(vg_producto,'Cliente no existe.','exclamation')
				CALL fl_mostrar_mensaje('Cliente no existe.','exclamation')
				NEXT FIELD z26_codcli
			END IF
			DISPLAY r_cli_gen.z01_nomcli TO tit_nombre_cli
			IF r_cli_gen.z01_estado = 'B' THEN
                                CALL fl_mensaje_estado_bloqueado()
                                NEXT FIELD z26_codcli
                        END IF		 
			CALL fl_lee_cliente_localidad(vg_codcia, vg_codloc,
							rm_z26.z26_codcli)
		 		RETURNING r_cli.*
			IF r_cli.z02_compania IS NULL THEN
				--CALL fgl_winmessage(vg_producto,'Cliente no está activado para la compañía.','exclamation')
				CALL fl_mostrar_mensaje('Cliente no está activado para la compañía.','exclamation')
				NEXT FIELD z26_codcli
			END IF
		ELSE
			CLEAR tit_nombre_cli
		END IF
	AFTER FIELD z26_banco
                IF rm_z26.z26_banco IS NOT NULL THEN
                        CALL fl_lee_banco_general(rm_z26.z26_banco)
                                RETURNING r_bco_gen.*
			IF r_bco_gen.g08_banco IS NULL THEN
				--CALL fgl_winmessage(vg_producto,'Banco no existe.','exclamation')
				CALL fl_mostrar_mensaje('Banco no existe.','exclamation')
				NEXT FIELD z26_banco
			END IF
			DISPLAY r_bco_gen.g08_nombre TO tit_banco
		ELSE
			CLEAR tit_banco
                END IF
	AFTER FIELD z26_valor
		IF rm_z26.z26_valor IS NULL THEN
			LET rm_z26.z26_valor = valor
			DISPLAY BY NAME rm_z26.z26_valor
		END IF
	AFTER FIELD z26_areaneg
		IF rm_z26.z26_areaneg IS NOT NULL THEN
			CALL fl_lee_area_negocio(vg_codcia,rm_z26.z26_areaneg)
				RETURNING r_are.*
			IF r_are.g03_areaneg IS NULL THEN
				--CALL fgl_winmessage(vg_producto,'Area de Negocio no existe.','exclamation')
				CALL fl_mostrar_mensaje('Area de Negocio no existe.','exclamation')
				NEXT FIELD z26_areaneg
			END IF
			DISPLAY r_are.g03_nombre TO tit_area
		ELSE
			CLEAR tit_area
		END IF
	AFTER FIELD z26_tipo_doc 
		IF rm_z26.z26_tipo_doc IS NOT NULL THEN
			CALL fl_lee_tipo_doc(rm_z26.z26_tipo_doc)
				RETURNING r_tip.* 
			IF r_tip.z04_tipo_doc IS NULL THEN
				--CALL fgl_winmessage(vg_producto,'Tipo de documento no existe.','exclamation')
				CALL fl_mostrar_mensaje('Tipo de documento no existe.','exclamation')
				NEXT FIELD z26_tipo_doc
			END IF
			DISPLAY r_tip.z04_nombre TO tit_tipo_doc
			IF r_tip.z04_tipo <> 'D' THEN
				--CALL fgl_winmessage(vg_producto,'Tipo de documento debe ser deudor.','exclamation')
				CALL fl_mostrar_mensaje('Tipo de documento debe ser deudor.','exclamation')
				NEXT FIELD z26_tipo_doc
			END IF
			IF rm_z26.z26_tipo_doc <> 'DO'
			AND rm_z26.z26_tipo_doc <> 'DI'
			AND rm_z26.z26_tipo_doc <> 'FA'
			AND rm_z26.z26_tipo_doc <> 'ND' THEN
				--CALL fgl_winmessage(vg_producto,'Tipo de documento debe ser deudor.','exclamation')
				CALL fl_mostrar_mensaje('Tipo de documento debe ser de cobro a clientes.','exclamation')
				NEXT FIELD z26_tipo_doc
			END IF
			IF r_tip.z04_estado = 'B' THEN
                                CALL fl_mensaje_estado_bloqueado()
				NEXT FIELD z26_tipo_doc
			END IF
		ELSE
			CLEAR tit_tipo_doc
		END IF
	AFTER FIELD z26_fecha_cobro
		IF rm_z26.z26_fecha_cobro IS NOT NULL THEN
			IF rm_z26.z26_fecha_cobro < TODAY THEN
				--CALL fgl_winmessage(vg_producto,'La fecha de cobro no puede ser menor a la fecha de hoy.','exclamation')
				CALL fl_mostrar_mensaje('La fecha de cobro no puede ser menor a la fecha de hoy.','exclamation')
				NEXT FIELD z26_fecha_cobro
			END IF
		END IF
	AFTER INPUT
		IF rm_z26.z26_valor = 0 THEN
			--CALL fgl_winmessage(vg_producto,'El valor del cheque debe ser mayor a cero.','exclamation')
			CALL fl_mostrar_mensaje('El valor del cheque debe ser mayor a cero.','exclamation')
			NEXT FIELD z26_valor
		END IF
		CALL fl_lee_cheque_fecha_cxc(vg_codcia, vg_codloc,
				rm_z26.z26_codcli, rm_z26.z26_banco,
				rm_z26.z26_num_cta, rm_z26.z26_num_cheque)
			RETURNING r_cxc_aux.*
		IF r_cxc_aux.z26_compania IS NOT NULL AND flag = 'I' THEN
			--CALL fgl_winmessage(vg_producto,'Cheque ya ha sido ingresado.','exclamation')
			CALL fl_mostrar_mensaje('Cheque ya ha sido ingresado.','exclamation')
			NEXT FIELD z26_num_cheque
		END IF
		IF rm_z26.z26_tipo_doc IS NOT NULL THEN
			CALL fl_lee_documento_deudor_cxc(vg_codcia, vg_codloc,
				rm_z26.z26_codcli, rm_z26.z26_tipo_doc,
				rm_z26.z26_num_doc, rm_z26.z26_dividendo)
				RETURNING r_doc.*
			IF r_doc.z20_compania IS NULL THEN
				--CALL fgl_winmessage(vg_producto,'Documento no existe.','exclamation')
				CALL fl_mostrar_mensaje('Documento no existe.','exclamation')
				NEXT FIELD z26_tipo_doc
			END IF
		END IF
		{
		IF r_doc.z20_saldo_cap + r_doc.z20_saldo_int > rm_z26.z26_valor
		THEN
			--CALL fgl_winmessage(vg_producto,'El saldo del documento no puede ser mayor al valor del cheque.','exclamation')
			CALL fl_mostrar_mensaje('El saldo del documento no puede ser mayor al valor del cheque.','exclamation')
			NEXT FIELD z26_valor
		END IF
		}
END INPUT

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



FUNCTION bloquear_activar()
DEFINE confir		CHAR(6)

CALL mostrar_registro(vm_r_rows[vm_row_current])
IF vm_num_rows = 0 THEN
	CALL fl_mensaje_consultar_primero()
	RETURN
END IF
LET int_flag = 0
BEGIN WORK
WHENEVER ERROR CONTINUE
DECLARE q_ba CURSOR FOR
	SELECT * FROM cxct026 WHERE ROWID = vm_r_rows[vm_row_current]
	FOR UPDATE
OPEN q_ba
FETCH q_ba INTO rm_z26.*
IF STATUS < 0 THEN
	ROLLBACK WORK
	CALL fl_mensaje_bloqueo_otro_usuario()
	WHENEVER ERROR STOP
	RETURN
END IF	
WHENEVER ERROR STOP
CALL fl_mensaje_seguro_ejecutar_proceso() RETURNING confir
IF confir <> 'Yes' THEN
	ROLLBACK WORK
	RETURN
END IF
LET int_flag = 1
CALL bloquea_activa_registro()
COMMIT WORK
CALL mostrar_registro(vm_r_rows[vm_row_current])
CALL fl_mensaje_registro_modificado()

END FUNCTION



FUNCTION bloquea_activa_registro()
DEFINE estado		CHAR(1)

IF rm_z26.z26_estado = 'A' THEN
	DISPLAY 'BLOQUEADO' TO tit_estado_che
	LET estado = 'B'
ELSE 
	DISPLAY 'ACTIVO' TO tit_estado_che
	LET estado = 'A'
END IF
DISPLAY estado TO z26_estado
UPDATE cxct026 SET z26_estado = estado WHERE CURRENT OF q_ba
LET rm_z26.z26_estado = estado

END FUNCTION



FUNCTION retorna_estado()

IF rm_z26.z26_estado = 'A' THEN
	RETURN 'ACTIVO'
ELSE
	RETURN 'BLOQUEADO'
END IF

END FUNCTION



FUNCTION muestra_estado()
DEFINE tit_estado_che	VARCHAR(15)

IF rm_z26.z26_estado = 'A' THEN
	LET tit_estado_che = 'ACTIVO'
ELSE
	LET tit_estado_che = 'BLOQUEADO'
END IF
DISPLAY BY NAME rm_z26.z26_estado, tit_estado_che

END FUNCTION



FUNCTION ver_documento_deudor()
DEFINE run_prog		CHAR(10)

IF rm_z26.z26_tipo_doc IS NULL THEN
	--CALL fgl_winmessage(vg_producto,'Ingrese primero el tipo de documento.','exclamation')
	CALL fl_mostrar_mensaje('Ingrese primero el tipo de documento.','exclamation')
	RETURN
END IF
IF rm_z26.z26_num_doc IS NULL THEN
	--CALL fgl_winmessage(vg_producto,'Ingrese el número de documento.','exclamation')
	CALL fl_mostrar_mensaje('Ingrese el número de documento.','exclamation')
	RETURN
END IF
IF rm_z26.z26_dividendo IS NULL THEN
	--CALL fgl_winmessage(vg_producto,'Ingrese el dividendo de documento.','exclamation')
	CALL fl_mostrar_mensaje('Ingrese el dividendo de documento.','exclamation')
	RETURN
END IF
LET run_prog = '; fglrun '
IF vg_gui = 0 THEN
	LET run_prog = '; fglgo '
END IF
LET vm_nuevoprog = 'cd ..', vg_separador, '..', vg_separador, 'COBRANZAS',
	vg_separador, 'fuentes', vg_separador, run_prog, 'cxcp200 ', vg_base,
	' ', vg_modulo, ' ', vg_codcia, ' ', vg_codloc, ' ', rm_z26.z26_codcli,
	' ', rm_z26.z26_tipo_doc, ' ', rm_z26.z26_num_doc, ' ',
	rm_z26.z26_dividendo 
RUN vm_nuevoprog

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
	PRINT COLUMN 001, "FECHA IMPRESION: ", TODAY USING "dd-mm-yyyy",
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
DISPLAY '<F5>      Documento Deudor'         AT a,2
DISPLAY  'F5' AT a,3 ATTRIBUTE(REVERSE)
LET a = fgl_getkey()
CLOSE WINDOW w_tf

END FUNCTION
