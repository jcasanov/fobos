------------------------------------------------------------------------------
-- Titulo           : cxcp201.4gl - Ingreso de documentos a favor 
-- Elaboracion      : 15-nov-2001
-- Autor            : NPC
-- Formato Ejecucion: fglrun cxcp201 base módulo compañía localidad
--			[cliente] [tipo_documento] [numero_documento]
-- Ultima Correccion: 
-- Motivo Correccion: 
------------------------------------------------------------------------------
GLOBALS '../../../PRODUCCION/LIBRERIAS/fuentes/globales.4gl'

DEFINE rm_z21		RECORD LIKE cxct021.*
DEFINE rm_g37		RECORD LIKE gent037.*
DEFINE vm_num_rows	SMALLINT
DEFINE vm_row_current	SMALLINT
DEFINE vm_max_rows	SMALLINT
DEFINE vm_r_rows	ARRAY [1000] OF INTEGER
DEFINE val_base		DECIMAL(12,2)
DEFINE flag_impto	CHAR(1)
DEFINE rm_datdoc	RECORD
				codcia		LIKE gent001.g01_compania,
				cliprov		INTEGER,
				tipo_doc	CHAR(2),
				num_doc		VARCHAR(15),
				subtipo		LIKE ctbt012.b12_subtipo,
				moneda		LIKE gent013.g13_moneda,
				paridad		LIKE gent014.g14_tasa,
				valor_doc	DECIMAL(14,2),
				glosa_adi	VARCHAR(90),
				flag_mod	SMALLINT
			END RECORD



MAIN

DEFER QUIT 
DEFER INTERRUPT
CLEAR SCREEN
CALL startlog('../logs/cxcp201.err')
--#CALL fgl_init4js()
CALL fl_marca_registrada_producto()
IF num_args() <> 4 AND num_args() <> 7 AND num_args() <> 8 THEN
	-- Validar # parámetros correcto
	CALL fl_mostrar_mensaje('Número de parámetros incorrecto.', 'stop')
	EXIT PROGRAM
END IF
LET vg_base    = arg_val(1)
LET vg_modulo  = arg_val(2)
LET vg_codcia  = arg_val(3)
LET vg_codloc  = arg_val(4)
LET vg_proceso = 'cxcp201'
CALL fl_activar_base_datos(vg_base)
CALL fl_seteos_defaults()	
--#CALL fgl_settitle(vg_proceso || ' - ' || vg_producto)
CALL fl_validar_parametros()
CALL fl_cabecera_pantalla(vg_codcia, vg_codloc, vg_modulo, vg_proceso)
CALL control_master()

END MAIN



FUNCTION control_master()
DEFINE lin_menu		SMALLINT
DEFINE row_ini  	SMALLINT
DEFINE num_rows 	SMALLINT
DEFINE num_cols 	SMALLINT

CALL fl_nivel_isolation()
IF num_args() = 4 THEN
	CALL fl_chequeo_mes_proceso_cxc(vg_codcia) RETURNING int_flag 
	IF int_flag THEN
		RETURN
	END IF
END IF
LET vm_max_rows	= 1000
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
OPEN WINDOW wf AT row_ini, 2 WITH num_rows ROWS, num_cols COLUMNS
	ATTRIBUTE(FORM LINE FIRST + 1, COMMENT LINE LAST, MENU LINE lin_menu,
		  BORDER, MESSAGE LINE LAST - 1) 
IF vg_gui = 1 THEN
	OPEN FORM f_cxc FROM "../forms/cxcf201_1"
ELSE
	OPEN FORM f_cxc FROM "../forms/cxcf201_1c"
END IF
DISPLAY FORM f_cxc
INITIALIZE rm_z21.* TO NULL
LET vm_num_rows    = 0
LET vm_row_current = 0
CALL muestra_contadores(vm_row_current, vm_num_rows)
MENU 'OPCIONES'
	BEFORE MENU
		HIDE OPTION 'Avanzar'
		HIDE OPTION 'Retroceder'
		HIDE OPTION 'Imprimir'
		HIDE OPTION 'Contabilización'
		IF num_args() >= 7 THEN
			HIDE OPTION 'Ingresar'
			HIDE OPTION 'Consultar'
			SHOW OPTION 'Imprimir'
			SHOW OPTION 'Contabilización'
			CALL control_consulta()
			IF vm_num_rows = 0 THEN
                                EXIT PROGRAM
                        END IF
		END IF
	COMMAND KEY('I') 'Ingresar' 'Ingresar nuevos registros. '
		CALL control_ingreso()
		IF vm_row_current > 1 THEN
			SHOW OPTION 'Retroceder'
		END IF
		IF vm_row_current = vm_num_rows THEN
			HIDE OPTION 'Avanzar'
		END IF
		IF vm_row_current > 0 THEN
			SHOW OPTION 'Imprimir'
			SHOW OPTION 'Contabilización'
		ELSE
			HIDE OPTION 'Imprimir'
			HIDE OPTION 'Contabilización'
		END IF
	COMMAND KEY('C') 'Consultar' 'Consultar un registro. '
		CALL control_consulta()
		IF vm_num_rows <= 1 THEN
			HIDE OPTION 'Avanzar'
			HIDE OPTION 'Retroceder'
		ELSE
			SHOW OPTION 'Avanzar'
		END IF
		IF vm_row_current <= 1 THEN
                        HIDE OPTION 'Retroceder'
                END IF
		IF vm_num_rows > 0 THEN
			SHOW OPTION 'Imprimir'
			SHOW OPTION 'Contabilización'
		ELSE
			HIDE OPTION 'Imprimir'
			HIDE OPTION 'Contabilización'
                END IF
	COMMAND KEY('P') 'Imprimir' 'Imprime el registro . '
		CALL imprimir()
	COMMAND KEY('B') 'Contabilización' 'Contabilización del registro . '
		CALL control_contabilizar()
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

END FUNCTION



FUNCTION control_ingreso()
DEFINE num_aux		INTEGER
DEFINE r_b12		RECORD LIKE ctbt012.*
DEFINE r_b00		RECORD LIKE ctbt000.*
DEFINE r_mon            RECORD LIKE gent013.*
DEFINE r_g37            RECORD LIKE gent037.*
DEFINE sec_sri		LIKE gent037.g37_sec_num_sri
DEFINE cuantos		SMALLINT
DEFINE resul		SMALLINT
DEFINE resp		CHAR(6)

