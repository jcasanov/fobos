------------------------------------------------------------------------------
-- Titulo           : cxpp202.4gl - Ajustes de documentos deudores
-- Elaboracion      : 28-nov-2001
-- Autor            : NPC
-- Formato Ejecucion: fglrun cxpp202 base módulo compañía localidad
--			[proveedor tipo-transacción número-transacción]
-- Ultima Correccion: 
-- Motivo Correccion: 
------------------------------------------------------------------------------
GLOBALS '../../../PRODUCCION/LIBRERIAS/fuentes/globales.4gl'

DEFINE rm_cxp		RECORD LIKE cxpt022.*
DEFINE rm_cxp2		RECORD LIKE cxpt023.*
DEFINE rm_cxp3		RECORD LIKE cxpt020.*
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
DEFINE vm_tipo_trn	LIKE cxpt022.p22_tipo_trn
DEFINE vm_r_rows	ARRAY [1000] OF INTEGER
DEFINE rm_aju 		ARRAY [5000] OF RECORD
				p23_tipo_doc	LIKE cxpt023.p23_tipo_doc,
				p23_num_doc	LIKE cxpt023.p23_num_doc,
				p23_div_doc	LIKE cxpt023.p23_div_doc,
				tit_saldo_act	DECIMAL(12,2),
				tit_valor_apl	DECIMAL(12,2),
				tit_saldo_nue	DECIMAL(12,2),
				tit_check	CHAR(1)
			END RECORD
DEFINE rm_sld 		ARRAY [5000] OF RECORD
				p20_fecha_vcto	LIKE cxpt020.p20_fecha_vcto
			END RECORD

MAIN

DEFER QUIT 
DEFER INTERRUPT
CLEAR SCREEN
CALL startlog('../logs/errores')
CALL fgl_init4js()
CALL fl_marca_registrada_producto()
IF num_args() <> 4 AND num_args() <> 7 THEN  -- Validar # parámetros correcto
	CALL fgl_winmessage(vg_producto, 'Número de parámetros incorrecto.', 'stop')
	EXIT PROGRAM
END IF
LET vg_base     = arg_val(1)
LET vg_modulo   = arg_val(2)
LET vg_codcia   = arg_val(3)
LET vg_codloc   = arg_val(4)
LET vg_proceso = 'cxpp202'
CALL fl_activar_base_datos(vg_base)
CALL fl_seteos_defaults()	
CALL fgl_settitle(vg_proceso || ' - ' || vg_producto)
CALL validar_parametros()
CALL fl_cabecera_pantalla(vg_codcia, vg_codloc, vg_modulo, vg_proceso)
CALL control_master()

END MAIN



FUNCTION control_master()
DEFINE indice           SMALLINT

CALL fl_nivel_isolation()
CALL fl_chequeo_mes_proceso_cxp(vg_codcia) RETURNING int_flag 
IF int_flag THEN
	RETURN
END IF
LET vm_max_rows	= 1000
LET vm_max_elm  = 5000
LET vm_tipo_trn = 'AJ'
OPEN WINDOW wf AT 3,2 WITH 22 ROWS, 80 COLUMNS
    ATTRIBUTE(FORM LINE FIRST + 2, COMMENT LINE LAST, MENU LINE FIRST,BORDER,
	      MESSAGE LINE LAST - 2)
OPTIONS INPUT WRAP,
	ACCEPT KEY	F12
OPEN FORM f_cxp FROM "../forms/cxpf202_1"
DISPLAY FORM f_cxp
CALL mostrar_botones_detalle()
INITIALIZE rm_cxp.*, rm_cxp2.*, rm_cxp3.* TO NULL
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
		p23_tipo_doc	CHAR(2),
		p23_num_doc	CHAR(15),
		p23_div_doc	SMALLINT,
		tit_saldo_act	DECIMAL(12,2),
		tit_valor_apl	DECIMAL(12,2),
		tit_saldo_nue	DECIMAL(12,2),
		tit_check	CHAR(1),
		p20_fecha_vcto	DATE
	)
CREATE INDEX tmp_ind1
        ON tmp_detalle(p23_tipo_doc ASC, p23_num_doc ASC, p23_div_doc ASC)
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
		IF num_args() = 7 THEN
			HIDE OPTION 'Ingresar'
			HIDE OPTION 'Consultar'
			CALL control_consulta()
			IF vm_num_rows = 0 THEN
				EXIT PROGRAM
			END IF
                	CALL muestra_detalle_arr()
			EXIT PROGRAM
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
                SHOW OPTION 'Detalle'
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
DEFINE r_cxp            RECORD LIKE cxpt022.*

CALL fl_retorna_usuario()
INITIALIZE rm_cxp.*, rm_cxp2.*, rm_cxp3, r_cxp.*, r_mon.* TO NULL
CLEAR p22_num_trn, tit_nombre_pro, tit_tipo_trn, tit_subtipo, tit_mon_bas,
	p20_fecha_vcto, tit_fecha_vcto, tit_dias, tit_total_apl,
	tit_total_act, tit_total_nue, p22_referencia
