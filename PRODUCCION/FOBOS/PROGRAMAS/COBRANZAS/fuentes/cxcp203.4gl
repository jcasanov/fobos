------------------------------------------------------------------------------
-- Titulo           : cxcp203.4gl - Aplicación de Documentos a Favor
-- Elaboracion      : 22-nov-2001
-- Autor            : NPC
-- Formato Ejecucion: fglrun cxcp203 base módulo compañía localidad
-- Ultima Correccion: 
-- Motivo Correccion: 
------------------------------------------------------------------------------
GLOBALS '../../../PRODUCCION/LIBRERIAS/fuentes/globales.4gl'

DEFINE vm_demonios	VARCHAR(12)
DEFINE rm_z22		RECORD LIKE cxct022.*
DEFINE rm_z23		RECORD LIKE cxct023.*
DEFINE rm_z21		RECORD LIKE cxct021.*
DEFINE rm_z20		RECORD LIKE cxct020.*
DEFINE vm_num_rows	SMALLINT
DEFINE vm_row_current	SMALLINT
DEFINE vm_max_rows	SMALLINT
DEFINE vm_max_elm       SMALLINT
DEFINE vm_num_elm       SMALLINT
DEFINE vm_total_apl     DECIMAL(12,2)
DEFINE vm_total_act     DECIMAL(12,2)
DEFINE vm_total_nue     DECIMAL(12,2)
DEFINE rm_orden 	ARRAY[10] OF CHAR(4)
DEFINE vm_columna_1	SMALLINT
DEFINE vm_columna_2	SMALLINT
DEFINE vm_saldo		LIKE cxct021.z21_saldo
DEFINE vm_tipo_trn	LIKE cxct022.z22_tipo_trn
DEFINE vm_r_rows	ARRAY [1000] OF INTEGER
DEFINE rm_aju 		ARRAY [1000] OF RECORD
				z23_tipo_doc	LIKE cxct023.z23_tipo_doc,
				z23_num_doc	LIKE cxct023.z23_num_doc,
				z23_div_doc	LIKE cxct023.z23_div_doc,
				tit_saldo_act	DECIMAL(12,2),
				tit_valor_apl	DECIMAL(12,2),
				tit_saldo_nue	DECIMAL(12,2),
				tit_check	CHAR(1)
			END RECORD
DEFINE rm_sld 		ARRAY [1000] OF RECORD
				z20_fecha_vcto	LIKE cxct020.z20_fecha_vcto
			END RECORD
DEFINE rm_datdoc	RECORD
				codcia		LIKE gent001.g01_compania,
				cliprov		INTEGER,
				tipo_doc	CHAR(2),
				subtipo		LIKE ctbt012.b12_subtipo,
				moneda		LIKE gent013.g13_moneda,
				paridad		LIKE gent014.g14_tasa,
				valor_doc	DECIMAL(14,2),
				flag_mod	SMALLINT
			END RECORD



MAIN

DEFER QUIT 
DEFER INTERRUPT
CLEAR SCREEN
CALL startlog('../logs/errores')
--#CALL fgl_init4js()
CALL fl_marca_registrada_producto()
IF num_args() <> 4 THEN          -- Validar # parámetros correcto
	--CALL fgl_winmessage(vg_producto,'Número de parámetros incorrecto.', 'stop')
	CALL fl_mostrar_mensaje('Número de parámetros incorrecto.', 'stop')
	EXIT PROGRAM
END IF
LET vg_base     = arg_val(1)
LET vg_modulo   = arg_val(2)
LET vg_codcia   = arg_val(3)
LET vg_codloc   = arg_val(4)
LET vg_proceso = 'cxcp203'
CALL fl_activar_base_datos(vg_base)
CALL fl_seteos_defaults()	
--#CALL fgl_settitle(vg_proceso || ' - ' || vg_producto)
CALL fl_validar_parametros()
CALL fl_cabecera_pantalla(vg_codcia, vg_codloc, vg_modulo, vg_proceso)
CALL control_master()

END MAIN



FUNCTION control_master()
DEFINE indice           SMALLINT
DEFINE lin_menu		SMALLINT
DEFINE row_ini  	SMALLINT
DEFINE num_rows 	SMALLINT
DEFINE num_cols 	SMALLINT

CALL fl_nivel_isolation()
CALL fl_chequeo_mes_proceso_cxc(vg_codcia) RETURNING int_flag 
IF int_flag THEN
	RETURN
END IF
LET vm_max_rows	= 1000
LET vm_max_elm  = 1000
LET vm_tipo_trn = 'AJ'
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
	OPEN FORM f_cxc FROM "../forms/cxcf203_1"
ELSE
	OPEN FORM f_cxc FROM "../forms/cxcf203_1c"
END IF
DISPLAY FORM f_cxc
CALL mostrar_botones_detalle()
INITIALIZE rm_z22.*, rm_z23.*, rm_z21, rm_z20.* TO NULL
FOR indice = 1 TO 10
	LET rm_orden[indice] = '' 
END FOR
LET vm_num_rows    = 0
LET vm_row_current = 0
LET vm_num_elm     = 0
LET vm_total_apl   = 0
LET vm_total_act   = 0
LET vm_total_nue   = 0
CREATE TEMP TABLE tmp_detalle(
		z23_tipo_doc	CHAR(2),
		z23_num_doc	CHAR(15),
		z23_div_doc	SMALLINT,
		tit_saldo_act	DECIMAL(12,2),
		tit_valor_apl	DECIMAL(12,2),
		tit_saldo_nue	DECIMAL(12,2),
		tit_check	CHAR(1),
		z20_fecha_vcto	DATE
	)
CREATE INDEX tmp_ind1
        ON tmp_detalle(z23_tipo_doc ASC, z23_num_doc ASC, z23_div_doc ASC)
FOR indice = 1 TO vm_max_elm
        INITIALIZE rm_aju[indice].* TO NULL
END FOR
CALL muestra_contadores(vm_row_current, vm_num_rows)
CALL muestra_contadores_det(0)
MENU 'OPCIONES'
	BEFORE MENU
		HIDE OPTION 'Avanzar'
		HIDE OPTION 'Retroceder'
		HIDE OPTION 'Detalle'
		HIDE OPTION 'Contabilización'
       	COMMAND KEY('I') 'Ingreso' 'Ingresar nuevos registros. '
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
                SHOW OPTION 'Detalle'
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
                SHOW OPTION 'Detalle'
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
                SHOW OPTION 'Detalle'
	COMMAND KEY('D') 'Detalle' 'Muestra siguiente detalles del registro. '
                CALL muestra_detalle_arr()
	COMMAND KEY('S') 'Salir' 'Salir del programa. '
		EXIT MENU
END MENU

END FUNCTION



FUNCTION control_ingreso()
DEFINE num_aux		INTEGER
DEFINE i		SMALLINT
DEFINE valor_aux	DECIMAL(12,2)
DEFINE r_mon            RECORD LIKE gent013.*
DEFINE r_cxc            RECORD LIKE cxct022.*
DEFINE r_cxc3           RECORD LIKE cxct021.*
DEFINE r_cxc3_aux       RECORD LIKE cxct021.*
DEFINE r_b12		RECORD LIKE ctbt012.*
DEFINE r_b00		RECORD LIKE ctbt000.*
DEFINE resul		SMALLINT
DEFINE resp		CHAR(6)

CALL fl_retorna_usuario()
INITIALIZE rm_z22.*, rm_z23.*, rm_z21, rm_z20.*, r_cxc.*, r_cxc3.*,
	r_mon.*, r_cxc3_aux.*  TO NULL
CLEAR z22_tipo_trn, z22_num_trn, tit_nombre_cli, tit_mon_bas, tit_area,
	z20_fecha_vcto, tit_fecha_vcto, tit_dias, tit_tipo_doc, tit_total_apl,
	tit_total_act, tit_total_nue, z22_referencia, z21_saldo
