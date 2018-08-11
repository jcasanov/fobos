--------------------------------------------------------------------------------
-- Titulo           : cxpp201.4gl - Ingreso de documentos a favor
-- Elaboracion      : 27-nov-2001
-- Autor            : NPC
-- Formato Ejecucion: fglrun cxpp201 base módulo compañía localidad
--						[proveedor tipo_documento numero_documento]
-- Ultima Correccion: 
-- Motivo Correccion: 
--------------------------------------------------------------------------------
GLOBALS '../../../PRODUCCION/LIBRERIAS/fuentes/globales.4gl'

DEFINE rm_p21			RECORD LIKE cxpt021.*
DEFINE rm_datdoc		RECORD
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
DEFINE vm_r_rows		ARRAY [1000] OF INTEGER

-- SE AGREGARON las variables val_base y flag_impto el 02/01/2018 por NPC
DEFINE val_base			DECIMAL(12,2)
DEFINE flag_impto		CHAR(1)
--

DEFINE vm_num_rows		SMALLINT
DEFINE vm_row_current	SMALLINT
DEFINE vm_max_rows		SMALLINT



MAIN

DEFER QUIT 
DEFER INTERRUPT
CLEAR SCREEN
LET vg_proceso = arg_val(0)
CALL startlog('../logs/' || vg_proceso CLIPPED || '.err')
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
	CALL fl_chequeo_mes_proceso_cxp(vg_codcia) RETURNING int_flag 
	IF int_flag THEN
		RETURN
	END IF
END IF
LET vm_max_rows	= 1000
LET lin_menu = 0
LET row_ini  = 3
LET num_rows = 20
LET num_cols = 80
IF vg_gui = 0 THEN
	LET lin_menu = 1
	LET row_ini  = 4
	LET num_rows = 20
	LET num_cols = 78
END IF
OPEN WINDOW w_cxpf201_1 AT row_ini, 02 WITH num_rows ROWS, num_cols COLUMNS
	ATTRIBUTE(FORM LINE FIRST + 1, COMMENT LINE LAST, MENU LINE lin_menu,
				BORDER, MESSAGE LINE LAST - 1) 
IF vg_gui = 1 THEN
	OPEN FORM f_cxpf201_1 FROM "../forms/cxpf201_1"
ELSE
	OPEN FORM f_cxpf201_1 FROM "../forms/cxpf201_1c"
END IF
DISPLAY FORM f_cxpf201_1
INITIALIZE rm_p21.* TO NULL
LET vm_num_rows    = 0
LET vm_row_current = 0
CALL muestra_contadores(vm_row_current, vm_num_rows)
MENU 'OPCIONES'
	BEFORE MENU
		HIDE OPTION 'Avanzar'
		HIDE OPTION 'Retroceder'
		HIDE OPTION 'Datos Adic. N/C'
		HIDE OPTION 'Contabilización'
		IF num_args() >= 7 THEN
			HIDE OPTION 'Ingresar'
			HIDE OPTION 'Consultar'
			CALL control_consulta()
			SHOW OPTION 'Datos Adic. N/C'
			SHOW OPTION 'Contabilización'
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
			IF rm_p21.p21_tipo_doc = 'NC' THEN
				SHOW OPTION 'Datos Adic. N/C'
			ELSE
				HIDE OPTION 'Datos Adic. N/C'
			END IF
			SHOW OPTION 'Contabilización'
		ELSE
			HIDE OPTION 'Datos Adic. N/C'
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
			IF rm_p21.p21_tipo_doc = 'NC' THEN
				SHOW OPTION 'Datos Adic. N/C'
			ELSE
				HIDE OPTION 'Datos Adic. N/C'
			END IF
			SHOW OPTION 'Contabilización'
		ELSE
			HIDE OPTION 'Datos Adic. N/C'
			HIDE OPTION 'Contabilización'
		END IF
	COMMAND KEY('N') 'Datos Adic. N/C' 'Datos Adic. N/C del registro . '
		CALL control_datos_adicionales_nc('M')
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
DEFINE num_aux			INTEGER
DEFINE r_mon            RECORD LIKE gent013.*
DEFINE r_b12			RECORD LIKE ctbt012.*
DEFINE r_b00			RECORD LIKE ctbt000.*
DEFINE resul			SMALLINT
DEFINE resp				CHAR(6)

CALL fl_retorna_usuario()
INITIALIZE rm_p21.*, r_mon.* TO NULL
CLEAR p21_paridad, p21_saldo, p21_origen, tit_nombre_pro, tit_tipo_doc,
	tit_subtipo, tit_mon_bas, p21_val_impto, p21_cod_tran, p21_num_tran
LET rm_p21.p21_compania  = vg_codcia
LET rm_p21.p21_localidad = vg_codloc
LET rm_p21.p21_fecha_emi = vg_fecha
LET rm_p21.p21_moneda    = rg_gen.g00_moneda_base
LET val_base             = 0
LET rm_p21.p21_val_impto = 0
LET rm_p21.p21_valor     = 0
LET rm_p21.p21_saldo     = 0
LET rm_p21.p21_paridad   = 1
LET rm_p21.p21_origen    = 'M'
LET rm_p21.p21_usuario   = vg_usuario
LET rm_p21.p21_fecing    = fl_current()
DISPLAY BY NAME rm_p21.p21_val_impto
CALL fl_lee_moneda(rm_p21.p21_moneda) RETURNING r_mon.*
IF r_mon.g13_moneda IS NULL THEN
	CALL fl_mostrar_mensaje('No existe ninguna moneda base.','stop')
	EXIT PROGRAM
