--------------------------------------------------------------------------------
-- Titulo           : cxpp200.4gl - Ingreso de documentos deudores 
-- Elaboracion      : 26-nov-2001
-- Autor            : NPC
-- Formato Ejecucion: fglrun cxpp200 base módulo compañía localidad
--			[proveedor tipo_docuemnto numero_documento dividendo]
-- Ultima Correccion: 
-- Motivo Correccion: 
--------------------------------------------------------------------------------
GLOBALS '../../../PRODUCCION/LIBRERIAS/fuentes/globales.4gl'

DEFINE rm_p20		RECORD LIKE cxpt020.*
DEFINE vm_num_rows	SMALLINT
DEFINE vm_row_current	SMALLINT
DEFINE vm_max_rows	SMALLINT
DEFINE vm_r_rows	ARRAY [1000] OF INTEGER
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
CALL startlog('../logs/cxpp200.err')
--#CALL fgl_init4js()
CALL fl_marca_registrada_producto()
IF num_args() <> 4 AND num_args() <> 8 AND num_args() <> 9 THEN
	-- Validar # parámetros correcto
	CALL fgl_winmessage(vg_producto, 'Número de parámetros incorrecto.', 'stop')
	EXIT PROGRAM
END IF
LET vg_base    = arg_val(1)
LET vg_modulo  = arg_val(2)
LET vg_codcia  = arg_val(3)
LET vg_codloc  = arg_val(4)
LET vg_proceso = 'cxpp200'
CALL fl_activar_base_datos(vg_base)
CALL fl_seteos_defaults()	
--#CALL fgl_settitle(vg_proceso || ' - ' || vg_producto)
CALL fl_validar_parametros()
CALL fl_cabecera_pantalla(vg_codcia, vg_codloc, vg_modulo, vg_proceso)
CALL control_master()

END MAIN



FUNCTION control_master()

CALL fl_nivel_isolation()
IF num_args() = 4 THEN
	CALL fl_chequeo_mes_proceso_cxp(vg_codcia) RETURNING int_flag 
	IF int_flag THEN
		RETURN
	END IF
END IF
LET vm_max_rows	= 1000
OPEN WINDOW wf AT 3,2 WITH 21 ROWS, 80 COLUMNS
    ATTRIBUTE(FORM LINE FIRST + 2, COMMENT LINE LAST, MENU LINE FIRST,BORDER,
	      MESSAGE LINE LAST - 2)
OPTIONS INPUT WRAP,
	ACCEPT KEY	F12
OPEN FORM f_cxp FROM "../forms/cxpf200_1"
DISPLAY FORM f_cxp
INITIALIZE rm_p20.* TO NULL
LET vm_num_rows    = 0
LET vm_row_current = 0
CALL muestra_contadores(vm_row_current, vm_num_rows)
MENU 'OPCIONES'
	BEFORE MENU
		HIDE OPTION 'Avanzar'
		HIDE OPTION 'Retroceder'
		HIDE OPTION 'Contabilización'
		IF num_args() >= 8 THEN
			HIDE OPTION 'Ingresar'
			HIDE OPTION 'Consultar'
			CALL control_consulta()
			IF vm_num_rows = 0 THEN
                                EXIT PROGRAM
                        END IF
			SHOW OPTION 'Contabilización'
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
			SHOW OPTION 'Contabilización'
		ELSE
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
			SHOW OPTION 'Contabilización'
		ELSE
			HIDE OPTION 'Contabilización'
                END IF
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
DEFINE r_mon            RECORD LIKE gent013.*
DEFINE r_b12		RECORD LIKE ctbt012.*
DEFINE r_b00		RECORD LIKE ctbt000.*
DEFINE resul		SMALLINT
DEFINE resp		CHAR(6)

CALL fl_retorna_usuario()
INITIALIZE rm_p20.*, r_mon.* TO NULL
CLEAR p20_paridad, p20_saldo_cap, p20_saldo_int, p20_valor_fact, tit_nombre_pro,
	tit_tipo_doc, tit_mon_bas, tit_cartera, n_depto
LET rm_p20.p20_compania    = vg_codcia
LET rm_p20.p20_localidad   = vg_codloc
LET rm_p20.p20_dividendo   = 1
LET rm_p20.p20_fecha_emi   = CURRENT
LET rm_p20.p20_tasa_int    = 0 
LET rm_p20.p20_tasa_mora   = 0
LET rm_p20.p20_moneda      = rg_gen.g00_moneda_base
LET rm_p20.p20_valor_cap   = 0
LET rm_p20.p20_valor_int   = 0
LET rm_p20.p20_valor_fact  = 0
LET rm_p20.p20_porc_impto  = 0
LET rm_p20.p20_valor_impto = 0
LET rm_p20.p20_saldo_cap   = 0
LET rm_p20.p20_saldo_int   = 0
LET rm_p20.p20_paridad     = 1
LET rm_p20.p20_origen      = 'M'
LET rm_p20.p20_usuario     = vg_usuario
LET rm_p20.p20_fecing      = CURRENT
CALL fl_lee_moneda(rm_p20.p20_moneda) RETURNING r_mon.*
IF r_mon.g13_moneda IS NULL THEN
        CALL fgl_winmessage(vg_producto,'No existe ninguna moneda base.','stop')
        EXIT PROGRAM
