--------------------------------------------------------------------------------
-- Titulo           : cxcp200.4gl - Ingreso de documentos deudores 
-- Elaboracion      : 02-oct-2001
-- Autor            : NPC
-- Formato Ejecucion: fglrun cxcp200 base módulo compañía localidad
--			[cliente][tipo_documento][numero_documento][dividendo]
-- Ultima Correccion: 
-- Motivo Correccion: 
--------------------------------------------------------------------------------
GLOBALS '../../../PRODUCCION/LIBRERIAS/fuentes/globales.4gl'

DEFINE rm_z20		RECORD LIKE cxct020.*
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
CALL startlog('../logs/cxcp200.err')
--#CALL fgl_init4js()
CALL fl_marca_registrada_producto()
IF num_args() <> 4 AND num_args() <> 8 AND num_args() <> 9 THEN
	-- Validar # parámetros correcto
	CALL fl_mostrar_mensaje( 'Número de parámetros incorrecto.', 'stop')
	EXIT PROGRAM
END IF
LET vg_base    = arg_val(1)
LET vg_modulo  = arg_val(2)
LET vg_codcia  = arg_val(3)
LET vg_codloc  = arg_val(4)
LET vg_proceso = 'cxcp200'
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
	CALL fl_chequeo_mes_proceso_cxc(vg_codcia) RETURNING int_flag 
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
OPEN FORM f_cxc FROM "../forms/cxcf200_1"
DISPLAY FORM f_cxc
INITIALIZE rm_z20.* TO NULL
LET vm_num_rows    = 0
LET vm_row_current = 0
CALL muestra_contadores(vm_row_current, vm_num_rows)
MENU 'OPCIONES'
	BEFORE MENU
		HIDE OPTION 'Avanzar'
		HIDE OPTION 'Retroceder'
		HIDE OPTION 'Imprimir'
		HIDE OPTION 'Contabilización'
		IF num_args() >= 8 THEN
			HIDE OPTION 'Ingresar'
			HIDE OPTION 'Consultar'
			CALL control_consulta()
			IF vm_num_rows = 0 THEN
                                EXIT PROGRAM
                        END IF
			SHOW OPTION 'Imprimir'
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
DEFINE r_cia            RECORD LIKE cxct000.*
DEFINE r_mon            RECORD LIKE gent013.*
DEFINE r_g37            RECORD LIKE gent037.*
DEFINE sec_sri		LIKE gent037.g37_sec_num_sri
DEFINE cuantos		SMALLINT
DEFINE resul		SMALLINT
DEFINE resp		CHAR(6)

CALL fl_retorna_usuario()
INITIALIZE rm_z20.*, r_mon.*, r_cia.* TO NULL
CLEAR z20_paridad, z20_saldo_cap, tit_modulo, z20_cod_tran, z20_num_tran,
	z20_saldo_int, tit_nombre_cli, tit_tipo_doc, tit_subtipo, tit_mon_bas,
	tit_cartera, tit_linea, tit_area
CALL fl_lee_compania_cobranzas(vg_codcia)
	RETURNING r_cia.*
LET rm_z20.z20_compania  = vg_codcia
LET rm_z20.z20_localidad = vg_codloc
LET rm_z20.z20_dividendo = 1
LET rm_z20.z20_fecha_emi = fl_current()
LET rm_z20.z20_tasa_int  = 0 
LET rm_z20.z20_tasa_mora = r_cia.z00_tasa_mora
LET rm_z20.z20_moneda    = rg_gen.g00_moneda_base
LET rm_z20.z20_valor_cap = 0
LET rm_z20.z20_valor_int = 0
LET rm_z20.z20_saldo_cap = 0
LET rm_z20.z20_saldo_int = 0
LET rm_z20.z20_paridad   = 1
LET rm_z20.z20_origen    = 'M'
LET rm_z20.z20_usuario   = vg_usuario
LET rm_z20.z20_fecing    = fl_current()
CALL fl_lee_moneda(rm_z20.z20_moneda) RETURNING r_mon.*
IF r_mon.g13_moneda IS NULL THEN
        CALL fl_mostrar_mensaje('No existe ninguna moneda base.','stop')
        EXIT PROGRAM
ELSE
        DISPLAY r_mon.g13_nombre TO tit_mon_bas