CALL fl_retorna_usuario()
INITIALIZE rm_z21.*, r_mon.* TO NULL
CLEAR z21_paridad, z21_saldo, z21_origen, tit_nombre_cli, tit_tipo_doc,
	tit_subtipo, tit_mon_bas, tit_area, z21_cod_tran, z21_num_tran, n_linea
LET val_base             = 0
LET rm_z21.z21_compania  = vg_codcia
LET rm_z21.z21_localidad = vg_codloc
LET rm_z21.z21_fecha_emi = TODAY
LET rm_z21.z21_moneda    = rg_gen.g00_moneda_base
LET rm_z21.z21_valor     = 0
LET rm_z21.z21_saldo     = 0
LET rm_z21.z21_val_impto = 0
LET rm_z21.z21_paridad   = 1
LET rm_z21.z21_origen    = 'M'
LET rm_z21.z21_usuario   = vg_usuario
LET rm_z21.z21_fecing    = CURRENT
DISPLAY BY NAME rm_z21.z21_val_impto
CALL fl_lee_moneda(rm_z21.z21_moneda) RETURNING r_mon.*
IF r_mon.g13_moneda IS NULL THEN
	CALL fl_mostrar_mensaje('No existe ninguna moneda base.','stop')
        EXIT PROGRAM
END IF
DISPLAY r_mon.g13_nombre TO tit_mon_bas
CALL leer_datos()
IF NOT int_flag THEN
	BEGIN WORK
		IF rm_z21.z21_tipo_doc = 'NC' THEN
			WHENEVER ERROR CONTINUE
			DECLARE q_sri CURSOR FOR
				SELECT * FROM gent037
					WHERE g37_compania  =  vg_codcia
					  AND g37_localidad =  vg_codloc
					  AND g37_tipo_doc = rm_z21.z21_tipo_doc
					  AND g37_cont_cred =  'N'
					{--
		  			  AND g37_fecha_emi <= DATE(TODAY)
		  			  AND g37_fecha_exp >= DATE(TODAY)
					--}
					  AND g37_secuencia IN
						(SELECT MAX(g37_secuencia)
						FROM gent037
						WHERE g37_compania  = vg_codcia
						  AND g37_localidad = vg_codloc
						  AND g37_tipo_doc  =
							rm_z21.z21_tipo_doc)
				FOR UPDATE
			OPEN q_sri
			FETCH q_sri INTO r_g37.*
			IF STATUS < 0 THEN
				ROLLBACK WORK
				CALL fl_mostrar_mensaje('Lo siento ahora no puede modificar este No. del SRI, porque ésta secuencia se encuentra bloqueada por otro usuario.','exclamation')
				WHENEVER ERROR STOP
				RETURN
			END IF
			WHENEVER ERROR STOP
			LET cuantos = 8 + rm_g37.g37_num_dig_sri
			LET sec_sri = rm_z21.z21_num_sri[9, cuantos]
					USING "########"
			UPDATE gent037 SET g37_sec_num_sri = sec_sri
				WHERE g37_compania    = rm_g37.g37_compania
				  AND g37_localidad   = rm_g37.g37_localidad
				  AND g37_tipo_doc    = rm_g37.g37_tipo_doc
				  AND g37_secuencia   = rm_g37.g37_secuencia
		  		  AND g37_sec_num_sri < sec_sri
		END IF
		IF NOT generar_secuencia() THEN
			ROLLBACK WORK
			EXIT PROGRAM
		END IF
		DISPLAY BY NAME rm_z21.z21_num_doc
		LET rm_z21.z21_fecing = CURRENT
		INSERT INTO cxct021 VALUES (rm_z21.*)
		LET num_aux = SQLCA.SQLERRD[6] 
		CALL fl_genera_saldos_cliente(vg_codcia, vg_codloc,
						rm_z21.z21_codcli)
		LET rm_datdoc.codcia    = vg_codcia
		LET rm_datdoc.cliprov   = rm_z21.z21_codcli
		LET rm_datdoc.tipo_doc  = rm_z21.z21_tipo_doc
		LET rm_datdoc.num_doc   = rm_z21.z21_num_doc
		LET rm_datdoc.subtipo   = NULL
		IF rm_z21.z21_tipo_doc = 'NC' THEN
			LET rm_datdoc.subtipo = 23
		END IF
		LET rm_datdoc.moneda    = rm_z21.z21_moneda
		LET rm_datdoc.paridad   = rm_z21.z21_paridad
		LET rm_datdoc.valor_doc = rm_z21.z21_valor
		LET rm_datdoc.glosa_adi = NULL
		LET rm_datdoc.flag_mod  = 1	-- Modulo
		CALL fl_contabilizacion_documentos(rm_datdoc.*)
			RETURNING r_b12.*, resul
		IF int_flag THEN
			IF resul = 0 THEN
				ROLLBACK WORK
				EXIT PROGRAM
			END IF
		END IF
		IF resul THEN
			INSERT INTO cxct040
			VALUES (rm_z21.z21_compania, rm_z21.z21_localidad,
				rm_z21.z21_codcli, rm_z21.z21_tipo_doc,
				rm_z21.z21_num_doc, r_b12.b12_tipo_comp,
				r_b12.b12_num_comp)
		END IF
	COMMIT WORK
	IF resul THEN
		CALL fl_lee_compania_contabilidad(vg_codcia) RETURNING r_b00.*
		IF r_b12.b12_compania IS NOT NULL AND
		   r_b00.b00_mayo_online = 'S'
		THEN
			CALL fl_mayoriza_comprobante(r_b12.b12_compania,
				r_b12.b12_tipo_comp, r_b12.b12_num_comp, 'M')
		END IF
		CALL fl_hacer_pregunta('Desea ver contabilización generada?','No')
			RETURNING resp
		IF resp = 'Yes' THEN
			CALL ver_contabilizacion(r_b12.b12_tipo_comp,
						r_b12.b12_num_comp)
		END IF
	END IF
	IF vm_num_rows = vm_max_rows THEN
		LET vm_num_rows = 1
	ELSE
		LET vm_num_rows = vm_num_rows + 1
	END IF
	DISPLAY BY NAME rm_z21.z21_fecing
	LET vm_row_current = vm_num_rows
	LET vm_r_rows[vm_row_current] = num_aux
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