ELSE
        DISPLAY r_mon.g13_nombre TO tit_mon_bas
END IF
CALL leer_datos()
IF NOT int_flag THEN
	BEGIN WORK
		IF rm_p20.p20_tipo_doc = 'ND' THEN
			CALL fl_actualiza_control_secuencias(vg_codcia,
						vg_codloc, vg_modulo, 'AA',
						rm_p20.p20_tipo_doc)
				RETURNING rm_p20.p20_num_doc
			IF rm_p20.p20_num_doc <= '0' THEN
				ROLLBACK WORK
				EXIT PROGRAM
			END IF
			DISPLAY BY NAME rm_p20.p20_num_doc
		END IF
		LET rm_p20.p20_fecing = CURRENT
		INSERT INTO cxpt020 VALUES (rm_p20.*)
		LET num_aux = SQLCA.SQLERRD[6] 
		CALL fl_genera_saldos_proveedor(vg_codcia, vg_codloc,
						rm_p20.p20_codprov)
		LET rm_datdoc.codcia    = vg_codcia
		LET rm_datdoc.cliprov   = rm_p20.p20_codprov
		LET rm_datdoc.tipo_doc  = rm_p20.p20_tipo_doc
		LET rm_datdoc.num_doc   = rm_p20.p20_num_doc
		LET rm_datdoc.subtipo   = NULL
		IF rm_p20.p20_tipo_doc = 'ND' THEN
			LET rm_datdoc.subtipo = 21
		END IF
		LET rm_datdoc.moneda    = rm_p20.p20_moneda
		LET rm_datdoc.paridad   = rm_p20.p20_paridad
		LET rm_datdoc.valor_doc = rm_p20.p20_valor_cap
		LET rm_datdoc.glosa_adi = NULL
		LET rm_datdoc.flag_mod  = 2	-- Modulo
		CALL fl_contabilizacion_documentos(rm_datdoc.*)
			RETURNING r_b12.*, resul
		IF int_flag THEN
			IF resul = 0 THEN
				ROLLBACK WORK
				EXIT PROGRAM
			END IF
		END IF
		IF resul THEN
			INSERT INTO cxpt041
			VALUES (rm_p20.p20_compania, rm_p20.p20_localidad,
				rm_p20.p20_codprov, rm_p20.p20_tipo_doc,
				rm_p20.p20_num_doc, rm_p20.p20_dividendo,
				r_b12.b12_tipo_comp, r_b12.b12_num_comp)
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
	DISPLAY BY NAME rm_p20.p20_fecing
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
DEFINE cod_aux		LIKE cxpt002.p02_codprov
DEFINE nom_aux		LIKE cxpt001.p01_nomprov
DEFINE codt_aux		LIKE cxpt004.p04_tipo_doc
DEFINE nomt_aux		LIKE cxpt004.p04_nombre
DEFINE mone_aux		LIKE gent013.g13_moneda
DEFINE nomm_aux		LIKE gent013.g13_nombre
DEFINE deci_aux		LIKE gent013.g13_decimales
DEFINE codc_aux		LIKE gent012.g12_subtipo
DEFINE nomc_aux		LIKE gent012.g12_nombre
DEFINE r_cxp		RECORD LIKE cxpt020.*
DEFINE query		VARCHAR(800)
DEFINE expr_sql		VARCHAR(800)
DEFINE num_reg		INTEGER

DEFINE r_g34		RECORD LIKE gent034.*

