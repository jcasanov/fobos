------------------------------------------------------------------------------
-- Titulo           : cxpp200.4gl - Ingreso de documentos deudores 
-- Elaboracion      : 26-nov-2001
-- Autor            : NPC
-- Formato Ejecucion: fglrun cxpp200 base módulo compañía localidad
--			[proveedor tipo_docuemnto numero_documento dividendo]
-- Ultima Correccion: 
-- Motivo Correccion: 
------------------------------------------------------------------------------
GLOBALS '../../../PRODUCCION/LIBRERIAS/fuentes/globales.4gl'

DEFINE vm_demonios	VARCHAR(12)
DEFINE rm_cxp		RECORD LIKE cxpt020.*
DEFINE vm_num_rows	SMALLINT
DEFINE vm_row_current	SMALLINT
DEFINE vm_max_rows	SMALLINT
DEFINE vm_r_rows	ARRAY [1000] OF INTEGER

MAIN

DEFER QUIT 
DEFER INTERRUPT
CLEAR SCREEN
CALL startlog('../logs/errores')
CALL fgl_init4js()
CALL fl_marca_registrada_producto()
IF num_args() <> 4 AND num_args() <> 8 THEN  -- Validar # parámetros correcto
	CALL fgl_winmessage(vg_producto, 'Número de parámetros incorrecto.', 'stop')
	EXIT PROGRAM
END IF
LET vg_base     = arg_val(1)
LET vg_modulo   = arg_val(2)
LET vg_codcia   = arg_val(3)
LET vg_codloc   = arg_val(4)
LET vg_proceso = 'cxpp200'
CALL fl_activar_base_datos(vg_base)
CALL fl_seteos_defaults()	
CALL fgl_settitle(vg_proceso || ' - ' || vg_producto)
CALL validar_parametros()
CALL fl_cabecera_pantalla(vg_codcia, vg_codloc, vg_modulo, vg_proceso)
CALL control_master()

END MAIN



FUNCTION control_master()

CALL fl_nivel_isolation()
CALL fl_chequeo_mes_proceso_cxp(vg_codcia) RETURNING int_flag 
IF int_flag THEN
	RETURN
END IF
LET vm_max_rows	= 1000
OPEN WINDOW wf AT 3,2 WITH 20 ROWS, 80 COLUMNS
    ATTRIBUTE(FORM LINE FIRST + 2, COMMENT LINE LAST, MENU LINE FIRST,BORDER,
	      MESSAGE LINE LAST - 2)
OPTIONS INPUT WRAP,
	ACCEPT KEY	F12
OPEN FORM f_cxp FROM "../forms/cxpf200_1"
DISPLAY FORM f_cxp
INITIALIZE rm_cxp.* TO NULL
LET vm_num_rows    = 0
LET vm_row_current = 0
CALL muestra_contadores(vm_row_current, vm_num_rows)
MENU 'OPCIONES'
	BEFORE MENU
		HIDE OPTION 'Avanzar'
		HIDE OPTION 'Retroceder'
		IF num_args() = 8 THEN
			HIDE OPTION 'Ingresar'
			HIDE OPTION 'Consultar'
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
DEFINE resul            SMALLINT
DEFINE resp             CHAR(6)
DEFINE r_b12            RECORD LIKE ctbt012.*
DEFINE r_b00            RECORD LIKE ctbt000.*
DEFINE r_datdoc        RECORD
                                codcia          LIKE gent001.g01_compania,
                                cliprov         INTEGER,
                                tipo_doc        CHAR(2),
                                subtipo         LIKE ctbt012.b12_subtipo,
                                moneda          LIKE gent013.g13_moneda,
                                paridad         LIKE gent014.g14_tasa,
                                valor_doc       DECIMAL(14,2),
                                flag_mod        SMALLINT
                        END RECORD

CALL fl_retorna_usuario()
INITIALIZE rm_cxp.*, r_mon.* TO NULL
CLEAR p20_paridad, p20_saldo_cap, p20_saldo_int, p20_valor_fact, tit_nombre_pro,
	tit_tipo_doc, tit_mon_bas, tit_cartera