END IF
DISPLAY r_mon.g13_nombre TO tit_mon_bas
CALL leer_datos()
IF int_flag THEN
	CLEAR FORM
	CALL muestra_contadores(vm_row_current, vm_num_rows)
	IF vm_row_current > 0 THEN
		CALL mostrar_registro(vm_r_rows[vm_row_current])
	END IF
	RETURN
END IF
BEGIN WORK
WHENEVER ERROR CONTINUE
	IF rm_p21.p21_tipo_doc = 'NC' THEN
		CALL fl_actualiza_control_secuencias(vg_codcia, vg_codloc, vg_modulo,
											'AA', rm_p21.p21_tipo_doc)
			RETURNING rm_p21.p21_num_doc
		IF rm_p21.p21_num_doc <= 0 THEN
			WHENEVER ERROR STOP
			ROLLBACK WORK
			EXIT PROGRAM
		END IF
		DISPLAY BY NAME rm_p21.p21_num_doc
		CALL control_datos_adicionales_nc('I')
	END IF
	LET rm_p21.p21_fecing = fl_current()

	--
	{XXX La tabla cxpt021 se le incluyó los siguientes campos el 02/01/2018:
			- p21_val_impto
			- p21_cod_tran
			- p21_num_tran
			- p21_num_sri
			- p21_num_aut
			- p21_fec_emi_nc
			- p21_fec_emi_aut

		Estos 2 campos, solo son utilizados por el programa repp218
		Devolución de Compra Local
			- p21_cod_tran
			- p21_num_tran
	 XXX}

	INSERT INTO cxpt021 VALUES (rm_p21.*)
	--

	LET num_aux = SQLCA.SQLERRD[6] 
	CALL fl_genera_saldos_proveedor(vg_codcia, vg_codloc, rm_p21.p21_codprov)
	LET rm_datdoc.codcia    = vg_codcia
	LET rm_datdoc.cliprov   = rm_p21.p21_codprov
	LET rm_datdoc.tipo_doc  = rm_p21.p21_tipo_doc
	LET rm_datdoc.num_doc   = rm_p21.p21_num_doc
	LET rm_datdoc.subtipo   = NULL
	IF rm_p21.p21_tipo_doc = 'NC' THEN
		LET rm_datdoc.subtipo = 23
	END IF
	LET rm_datdoc.moneda    = rm_p21.p21_moneda
	LET rm_datdoc.paridad   = rm_p21.p21_paridad
	LET rm_datdoc.valor_doc = rm_p21.p21_valor
	LET rm_datdoc.glosa_adi = NULL
	LET rm_datdoc.flag_mod  = 2	-- Modulo
	CALL fl_contabilizacion_documentos(rm_datdoc.*) RETURNING r_b12.*, resul
	IF int_flag AND resul = 0 THEN
		WHENEVER ERROR STOP
		ROLLBACK WORK
		EXIT PROGRAM
	END IF
	IF resul THEN
		INSERT INTO cxpt040
			VALUES (rm_p21.p21_compania, rm_p21.p21_localidad,
					rm_p21.p21_codprov, rm_p21.p21_tipo_doc, rm_p21.p21_num_doc,
					r_b12.b12_tipo_comp, r_b12.b12_num_comp)
	END IF
WHENEVER ERROR STOP
COMMIT WORK
IF resul THEN
	CALL fl_lee_compania_contabilidad(vg_codcia) RETURNING r_b00.*
	IF r_b12.b12_compania IS NOT NULL AND r_b00.b00_mayo_online = 'S' THEN
		CALL fl_mayoriza_comprobante(r_b12.b12_compania, r_b12.b12_tipo_comp,
										r_b12.b12_num_comp, 'M')
	END IF
	CALL fl_hacer_pregunta('Desea ver contabilización generada?','No')
		RETURNING resp
	IF resp = 'Yes' THEN
		CALL ver_contabilizacion(r_b12.b12_tipo_comp, r_b12.b12_num_comp)
	END IF
END IF
IF vm_num_rows = vm_max_rows THEN
	LET vm_num_rows = 1
ELSE
	LET vm_num_rows = vm_num_rows + 1
END IF
DISPLAY BY NAME rm_p21.p21_fecing
LET vm_row_current = vm_num_rows
LET vm_r_rows[vm_row_current] = num_aux
CALL muestra_contadores(vm_row_current, vm_num_rows)
CALL mostrar_registro(vm_r_rows[vm_num_rows])	
CALL fl_mensaje_registro_ingresado()

END FUNCTION