CLEAR FORM
INITIALIZE cod_aux, codt_aux, mone_aux, codc_aux, r_cxp.* TO NULL
LET int_flag = 0
IF num_args() = 4 THEN
	CONSTRUCT BY NAME expr_sql ON p20_codprov, p20_tipo_doc, p20_num_doc,
	p20_dividendo, p20_referencia, p20_fecha_emi,
	p20_fecha_vcto, p20_tasa_int, p20_tasa_mora, p20_moneda, 
   	p20_valor_cap, p20_valor_int, p20_valor_fact, p20_porc_impto,
	p20_cod_depto, p20_cartera, p20_origen
	ON KEY(F2)
		IF INFIELD(p20_codprov) THEN
			CALL fl_ayuda_proveedores_localidad(vg_codcia,vg_codloc)
				RETURNING cod_aux, nom_aux
			LET int_flag = 0
			IF cod_aux IS NOT NULL THEN
				DISPLAY cod_aux TO p20_codprov 
				DISPLAY nom_aux TO tit_nombre_pro
			END IF 
		END IF
		IF INFIELD(p20_tipo_doc) THEN
			CALL fl_ayuda_tipo_documento_tesoreria('D')
				RETURNING codt_aux, nomt_aux
			LET int_flag = 0
			IF codt_aux IS NOT NULL THEN
				DISPLAY codt_aux TO p20_tipo_doc
				DISPLAY nomt_aux TO tit_tipo_doc
			END IF 
		END IF
		IF INFIELD(p20_num_doc) THEN
			CALL fl_ayuda_doc_deudores_tes(vg_codcia, vg_codloc,
					cod_aux, codt_aux)
				RETURNING nom_aux, r_cxp.p20_tipo_doc,
					r_cxp.p20_num_doc, r_cxp.p20_dividendo,
					r_cxp.p20_saldo_cap, r_cxp.p20_moneda
			LET int_flag = 0
			IF r_cxp.p20_num_doc IS NOT NULL THEN
				DISPLAY BY NAME r_cxp.p20_num_doc
				DISPLAY BY NAME r_cxp.p20_dividendo
			END IF 
		END IF
		IF INFIELD(p20_moneda) THEN
			CALL fl_ayuda_monedas()
				RETURNING mone_aux, nomm_aux, deci_aux
			LET int_flag = 0
			IF mone_aux IS NOT NULL THEN
				DISPLAY mone_aux TO p20_moneda 
				DISPLAY nomm_aux TO tit_mon_bas
			END IF 
		END IF
		IF INFIELD(p20_cartera) THEN
			CALL fl_ayuda_subtipo_cartera()
				RETURNING codc_aux, nomc_aux
			LET int_flag = 0
			IF codc_aux IS NOT NULL THEN
				DISPLAY codc_aux TO p20_cartera 
				DISPLAY nomc_aux TO tit_cartera
			END IF 
		END IF
                IF INFIELD(p20_cod_depto) THEN
                        CALL fl_ayuda_departamentos(vg_codcia)
                                RETURNING r_g34.g34_cod_depto,
                                          r_g34.g34_nombre
                        IF r_g34.g34_cod_depto IS NOT NULL THEN
                                LET rm_p20.p20_cod_depto = r_g34.g34_cod_depto
                                DISPLAY BY NAME rm_p20.p20_cod_depto
                                DISPLAY  r_g34.g34_nombre TO n_depto
                        END IF
                END IF
		LET int_flag = 0
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
	LET expr_sql = ' p20_codprov    = ' || arg_val(5) ||
		   ' AND p20_tipo_doc  = ' || '"' || arg_val(6) || '"' ||
		   ' AND p20_num_doc   = ' || '"' || arg_val(7) || '"' ||
		   ' AND p20_dividendo = ' || arg_val(8)
END IF
LET query = 'SELECT *, ROWID FROM cxpt020 ' ||
		'WHERE p20_compania  = ' || vg_codcia ||
		'  AND p20_localidad = ' || vg_codloc ||
		'  AND ' || expr_sql CLIPPED ||
		' ORDER BY 3,4,5,6'
PREPARE cons FROM query	
DECLARE q_cons CURSOR FOR cons
LET vm_num_rows = 0
FOREACH q_cons INTO rm_p20.*, num_reg
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



FUNCTION leer_datos ()
DEFINE resp		CHAR(6)
DEFINE r_cxp_aux	RECORD LIKE cxpt020.*
DEFINE r_pro		RECORD LIKE cxpt002.*
DEFINE r_pro_gen	RECORD LIKE cxpt001.*
DEFINE r_tip		RECORD LIKE cxpt004.*
DEFINE r_mon		RECORD LIKE gent013.*
DEFINE r_mon_par	RECORD LIKE gent014.*
DEFINE r_car		RECORD LIKE gent012.*
DEFINE r_g34		RECORD LIKE gent034.*
DEFINE cod_aux		LIKE cxpt002.p02_codprov
DEFINE nom_aux		LIKE cxpt001.p01_nomprov
DEFINE codt_aux		LIKE cxpt004.p04_tipo_doc
DEFINE nomt_aux		LIKE cxpt004.p04_nombre
DEFINE mone_aux		LIKE gent013.g13_moneda
DEFINE nomm_aux		LIKE gent013.g13_nombre
DEFINE deci_aux		LIKE gent013.g13_decimales
DEFINE codc_aux		LIKE gent012.g12_subtipo
DEFINE nomc_aux		LIKE gent012.g12_nombre
DEFINE r_cxp		RECORD LIKE cxpt020.*
DEFINE tasa_mora	LIKE cxpt020.p20_tasa_mora
DEFINE fecha_emi	LIKE cxpt020.p20_fecha_emi

INITIALIZE r_cxp_aux.*, r_pro.*, r_pro_gen.*, r_tip.*, r_mon.*, r_mon_par.*,
	r_car.*, cod_aux, codt_aux, mone_aux, codc_aux, r_cxp.* TO NULL
DISPLAY BY NAME rm_p20.p20_dividendo, rm_p20.p20_tasa_int, rm_p20.p20_tasa_mora,
		rm_p20.p20_fecha_emi, rm_p20.p20_paridad, rm_p20.p20_valor_cap,
		rm_p20.p20_valor_int, rm_p20.p20_porc_impto, rm_p20.p20_origen,
		rm_p20.p20_usuario, rm_p20.p20_fecing, rm_p20.p20_saldo_cap,
		rm_p20.p20_saldo_int, rm_p20.p20_valor_impto