LET rm_cxp.p20_compania    = vg_codcia
LET rm_cxp.p20_localidad   = vg_codloc
LET rm_cxp.p20_dividendo   = 1
LET rm_cxp.p20_fecha_emi   = CURRENT
LET rm_cxp.p20_tasa_int    = 0 
LET rm_cxp.p20_tasa_mora   = 0
LET rm_cxp.p20_moneda      = rg_gen.g00_moneda_base
LET rm_cxp.p20_valor_cap   = 0
LET rm_cxp.p20_valor_int   = 0
LET rm_cxp.p20_valor_fact  = 0
LET rm_cxp.p20_porc_impto  = 0
LET rm_cxp.p20_valor_impto = 0
LET rm_cxp.p20_saldo_cap   = 0
LET rm_cxp.p20_saldo_int   = 0
LET rm_cxp.p20_paridad     = 1
LET rm_cxp.p20_origen      = 'M'
LET rm_cxp.p20_usuario     = vg_usuario
LET rm_cxp.p20_fecing      = CURRENT
CALL fl_lee_moneda(rm_cxp.p20_moneda) RETURNING r_mon.*
IF r_mon.g13_moneda IS NULL THEN
        CALL fgl_winmessage(vg_producto,'No existe ninguna moneda base.','stop')
        EXIT PROGRAM
ELSE
        DISPLAY r_mon.g13_nombre TO tit_mon_bas
END IF
CALL leer_datos()
IF NOT int_flag THEN
	LET rm_cxp.p20_fecing = CURRENT
	BEGIN WORK
		IF rm_cxp.p20_tipo_doc = 'ND' THEN
			CALL fl_actualiza_control_secuencias(vg_codcia,
						vg_codloc, vg_modulo, 'AA',
						rm_cxp.p20_tipo_doc)
				RETURNING rm_cxp.p20_num_doc
			IF rm_cxp.p20_num_doc <= '0' THEN
				ROLLBACK WORK
				EXIT PROGRAM
			END IF
			DISPLAY BY NAME rm_cxp.p20_num_doc
		END IF
		INSERT INTO cxpt020 VALUES (rm_cxp.*)
		LET num_aux = SQLCA.SQLERRD[6] 
		CALL fl_genera_saldos_proveedor(vg_codcia, vg_codloc,
						rm_cxp.p20_codprov)