FUNCTION control_consulta()
DEFINE cod_aux		LIKE cxct002.z02_codcli
DEFINE nom_aux		LIKE cxct001.z01_nomcli
DEFINE codt_aux		LIKE cxct004.z04_tipo_doc
DEFINE nomt_aux		LIKE cxct004.z04_nombre
DEFINE coda_aux		LIKE gent003.g03_areaneg
DEFINE noma_aux		LIKE gent003.g03_nombre
DEFINE codte_aux	LIKE gent012.g12_tiporeg
DEFINE codst_aux	LIKE gent012.g12_subtipo
DEFINE nomte_aux	LIKE gent012.g12_nombre
DEFINE nomst_aux	LIKE gent011.g11_nombre
DEFINE mone_aux		LIKE gent013.g13_moneda
DEFINE nomm_aux		LIKE gent013.g13_nombre
DEFINE deci_aux		LIKE gent013.g13_decimales
DEFINE r_cxc		RECORD LIKE cxct021.*
DEFINE abrevia		LIKE gent003.g03_abreviacion
DEFINE query		CHAR(1200)
DEFINE expr_sql		CHAR(1000)
DEFINE num_reg		INTEGER
DEFINE r_g20		RECORD LIKE gent020.*

CLEAR FORM
INITIALIZE cod_aux, codt_aux, coda_aux, codte_aux, codst_aux, mone_aux, r_cxc.*
	TO NULL
IF num_args() = 4 THEN
	LET int_flag = 0
	CONSTRUCT BY NAME expr_sql ON z21_codcli, z21_tipo_doc, z21_num_doc,
	z21_num_sri, z21_subtipo, z21_areaneg, z21_linea, z21_referencia,
	z21_fecha_emi, z21_moneda, z21_val_impto, z21_valor, z21_saldo,
	z21_origen, z21_cod_tran, z21_num_tran, z21_usuario, z21_fecing
        ON KEY(F1,CONTROL-W)
		CALL llamar_visor_teclas()
	ON KEY(F2)
		IF INFIELD(z21_codcli) THEN
			CALL fl_ayuda_cliente_localidad(vg_codcia,vg_codloc)
				RETURNING cod_aux, nom_aux
			LET int_flag = 0
			IF cod_aux IS NOT NULL THEN
				DISPLAY cod_aux TO z21_codcli 
				DISPLAY nom_aux TO tit_nombre_cli
			END IF 
		END IF
		IF INFIELD(z21_linea) THEN
			CALL fl_ayuda_grupo_lineas(vg_codcia) 
				RETURNING r_g20.g20_grupo_linea,
					  r_g20.g20_nombre
			IF r_g20.g20_grupo_linea IS NOT NULL THEN
				LET rm_z21.z21_linea = r_g20.g20_grupo_linea
				DISPLAY BY NAME rm_z21.z21_linea
				DISPLAY r_g20.g20_nombre TO n_linea
			END IF
		END IF
		IF INFIELD(z21_tipo_doc) THEN
			CALL fl_ayuda_tipo_documento_cobranzas('F')
				RETURNING codt_aux, nomt_aux
			LET int_flag = 0
			IF codt_aux IS NOT NULL THEN
				DISPLAY codt_aux TO z21_tipo_doc
				DISPLAY nomt_aux TO tit_tipo_doc
			END IF 
		END IF
		IF INFIELD(z21_num_doc) THEN
			CALL fl_ayuda_doc_favor_cob(vg_codcia, vg_codloc,
					coda_aux, cod_aux, codt_aux)
				RETURNING nom_aux, r_cxc.z21_tipo_doc,
					r_cxc.z21_num_doc, r_cxc.z21_saldo,
					r_cxc.z21_moneda, abrevia
			LET int_flag = 0
			IF r_cxc.z21_num_doc IS NOT NULL THEN
				DISPLAY r_cxc.z21_num_doc TO z21_num_doc
				DISPLAY r_cxc.z21_saldo TO z21_saldo
			END IF 
		END IF
		IF INFIELD(z21_subtipo) THEN
			CALL fl_ayuda_subtipo_entidad(codt_aux)
				RETURNING codte_aux, codst_aux, nomte_aux,
					nomst_aux
			LET int_flag = 0
			IF codte_aux IS NOT NULL THEN
				DISPLAY codst_aux TO z21_subtipo
				DISPLAY nomte_aux TO tit_subtipo
			END IF 
		END IF
		IF INFIELD(z21_areaneg) THEN
			CALL fl_ayuda_areaneg(vg_codcia)
				RETURNING coda_aux, noma_aux
			LET int_flag = 0
			IF coda_aux IS NOT NULL THEN
				DISPLAY coda_aux TO z21_areaneg
				DISPLAY noma_aux TO tit_area
			END IF 
		END IF
		IF INFIELD(z21_moneda) THEN
			CALL fl_ayuda_monedas()
				RETURNING mone_aux, nomm_aux, deci_aux
			LET int_flag = 0
			IF mone_aux IS NOT NULL THEN
				DISPLAY mone_aux TO z21_moneda 
				DISPLAY nomm_aux TO tit_mon_bas
			END IF 
		END IF
		BEFORE CONSTRUCT
			--#CALL dialog.keysetlabel("F1","")
			--#CALL dialog.keysetlabel("CONTROL-W","")
		AFTER FIELD z21_origen
			LET rm_z21.z21_origen = get_fldbuf(z21_origen)
			IF vg_gui = 0 THEN
				IF rm_z21.z21_origen IS NOT NULL THEN
					CALL muestra_origen(rm_z21.z21_origen)
				ELSE
					CLEAR tit_origen
				END IF
			END IF
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
	LET expr_sql = ' z21_codcli   = ' || arg_val(5) CLIPPED ||
	          ' AND z21_tipo_doc  = ' || '"' || arg_val(6) CLIPPED || '"' ||
		   ' AND z21_num_doc  = ' || arg_val(7)
END IF
LET query = 'SELECT *, ROWID FROM cxct021 ' ||
		'WHERE z21_compania  = ' || vg_codcia ||
		'  AND z21_localidad = ' || vg_codloc ||
		'  AND ' || expr_sql CLIPPED ||
		' ORDER BY 3,4,13,5,6'
PREPARE cons FROM query	
DECLARE q_cons CURSOR FOR cons
LET vm_num_rows = 0
FOREACH q_cons INTO rm_z21.*, num_reg
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
	IF num_args() <> 4 THEN
		EXIT PROGRAM
	END IF
	CLEAR FORM
	LET vm_row_current = 0
	CALL muestra_contadores(vm_row_current, vm_num_rows)