FOR i = 1 TO vm_max_elm
	INITIALIZE rm_aju[i].*, rm_sld[i].* TO NULL
END FOR
FOR i = 1 TO fgl_scr_size('rm_aju')
	CLEAR rm_aju[i].*
END FOR
LET rm_z22.z22_compania   = vg_codcia
LET rm_z22.z22_localidad  = vg_codloc
LET rm_z22.z22_tipo_trn   = vm_tipo_trn
LET rm_z22.z22_fecha_emi  = TODAY
LET rm_z22.z22_moneda     = rg_gen.g00_moneda_base
LET rm_z22.z22_paridad    = 1
LET rm_z22.z22_tasa_mora  = 0
LET rm_z22.z22_total_cap  = 0
LET rm_z22.z22_total_int  = 0
LET rm_z22.z22_total_mora = 0
LET rm_z22.z22_origen     = 'M'
LET rm_z22.z22_usuario    = vg_usuario
LET rm_z22.z22_fecing     = CURRENT

LET rm_z23.z23_compania   = vg_codcia
LET rm_z23.z23_localidad  = vg_codloc
LET rm_z23.z23_valor_mora = 0
LET rm_z23.z23_saldo_cap  = 0
LET rm_z23.z23_saldo_int  = 0
CALL fl_lee_moneda(rm_z22.z22_moneda) RETURNING r_mon.*
IF r_mon.g13_moneda IS NULL THEN
        --CALL fgl_winmessage(vg_producto,'No existe ninguna moneda base.','stop')
	CALL fl_mostrar_mensaje('No existe ninguna moneda base.','stop')
        EXIT PROGRAM