FUNCTION control_consulta()
DEFINE cod_aux		LIKE cxpt002.p02_codprov
DEFINE nom_aux		LIKE cxpt001.p01_nomprov
DEFINE codt_aux		LIKE cxpt004.p04_tipo_doc
DEFINE nomt_aux		LIKE cxpt004.p04_nombre
DEFINE codte_aux	LIKE gent012.g12_tiporeg
DEFINE codst_aux	LIKE gent012.g12_subtipo
DEFINE nomte_aux	LIKE gent012.g12_nombre
DEFINE nomst_aux	LIKE gent011.g11_nombre
DEFINE mone_aux		LIKE gent013.g13_moneda
DEFINE nomm_aux		LIKE gent013.g13_nombre
DEFINE deci_aux		LIKE gent013.g13_decimales
DEFINE r_cxp		RECORD LIKE cxpt021.*
DEFINE query		CHAR(800)
DEFINE expr_sql		CHAR(800)
DEFINE num_reg		INTEGER

CLEAR FORM
INITIALIZE cod_aux, codt_aux, codte_aux, codst_aux, mone_aux, r_cxp.* TO NULL
LET int_flag = 0
IF num_args() = 4 THEN
	CONSTRUCT BY NAME expr_sql ON p21_codprov, p21_tipo_doc, p21_num_doc,
	p21_subtipo, p21_referencia, p21_fecha_emi, p21_moneda, p21_valor,
	p21_saldo, p21_origen, p21_usuario, p21_fecing
        ON KEY(F1,CONTROL-W)
		CALL llamar_visor_teclas()
	ON KEY(F2)
		IF INFIELD(p21_codprov) THEN
			CALL fl_ayuda_proveedores_localidad(vg_codcia,vg_codloc)
				RETURNING cod_aux, nom_aux
			LET int_flag = 0
			IF cod_aux IS NOT NULL THEN
				DISPLAY cod_aux TO p21_codprov 
				DISPLAY nom_aux TO tit_nombre_pro
			END IF 
		END IF
		IF INFIELD(p21_tipo_doc) THEN
			CALL fl_ayuda_tipo_documento_tesoreria('F')
				RETURNING codt_aux, nomt_aux
			LET int_flag = 0
			IF codt_aux IS NOT NULL THEN
				DISPLAY codt_aux TO p21_tipo_doc
				DISPLAY nomt_aux TO tit_tipo_doc
			END IF 
		END IF
		IF INFIELD(p21_num_doc) THEN
			CALL fl_ayuda_doc_favor_tes(vg_codcia, vg_codloc,
					cod_aux, codt_aux)
				RETURNING nom_aux, r_cxp.p21_tipo_doc,
					r_cxp.p21_num_doc, r_cxp.p21_saldo,
					r_cxp.p21_moneda
			LET int_flag = 0
			IF r_cxp.p21_num_doc IS NOT NULL THEN
				DISPLAY r_cxp.p21_num_doc TO p21_num_doc
				DISPLAY r_cxp.p21_saldo TO p21_saldo
			END IF 
		END IF
		IF INFIELD(p21_subtipo) THEN
			CALL fl_ayuda_subtipo_entidad(codt_aux)
				RETURNING codte_aux, codst_aux, nomte_aux,
					nomst_aux
			LET int_flag = 0
			IF codte_aux IS NOT NULL THEN
				DISPLAY codst_aux TO p21_subtipo
				DISPLAY nomte_aux TO tit_subtipo
			END IF 
		END IF
		IF INFIELD(p21_moneda) THEN
			CALL fl_ayuda_monedas()
				RETURNING mone_aux, nomm_aux, deci_aux
			LET int_flag = 0
			IF mone_aux IS NOT NULL THEN
				DISPLAY mone_aux TO p21_moneda 
				DISPLAY nomm_aux TO tit_mon_bas
			END IF 
		END IF
		AFTER FIELD p21_origen
			LET rm_p21.p21_origen = get_fldbuf(p21_origen)
			IF vg_gui = 0 THEN
				IF rm_p21.p21_origen IS NOT NULL THEN
					CALL muestra_origen(rm_p21.p21_origen)
				ELSE
					CLEAR tit_origen
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
	LET expr_sql = ' p21_codprov   = ' || arg_val(5) ||
		   ' AND p21_tipo_doc  = ' || '"' || arg_val(6) || '"' ||
		   ' AND p21_num_doc   = ' || arg_val(7)
END IF
LET query = 'SELECT *, ROWID FROM cxpt021 ' ||
		'WHERE p21_compania  = ' || vg_codcia ||
		'  AND p21_localidad = ' || vg_codloc ||
		'  AND ' || expr_sql CLIPPED ||
		' ORDER BY 3,4,13,5,6'