--OJO DESDE AQUI SE LLAMA A LA CONTABILIZACION

                LET r_datdoc.codcia    = vg_codcia
                LET r_datdoc.cliprov   = rm_cxp.p20_codprov
                LET r_datdoc.tipo_doc  = rm_cxp.p20_tipo_doc
                LET r_datdoc.subtipo   = NULL
                IF rm_cxp.p20_tipo_doc = 'ND' THEN
                        LET r_datdoc.subtipo = 21
                END IF
                LET r_datdoc.moneda    = rm_cxp.p20_moneda
                LET r_datdoc.paridad   = rm_cxp.p20_paridad
                LET r_datdoc.valor_doc = rm_cxp.p20_valor_cap
                LET r_datdoc.flag_mod  = 2     -- Modulo
                CALL fl_contabilizacion_documentos(r_datdoc.*)
                        RETURNING r_b12.*, resul
                IF int_flag THEN
                        IF resul = 0 THEN
                                ROLLBACK WORK
                                EXIT PROGRAM
                        END IF
                END IF
                IF resul THEN
                        INSERT INTO cxpt041
                        VALUES (rm_cxp.p20_compania, rm_cxp.p20_localidad,
                                rm_cxp.p20_codprov, rm_cxp.p20_tipo_doc,
                                rm_cxp.p20_num_doc, rm_cxp.p20_dividendo,
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
		CALL fgl_winquestion(vg_producto,'Desea ver contabilizacion generada ?','No','Yes|No|Cancel','question',1)
        	RETURNING resp
                IF resp = 'Yes' THEN
                        CALL ver_contabilizacion(r_b12.b12_tipo_comp,
                                                r_b12.b12_num_comp)
                END IF
        END IF
-- HASTA AQUI
	IF vm_num_rows = vm_max_rows THEN
		LET vm_num_rows = 1
	ELSE
		LET vm_num_rows = vm_num_rows + 1
	END IF
	DISPLAY BY NAME rm_cxp.p20_fecing
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
		IF infield(p20_codprov) THEN
			CALL fl_ayuda_proveedores_localidad(vg_codcia,vg_codloc)
				RETURNING cod_aux, nom_aux
			LET int_flag = 0
			IF cod_aux IS NOT NULL THEN
				DISPLAY cod_aux TO p20_codprov 
				DISPLAY nom_aux TO tit_nombre_pro
			END IF 
		END IF
		IF infield(p20_tipo_doc) THEN
			CALL fl_ayuda_tipo_documento_tesoreria('D')
				RETURNING codt_aux, nomt_aux
			LET int_flag = 0
			IF codt_aux IS NOT NULL THEN
				DISPLAY codt_aux TO p20_tipo_doc
				DISPLAY nomt_aux TO tit_tipo_doc
			END IF 
		END IF
		IF infield(p20_num_doc) THEN
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
		IF infield(p20_moneda) THEN
			CALL fl_ayuda_monedas()
				RETURNING mone_aux, nomm_aux, deci_aux
			LET int_flag = 0
			IF mone_aux IS NOT NULL THEN
				DISPLAY mone_aux TO p20_moneda 
				DISPLAY nomm_aux TO tit_mon_bas
			END IF 
		END IF
		IF infield(p20_cartera) THEN
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
                                LET rm_cxp.p20_cod_depto = r_g34.g34_cod_depto
                                DISPLAY BY NAME rm_cxp.p20_cod_depto
                                DISPLAY  r_g34.g34_nombre TO n_depto
                        END IF
                END IF
		LET int_flag = 0
	AFTER FIELD p20_codprov
		LET cod_aux = get_fldbuf(p20_codprov)
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
FOREACH q_cons INTO rm_cxp.*, num_reg
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
DISPLAY BY NAME rm_cxp.p20_dividendo, rm_cxp.p20_tasa_int, rm_cxp.p20_tasa_mora,
		rm_cxp.p20_fecha_emi, rm_cxp.p20_paridad, rm_cxp.p20_valor_cap,
		rm_cxp.p20_valor_int, rm_cxp.p20_porc_impto, rm_cxp.p20_origen,
		rm_cxp.p20_usuario, rm_cxp.p20_fecing, rm_cxp.p20_saldo_cap,
		rm_cxp.p20_saldo_int, rm_cxp.p20_valor_impto
LET int_flag = 0
INPUT BY NAME rm_cxp.p20_codprov, rm_cxp.p20_tipo_doc, rm_cxp.p20_num_doc,
	rm_cxp.p20_dividendo, rm_cxp.p20_referencia, rm_cxp.p20_fecha_emi,
	rm_cxp.p20_fecha_vcto, rm_cxp.p20_tasa_int, rm_cxp.p20_tasa_mora,
	rm_cxp.p20_moneda, rm_cxp.p20_valor_cap, rm_cxp.p20_valor_int,
	rm_cxp.p20_valor_fact, rm_cxp.p20_porc_impto, rm_cxp.p20_cod_depto,
	rm_cxp.p20_cartera
	WITHOUT DEFAULTS
	ON KEY(INTERRUPT)
	        IF field_touched(rm_cxp.p20_codprov, rm_cxp.p20_tipo_doc,
			rm_cxp.p20_num_doc,    rm_cxp.p20_dividendo,
			rm_cxp.p20_referencia, rm_cxp.p20_fecha_emi,
			rm_cxp.p20_fecha_vcto, rm_cxp.p20_tasa_int,
			rm_cxp.p20_tasa_mora,  rm_cxp.p20_moneda,
			rm_cxp.p20_valor_cap,  rm_cxp.p20_valor_int,
			rm_cxp.p20_valor_fact, rm_cxp.p20_porc_impto,
			rm_cxp.p20_cartera,    rm_cxp.p20_cod_depto)
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
		IF infield(p20_codprov) THEN
			CALL fl_ayuda_proveedores_localidad(vg_codcia,vg_codloc)
				RETURNING cod_aux, nom_aux
			LET int_flag = 0
			IF cod_aux IS NOT NULL THEN
				LET rm_cxp.p20_codprov = cod_aux
				DISPLAY BY NAME rm_cxp.p20_codprov 
				DISPLAY nom_aux TO tit_nombre_pro
			END IF 
		END IF
		IF infield(p20_tipo_doc) THEN
			CALL fl_ayuda_tipo_documento_tesoreria('D')
				RETURNING codt_aux, nomt_aux
			LET int_flag = 0
			IF codt_aux IS NOT NULL THEN
				LET rm_cxp.p20_tipo_doc = codt_aux
				DISPLAY BY NAME rm_cxp.p20_tipo_doc
				DISPLAY nomt_aux TO tit_tipo_doc
			END IF 
		END IF
		IF infield(p20_num_doc) THEN
			CALL fl_ayuda_doc_deudores_tes(vg_codcia, vg_codloc,
					rm_cxp.p20_codprov, rm_cxp.p20_tipo_doc)
				RETURNING nom_aux, r_cxp.p20_tipo_doc,
					r_cxp.p20_num_doc, r_cxp.p20_dividendo,
					r_cxp.p20_saldo_cap, r_cxp.p20_moneda
			LET int_flag = 0
			IF r_cxp.p20_num_doc IS NOT NULL THEN
				LET rm_cxp.p20_num_doc = r_cxp.p20_num_doc
				LET rm_cxp.p20_dividendo = r_cxp.p20_dividendo
							+ 1
				DISPLAY BY NAME rm_cxp.p20_num_doc
				DISPLAY BY NAME rm_cxp.p20_dividendo
			END IF 
		END IF
		IF infield(p20_moneda) THEN
			CALL fl_ayuda_monedas()
				RETURNING mone_aux, nomm_aux, deci_aux
			LET int_flag = 0
			IF mone_aux IS NOT NULL THEN
				LET rm_cxp.p20_moneda = mone_aux
				DISPLAY BY NAME rm_cxp.p20_moneda 
				DISPLAY nomm_aux TO tit_mon_bas
			END IF 
		END IF
		IF infield(p20_cartera) THEN
			CALL fl_ayuda_subtipo_cartera()
				RETURNING codc_aux, nomc_aux
			LET int_flag = 0
			IF codc_aux IS NOT NULL THEN
				LET rm_cxp.p20_cartera = codc_aux
				DISPLAY BY NAME rm_cxp.p20_cartera 
				DISPLAY nomc_aux TO tit_cartera
			END IF 
		END IF
                IF INFIELD(p20_cod_depto) THEN
                        CALL fl_ayuda_departamentos(vg_codcia)
                                RETURNING r_g34.g34_cod_depto,
                                          r_g34.g34_nombre
                        IF r_g34.g34_cod_depto IS NOT NULL THEN
                                LET rm_cxp.p20_cod_depto = r_g34.g34_cod_depto
                                DISPLAY BY NAME rm_cxp.p20_cod_depto
                                DISPLAY  r_g34.g34_nombre TO n_depto
                        END IF
                END IF
		LET int_flag = 0
	BEFORE FIELD p20_fecha_emi
		LET fecha_emi = rm_cxp.p20_fecha_emi
	BEFORE FIELD p20_fecha_vcto
		IF rm_cxp.p20_fecha_emi IS NULL THEN
			CALL fgl_winmessage(vg_producto,'Ingrese la fecha de emisión primero.','info')
			NEXT FIELD p20_fecha_emi
		END IF
	BEFORE FIELD p20_tasa_mora
		LET tasa_mora = rm_cxp.p20_tasa_mora
	AFTER FIELD p20_codprov
		IF rm_cxp.p20_codprov IS NOT NULL THEN
			CALL fl_lee_proveedor(rm_cxp.p20_codprov)
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
							rm_cxp.p20_codprov)
		 		RETURNING r_pro.*
			IF r_pro.p02_compania IS NULL THEN
				CALL fgl_winmessage(vg_producto,'Proveedor no está activado para la compañía.','exclamation')
				NEXT FIELD p20_codprov
			END IF
		ELSE
			CLEAR tit_nombre_pro
		END IF
	AFTER FIELD p20_tipo_doc 
		IF rm_cxp.p20_tipo_doc IS NOT NULL THEN
			CALL fl_lee_tipo_doc_tesoreria(rm_cxp.p20_tipo_doc)
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
			IF rm_cxp.p20_tipo_doc <> 'DO'
			AND rm_cxp.p20_tipo_doc <> 'FA'
			AND rm_cxp.p20_tipo_doc <> 'ND' THEN
				CALL fgl_winmessage(vg_producto,'Tipo de documento debe ser deudor.','exclamation')
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
		IF rm_cxp.p20_num_doc IS NULL THEN
			LET rm_cxp.p20_num_doc = 0
			DISPLAY BY NAME rm_cxp.p20_num_doc
		END IF
	AFTER FIELD p20_fecha_emi
		IF rm_cxp.p20_fecha_emi IS NOT NULL THEN
			IF rm_cxp.p20_fecha_emi > TODAY
			OR (MONTH(rm_cxp.p20_fecha_emi) <> MONTH(TODAY)
			OR YEAR(rm_cxp.p20_fecha_emi) <> YEAR(TODAY)) THEN
				CALL fgl_winmessage(vg_producto,'La fecha de emisión debe ser de hoy o del presente mes.','exclamation')
				NEXT FIELD p20_fecha_emi
			END IF
		ELSE
			LET rm_cxp.p20_fecha_emi = fecha_emi
			DISPLAY BY NAME rm_cxp.p20_fecha_emi
		END IF
	AFTER FIELD p20_fecha_vcto
		IF rm_cxp.p20_fecha_vcto IS NOT NULL THEN
			IF rm_cxp.p20_fecha_vcto <= rm_cxp.p20_fecha_emi THEN
				CALL fgl_winmessage(vg_producto,'La fecha de vencimiento debe ser mayor a la fecha de emisión.','exclamation')
				NEXT FIELD p20_fecha_vcto
			END IF
		END IF
	AFTER FIELD p20_tasa_int
		IF rm_cxp.p20_tasa_int IS NULL THEN
			LET rm_cxp.p20_tasa_mora = 0
			DISPLAY BY NAME rm_cxp.p20_tasa_mora
		END IF
	AFTER FIELD p20_tasa_mora
		IF rm_cxp.p20_tasa_mora IS NULL THEN
			LET rm_cxp.p20_tasa_mora = tasa_mora
			DISPLAY BY NAME rm_cxp.p20_tasa_mora
		END IF
	AFTER FIELD p20_moneda 
		IF rm_cxp.p20_moneda IS NOT NULL THEN
			CALL fl_lee_moneda(rm_cxp.p20_moneda)
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
			IF rm_cxp.p20_moneda = rg_gen.g00_moneda_base THEN
				LET r_mon_par.g14_tasa = 1
			ELSE
				CALL fl_lee_factor_moneda(rm_cxp.p20_moneda,
							rg_gen.g00_moneda_base)
					RETURNING r_mon_par.*
				IF r_mon_par.g14_serial IS NULL THEN
					CALL fgl_winmessage(vg_producto,'La paridad para está moneda no existe.','exclamation')
					NEXT FIELD p20_moneda
				END IF
			END IF
			LET rm_cxp.p20_paridad = r_mon_par.g14_tasa
			DISPLAY BY NAME rm_cxp.p20_paridad
		ELSE
			LET rm_cxp.p20_moneda = rg_gen.g00_moneda_base
			DISPLAY BY NAME rm_cxp.p20_moneda
			CALL fl_lee_moneda(rm_cxp.p20_moneda) RETURNING r_mon.* 
			DISPLAY r_mon.g13_nombre TO tit_mon_bas
		END IF
	AFTER FIELD p20_valor_cap
		IF rm_cxp.p20_valor_cap IS NOT NULL THEN
			CALL fl_retorna_precision_valor(rm_cxp.p20_moneda,
                                                        rm_cxp.p20_valor_cap)
                                RETURNING rm_cxp.p20_valor_cap
			LET rm_cxp.p20_saldo_cap = rm_cxp.p20_valor_cap
			IF rm_cxp.p20_valor_fact = 0 THEN
				LET rm_cxp.p20_valor_fact = rm_cxp.p20_valor_cap
			END IF
			DISPLAY BY NAME rm_cxp.p20_saldo_cap,
					rm_cxp.p20_valor_fact
		ELSE
			LET rm_cxp.p20_valor_cap = 0
			LET rm_cxp.p20_saldo_cap = rm_cxp.p20_valor_cap
			IF rm_cxp.p20_valor_fact = 0 THEN
				LET rm_cxp.p20_valor_fact = rm_cxp.p20_valor_cap
			END IF
			DISPLAY BY NAME rm_cxp.p20_valor_cap,
					rm_cxp.p20_saldo_cap,
					rm_cxp.p20_valor_fact
		END IF
	AFTER FIELD p20_valor_int
		IF rm_cxp.p20_valor_int IS NOT NULL THEN
			CALL fl_retorna_precision_valor(rm_cxp.p20_moneda,
                                                        rm_cxp.p20_valor_int)
                                RETURNING rm_cxp.p20_valor_int
			LET rm_cxp.p20_saldo_int = rm_cxp.p20_valor_int
			DISPLAY BY NAME rm_cxp.p20_saldo_int
		ELSE
			LET rm_cxp.p20_valor_int = 0
			LET rm_cxp.p20_saldo_int = rm_cxp.p20_valor_int
			DISPLAY BY NAME rm_cxp.p20_valor_int,
					rm_cxp.p20_saldo_int
		END IF
	AFTER FIELD p20_valor_fact
		IF rm_cxp.p20_valor_fact IS NOT NULL THEN
			IF rm_cxp.p20_valor_fact = 0 THEN
				LET rm_cxp.p20_valor_fact = rm_cxp.p20_valor_cap
			END IF
			CALL fl_retorna_precision_valor(rm_cxp.p20_moneda,
                                                        rm_cxp.p20_valor_fact)
                                RETURNING rm_cxp.p20_valor_fact
		ELSE
			IF rm_cxp.p20_valor_cap > 0 THEN
				LET rm_cxp.p20_valor_fact = rm_cxp.p20_valor_cap
			ELSE
				LET rm_cxp.p20_valor_fact = 0
			END IF
		END IF
		DISPLAY BY NAME rm_cxp.p20_valor_fact
		CALL calcula_valor_impto()
	AFTER FIELD p20_porc_impto
		IF rm_cxp.p20_porc_impto IS NULL THEN
			LET rm_cxp.p20_porc_impto = 0
			DISPLAY BY NAME rm_cxp.p20_porc_impto
		END IF
		CALL fl_retorna_precision_valor(rm_cxp.p20_moneda,
                				rm_cxp.p20_porc_impto)
                	RETURNING rm_cxp.p20_porc_impto
		CALL calcula_valor_impto()
	AFTER FIELD p20_cartera 
		IF rm_cxp.p20_cartera IS NOT NULL THEN
			CALL fl_lee_subtipo_entidad('CR',rm_cxp.p20_cartera)
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
                IF rm_cxp.p20_cod_depto IS NOT NULL THEN
                        CALL fl_lee_departamento(vg_codcia,
                                                 rm_cxp.p20_cod_depto)
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
				rm_cxp.p20_codprov, rm_cxp.p20_tipo_doc,
				rm_cxp.p20_num_doc,rm_cxp.p20_dividendo)
			RETURNING r_cxp_aux.*
		IF r_cxp_aux.p20_compania IS NOT NULL THEN
			CALL fgl_winmessage(vg_producto,'Documento ya ha sido ingresado.','exclamation')
			NEXT FIELD rm_cxp.p20_codprov
		END IF
		IF rm_cxp.p20_valor_cap + rm_cxp.p20_valor_int <= 0 THEN
			CALL fgl_winmessage(vg_producto,'El documento no puede grabarse con valor capital o valor interés de cero.','exclamation')
			NEXT FIELD p20_valor_cap
		END IF
		CALL calcula_valor_impto()
		LET rm_cxp.p20_saldo_cap  = rm_cxp.p20_valor_cap
		LET rm_cxp.p20_saldo_int  = rm_cxp.p20_valor_int
		IF rm_cxp.p20_valor_fact = 0 THEN
			LET rm_cxp.p20_valor_fact = rm_cxp.p20_valor_cap
		END IF
		IF rm_cxp.p20_tipo_doc = 'ND' THEN
			LET rm_cxp.p20_num_doc = NULL
		END IF