END IF
DISPLAY r_mon.g13_nombre TO tit_mon_bas
CALL leer_cabecera()
IF NOT int_flag THEN
	BEGIN WORK
	WHENEVER ERROR CONTINUE
	DECLARE q_aplic CURSOR FOR SELECT * FROM cxct021
		WHERE z21_compania  = vg_codcia
		  AND z21_localidad = vg_codloc
		  AND z21_codcli    = rm_z22.z22_codcli
		  AND z21_tipo_doc  = rm_z21.z21_tipo_doc
		  AND z21_num_doc   = rm_z21.z21_num_doc
		FOR UPDATE
	OPEN q_aplic
	FETCH q_aplic INTO r_cxc3_aux.*
	IF STATUS < 0 THEN
		ROLLBACK WORK
		CALL fl_mensaje_bloqueo_otro_usuario()
		WHENEVER ERROR STOP
		RETURN
	END IF
	WHENEVER ERROR STOP
	CALL carga_detalle()
	IF vm_num_elm = 0 THEN
		ROLLBACK WORK
		RETURN
	END IF
	CALL leer_detalle()
	IF int_flag OR vm_num_elm < 1 THEN
		ROLLBACK WORK
		RETURN
	END IF
	CALL fl_actualiza_control_secuencias(vg_codcia,vg_codloc,
					vg_modulo,'AA',vm_tipo_trn)
		RETURNING rm_z22.z22_num_trn
	IF rm_z22.z22_num_trn <= 0 THEN
		ROLLBACK WORK
		EXIT PROGRAM
	END IF
	IF rm_z22.z22_num_trn <= 0 THEN
		ROLLBACK WORK
		EXIT PROGRAM
	END IF
	LET rm_z22.z22_fecing = CURRENT
	INSERT INTO cxct022 VALUES (rm_z22.*)
	LET num_aux              = SQLCA.SQLERRD[6] 
	LET rm_z23.z23_codcli   = rm_z22.z22_codcli
	LET rm_z23.z23_tipo_trn = rm_z22.z22_tipo_trn
	LET rm_z23.z23_num_trn  = rm_z22.z22_num_trn
	LET rm_z23.z23_areaneg  = rm_z22.z22_areaneg
	FOR i = 1 TO vm_num_elm
		IF rm_aju[i].tit_valor_apl = 0 THEN
			CONTINUE FOR
		END IF
		LET valor_aux = rm_aju[i].tit_valor_apl * (-1)
		WHENEVER ERROR CONTINUE
		DECLARE q_up CURSOR FOR
			SELECT * FROM cxct020
				WHERE z20_compania  = vg_codcia
				  AND z20_localidad = vg_codloc
				  AND z20_codcli    = rm_z23.z23_codcli
				  AND z20_tipo_doc  = rm_aju[i].z23_tipo_doc
				  AND z20_num_doc   = rm_aju[i].z23_num_doc
				  AND z20_dividendo = rm_aju[i].z23_div_doc
			FOR UPDATE
		OPEN q_up
		FETCH q_up INTO rm_z20.*
		IF STATUS = NOTFOUND THEN
			ROLLBACK WORK
			CALL fl_mostrar_mensaje('Registro no encontrado.','stop')
			WHENEVER ERROR STOP
			EXIT PROGRAM
		END IF
		IF STATUS < 0 THEN
			ROLLBACK WORK
			CALL fl_mensaje_bloqueo_otro_usuario()
			WHENEVER ERROR STOP
			EXIT PROGRAM
		END IF
		IF valor_aux > rm_z20.z20_saldo_cap + rm_z20.z20_saldo_int
		THEN
			ROLLBACK WORK
			CALL fl_mostrar_mensaje('No puede realizar el ajuste de documentos al cliente en este momento.','stop')
			WHENEVER ERROR STOP
			EXIT PROGRAM
		END IF
		WHENEVER ERROR STOP
		LET rm_z23.z23_orden = i
		IF valor_aux <= rm_z20.z20_saldo_int THEN
	                LET rm_z23.z23_valor_int = rm_aju[i].tit_valor_apl
	                LET rm_z23.z23_valor_cap = 0
	        ELSE
       		     	LET rm_z23.z23_valor_int = rm_z20.z20_saldo_int * (-1)
	                LET rm_z23.z23_valor_cap = rm_z20.z20_saldo_int	+
							rm_aju[i].tit_valor_apl
	        END IF
		LET rm_z22.z22_total_cap = rm_z22.z22_total_cap
					+ rm_z23.z23_valor_cap
		LET rm_z22.z22_total_int = rm_z22.z22_total_int
					+ rm_z23.z23_valor_int
		INSERT INTO cxct023 VALUES(rm_z23.z23_compania,
			rm_z23.z23_localidad, rm_z23.z23_codcli,
			rm_z23.z23_tipo_trn, rm_z23.z23_num_trn,
			rm_z23.z23_orden, rm_z23.z23_areaneg,
			rm_aju[i].z23_tipo_doc, rm_aju[i].z23_num_doc,
			rm_aju[i].z23_div_doc, rm_z21.z21_tipo_doc,
			rm_z21.z21_num_doc, rm_z23.z23_valor_cap,
			rm_z23.z23_valor_int, rm_z23.z23_valor_mora,
			rm_z20.z20_saldo_cap, rm_z20.z20_saldo_int)
		UPDATE cxct020
			SET z20_saldo_cap = z20_saldo_cap
					+ rm_z23.z23_valor_cap,
			   z20_saldo_int = z20_saldo_int
					+ rm_z23.z23_valor_int
			WHERE CURRENT OF q_up
		CLOSE q_up
		FREE q_up
	END FOR
	WHENEVER ERROR CONTINUE
	DECLARE q_up2 CURSOR FOR
		SELECT * FROM cxct022
			WHERE z22_compania  = vg_codcia
			  AND z22_localidad = vg_codloc
			  AND z22_codcli    = rm_z22.z22_codcli
			  AND z22_tipo_trn  = rm_z22.z22_tipo_trn
			  AND z22_num_trn   = rm_z22.z22_num_trn
		FOR UPDATE
	OPEN q_up2
	FETCH q_up2 INTO r_cxc.*
	IF STATUS < 0 THEN
		ROLLBACK WORK
		CALL fl_mensaje_bloqueo_otro_usuario()
		WHENEVER ERROR STOP
		EXIT PROGRAM
	END IF
	WHENEVER ERROR STOP
	UPDATE cxct022 SET z22_total_cap = rm_z22.z22_total_cap,
			   z22_total_int = rm_z22.z22_total_int
		WHERE CURRENT OF q_up2
	CLOSE q_up2
	FREE q_up2
	WHENEVER ERROR CONTINUE
	DECLARE q_up3 CURSOR FOR
		SELECT * FROM cxct021
			WHERE z21_compania  = vg_codcia
			  AND z21_localidad = vg_codloc
			  AND z21_codcli    = rm_z22.z22_codcli
			  AND z21_tipo_doc  = rm_z21.z21_tipo_doc
			  AND z21_num_doc   = rm_z21.z21_num_doc
		FOR UPDATE
	OPEN q_up3
	FETCH q_up3 INTO r_cxc3.*
	IF STATUS < 0 THEN
		ROLLBACK WORK
		CALL fl_mensaje_bloqueo_otro_usuario()
		WHENEVER ERROR STOP
		EXIT PROGRAM
	END IF
	WHENEVER ERROR STOP
	UPDATE cxct021 SET z21_saldo = rm_z21.z21_saldo
		WHERE CURRENT OF q_up3
	CLOSE q_up3
	FREE q_up3
	CALL fl_genera_saldos_cliente(vg_codcia, vg_codloc, rm_z22.z22_codcli)
	LET rm_datdoc.codcia    = vg_codcia
	LET rm_datdoc.cliprov   = rm_z22.z22_codcli
	LET rm_datdoc.tipo_doc  = rm_z22.z22_tipo_trn
	LET rm_datdoc.subtipo   = NULL
	LET rm_datdoc.moneda    = rm_z22.z22_moneda
	LET rm_datdoc.paridad   = rm_z22.z22_paridad
	LET rm_datdoc.valor_doc = rm_z22.z22_total_cap + rm_z22.z22_total_int 
	IF rm_datdoc.valor_doc < 0 THEN
		LET rm_datdoc.valor_doc = rm_datdoc.valor_doc * (-1)
	END IF
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
			VALUES (rm_z22.z22_compania, rm_z22.z22_localidad,
				rm_z22.z22_codcli, rm_z22.z22_tipo_trn,
				rm_z22.z22_num_trn, r_b12.b12_tipo_comp,
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
	LET vm_row_current = vm_num_rows
	DISPLAY BY NAME rm_z22.z22_fecing
	LET vm_r_rows[vm_row_current] = num_aux
	CALL muestra_contadores(vm_row_current, vm_num_rows)
	CALL muestra_contadores_det(0)
	CALL mostrar_registro(vm_r_rows[vm_num_rows])	
	CALL fl_mensaje_registro_ingresado()
END IF
IF int_flag OR vm_num_elm = 0 THEN
	CLEAR FORM
	CALL mostrar_botones_detalle()
	CALL muestra_contadores(vm_row_current, vm_num_rows)
	CALL muestra_contadores_det(0)
	IF vm_row_current > 0 THEN
		CALL mostrar_registro(vm_r_rows[vm_row_current])
	END IF
END IF

END FUNCTION



FUNCTION control_consulta()
DEFINE num_trn		LIKE cxct022.z22_num_trn
DEFINE codcli		LIKE cxct002.z02_codcli
DEFINE nomcli		LIKE cxct001.z01_nomcli
DEFINE coda_aux		LIKE gent003.g03_areaneg
DEFINE noma_aux		LIKE gent003.g03_nombre
DEFINE mone_aux		LIKE gent013.g13_moneda
DEFINE nomm_aux		LIKE gent013.g13_nombre
DEFINE deci_aux		LIKE gent013.g13_decimales
DEFINE codt_aux         LIKE cxct004.z04_tipo_doc
DEFINE nomt_aux         LIKE cxct004.z04_nombre
DEFINE r_cxc		RECORD LIKE cxct021.*
DEFINE abrevia		LIKE gent003.g03_abreviacion
DEFINE query		CHAR(800)
DEFINE expr_sql		CHAR(600)

CLEAR FORM
CALL mostrar_botones_detalle()
INITIALIZE num_trn, codcli, codt_aux, coda_aux, mone_aux, r_cxc.* TO NULL
LET int_flag = 0
CONSTRUCT BY NAME expr_sql ON z22_tipo_trn, z22_num_trn, z22_codcli,
	z22_areaneg, z22_moneda, z21_tipo_doc, z21_num_doc, z22_referencia
        ON KEY(F1,CONTROL-W)
		CALL llamar_visor_teclas()
	ON KEY(F2)
		IF INFIELD(z22_tipo_trn) THEN
                	CALL fl_ayuda_tipo_documento_cobranzas('T')
                                RETURNING codt_aux, nomt_aux
                        LET int_flag = 0
                        IF codt_aux IS NOT NULL THEN
                                DISPLAY codt_aux TO z22_tipo_trn
                        END IF
                END IF
		IF INFIELD(z22_num_trn) THEN
			CALL fl_ayuda_transaccion_cob(vg_codcia, vg_codloc)
				RETURNING num_trn
                        LET int_flag = 0
                        IF num_trn IS NOT NULL THEN
				DISPLAY num_trn TO z22_num_trn
                	END IF
                END IF
		IF INFIELD(z22_codcli) THEN
			CALL fl_ayuda_cliente_localidad(vg_codcia,vg_codloc)
                                RETURNING codcli, nomcli
                        LET int_flag = 0
                        IF codcli IS NOT NULL THEN
                                DISPLAY codcli TO z22_codcli
                                DISPLAY nomcli TO tit_nombre_cli
                        END IF
                END IF
		IF INFIELD(z22_areaneg) THEN
			CALL fl_ayuda_areaneg(vg_codcia)
				RETURNING coda_aux, noma_aux
			LET int_flag = 0
			IF coda_aux IS NOT NULL THEN
				DISPLAY coda_aux TO z22_areaneg
				DISPLAY noma_aux TO tit_area
			END IF 
		END IF
		IF INFIELD(z22_moneda) THEN
			CALL fl_ayuda_monedas()
				RETURNING mone_aux, nomm_aux, deci_aux
			LET int_flag = 0
			IF mone_aux IS NOT NULL THEN
				DISPLAY mone_aux TO z22_moneda 
				DISPLAY nomm_aux TO tit_mon_bas
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
					coda_aux, codcli, codt_aux)
				RETURNING nomcli, r_cxc.z21_tipo_doc,
					r_cxc.z21_num_doc, r_cxc.z21_saldo,
					r_cxc.z21_moneda, abrevia
			LET int_flag = 0
			IF r_cxc.z21_num_doc IS NOT NULL THEN
				DISPLAY r_cxc.z21_num_doc TO z21_num_doc
				DISPLAY r_cxc.z21_saldo TO z21_saldo
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
		CALL mostrar_botones_detalle()
	END IF
	RETURN
END IF
LET query = 'SELECT DISTINCT cxct022.*, cxct022.ROWID ' ||
		'FROM cxct022, cxct023, cxct021 ' ||
		'WHERE z22_compania  = ' || vg_codcia ||
		'  AND z22_localidad = ' || vg_codloc ||
		'  AND ' || expr_sql CLIPPED ||
		'  AND z23_compania  = z22_compania ' ||
                '  AND z23_localidad = z22_localidad ' ||
                '  AND z23_codcli    = z22_codcli ' ||
                '  AND z23_tipo_trn  = z22_tipo_trn ' ||
                '  AND z23_num_trn   = z22_num_trn ' ||
                '  AND z21_compania  = z23_compania ' ||
                '  AND z21_localidad = z23_localidad ' ||
                '  AND z21_codcli    = z23_codcli ' ||
                '  AND z21_tipo_doc  = z23_tipo_favor ' ||
                '  AND z21_num_doc   = z23_doc_favor ' ||
		' ORDER BY 4,5'