PREPARE cons FROM query	
DECLARE q_cons CURSOR FOR cons
LET vm_num_rows = 0
FOREACH q_cons INTO rm_p21.*, num_reg
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
DEFINE r_cxp_aux	RECORD LIKE cxpt021.*
DEFINE r_pro		RECORD LIKE cxpt002.*
DEFINE r_pro_gen	RECORD LIKE cxpt001.*
DEFINE r_tip		RECORD LIKE cxpt004.*
DEFINE r_sub		RECORD LIKE gent012.*
DEFINE r_mon		RECORD LIKE gent013.*
DEFINE r_mon_par	RECORD LIKE gent014.*
DEFINE cod_aux		LIKE cxpt002.p02_codprov
DEFINE nom_aux		LIKE cxpt001.p01_nomprov
DEFINE codt_aux		LIKE cxpt004.p04_tipo_doc
DEFINE nomt_aux		LIKE cxpt004.p04_nombre
DEFINE codte_aux	LIKE gent012.g12_tiporeg
DEFINE codst_aux	LIKE gent012.g12_subtipo
DEFINE nomte_aux	LIKE gent012.g12_nombre
DEFINE nomst_aux	LIKE gent011.g11_nombre
DEFINE mone_aux		LIKE gent013.g13_moneda
DEFINE nomm_aux		LIKE gent013.g13_nombre
DEFINE deci_aux		LIKE gent013.g13_decimales
DEFINE fecha_emi	LIKE cxpt021.p21_fecha_emi

INITIALIZE r_cxp_aux.*, r_pro.*, r_pro_gen.*, r_tip.*, r_sub.*, r_mon.*,
	r_mon_par.*, cod_aux, codt_aux, codte_aux, codst_aux, mone_aux TO NULL
DISPLAY BY NAME rm_p21.p21_fecha_emi, rm_p21.p21_paridad, rm_p21.p21_valor,
		rm_p21.p21_saldo, rm_p21.p21_origen, rm_p21.p21_usuario,
		rm_p21.p21_fecing
IF vg_gui = 0 THEN
	CALL muestra_origen(rm_p21.p21_origen)