END INPUT

END FUNCTION



FUNCTION calcula_valor_impto()
{
CALL fl_retorna_precision_valor(rm_cxp.p20_moneda, rm_cxp.p20_porc_impto)
   	RETURNING rm_cxp.p20_porc_impto
}
LET rm_cxp.p20_valor_impto = (rm_cxp.p20_valor_fact * rm_cxp.p20_porc_impto)
				/ (100 + rm_cxp.p20_porc_impto)
CALL fl_retorna_precision_valor(rm_cxp.p20_moneda, rm_cxp.p20_valor_impto)
      	RETURNING rm_cxp.p20_valor_impto
DISPLAY BY NAME rm_cxp.p20_valor_impto

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

IF vm_num_rows > 0 THEN
	SELECT * INTO rm_cxp.* FROM cxpt020 WHERE ROWID = num_registro
	IF STATUS = NOTFOUND THEN
		CALL fgl_winmessage (vg_producto,'No existe registro con índice: ' || vm_row_current,'exclamation')
		RETURN
	END IF
	DISPLAY BY NAME rm_cxp.p20_codprov, rm_cxp.p20_tipo_doc,
			rm_cxp.p20_num_doc, rm_cxp.p20_dividendo,
			rm_cxp.p20_referencia, rm_cxp.p20_fecha_emi,
			rm_cxp.p20_fecha_vcto, rm_cxp.p20_tasa_int,
			rm_cxp.p20_tasa_mora, rm_cxp.p20_moneda,
			rm_cxp.p20_paridad, rm_cxp.p20_valor_cap,
			rm_cxp.p20_valor_int, rm_cxp.p20_saldo_cap,
			rm_cxp.p20_saldo_int, rm_cxp.p20_valor_fact,
			rm_cxp.p20_porc_impto, rm_cxp.p20_valor_impto,
			rm_cxp.p20_cartera, rm_cxp.p20_origen,
			rm_cxp.p20_usuario, rm_cxp.p20_fecing
	CALL fl_lee_proveedor(rm_cxp.p20_codprov) RETURNING r_pro_gen.*
	CALL fl_lee_tipo_doc(rm_cxp.p20_tipo_doc) RETURNING r_tip.* 
	DISPLAY r_tip.p04_nombre TO tit_tipo_doc
	CALL fl_lee_moneda(rm_cxp.p20_moneda) RETURNING r_mon.* 
	DISPLAY r_mon.g13_nombre TO tit_mon_bas
	CALL fl_lee_subtipo_entidad('CR',rm_cxp.p20_cartera) RETURNING r_car.*
	DISPLAY r_car.g12_nombre TO tit_cartera
	DISPLAY r_pro_gen.p01_nomprov TO tit_nombre_pro