END IF
CALL leer_datos()
IF NOT int_flag THEN
	BEGIN WORK
		IF rm_z20.z20_tipo_doc = 'ND' THEN
			WHENEVER ERROR CONTINUE
			DECLARE q_sri CURSOR FOR
				SELECT * FROM gent037
					WHERE g37_compania  =  vg_codcia
					  AND g37_localidad =  vg_codloc
					  AND g37_tipo_doc = rm_z20.z20_tipo_doc
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
							rm_z20.z20_tipo_doc)
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
			LET sec_sri = rm_z20.z20_num_sri[9, cuantos]
					USING "########"
			UPDATE gent037 SET g37_sec_num_sri = sec_sri
				WHERE g37_compania    = rm_g37.g37_compania
				  AND g37_localidad   = rm_g37.g37_localidad
				  AND g37_tipo_doc    = rm_g37.g37_tipo_doc
				  AND g37_secuencia   = rm_g37.g37_secuencia
		  		  AND g37_sec_num_sri < sec_sri
		END IF
		IF rm_z20.z20_tipo_doc = 'ND' OR rm_z20.z20_tipo_doc = 'DO' OR
		   rm_z20.z20_tipo_doc = 'DI' OR rm_z20.z20_tipo_doc = 'DF'
		THEN
			IF NOT generar_secuencia() THEN
				ROLLBACK WORK
				EXIT PROGRAM
			END IF
		END IF
		DISPLAY BY NAME rm_z20.z20_num_doc
		LET rm_z20.z20_fecing = fl_current()
		INSERT INTO cxct020 VALUES (rm_z20.*)
		LET num_aux = SQLCA.SQLERRD[6] 
		CALL fl_genera_saldos_cliente(vg_codcia, vg_codloc,
						rm_z20.z20_codcli)
		LET rm_datdoc.codcia    = vg_codcia
		LET rm_datdoc.cliprov   = rm_z20.z20_codcli
		LET rm_datdoc.tipo_doc  = rm_z20.z20_tipo_doc
		LET rm_datdoc.num_doc   = rm_z20.z20_num_doc
		LET rm_datdoc.subtipo   = NULL
		IF rm_z20.z20_tipo_doc = 'ND' THEN
			LET rm_datdoc.subtipo = 21
		END IF
		LET rm_datdoc.moneda    = rm_z20.z20_moneda
		LET rm_datdoc.paridad   = rm_z20.z20_paridad
		LET rm_datdoc.valor_doc = rm_z20.z20_valor_cap
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
			INSERT INTO cxct041
			VALUES (rm_z20.z20_compania, rm_z20.z20_localidad,
				rm_z20.z20_codcli, rm_z20.z20_tipo_doc,
				rm_z20.z20_num_doc, rm_z20.z20_dividendo,
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
	IF rm_z20.z20_tipo_doc = "ND" THEN
		CALL generar_doc_elec()
	END IF
	IF vm_num_rows = vm_max_rows THEN
		LET vm_num_rows = 1
	ELSE
		LET vm_num_rows = vm_num_rows + 1
	END IF
	DISPLAY BY NAME rm_z20.z20_fecing
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
DEFINE codte_aux	LIKE gent012.g12_tiporeg
DEFINE codst_aux	LIKE gent012.g12_subtipo
DEFINE nomte_aux	LIKE gent012.g12_nombre
DEFINE nomst_aux	LIKE gent011.g11_nombre
DEFINE coda_aux		LIKE gent003.g03_areaneg
DEFINE noma_aux		LIKE gent003.g03_nombre
DEFINE mone_aux		LIKE gent013.g13_moneda
DEFINE nomm_aux		LIKE gent013.g13_nombre
DEFINE deci_aux		LIKE gent013.g13_decimales
DEFINE codc_aux		LIKE gent012.g12_subtipo
DEFINE nomc_aux		LIKE gent012.g12_nombre
DEFINE codl_aux		LIKE gent020.g20_grupo_linea
DEFINE noml_aux		LIKE gent020.g20_nombre
DEFINE r_cxc		RECORD LIKE cxct020.*
DEFINE abrevia		LIKE gent003.g03_abreviacion
DEFINE query		VARCHAR(1200)
DEFINE expr_sql		VARCHAR(1000)
DEFINE num_reg		INTEGER

CLEAR FORM
INITIALIZE cod_aux, codt_aux, coda_aux, mone_aux, codc_aux, codl_aux, codte_aux,
	codst_aux, r_cxc.* TO NULL
IF num_args() = 4 THEN
	LET int_flag = 0
	CONSTRUCT BY NAME expr_sql ON z20_codcli, z20_tipo_doc, z20_num_doc,
	z20_dividendo, z20_subtipo, z20_areaneg, z20_referencia, z20_fecha_emi,
	z20_fecha_vcto, z20_tasa_int, z20_tasa_mora, z20_cod_tran, z20_num_tran,
	z20_moneda, z20_valor_cap, z20_valor_int, z20_cartera, z20_linea,
	z20_origen, z20_num_sri, z20_usuario, z20_fecing
	ON KEY(F2)
		IF INFIELD(z20_codcli) THEN
			CALL fl_ayuda_cliente_localidad(vg_codcia,vg_codloc)
				RETURNING cod_aux, nom_aux
			LET int_flag = 0
			IF cod_aux IS NOT NULL THEN
				DISPLAY cod_aux TO z20_codcli 
				DISPLAY nom_aux TO tit_nombre_cli
			END IF 
		END IF
		IF INFIELD(z20_tipo_doc) THEN
			CALL fl_ayuda_tipo_documento_cobranzas('D')
				RETURNING codt_aux, nomt_aux
			LET int_flag = 0
			IF codt_aux IS NOT NULL THEN
				DISPLAY codt_aux TO z20_tipo_doc
				DISPLAY nomt_aux TO tit_tipo_doc
			END IF 
		END IF
		IF INFIELD(z20_num_doc) THEN
			CALL fl_ayuda_doc_deudores_cob(vg_codcia, vg_codloc,
					coda_aux, cod_aux, codt_aux)
				RETURNING nom_aux, r_cxc.z20_tipo_doc,
					r_cxc.z20_num_doc, r_cxc.z20_dividendo,
					r_cxc.z20_saldo_cap, r_cxc.z20_moneda,
					abrevia
			LET int_flag = 0
			IF r_cxc.z20_num_doc IS NOT NULL THEN
				DISPLAY BY NAME r_cxc.z20_num_doc
				DISPLAY BY NAME r_cxc.z20_dividendo
			END IF 
		END IF
		IF INFIELD(z20_subtipo) THEN
			CALL fl_ayuda_subtipo_entidad(codt_aux)
				RETURNING codte_aux, codst_aux, nomte_aux,
					nomst_aux
			LET int_flag = 0
			IF codte_aux IS NOT NULL THEN
				DISPLAY codst_aux TO z20_subtipo
				DISPLAY nomte_aux TO tit_subtipo
			END IF 
		END IF
		IF INFIELD(z20_areaneg) THEN
			CALL fl_ayuda_areaneg(vg_codcia)
				RETURNING coda_aux, noma_aux
			LET int_flag = 0
			IF coda_aux IS NOT NULL THEN
				DISPLAY coda_aux TO z20_areaneg
				DISPLAY noma_aux TO tit_area
			END IF 
		END IF
		IF INFIELD(z20_moneda) THEN
			CALL fl_ayuda_monedas()
				RETURNING mone_aux, nomm_aux, deci_aux
			LET int_flag = 0
			IF mone_aux IS NOT NULL THEN
				DISPLAY mone_aux TO z20_moneda 
				DISPLAY nomm_aux TO tit_mon_bas
			END IF 
		END IF
		IF INFIELD(z20_cartera) THEN
			CALL fl_ayuda_subtipo_cartera()
				RETURNING codc_aux, nomc_aux
			LET int_flag = 0
			IF codc_aux IS NOT NULL THEN
				DISPLAY codc_aux TO z20_cartera 
				DISPLAY nomc_aux TO tit_cartera
			END IF 
		END IF
		IF INFIELD(z20_linea) THEN
			CALL fl_ayuda_grupo_lineas(vg_codcia)
				RETURNING codl_aux, noml_aux
			LET int_flag = 0
			IF codl_aux IS NOT NULL THEN
				DISPLAY codl_aux TO z20_linea 
				DISPLAY noml_aux TO tit_linea
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
	LET expr_sql = ' z20_codcli    = ' || arg_val(5) ||
		   ' AND z20_tipo_doc  = ' || '"' || arg_val(6) || '"' ||
		   ' AND z20_num_doc   = ' || '"' || arg_val(7) || '"' ||
		   ' AND z20_dividendo = ' || arg_val(8)
END IF
LET query = 'SELECT *, ROWID FROM cxct020 ' ||
		'WHERE z20_compania  = ' || vg_codcia ||
		'  AND z20_localidad = ' || vg_codloc ||
		'  AND ' || expr_sql CLIPPED||
		' ORDER BY 3,4,5,6'
PREPARE cons FROM query	
DECLARE q_cons CURSOR FOR cons
LET vm_num_rows = 0
FOREACH q_cons INTO rm_z20.*, num_reg
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
DEFINE r_cxc_aux	RECORD LIKE cxct020.*
DEFINE r_cli		RECORD LIKE cxct002.*
DEFINE r_cli_gen	RECORD LIKE cxct001.*
DEFINE r_tip		RECORD LIKE cxct004.*
DEFINE r_sub		RECORD LIKE gent012.*
DEFINE r_are		RECORD LIKE gent003.*
DEFINE r_mon		RECORD LIKE gent013.*
DEFINE r_mon_par	RECORD LIKE gent014.*
DEFINE r_car		RECORD LIKE gent012.*
DEFINE r_lin		RECORD LIKE gent020.*
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
DEFINE codc_aux		LIKE gent012.g12_subtipo
DEFINE nomc_aux		LIKE gent012.g12_nombre
DEFINE codl_aux		LIKE gent020.g20_grupo_linea
DEFINE noml_aux		LIKE gent020.g20_nombre
DEFINE r_cxc		RECORD LIKE cxct020.*
DEFINE abrevia		LIKE gent003.g03_abreviacion
DEFINE tasa_mora	LIKE cxct020.z20_tasa_mora
DEFINE fecha_emi	LIKE cxct020.z20_fecha_emi
DEFINE aux_sri		LIKE cxct020.z20_num_sri
DEFINE resul		SMALLINT

INITIALIZE r_cxc_aux.*, r_cli.*, r_cli_gen.*, r_tip.*, r_are.*, r_mon.*,
	r_mon_par.*, r_car.*, r_lin.*, cod_aux, codt_aux, coda_aux, mone_aux,
	codc_aux, codl_aux, codte_aux, codst_aux, r_cxc.* TO NULL
DISPLAY BY NAME rm_z20.z20_dividendo, rm_z20.z20_tasa_int, rm_z20.z20_tasa_mora,
		rm_z20.z20_fecha_emi, rm_z20.z20_paridad, rm_z20.z20_valor_cap,
		rm_z20.z20_valor_int, rm_z20.z20_origen, rm_z20.z20_saldo_cap,
		rm_z20.z20_saldo_int, rm_z20.z20_usuario, rm_z20.z20_fecing
LET val_base   = 0
LET rm_z20.z20_val_impto  = 0
LET int_flag = 0
LET flag_impto = 'S'
INPUT BY NAME rm_z20.z20_codcli, rm_z20.z20_tipo_doc, rm_z20.z20_num_doc,
	rm_z20.z20_dividendo, rm_z20.z20_subtipo, rm_z20.z20_areaneg,
	rm_z20.z20_referencia, rm_z20.z20_fecha_emi, rm_z20.z20_fecha_vcto,
	rm_z20.z20_tasa_int, rm_z20.z20_tasa_mora, rm_z20.z20_moneda,
	val_base, flag_impto, rm_z20.z20_val_impto, rm_z20.z20_valor_cap, 
	rm_z20.z20_valor_int, rm_z20.z20_cartera, rm_z20.z20_linea, 
	rm_z20.z20_num_sri
	WITHOUT DEFAULTS
	ON KEY(INTERRUPT)
	        IF field_touched(rm_z20.z20_codcli, rm_z20.z20_tipo_doc,
			rm_z20.z20_num_doc, rm_z20.z20_dividendo,
			rm_z20.z20_subtipo, rm_z20.z20_areaneg,
			rm_z20.z20_referencia, rm_z20.z20_fecha_emi,
			rm_z20.z20_fecha_vcto, rm_z20.z20_tasa_int,
			rm_z20.z20_tasa_mora, rm_z20.z20_moneda,
			val_base, flag_impto, rm_z20.z20_val_impto, 
			rm_z20.z20_valor_cap, rm_z20.z20_valor_int,
			rm_z20.z20_cartera, rm_z20.z20_linea,rm_z20.z20_num_sri)
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
		IF INFIELD(z20_codcli) THEN
			CALL fl_ayuda_cliente_localidad(vg_codcia,vg_codloc)
				RETURNING cod_aux, nom_aux
			LET int_flag = 0
			IF cod_aux IS NOT NULL THEN
				LET rm_z20.z20_codcli = cod_aux
				DISPLAY BY NAME rm_z20.z20_codcli 
				DISPLAY nom_aux TO tit_nombre_cli
			END IF 
		END IF
		IF INFIELD(z20_tipo_doc) THEN
			CALL fl_ayuda_tipo_documento_cobranzas('D')
				RETURNING codt_aux, nomt_aux
			LET int_flag = 0
			IF codt_aux IS NOT NULL THEN
				LET rm_z20.z20_tipo_doc = codt_aux
				DISPLAY BY NAME rm_z20.z20_tipo_doc
				DISPLAY nomt_aux TO tit_tipo_doc
			END IF 
		END IF
		IF INFIELD(z20_num_doc) THEN
			CALL fl_ayuda_doc_deudores_cob(vg_codcia, vg_codloc,
					rm_z20.z20_areaneg, rm_z20.z20_codcli,
					rm_z20.z20_tipo_doc)
				RETURNING nom_aux, r_cxc.z20_tipo_doc,
					r_cxc.z20_num_doc, r_cxc.z20_dividendo,
					r_cxc.z20_saldo_cap, r_cxc.z20_moneda,
					abrevia
			LET int_flag = 0
			IF r_cxc.z20_num_doc IS NOT NULL THEN
				LET rm_z20.z20_num_doc = r_cxc.z20_num_doc
				LET rm_z20.z20_dividendo = r_cxc.z20_dividendo
							+ 1
				DISPLAY BY NAME rm_z20.z20_num_doc
				DISPLAY BY NAME rm_z20.z20_dividendo
			END IF 
		END IF
		IF INFIELD(z20_subtipo) THEN
			CALL fl_ayuda_subtipo_entidad(rm_z20.z20_tipo_doc)
				RETURNING codte_aux, codst_aux, nomte_aux,
					nomst_aux
			LET int_flag = 0
			IF codte_aux IS NOT NULL THEN
				LET rm_z20.z20_subtipo = codst_aux
				DISPLAY BY NAME rm_z20.z20_subtipo
				DISPLAY nomte_aux TO tit_subtipo
			END IF 
		END IF
		IF INFIELD(z20_areaneg) THEN
			CALL fl_ayuda_areaneg(vg_codcia)
				RETURNING coda_aux, noma_aux
			LET int_flag = 0
			IF coda_aux IS NOT NULL THEN
				LET rm_z20.z20_areaneg = coda_aux
				DISPLAY BY NAME rm_z20.z20_areaneg
				DISPLAY noma_aux TO tit_area
			END IF 
		END IF
		IF INFIELD(z20_moneda) THEN
			CALL fl_ayuda_monedas()
				RETURNING mone_aux, nomm_aux, deci_aux
			LET int_flag = 0
			IF mone_aux IS NOT NULL THEN
				LET rm_z20.z20_moneda = mone_aux
				DISPLAY BY NAME rm_z20.z20_moneda 
				DISPLAY nomm_aux TO tit_mon_bas
			END IF 
		END IF
		IF INFIELD(z20_cartera) THEN
			CALL fl_ayuda_subtipo_cartera()
				RETURNING codc_aux, nomc_aux
			LET int_flag = 0
			IF codc_aux IS NOT NULL THEN
				LET rm_z20.z20_cartera = codc_aux
				DISPLAY BY NAME rm_z20.z20_cartera 
				DISPLAY nomc_aux TO tit_cartera
			END IF 
		END IF
		IF INFIELD(z20_linea) THEN
			CALL fl_ayuda_grupo_lineas(vg_codcia)
				RETURNING codl_aux, noml_aux
			LET int_flag = 0
			IF codl_aux IS NOT NULL THEN
				LET rm_z20.z20_linea = codl_aux
				DISPLAY BY NAME rm_z20.z20_linea 
				DISPLAY noml_aux TO tit_linea
			END IF
		END IF
	BEFORE FIELD z20_fecha_emi
		LET fecha_emi = rm_z20.z20_fecha_emi
	BEFORE FIELD z20_fecha_vcto
		IF rm_z20.z20_fecha_emi IS NULL THEN
			CALL fl_mostrar_mensaje('Ingrese la fecha de emisión primero.','info')
			NEXT FIELD z20_fecha_emi
		END IF
	BEFORE FIELD z20_tasa_mora
		LET tasa_mora = rm_z20.z20_tasa_mora
	AFTER FIELD z20_codcli
		IF rm_z20.z20_codcli IS NOT NULL THEN
			CALL fl_lee_cliente_general(rm_z20.z20_codcli)
		 		RETURNING r_cli_gen.*
			IF r_cli_gen.z01_codcli IS NULL THEN
				CALL fl_mostrar_mensaje('Cliente no existe.','exclamation')
				NEXT FIELD z20_codcli
			END IF
			DISPLAY r_cli_gen.z01_nomcli TO tit_nombre_cli
			IF r_cli_gen.z01_estado = 'B' THEN
                                CALL fl_mensaje_estado_bloqueado()
                                NEXT FIELD z20_codcli
                        END IF		 
			CALL fl_lee_cliente_localidad(vg_codcia, vg_codloc,
							rm_z20.z20_codcli)
		 		RETURNING r_cli.*
			IF r_cli.z02_compania IS NULL THEN
				CALL fl_mostrar_mensaje('Cliente no está activado para la compañía.','exclamation')
				NEXT FIELD z20_codcli
			END IF
		ELSE
			CLEAR tit_nombre_cli
		END IF
	AFTER FIELD z20_tipo_doc 
		IF rm_z20.z20_tipo_doc IS NOT NULL THEN
			CALL fl_lee_tipo_doc(rm_z20.z20_tipo_doc)
				RETURNING r_tip.* 
			IF r_tip.z04_tipo_doc IS NULL THEN
				CALL fl_mostrar_mensaje('Tipo de documento no existe.','exclamation')
				NEXT FIELD z20_tipo_doc
			END IF
			DISPLAY r_tip.z04_nombre TO tit_tipo_doc
			IF r_tip.z04_tipo <> "D" THEN
				CALL fl_mostrar_mensaje('Tipo de documento debe ser deudor.','exclamation')
				NEXT FIELD z20_tipo_doc
			END IF
			IF rm_z20.z20_tipo_doc <> 'DO' AND
			   rm_z20.z20_tipo_doc <> 'DI' AND
			   rm_z20.z20_tipo_doc <> 'DF' AND
			   rm_z20.z20_tipo_doc <> 'FA' AND
			   rm_z20.z20_tipo_doc <> 'ND'
			THEN
				CALL fl_mostrar_mensaje('Tipo de documento debe ser deudor.','exclamation')
				NEXT FIELD z20_tipo_doc
			END IF
			IF r_tip.z04_estado = 'B' THEN
                                CALL fl_mensaje_estado_bloqueado()
				NEXT FIELD z20_tipo_doc
			END IF
		ELSE
			CLEAR tit_tipo_doc
		END IF
	AFTER FIELD z20_num_doc 
		IF rm_z20.z20_num_doc IS NULL OR rm_z20.z20_tipo_doc = 'ND' THEN
			LET rm_z20.z20_num_doc = 0
			DISPLAY BY NAME rm_z20.z20_num_doc
		END IF
	AFTER FIELD z20_subtipo
		IF rm_z20.z20_subtipo IS NOT NULL THEN
			CALL fl_lee_subtipo_entidad(rm_z20.z20_tipo_doc,
							rm_z20.z20_subtipo)
				RETURNING r_sub.*
			IF r_sub.g12_tiporeg IS NULL THEN
				CALL fl_mostrar_mensaje('No existe este subtipo de documento.','exclamation')
				NEXT FIELD z20_subtipo
			END IF
			DISPLAY r_sub.g12_nombre TO tit_subtipo
		END IF
	AFTER FIELD z20_areaneg
		IF rm_z20.z20_areaneg IS NOT NULL THEN
			CALL fl_lee_area_negocio(vg_codcia,rm_z20.z20_areaneg)
				RETURNING r_are.*
			IF r_are.g03_areaneg IS NULL THEN
				CALL fl_mostrar_mensaje('Area de Negocio no existe.','exclamation')
				NEXT FIELD z20_areaneg
			END IF
			DISPLAY r_are.g03_nombre TO tit_area
		ELSE
			CLEAR tit_area
		END IF
	AFTER FIELD z20_fecha_emi
		IF rm_z20.z20_fecha_emi IS NOT NULL THEN
			IF rm_z20.z20_fecha_emi > vg_fecha 
			OR (MONTH(rm_z20.z20_fecha_emi) <> MONTH(vg_fecha)
			OR YEAR(rm_z20.z20_fecha_emi) <> YEAR(vg_fecha)) THEN
				CALL fl_mostrar_mensaje('La fecha de emisión debe ser de hoy o del presente mes.','exclamation')
				NEXT FIELD z20_fecha_emi
			END IF
		ELSE
			LET rm_z20.z20_fecha_emi = fecha_emi
			DISPLAY BY NAME rm_z20.z20_fecha_emi
		END IF
	AFTER FIELD z20_fecha_vcto
		IF rm_z20.z20_fecha_vcto IS NOT NULL THEN
			IF rm_z20.z20_fecha_vcto <= rm_z20.z20_fecha_emi THEN
				CALL fl_mostrar_mensaje('La fecha de vencimiento debe ser mayor a la fecha de emisión.','exclamation')
				NEXT FIELD z20_fecha_vcto
			END IF
		END IF
	AFTER FIELD z20_tasa_int
		IF rm_z20.z20_tasa_int IS NULL THEN
			LET rm_z20.z20_tasa_mora = 0
			DISPLAY BY NAME rm_z20.z20_tasa_mora
		END IF
	AFTER FIELD z20_tasa_mora
		IF rm_z20.z20_tasa_mora IS NULL THEN
			LET rm_z20.z20_tasa_mora = tasa_mora
			DISPLAY BY NAME rm_z20.z20_tasa_mora
		END IF
	AFTER FIELD z20_moneda 
		IF rm_z20.z20_moneda IS NOT NULL THEN
			CALL fl_lee_moneda(rm_z20.z20_moneda)
				RETURNING r_mon.* 
			IF r_mon.g13_moneda IS NULL  THEN
				CALL fl_mostrar_mensaje('Moneda no existe.','exclamation')
				NEXT FIELD z20_moneda
			END IF
			DISPLAY r_mon.g13_nombre TO tit_mon_bas
			IF r_mon.g13_estado = 'B' THEN
                                CALL fl_mensaje_estado_bloqueado()
				NEXT FIELD z20_moneda
			END IF
			IF rm_z20.z20_moneda = rg_gen.g00_moneda_base THEN
				LET r_mon_par.g14_tasa = 1
			ELSE
				CALL fl_lee_factor_moneda(rm_z20.z20_moneda,
							rg_gen.g00_moneda_base)
					RETURNING r_mon_par.*
				IF r_mon_par.g14_serial IS NULL THEN
					CALL fl_mostrar_mensaje('La paridad para está moneda no existe.','exclamation')
					NEXT FIELD z20_moneda
				END IF
			END IF
			LET rm_z20.z20_paridad = r_mon_par.g14_tasa
			DISPLAY BY NAME rm_z20.z20_paridad
		ELSE
			LET rm_z20.z20_moneda = rg_gen.g00_moneda_base
			DISPLAY BY NAME rm_z20.z20_moneda
			CALL fl_lee_moneda(rm_z20.z20_moneda) RETURNING r_mon.* 
			DISPLAY r_mon.g13_nombre TO tit_mon_bas
		END IF
	AFTER FIELD val_base 
		IF val_base IS NULL THEN
			LET val_base = 0
		END IF
		CALL fl_retorna_precision_valor(rm_z20.z20_moneda, val_base)
                	RETURNING val_base
		DISPLAY BY NAME val_base
		CALL calcula_valores()
	AFTER FIELD z20_valor_cap
		IF rm_z20.z20_valor_cap IS NOT NULL THEN
			CALL fl_retorna_precision_valor(rm_z20.z20_moneda,
                                                        rm_z20.z20_valor_cap)
                                RETURNING rm_z20.z20_valor_cap
			LET rm_z20.z20_saldo_cap = rm_z20.z20_valor_cap
			DISPLAY BY NAME rm_z20.z20_saldo_cap
		ELSE
			LET rm_z20.z20_valor_cap = 0
			LET rm_z20.z20_saldo_cap = rm_z20.z20_valor_cap
			DISPLAY BY NAME rm_z20.z20_valor_cap,
					rm_z20.z20_saldo_cap
		END IF
	AFTER FIELD z20_valor_int
		IF rm_z20.z20_valor_int IS NULL OR rm_z20.z20_tipo_doc = 'ND' THEN
			LET rm_z20.z20_valor_int = 0
		END IF
		CALL fl_retorna_precision_valor(rm_z20.z20_moneda,
                                                 rm_z20.z20_valor_int)
                        RETURNING rm_z20.z20_valor_int
		CALL calcula_valores()
	AFTER FIELD flag_impto
		CALL calcula_valores()
	AFTER FIELD z20_cartera 
		IF rm_z20.z20_cartera IS NOT NULL THEN
			CALL fl_lee_subtipo_entidad('CR',rm_z20.z20_cartera)
				RETURNING r_car.*
			IF r_car.g12_tiporeg IS NULL  THEN
				CALL fl_mostrar_mensaje('Cartera no existe.','exclamation')
				NEXT FIELD z20_cartera
			END IF
			DISPLAY r_car.g12_nombre TO tit_cartera
		ELSE
			CLEAR tit_cartera
		END IF
	AFTER FIELD z20_linea 
		IF rm_z20.z20_linea IS NOT NULL THEN
			CALL fl_lee_grupo_linea(vg_codcia,rm_z20.z20_linea)
				RETURNING r_lin.*
			IF r_lin.g20_grupo_linea IS NULL  THEN
				CALL fl_mostrar_mensaje('Línea de venta no existe.','exclamation')
				NEXT FIELD z20_linea
			END IF
			DISPLAY r_lin.g20_nombre TO tit_linea
		ELSE
			CLEAR tit_linea
		END IF
	AFTER FIELD z20_dividendo 
		IF rm_z20.z20_tipo_doc = 'ND' THEN
			LET rm_z20.z20_dividendo = 1
			DISPLAY BY NAME rm_z20.z20_dividendo
		END IF
	BEFORE FIELD z20_num_sri
		IF rm_z20.z20_tipo_doc = 'ND' THEN
			LET aux_sri = rm_z20.z20_num_sri
			CALL validar_num_sri(aux_sri) RETURNING rm_g37.*, resul
			CASE resul
				WHEN -1
					--ROLLBACK WORK
					EXIT PROGRAM
				WHEN 0
					NEXT FIELD z20_num_sri
			END CASE
		ELSE
			LET rm_z20.z20_num_sri = NULL
			DISPLAY BY NAME rm_z20.z20_num_sri
		END IF
	AFTER FIELD z20_num_sri
		IF rm_z20.z20_tipo_doc = 'ND' THEN
			IF rm_z20.z20_num_sri IS NOT NULL THEN
				CALL validar_num_sri(aux_sri)
					RETURNING rm_g37.*, resul
				CASE resul
					WHEN -1
						--ROLLBACK WORK
						EXIT PROGRAM
					WHEN 0
						NEXT FIELD z20_num_sri
				END CASE
			ELSE
				LET rm_z20.z20_num_sri = aux_sri
			END IF
		ELSE
			LET rm_z20.z20_num_sri = NULL
		END IF
		DISPLAY BY NAME rm_z20.z20_num_sri
	AFTER INPUT
		CALL calcula_valores()
		IF rm_z20.z20_tipo_doc = 'ND' THEN
			LET rm_z20.z20_dividendo = 1
			DISPLAY BY NAME rm_z20.z20_dividendo
			IF rm_z20.z20_num_sri IS NULL THEN
				CALL fl_mostrar_mensaje('Digite número pre-impreso en el formato de Nota de Débito.','exclamation')
				NEXT FIELD rm_z20.z20_num_sri
			END IF
		END IF
		IF rm_z20.z20_tipo_doc = 'ND' THEN
			IF rm_z20.z20_num_sri IS NOT NULL THEN
				CALL validar_num_sri(aux_sri)
					RETURNING rm_g37.*, resul
				CASE resul
					WHEN -1
						--ROLLBACK WORK
						EXIT PROGRAM
					WHEN 0
						NEXT FIELD z20_num_sri
				END CASE
			END IF
		ELSE
			LET rm_z20.z20_num_sri = NULL
			DISPLAY BY NAME rm_z20.z20_num_sri
		END IF
		CALL fl_lee_documento_deudor_cxc(vg_codcia, vg_codloc,
				rm_z20.z20_codcli, rm_z20.z20_tipo_doc,
				rm_z20.z20_num_doc,rm_z20.z20_dividendo)
			RETURNING r_cxc_aux.*
		IF r_cxc_aux.z20_compania IS NOT NULL THEN
			IF rm_z20.z20_num_doc > 0 THEN
				CALL fl_mostrar_mensaje('Documento ya ha sido ingresado.','exclamation')
				NEXT FIELD z20_codcli
			END IF
		END IF
		IF rm_z20.z20_subtipo IS NULL THEN
			IF rm_z20.z20_tipo_doc = 'ND' THEN
				CALL fl_mostrar_mensaje('Ingrese el subtipo de la Nota de Débito.','exclamation')
				NEXT FIELD z20_subtipo
			END IF
		END IF
		IF rm_z20.z20_linea IS NOT NULL THEN
			CALL fl_lee_grupo_linea(vg_codcia,rm_z20.z20_linea)
				RETURNING r_lin.*
			IF rm_z20.z20_areaneg <> r_lin.g20_areaneg THEN
				CALL fl_mostrar_mensaje('La línea no pertenece al área de negocio especificada.','exclamation')
				NEXT FIELD z20_linea
			END IF
		END IF
		IF rm_z20.z20_valor_cap + rm_z20.z20_valor_int <= 0 THEN
			CALL fl_mostrar_mensaje('El documento no puede grabarse con valor capital o valor interés de cero.','exclamation')
			NEXT FIELD z20_valor_cap
		END IF
		LET rm_z20.z20_saldo_cap = rm_z20.z20_valor_cap
		LET rm_z20.z20_saldo_int = rm_z20.z20_valor_int
		IF rm_z20.z20_tipo_doc = 'ND' THEN
			LET rm_z20.z20_num_doc = NULL
		END IF
END INPUT

END FUNCTION



FUNCTION validar_num_sri(aux_sri)
DEFINE aux_sri		LIKE cxct020.z20_num_sri
DEFINE cont		INTEGER
DEFINE flag		SMALLINT

CALL fl_validacion_num_sri(vg_codcia, vg_codloc, rm_z20.z20_tipo_doc, 'N', 
				rm_z20.z20_num_sri)
	RETURNING rm_g37.*, rm_z20.z20_num_sri, flag
CASE flag
	WHEN -1
		RETURN rm_g37.*, -1
	WHEN 0
		RETURN rm_g37.*, 0
END CASE
DISPLAY BY NAME rm_z20.z20_num_sri
{--
IF LENGTH(rm_z20.z20_num_sri) < 15 THEN
	CALL fl_mostrar_mensaje('Digite completo el número del SRI.','exclamation')
	RETURN rm_g37.*, 0
END IF
--}
IF aux_sri <> rm_z20.z20_num_sri THEN
	SELECT COUNT(*) INTO cont FROM cxct020
		WHERE z20_compania  = vg_codcia
		  AND z20_localidad = vg_codloc
  		  AND z20_num_sri   = rm_z20.z20_num_sri
	IF cont > 0 THEN
		CALL fl_mostrar_mensaje('La secuencia del SRI ' || rm_z20.z20_num_sri[9,15] || ' ya existe.','exclamation')
		RETURN rm_g37.*, 0
	END IF
END IF
RETURN rm_g37.*, 1

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
                                                                                
DISPLAY "        " TO tit_nombre_cli
CLEAR tit_nombre_cli
DISPLAY num_rows    TO vm_num_rows2
DISPLAY row_current TO vm_num_current2
DISPLAY num_rows    TO vm_num_rows1
DISPLAY row_current TO vm_num_current1

END FUNCTION



FUNCTION mostrar_registro(num_registro)
DEFINE r_cli_gen	RECORD LIKE cxct001.*
DEFINE r_tip		RECORD LIKE cxct004.*
DEFINE r_sub		RECORD LIKE gent012.*
DEFINE r_are		RECORD LIKE gent003.*
DEFINE r_mon		RECORD LIKE gent013.*
DEFINE r_car		RECORD LIKE gent012.*
DEFINE r_lin		RECORD LIKE gent020.*
DEFINE r_mod		RECORD LIKE gent050.*
DEFINE num_registro	INTEGER

IF vm_num_rows <= 0 THEN
	RETURN
END IF
SELECT * INTO rm_z20.* FROM cxct020 WHERE ROWID = num_registro
IF STATUS = NOTFOUND THEN
	CALL fgl_winmessage (vg_producto,'No existe registro con índice: ' || vm_row_current,'exclamation')
	RETURN
END IF
IF num_args() = 9 THEN
	IF arg_val(9) < vg_fecha THEN
		CALL obtener_saldo_deudor_fecha()
	END IF
END IF
LET flag_impto = 'N'
IF rm_z20.z20_val_impto > 0 THEN
	LET flag_impto = 'S'
END IF
LET val_base = rm_z20.z20_valor_cap - rm_z20.z20_val_impto
DISPLAY BY NAME rm_z20.z20_codcli, rm_z20.z20_tipo_doc,
		rm_z20.z20_num_doc, rm_z20.z20_dividendo,
		rm_z20.z20_subtipo, rm_z20.z20_areaneg,
		rm_z20.z20_referencia, rm_z20.z20_fecha_emi,
		rm_z20.z20_fecha_vcto, rm_z20.z20_tasa_int,
		rm_z20.z20_tasa_mora, rm_z20.z20_moneda,
		rm_z20.z20_paridad, rm_z20.z20_valor_cap,
		rm_z20.z20_valor_int, rm_z20.z20_saldo_cap,
		rm_z20.z20_saldo_int, rm_z20.z20_cartera,
		rm_z20.z20_linea, rm_z20.z20_origen,
		rm_z20.z20_cod_tran, rm_z20.z20_num_tran,
		rm_z20.z20_num_sri,  rm_z20.z20_val_impto,
		val_base, flag_impto,
		rm_z20.z20_usuario, rm_z20.z20_fecing
CALL fl_lee_cliente_general(rm_z20.z20_codcli) RETURNING r_cli_gen.*
CALL fl_lee_tipo_doc(rm_z20.z20_tipo_doc) RETURNING r_tip.* 
DISPLAY r_tip.z04_nombre TO tit_tipo_doc
CALL fl_lee_subtipo_entidad(rm_z20.z20_tipo_doc,rm_z20.z20_subtipo)
	RETURNING r_sub.*
DISPLAY r_sub.g12_nombre TO tit_subtipo
CALL fl_lee_area_negocio(vg_codcia,rm_z20.z20_areaneg) RETURNING r_are.*
CALL fl_lee_modulo(r_are.g03_modulo) RETURNING r_mod.*
DISPLAY r_are.g03_nombre TO tit_area
DISPLAY r_mod.g50_nombre TO tit_modulo
CALL fl_lee_moneda(rm_z20.z20_moneda) RETURNING r_mon.* 
DISPLAY r_mon.g13_nombre TO tit_mon_bas
CALL fl_lee_subtipo_entidad('CR',rm_z20.z20_cartera) RETURNING r_car.*
DISPLAY r_car.g12_nombre TO tit_cartera
CALL fl_lee_grupo_linea(vg_codcia,rm_z20.z20_linea)
	RETURNING r_lin.*
DISPLAY r_lin.g20_nombre TO tit_linea
DISPLAY r_cli_gen.z01_nomcli TO tit_nombre_cli

END FUNCTION



FUNCTION calcula_valores()

IF flag_impto = 'S' THEN
	LET rm_z20.z20_val_impto = val_base * rg_gen.g00_porc_impto / 100
	CALL fl_retorna_precision_valor(rm_z20.z20_moneda, rm_z20.z20_val_impto)
            	RETURNING rm_z20.z20_val_impto
ELSE
	LET rm_z20.z20_val_impto = 0
END IF
LET rm_z20.z20_valor_cap = val_base + rm_z20.z20_val_impto
LET rm_z20.z20_saldo_cap = rm_z20.z20_valor_cap
LET rm_z20.z20_saldo_int = rm_z20.z20_valor_int
DISPLAY BY NAME rm_z20.z20_valor_cap, rm_z20.z20_val_impto, 
	        rm_z20.z20_saldo_cap, rm_z20.z20_saldo_int

END FUNCTION



FUNCTION obtener_saldo_deudor_fecha()
DEFINE r_z60		RECORD LIKE cxct060.*
DEFINE fecha		LIKE cxct022.z22_fecing
DEFINE query		CHAR(4000)
DEFINE subquery1	CHAR(1500)
DEFINE subquery2	CHAR(500)
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
LET subquery1 = '(SELECT z23_valor_cap + z23_valor_int + z23_saldo_cap + ',
			'z23_saldo_int ',
		' FROM cxct023, cxct022 ',
		' WHERE z23_compania  = z20_compania ',
		'   AND z23_localidad = z20_localidad ',
		'   AND z23_codcli    = z20_codcli ',
		'   AND z23_tipo_doc  = z20_tipo_doc ',
		'   AND z23_num_doc   = z20_num_doc ',
		'   AND z23_div_doc   = z20_dividendo ',
		'   AND z22_compania  = z23_compania ',
		'   AND z22_localidad = z23_localidad ',
		'   AND z22_codcli    = z23_codcli ',
		'   AND z22_tipo_trn  = z23_tipo_trn ',
		'   AND z22_num_trn   = z23_num_trn ',
		'   AND z22_fecing    = (SELECT MAX(z22_fecing) ',
					' FROM cxct023, cxct022 ',
					' WHERE z23_compania  = z20_compania ',
					'   AND z23_localidad = z20_localidad ',
					'   AND z23_codcli    = z20_codcli ',
					'   AND z23_tipo_doc  = z20_tipo_doc ',
					'   AND z23_num_doc   = z20_num_doc ',
					'   AND z23_div_doc   = z20_dividendo ',
					'   AND z22_compania  = z23_compania ',
					'   AND z22_localidad = z23_localidad ',
					'   AND z22_codcli    = z23_codcli ',
					'   AND z22_tipo_trn  = z23_tipo_trn ',
					'   AND z22_num_trn   = z23_num_trn ',
					'   AND z22_fecing   <= "', fecha, '"))'
LET subquery2 = ' (SELECT NVL(SUM(z23_valor_cap + z23_valor_int), 0) ',
		' FROM cxct023 ',
		' WHERE z23_compania  = z20_compania ',
		'   AND z23_localidad = z20_localidad ',
		'   AND z23_codcli    = z20_codcli ',
		'   AND z23_tipo_doc  = z20_tipo_doc ',
		'   AND z23_num_doc   = z20_num_doc ',
		'   AND z23_div_doc   = z20_dividendo) '
LET query = 'SELECT NVL(', subquery1 CLIPPED, ', ',
			' CASE WHEN z20_fecha_emi <= "', fec_ini, '"',
				' THEN z20_saldo_cap + z20_saldo_int - ',
					subquery2 CLIPPED,
				' ELSE z20_valor_cap + z20_valor_int',
			' END) saldo_doc ',
		' FROM cxct020 ',
		' WHERE z20_compania   = ', rm_z20.z20_compania,
		'   AND z20_localidad  = ', rm_z20.z20_localidad,
		'   AND z20_codcli     = ', rm_z20.z20_codcli,
		'   AND z20_tipo_doc   = "', rm_z20.z20_tipo_doc, '"',
		'   AND z20_num_doc    = "', rm_z20.z20_num_doc, '"',
		'   AND z20_dividendo  = ', rm_z20.z20_dividendo,
		'   AND z20_fecha_emi <= "', arg_val(9), '"',
		' INTO TEMP t1 '
PREPARE stmnt1 FROM query
EXECUTE stmnt1
SELECT NVL(saldo_doc, 0) INTO rm_z20.z20_saldo_cap FROM t1
DROP TABLE t1
ERROR ' '

END FUNCTION



FUNCTION generar_secuencia()
DEFINE resul		SMALLINT
DEFINE r_z20		RECORD LIKE cxct020.*

WHILE TRUE
	CALL fl_actualiza_control_secuencias(vg_codcia, vg_codloc, vg_modulo,
						'AA', rm_z20.z20_tipo_doc)
		RETURNING rm_z20.z20_num_doc
	IF rm_z20.z20_num_doc <= 0 THEN
		LET resul = 0
		EXIT WHILE
	END IF
	CALL fl_lee_documento_deudor_cxc(vg_codcia, vg_codloc,rm_z20.z20_codcli,
					rm_z20.z20_tipo_doc, rm_z20.z20_num_doc,
					rm_z20.z20_dividendo)
		RETURNING r_z20.*
	IF r_z20.z20_compania IS NULL THEN
		LET resul = 1
		EXIT WHILE
	END IF
END WHILE
RETURN resul

END FUNCTION



FUNCTION imprimir()
DEFINE comando		CHAR(400)
DEFINE run_prog		VARCHAR(20)

LET run_prog = '; fglrun '
IF vg_gui = 0 THEN
	LET run_prog = '; fglgo '
END IF
LET comando = 'cd ..', vg_separador, '..', vg_separador, 'COBRANZAS',
	vg_separador, 'fuentes', vg_separador, run_prog, 'cxcp415 ', vg_base,
	' ', vg_modulo, ' ', vg_codcia, ' ', vg_codloc, ' ', rm_z20.z20_codcli,
	' "', rm_z20.z20_tipo_doc, '" ', rm_z20.z20_num_doc, ' ',
	rm_z20.z20_dividendo
RUN comando

END FUNCTION



FUNCTION control_contabilizar()
DEFINE r_z41		RECORD LIKE cxct041.*

INITIALIZE r_z41.* TO NULL
SELECT * INTO r_z41.* FROM cxct041
	WHERE z41_compania  = rm_z20.z20_compania
	  AND z41_localidad = rm_z20.z20_localidad
	  AND z41_codcli    = rm_z20.z20_codcli
	  AND z41_tipo_doc  = rm_z20.z20_tipo_doc
	  AND z41_num_doc   = rm_z20.z20_num_doc
	  AND z41_dividendo = rm_z20.z20_dividendo
IF r_z41.z41_compania IS NULL THEN
	CALL fl_mostrar_mensaje('Este documento no tiene contablización automatica.', 'exclamation')
	RETURN
END IF
CALL ver_contabilizacion(r_z41.z41_tipo_comp, r_z41.z41_num_comp)

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



FUNCTION generar_doc_elec()
DEFINE comando		VARCHAR(250)
DEFINE servid		VARCHAR(10)
DEFINE mensaje		VARCHAR(250)

LET servid  = FGL_GETENV("INFORMIXSERVER")
CASE servid
	WHEN "ACGYE01"
		LET servid = "idsgye01"
	WHEN "ACUIO01"
		LET servid = "idsuio01"
	WHEN "ACUIO02"
		LET servid = "idsuio02"
END CASE
LET comando = "fglgo gen_tra_ele ", vg_base CLIPPED, " ", servid CLIPPED, " ",
		vg_codcia, " ", vg_codloc, " ", rm_z20.z20_tipo_doc, " ",
		rm_z20.z20_num_doc, " NDC ", rm_z20.z20_codcli
RUN comando
LET mensaje = FGL_GETENV("HOME"), '/tmp/ND_ELEC/'
CALL fl_mostrar_mensaje('Archivo XML de NOTA DEBITO Generado en: ' || mensaje, 'info')

END FUNCTION