FOR i = 1 TO vm_max_elm
	INITIALIZE rm_aju[i].*, rm_sld[i].* TO NULL
END FOR
FOR i = 1 TO fgl_scr_size('rm_aju')
	CLEAR rm_aju[i].*
END FOR
LET rm_cxp.p22_compania   = vg_codcia
LET rm_cxp.p22_localidad  = vg_codloc
LET rm_cxp.p22_fecha_emi  = TODAY
LET rm_cxp.p22_moneda     = rg_gen.g00_moneda_base
LET rm_cxp.p22_paridad    = 1
LET rm_cxp.p22_tasa_mora  = 0
LET rm_cxp.p22_total_cap  = 0
LET rm_cxp.p22_total_int  = 0
LET rm_cxp.p22_total_mora = 0
LET rm_cxp.p22_origen     = 'M'
LET rm_cxp.p22_usuario    = vg_usuario
LET rm_cxp.p22_fecing     = CURRENT

LET rm_cxp2.p23_compania   = vg_codcia
LET rm_cxp2.p23_localidad  = vg_codloc
LET rm_cxp2.p23_valor_mora = 0
LET rm_cxp2.p23_saldo_cap  = 0
LET rm_cxp2.p23_saldo_int  = 0
CALL fl_lee_moneda(rm_cxp.p22_moneda) RETURNING r_mon.*
IF r_mon.g13_moneda IS NULL THEN
        CALL fgl_winmessage(vg_producto,'No existe ninguna moneda base.','stop')
        EXIT PROGRAM
ELSE
        DISPLAY r_mon.g13_nombre TO tit_mon_bas