END IF
LET flag_impto = 'S'
LET int_flag   = 0
INPUT BY NAME rm_p21.p21_codprov, rm_p21.p21_tipo_doc, flag_impto,
			  rm_p21.p21_num_doc, rm_p21.p21_subtipo, rm_p21.p21_referencia,
			  rm_p21.p21_fecha_emi, rm_p21.p21_moneda, val_base,
			  rm_p21.p21_valor
	WITHOUT DEFAULTS
	ON KEY(INTERRUPT)
		IF NOT FIELD_TOUCHED(rm_p21.p21_codprov, rm_p21.p21_tipo_doc,
							 flag_impto, rm_p21.p21_num_doc, rm_p21.p21_subtipo,
							 rm_p21.p21_referencia, rm_p21.p21_fecha_emi,
							 rm_p21.p21_moneda, val_base, rm_p21.p21_valor)
		THEN
			LET int_flag = 1
			EXIT INPUT
		END IF
		LET int_flag = 0
		CALL fl_mensaje_abandonar_proceso() RETURNING resp
		IF resp = 'Yes' THEN
			CLEAR FORM
			LET int_flag = 1
			EXIT INPUT
		END IF
	ON KEY(F1,CONTROL-W)
		CALL llamar_visor_teclas()
	ON KEY(F2)
		IF INFIELD(p21_codprov) THEN
			CALL fl_ayuda_proveedores_localidad(vg_codcia,vg_codloc)
				RETURNING cod_aux, nom_aux
			LET int_flag = 0
			IF cod_aux IS NOT NULL THEN
				LET rm_p21.p21_codprov = cod_aux
				DISPLAY BY NAME rm_p21.p21_codprov 
				DISPLAY nom_aux TO tit_nombre_pro
			END IF 
		END IF
		IF INFIELD(p21_tipo_doc) THEN
			CALL fl_ayuda_tipo_documento_tesoreria('F')
				RETURNING codt_aux, nomt_aux
			LET int_flag = 0
			IF codt_aux IS NOT NULL THEN
				LET rm_p21.p21_tipo_doc = codt_aux
				DISPLAY BY NAME rm_p21.p21_tipo_doc
				DISPLAY nomt_aux TO tit_tipo_doc
			END IF 
		END IF
		IF INFIELD(p21_subtipo) THEN
			CALL fl_ayuda_subtipo_entidad(rm_p21.p21_tipo_doc)
				RETURNING codte_aux, codst_aux, nomte_aux,
					nomst_aux
			LET int_flag = 0
			IF codte_aux IS NOT NULL THEN
				LET rm_p21.p21_subtipo = codst_aux
				DISPLAY BY NAME rm_p21.p21_subtipo
				DISPLAY nomte_aux TO tit_subtipo
			END IF 
		END IF
		IF INFIELD(p21_moneda) THEN
			CALL fl_ayuda_monedas()
				RETURNING mone_aux, nomm_aux, deci_aux
			LET int_flag = 0
			IF mone_aux IS NOT NULL THEN
				LET rm_p21.p21_moneda = mone_aux
				DISPLAY BY NAME rm_p21.p21_moneda 
				DISPLAY nomm_aux TO tit_mon_bas
			END IF 
		END IF
	BEFORE INPUT
		--#CALL dialog.keysetlabel("F1","")
		--#CALL dialog.keysetlabel("CONTROL-W","")
	BEFORE FIELD p21_fecha_emi
		LET fecha_emi = rm_p21.p21_fecha_emi
	AFTER FIELD p21_codprov
		IF rm_p21.p21_codprov IS NOT NULL THEN
			CALL fl_lee_proveedor(rm_p21.p21_codprov)
		 		RETURNING r_pro_gen.*
			IF r_pro_gen.p01_codprov IS NULL THEN
				CALL fl_mostrar_mensaje('Proveedor no existe.','exclamation')
				NEXT FIELD p21_codprov
			END IF
			DISPLAY r_pro_gen.p01_nomprov TO tit_nombre_pro
			IF r_pro_gen.p01_estado = 'B' THEN
                                CALL fl_mensaje_estado_bloqueado()
                                NEXT FIELD p21_codprov
                        END IF		 
			CALL fl_lee_proveedor_localidad(vg_codcia, vg_codloc,
							rm_p21.p21_codprov)
		 		RETURNING r_pro.*
			IF r_pro.p02_compania IS NULL THEN
				CALL fl_mostrar_mensaje('Proveedor no está activado para la compañía.','exclamation')
				NEXT FIELD p21_codprov
			END IF
		ELSE
			CLEAR tit_nombre_pro
		END IF
	AFTER FIELD p21_tipo_doc 
		IF rm_p21.p21_tipo_doc IS NOT NULL THEN
			CALL calcula_valores()
			CALL fl_lee_tipo_doc(rm_p21.p21_tipo_doc)
				RETURNING r_tip.* 
			IF r_tip.p04_tipo_doc IS NULL THEN
				CALL fl_mostrar_mensaje('Tipo de documento no existe.','exclamation')
				NEXT FIELD p21_tipo_doc
			END IF
			DISPLAY r_tip.p04_nombre TO tit_tipo_doc
			IF r_tip.p04_tipo <> 'F' THEN
				CALL fl_mostrar_mensaje('Tipo de documento debe ser a favor.','exclamation')
				NEXT FIELD p21_tipo_doc
			END IF
			IF rm_p21.p21_tipo_doc <> 'NC' THEN
				CALL fl_mostrar_mensaje('Los pagos anticipados entran por caja.','exclamation')
				NEXT FIELD p21_tipo_doc
			END IF
			IF r_tip.p04_estado = 'B' THEN
                                CALL fl_mensaje_estado_bloqueado()
				NEXT FIELD p21_tipo_doc
			END IF
		ELSE
			CLEAR tit_tipo_doc
		END IF
	AFTER FIELD p21_num_doc 
		IF rm_p21.p21_num_doc IS NULL THEN
			LET rm_p21.p21_num_doc = 0
			DISPLAY BY NAME rm_p21.p21_num_doc
		END IF
	AFTER FIELD flag_impto
		CALL calcula_valores()
	AFTER FIELD p21_subtipo
		IF rm_p21.p21_subtipo IS NOT NULL THEN
			CALL fl_lee_subtipo_entidad(rm_p21.p21_tipo_doc, rm_p21.p21_subtipo)
				RETURNING r_sub.*
			IF r_sub.g12_tiporeg IS NULL THEN
				CALL fl_mostrar_mensaje('No existe este subtipo de documento.','exclamation')
				NEXT FIELD p21_subtipo
			END IF
			DISPLAY r_sub.g12_nombre TO tit_subtipo
		END IF
	AFTER FIELD p21_moneda 
		IF rm_p21.p21_moneda IS NOT NULL THEN
			CALL fl_lee_moneda(rm_p21.p21_moneda)
				RETURNING r_mon.* 
			IF r_mon.g13_moneda IS NULL THEN
				CALL fl_mostrar_mensaje('Moneda no existe.','exclamation')
				NEXT FIELD p21_moneda
			END IF
			DISPLAY r_mon.g13_nombre TO tit_mon_bas
			IF r_mon.g13_estado = 'B' THEN
				CALL fl_mensaje_estado_bloqueado()
				NEXT FIELD p21_moneda
			END IF
			IF rm_p21.p21_moneda = rg_gen.g00_moneda_base THEN
				LET r_mon_par.g14_tasa = 1
			ELSE
				CALL fl_lee_factor_moneda(rm_p21.p21_moneda,
							rg_gen.g00_moneda_base)
					RETURNING r_mon_par.*
				IF r_mon_par.g14_serial IS NULL THEN
					CALL fl_mostrar_mensaje('La paridad para está moneda no existe.','exclamation')
					NEXT FIELD p21_moneda
				END IF
			END IF
			LET rm_p21.p21_paridad = r_mon_par.g14_tasa
			DISPLAY BY NAME rm_p21.p21_paridad
		ELSE
			LET rm_p21.p21_moneda = rg_gen.g00_moneda_base
			DISPLAY BY NAME rm_p21.p21_moneda
			CALL fl_lee_moneda(rm_p21.p21_moneda) RETURNING r_mon.* 
			DISPLAY r_mon.g13_nombre TO tit_mon_bas
		END IF
	AFTER FIELD p21_fecha_emi
		IF rm_p21.p21_fecha_emi IS NOT NULL THEN
			IF rm_p21.p21_fecha_emi > vg_fecha
			OR (MONTH(rm_p21.p21_fecha_emi) <> MONTH(vg_fecha)
			OR YEAR(rm_p21.p21_fecha_emi) <> YEAR(vg_fecha)) THEN
				CALL fl_mostrar_mensaje('La fecha de emisión debe ser de hoy o del presente mes.','exclamation')
				NEXT FIELD p21_fecha_emi
			END IF
		ELSE
			LET rm_p21.p21_fecha_emi = fecha_emi
			DISPLAY BY NAME rm_p21.p21_fecha_emi
		END IF
	AFTER FIELD val_base
		IF val_base IS NULL THEN
			LET val_base = 0
		END IF
		CALL fl_retorna_precision_valor(rm_p21.p21_moneda, val_base)
			RETURNING val_base
		DISPLAY BY NAME val_base
		CALL calcula_valores()
	AFTER FIELD p21_valor
		IF rm_p21.p21_valor IS NOT NULL THEN
			CALL fl_retorna_precision_valor(rm_p21.p21_moneda,
                                                        rm_p21.p21_valor)
                                RETURNING rm_p21.p21_valor
			LET rm_p21.p21_saldo = rm_p21.p21_valor
			DISPLAY BY NAME rm_p21.p21_saldo
		ELSE
			LET rm_p21.p21_valor = 0
			LET rm_p21.p21_saldo = rm_p21.p21_valor
			DISPLAY BY NAME rm_p21.p21_valor, rm_p21.p21_saldo
		END IF
	AFTER INPUT
		CALL calcula_valores()
		CALL fl_lee_documento_favor_cxp(vg_codcia, vg_codloc,
										rm_p21.p21_codprov, rm_p21.p21_tipo_doc,
										rm_p21.p21_num_doc)
			RETURNING r_cxp_aux.*
		IF r_cxp_aux.p21_compania IS NOT NULL THEN
			CALL fl_mostrar_mensaje('Documento ya ha sido ingresado.','exclamation')
			NEXT FIELD rm_p21.p21_codprov
		END IF
		IF rm_p21.p21_valor <= 0 THEN
			CALL fl_mostrar_mensaje('El documento no puede grabarse con valor original de cero.','exclamation')
			NEXT FIELD p21_valor
		END IF
		LET rm_p21.p21_saldo = rm_p21.p21_valor
		IF rm_p21.p21_tipo_doc = 'NC' THEN
			LET rm_p21.p21_num_doc = NULL
		END IF