ELSE
	RETURN
END IF

END FUNCTION



FUNCTION ver_contabilizacion(tipo_comp, num_comp)
DEFINE tipo_comp        LIKE ctbt012.b12_tipo_comp
DEFINE num_comp         LIKE ctbt012.b12_num_comp
DEFINE comando          CHAR(400)
DEFINE run_prog         VARCHAR(20)
                                                                                
LET run_prog = '; fglrun '
LET comando = 'cd ..', vg_separador, '..', vg_separador, 'CONTABILIDAD',
        vg_separador, 'fuentes', vg_separador, run_prog, 'ctbp201 ', vg_base,
        ' ', 'CB', ' ', vg_codcia, ' ', vg_codloc, ' "', tipo_comp, '" ', num_comp
RUN comando
                                                                                
END FUNCTION



FUNCTION validar_parametros()

CALL fl_lee_modulo(vg_modulo) RETURNING rg_mod.*
IF rg_mod.g50_modulo IS NULL THEN
	CALL fgl_winmessage(vg_producto, 'No existe módulo: ' || vg_modulo, 'stop')
	EXIT PROGRAM
END IF
CALL fl_lee_compania(vg_codcia) RETURNING rg_cia.*
IF rg_cia.g01_compania IS NULL THEN
	CALL fgl_winmessage(vg_producto, 'No existe compañía: '|| vg_codcia, 'stop')
	EXIT PROGRAM
END IF
IF rg_cia.g01_estado <> 'A' THEN
	CALL fgl_winmessage(vg_producto, 'Compañía no está activa: ' || vg_codcia, 'stop')
	EXIT PROGRAM
END IF
IF vg_codloc IS NULL THEN
	LET vg_codloc   = fl_retorna_agencia_default(vg_codcia)
END IF
CALL fl_lee_localidad(vg_codcia, vg_codloc) RETURNING rg_loc.*
IF rg_loc.g02_localidad IS NULL THEN
	CALL fgl_winmessage(vg_producto, 'No existe localidad: ' || vg_codloc, 'stop')
	EXIT PROGRAM
END IF
IF rg_loc.g02_estado <> 'A' THEN
	CALL fgl_winmessage(vg_producto, 'Localidad no está activa: '|| vg_codloc, 'stop')
	EXIT PROGRAM
END IF

END FUNCTION