ELSE  
	LET vm_row_current = 1
	CALL muestra_contadores(vm_row_current, vm_num_rows)
	CALL mostrar_registro(vm_r_rows[vm_row_current])
END IF

END FUNCTION



FUNCTION leer_datos()
DEFINE resp		CHAR(6)
DEFINE r_cxc_aux	RECORD LIKE cxct021.*
DEFINE r_cli		RECORD LIKE cxct002.*
DEFINE r_cli_gen	RECORD LIKE cxct001.*
DEFINE r_tip		RECORD LIKE cxct004.*
DEFINE r_sub		RECORD LIKE gent012.*
DEFINE r_are		RECORD LIKE gent003.*
DEFINE r_mon		RECORD LIKE gent013.*
DEFINE r_mon_par	RECORD LIKE gent014.*
DEFINE cod_aux		LIKE cxct002.z02_codcli
DEFINE nom_aux		LIKE cxct001.z01_nomcli
DEFINE codt_aux		LIKE cxct004.z04_tipo_doc
DEFINE nomt_aux		LIKE cxct004.z04_nombre
DEFINE codte_aux	LIKE gent012.g12_tiporeg
DEFINE codst_aux	LIKE gent012.g12_subtipo
DEFINE nomte_aux	LIKE gent012.g12_nombre
DEFINE nomst_aux	LIKE gent011.g11_nombre
DEFINE coda_aux		LIKE gent003.g03_areaneg
DEFINE noma_aux		LIKE gent003.g03_nombre
DEFINE mone_aux		LIKE gent013.g13_moneda
DEFINE nomm_aux		LIKE gent013.g13_nombre
DEFINE deci_aux		LIKE gent013.g13_decimales
DEFINE fecha_emi	LIKE cxct021.z21_fecha_emi
DEFINE r_g20		RECORD LIKE gent020.*
DEFINE aux_sri		LIKE cxct021.z21_num_sri
DEFINE resul		SMALLINT

INITIALIZE r_cxc_aux.*, r_cli.*, r_cli_gen.*, r_tip.*, r_sub.*, r_are.*,
	r_mon.*, r_mon_par.*, cod_aux, codt_aux, coda_aux, codte_aux, codst_aux,
	mone_aux, r_g20.* TO NULL
DISPLAY BY NAME rm_z21.z21_fecha_emi, rm_z21.z21_paridad, rm_z21.z21_valor,
		rm_z21.z21_origen, rm_z21.z21_saldo, rm_z21.z21_usuario,
		rm_z21.z21_fecing
IF vg_gui = 0 THEN
	CALL muestra_origen(rm_z21.z21_origen)