END INPUT

END FUNCTION



FUNCTION calcula_valores()

IF flag_impto = 'S' THEN
	LET rm_p21.p21_val_impto = val_base * rg_gen.g00_porc_impto / 100
	CALL fl_retorna_precision_valor(rm_p21.p21_moneda, rm_p21.p21_val_impto)
		RETURNING rm_p21.p21_val_impto
ELSE
	LET rm_p21.p21_val_impto = 0
END IF
LET rm_p21.p21_valor = val_base + rm_p21.p21_val_impto
LET rm_p21.p21_saldo = rm_p21.p21_valor
DISPLAY BY NAME rm_p21.p21_valor, rm_p21.p21_val_impto, rm_p21.p21_saldo

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
DEFINE r_pro_gen	RECORD LIKE cxpt001.*
DEFINE r_tip		RECORD LIKE cxpt004.*
DEFINE r_sub		RECORD LIKE gent012.*
DEFINE r_mon		RECORD LIKE gent013.*
DEFINE num_registro	INTEGER

IF vm_num_rows <= 0 THEN
	RETURN
END IF
SELECT * INTO rm_p21.* FROM cxpt021 WHERE ROWID = num_registro
IF STATUS = NOTFOUND THEN
	CALL fl_mostrar_mensaje('No existe registro con índice: ' || vm_row_current,'exclamation')
	RETURN
END IF
IF num_args() = 8 THEN
	IF arg_val(8) < vg_fecha THEN
		CALL obtener_saldo_a_favor_fecha()
	END IF
END IF
LET flag_impto = 'N'
IF rm_p21.p21_val_impto > 0 THEN
	LET flag_impto = 'S'
END IF
LET val_base = rm_p21.p21_valor - rm_p21.p21_val_impto
DISPLAY BY NAME rm_p21.p21_codprov, rm_p21.p21_tipo_doc, flag_impto,
				rm_p21.p21_num_doc, rm_p21.p21_subtipo, rm_p21.p21_referencia,
				rm_p21.p21_fecha_emi, rm_p21.p21_moneda, rm_p21.p21_paridad,
				val_base, rm_p21.p21_val_impto, rm_p21.p21_valor,
				rm_p21.p21_saldo, rm_p21.p21_origen, rm_p21.p21_cod_tran,
				rm_p21.p21_num_tran, rm_p21.p21_usuario, rm_p21.p21_fecing
CALL fl_lee_proveedor(rm_p21.p21_codprov) RETURNING r_pro_gen.*
CALL fl_lee_tipo_doc(rm_p21.p21_tipo_doc) RETURNING r_tip.* 
DISPLAY r_tip.p04_nombre TO tit_tipo_doc
CALL fl_lee_subtipo_entidad(rm_p21.p21_tipo_doc,rm_p21.p21_subtipo)
	RETURNING r_sub.*
DISPLAY r_sub.g12_nombre TO tit_subtipo
CALL fl_lee_moneda(rm_p21.p21_moneda) RETURNING r_mon.* 
DISPLAY r_mon.g13_nombre TO tit_mon_bas
DISPLAY r_pro_gen.p01_nomprov TO tit_nombre_pro
IF vg_gui = 0 THEN
	CALL muestra_origen(rm_p21.p21_origen)