LET int_flag = 0
INPUT BY NAME rm_p20.p20_codprov, rm_p20.p20_tipo_doc, rm_p20.p20_num_doc,
	rm_p20.p20_dividendo, rm_p20.p20_referencia, rm_p20.p20_fecha_emi,
	rm_p20.p20_fecha_vcto, rm_p20.p20_tasa_int, rm_p20.p20_tasa_mora,
	rm_p20.p20_moneda, rm_p20.p20_valor_cap, rm_p20.p20_valor_int,
	rm_p20.p20_valor_fact, rm_p20.p20_porc_impto, rm_p20.p20_cod_depto,
	rm_p20.p20_cartera
	WITHOUT DEFAULTS
	ON KEY(INTERRUPT)
	        IF FIELD_TOUCHED(rm_p20.p20_codprov, rm_p20.p20_tipo_doc,
			rm_p20.p20_num_doc,    rm_p20.p20_dividendo,
			rm_p20.p20_referencia, rm_p20.p20_fecha_emi,
			rm_p20.p20_fecha_vcto, rm_p20.p20_tasa_int,
			rm_p20.p20_tasa_mora,  rm_p20.p20_moneda,
			rm_p20.p20_valor_cap,  rm_p20.p20_valor_int,
			rm_p20.p20_valor_fact, rm_p20.p20_porc_impto,
			rm_p20.p20_cartera,    rm_p20.p20_cod_depto)
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
	ON KEY(F2)
		IF INFIELD(p20_codprov) THEN
			CALL fl_ayuda_proveedores_localidad(vg_codcia,vg_codloc)
				RETURNING cod_aux, nom_aux
			LET int_flag = 0
			IF cod_aux IS NOT NULL THEN
				LET rm_p20.p20_codprov = cod_aux
				DISPLAY BY NAME rm_p20.p20_codprov 
				DISPLAY nom_aux TO tit_nombre_pro
			END IF 
		END IF
		IF INFIELD(p20_tipo_doc) THEN
			CALL fl_ayuda_tipo_documento_tesoreria('D')
				RETURNING codt_aux, nomt_aux
			LET int_flag = 0
			IF codt_aux IS NOT NULL THEN
				LET rm_p20.p20_tipo_doc = codt_aux
				DISPLAY BY NAME rm_p20.p20_tipo_doc
				DISPLAY nomt_aux TO tit_tipo_doc
			END IF 
		END IF
		IF INFIELD(p20_num_doc) THEN
			CALL fl_ayuda_doc_deudores_tes(vg_codcia, vg_codloc,
					rm_p20.p20_codprov, rm_p20.p20_tipo_doc)
				RETURNING nom_aux, r_cxp.p20_tipo_doc,
					r_cxp.p20_num_doc, r_cxp.p20_dividendo,
					r_cxp.p20_saldo_cap, r_cxp.p20_moneda
			LET int_flag = 0
			IF r_cxp.p20_num_doc IS NOT NULL THEN
				LET rm_p20.p20_num_doc = r_cxp.p20_num_doc
				LET rm_p20.p20_dividendo = r_cxp.p20_dividendo
							+ 1
				DISPLAY BY NAME rm_p20.p20_num_doc
				DISPLAY BY NAME rm_p20.p20_dividendo
			END IF 
		END IF
		IF INFIELD(p20_moneda) THEN
			CALL fl_ayuda_monedas()
				RETURNING mone_aux, nomm_aux, deci_aux
			LET int_flag = 0
			IF mone_aux IS NOT NULL THEN
				LET rm_p20.p20_moneda = mone_aux
				DISPLAY BY NAME rm_p20.p20_moneda 
				DISPLAY nomm_aux TO tit_mon_bas
			END IF 
		END IF
		IF INFIELD(p20_cartera) THEN
			CALL fl_ayuda_subtipo_cartera()
				RETURNING codc_aux, nomc_aux
			LET int_flag = 0
			IF codc_aux IS NOT NULL THEN
				LET rm_p20.p20_cartera = codc_aux
				DISPLAY BY NAME rm_p20.p20_cartera 
				DISPLAY nomc_aux TO tit_cartera
			END IF 
		END IF
                IF INFIELD(p20_cod_depto) THEN
                        CALL fl_ayuda_departamentos(vg_codcia)
                                RETURNING r_g34.g34_cod_depto,
                                          r_g34.g34_nombre
                        IF r_g34.g34_cod_depto IS NOT NULL THEN
                                LET rm_p20.p20_cod_depto = r_g34.g34_cod_depto
                                DISPLAY BY NAME rm_p20.p20_cod_depto
                                DISPLAY  r_g34.g34_nombre TO n_depto
                        END IF
                END IF
		LET int_flag = 0
	BEFORE FIELD p20_fecha_emi
		LET fecha_emi = rm_p20.p20_fecha_emi
	BEFORE FIELD p20_fecha_vcto
		IF rm_p20.p20_fecha_emi IS NULL THEN
			CALL fgl_winmessage(vg_producto,'Ingrese la fecha de emisión primero.','info')
			NEXT FIELD p20_fecha_emi
		END IF
	BEFORE FIELD p20_tasa_mora
		LET tasa_mora = rm_p20.p20_tasa_mora
	AFTER FIELD p20_codprov
		IF rm_p20.p20_codprov IS NOT NULL THEN
			CALL fl_lee_proveedor(rm_p20.p20_codprov)
		 		RETURNING r_pro_gen.*
			IF r_pro_gen.p01_codprov IS NULL THEN
				CALL fgl_winmessage(vg_producto,'Proveedor no existe.','exclamation')
				NEXT FIELD p20_codprov
			END IF
			DISPLAY r_pro_gen.p01_nomprov TO tit_nombre_pro
			IF r_pro_gen.p01_estado = 'B' THEN
                                CALL fl_mensaje_estado_bloqueado()
                                NEXT FIELD p20_codprov
                        END IF		 
			CALL fl_lee_proveedor_localidad(vg_codcia, vg_codloc,
							rm_p20.p20_codprov)
		 		RETURNING r_pro.*
			IF r_pro.p02_compania IS NULL THEN
				CALL fgl_winmessage(vg_producto,'Proveedor no está activado para la compañía.','exclamation')
				NEXT FIELD p20_codprov
			END IF
		ELSE
			CLEAR tit_nombre_pro
		END IF
	AFTER FIELD p20_tipo_doc 
		IF rm_p20.p20_tipo_doc IS NOT NULL THEN
			CALL fl_lee_tipo_doc_tesoreria(rm_p20.p20_tipo_doc)
				RETURNING r_tip.* 
			IF r_tip.p04_tipo_doc IS NULL THEN
				CALL fgl_winmessage(vg_producto,'Tipo de documento no existe.','exclamation')
				NEXT FIELD p20_tipo_doc
			END IF
			DISPLAY r_tip.p04_nombre TO tit_tipo_doc
			IF r_tip.p04_tipo <> 'D' THEN
				CALL fgl_winmessage(vg_producto,'Tipo de documento debe ser deudor.','exclamation')
				NEXT FIELD p20_tipo_doc
			END IF
			IF rm_p20.p20_tipo_doc <> 'DO'
			AND rm_p20.p20_tipo_doc <> 'FA'
			AND rm_p20.p20_tipo_doc <> 'ND' THEN
				CALL fgl_winmessage(vg_producto,'Tipo de documento debe ser deudor.','exclamation')
				NEXT FIELD p20_tipo_doc
			END IF
			IF rm_p20.p20_tipo_doc = 'FA' THEN
				CALL fl_mostrar_mensaje('Las FACTURAS DE PROVEEDORES se ingresan por la opcion INGRESO FACTURAS del menu transacciones.','exclamation')
				NEXT FIELD p20_tipo_doc
			END IF
			IF r_tip.p04_estado = 'B' THEN
                                CALL fl_mensaje_estado_bloqueado()
				NEXT FIELD p20_tipo_doc
			END IF
		ELSE
			CLEAR tit_tipo_doc
		END IF
	AFTER FIELD p20_num_doc 
		IF rm_p20.p20_num_doc IS NULL THEN
			LET rm_p20.p20_num_doc = 0
			DISPLAY BY NAME rm_p20.p20_num_doc
		END IF
	AFTER FIELD p20_dividendo 
		IF rm_p20.p20_tipo_doc = 'ND' THEN
			LET rm_p20.p20_dividendo = 1
			DISPLAY BY NAME rm_p20.p20_dividendo
		END IF
	AFTER FIELD p20_fecha_emi
		IF rm_p20.p20_fecha_emi IS NOT NULL THEN
			IF rm_p20.p20_fecha_emi > TODAY
			OR (MONTH(rm_p20.p20_fecha_emi) <> MONTH(TODAY)
			OR YEAR(rm_p20.p20_fecha_emi) <> YEAR(TODAY)) THEN
				CALL fgl_winmessage(vg_producto,'La fecha de emisión debe ser de hoy o del presente mes.','exclamation')
				NEXT FIELD p20_fecha_emi
			END IF
		ELSE
			LET rm_p20.p20_fecha_emi = fecha_emi
			DISPLAY BY NAME rm_p20.p20_fecha_emi
		END IF
	AFTER FIELD p20_fecha_vcto
		IF rm_p20.p20_fecha_vcto IS NOT NULL THEN
			IF rm_p20.p20_fecha_vcto <= rm_p20.p20_fecha_emi THEN
				CALL fgl_winmessage(vg_producto,'La fecha de vencimiento debe ser mayor a la fecha de emisión.','exclamation')
				NEXT FIELD p20_fecha_vcto
			END IF
		END IF
	AFTER FIELD p20_tasa_int
		IF rm_p20.p20_tasa_int IS NULL THEN
			LET rm_p20.p20_tasa_mora = 0
			DISPLAY BY NAME rm_p20.p20_tasa_mora
		END IF
	AFTER FIELD p20_tasa_mora
		IF rm_p20.p20_tasa_mora IS NULL THEN
			LET rm_p20.p20_tasa_mora = tasa_mora
			DISPLAY BY NAME rm_p20.p20_tasa_mora
		END IF
	AFTER FIELD p20_moneda 
		IF rm_p20.p20_moneda IS NOT NULL THEN
			CALL fl_lee_moneda(rm_p20.p20_moneda)
				RETURNING r_mon.* 
			IF r_mon.g13_moneda IS NULL  THEN
				CALL fgl_winmessage(vg_producto,'Moneda no existe.','exclamation')
				NEXT FIELD p20_moneda
			END IF
			DISPLAY r_mon.g13_nombre TO tit_mon_bas
			IF r_mon.g13_estado = 'B' THEN
                                CALL fl_mensaje_estado_bloqueado()
				NEXT FIELD p20_moneda
			END IF
			IF rm_p20.p20_moneda = rg_gen.g00_moneda_base THEN
				LET r_mon_par.g14_tasa = 1
			ELSE
				CALL fl_lee_factor_moneda(rm_p20.p20_moneda,
							rg_gen.g00_moneda_base)
					RETURNING r_mon_par.*
				IF r_mon_par.g14_serial IS NULL THEN
					CALL fgl_winmessage(vg_producto,'La paridad para está moneda no existe.','exclamation')
					NEXT FIELD p20_moneda
				END IF
			END IF
			LET rm_p20.p20_paridad = r_mon_par.g14_tasa
			DISPLAY BY NAME rm_p20.p20_paridad
		ELSE
			LET rm_p20.p20_moneda = rg_gen.g00_moneda_base
			DISPLAY BY NAME rm_p20.p20_moneda
			CALL fl_lee_moneda(rm_p20.p20_moneda) RETURNING r_mon.* 
			DISPLAY r_mon.g13_nombre TO tit_mon_bas
		END IF
	AFTER FIELD p20_valor_cap
		IF rm_p20.p20_valor_cap IS NOT NULL THEN
			CALL fl_retorna_precision_valor(rm_p20.p20_moneda,
                                                        rm_p20.p20_valor_cap)
                                RETURNING rm_p20.p20_valor_cap
			LET rm_p20.p20_saldo_cap = rm_p20.p20_valor_cap
			IF rm_p20.p20_valor_fact = 0 THEN
				LET rm_p20.p20_valor_fact = rm_p20.p20_valor_cap
			END IF
			DISPLAY BY NAME rm_p20.p20_saldo_cap,
					rm_p20.p20_valor_fact
		ELSE
			LET rm_p20.p20_valor_cap = 0
			LET rm_p20.p20_saldo_cap = rm_p20.p20_valor_cap
			IF rm_p20.p20_valor_fact = 0 THEN
				LET rm_p20.p20_valor_fact = rm_p20.p20_valor_cap
			END IF
			DISPLAY BY NAME rm_p20.p20_valor_cap,
					rm_p20.p20_saldo_cap,
					rm_p20.p20_valor_fact
		END IF
	AFTER FIELD p20_valor_int
		IF rm_p20.p20_valor_int IS NOT NULL THEN
			CALL fl_retorna_precision_valor(rm_p20.p20_moneda,
                                                        rm_p20.p20_valor_int)
                                RETURNING rm_p20.p20_valor_int
			LET rm_p20.p20_saldo_int = rm_p20.p20_valor_int
			DISPLAY BY NAME rm_p20.p20_saldo_int
		ELSE
			LET rm_p20.p20_valor_int = 0
			LET rm_p20.p20_saldo_int = rm_p20.p20_valor_int
			DISPLAY BY NAME rm_p20.p20_valor_int,
					rm_p20.p20_saldo_int
		END IF
	AFTER FIELD p20_valor_fact
		IF rm_p20.p20_valor_fact IS NOT NULL THEN
			IF rm_p20.p20_valor_fact = 0 THEN
				LET rm_p20.p20_valor_fact = rm_p20.p20_valor_cap
			END IF
			CALL fl_retorna_precision_valor(rm_p20.p20_moneda,
                                                        rm_p20.p20_valor_fact)
                                RETURNING rm_p20.p20_valor_fact
		ELSE
			IF rm_p20.p20_valor_cap > 0 THEN
				LET rm_p20.p20_valor_fact = rm_p20.p20_valor_cap
			ELSE
				LET rm_p20.p20_valor_fact = 0
			END IF
		END IF
		DISPLAY BY NAME rm_p20.p20_valor_fact
		CALL calcula_valor_impto()
	AFTER FIELD p20_porc_impto
		IF rm_p20.p20_porc_impto IS NULL THEN
			LET rm_p20.p20_porc_impto = 0
			DISPLAY BY NAME rm_p20.p20_porc_impto
		END IF
		CALL fl_retorna_precision_valor(rm_p20.p20_moneda,
                				rm_p20.p20_porc_impto)
                	RETURNING rm_p20.p20_porc_impto
		CALL calcula_valor_impto()
	AFTER FIELD p20_cartera 
		IF rm_p20.p20_cartera IS NOT NULL THEN
			CALL fl_lee_subtipo_entidad('CR',rm_p20.p20_cartera)
				RETURNING r_car.*
			IF r_car.g12_tiporeg IS NULL  THEN
				CALL fgl_winmessage(vg_producto,'Cartera no existe.','exclamation')
				NEXT FIELD p20_cartera
			END IF
			DISPLAY r_car.g12_nombre TO tit_cartera
		ELSE
			CLEAR tit_cartera
		END IF
        AFTER FIELD p20_cod_depto
                IF rm_p20.p20_cod_depto IS NOT NULL THEN
                        CALL fl_lee_departamento(vg_codcia,
                                                 rm_p20.p20_cod_depto)
                                RETURNING r_g34.*
                        IF r_g34.g34_cod_depto IS NULL THEN
                                CALL fgl_winmessage(vg_producto,
					'No existe el departamento en la ' ||
					'compañía.',
					'exclamation')
                                NEXT FIELD p20_cod_depto
                        END IF
                        DISPLAY r_g34.g34_nombre TO n_depto
                ELSE
                        CLEAR n_depto
                END IF
	AFTER INPUT
		CALL fl_lee_documento_deudor_cxp(vg_codcia, vg_codloc,
				rm_p20.p20_codprov, rm_p20.p20_tipo_doc,
				rm_p20.p20_num_doc,rm_p20.p20_dividendo)
			RETURNING r_cxp_aux.*
		IF r_cxp_aux.p20_compania IS NOT NULL THEN
			CALL fgl_winmessage(vg_producto,'Documento ya ha sido ingresado.','exclamation')
			NEXT FIELD rm_p20.p20_codprov
		END IF
		IF rm_p20.p20_valor_cap + rm_p20.p20_valor_int <= 0 THEN
			CALL fgl_winmessage(vg_producto,'El documento no puede grabarse con valor capital o valor interés de cero.','exclamation')
			NEXT FIELD p20_valor_cap
		END IF
		CALL calcula_valor_impto()
		LET rm_p20.p20_saldo_cap  = rm_p20.p20_valor_cap
		LET rm_p20.p20_saldo_int  = rm_p20.p20_valor_int
		IF rm_p20.p20_valor_fact = 0 THEN
			LET rm_p20.p20_valor_fact = rm_p20.p20_valor_cap
		END IF
		IF rm_p20.p20_tipo_doc = 'ND' THEN
			LET rm_p20.p20_num_doc = NULL
		END IF