END IF
LET flag_impto = 'S'
LET int_flag   = 0
INPUT BY NAME rm_z21.z21_codcli, rm_z21.z21_tipo_doc, flag_impto,
	rm_z21.z21_num_doc, rm_z21.z21_num_sri, rm_z21.z21_subtipo,
	rm_z21.z21_areaneg, rm_z21.z21_linea, rm_z21.z21_referencia,
	rm_z21.z21_fecha_emi, rm_z21.z21_moneda, val_base, rm_z21.z21_valor
	WITHOUT DEFAULTS
	ON KEY(INTERRUPT)
	        IF field_touched(rm_z21.z21_codcli, rm_z21.z21_tipo_doc,
			flag_impto, rm_z21.z21_num_doc, rm_z21.z21_num_sri,
			rm_z21.z21_subtipo, rm_z21.z21_areaneg,
			rm_z21.z21_referencia, rm_z21.z21_fecha_emi,
			rm_z21.z21_moneda, val_base, rm_z21.z21_valor)
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
		CALL llamar_visor_teclas()
	ON KEY(F2)
		IF INFIELD(z21_codcli) THEN
			CALL fl_ayuda_cliente_localidad(vg_codcia,vg_codloc)
				RETURNING cod_aux, nom_aux
			LET int_flag = 0
			IF cod_aux IS NOT NULL THEN
				LET rm_z21.z21_codcli = cod_aux
				DISPLAY BY NAME rm_z21.z21_codcli 
				DISPLAY nom_aux TO tit_nombre_cli
			END IF 
		END IF
		IF INFIELD(z21_tipo_doc) THEN
			CALL fl_ayuda_tipo_documento_cobranzas('F')
				RETURNING codt_aux, nomt_aux
			LET int_flag = 0
			IF codt_aux IS NOT NULL THEN
				LET rm_z21.z21_tipo_doc = codt_aux
				DISPLAY BY NAME rm_z21.z21_tipo_doc
				DISPLAY nomt_aux TO tit_tipo_doc
			END IF 
		END IF
		IF INFIELD(z21_subtipo) THEN
			CALL fl_ayuda_subtipo_entidad(rm_z21.z21_tipo_doc)
				RETURNING codte_aux, codst_aux, nomte_aux,
					nomst_aux
			LET int_flag = 0
			IF codte_aux IS NOT NULL THEN
				LET rm_z21.z21_subtipo = codst_aux
				DISPLAY BY NAME rm_z21.z21_subtipo
				DISPLAY nomte_aux TO tit_subtipo
			END IF 
		END IF
		IF INFIELD(z21_areaneg) THEN
			CALL fl_ayuda_areaneg(vg_codcia)
				RETURNING coda_aux, noma_aux
			LET int_flag = 0
			IF coda_aux IS NOT NULL THEN
				LET rm_z21.z21_areaneg = coda_aux
				DISPLAY BY NAME rm_z21.z21_areaneg
				DISPLAY noma_aux TO tit_area
			END IF 
		END IF
		IF INFIELD(z21_linea) THEN
			CALL fl_ayuda_grupo_lineas(vg_codcia) 
				RETURNING r_g20.g20_grupo_linea,
					  r_g20.g20_nombre
			IF r_g20.g20_grupo_linea IS NOT NULL THEN
				LET rm_z21.z21_linea = r_g20.g20_grupo_linea
				DISPLAY BY NAME rm_z21.z21_linea
				DISPLAY r_g20.g20_nombre TO n_linea
			END IF
		END IF
		IF INFIELD(z21_moneda) THEN
			CALL fl_ayuda_monedas()
				RETURNING mone_aux, nomm_aux, deci_aux
			LET int_flag = 0
			IF mone_aux IS NOT NULL THEN
				LET rm_z21.z21_moneda = mone_aux
				DISPLAY BY NAME rm_z21.z21_moneda 
				DISPLAY nomm_aux TO tit_mon_bas
			END IF 
		END IF
	BEFORE INPUT
		--#CALL dialog.keysetlabel("F1","")
		--#CALL dialog.keysetlabel("CONTROL-W","")
	BEFORE FIELD z21_fecha_emi
		LET fecha_emi = rm_z21.z21_fecha_emi
	AFTER FIELD flag_impto
		CALL calcula_valores()
	AFTER FIELD z21_codcli
		IF rm_z21.z21_codcli IS NOT NULL THEN
			CALL fl_lee_cliente_general(rm_z21.z21_codcli)
		 		RETURNING r_cli_gen.*
			IF r_cli_gen.z01_codcli IS NULL THEN
				--CALL fgl_winmessage(vg_producto,'Cliente no existe.','exclamation')
				CALL fl_mostrar_mensaje('Cliente no existe.','exclamation')
				NEXT FIELD z21_codcli
			END IF
			DISPLAY r_cli_gen.z01_nomcli TO tit_nombre_cli
			IF r_cli_gen.z01_estado = 'B' THEN
                                CALL fl_mensaje_estado_bloqueado()
                                NEXT FIELD z21_codcli
                        END IF		 
			CALL fl_lee_cliente_localidad(vg_codcia, vg_codloc,
							rm_z21.z21_codcli)
		 		RETURNING r_cli.*
			IF r_cli.z02_compania IS NULL THEN
				--CALL fgl_winmessage(vg_producto,'Cliente no está activado para la compañía.','exclamation')
				CALL fl_mostrar_mensaje('Cliente no está activado para la compañía.','exclamation')
				NEXT FIELD z21_codcli
			END IF
		ELSE
			CLEAR tit_nombre_cli
		END IF
	AFTER FIELD z21_tipo_doc 
		IF rm_z21.z21_tipo_doc IS NOT NULL THEN
			CALL calcula_valores()
			CALL fl_lee_tipo_doc(rm_z21.z21_tipo_doc)
				RETURNING r_tip.* 
			IF r_tip.z04_tipo_doc IS NULL THEN
				--CALL fgl_winmessage(vg_producto,'Tipo de documento no existe.','exclamation')
				CALL fl_mostrar_mensaje('Tipo de documento no existe.','exclamation')
				NEXT FIELD z21_tipo_doc
			END IF
			DISPLAY r_tip.z04_nombre TO tit_tipo_doc
			IF r_tip.z04_tipo <> 'F' THEN
				--CALL fgl_winmessage(vg_producto,'Tipo de documento debe ser a favor.','exclamation')
				CALL fl_mostrar_mensaje('Tipo de documento debe ser a favor.','exclamation')
				NEXT FIELD z21_tipo_doc
			END IF
			IF rm_z21.z21_tipo_doc = 'PA' THEN
				--CALL fgl_winmessage(vg_producto,'Los pagos anticipados entran por caja.','exclamation')
				CALL fl_mostrar_mensaje('Los pagos anticipados entran por caja.','exclamation')
				NEXT FIELD z21_tipo_doc
			END IF
			IF r_tip.z04_estado = 'B' THEN
                                CALL fl_mensaje_estado_bloqueado()
				NEXT FIELD z21_tipo_doc
			END IF
		ELSE
			CLEAR tit_tipo_doc
		END IF
	AFTER FIELD z21_num_doc 
		IF rm_z21.z21_num_doc IS NULL THEN
			LET rm_z21.z21_num_doc = 0
			DISPLAY BY NAME rm_z21.z21_num_doc
		END IF
	AFTER FIELD z21_subtipo
		IF rm_z21.z21_subtipo IS NOT NULL THEN
			CALL fl_lee_subtipo_entidad(rm_z21.z21_tipo_doc,
							rm_z21.z21_subtipo)
				RETURNING r_sub.*
			IF r_sub.g12_tiporeg IS NULL THEN
				--CALL fgl_winmessage(vg_producto,'No existe este subtipo de documento.','exclamation')
				CALL fl_mostrar_mensaje('No existe este subtipo de documento.','exclamation')
				NEXT FIELD z21_subtipo
			END IF
			DISPLAY r_sub.g12_nombre TO tit_subtipo
		END IF
	AFTER FIELD z21_areaneg
		IF rm_z21.z21_areaneg IS NOT NULL THEN
			CALL fl_lee_area_negocio(vg_codcia,rm_z21.z21_areaneg)
				RETURNING r_are.*
			IF r_are.g03_areaneg IS NULL THEN
				--CALL fgl_winmessage(vg_producto,'Area de Negocio no existe.','exclamation')
				CALL fl_mostrar_mensaje('Area de Negocio no existe.','exclamation')
				NEXT FIELD z21_areaneg
			END IF
			DISPLAY r_are.g03_nombre TO tit_area
		ELSE
			CLEAR tit_area
		END IF
	AFTER FIELD z21_linea
		IF rm_z21.z21_linea IS NULL THEN
			CLEAR n_linea
			CONTINUE INPUT
		END IF
		CALL fl_lee_grupo_linea(vg_codcia, rm_z21.z21_linea)
			RETURNING r_g20.*
		IF r_g20.g20_grupo_linea IS NULL THEN
			--CALL fgl_winmessage(vg_producto,'Grupo de linea no existe.','exclamation')
			CALL fl_mostrar_mensaje('Grupo de linea no existe.','exclamation')
			CLEAR n_linea
			NEXT FIELD z21_linea
		END IF
		IF rm_z21.z21_areaneg IS NOT NULL THEN
			IF rm_z21.z21_areaneg <> r_g20.g20_areaneg THEN
				--CALL fgl_winmessage(vg_producto,'El grupo de línea no pertenece al área de negocio.','exclamation')
				CALL fl_mostrar_mensaje('El grupo de línea no pertenece al área de negocio.','exclamation')
				CLEAR n_linea
				NEXT FIELD z21_linea 
			END IF
		ELSE
			CALL fl_lee_area_negocio(vg_codcia, r_g20.g20_areaneg)
				RETURNING r_are.*
			LET rm_z21.z21_areaneg = r_g20.g20_areaneg
			DISPLAY BY NAME rm_z21.z21_areaneg
			DISPLAY r_are.g03_nombre TO tit_area 
		END IF
		DISPLAY r_g20.g20_nombre TO n_linea
	AFTER FIELD z21_moneda 
		IF rm_z21.z21_moneda IS NOT NULL THEN
			CALL fl_lee_moneda(rm_z21.z21_moneda)
				RETURNING r_mon.* 
			IF r_mon.g13_moneda IS NULL THEN
				--CALL fgl_winmessage(vg_producto,'Moneda no existe.','exclamation')
				CALL fl_mostrar_mensaje('Moneda no existe.','exclamation')
				NEXT FIELD z21_moneda
			END IF
			DISPLAY r_mon.g13_nombre TO tit_mon_bas
			IF r_mon.g13_estado = 'B' THEN
                                CALL fl_mensaje_estado_bloqueado()
				NEXT FIELD z21_moneda
			END IF
			IF rm_z21.z21_moneda = rg_gen.g00_moneda_base THEN
				LET r_mon_par.g14_tasa = 1
			ELSE
				CALL fl_lee_factor_moneda(rm_z21.z21_moneda,
							rg_gen.g00_moneda_base)
					RETURNING r_mon_par.*
				IF r_mon_par.g14_serial IS NULL THEN
					--CALL fgl_winmessage(vg_producto,'La paridad para está moneda no existe.','exclamation')
					CALL fl_mostrar_mensaje('La paridad para está moneda no existe.','exclamation')
					NEXT FIELD z21_moneda
				END IF
			END IF
			LET rm_z21.z21_paridad = r_mon_par.g14_tasa
			DISPLAY BY NAME rm_z21.z21_paridad
		ELSE
			LET rm_z21.z21_moneda = rg_gen.g00_moneda_base
			DISPLAY BY NAME rm_z21.z21_moneda
			CALL fl_lee_moneda(rm_z21.z21_moneda) RETURNING r_mon.* 
			DISPLAY r_mon.g13_nombre TO tit_mon_bas
		END IF
	AFTER FIELD z21_fecha_emi
		IF rm_z21.z21_fecha_emi IS NOT NULL THEN
			IF rm_z21.z21_fecha_emi > TODAY
			OR (MONTH(rm_z21.z21_fecha_emi) <> MONTH(TODAY)
			OR YEAR(rm_z21.z21_fecha_emi) <> YEAR(TODAY)) THEN
				--CALL fgl_winmessage(vg_producto,'La fecha de emisión debe ser de hoy o del presente mes.','exclamation')
				CALL fl_mostrar_mensaje('La fecha de emisión debe ser de hoy o del presente mes.','exclamation')
				NEXT FIELD z21_fecha_emi
			END IF
		ELSE
			LET rm_z21.z21_fecha_emi = fecha_emi
			DISPLAY BY NAME rm_z21.z21_fecha_emi
		END IF
	AFTER FIELD val_base
		IF val_base IS NULL THEN
			LET val_base = 0
		END IF
		CALL fl_retorna_precision_valor(rm_z21.z21_moneda, val_base)
                	RETURNING val_base
		DISPLAY BY NAME val_base
		CALL calcula_valores()
	AFTER FIELD z21_valor
		IF rm_z21.z21_valor IS NOT NULL THEN
			CALL fl_retorna_precision_valor(rm_z21.z21_moneda,
                                                        rm_z21.z21_valor)
                                RETURNING rm_z21.z21_valor
			LET rm_z21.z21_saldo = rm_z21.z21_valor
			DISPLAY BY NAME rm_z21.z21_saldo
		ELSE
			LET rm_z21.z21_valor = 0
			LET rm_z21.z21_saldo = rm_z21.z21_valor
			DISPLAY BY NAME rm_z21.z21_valor, rm_z21.z21_saldo
		END IF
	BEFORE FIELD z21_num_sri
		IF rm_z21.z21_tipo_doc = 'NC' THEN
			LET aux_sri = rm_z21.z21_num_sri
			CALL validar_num_sri(aux_sri) RETURNING rm_g37.*, resul
			CASE resul
				WHEN -1
					--ROLLBACK WORK
					EXIT PROGRAM
				WHEN 0
					NEXT FIELD z21_num_sri
			END CASE
		ELSE
			LET rm_z21.z21_num_sri = NULL
			DISPLAY BY NAME rm_z21.z21_num_sri
		END IF
	AFTER FIELD z21_num_sri
		IF rm_z21.z21_tipo_doc = 'NC' THEN
			IF rm_z21.z21_num_sri IS NOT NULL THEN
				CALL validar_num_sri(aux_sri)
					RETURNING rm_g37.*, resul
				CASE resul
					WHEN -1
						--ROLLBACK WORK
						EXIT PROGRAM
					WHEN 0
						NEXT FIELD z21_num_sri
				END CASE
			ELSE
				LET rm_z21.z21_num_sri = aux_sri
			END IF
		ELSE
			LET rm_z21.z21_num_sri = NULL
		END IF
		DISPLAY BY NAME rm_z21.z21_num_sri
	AFTER INPUT
		CALL calcula_valores()
		IF rm_z21.z21_tipo_doc='NC' AND rm_z21.z21_num_sri IS NULL THEN
			CALL fl_mostrar_mensaje('Digite número pre-impreso en el formato de Nota de Crédito.','exclamation')
			NEXT FIELD rm_z21.z21_num_sri
		END IF
		IF rm_z21.z21_tipo_doc = 'NC' THEN
			IF rm_z21.z21_num_sri IS NOT NULL THEN
				CALL validar_num_sri(aux_sri)
					RETURNING rm_g37.*, resul
				CASE resul
					WHEN -1
						--ROLLBACK WORK
						EXIT PROGRAM
					WHEN 0
						NEXT FIELD z21_num_sri
				END CASE
			END IF
		ELSE
			LET rm_z21.z21_num_sri = NULL
			DISPLAY BY NAME rm_z21.z21_num_sri
		END IF
		CALL fl_lee_documento_favor_cxc(vg_codcia, vg_codloc,
				rm_z21.z21_codcli, rm_z21.z21_tipo_doc,
				rm_z21.z21_num_doc)
			RETURNING r_cxc_aux.*
		IF r_cxc_aux.z21_compania IS NOT NULL THEN
			IF rm_z21.z21_num_doc > 0 THEN
				CALL fl_mostrar_mensaje('Documento ya ha sido ingresado.','exclamation')
				NEXT FIELD z21_codcli
			END IF
		END IF
		IF rm_z21.z21_valor <= 0 THEN
			CALL fl_mostrar_mensaje('El documento no puede grabarse con valor original de cero.','exclamation')
			NEXT FIELD z21_valor
		END IF
		LET rm_z21.z21_saldo = rm_z21.z21_valor
		IF rm_z21.z21_tipo_doc = 'NC' THEN
			LET rm_z21.z21_num_doc = NULL
		END IF