END IF
CALL leer_cabecera()
IF NOT int_flag THEN
	BEGIN WORK
	CALL carga_detalle()
	IF vm_num_elm = 0 THEN
		ROLLBACK WORK
		RETURN
	END IF
	CALL leer_detalle()
	IF NOT int_flag AND vm_num_elm > 0 THEN
		CALL fl_actualiza_control_secuencias(vg_codcia,vg_codloc,
						vg_modulo,'AA',vm_tipo_trn)
			RETURNING rm_cxp.p22_num_trn
		IF rm_cxp.p22_num_trn <= 0 THEN
			ROLLBACK WORK
			EXIT PROGRAM
		END IF
		IF rm_cxp.p22_num_trn <= 0 THEN
			ROLLBACK WORK
			EXIT PROGRAM
		END IF
		LET rm_cxp.p22_fecing = CURRENT
		INSERT INTO cxpt022 VALUES (rm_cxp.*)
		LET num_aux              = SQLCA.SQLERRD[6] 
		LET rm_cxp2.p23_codprov  = rm_cxp.p22_codprov
		LET rm_cxp2.p23_tipo_trn = rm_cxp.p22_tipo_trn
		LET rm_cxp2.p23_num_trn  = rm_cxp.p22_num_trn
		FOR i = 1 TO vm_num_elm
			IF rm_aju[i].tit_valor_apl = 0 THEN
				CONTINUE FOR
			END IF
			IF rm_aju[i].tit_valor_apl < 0 THEN
				LET valor_aux = rm_aju[i].tit_valor_apl * (-1)
			ELSE
				LET valor_aux = rm_aju[i].tit_valor_apl
			END IF
			WHENEVER ERROR CONTINUE
			DECLARE q_up CURSOR FOR SELECT * FROM cxpt020
		 	    WHERE p20_compania  = vg_codcia
			      AND p20_localidad = vg_codloc
			      AND p20_codprov   = rm_cxp2.p23_codprov
			      AND p20_tipo_doc  = rm_aju[i].p23_tipo_doc
			      AND p20_num_doc   = rm_aju[i].p23_num_doc
			      AND p20_dividendo = rm_aju[i].p23_div_doc
			    FOR UPDATE
			OPEN q_up
			FETCH q_up INTO rm_cxp3.*
			IF STATUS = NOTFOUND THEN
				ROLLBACK WORK
				CALL fgl_winmessage(vg_producto,'Regsitro no encontrado.','stop')
				WHENEVER ERROR STOP
				EXIT PROGRAM
			END IF
			IF STATUS < 0 THEN
				ROLLBACK WORK
				CALL fl_mensaje_bloqueo_otro_usuario()
				WHENEVER ERROR STOP
				EXIT PROGRAM
			END IF
			WHENEVER ERROR STOP
			IF valor_aux >
			rm_cxp3.p20_saldo_cap + rm_cxp3.p20_saldo_int THEN
				ROLLBACK WORK
				CALL fgl_winmessage(vg_producto,'No puede realizar el ajuste de documentos al proveedor en este momento.','stop')
				EXIT PROGRAM
			END IF
			LET rm_cxp2.p23_orden = i
			IF valor_aux <= rm_cxp3.p20_saldo_int THEN
		                LET rm_cxp2.p23_valor_int =
						rm_aju[i].tit_valor_apl
		                LET rm_cxp2.p23_valor_cap = 0
		        ELSE
           		     	LET rm_cxp2.p23_valor_int =
					rm_cxp3.p20_saldo_int
                		IF rm_aju[i].tit_valor_apl < 0 THEN
           		     		LET rm_cxp2.p23_valor_int =
						rm_cxp2.p23_valor_int * (-1)
				END IF
		                LET rm_cxp2.p23_valor_cap =
					rm_cxp3.p20_saldo_int
                			+ rm_aju[i].tit_valor_apl
		        END IF
			LET rm_cxp.p22_total_cap = rm_cxp.p22_total_cap
						+ rm_cxp2.p23_valor_cap
			LET rm_cxp.p22_total_int = rm_cxp.p22_total_int
						+ rm_cxp2.p23_valor_int
			INSERT INTO cxpt023 VALUES(rm_cxp2.p23_compania,
				rm_cxp2.p23_localidad, rm_cxp2.p23_codprov,
				rm_cxp2.p23_tipo_trn, rm_cxp2.p23_num_trn,
				rm_cxp2.p23_orden, rm_aju[i].p23_tipo_doc,
				rm_aju[i].p23_num_doc, rm_aju[i].p23_div_doc,
				NULL, NULL, rm_cxp2.p23_valor_cap,
				rm_cxp2.p23_valor_int, rm_cxp2.p23_valor_mora,
				rm_cxp3.p20_saldo_cap, rm_cxp3.p20_saldo_int)
			UPDATE cxpt020
			       SET p20_saldo_cap = p20_saldo_cap
						+ rm_cxp2.p23_valor_cap,
				   p20_saldo_int = p20_saldo_int
						+ rm_cxp2.p23_valor_int
				WHERE CURRENT OF q_up
			CLOSE q_up
			FREE q_up
		END FOR
		WHENEVER ERROR CONTINUE
		DECLARE q_up2 CURSOR FOR SELECT * FROM cxpt022
		 	    WHERE p22_compania  = vg_codcia
			      AND p22_localidad = vg_codloc
			      AND p22_codprov   = rm_cxp.p22_codprov
			      AND p22_tipo_trn  = rm_cxp.p22_tipo_trn
			      AND p22_num_trn   = rm_cxp.p22_num_trn
		    FOR UPDATE
		OPEN q_up2
		FETCH q_up2 INTO r_cxp.*
		IF STATUS < 0 THEN
			ROLLBACK WORK
			CALL fl_mensaje_bloqueo_otro_usuario()
			WHENEVER ERROR STOP
			EXIT PROGRAM
		END IF
		WHENEVER ERROR STOP
		UPDATE cxpt022 SET p22_total_cap = rm_cxp.p22_total_cap,
				   p22_total_int = rm_cxp.p22_total_int
			WHERE CURRENT OF q_up2
		CLOSE q_up2
		FREE q_up2
		CALL fl_genera_saldos_proveedor(vg_codcia, vg_codloc,
							rm_cxp.p22_codprov)
		COMMIT WORK
		IF vm_num_rows = vm_max_rows THEN
			LET vm_num_rows = 1
		ELSE
			LET vm_num_rows = vm_num_rows + 1
		END IF
		LET vm_row_current = vm_num_rows
		DISPLAY BY NAME rm_cxp.p22_fecing
		LET vm_r_rows[vm_row_current] = num_aux
		CALL muestra_contadores(vm_row_current, vm_num_rows)
		CALL muestra_contadores_det(0)
		CALL mostrar_registro(vm_r_rows[vm_num_rows])	
		CALL fl_mensaje_registro_ingresado()
	ELSE
		ROLLBACK WORK
	END IF
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
DEFINE num_trn		LIKE cxpt022.p22_num_trn
DEFINE codprov		LIKE cxpt002.p02_codprov
DEFINE nomprov		LIKE cxpt001.p01_nomprov
DEFINE codt_aux		LIKE cxpt004.p04_tipo_doc
DEFINE nomt_aux		LIKE cxpt004.p04_nombre
DEFINE codte_aux	LIKE gent012.g12_tiporeg
DEFINE codst_aux	LIKE gent012.g12_subtipo
DEFINE nomte_aux	LIKE gent012.g12_nombre
DEFINE nomst_aux	LIKE gent011.g11_nombre
DEFINE mone_aux		LIKE gent013.g13_moneda
DEFINE nomm_aux		LIKE gent013.g13_nombre
DEFINE deci_aux		LIKE gent013.g13_decimales
DEFINE query		VARCHAR(800)
DEFINE expr_sql		VARCHAR(800)