END IF

END FUNCTION



FUNCTION obtener_saldo_a_favor_fecha()
DEFINE r_z60		RECORD LIKE cxct060.*
DEFINE fecha		LIKE cxpt022.p22_fecing
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
LET subquery1 = '(SELECT SUM(p23_valor_cap + p23_valor_int) ',
		' FROM cxpt023, cxpt022 ',
		' WHERE p23_compania   = p21_compania ',
		'   AND p23_localidad  = p21_localidad ',
		'   AND p23_codprov    = p21_codprov ',
		'   AND p23_tipo_favor = p21_tipo_doc ',
		'   AND p23_doc_favor  = p21_num_doc ',
		'   AND p22_compania   = p23_compania ',
		'   AND p22_localidad  = p23_localidad ',
		'   AND p22_codprov    = p23_codprov ',
		'   AND p22_tipo_trn   = p23_tipo_trn ',
		'   AND p22_num_trn    = p23_num_trn ',
		'   AND p22_fecing     BETWEEN EXTEND(p21_fecha_emi, ',
						'YEAR TO SECOND)',
					 ' AND "', fecha, '")'
LET subquery2 = '(SELECT NVL(SUM(p23_valor_cap + p23_valor_int), 0) ',
		' FROM cxpt023 ',
		' WHERE p23_compania   = p21_compania ',
		'   AND p23_localidad  = p21_localidad ',
		'   AND p23_codprov    = p21_codprov ',
		'   AND p23_tipo_favor = p21_tipo_doc ',
		'   AND p23_doc_favor  = p21_num_doc) '
LET query = 'SELECT NVL(CASE WHEN p21_fecha_emi > "', fec_ini, '"',
			' THEN p21_valor + ', subquery1 CLIPPED,
			' ELSE ', subquery2 CLIPPED, ' + p21_saldo - ',
				  subquery1 CLIPPED,
		' END, ',
		' CASE WHEN p21_fecha_emi <= "', fec_ini, '"',
			' THEN p21_saldo - ', subquery2 CLIPPED,
			' ELSE p21_valor',
		' END) saldo_doc ',
		' FROM cxpt021 ',
		' WHERE p21_compania   = ', rm_p21.p21_compania,
		'   AND p21_localidad  = ', rm_p21.p21_localidad,
		'   AND p21_codprov    = ', rm_p21.p21_codprov,
		'   AND p21_tipo_doc   = "', rm_p21.p21_tipo_doc, '"',
		'   AND p21_num_doc    = ', rm_p21.p21_num_doc,
		'   AND p21_fecha_emi <= "', arg_val(8), '"',
		' INTO TEMP t1 '
PREPARE stmnt2 FROM query
EXECUTE stmnt2
SELECT NVL(saldo_doc, 0) INTO rm_p21.p21_saldo FROM t1
DROP TABLE t1
ERROR ' '

END FUNCTION



FUNCTION muestra_origen(origen)
DEFINE origen		CHAR(1)

CASE origen
	WHEN 'M'
		DISPLAY 'MANUAL' TO tit_origen
	WHEN 'A'
		DISPLAY 'AUTOMATICO' TO tit_origen
	OTHERWISE
		CLEAR p21_origen, tit_origen
END CASE

END FUNCTION



{XXX ESTA FUNCION SIRVE PARA CONSULTA, INGRESAR O MODIFICAR LOS VALORES DE:
	- p21_num_sri
	- p21_num_aut
	- p21_fec_emi_nc
	- p21_fec_emi_aut
XXX}

FUNCTION control_datos_adicionales_nc(flag_mant)
DEFINE flag_mant		CHAR(1)
DEFINE r_p21, r_p21_2	RECORD LIKE cxpt021.*
DEFINE r_p01			RECORD LIKE cxpt001.*
DEFINE lim				SMALLINT
DEFINE numero			VARCHAR(30)
DEFINE resp				CHAR(6)
DEFINE tecla			CHAR(1)

OPEN WINDOW w_cxpf201_2 AT 08, 03 WITH 11 ROWS, 76 COLUMNS
	ATTRIBUTE(FORM LINE FIRST + 1, COMMENT LINE LAST, MENU LINE 0,
				BORDER, MESSAGE LINE LAST) 
IF vg_gui = 1 THEN
	OPEN FORM f_cxpf201_2 FROM "../forms/cxpf201_2"
ELSE
	OPEN FORM f_cxpf201_2 FROM "../forms/cxpf201_2c"
END IF
DISPLAY FORM f_cxpf201_2
IF num_args() <> 4 THEN
	DISPLAY BY NAME rm_p21.p21_num_sri, rm_p21.p21_num_aut,
					rm_p21.p21_fec_emi_nc, rm_p21.p21_fec_emi_aut
	MESSAGE 'Presione cualquier tecla para continuar ...'
	LET tecla = fgl_getkey()
	CLOSE WINDOW w_cxpf201_2
	RETURN