END INPUT

END FUNCTION



FUNCTION calcula_valor_impto()
{
CALL fl_retorna_precision_valor(rm_p20.p20_moneda, rm_p20.p20_porc_impto)
   	RETURNING rm_p20.p20_porc_impto
}
LET rm_p20.p20_valor_impto = (rm_p20.p20_valor_fact * rm_p20.p20_porc_impto)
				/ (100 + rm_p20.p20_porc_impto)
CALL fl_retorna_precision_valor(rm_p20.p20_moneda, rm_p20.p20_valor_impto)
      	RETURNING rm_p20.p20_valor_impto
DISPLAY BY NAME rm_p20.p20_valor_impto

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
                                                                                
DISPLAY "        " TO tit_nombre_pro
CLEAR tit_nombre_pro
DISPLAY num_rows    TO vm_num_rows2
DISPLAY row_current TO vm_num_current2
DISPLAY num_rows    TO vm_num_rows1
DISPLAY row_current TO vm_num_current1

END FUNCTION



FUNCTION mostrar_registro(num_registro)
DEFINE r_pro_gen	RECORD LIKE cxpt001.*
DEFINE r_tip		RECORD LIKE cxpt004.*
DEFINE r_mon		RECORD LIKE gent013.*
DEFINE r_car		RECORD LIKE gent012.*
DEFINE num_registro	INTEGER