PREPARE cons FROM query	
DECLARE q_cons CURSOR FOR cons
LET vm_num_rows = 1
FOREACH q_cons INTO rm_z22.*, vm_r_rows[vm_num_rows]
	LET vm_num_rows = vm_num_rows + 1
        IF vm_num_rows > vm_max_rows THEN
                EXIT FOREACH
        END IF
END FOREACH
LET vm_num_rows = vm_num_rows - 1
IF vm_num_rows = 0 THEN
	LET int_flag = 0
	CALL fl_mensaje_consulta_sin_registros()
	CLEAR FORM
	CALL muestra_contadores(vm_row_current, vm_num_rows)
	CALL muestra_contadores_det(0)
	CALL mostrar_botones_detalle()
	LET vm_row_current = 0
ELSE  
	LET vm_row_current = 1
	CALL muestra_contadores(vm_row_current, vm_num_rows)
	CALL mostrar_registro(vm_r_rows[vm_row_current])
	CALL muestra_contadores_det(0)
END IF

END FUNCTION



FUNCTION leer_cabecera()
DEFINE resp		CHAR(6)
DEFINE r_cxc_aux	RECORD LIKE cxct022.*
DEFINE r_cxc_aux2	RECORD LIKE cxct021.*
DEFINE r_cli		RECORD LIKE cxct002.*
DEFINE r_cli_gen	RECORD LIKE cxct001.*
DEFINE r_tip		RECORD LIKE cxct004.*
DEFINE r_are		RECORD LIKE gent003.*
DEFINE r_mon		RECORD LIKE gent013.*
DEFINE r_mon_par	RECORD LIKE gent014.*
DEFINE cod_aux		LIKE cxct002.z02_codcli
DEFINE nom_aux		LIKE cxct001.z01_nomcli
DEFINE codt_aux		LIKE cxct004.z04_tipo_doc
DEFINE nomt_aux		LIKE cxct004.z04_nombre
DEFINE coda_aux		LIKE gent003.g03_areaneg
DEFINE noma_aux		LIKE gent003.g03_nombre
DEFINE mone_aux		LIKE gent013.g13_moneda
DEFINE nomm_aux		LIKE gent013.g13_nombre
DEFINE deci_aux		LIKE gent013.g13_decimales
DEFINE r_cxc		RECORD LIKE cxct021.*
DEFINE abrevia		LIKE gent003.g03_abreviacion

INITIALIZE r_cxc_aux.*, r_cli.*, r_cli_gen.*, r_tip.*, r_are.*, r_mon.*,
	r_mon_par.*, cod_aux, codt_aux, coda_aux, mone_aux, r_cxc.* TO NULL
DISPLAY BY NAME	rm_z22.z22_usuario, rm_z22.z22_fecing
LET int_flag = 0
INPUT BY NAME rm_z22.z22_codcli, rm_z22.z22_areaneg, rm_z22.z22_moneda,
	rm_z21.z21_tipo_doc, rm_z21.z21_num_doc, rm_z22.z22_referencia
	WITHOUT DEFAULTS
	ON KEY(INTERRUPT)
	        IF field_touched(rm_z22.z22_codcli, rm_z22.z22_areaneg,
			rm_z22.z22_moneda, rm_z21.z21_tipo_doc,
			rm_z21.z21_num_doc, rm_z22.z22_referencia)
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
		IF INFIELD(z22_codcli) THEN
			CALL fl_ayuda_cliente_localidad(vg_codcia,vg_codloc)
				RETURNING cod_aux, nom_aux
			LET int_flag = 0
			IF cod_aux IS NOT NULL THEN
				LET rm_z22.z22_codcli = cod_aux
				DISPLAY BY NAME rm_z22.z22_codcli 
				DISPLAY nom_aux TO tit_nombre_cli
			END IF 
		END IF
		IF INFIELD(z22_areaneg) THEN
			CALL fl_ayuda_areaneg(vg_codcia)
				RETURNING coda_aux, noma_aux
			LET int_flag = 0
			IF coda_aux IS NOT NULL THEN
				LET rm_z22.z22_areaneg = coda_aux
				DISPLAY BY NAME rm_z22.z22_areaneg
				DISPLAY noma_aux TO tit_area
			END IF 
		END IF
		IF INFIELD(z22_moneda) THEN
			CALL fl_ayuda_monedas()
				RETURNING mone_aux, nomm_aux, deci_aux
			LET int_flag = 0
			IF mone_aux IS NOT NULL THEN
				LET rm_z22.z22_moneda = mone_aux
				DISPLAY BY NAME rm_z22.z22_moneda 
				DISPLAY nomm_aux TO tit_mon_bas
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
		IF INFIELD(z21_num_doc) THEN
			CALL fl_ayuda_doc_favor_cob(vg_codcia, vg_codloc,
					rm_z22.z22_areaneg, rm_z22.z22_codcli,
					rm_z21.z21_tipo_doc)
				RETURNING nom_aux, r_cxc.z21_tipo_doc,
					r_cxc.z21_num_doc, r_cxc.z21_saldo,
					r_cxc.z21_moneda, abrevia
			LET int_flag = 0
			IF r_cxc.z21_num_doc IS NOT NULL THEN
				LET rm_z21.z21_num_doc = r_cxc.z21_num_doc
				LET rm_z21.z21_saldo = r_cxc.z21_saldo
				DISPLAY BY NAME rm_z21.z21_num_doc
				DISPLAY r_cxc.z21_saldo TO z21_saldo
			END IF 
		END IF
	BEFORE INPUT
		--#CALL dialog.keysetlabel("F1","")
		--#CALL dialog.keysetlabel("CONTROL-W","")
	AFTER FIELD z22_codcli
		IF rm_z22.z22_codcli IS NOT NULL THEN
			CALL fl_lee_cliente_general(rm_z22.z22_codcli)
		 		RETURNING r_cli_gen.*
			IF r_cli_gen.z01_codcli IS NULL THEN
				--CALL fgl_winmessage(vg_producto,'Cliente no existe.','exclamation')
				CALL fl_mostrar_mensaje('Cliente no existe.','exclamation')
				NEXT FIELD z22_codcli
			END IF
			DISPLAY r_cli_gen.z01_nomcli TO tit_nombre_cli
			IF r_cli_gen.z01_estado = 'B' THEN
                                CALL fl_mensaje_estado_bloqueado()
                                NEXT FIELD z22_codcli
                        END IF		 
			CALL fl_lee_cliente_localidad(vg_codcia, vg_codloc,
							rm_z22.z22_codcli)
		 		RETURNING r_cli.*
			IF r_cli.z02_compania IS NULL THEN
				--CALL fgl_winmessage(vg_producto,'Cliente no está activado para la compañía.','exclamation')
				CALL fl_mostrar_mensaje('Cliente no está activado para la compañía.','exclamation')
				NEXT FIELD z22_codcli
			END IF
		ELSE
			CLEAR tit_nombre_cli
		END IF
	AFTER FIELD z22_areaneg
		IF rm_z22.z22_areaneg IS NOT NULL THEN
			CALL fl_lee_area_negocio(vg_codcia,rm_z22.z22_areaneg)
				RETURNING r_are.*
			IF r_are.g03_areaneg IS NULL THEN
				--CALL fgl_winmessage(vg_producto,'Area de Negocio no existe.','exclamation')
				CALL fl_mostrar_mensaje('Area de Negocio no existe.','exclamation')
				NEXT FIELD z22_areaneg
			END IF
			DISPLAY r_are.g03_nombre TO tit_area
		ELSE
			CLEAR tit_area
		END IF
	AFTER FIELD z22_moneda 
		IF rm_z22.z22_moneda IS NOT NULL THEN
			CALL fl_lee_moneda(rm_z22.z22_moneda)
				RETURNING r_mon.* 
			IF r_mon.g13_moneda IS NULL  THEN
				--CALL fgl_winmessage(vg_producto,'Moneda no existe.','exclamation')
				CALL fl_mostrar_mensaje('Moneda no existe.','exclamation')
				NEXT FIELD z22_moneda
			END IF
			DISPLAY r_mon.g13_nombre TO tit_mon_bas
			IF r_mon.g13_estado = 'B' THEN
                                CALL fl_mensaje_estado_bloqueado()
				NEXT FIELD z22_moneda
			END IF
			IF rm_z22.z22_moneda = rg_gen.g00_moneda_base THEN
				LET r_mon_par.g14_tasa = 1
			ELSE
				CALL fl_lee_factor_moneda(rm_z22.z22_moneda,
							rg_gen.g00_moneda_base)
					RETURNING r_mon_par.*
				IF r_mon_par.g14_serial IS NULL THEN
					--CALL fgl_winmessage(vg_producto,'La paridad para está moneda no existe.','exclamation')
					CALL fl_mostrar_mensaje('La paridad para está moneda no existe.','exclamation')
					NEXT FIELD z22_moneda
				END IF
			END IF
			LET rm_z22.z22_paridad = r_mon_par.g14_tasa
		ELSE
			LET rm_z22.z22_moneda = rg_gen.g00_moneda_base
			DISPLAY BY NAME rm_z22.z22_moneda
			CALL fl_lee_moneda(rm_z22.z22_moneda) RETURNING r_mon.* 
			DISPLAY r_mon.g13_nombre TO tit_mon_bas
		END IF
	AFTER FIELD z21_tipo_doc 
		IF rm_z21.z21_tipo_doc IS NOT NULL THEN
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
			IF r_tip.z04_estado = 'B' THEN
                                CALL fl_mensaje_estado_bloqueado()
				NEXT FIELD z21_tipo_doc
			END IF
		ELSE
			CLEAR tit_tipo_doc
		END IF
	AFTER INPUT
		CALL fl_lee_transaccion_cxc(vg_codcia, vg_codloc,
				rm_z22.z22_codcli, rm_z21.z21_tipo_doc,
				rm_z21.z21_num_doc)
			RETURNING r_cxc_aux.*
		IF r_cxc_aux.z22_compania IS NOT NULL THEN
			--CALL fgl_winmessage(vg_producto,'Documento ya ha sido ingresado.','exclamation')
			CALL fl_mostrar_mensaje('Documento ya ha sido ingresado.','exclamation')
			NEXT FIELD z22_codcli
		END IF
		CALL fl_lee_documento_favor_cxc(vg_codcia, vg_codloc,
				rm_z22.z22_codcli, rm_z21.z21_tipo_doc,
				rm_z21.z21_num_doc)
			RETURNING r_cxc_aux2.*
		IF r_cxc_aux2.z21_compania IS NULL THEN
			--CALL fgl_winmessage(vg_producto,'Documento no existe.','exclamation')
			CALL fl_mostrar_mensaje('Documento no existe.','exclamation')
			NEXT FIELD z21_tipo_doc
		END IF
		IF r_cxc_aux2.z21_saldo <= 0 THEN
			--CALL fgl_winmessage(vg_producto,'Documento no tiene saldo.','exclamation')
			CALL fl_mostrar_mensaje('Documento no tiene saldo.','exclamation')
			NEXT FIELD z21_tipo_doc
		END IF
		LET rm_z21.z21_saldo = r_cxc_aux2.z21_saldo
		LET vm_saldo          = r_cxc_aux2.z21_saldo
		DISPLAY BY NAME rm_z21.z21_saldo
		IF rm_z22.z22_referencia IS NULL THEN
			--CALL fgl_winmessage(vg_producto,'Dígite la referencia de la aplicación.','exclamation')
			CALL fl_mostrar_mensaje('Dígite la referencia de la aplicación.','exclamation')
			NEXT FIELD z22_referencia
		END IF