CLEAR FORM
CALL mostrar_botones_detalle()
INITIALIZE num_trn, codprov, codt_aux, codte_aux, codst_aux, mone_aux TO NULL
LET int_flag = 0
IF num_args() = 4 THEN
	CONSTRUCT BY NAME expr_sql ON p22_tipo_trn, p22_num_trn, p22_subtipo,
	p22_codprov, p22_moneda, p22_referencia
	ON KEY(F2)
		IF infield(p22_tipo_trn) THEN
                	CALL fl_ayuda_tipo_documento_tesoreria('T')
                                RETURNING codt_aux, nomt_aux
                        LET int_flag = 0
                        IF codt_aux IS NOT NULL THEN
                                DISPLAY codt_aux TO p22_tipo_trn
                                DISPLAY nomt_aux TO tit_tipo_trn
                        END IF
                END IF
		IF infield(p22_num_trn) THEN
			CALL fl_ayuda_transaccion_tes(vg_codcia, vg_codloc)
				RETURNING num_trn
                        LET int_flag = 0
                        IF num_trn IS NOT NULL THEN
				DISPLAY num_trn TO p22_num_trn
                	END IF
                END IF
		IF infield(p22_subtipo) THEN
			CALL fl_ayuda_subtipo_entidad(codt_aux)
				RETURNING codte_aux, codst_aux, nomte_aux,
					nomst_aux
			LET int_flag = 0
			IF codte_aux IS NOT NULL THEN
				DISPLAY codst_aux TO p22_subtipo
				DISPLAY nomte_aux TO tit_subtipo
			END IF 
		END IF
		IF infield(p22_codprov) THEN
			CALL fl_ayuda_proveedores_localidad(vg_codcia,vg_codloc)
                                RETURNING codprov, nomprov
                        LET int_flag = 0
                        IF codprov IS NOT NULL THEN
                                DISPLAY codprov TO p22_codprov
                                DISPLAY nomprov TO tit_nombre_pro
                        END IF
                END IF
		IF infield(p22_moneda) THEN
			CALL fl_ayuda_monedas()
				RETURNING mone_aux, nomm_aux, deci_aux
			LET int_flag = 0
			IF mone_aux IS NOT NULL THEN
				DISPLAY mone_aux TO p22_moneda 
				DISPLAY nomm_aux TO tit_mon_bas
			END IF 
		END IF
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
ELSE
	LET expr_sql = ' p22_codprov = ' || arg_val(5) ||
		 ' AND p22_tipo_trn  = ' || '"' || arg_val(6) || '"' ||
		 ' AND p22_num_trn   = ' || arg_val(7)
END IF
LET query = 'SELECT *, ROWID FROM cxpt022 ' ||
		'WHERE p22_compania  = ' || vg_codcia ||
		'  AND p22_localidad = ' || vg_codloc ||
		'  AND ' || expr_sql CLIPPED ||
		' ORDER BY 4,5'
PREPARE cons FROM query	
DECLARE q_cons CURSOR FOR cons
LET vm_num_rows = 1
FOREACH q_cons INTO rm_cxp.*, vm_r_rows[vm_num_rows]
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
DEFINE r_cxp_aux	RECORD LIKE cxpt022.*
DEFINE r_pro		RECORD LIKE cxpt002.*
DEFINE r_pro_gen	RECORD LIKE cxpt001.*
DEFINE r_tip		RECORD LIKE cxpt004.*
DEFINE r_sub		RECORD LIKE gent012.*
DEFINE r_mon		RECORD LIKE gent013.*
DEFINE r_mon_par	RECORD LIKE gent014.*
DEFINE r_cob		RECORD LIKE cxpt005.*
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

INITIALIZE r_cxp_aux.*, r_pro.*, r_pro_gen.*, r_tip.*, r_sub.*, r_mon.*,
	r_mon_par.*, cod_aux, codt_aux, codte_aux, codst_aux, mone_aux TO NULL