IF vm_num_rows <= 0 THEN
	RETURN
END IF
SELECT * INTO rm_p20.* FROM cxpt020 WHERE ROWID = num_registro
IF STATUS = NOTFOUND THEN
	CALL fgl_winmessage (vg_producto,'No existe registro con índice: ' || vm_row_current,'exclamation')
	RETURN
END IF
IF num_args() = 9 THEN
	IF arg_val(9) < TODAY THEN
		CALL obtener_saldo_deudor_fecha()
	END IF
END IF
DISPLAY BY NAME rm_p20.p20_codprov, rm_p20.p20_tipo_doc,
		rm_p20.p20_num_doc, rm_p20.p20_dividendo,
		rm_p20.p20_referencia, rm_p20.p20_fecha_emi,
		rm_p20.p20_fecha_vcto, rm_p20.p20_tasa_int,
		rm_p20.p20_tasa_mora, rm_p20.p20_moneda,
		rm_p20.p20_paridad, rm_p20.p20_valor_cap,
		rm_p20.p20_valor_int, rm_p20.p20_saldo_cap,
		rm_p20.p20_saldo_int, rm_p20.p20_valor_fact,
		rm_p20.p20_porc_impto, rm_p20.p20_valor_impto,
		rm_p20.p20_cartera, rm_p20.p20_origen, rm_p20.p20_numero_oc,
		rm_p20.p20_usuario, rm_p20.p20_fecing