END INPUT

END FUNCTION



FUNCTION leer_detalle()
DEFINE check,ordenar	SMALLINT
DEFINE resp             CHAR(6)
DEFINE i,j,l,col,salir	SMALLINT
DEFINE query		CHAR(600)
DEFINE saldo_ant	DECIMAL(12,2)
DEFINE valor_ant	LIKE cxct023.z23_valor_cap
DEFINE valor_aux	LIKE cxct023.z23_valor_cap
DEFINE saldo_aux	LIKE cxct021.z21_saldo

OPTIONS	INSERT KEY F13,
        DELETE KEY F14
LET valor_ant    = 0
LET saldo_ant    = 0
LET rm_orden[1]  = 'ASC'
LET vm_columna_1 = 1
LET vm_columna_2 = 2
LET col          = 1
LET salir        = 0
LET check        = 0
--#CALL fgl_keysetlabel("F5","Chequear")
WHILE NOT salir
	LET query = 'SELECT * FROM tmp_detalle ',
                    'ORDER BY ', vm_columna_1, ' ', rm_orden[vm_columna_1],
                           ', ', vm_columna_2, ' ', rm_orden[vm_columna_2]
        PREPARE deto FROM query
        DECLARE q_deto CURSOR FOR deto
        LET vm_num_elm = 1
        FOREACH q_deto INTO rm_aju[vm_num_elm].*,
				rm_sld[vm_num_elm].z20_fecha_vcto
                LET vm_num_elm = vm_num_elm + 1
                IF vm_num_elm > vm_max_elm THEN
                        EXIT FOREACH
                END IF
        END FOREACH
	LET vm_num_elm = vm_num_elm - 1
	IF vm_num_elm = 0 THEN
		--CALL fgl_winmessage(vg_producto,'El cliente no tiene documentos que ajustar.','exclamation')
		CALL fl_mostrar_mensaje('El cliente no tiene documentos que ajustar.','exclamation')
		EXIT WHILE
	END IF
	CALL set_count(vm_num_elm)
	LET int_flag = 0
	INPUT ARRAY rm_aju WITHOUT DEFAULTS FROM rm_aju.*
		ON KEY(INTERRUPT)
        	       	LET int_flag = 0
               		CALL fl_mensaje_abandonar_proceso()
               			RETURNING resp
	              	IF resp = 'Yes' THEN
				LET vm_total_apl = 0
               			LET int_flag = 1
               			CLEAR FORM
				CALL muestra_contadores_det(0)
				CALL mostrar_botones_detalle()
        	  		RETURN
               		END IF
        	ON KEY(F1,CONTROL-W)
			CALL control_visor_teclas_caracter_1() 
		ON KEY(F5)
			LET ordenar = 1
			CALL chequear_valor_apl(check)
			IF check THEN
				LET check = 0
        			--#CALL fgl_keysetlabel("F5","Chequear")
			ELSE
				LET check = 1
        			--#CALL fgl_keysetlabel("F5","Deschequear")
			END IF
			FOR l = 1 TO vm_num_elm
				DISPLAY BY NAME rm_aju[l].tit_valor_apl,
						rm_aju[l].tit_saldo_nue,
						rm_aju[l].tit_check
			END FOR
			EXIT INPUT
	 	ON KEY(F15)
                        LET col = 1
                        EXIT INPUT
                ON KEY(F16)
                        LET col = 2
                        EXIT INPUT
                ON KEY(F17)
                        LET col = 3
                        EXIT INPUT
                ON KEY(F18)
                        LET col = 4
                        EXIT INPUT
                ON KEY(F19)
                        LET col = 5
                        EXIT INPUT
                ON KEY(F20)
                        LET col = 6
                        EXIT INPUT
                ON KEY(F21)
                        LET col = 7
                        EXIT INPUT
		BEFORE INPUT
			LET ordenar = 0
        		--#CALL dialog.keysetlabel("DELETE","")
                	--#CALL dialog.keysetlabel("INSERT","")
			--#CALL dialog.keysetlabel("F1","")
			--#CALL dialog.keysetlabel("CONTROL-W","")
		BEFORE INSERT
			EXIT INPUT
		BEFORE ROW
        		LET i = arr_curr()
	        	LET j = scr_line()
			DISPLAY rm_sld[i].z20_fecha_vcto TO z20_fecha_vcto
			CALL muestra_contadores_det(i)
			CALL mensaje_fecha(i)
			CALL sacar_total()
		BEFORE FIELD tit_valor_apl
			LET valor_ant = rm_aju[i].tit_valor_apl
			LET saldo_ant = rm_aju[i].tit_saldo_nue
		AFTER FIELD tit_valor_apl
			IF rm_aju[i].tit_valor_apl IS NOT NULL THEN
				IF rm_aju[i].tit_valor_apl <> 0 THEN
					IF rm_aju[i].tit_valor_apl < 0 THEN
						LET valor_aux =
							rm_aju[i].tit_valor_apl
							* (-1)
					ELSE
						LET valor_aux =
							rm_aju[i].tit_valor_apl
							* (-1)
						LET rm_aju[i].tit_valor_apl = 
							valor_aux
					END IF
					DISPLAY rm_aju[i].tit_valor_apl 
						TO rm_aju[j].tit_valor_apl
					IF valor_aux > rm_aju[i].tit_saldo_act
					THEN
						--CALL fgl_winmessage(vg_producto,'El valor a ajustar no puede ser mayor al saldo actual.','exclamation')
						CALL fl_mostrar_mensaje('El valor a ajustar no puede ser mayor al saldo actual.','exclamation')
						NEXT FIELD tit_valor_apl
					END IF
					LET rm_aju[i].tit_saldo_nue =
						rm_aju[i].tit_saldo_act
						+ rm_aju[i].tit_valor_apl
					LET rm_aju[i].tit_check = 'S'
					DISPLAY rm_aju[i].tit_check
						TO rm_aju[j].tit_check
					CALL fl_retorna_precision_valor(
							rm_z22.z22_moneda,
                	       	                    	rm_aju[i].tit_valor_apl)
	       		        	       RETURNING rm_aju[i].tit_valor_apl
					CALL fl_retorna_precision_valor(
							rm_z22.z22_moneda,
                            	                    	rm_aju[i].tit_saldo_nue)
	        	               	       RETURNING rm_aju[i].tit_saldo_nue
	          			DISPLAY rm_aju[i].tit_valor_apl
						TO rm_aju[j].tit_valor_apl
					DISPLAY rm_aju[i].tit_saldo_nue
						TO rm_aju[j].tit_saldo_nue
					CALL sacar_total()
				ELSE
					LET rm_aju[i].tit_check = 'N'
					DISPLAY rm_aju[i].tit_check
						TO rm_aju[j].tit_check
					LET rm_aju[i].tit_saldo_nue = 
						rm_aju[i].tit_saldo_act 
					DISPLAY rm_aju[i].tit_saldo_nue
						TO rm_aju[j].tit_saldo_nue
				END IF
			ELSE
				LET rm_aju[i].tit_valor_apl = valor_ant
				LET rm_aju[i].tit_saldo_nue = saldo_ant
				DISPLAY rm_aju[i].tit_valor_apl
					TO rm_aju[j].tit_valor_apl
				DISPLAY rm_aju[i].tit_saldo_nue
					TO rm_aju[j].tit_saldo_nue
			END IF
		AFTER ROW
			IF rm_aju[i].tit_valor_apl = 0 THEN
				IF rm_aju[i].tit_check = 'S' THEN
					LET rm_aju[i].tit_valor_apl =
						rm_aju[i].tit_saldo_act * (-1)
					LET valor_aux = rm_aju[i].tit_valor_apl
							* (-1)
					CALL fl_retorna_precision_valor(
							rm_z22.z22_moneda,
                                		        rm_aju[i].tit_valor_apl)
          	           	               RETURNING rm_aju[i].tit_valor_apl
					LET rm_aju[i].tit_saldo_nue = 
							rm_aju[i].tit_valor_apl
						       + rm_aju[i].tit_saldo_act
					END IF
			ELSE
				IF rm_aju[i].tit_check = 'N' THEN
					LET rm_aju[i].tit_valor_apl = 0
					LET rm_aju[i].tit_saldo_nue =
						rm_aju[i].tit_saldo_act
				END IF
			END IF
			DISPLAY rm_aju[i].tit_valor_apl
				TO rm_aju[j].tit_valor_apl
			DISPLAY rm_aju[i].tit_saldo_nue
				TO rm_aju[j].tit_saldo_nue
	               	CALL sacar_total()
		AFTER INPUT
                	CALL sacar_total()
			IF vm_total_apl = 0 THEN
				NEXT FIELD tit_valor_apl
			END IF
			LET valor_aux = vm_total_apl * (-1)
			IF valor_aux > vm_saldo THEN
				--CALL fgl_winmessage(vg_producto,'El total del valor a ajustar no puede ser mayor al saldo documento a favor.','exclamation')
				CALL fl_mostrar_mensaje('El total del valor a ajustar no puede ser mayor al saldo documento a favor.','exclamation')
				NEXT FIELD tit_valor_apl
			END IF
			IF rm_z21.z21_saldo > 0 THEN
				LET rm_z21.z21_saldo = rm_z21.z21_saldo
							- valor_aux
			END IF
			LET salir = 1
	END INPUT
	IF int_flag = 1 THEN
                CALL muestra_contadores_det(0)
                RETURN
        END IF
	IF salir THEN
                EXIT WHILE
        END IF
	FOR i = 1 TO vm_num_elm
                UPDATE tmp_detalle SET tit_valor_apl = rm_aju[i].tit_valor_apl,
				       tit_saldo_nue = rm_aju[i].tit_saldo_nue,
				       tit_check     = rm_aju[i].tit_check
                        WHERE z23_tipo_doc = rm_aju[i].z23_tipo_doc
                          AND z23_num_doc  = rm_aju[i].z23_num_doc
                          AND z23_div_doc  = rm_aju[i].z23_div_doc
        END FOR
	IF NOT ordenar THEN
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
       	END IF