END INPUT

END FUNCTION



FUNCTION validar_num_sri(aux_sri)
DEFINE aux_sri		LIKE cxct021.z21_num_sri
DEFINE cont		INTEGER
DEFINE flag		SMALLINT

CALL fl_validacion_num_sri(vg_codcia, vg_codloc, rm_z21.z21_tipo_doc, 'N', 
				rm_z21.z21_num_sri)
	RETURNING rm_g37.*, rm_z21.z21_num_sri, flag
CASE flag
	WHEN -1
		RETURN rm_g37.*, -1
	WHEN 0
		RETURN rm_g37.*, 0
END CASE
DISPLAY BY NAME rm_z21.z21_num_sri
{--
IF LENGTH(rm_z21.z21_num_sri) < 15 THEN
	CALL fl_mostrar_mensaje('Digite completo el número del SRI.','exclamation')
	RETURN rm_g37.*, 0
END IF
--}
IF aux_sri <> rm_z21.z21_num_sri THEN
	SELECT COUNT(*) INTO cont FROM cxct021
		WHERE z21_compania  = vg_codcia
		  AND z21_localidad = vg_codloc
  		  AND z21_num_sri   = rm_z21.z21_num_sri
	IF cont > 0 THEN
		CALL fl_mostrar_mensaje('La secuencia del SRI ' || rm_z21.z21_num_sri[9,15] || ' ya existe.','exclamation')
		RETURN rm_g37.*, 0
	END IF