CALL fl_lee_proveedor(rm_p20.p20_codprov) RETURNING r_pro_gen.*
CALL fl_lee_tipo_doc(rm_p20.p20_tipo_doc) RETURNING r_tip.* 
DISPLAY r_tip.p04_nombre TO tit_tipo_doc
CALL fl_lee_moneda(rm_p20.p20_moneda) RETURNING r_mon.* 
DISPLAY r_mon.g13_nombre TO tit_mon_bas
CALL fl_lee_subtipo_entidad('CR',rm_p20.p20_cartera) RETURNING r_car.*
DISPLAY r_car.g12_nombre TO tit_cartera
DISPLAY r_pro_gen.p01_nomprov TO tit_nombre_pro

END FUNCTION



FUNCTION obtener_saldo_deudor_fecha()
DEFINE r_z60		RECORD LIKE cxct060.*
DEFINE fecha		LIKE cxpt022.p22_fecing
DEFINE query		CHAR(6000)
DEFINE subquery1	CHAR(3000)
DEFINE subquery2	CHAR(500)
DEFINE join_p22p23	CHAR(500)
DEFINE fec_ini		DATE

ERROR "Procesando documento deudor con saldo . . . espere por favor." ATTRIBUTE(NORMAL)
CALL fl_lee_fecha_carga_cxc(vg_codcia, vg_codloc) RETURNING r_z60.*
IF r_z60.z60_compania IS NULL THEN
	CALL fl_mostrar_mensaje('No existe una fecha de carga para este módulo.', 'stop')
	EXIT PROGRAM