END IF
INITIALIZE r_p21.* TO NULL
LET r_p21.* = rm_p21.*
CALL fl_lee_proveedor(rm_p21.p21_codprov) RETURNING r_p01.*
IF rm_p21.p21_num_aut IS NULL THEN
	LET rm_p21.p21_num_aut = r_p01.p01_num_aut
END IF
IF rm_p21.p21_num_sri IS NULL THEN
	LET rm_p21.p21_num_sri = r_p01.p01_serie_comp[1, 3], '-',
								r_p01.p01_serie_comp[4, 6], '-'
END IF
LET int_flag = 0
INPUT BY NAME rm_p21.p21_num_sri, rm_p21.p21_num_aut, rm_p21.p21_fec_emi_nc,
			  rm_p21.p21_fec_emi_aut
	WITHOUT DEFAULTS
	ON KEY(INTERRUPT)
		IF NOT FIELD_TOUCHED(rm_p21.p21_num_sri, rm_p21.p21_num_aut,
							 rm_p21.p21_fec_emi_nc, rm_p21.p21_fec_emi_aut)
		THEN
			LET int_flag = 1
			EXIT INPUT
		END IF
		LET int_flag = 0
		CALL fl_mensaje_abandonar_proceso() RETURNING resp
		IF resp = 'Yes' THEN
			CLEAR FORM
			LET int_flag = 1
			EXIT INPUT
		END IF
	AFTER INPUT
		LET lim = LENGTH(rm_p21.p21_num_sri)
		IF lim <> 17 AND num_args() = 4 THEN
			CALL fl_mostrar_mensaje('La longitud del numero SRI es diferente de la longitud reglamentaria (17).', 'exclamation')
			CONTINUE INPUT
		END IF
		LET numero = rm_p21.p21_num_sri[9, lim]
		IF NOT fl_valida_numeros(numero) THEN
			CALL fl_mostrar_mensaje('El numero de secuencia de la N/C no es valido.', 'exclamation')
			CONTINUE INPUT
		END IF
		IF rm_p21.p21_num_sri IS NOT NULL AND rm_p21.p21_fec_emi_nc IS NULL THEN
			CALL fl_mostrar_mensaje('Por favor también ingrese la fecha de emision de la N/C.', 'exclamation')
			NEXT FIELD p21_fec_emi_nc
		END IF
END INPUT
IF flag_mant = 'I' OR int_flag THEN
	IF int_flag THEN
		LET rm_p21.* = r_p21.*
	END IF
	CLOSE WINDOW w_cxpf201_2
	RETURN
END IF
BEGIN WORK
WHENEVER ERROR CONTINUE
	DECLARE q_p21 CURSOR FOR
		SELECT * FROM cxpt021
			WHERE p21_compania  = rm_p21.p21_compania
			  AND p21_localidad = rm_p21.p21_localidad
			  AND p21_codprov   = rm_p21.p21_codprov
			  AND p21_tipo_doc  = rm_p21.p21_tipo_doc
			  AND p21_num_doc   = rm_p21.p21_num_doc
		FOR UPDATE
	INITIALIZE r_p21_2.* TO NULL
	OPEN q_p21
	FETCH q_p21 INTO r_p21_2.*
	IF STATUS <> 0 THEN
		WHENEVER ERROR STOP
		ROLLBACK WORK
		CALL fl_mostrar_mensaje('Este registro esta bloqueado para actualizar. Por favor llame al ADMINISTRADOR', 'stop')
		CLOSE WINDOW w_cxpf201_2
		RETURN
	END IF
	UPDATE cxpt021
		SET p21_num_sri     = rm_p21.p21_num_sri,
		    p21_num_aut     = rm_p21.p21_num_aut,
		    p21_fec_emi_nc  = rm_p21.p21_fec_emi_nc,
		    p21_fec_emi_aut = rm_p21.p21_fec_emi_aut
		WHERE CURRENT OF q_p21
	IF STATUS <> 0 THEN
		WHENEVER ERROR STOP
		ROLLBACK WORK
		CALL fl_mostrar_mensaje('No se pudo actualizar los datos adicionales de la N/C. Por favor llame al ADMINISTRADOR', 'stop')
		CLOSE WINDOW w_cxpf201_2
		RETURN
	END IF
WHENEVER ERROR STOP
COMMIT WORK
CLOSE WINDOW w_cxpf201_2
CALL fl_mostrar_mensaje('Se actualizo los datos adicionales de la N/C. OK', 'info')
RETURN

END FUNCTION



FUNCTION control_contabilizar()
DEFINE r_p40		RECORD LIKE cxpt040.*

INITIALIZE r_p40.* TO NULL
SELECT * INTO r_p40.* FROM cxpt040
	WHERE p40_compania  = rm_p21.p21_compania
	  AND p40_localidad = rm_p21.p21_localidad
	  AND p40_codprov   = rm_p21.p21_codprov
	  AND p40_tipo_doc  = rm_p21.p21_tipo_doc
	  AND p40_num_doc   = rm_p21.p21_num_doc
IF r_p40.p40_compania IS NULL THEN
	CALL fl_mostrar_mensaje('Este documento no tiene contablización automatica.', 'exclamation')
	RETURN
END IF
CALL ver_contabilizacion(r_p40.p40_tipo_comp, r_p40.p40_num_comp)

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