END IF
RETURN rm_g37.*, 1

END FUNCTION



FUNCTION calcula_valores()

IF flag_impto = 'S' THEN
	LET rm_z21.z21_val_impto = val_base * rg_gen.g00_porc_impto / 100
	CALL fl_retorna_precision_valor(rm_z21.z21_moneda, rm_z21.z21_val_impto)
            	RETURNING rm_z21.z21_val_impto
ELSE
	LET rm_z21.z21_val_impto = 0
END IF
LET rm_z21.z21_valor = val_base + rm_z21.z21_val_impto
LET rm_z21.z21_saldo = rm_z21.z21_valor
DISPLAY BY NAME rm_z21.z21_valor, rm_z21.z21_val_impto, rm_z21.z21_saldo

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



FUNCTION muestra_contadores(row_current, num_rows)
DEFINE row_current	SMALLINT
DEFINE num_rows		SMALLINT
                                                                                
DISPLAY num_rows    TO vm_num_rows1
DISPLAY row_current TO vm_num_current1

END FUNCTION



FUNCTION mostrar_registro(num_registro)
DEFINE r_cli_gen	RECORD LIKE cxct001.*
DEFINE r_tip		RECORD LIKE cxct004.*
DEFINE r_sub		RECORD LIKE gent012.*
DEFINE r_are		RECORD LIKE gent003.*
DEFINE r_mon		RECORD LIKE gent013.*
DEFINE r_g20		RECORD LIKE gent020.*
DEFINE num_registro	INTEGER

IF vm_num_rows <= 0 THEN
	RETURN
END IF
SELECT * INTO rm_z21.* FROM cxct021 WHERE ROWID = num_registro
IF STATUS = NOTFOUND THEN
	CALL fl_mostrar_mensaje('No existe registro con índice: ' || vm_row_current,'exclamation')
	RETURN
END IF
IF num_args() = 8 THEN
	IF arg_val(8) < TODAY THEN
		CALL obtener_saldo_a_favor_fecha()
	END IF
END IF
LET flag_impto = 'N'
IF rm_z21.z21_val_impto > 0 THEN
	LET flag_impto = 'S'
END IF
LET val_base = rm_z21.z21_valor - rm_z21.z21_val_impto
DISPLAY BY NAME rm_z21.z21_codcli, rm_z21.z21_tipo_doc, flag_impto,
		rm_z21.z21_num_doc, rm_z21.z21_subtipo,
		rm_z21.z21_areaneg, rm_z21.z21_referencia,
		rm_z21.z21_fecha_emi, rm_z21.z21_moneda,
		rm_z21.z21_paridad, rm_z21.z21_valor, rm_z21.z21_linea,
		rm_z21.z21_val_impto, val_base, rm_z21.z21_saldo,
		rm_z21.z21_origen, rm_z21.z21_usuario,
		rm_z21.z21_fecing, rm_z21.z21_num_sri,
		rm_z21.z21_cod_tran, rm_z21.z21_num_tran
IF vg_gui = 0 THEN
	CALL muestra_origen(rm_z21.z21_origen)
END IF
CALL fl_lee_cliente_general(rm_z21.z21_codcli) RETURNING r_cli_gen.*
CALL fl_lee_tipo_doc(rm_z21.z21_tipo_doc) RETURNING r_tip.* 
CALL fl_lee_grupo_linea(vg_codcia, rm_z21.z21_linea) RETURNING r_g20.*
CALL fl_lee_subtipo_entidad(rm_z21.z21_tipo_doc,rm_z21.z21_subtipo)
	RETURNING r_sub.*
CALL fl_lee_area_negocio(vg_codcia,rm_z21.z21_areaneg) RETURNING r_are.*
CALL fl_lee_moneda(rm_z21.z21_moneda) RETURNING r_mon.* 
DISPLAY r_tip.z04_nombre TO tit_tipo_doc
DISPLAY r_sub.g12_nombre TO tit_subtipo
DISPLAY r_are.g03_nombre TO tit_area
DISPLAY r_mon.g13_nombre TO tit_mon_bas
DISPLAY r_cli_gen.z01_nomcli TO tit_nombre_cli
DISPLAY r_g20.g20_nombre TO n_linea

END FUNCTION



FUNCTION obtener_saldo_a_favor_fecha()
DEFINE r_z60		RECORD LIKE cxct060.*
DEFINE fecha		LIKE cxct022.z22_fecing
DEFINE query		CHAR(6000)
DEFINE subquery1	CHAR(1000)
DEFINE subquery2	CHAR(400)
DEFINE fec_ini		DATE

ERROR "Procesando documento a favor con saldo . . . espere por favor." ATTRIBUTE(NORMAL)
CALL fl_lee_fecha_carga_cxc(vg_codcia, vg_codloc) RETURNING r_z60.*
IF r_z60.z60_compania IS NULL THEN
	CALL fl_mostrar_mensaje('No existe una fecha de carga para este módulo.', 'stop')
	EXIT PROGRAM