END WHILE
LET vm_num_elm = arr_count()

END FUNCTION



FUNCTION sacar_total()
DEFINE i        	SMALLINT

LET vm_total_apl = 0
LET vm_total_act = 0
LET vm_total_nue = 0
FOR i = 1 TO vm_num_elm
        LET vm_total_act = vm_total_act + rm_aju[i].tit_saldo_act
        LET vm_total_apl = vm_total_apl + rm_aju[i].tit_valor_apl
        LET vm_total_nue = vm_total_nue + rm_aju[i].tit_saldo_nue
END FOR
DISPLAY vm_total_act TO tit_total_act
DISPLAY vm_total_apl TO tit_total_apl
DISPLAY vm_total_nue TO tit_total_nue

END FUNCTION



FUNCTION chequear_valor_apl(check)
DEFINE i,check		SMALLINT

FOR i = 1 TO vm_num_elm
	IF NOT check THEN
		IF rm_z21.z21_saldo > 0 THEN
			IF rm_z21.z21_saldo > rm_aju[i].tit_saldo_act THEN
				LET rm_z21.z21_saldo = rm_z21.z21_saldo
						+ rm_aju[i].tit_saldo_act * (-1)
				LET rm_aju[i].tit_valor_apl =
						rm_aju[i].tit_saldo_act * (-1)
			ELSE
				LET rm_aju[i].tit_valor_apl = rm_z21.z21_saldo
								* (-1)
				LET rm_z21.z21_saldo = 0
			END IF
			LET rm_aju[i].tit_saldo_nue = rm_aju[i].tit_valor_apl
						+ rm_aju[i].tit_saldo_act
			LET rm_aju[i].tit_check     = 'S'
		END IF
	ELSE
		LET rm_z21.z21_saldo       = vm_saldo
		LET rm_aju[i].tit_valor_apl = 0
		LET rm_aju[i].tit_saldo_nue = rm_aju[i].tit_saldo_act
		LET rm_aju[i].tit_check     = 'N'
	END IF
END FOR
CALL sacar_total()

END FUNCTION