DISPLAY BY NAME	rm_cxp.p22_usuario, rm_cxp.p22_fecing
LET int_flag = 0
INPUT BY NAME rm_cxp.p22_tipo_trn, rm_cxp.p22_subtipo, rm_cxp.p22_codprov,
	rm_cxp.p22_moneda, rm_cxp.p22_referencia
	WITHOUT DEFAULTS
	ON KEY(INTERRUPT)
	        IF field_touched(rm_cxp.p22_tipo_trn, rm_cxp.p22_subtipo,
			rm_cxp.p22_codprov, rm_cxp.p22_moneda,
			rm_cxp.p22_referencia)
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
		IF infield(p22_tipo_trn) THEN
			CALL fl_ayuda_tipo_documento_tesoreria('T')
				RETURNING codt_aux, nomt_aux
			LET int_flag = 0
			IF codt_aux IS NOT NULL THEN
				LET rm_cxp.p22_tipo_trn = codt_aux
				DISPLAY BY NAME rm_cxp.p22_tipo_trn
				DISPLAY nomt_aux TO tit_tipo_trn
			END IF 
		END IF
		IF infield(p22_subtipo) THEN
			CALL fl_ayuda_subtipo_entidad(rm_cxp.p22_tipo_trn)
				RETURNING codte_aux, codst_aux, nomte_aux,
					nomst_aux
			LET int_flag = 0
			IF codte_aux IS NOT NULL THEN
				LET rm_cxp.p22_subtipo = codst_aux
				DISPLAY BY NAME rm_cxp.p22_subtipo
				DISPLAY nomte_aux TO tit_subtipo
			END IF 
		END IF
		IF infield(p22_codprov) THEN
			CALL fl_ayuda_proveedores_localidad(vg_codcia,vg_codloc)
				RETURNING cod_aux, nom_aux
			LET int_flag = 0
			IF cod_aux IS NOT NULL THEN
				LET rm_cxp.p22_codprov = cod_aux
				DISPLAY BY NAME rm_cxp.p22_codprov 
				DISPLAY nom_aux TO tit_nombre_pro
			END IF 
		END IF
		IF infield(p22_moneda) THEN
			CALL fl_ayuda_monedas()
				RETURNING mone_aux, nomm_aux, deci_aux
			LET int_flag = 0
			IF mone_aux IS NOT NULL THEN
				LET rm_cxp.p22_moneda = mone_aux
				DISPLAY BY NAME rm_cxp.p22_moneda 
				DISPLAY nomm_aux TO tit_mon_bas
			END IF 
		END IF
	AFTER FIELD p22_tipo_trn 
		IF rm_cxp.p22_tipo_trn IS NOT NULL THEN
			CALL fl_lee_tipo_doc_tesoreria(rm_cxp.p22_tipo_trn)
				RETURNING r_tip.* 
			IF r_tip.p04_tipo_doc IS NULL THEN
				CALL fgl_winmessage(vg_producto,'Tipo de documento no existe.','exclamation')
				NEXT FIELD p22_tipo_trn
			END IF
			DISPLAY r_tip.p04_nombre TO tit_tipo_trn
			IF r_tip.p04_tipo <> 'T' THEN
				CALL fgl_winmessage(vg_producto,'Tipo de documento debe ser una transacción.','exclamation')
				NEXT FIELD p22_tipo_trn
			END IF
			IF r_tip.p04_tipo_doc = 'PG' THEN
				CALL fgl_winmessage(vg_producto,'Los pagos no se ajustan, se los hace en caja.','exclamation')
				NEXT FIELD p22_tipo_trn
			END IF
			IF r_tip.p04_estado = 'B' THEN
                                CALL fl_mensaje_estado_bloqueado()
				NEXT FIELD p22_tipo_trn
			END IF
		ELSE
			CLEAR tit_tipo_trn
		END IF
	AFTER FIELD p22_subtipo
		IF rm_cxp.p22_subtipo IS NOT NULL THEN
			CALL fl_lee_subtipo_entidad(rm_cxp.p22_tipo_trn,
							rm_cxp.p22_subtipo)
				RETURNING r_sub.*
			IF r_sub.g12_tiporeg IS NULL THEN
				CALL fgl_winmessage(vg_producto,'No existe este subtipo de documento.','exclamation')
				NEXT FIELD p22_subtipo
			END IF
			DISPLAY r_sub.g12_nombre TO tit_subtipo
		END IF
	AFTER FIELD p22_codprov
		IF rm_cxp.p22_codprov IS NOT NULL THEN
			CALL fl_lee_proveedor(rm_cxp.p22_codprov)
		 		RETURNING r_pro_gen.*
			IF r_pro_gen.p01_codprov IS NULL THEN
				CALL fgl_winmessage(vg_producto,'Proveedor no existe.','exclamation')
				NEXT FIELD p22_codprov
			END IF
			DISPLAY r_pro_gen.p01_nomprov TO tit_nombre_pro
			IF r_pro_gen.p01_estado = 'B' THEN
                                CALL fl_mensaje_estado_bloqueado()
                                NEXT FIELD p22_codprov
                        END IF		 
			CALL fl_lee_proveedor_localidad(vg_codcia, vg_codloc,
							rm_cxp.p22_codprov)
		 		RETURNING r_pro.*
			IF r_pro.p02_compania IS NULL THEN
				CALL fgl_winmessage(vg_producto,'Proveedor no está activado para la compañía.','exclamation')
				NEXT FIELD p22_codprov
			END IF
		ELSE
			CLEAR tit_nombre_pro
		END IF
	AFTER FIELD p22_moneda 
		IF rm_cxp.p22_moneda IS NOT NULL THEN
			CALL fl_lee_moneda(rm_cxp.p22_moneda)
				RETURNING r_mon.* 
			IF r_mon.g13_moneda IS NULL  THEN
				CALL fgl_winmessage(vg_producto,'Moneda no existe.','exclamation')
				NEXT FIELD p22_moneda
			END IF
			DISPLAY r_mon.g13_nombre TO tit_mon_bas
			IF r_mon.g13_estado = 'B' THEN
                                CALL fl_mensaje_estado_bloqueado()
				NEXT FIELD p22_moneda
			END IF
			IF rm_cxp.p22_moneda = rg_gen.g00_moneda_base THEN
				LET r_mon_par.g14_tasa = 1
			ELSE
				CALL fl_lee_factor_moneda(rm_cxp.p22_moneda,
							rg_gen.g00_moneda_base)
					RETURNING r_mon_par.*
				IF r_mon_par.g14_serial IS NULL THEN
					CALL fgl_winmessage(vg_producto,'La paridad para está moneda no existe.','exclamation')
					NEXT FIELD p22_moneda
				END IF
			END IF
			LET rm_cxp.p22_paridad = r_mon_par.g14_tasa
		ELSE
			LET rm_cxp.p22_moneda = rg_gen.g00_moneda_base
			DISPLAY BY NAME rm_cxp.p22_moneda
			CALL fl_lee_moneda(rm_cxp.p22_moneda) RETURNING r_mon.* 
			DISPLAY r_mon.g13_nombre TO tit_mon_bas
		END IF
	AFTER INPUT
		CALL fl_lee_transaccion_cxp(vg_codcia, vg_codloc,
				rm_cxp.p22_codprov, rm_cxp.p22_tipo_trn,
				rm_cxp.p22_num_trn)
			RETURNING r_cxp_aux.*
		IF r_cxp_aux.p22_compania IS NOT NULL THEN
			CALL fgl_winmessage(vg_producto,'Documento ya ha sido ingresado.','exclamation')
			NEXT FIELD rm_cxp.p22_codprov
		END IF
		IF rm_cxp.p22_referencia IS NULL THEN
			CALL fgl_winmessage(vg_producto,'Dígite la referencia del ajuste.','exclamation')
			NEXT FIELD rm_cxp.p22_referencia
		END IF
