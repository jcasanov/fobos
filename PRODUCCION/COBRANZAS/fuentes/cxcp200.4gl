------------------------------------------------------------------------------
-- Titulo           : cxcp200.4gl - Ingreso de documentos deudores 
-- Elaboracion      : 02-oct-2001
-- Autor            : NPC
-- Formato Ejecucion: fglrun cxcp200 base m�dulo compa��a localidad
--			[cliente][tipo_documento][numero_documento][dividendo]
-- Ultima Correccion: 
-- Motivo Correccion: 
------------------------------------------------------------------------------
GLOBALS '../../../PRODUCCION/LIBRERIAS/fuentes/globales.4gl'

DEFINE rm_cxc		RECORD LIKE cxct020.*
DEFINE rm_z20           RECORD LIKE cxct020.*
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
IF num_args() <> 4 AND num_args() <> 8 THEN  -- Validar # par�metros correcto
	CALL fgl_winmessage(vg_producto, 'N�mero de par�metros incorrecto.', 'stop')
	EXIT PROGRAM
END IF
LET vg_base     = arg_val(1)
LET vg_modulo   = arg_val(2)
LET vg_codcia   = arg_val(3)
LET vg_codloc   = arg_val(4)
LET vg_proceso = 'cxcp200'
CALL fl_activar_base_datos(vg_base)
CALL fl_seteos_defaults()	
CALL fgl_settitle(vg_proceso || ' - ' || vg_producto)
CALL validar_parametros()
CALL fl_cabecera_pantalla(vg_codcia, vg_codloc, vg_modulo, vg_proceso)
CALL control_master()

END MAIN



FUNCTION control_master()

CALL fl_nivel_isolation()
CALL fl_chequeo_mes_proceso_cxc(vg_codcia) RETURNING int_flag 
IF int_flag THEN
	RETURN
END IF
LET vm_max_rows	= 1000
OPEN WINDOW wf AT 3,2 WITH 21 ROWS, 80 COLUMNS
    ATTRIBUTE(FORM LINE FIRST + 2, COMMENT LINE LAST, MENU LINE FIRST,BORDER,
	      MESSAGE LINE LAST - 2)
OPTIONS INPUT WRAP,
	ACCEPT KEY	F12
OPEN FORM f_cxc FROM "../forms/cxcf200_1"
DISPLAY FORM f_cxc
INITIALIZE rm_cxc.* TO NULL
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
DEFINE r_cia            RECORD LIKE cxct000.*
DEFINE cuantos          SMALLINT
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
INITIALIZE rm_cxc.*, r_mon.*, r_cia.* TO NULL
CLEAR z20_paridad, z20_saldo_cap, tit_modulo, z20_cod_tran, z20_num_tran,
	z20_saldo_int, tit_nombre_cli, tit_tipo_doc, tit_subtipo, tit_mon_bas,
	tit_cartera, tit_linea, tit_area
CALL fl_lee_compania_cobranzas(vg_codcia)
	RETURNING r_cia.*
LET rm_cxc.z20_compania  = vg_codcia
LET rm_cxc.z20_localidad = vg_codloc
LET rm_cxc.z20_dividendo = 1
LET rm_cxc.z20_fecha_emi = CURRENT
LET rm_cxc.z20_tasa_int  = 0 
LET rm_cxc.z20_tasa_mora = r_cia.z00_tasa_mora
LET rm_cxc.z20_moneda    = rg_gen.g00_moneda_base
LET rm_cxc.z20_valor_cap = 0
LET rm_cxc.z20_valor_int = 0
LET rm_cxc.z20_saldo_cap = 0
LET rm_cxc.z20_saldo_int = 0
LET rm_cxc.z20_paridad   = 1
LET rm_cxc.z20_origen    = 'M'
LET rm_cxc.z20_usuario   = vg_usuario
LET rm_cxc.z20_fecing    = CURRENT
CALL fl_lee_moneda(rm_cxc.z20_moneda) RETURNING r_mon.*
IF r_mon.g13_moneda IS NULL THEN
        CALL fgl_winmessage(vg_producto,'No existe ninguna moneda base.','stop')
        EXIT PROGRAM