FUNCTION muestra_siguiente_registro()

IF vm_row_current < vm_num_rows THEN
	LET vm_row_current = vm_row_current + 1
END IF
CALL mostrar_registro(vm_r_rows[vm_row_current])
CALL muestra_contadores(vm_row_current, vm_num_rows)
CALL muestra_contadores_det(0)

END FUNCTION



FUNCTION muestra_anterior_registro()

IF vm_row_current > 1 THEN
	LET vm_row_current = vm_row_current - 1
END IF
CALL mostrar_registro(vm_r_rows[vm_row_current])
CALL muestra_contadores(vm_row_current, vm_num_rows)
CALL muestra_contadores_det(0)

END FUNCTION



FUNCTION muestra_contadores(row_current, num_rows)
DEFINE row_current	SMALLINT
DEFINE num_rows		SMALLINT
                                                                                
IF vg_gui = 1 THEN
	DISPLAY "" AT 1,1
	DISPLAY row_current, " de ", num_rows AT 1, 67
END IF
                                                                                
END FUNCTION



FUNCTION muestra_contadores_det(cor)
DEFINE cor                 SMALLINT

IF vg_gui = 1 THEN
	DISPLAY "" AT 20, 64
	DISPLAY cor, " de ", vm_num_elm AT 20, 64
END IF

END FUNCTION



FUNCTION mostrar_registro(num_registro)
DEFINE num_registro	INTEGER
DEFINE r_cli_gen	RECORD LIKE cxct001.*
DEFINE r_tip		RECORD LIKE cxct004.*
DEFINE r_are		RECORD LIKE gent003.*
DEFINE r_mon		RECORD LIKE gent013.*

IF vm_num_rows > 0 THEN
	DECLARE q_dt CURSOR FOR SELECT cxct022.*, cxct023.*, cxct021.*
		FROM cxct022, cxct023, cxct021
		WHERE cxct022.ROWID = num_registro
                  AND z23_compania  = z22_compania
                  AND z23_localidad = z22_localidad
                  AND z23_codcli    = z22_codcli
                  AND z23_tipo_trn  = z22_tipo_trn
                  AND z23_num_trn   = z22_num_trn
                  AND z21_compania  = z23_compania
                  AND z21_localidad = z23_localidad
                  AND z21_codcli    = z23_codcli
                  AND z21_tipo_doc  = z23_tipo_favor
                  AND z21_num_doc   = z23_doc_favor
        OPEN q_dt
        FETCH q_dt INTO rm_z22.*, rm_z23.*, rm_z21.*
	IF STATUS = NOTFOUND THEN
		--CALL fgl_winmessage (vg_producto,'No existe registro con índice: ' || vm_row_current,'exclamation')
		CALL fl_mostrar_mensaje('No existe registro con índice: ' || vm_row_current,'exclamation')
		RETURN
	END IF
	DISPLAY BY NAME	rm_z22.z22_tipo_trn, rm_z22.z22_num_trn,
			rm_z22.z22_codcli, rm_z22.z22_areaneg,rm_z22.z22_moneda,
			rm_z22.z22_referencia, rm_z21.z21_tipo_doc,
			rm_z21.z21_num_doc, rm_z22.z22_usuario,
			rm_z22.z22_fecing, rm_z21.z21_saldo
	CALL fl_lee_cliente_general(rm_z22.z22_codcli) RETURNING r_cli_gen.*
	DISPLAY r_cli_gen.z01_nomcli TO tit_nombre_cli
	CALL fl_lee_tipo_doc(rm_z21.z21_tipo_doc) RETURNING r_tip.* 
	DISPLAY r_tip.z04_nombre TO tit_tipo_doc
	CALL fl_lee_area_negocio(vg_codcia,rm_z22.z22_areaneg) RETURNING r_are.*
	DISPLAY r_are.g03_nombre TO tit_area
	CALL fl_lee_moneda(rm_z22.z22_moneda) RETURNING r_mon.* 
	DISPLAY r_mon.g13_nombre TO tit_mon_bas
	CALL muestra_detalle(rm_z22.z22_num_trn)
ELSE
	RETURN
END IF
CLOSE q_dt

END FUNCTION



FUNCTION muestra_detalle(num_reg)
DEFINE num_reg		LIKE cxct022.z22_num_trn
DEFINE query            CHAR(800)
DEFINE i                SMALLINT
DEFINE r_cxc		RECORD LIKE cxct023.*

LET int_flag = 0
FOR i = 1 TO fgl_scr_size('rm_aju')
        INITIALIZE rm_aju[i].* TO NULL
        CLEAR rm_aju[i].*
END FOR
LET query = 'SELECT cxct023.*, z20_fecha_vcto FROM cxct023, cxct020 ' ||
                'WHERE z23_compania  = ' || vg_codcia ||
		'  AND z23_localidad = ' || vg_codloc ||
		'  AND z23_codcli    = ' || rm_z22.z22_codcli ||
		'  AND z23_tipo_trn  = ' || '"' || rm_z22.z22_tipo_trn || '"' ||
		'  AND z23_num_trn   = ' || num_reg ||
                '  AND z20_compania  = z23_compania ' ||
		'  AND z20_localidad = z23_localidad ' ||
		'  AND z20_codcli    = z23_codcli ' ||
		'  AND z20_tipo_doc  = z23_tipo_doc ' ||
		'  AND z20_num_doc   = z23_num_doc ' ||
                '  AND z20_dividendo = z23_div_doc ' ||
		' ORDER BY 1,2,3,4,5,6'
PREPARE cons2 FROM query
DECLARE q_cons2 CURSOR FOR cons2
LET i          = 1
LET vm_num_elm = 0
FOREACH q_cons2 INTO r_cxc.*, rm_sld[i].z20_fecha_vcto
	LET rm_aju[i].z23_tipo_doc   = r_cxc.z23_tipo_doc
	LET rm_aju[i].z23_num_doc    = r_cxc.z23_num_doc
	LET rm_aju[i].z23_div_doc    = r_cxc.z23_div_doc
	LET rm_aju[i].tit_saldo_act  = r_cxc.z23_saldo_cap + r_cxc.z23_saldo_int
	LET rm_aju[i].tit_valor_apl  = r_cxc.z23_valor_cap + r_cxc.z23_valor_int
	LET rm_aju[i].tit_saldo_nue  = rm_aju[i].tit_saldo_act
					+ rm_aju[i].tit_valor_apl
	LET rm_aju[i].tit_check      = 'S'
        LET vm_num_elm = vm_num_elm + 1
        LET i = i + 1
        IF vm_num_elm > vm_max_elm THEN
        	LET vm_num_elm = vm_num_elm - 1
		CALL fl_mensaje_arreglo_incompleto()
		EXIT PROGRAM
                --EXIT FOREACH
        END IF
END FOREACH
CLOSE q_cons2
FREE q_cons2
IF vm_num_elm > 0 THEN
        LET int_flag = 0
        FOR i = 1 TO fgl_scr_size('rm_aju')
                DISPLAY rm_aju[i].* TO rm_aju[i].*
        END FOR
END IF
CALL sacar_total()
DELETE FROM tmp_detalle
FOR i = 1 TO vm_num_elm
        INSERT INTO tmp_detalle VALUES(rm_aju[i].*, rm_sld[i])
END FOR
IF int_flag THEN
        INITIALIZE rm_aju[1].* TO NULL
        RETURN
END IF

END FUNCTION



FUNCTION carga_detalle()
DEFINE query            CHAR(800)
DEFINE i                SMALLINT
DEFINE documento        VARCHAR(25)
DEFINE r_cxc		RECORD LIKE cxct020.*
DEFINE r_cxc_aux	RECORD LIKE cxct020.*

LET int_flag = 0
FOR i = 1 TO fgl_scr_size('rm_aju')
        INITIALIZE rm_aju[i].* TO NULL
        CLEAR rm_aju[i].*