END INPUT

END FUNCTION



FUNCTION leer_detalle()
DEFINE ordenar,check	SMALLINT
DEFINE resp             CHAR(6)
DEFINE i,j,l,col,salir	SMALLINT
DEFINE query		VARCHAR(600)
DEFINE saldo_ant	DECIMAL(12,2)
DEFINE valor_ant	LIKE cxpt023.p23_valor_cap
DEFINE valor_aux	LIKE cxpt023.p23_valor_cap

OPTIONS	INSERT KEY F13,
        DELETE KEY F14
LET rm_orden[1] = 'ASC'
LET vm_columna_1 = 1
LET vm_columna_2 = 2
LET col          = 1
LET salir        = 0
LET check        = 0
CALL fgl_keysetlabel("F5","Chequear")
WHILE NOT salir
	LET query = 'SELECT * FROM tmp_detalle ',
                    'ORDER BY ', vm_columna_1, ' ', rm_orden[vm_columna_1],
                           ', ', vm_columna_2, ' ', rm_orden[vm_columna_2]
        PREPARE deto FROM query
        DECLARE q_deto CURSOR FOR deto
        LET vm_num_elm = 1
        FOREACH q_deto INTO rm_aju[vm_num_elm].*,
				rm_sld[vm_num_elm].p20_fecha_vcto
                LET vm_num_elm = vm_num_elm + 1
                IF vm_num_elm > vm_max_elm THEN
                        EXIT FOREACH
                END IF
        END FOREACH
	LET vm_num_elm = vm_num_elm - 1
	IF vm_num_elm = 0 THEN
		CALL fgl_winmessage(vg_producto,'El proveedor no tiene documentos que ajustar.','exclamation')
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
		ON KEY(F5)
			LET ordenar = 1
			CALL chequear_valor_apl(check)
			IF check THEN
				LET check = 0
                                CALL fgl_keysetlabel("F5","Chequear")
			ELSE
				LET check = 1
                                CALL fgl_keysetlabel("F5","Deschequear")
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
        		CALL dialog.keysetlabel("DELETE","")
                	CALL dialog.keysetlabel("INSERT","")
		BEFORE INSERT
			EXIT INPUT
		BEFORE ROW
        		LET i = arr_curr()
	        	LET j = scr_line()
			DISPLAY rm_sld[i].p20_fecha_vcto TO p20_fecha_vcto
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
					END IF
					IF valor_aux > rm_aju[i].tit_saldo_act
					THEN
						CALL fgl_winmessage(vg_producto,'El valor a ajustar no puede ser mayor al saldo actual.','exclamation')
						NEXT FIELD tit_valor_apl
					END IF
					LET rm_aju[i].tit_saldo_nue =
						rm_aju[i].tit_saldo_act
						+ rm_aju[i].tit_valor_apl
					LET rm_aju[i].tit_check = 'S'
					DISPLAY rm_aju[i].tit_check
						TO rm_aju[j].tit_check
					CALL fl_retorna_precision_valor(
							rm_cxp.p22_moneda,
                	       	                    	rm_aju[i].tit_valor_apl)
	       		        	       RETURNING rm_aju[i].tit_valor_apl
					CALL fl_retorna_precision_valor(
							rm_cxp.p22_moneda,
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
					CALL fl_retorna_precision_valor(
							rm_cxp.p22_moneda,
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
                        WHERE p23_tipo_doc = rm_aju[i].p23_tipo_doc
                          AND p23_num_doc  = rm_aju[i].p23_num_doc
                          AND p23_div_doc  = rm_aju[i].p23_div_doc
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
		LET rm_aju[i].tit_valor_apl = rm_aju[i].tit_saldo_act * (-1)
		LET rm_aju[i].tit_saldo_nue = rm_aju[i].tit_valor_apl
					+ rm_aju[i].tit_saldo_act
		LET rm_aju[i].tit_check     = 'S'
	ELSE
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
                                                                                
DISPLAY "" AT 1,1
DISPLAY row_current, " de ", num_rows AT 1, 68
                                                                                
END FUNCTION



FUNCTION muestra_contadores_det(cor)
DEFINE cor                 SMALLINT

DISPLAY "" AT 21, 64
DISPLAY cor, " de ", vm_num_elm AT 21, 64

END FUNCTION



FUNCTION mostrar_registro(num_registro)
DEFINE num_registro	INTEGER
DEFINE r_pro_gen	RECORD LIKE cxpt001.*
DEFINE r_tip		RECORD LIKE cxpt004.*
DEFINE r_sub		RECORD LIKE gent012.*
DEFINE r_mon		RECORD LIKE gent013.*

IF vm_num_rows > 0 THEN
	DECLARE q_dt CURSOR FOR SELECT * FROM cxpt022 WHERE ROWID = num_registro
        OPEN q_dt
        FETCH q_dt INTO rm_cxp.*
	IF STATUS = NOTFOUND THEN
		CALL fgl_winmessage(vg_producto,'No existe registro con índice: ' || vm_row_current,'exclamation')
		RETURN
	END IF
	DISPLAY BY NAME	rm_cxp.p22_num_trn, rm_cxp.p22_codprov,
			rm_cxp.p22_tipo_trn, rm_cxp.p22_subtipo,
			rm_cxp.p22_moneda, rm_cxp.p22_referencia,
			rm_cxp.p22_usuario, rm_cxp.p22_fecing
	CALL fl_lee_proveedor(rm_cxp.p22_codprov) RETURNING r_pro_gen.*
	DISPLAY r_pro_gen.p01_nomprov TO tit_nombre_pro
	CALL fl_lee_tipo_doc_tesoreria(rm_cxp.p22_tipo_trn) RETURNING r_tip.* 
	DISPLAY r_tip.p04_nombre TO tit_tipo_trn
	CALL fl_lee_subtipo_entidad(rm_cxp.p22_tipo_trn,rm_cxp.p22_subtipo)
		RETURNING r_sub.*
	DISPLAY r_sub.g12_nombre TO tit_subtipo
	CALL fl_lee_moneda(rm_cxp.p22_moneda) RETURNING r_mon.* 
	DISPLAY r_mon.g13_nombre TO tit_mon_bas
	CALL muestra_detalle(rm_cxp.p22_num_trn)
ELSE
	RETURN
END IF
CLOSE q_dt

END FUNCTION



FUNCTION muestra_detalle(num_reg)
DEFINE num_reg		LIKE cxpt022.p22_num_trn
DEFINE query            VARCHAR(800)
DEFINE i                SMALLINT
DEFINE r_cxp		RECORD LIKE cxpt023.*

LET int_flag = 0
FOR i = 1 TO fgl_scr_size('rm_aju')
        INITIALIZE rm_aju[i].* TO NULL
        CLEAR rm_aju[i].*
END FOR
LET query = 'SELECT cxpt023.*, p20_fecha_vcto FROM cxpt023, cxpt020 ' ||
                'WHERE p23_compania  = ' || vg_codcia ||
		'  AND p23_localidad = ' || vg_codloc ||
		'  AND p23_codprov    = ' || rm_cxp.p22_codprov ||
		'  AND p23_tipo_trn  = ' || '"' || rm_cxp.p22_tipo_trn || '"' ||
		'  AND p23_num_trn   = ' || num_reg ||
                '  AND p20_compania  = p23_compania ' ||
		'  AND p20_localidad = p23_localidad ' ||
		'  AND p20_codprov   = p23_codprov ' ||
		'  AND p20_tipo_doc  = p23_tipo_doc ' ||
		'  AND p20_num_doc   = p23_num_doc ' ||
                '  AND p20_dividendo = p23_div_doc ' ||
		' ORDER BY 1,2,3,4,5,6'
PREPARE cons2 FROM query
DECLARE q_cons2 CURSOR FOR cons2
LET i          = 1
LET vm_num_elm = 0
FOREACH q_cons2 INTO r_cxp.*, rm_sld[i].p20_fecha_vcto
	LET rm_aju[i].p23_tipo_doc   = r_cxp.p23_tipo_doc
	LET rm_aju[i].p23_num_doc    = r_cxp.p23_num_doc
	LET rm_aju[i].p23_div_doc    = r_cxp.p23_div_doc
	LET rm_aju[i].tit_saldo_act  = r_cxp.p23_saldo_cap + r_cxp.p23_saldo_int
	LET rm_aju[i].tit_valor_apl  = r_cxp.p23_valor_cap + r_cxp.p23_valor_int
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
DEFINE query            VARCHAR(800)
DEFINE i                SMALLINT
DEFINE documento        VARCHAR(25)
DEFINE r_cxp		RECORD LIKE cxpt020.*
DEFINE r_cxp_aux	RECORD LIKE cxpt020.*

LET int_flag = 0
FOR i = 1 TO fgl_scr_size('rm_aju')
        INITIALIZE rm_aju[i].* TO NULL
        CLEAR rm_aju[i].*
END FOR
LET query = 'SELECT * FROM cxpt020 ' ||
                'WHERE p20_compania  = ' || vg_codcia ||
		'  AND p20_localidad = ' || vg_codloc ||
		'  AND p20_codprov   = ' || rm_cxp.p22_codprov ||
		'  AND p20_moneda    = ' || '"' || rm_cxp.p22_moneda || '"' ||
		'  AND p20_saldo_cap + p20_saldo_int > 0 ' ||
		' ORDER BY 1,2,3,5'
PREPARE cons1 FROM query
DECLARE q_cons1 CURSOR FOR cons1
LET i          = 1
LET vm_num_elm = 0
WHENEVER ERROR CONTINUE
FOREACH q_cons1 INTO r_cxp.*
	DECLARE q_proc CURSOR FOR SELECT * FROM cxpt020
		WHERE p20_compania  = vg_codcia
		  AND p20_localidad = vg_codloc
		  AND p20_codprov   = r_cxp.p20_codprov
		  AND p20_tipo_doc  = r_cxp.p20_tipo_doc
		  AND p20_num_doc   = r_cxp.p20_num_doc
		  AND p20_dividendo = r_cxp.p20_dividendo
		FOR UPDATE
	OPEN q_proc
	FETCH q_proc INTO r_cxp_aux.*
	IF STATUS < 0 THEN
		ROLLBACK WORK
		LET documento = r_cxp_aux.p20_tipo_doc CLIPPED, '-',
				r_cxp_aux.p20_num_doc CLIPPED, '-',
				r_cxp_aux.p20_dividendo CLIPPED USING '&&'
		CALL fgl_winmessage(vg_producto,'El documento ' || documento || ' del proveedor está siendo modificado por otro usuario.','exclamation')
		LET vm_num_elm = 0
		WHENEVER ERROR STOP
		RETURN
	END IF
	LET rm_aju[i].p23_tipo_doc   = r_cxp.p20_tipo_doc
	LET rm_aju[i].p23_num_doc    = r_cxp.p20_num_doc
	LET rm_aju[i].p23_div_doc    = r_cxp.p20_dividendo
	LET rm_aju[i].tit_saldo_act  = r_cxp.p20_saldo_cap + r_cxp.p20_saldo_int
	LET rm_aju[i].tit_valor_apl  = 0
	LET rm_aju[i].tit_saldo_nue  = rm_aju[i].tit_saldo_act
	LET rm_aju[i].tit_check      = 'N'
	LET rm_sld[i].p20_fecha_vcto = r_cxp.p20_fecha_vcto
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
DEFINE query		VARCHAR(600)

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
				rm_sld[vm_num_elm].p20_fecha_vcto
                LET vm_num_elm = vm_num_elm + 1
                IF vm_num_elm > vm_max_elm THEN
                        EXIT FOREACH
                END IF
        END FOREACH
	LET vm_num_elm = vm_num_elm - 1
	LET int_flag = 0
	CALL set_count(vm_num_elm)
	DISPLAY ARRAY rm_aju TO rm_aju.*
		BEFORE ROW
			LET i = arr_curr()
			DISPLAY rm_sld[i].p20_fecha_vcto TO p20_fecha_vcto
			CALL mensaje_fecha(i)
		BEFORE DISPLAY
			CALL dialog.keysetlabel("ACCEPT","")
		AFTER DISPLAY
			CONTINUE DISPLAY
		ON KEY(INTERRUPT)
			CLEAR p20_fecha_vcto, tit_fecha_vcto, tit_dias
			EXIT DISPLAY
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

DISPLAY 'TD'              TO tit_col1
DISPLAY 'Documento'       TO tit_col2
DISPLAY 'Div'             TO tit_col3
DISPLAY 'Saldo Actual'    TO tit_col4
DISPLAY 'Valor a Ajustar' TO tit_col5
DISPLAY 'Saldo Nuevo'     TO tit_col6
DISPLAY 'C'               TO tit_col7

END FUNCTION



FUNCTION mensaje_fecha(i)
DEFINE i,dias		SMALLINT

IF rm_sld[i].p20_fecha_vcto >= TODAY THEN
	DISPLAY 'POR VENCER' TO tit_fecha_vcto
ELSE
	DISPLAY 'VENCIDO' TO tit_fecha_vcto
END IF
LET dias = rm_sld[i].p20_fecha_vcto - TODAY
DISPLAY dias TO tit_dias

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