END IF
LET fec_ini = r_z60.z60_fecha_carga
LET fecha   = EXTEND(arg_val(9), YEAR TO SECOND) + 23 UNITS HOUR +
		59 UNITS MINUTE + 59 UNITS SECOND
LET join_p22p23 = ' FROM cxpt023, cxpt022 ',
			' WHERE p23_compania  = p20_compania ',
			'   AND p23_localidad = p20_localidad ',
			'   AND p23_codprov   = p20_codprov ',
			'   AND p23_tipo_doc  = p20_tipo_doc ',
			'   AND p23_num_doc   = p20_num_doc ',
			'   AND p23_div_doc   = p20_dividendo ',
			'   AND p22_compania  = p23_compania ',
			'   AND p22_localidad = p23_localidad ',
			'   AND p22_codprov   = p23_codprov ',
			'   AND p22_tipo_trn  = p23_tipo_trn ',
			'   AND p22_num_trn   = p23_num_trn '
LET subquery1 = '(SELECT p23_valor_cap + p23_valor_int + p23_saldo_cap + ',
			'p23_saldo_int ',
		' FROM cxpt023, cxpt022 ',
		' WHERE p23_compania  = p20_compania ',
		'   AND p23_localidad = p20_localidad ',
		'   AND p23_codprov   = p20_codprov ',
		'   AND p23_tipo_doc  = p20_tipo_doc ',
		'   AND p23_num_doc   = p20_num_doc ',
		'   AND p23_div_doc   = p20_dividendo ',
		'   AND p23_orden     = (SELECT MAX(p23_orden) ',
					join_p22p23 CLIPPED,
					'   AND p22_fecing    = ',
					'(SELECT MAX(p22_fecing) ',
					join_p22p23 CLIPPED,
					'   AND p22_fecing   <= "', fecha,'"))',
		'   AND p22_compania  = p23_compania ',
		'   AND p22_localidad = p23_localidad ',
		'   AND p22_codprov   = p23_codprov ',
		'   AND p22_tipo_trn  = p23_tipo_trn ',
		'   AND p22_num_trn   = p23_num_trn ',
		'   AND p22_fecing    = (SELECT MAX(p22_fecing) ',
					join_p22p23 CLIPPED,
					'   AND p22_fecing   <= "', fecha, '"))'
LET subquery2 = ' (SELECT NVL(SUM(p23_valor_cap + p23_valor_int), 0) ',
		' FROM cxpt023 ',
		' WHERE p23_compania  = p20_compania ',
		'   AND p23_localidad = p20_localidad ',
		'   AND p23_codprov   = p20_codprov ',
		'   AND p23_tipo_doc  = p20_tipo_doc ',
		'   AND p23_num_doc   = p20_num_doc ',
		'   AND p23_div_doc   = p20_dividendo) '
LET query = 'SELECT NVL(', subquery1 CLIPPED, ', ',
			' CASE WHEN p20_fecha_emi <= "', fec_ini, '"',
				' THEN p20_saldo_cap + p20_saldo_int - ',
					subquery2 CLIPPED,
				' ELSE p20_valor_cap + p20_valor_int',
			' END) saldo_doc ',
		' FROM cxpt020 ',
		' WHERE p20_compania   = ', rm_p20.p20_compania,
		'   AND p20_localidad  = ', rm_p20.p20_localidad,
		'   AND p20_codprov    = ', rm_p20.p20_codprov,
		'   AND p20_tipo_doc   = "', rm_p20.p20_tipo_doc, '"',
		'   AND p20_num_doc    = "', rm_p20.p20_num_doc, '"',
		'   AND p20_dividendo  = ', rm_p20.p20_dividendo,
		'   AND p20_fecha_emi <= "', arg_val(9), '"',
		' INTO TEMP t1 '
PREPARE stmnt1 FROM query
EXECUTE stmnt1
SELECT NVL(saldo_doc, 0) INTO rm_p20.p20_saldo_cap FROM t1
DROP TABLE t1
ERROR ' '

END FUNCTION



FUNCTION control_contabilizar()
DEFINE r_p41		RECORD LIKE cxpt041.*

INITIALIZE r_p41.* TO NULL
SELECT * INTO r_p41.* FROM cxpt041
	WHERE p41_compania  = rm_p20.p20_compania
	  AND p41_localidad = rm_p20.p20_localidad
	  AND p41_codprov   = rm_p20.p20_codprov
	  AND p41_tipo_doc  = rm_p20.p20_tipo_doc
	  AND p41_num_doc   = rm_p20.p20_num_doc
	  AND p41_dividendo = rm_p20.p20_dividendo
IF r_p41.p41_compania IS NULL THEN
	CALL fl_mostrar_mensaje('Este documento no tiene contablipación automatica.', 'exclamation')
	RETURN
END IF
CALL ver_contabilizacion(r_p41.p41_tipo_comp, r_p41.p41_num_comp)

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