END FOR
LET query = 'SELECT * FROM cxct020 ' ||
                'WHERE z20_compania  = ' || vg_codcia ||
		'  AND z20_localidad = ' || vg_codloc ||
		'  AND z20_codcli    = ' || rm_z22.z22_codcli ||
		'  AND z20_moneda    = ' || '"' || rm_z22.z22_moneda || '"' ||
		'  AND z20_saldo_cap + z20_saldo_int > 0 ' ||
		' ORDER BY 1,2,3,5'
PREPARE cons1 FROM query
DECLARE q_cons1 CURSOR FOR cons1
LET i          = 1
LET vm_num_elm = 0
WHENEVER ERROR CONTINUE
FOREACH q_cons1 INTO r_cxc.*
	DECLARE q_proc CURSOR FOR SELECT * FROM cxct020
		WHERE z20_compania  = vg_codcia
		  AND z20_localidad = vg_codloc
		  AND z20_codcli    = r_cxc.z20_codcli
		  AND z20_tipo_doc  = r_cxc.z20_tipo_doc
		  AND z20_num_doc   = r_cxc.z20_num_doc
		  AND z20_dividendo = r_cxc.z20_dividendo
		FOR UPDATE
	OPEN q_proc
	FETCH q_proc INTO r_cxc_aux.*
	IF STATUS < 0 THEN
		ROLLBACK WORK
		LET documento = r_cxc_aux.z20_tipo_doc CLIPPED, '-',
				r_cxc_aux.z20_num_doc CLIPPED, '-',
				r_cxc_aux.z20_dividendo CLIPPED USING '&&'
		--CALL fgl_winmessage(vg_producto,'El documento ' || documento || ' del proveedor está siendo modificado por otro usuario.','exclamation')
		CALL fl_mostrar_mensaje('El documento ' || documento || ' del proveedor está siendo modificado por otro usuario.','exclamation')
		LET vm_num_elm = 0
		WHENEVER ERROR STOP
		RETURN
	END IF
	LET rm_aju[i].z23_tipo_doc   = r_cxc.z20_tipo_doc
	LET rm_aju[i].z23_num_doc    = r_cxc.z20_num_doc
	LET rm_aju[i].z23_div_doc    = r_cxc.z20_dividendo
	LET rm_aju[i].tit_saldo_act  = r_cxc.z20_saldo_cap + r_cxc.z20_saldo_int
	LET rm_aju[i].tit_valor_apl  = 0
	LET rm_aju[i].tit_saldo_nue  = rm_aju[i].tit_saldo_act
	LET rm_aju[i].tit_check      = 'N'
	LET rm_sld[i].z20_fecha_vcto = r_cxc.z20_fecha_vcto
        LET vm_num_elm = vm_num_elm + 1
        LET i = i + 1
        IF vm_num_elm > vm_max_elm THEN
        	LET vm_num_elm = vm_num_elm - 1
		CALL fl_mensaje_arreglo_incompleto()
		EXIT PROGRAM
                --EXIT FOREACH
        END IF
END FOREACH
WHENEVER ERROR STOP
IF vm_num_elm > 0 THEN
        LET int_flag = 0
        FOR i = 1 TO fgl_scr_size('rm_aju')
                DISPLAY rm_aju[i].* TO rm_aju[i].*
        END FOR
END IF
CALL sacar_total()
DELETE FROM tmp_detalle
FOR i = 1 TO vm_num_elm
        INSERT INTO tmp_detalle VALUES(rm_aju[i].*, rm_sld[i])
END FOR
IF int_flag THEN
        INITIALIZE rm_aju[1].* TO NULL
        RETURN
END IF

END FUNCTION



FUNCTION muestra_detalle_arr()
DEFINE i,col		SMALLINT
DEFINE query		CHAR(600)

LET rm_orden[1] = 'ASC'
LET vm_columna_1 = 1
LET vm_columna_2 = 2
LET col          = 1
WHILE TRUE
	LET query = 'SELECT * FROM tmp_detalle ',
                    'ORDER BY ', vm_columna_1, ' ', rm_orden[vm_columna_1],
                           ', ', vm_columna_2, ' ', rm_orden[vm_columna_2]
        PREPARE deto2 FROM query
        DECLARE q_deto2 CURSOR FOR deto2
        LET vm_num_elm = 1
        FOREACH q_deto2 INTO rm_aju[vm_num_elm].*,
				rm_sld[vm_num_elm].z20_fecha_vcto
                LET vm_num_elm = vm_num_elm + 1
                IF vm_num_elm > vm_max_elm THEN
                        EXIT FOREACH
                END IF
        END FOREACH
	LET vm_num_elm = vm_num_elm - 1
	LET int_flag = 0
	CALL set_count(vm_num_elm)
	DISPLAY ARRAY rm_aju TO rm_aju.*
		--#BEFORE ROW
			--#LET i = arr_curr()
			--#DISPLAY rm_sld[i].z20_fecha_vcto TO z20_fecha_vcto
			--#CALL mensaje_fecha(i)
		--#BEFORE DISPLAY
			--#CALL dialog.keysetlabel("ACCEPT","")
			--#CALL dialog.keysetlabel("F1","")
			--#CALL dialog.keysetlabel("CONTROL-W","")
		--#AFTER DISPLAY
			--#CONTINUE DISPLAY
		ON KEY(INTERRUPT)
			CLEAR z20_fecha_vcto, tit_fecha_vcto, tit_dias
			EXIT DISPLAY
        	ON KEY(F1,CONTROL-W)
			CALL llamar_visor_teclas()
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
	END DISPLAY
	IF int_flag = 1 THEN
                CALL muestra_contadores_det(0)
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

END FUNCTION



FUNCTION mostrar_botones_detalle()

--#DISPLAY 'TD'              TO tit_col1
--#DISPLAY 'Documento'       TO tit_col2
--#DISPLAY 'Div'             TO tit_col3
--#DISPLAY 'Saldo Actual'    TO tit_col4
--#DISPLAY 'Valor a Ajustar' TO tit_col5
--#DISPLAY 'Saldo Nuevo'     TO tit_col6
--#DISPLAY 'C'               TO tit_col7

END FUNCTION



FUNCTION mensaje_fecha(i)
DEFINE i,dias		SMALLINT

IF rm_sld[i].z20_fecha_vcto >= TODAY THEN
	DISPLAY 'POR VENCER' TO tit_fecha_vcto
ELSE
	DISPLAY 'VENCIDO' TO tit_fecha_vcto
END IF
LET dias = rm_sld[i].z20_fecha_vcto - TODAY
DISPLAY dias TO tit_dias

END FUNCTION



FUNCTION control_contabilizar()
DEFINE r_z40		RECORD LIKE cxct040.*

INITIALIZE r_z40.* TO NULL
SELECT * INTO r_z40.* FROM cxct040
	WHERE z40_compania  = rm_z22.z22_compania
	  AND z40_localidad = rm_z22.z22_localidad
	  AND z40_codcli    = rm_z22.z22_codcli
	  AND z40_tipo_doc  = rm_z22.z22_tipo_trn
	  AND z40_num_doc   = rm_z22.z22_num_trn
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

{-- ESTO PARA LLAMAR AL PROGRAMA SEGÚN SEA EL AMBIENTE --}
LET run_prog = '; fglrun '
IF vg_gui = 0 THEN
	LET run_prog = '; fglgo '
END IF
{--- ---}
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



FUNCTION control_visor_teclas_caracter_1() 
DEFINE a, fila		INTEGER

CALL fl_visor_teclas_caracter() RETURNING fila
LET a = fila + 2
DISPLAY 'Teclas exclusivas de este proceso:' AT a,2 ATTRIBUTE(REVERSE)	
LET a = a + 1
DISPLAY '<F5>      Chequear/Deschequear'     AT a,2
DISPLAY  'F5' AT a,3 ATTRIBUTE(REVERSE)
LET a = fgl_getkey()
CLOSE WINDOW w_tf

END FUNCTION