END IF
LET fec_ini = r_z60.z60_fecha_carga
LET fecha   = EXTEND(arg_val(8), YEAR TO SECOND) + 23 UNITS HOUR +
		59 UNITS MINUTE + 59 UNITS SECOND
LET subquery1 = '(SELECT SUM(z23_valor_cap + z23_valor_int) ',
		' FROM cxct023, cxct022 ',
		' WHERE z23_compania   = z21_compania ',
		'   AND z23_localidad  = z21_localidad ',
		'   AND z23_codcli     = z21_codcli ',
		'   AND z23_tipo_favor = z21_tipo_doc ',
		'   AND z23_doc_favor  = z21_num_doc ',
		'   AND z22_compania   = z23_compania ',
		'   AND z22_localidad  = z23_localidad ',
		'   AND z22_codcli     = z23_codcli ',
		'   AND z22_tipo_trn   = z23_tipo_trn ',
		'   AND z22_num_trn    = z23_num_trn ',
		'   AND z22_fecing     BETWEEN EXTEND(z21_fecha_emi, ',
						'YEAR TO SECOND)',
					 ' AND "', fecha, '")'
LET subquery2 = '(SELECT NVL(SUM(z23_valor_cap + z23_valor_int), 0) ',
		' FROM cxct023 ',
		' WHERE z23_compania   = z21_compania ',
		'   AND z23_localidad  = z21_localidad ',
		'   AND z23_codcli     = z21_codcli ',
		'   AND z23_tipo_favor = z21_tipo_doc ',
		'   AND z23_doc_favor  = z21_num_doc) '
LET query = 'SELECT NVL(CASE WHEN z21_fecha_emi > "', fec_ini, '"',
			' THEN z21_valor + ', subquery1 CLIPPED,
			' ELSE ', subquery2 CLIPPED, ' + z21_saldo - ',
				  subquery1 CLIPPED,
		' END, ',
		' CASE WHEN z21_fecha_emi <= "', fec_ini, '"',
			' THEN z21_saldo - ', subquery2 CLIPPED,
			' ELSE z21_valor',
		' END) saldo_doc ',
		' FROM cxct021 ',
		' WHERE z21_compania   = ', rm_z21.z21_compania,
		'   AND z21_localidad  = ', rm_z21.z21_localidad,
		'   AND z21_codcli     = ', rm_z21.z21_codcli,
		'   AND z21_tipo_doc   = "', rm_z21.z21_tipo_doc, '"',
		'   AND z21_num_doc    = ', rm_z21.z21_num_doc,
		'   AND z21_fecha_emi <= "', arg_val(8), '"',
		' INTO TEMP t1 '
PREPARE stmnt2 FROM query
EXECUTE stmnt2
SELECT NVL(saldo_doc, 0) INTO rm_z21.z21_saldo FROM t1
DROP TABLE t1
ERROR ' '

END FUNCTION



FUNCTION generar_secuencia()
DEFINE resul		SMALLINT
DEFINE r_z21		RECORD LIKE cxct021.*

WHILE TRUE
	CALL fl_actualiza_control_secuencias(vg_codcia, vg_codloc, vg_modulo,
						'AA', rm_z21.z21_tipo_doc)
		RETURNING rm_z21.z21_num_doc
	IF rm_z21.z21_num_doc <= 0 THEN
		LET resul = 0
		EXIT WHILE
	END IF
	CALL fl_lee_documento_favor_cxc(vg_codcia, vg_codloc, rm_z21.z21_codcli,
					rm_z21.z21_tipo_doc, rm_z21.z21_num_doc)
		RETURNING r_z21.*
	IF r_z21.z21_compania IS NULL THEN
		LET resul = 1
		EXIT WHILE
	END IF
END WHILE
RETURN resul

END FUNCTION



FUNCTION muestra_origen(origen)
DEFINE origen		CHAR(1)

CASE origen
	WHEN 'M'
		DISPLAY 'MANUAL' TO tit_origen
	WHEN 'A'
		DISPLAY 'AUTOMATICO' TO tit_origen
	OTHERWISE
		CLEAR z21_origen, tit_origen
END CASE

END FUNCTION



FUNCTION imprimir()
DEFINE comando		CHAR(400)
DEFINE run_prog		VARCHAR(20)

LET run_prog = '; fglrun '
IF vg_gui = 0 THEN
	LET run_prog = '; fglgo '
END IF
LET comando = 'cd ..', vg_separador, '..', vg_separador, 'COBRANZAS',
	vg_separador, 'fuentes', vg_separador, run_prog, 'cxcp414 ', vg_base,
	' ', vg_modulo, ' ', vg_codcia, ' ', vg_codloc, ' ', rm_z21.z21_codcli,
	' "', rm_z21.z21_tipo_doc, '" ', rm_z21.z21_num_doc
RUN comando

END FUNCTION



FUNCTION control_contabilizar()
DEFINE r_z40		RECORD LIKE cxct040.*

INITIALIZE r_z40.* TO NULL
SELECT * INTO r_z40.* FROM cxct040
	WHERE z40_compania  = rm_z21.z21_compania
	  AND z40_localidad = rm_z21.z21_localidad
	  AND z40_codcli    = rm_z21.z21_codcli
	  AND z40_tipo_doc  = rm_z21.z21_tipo_doc
	  AND z40_num_doc   = rm_z21.z21_num_doc
IF r_z40.z40_compania IS NULL THEN
	CALL fl_mostrar_mensaje('Este documento no tiene contablización automatica.', 'exclamation')
	RETURN
END IF
CALL ver_contabilizacion(r_z40.z40_tipo_comp, r_z40.z40_num_comp)

END FUNCTION



FUNCTION ver_contabilizacion(tipo_comp, num_comp)
DEFINE tipo_comp	LIKE ctbt012.b12_tipo_comp
DEFINE num_comp		LIKE ctbt012.b12_num_comp
DEFINE comando		CHAR(400)
DEFINE run_prog		VARCHAR(20)

LET run_prog = '; fglrun '
IF vg_gui = 0 THEN
	LET run_prog = '; fglgo '
END IF
LET comando = 'cd ..', vg_separador, '..', vg_separador, 'CONTABILIDAD',
	vg_separador, 'fuentes', vg_separador, run_prog, 'ctbp201 ', vg_base,
	' ', 'CB', ' ', vg_codcia, ' "', tipo_comp, '" ', num_comp
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