ELSE
        DISPLAY r_mon.g13_nombre TO tit_mon_bas
END IF
CALL leer_datos()
IF NOT int_flag THEN
	LET rm_cxc.z20_fecing = CURRENT
	BEGIN WORK
		IF rm_cxc.z20_tipo_doc = 'ND' THEN
			CALL fl_actualiza_control_secuencias(vg_codcia,
						vg_codloc, vg_modulo, 'AA',
						rm_cxc.z20_tipo_doc)
				RETURNING rm_cxc.z20_num_doc
			IF rm_cxc.z20_num_doc <= '0' THEN
				ROLLBACK WORK
				EXIT PROGRAM
			END IF
			DISPLAY BY NAME rm_cxc.z20_num_doc
		END IF
		INSERT INTO cxct020 VALUES (rm_cxc.*)
		LET num_aux = SQLCA.SQLERRD[6] 
		CALL fl_genera_saldos_cliente(vg_codcia, vg_codloc,
						rm_cxc.z20_codcli)
--OJO DESDE AQUI SE LLAMA A LA CONTABILIZACION

                LET r_datdoc.codcia    = vg_codcia
                LET r_datdoc.cliprov   = rm_cxc.z20_codcli
                LET r_datdoc.tipo_doc  = rm_cxc.z20_tipo_doc
                LET r_datdoc.subtipo   = NULL
                IF rm_cxc.z20_tipo_doc = 'ND' THEN
                        LET r_datdoc.subtipo = 21
                END IF
                LET r_datdoc.moneda    = rm_cxc.z20_moneda
                LET r_datdoc.paridad   = rm_cxc.z20_paridad
                LET r_datdoc.valor_doc = rm_cxc.z20_valor_cap
                LET r_datdoc.flag_mod  = 1     -- Modulo
                CALL fl_contabilizacion_documentos(r_datdoc.*)
                        RETURNING r_b12.*, resul
                IF int_flag THEN
                        IF resul = 0 THEN
                                ROLLBACK WORK
                                EXIT PROGRAM
                        END IF
                END IF
                IF resul THEN
                        INSERT INTO cxct041
                        VALUES (rm_cxc.z20_compania, rm_cxc.z20_localidad,
                                rm_cxc.z20_codcli, rm_cxc.z20_tipo_doc,
                                rm_cxc.z20_num_doc, rm_cxc.z20_dividendo,
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
	DISPLAY BY NAME rm_cxc.z20_fecing
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
DEFINE query		VARCHAR(800)
DEFINE expr_sql		VARCHAR(800)
DEFINE num_reg		INTEGER

CLEAR FORM
INITIALIZE cod_aux, codt_aux, coda_aux, mone_aux, codc_aux, codl_aux, codte_aux,
	codst_aux, r_cxc.* TO NULL
LET int_flag = 0
IF num_args() = 4 THEN
	CONSTRUCT BY NAME expr_sql ON z20_codcli, z20_tipo_doc, z20_num_doc,
	z20_dividendo, z20_subtipo, z20_areaneg, z20_referencia, z20_fecha_emi,
	z20_fecha_vcto, z20_tasa_int, z20_tasa_mora, z20_moneda, z20_valor_cap,
	z20_valor_int, z20_cartera, z20_linea, z20_origen
	ON KEY(F2)
		IF infield(z20_codcli) THEN
			CALL fl_ayuda_cliente_localidad(vg_codcia,vg_codloc)
				RETURNING cod_aux, nom_aux
			LET int_flag = 0
			IF cod_aux IS NOT NULL THEN
				DISPLAY cod_aux TO z20_codcli 
				DISPLAY nom_aux TO tit_nombre_cli
			END IF 
		END IF
		IF infield(z20_tipo_doc) THEN
			CALL fl_ayuda_tipo_documento_cobranzas('D')
				RETURNING codt_aux, nomt_aux
			LET int_flag = 0
			IF codt_aux IS NOT NULL THEN
				DISPLAY codt_aux TO z20_tipo_doc
				DISPLAY nomt_aux TO tit_tipo_doc
			END IF 
		END IF
		IF infield(z20_num_doc) THEN
			CALL fl_ayuda_doc_deudores_cob(vg_codcia, vg_codloc,
					coda_aux, cod_aux, codt_aux, 0)
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
		IF infield(z20_subtipo) THEN
			CALL fl_ayuda_subtipo_entidad(codt_aux)
				RETURNING codte_aux, codst_aux, nomte_aux,
					nomst_aux
			LET int_flag = 0
			IF codte_aux IS NOT NULL THEN
				DISPLAY codst_aux TO z20_subtipo
				DISPLAY nomte_aux TO tit_subtipo
			END IF 
		END IF
		IF infield(z20_areaneg) THEN
			CALL fl_ayuda_areaneg(vg_codcia)
				RETURNING coda_aux, noma_aux
			LET int_flag = 0
			IF coda_aux IS NOT NULL THEN
				DISPLAY coda_aux TO z20_areaneg
				DISPLAY noma_aux TO tit_area
			END IF 
		END IF
		IF infield(z20_moneda) THEN
			CALL fl_ayuda_monedas()
				RETURNING mone_aux, nomm_aux, deci_aux
			LET int_flag = 0
			IF mone_aux IS NOT NULL THEN
				DISPLAY mone_aux TO z20_moneda 
				DISPLAY nomm_aux TO tit_mon_bas
			END IF 
		END IF
		IF infield(z20_cartera) THEN
			CALL fl_ayuda_subtipo_cartera()
				RETURNING codc_aux, nomc_aux
			LET int_flag = 0
			IF codc_aux IS NOT NULL THEN
				DISPLAY codc_aux TO z20_cartera 
				DISPLAY nomc_aux TO tit_cartera
			END IF 
		END IF
		IF infield(z20_linea) THEN
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
FOREACH q_cons INTO rm_cxc.*, num_reg
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

INITIALIZE r_cxc_aux.*, r_cli.*, r_cli_gen.*, r_tip.*, r_are.*, r_mon.*,
	r_mon_par.*, r_car.*, r_lin.*, cod_aux, codt_aux, coda_aux, mone_aux,
	codc_aux, codl_aux, codte_aux, codst_aux, r_cxc.* TO NULL
DISPLAY BY NAME rm_cxc.z20_dividendo, rm_cxc.z20_tasa_int, rm_cxc.z20_tasa_mora,
		rm_cxc.z20_fecha_emi, rm_cxc.z20_paridad, rm_cxc.z20_valor_cap,
		rm_cxc.z20_valor_int, rm_cxc.z20_origen, rm_cxc.z20_saldo_cap,
		rm_cxc.z20_saldo_int, rm_cxc.z20_usuario, rm_cxc.z20_fecing
LET int_flag = 0
INPUT BY NAME rm_cxc.z20_codcli, rm_cxc.z20_tipo_doc, rm_cxc.z20_num_doc,
	rm_cxc.z20_dividendo, rm_cxc.z20_subtipo, rm_cxc.z20_areaneg,
	rm_cxc.z20_referencia, rm_cxc.z20_fecha_emi, rm_cxc.z20_fecha_vcto,
	rm_cxc.z20_tasa_int, rm_cxc.z20_tasa_mora, rm_cxc.z20_moneda,
	rm_cxc.z20_valor_cap, rm_cxc.z20_valor_int, rm_cxc.z20_cartera,
	rm_cxc.z20_linea
	WITHOUT DEFAULTS
	ON KEY(INTERRUPT)
	        IF field_touched(rm_cxc.z20_codcli, rm_cxc.z20_tipo_doc,
			rm_cxc.z20_num_doc, rm_cxc.z20_dividendo,
			rm_cxc.z20_subtipo, rm_cxc.z20_areaneg,
			rm_cxc.z20_referencia, rm_cxc.z20_fecha_emi,
			rm_cxc.z20_fecha_vcto, rm_cxc.z20_tasa_int,
			rm_cxc.z20_tasa_mora, rm_cxc.z20_moneda,
			rm_cxc.z20_valor_cap, rm_cxc.z20_valor_int,
			rm_cxc.z20_cartera, rm_cxc.z20_linea)
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
		IF infield(z20_codcli) THEN
			CALL fl_ayuda_cliente_localidad(vg_codcia,vg_codloc)
				RETURNING cod_aux, nom_aux
			LET int_flag = 0
			IF cod_aux IS NOT NULL THEN
				LET rm_cxc.z20_codcli = cod_aux
				DISPLAY BY NAME rm_cxc.z20_codcli 
				DISPLAY nom_aux TO tit_nombre_cli
			END IF 
		END IF
		IF infield(z20_tipo_doc) THEN
			CALL fl_ayuda_tipo_documento_cobranzas('D')
				RETURNING codt_aux, nomt_aux
			LET int_flag = 0
			IF codt_aux IS NOT NULL THEN
				LET rm_cxc.z20_tipo_doc = codt_aux
				DISPLAY BY NAME rm_cxc.z20_tipo_doc
				DISPLAY nomt_aux TO tit_tipo_doc
			END IF 
		END IF
		IF infield(z20_num_doc) THEN
			CALL fl_ayuda_doc_deudores_cob(vg_codcia, vg_codloc,
					rm_cxc.z20_areaneg, rm_cxc.z20_codcli,
					rm_cxc.z20_tipo_doc, 0)
				RETURNING nom_aux, r_cxc.z20_tipo_doc,
					r_cxc.z20_num_doc, r_cxc.z20_dividendo,
					r_cxc.z20_saldo_cap, r_cxc.z20_moneda,
					abrevia
			LET int_flag = 0
			IF r_cxc.z20_num_doc IS NOT NULL THEN
				LET rm_cxc.z20_num_doc = r_cxc.z20_num_doc
				LET rm_cxc.z20_dividendo = r_cxc.z20_dividendo
							+ 1
				DISPLAY BY NAME rm_cxc.z20_num_doc
				DISPLAY BY NAME rm_cxc.z20_dividendo
			END IF 
		END IF
		IF infield(z20_subtipo) THEN
			CALL fl_ayuda_subtipo_entidad(rm_cxc.z20_tipo_doc)
				RETURNING codte_aux, codst_aux, nomte_aux,
					nomst_aux
			LET int_flag = 0
			IF codte_aux IS NOT NULL THEN
				LET rm_cxc.z20_subtipo = codst_aux
				DISPLAY BY NAME rm_cxc.z20_subtipo
				DISPLAY nomte_aux TO tit_subtipo
			END IF 
		END IF
		IF infield(z20_areaneg) THEN
			CALL fl_ayuda_areaneg(vg_codcia)
				RETURNING coda_aux, noma_aux
			LET int_flag = 0
			IF coda_aux IS NOT NULL THEN
				LET rm_cxc.z20_areaneg = coda_aux
				DISPLAY BY NAME rm_cxc.z20_areaneg
				DISPLAY noma_aux TO tit_area
			END IF 
		END IF
		IF infield(z20_moneda) THEN
			CALL fl_ayuda_monedas()
				RETURNING mone_aux, nomm_aux, deci_aux
			LET int_flag = 0
			IF mone_aux IS NOT NULL THEN
				LET rm_cxc.z20_moneda = mone_aux
				DISPLAY BY NAME rm_cxc.z20_moneda 
				DISPLAY nomm_aux TO tit_mon_bas
			END IF 
		END IF
		IF infield(z20_cartera) THEN
			CALL fl_ayuda_subtipo_cartera()
				RETURNING codc_aux, nomc_aux
			LET int_flag = 0
			IF codc_aux IS NOT NULL THEN
				LET rm_cxc.z20_cartera = codc_aux
				DISPLAY BY NAME rm_cxc.z20_cartera 
				DISPLAY nomc_aux TO tit_cartera
			END IF 
		END IF
		IF infield(z20_linea) THEN
			CALL fl_ayuda_grupo_lineas(vg_codcia)
				RETURNING codl_aux, noml_aux
			LET int_flag = 0
			IF codl_aux IS NOT NULL THEN
				LET rm_cxc.z20_linea = codl_aux
				DISPLAY BY NAME rm_cxc.z20_linea 
				DISPLAY noml_aux TO tit_linea
			END IF
		END IF
	BEFORE FIELD z20_fecha_emi
		LET fecha_emi = rm_cxc.z20_fecha_emi
	BEFORE FIELD z20_fecha_vcto
		IF rm_cxc.z20_fecha_emi IS NULL THEN
			CALL fgl_winmessage(vg_producto,'Ingrese la fecha de emisi�n primero.','info')
			NEXT FIELD z20_fecha_emi
		END IF
	BEFORE FIELD z20_tasa_mora
		LET tasa_mora = rm_cxc.z20_tasa_mora
	AFTER FIELD z20_codcli
		IF rm_cxc.z20_codcli IS NOT NULL THEN
			CALL fl_lee_cliente_general(rm_cxc.z20_codcli)
		 		RETURNING r_cli_gen.*
			IF r_cli_gen.z01_codcli IS NULL THEN
				CALL fgl_winmessage(vg_producto,'Cliente no existe.','exclamation')
				NEXT FIELD z20_codcli
			END IF
			DISPLAY r_cli_gen.z01_nomcli TO tit_nombre_cli
			IF r_cli_gen.z01_estado = 'B' THEN
                                CALL fl_mensaje_estado_bloqueado()
                                NEXT FIELD z20_codcli
                        END IF		 
			CALL fl_lee_cliente_localidad(vg_codcia, vg_codloc,
							rm_cxc.z20_codcli)
		 		RETURNING r_cli.*
			IF r_cli.z02_compania IS NULL THEN
				CALL fgl_winmessage(vg_producto,'Cliente no est� activado para la compa��a.','exclamation')
				NEXT FIELD z20_codcli
			END IF
		ELSE
			CLEAR tit_nombre_cli
		END IF
	AFTER FIELD z20_tipo_doc 
		IF rm_cxc.z20_tipo_doc IS NOT NULL THEN
			CALL fl_lee_tipo_doc(rm_cxc.z20_tipo_doc)
				RETURNING r_tip.* 
			IF r_tip.z04_tipo_doc IS NULL THEN
				CALL fgl_winmessage(vg_producto,'Tipo de documento no existe.','exclamation')
				NEXT FIELD z20_tipo_doc
			END IF
			DISPLAY r_tip.z04_nombre TO tit_tipo_doc
			IF r_tip.z04_tipo <> 'D' THEN
				CALL fgl_winmessage(vg_producto,'Tipo de documento debe ser deudor.','exclamation')
				NEXT FIELD z20_tipo_doc
			END IF
			IF rm_cxc.z20_tipo_doc <> 'DO'
			AND rm_cxc.z20_tipo_doc <> 'FA'
			AND rm_cxc.z20_tipo_doc <> 'ND' THEN
				CALL fgl_winmessage(vg_producto,'Tipo de documento debe ser deudor.','exclamation')
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
		IF rm_cxc.z20_num_doc IS NULL THEN
			LET rm_cxc.z20_num_doc = 0
			DISPLAY BY NAME rm_cxc.z20_num_doc
		END IF
	AFTER FIELD z20_subtipo
		IF rm_cxc.z20_subtipo IS NOT NULL THEN
			CALL fl_lee_subtipo_entidad(rm_cxc.z20_tipo_doc,
							rm_cxc.z20_subtipo)
				RETURNING r_sub.*
			IF r_sub.g12_tiporeg IS NULL THEN
				CALL fgl_winmessage(vg_producto,'No existe este subtipo de documento.','exclamation')
				NEXT FIELD z20_subtipo
			END IF
			DISPLAY r_sub.g12_nombre TO tit_subtipo
		END IF
	AFTER FIELD z20_areaneg
		IF rm_cxc.z20_areaneg IS NOT NULL THEN
			CALL fl_lee_area_negocio(vg_codcia,rm_cxc.z20_areaneg)
				RETURNING r_are.*
			IF r_are.g03_areaneg IS NULL THEN
				CALL fgl_winmessage(vg_producto,'Area de Negocio no existe.','exclamation')
				NEXT FIELD z20_areaneg
			END IF
			DISPLAY r_are.g03_nombre TO tit_area
		ELSE
			CLEAR tit_area
		END IF
	AFTER FIELD z20_fecha_emi
		IF rm_cxc.z20_fecha_emi IS NOT NULL THEN
			IF rm_cxc.z20_fecha_emi > TODAY 
			OR (MONTH(rm_cxc.z20_fecha_emi) <> MONTH(TODAY)
			OR YEAR(rm_cxc.z20_fecha_emi) <> YEAR(TODAY)) THEN
				CALL fgl_winmessage(vg_producto,'La fecha de emisi�n debe ser de hoy o del presente mes.','exclamation')
				NEXT FIELD z20_fecha_emi
			END IF
		ELSE
			LET rm_cxc.z20_fecha_emi = fecha_emi
			DISPLAY BY NAME rm_cxc.z20_fecha_emi
		END IF
	AFTER FIELD z20_fecha_vcto
		IF rm_cxc.z20_fecha_vcto IS NOT NULL THEN
			IF rm_cxc.z20_fecha_vcto <= rm_cxc.z20_fecha_emi THEN
				CALL fgl_winmessage(vg_producto,'La fecha de vencimiento debe ser mayor a la fecha de emisi�n.','exclamation')
				NEXT FIELD z20_fecha_vcto
			END IF
		END IF
	AFTER FIELD z20_tasa_int
		IF rm_cxc.z20_tasa_int IS NULL THEN
			LET rm_cxc.z20_tasa_mora = 0
			DISPLAY BY NAME rm_cxc.z20_tasa_mora
		END IF
	AFTER FIELD z20_tasa_mora
		IF rm_cxc.z20_tasa_mora IS NULL THEN
			LET rm_cxc.z20_tasa_mora = tasa_mora
			DISPLAY BY NAME rm_cxc.z20_tasa_mora
		END IF
	AFTER FIELD z20_moneda 
		IF rm_cxc.z20_moneda IS NOT NULL THEN
			CALL fl_lee_moneda(rm_cxc.z20_moneda)
				RETURNING r_mon.* 
			IF r_mon.g13_moneda IS NULL  THEN
				CALL fgl_winmessage(vg_producto,'Moneda no existe.','exclamation')
				NEXT FIELD z20_moneda
			END IF
			DISPLAY r_mon.g13_nombre TO tit_mon_bas
			IF r_mon.g13_estado = 'B' THEN
                                CALL fl_mensaje_estado_bloqueado()
				NEXT FIELD z20_moneda
			END IF
			IF rm_cxc.z20_moneda = rg_gen.g00_moneda_base THEN
				LET r_mon_par.g14_tasa = 1
			ELSE
				CALL fl_lee_factor_moneda(rm_cxc.z20_moneda,
							rg_gen.g00_moneda_base)
					RETURNING r_mon_par.*
				IF r_mon_par.g14_serial IS NULL THEN
					CALL fgl_winmessage(vg_producto,'La paridad para est� moneda no existe.','exclamation')
					NEXT FIELD z20_moneda
				END IF
			END IF
			LET rm_cxc.z20_paridad = r_mon_par.g14_tasa
			DISPLAY BY NAME rm_cxc.z20_paridad
		ELSE
			LET rm_cxc.z20_moneda = rg_gen.g00_moneda_base
			DISPLAY BY NAME rm_cxc.z20_moneda
			CALL fl_lee_moneda(rm_cxc.z20_moneda) RETURNING r_mon.* 
			DISPLAY r_mon.g13_nombre TO tit_mon_bas
		END IF
	AFTER FIELD z20_valor_cap
		IF rm_cxc.z20_valor_cap IS NOT NULL THEN
			CALL fl_retorna_precision_valor(rm_cxc.z20_moneda,
                                                        rm_cxc.z20_valor_cap)
                                RETURNING rm_cxc.z20_valor_cap
			LET rm_cxc.z20_saldo_cap = rm_cxc.z20_valor_cap
			DISPLAY BY NAME rm_cxc.z20_saldo_cap
		ELSE
			LET rm_cxc.z20_valor_cap = 0
			LET rm_cxc.z20_saldo_cap = rm_cxc.z20_valor_cap
			DISPLAY BY NAME rm_cxc.z20_valor_cap,
					rm_cxc.z20_saldo_cap
		END IF
	AFTER FIELD z20_valor_int
		IF rm_cxc.z20_valor_int IS NOT NULL THEN
			CALL fl_retorna_precision_valor(rm_cxc.z20_moneda,
                                                        rm_cxc.z20_valor_int)
                                RETURNING rm_cxc.z20_valor_int
			LET rm_cxc.z20_saldo_int = rm_cxc.z20_valor_int
			DISPLAY BY NAME rm_cxc.z20_saldo_int
		ELSE
			LET rm_cxc.z20_valor_int = 0
			LET rm_cxc.z20_saldo_int = rm_cxc.z20_valor_int
			DISPLAY BY NAME rm_cxc.z20_valor_int,
					rm_cxc.z20_saldo_int
		END IF
	AFTER FIELD z20_cartera 
		IF rm_cxc.z20_cartera IS NOT NULL THEN
			CALL fl_lee_subtipo_entidad('CR',rm_cxc.z20_cartera)
				RETURNING r_car.*
			IF r_car.g12_tiporeg IS NULL  THEN
				CALL fgl_winmessage(vg_producto,'Cartera no existe.','exclamation')
				NEXT FIELD z20_cartera
			END IF
			DISPLAY r_car.g12_nombre TO tit_cartera
		ELSE
			CLEAR tit_cartera
		END IF
	AFTER FIELD z20_linea 
		IF rm_cxc.z20_linea IS NOT NULL THEN
			CALL fl_lee_grupo_linea(vg_codcia,rm_cxc.z20_linea)
				RETURNING r_lin.*
			IF r_lin.g20_grupo_linea IS NULL  THEN
				CALL fgl_winmessage(vg_producto,'L�nea de venta no existe.','exclamation')
				NEXT FIELD z20_linea
			END IF
			DISPLAY r_lin.g20_nombre TO tit_linea
		ELSE
			CLEAR tit_linea
		END IF
	AFTER INPUT
		CALL fl_lee_documento_deudor_cxc(vg_codcia, vg_codloc,
				rm_cxc.z20_codcli, rm_cxc.z20_tipo_doc,
				rm_cxc.z20_num_doc,rm_cxc.z20_dividendo)
			RETURNING r_cxc_aux.*
		IF r_cxc_aux.z20_compania IS NOT NULL THEN
			CALL fgl_winmessage(vg_producto,'Documento ya ha sido ingresado.','exclamation')
			NEXT FIELD z20_codcli
		END IF
		IF rm_cxc.z20_subtipo IS NULL THEN
			IF rm_cxc.z20_tipo_doc = 'ND' THEN
				CALL fgl_winmessage(vg_producto,'Ingrese el subtipo de la Nota de D�bito.','exclamation')
				NEXT FIELD z20_subtipo
			END IF
		END IF
		IF rm_cxc.z20_linea IS NOT NULL THEN
			CALL fl_lee_grupo_linea(vg_codcia,rm_cxc.z20_linea)
				RETURNING r_lin.*
			IF rm_cxc.z20_areaneg <> r_lin.g20_areaneg THEN
				CALL fgl_winmessage(vg_producto,'La l�nea no pertenece al �rea de negocio especificada.','exclamation')
				NEXT FIELD z20_linea
			END IF
		END IF
		IF rm_cxc.z20_valor_cap + rm_cxc.z20_valor_int <= 0 THEN
			CALL fgl_winmessage(vg_producto,'El documento no puede grabarse con valor capital o valor inter�s de cero.','exclamation')
			NEXT FIELD z20_valor_cap
		END IF
		LET rm_cxc.z20_saldo_cap = rm_cxc.z20_valor_cap
		LET rm_cxc.z20_saldo_int = rm_cxc.z20_valor_int
		IF rm_cxc.z20_tipo_doc = 'ND' THEN
			LET rm_cxc.z20_num_doc = NULL
		END IF
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

IF vm_num_rows > 0 THEN
	SELECT * INTO rm_cxc.* FROM cxct020 WHERE ROWID = num_registro
	IF STATUS = NOTFOUND THEN
		CALL fgl_winmessage (vg_producto,'No existe registro con �ndice: ' || vm_row_current,'exclamation')
		RETURN
	END IF
	DISPLAY BY NAME rm_cxc.z20_codcli, rm_cxc.z20_tipo_doc,
			rm_cxc.z20_num_doc, rm_cxc.z20_dividendo,
			rm_cxc.z20_subtipo, rm_cxc.z20_areaneg,
			rm_cxc.z20_referencia, rm_cxc.z20_fecha_emi,
			rm_cxc.z20_fecha_vcto, rm_cxc.z20_tasa_int,
			rm_cxc.z20_tasa_mora, rm_cxc.z20_moneda,
			rm_cxc.z20_paridad, rm_cxc.z20_valor_cap,
			rm_cxc.z20_valor_int, rm_cxc.z20_saldo_cap,
			rm_cxc.z20_saldo_int, rm_cxc.z20_cartera,
			rm_cxc.z20_linea, rm_cxc.z20_origen,
			rm_cxc.z20_cod_tran, rm_cxc.z20_num_tran,
			rm_cxc.z20_usuario, rm_cxc.z20_fecing
	CALL fl_lee_cliente_general(rm_cxc.z20_codcli) RETURNING r_cli_gen.*
	CALL fl_lee_tipo_doc(rm_cxc.z20_tipo_doc) RETURNING r_tip.* 
	DISPLAY r_tip.z04_nombre TO tit_tipo_doc
	CALL fl_lee_subtipo_entidad(rm_cxc.z20_tipo_doc,rm_cxc.z20_subtipo)
		RETURNING r_sub.*
	DISPLAY r_sub.g12_nombre TO tit_subtipo
	CALL fl_lee_area_negocio(vg_codcia,rm_cxc.z20_areaneg) RETURNING r_are.*
	CALL fl_lee_modulo(r_are.g03_modulo) RETURNING r_mod.*
	DISPLAY r_are.g03_nombre TO tit_area
	DISPLAY r_mod.g50_nombre TO tit_modulo
	CALL fl_lee_moneda(rm_cxc.z20_moneda) RETURNING r_mon.* 
	DISPLAY r_mon.g13_nombre TO tit_mon_bas
	CALL fl_lee_subtipo_entidad('CR',rm_cxc.z20_cartera) RETURNING r_car.*
	DISPLAY r_car.g12_nombre TO tit_cartera
	CALL fl_lee_grupo_linea(vg_codcia,rm_cxc.z20_linea)
		RETURNING r_lin.*
	DISPLAY r_lin.g20_nombre TO tit_linea
	DISPLAY r_cli_gen.z01_nomcli TO tit_nombre_cli
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
	CALL fgl_winmessage(vg_producto, 'No existe m�dulo: ' || vg_modulo, 'stop')
	EXIT PROGRAM
END IF
CALL fl_lee_compania(vg_codcia) RETURNING rg_cia.*
IF rg_cia.g01_compania IS NULL THEN
	CALL fgl_winmessage(vg_producto, 'No existe compa��a: '|| vg_codcia, 'stop')
	EXIT PROGRAM
END IF
IF rg_cia.g01_estado <> 'A' THEN
	CALL fgl_winmessage(vg_producto, 'Compa��a no est� activa: ' || vg_codcia, 'stop')
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
	CALL fgl_winmessage(vg_producto, 'Localidad no est� activa: '|| vg_codloc, 'stop')
	EXIT PROGRAM
END IF

END FUNCTION
