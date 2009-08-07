------------------------------------------------------------------------------
-- Titulo           : cxpp207.4gl - Ingreso comprobantes de retención
-- Elaboracion      : 17-dic-2001
-- Autor            : NPC
-- Formato Ejecucion: fglrun cxpp207 base módulo compañía localidad
-- Ultima Correccion: 
-- Motivo Correccion: 
------------------------------------------------------------------------------
GLOBALS '../../../PRODUCCION/LIBRERIAS/fuentes/globales.4gl'

DEFINE rm_cxp		RECORD LIKE cxpt027.*
DEFINE vm_max_det       SMALLINT
DEFINE vm_num_det       SMALLINT
DEFINE vm_scr_lin       SMALLINT
DEFINE vm_total         DECIMAL(12,2)
DEFINE rm_orden 	ARRAY[10] OF CHAR(4)
DEFINE vm_columna_1	SMALLINT
DEFINE vm_columna_2	SMALLINT
DEFINE vm_num_ret	LIKE cxpt027.p27_num_ret
DEFINE rm_det		ARRAY [1000] OF RECORD
				p20_tipo_doc	LIKE cxpt020.p20_tipo_doc,
				p20_num_doc	LIKE cxpt020.p20_num_doc,
				p20_fecha_emi	LIKE cxpt020.p20_fecha_emi,
				p20_valor_fact	LIKE cxpt020.p20_valor_fact,
				tit_valor_ret	DECIMAL(12,2)
			END RECORD
DEFINE rm_refer		ARRAY [1000] OF LIKE cxpt020.p20_referencia

DEFINE vm_retencion	CHAR(2)
DEFINE ind_max_ret	SMALLINT
DEFINE ind_ret		SMALLINT
DEFINE filas_pant	SMALLINT
DEFINE r_ret 		ARRAY[50] OF RECORD
				check		CHAR(1),
				n_retencion	LIKE ordt002.c02_nombre,
			    codigo_sri	LIKE cxpt005.p05_codigo_sri,
				tipo_ret	LIKE cxpt005.p05_tipo_ret, 
				val_base	LIKE rept019.r19_tot_bruto, 
				porc		LIKE cxpt005.p05_porcentaje, 
				subtotal 	LIKE rept019.r19_tot_neto
			END RECORD
DEFINE r_ret_aux	ARRAY[50] OF RECORD
				check		CHAR(1),
				n_retencion	LIKE ordt002.c02_nombre,
			    codigo_sri	LIKE cxpt005.p05_codigo_sri,
				tipo_ret	LIKE cxpt005.p05_tipo_ret, 
				val_base	LIKE rept019.r19_tot_bruto, 
				porc		LIKE cxpt005.p05_porcentaje, 
				subtotal 	LIKE rept019.r19_tot_neto
			END RECORD
DEFINE iva_bien		DECIMAL(11,2)
DEFINE iva_servi	DECIMAL(11,2)
DEFINE val_bienes	LIKE rept019.r19_tot_bruto
DEFINE val_servi	LIKE rept019.r19_tot_bruto
DEFINE val_impto	LIKE rept019.r19_tot_dscto
DEFINE val_neto		LIKE rept019.r19_tot_neto
DEFINE tot_ret		LIKE rept019.r19_tot_neto
------------------------------------------------------
---- DEFINICION DE LOS CAMPOS DE LA VENTANA DE FORMA DE PAGO ----

DEFINE vm_filas_pant		SMALLINT

DEFINE tot_dias			SMALLINT	
DEFINE pagos			SMALLINT
DEFINE fecha_pago		DATE
DEFINE dias_pagos		SMALLINT
DEFINE c10_interes		LIKE ordt010.c10_interes
DEFINE tot_compra		LIKE ordt010.c10_tot_compra
DEFINE tot_cap			LIKE ordt010.c10_tot_compra
DEFINE tot_int			LIKE ordt010.c10_tot_compra
DEFINE tot_sub			LIKE ordt010.c10_tot_compra
---------------------------------------------------------------

MAIN

DEFER QUIT 
DEFER INTERRUPT
CLEAR SCREEN
CALL startlog('../logs/cxpp207.error')
CALL fgl_init4js()
CALL fl_marca_registrada_producto()
IF num_args() <> 4 THEN   -- Validar # parámetros correcto
	CALL fgl_winmessage(vg_producto, 'Número de parámetros incorrecto', 'stop')
	EXIT PROGRAM
END IF
LET vg_base     = arg_val(1)
LET vg_modulo   = arg_val(2)
LET vg_codcia   = arg_val(3)
LET vg_codloc   = arg_val(4)
LET vg_proceso = 'cxpp207'
CALL fl_activar_base_datos(vg_base)
CALL fl_seteos_defaults()	
CALL fgl_settitle(vg_proceso || ' - ' || vg_producto)
CALL validar_parametros()
CALL fl_cabecera_pantalla(vg_codcia, vg_codloc, vg_modulo, vg_proceso)
CALL funcion_master()

END MAIN



FUNCTION funcion_master()

CALL fl_nivel_isolation()
CALL fl_chequeo_mes_proceso_cxp(vg_codcia) RETURNING int_flag 
IF int_flag THEN
	RETURN
END IF
LET vm_max_det   = 1000
LET vm_retencion = 'RT'
LET ind_max_ret	 = 50
OPEN WINDOW w_mas AT 3,2 WITH 22 ROWS, 80 COLUMNS
    ATTRIBUTE(FORM LINE FIRST, COMMENT LINE LAST, MENU LINE 0, BORDER,
	      MESSAGE LINE LAST - 2)
OPTIONS INPUT WRAP,
	ACCEPT KEY	F12
OPEN FORM f_cxp FROM "../forms/cxpf207_1"
DISPLAY FORM f_cxp
CREATE TEMP TABLE tmp_detalle_ret(
		p20_tipo_doc	CHAR(2)		NOT NULL,
		p20_num_doc	CHAR(15)	NOT NULL,
		p20_fecha_emi	DATE,
		p20_valor_fact	DECIMAL(12,2),
		tit_valor_ret	DECIMAL(12,2),
		p20_referencia	VARCHAR(30,20)
	)
CREATE UNIQUE INDEX tmp_pk1
	ON tmp_detalle_ret(p20_tipo_doc, p20_num_doc)
CREATE TEMP TABLE tmp_retenciones(
		tipo_doc	CHAR(2)      NOT NULL,
		num_doc		CHAR(15)     NOT NULL,
		codigo_sri	CHAR(3)		 NOT NULL,
		tipo_ret	CHAR(1)      NOT NULL,
		porc		DECIMAL(5,2) NOT NULL,
		val_base	DECIMAL(12,2),
		subtotal 	DECIMAL(12,2)
	)
CREATE UNIQUE INDEX tmp_pk2
	ON tmp_retenciones(tipo_doc, num_doc, codigo_sri, tipo_ret, porc)
LET vm_scr_lin = 0
CALL muestra_contadores_det(0)
CALL borrar_cabecera()
CALL borrar_detalle()
CALL mostrar_cabecera_forma()
CALL control_consulta()

END FUNCTION



FUNCTION control_consulta()
DEFINE i,j,k,col,done	SMALLINT
DEFINE query		VARCHAR(1000)
DEFINE expr_sql         VARCHAR(600)
DEFINE r_mon		RECORD LIKE gent013.*
DEFINE r_cxp_aux	RECORD LIKE cxpt020.*
DEFINE l,retenciones	SMALLINT
DEFINE valor_ret	DECIMAL(12,2)
DEFINE r_p27		RECORD LIKE cxpt027.*

LET rm_cxp.p27_estado  = 'A'
LET rm_cxp.p27_paridad = 1
LET rm_cxp.p27_usuario = vg_usuario
LET rm_cxp.p27_fecing  = CURRENT
LET rm_cxp.p27_moneda  = rg_gen.g00_moneda_base
CALL fl_lee_moneda(rm_cxp.p27_moneda) RETURNING r_mon.*
IF r_mon.g13_moneda IS NULL THEN
       	CALL fgl_winmessage(vg_producto,'Moneda no existe moneda base.','stop')
        EXIT PROGRAM
END IF
CALL muestra_estado()
DISPLAY r_mon.g13_nombre TO tit_moneda
DISPLAY BY NAME rm_cxp.p27_paridad, rm_cxp.p27_usuario, rm_cxp.p27_fecing
WHILE TRUE
	LET vm_num_det = 0
	CLEAR p20_referencia
	CALL borrar_detalle()
	CALL muestra_contadores_det(0)
	CALL lee_parametros()
	IF int_flag THEN
		EXIT WHILE
	END IF
	DELETE FROM tmp_detalle_ret
	INSERT INTO tmp_detalle_ret
		SELECT p20_tipo_doc, p20_num_doc, MIN(p20_fecha_emi),
			p20_valor_fact, 0, p20_referencia
			FROM cxpt020
			WHERE p20_compania  = vg_codcia
			  AND p20_localidad = vg_codloc
			  AND p20_codprov   = rm_cxp.p27_codprov
			  AND p20_dividendo = 1
			  AND p20_moneda    = rm_cxp.p27_moneda
			GROUP BY 1, 2, 4, 5, 6
			HAVING SUM(p20_saldo_cap + p20_saldo_int) > 0
	SELECT COUNT(*) INTO vm_num_det FROM tmp_detalle_ret
	IF vm_num_det = 0 THEN
		CALL fl_mensaje_consulta_sin_registros()
		CONTINUE WHILE
	END IF
	FOR i = 1 TO 10
		LET rm_orden[i] = '' 
	END FOR
	LET rm_orden[1]  = 'ASC'
	LET vm_columna_1 = 3
	LET vm_columna_2 = 4
	LET col          = 3
	WHILE TRUE
		LET query = 'SELECT * FROM tmp_detalle_ret ',
				" ORDER BY ", vm_columna_1, ' ',
					rm_orden[vm_columna_1],
			    		', ', vm_columna_2, ' ',
					rm_orden[vm_columna_2]
		PREPARE deto FROM query
		DECLARE q_deto CURSOR FOR deto
		LET k = 1
		FOREACH q_deto INTO rm_det[k].*, rm_refer[k]
			LET k = k + 1
			IF k > vm_max_det THEN
				EXIT FOREACH
			END IF
		END FOREACH
		LET k = k - 1
		CALL sacar_total()
		CALL set_count(k)
		LET int_flag = 0
		DISPLAY ARRAY rm_det TO rm_det.*
			BEFORE DISPLAY
				CALL dialog.keysetlabel('ACCEPT','')
			BEFORE ROW
				LET i = arr_curr()
				LET j = scr_line()
				LET rm_cxp.p27_fecing  = CURRENT
				CALL muestra_contadores_det(i)
				DISPLAY rm_refer[i] TO p20_referencia
				DISPLAY BY NAME rm_cxp.p27_fecing
				CALL sacar_total()
			AFTER DISPLAY 
				CONTINUE DISPLAY
			ON KEY(INTERRUPT)
				LET int_flag = 1
				EXIT DISPLAY
			ON KEY(F5)
				CALL cuantas_retenciones(i) RETURNING l
				IF l > 0 THEN
					CALL fgl_winmessage(vg_producto,'Comprobante ya tiene retención.','exclamation')
					CONTINUE DISPLAY
				END IF
				LET tot_ret = 0
				SELECT COUNT(*) INTO ind_ret
					FROM tmp_retenciones
					WHERE tipo_doc = rm_det[i].p20_tipo_doc
					  AND num_doc  = rm_det[i].p20_num_doc
				IF ind_ret = 0 THEN
					CALL fl_lee_documento_deudor_cxp(
							vg_codcia, vg_codloc,
							rm_cxp.p27_codprov,
							rm_det[i].p20_tipo_doc,
							rm_det[i].p20_num_doc,1)
						RETURNING r_cxp_aux.*
					CALL retenciones(r_cxp_aux.*)
				END IF
				CALL carga_retenciones(i)
				CALL muestra_retenciones(i)
				IF int_flag THEN
					LET int_flag = 0
					CONTINUE DISPLAY
				END IF
				LET rm_det[i].tit_valor_ret = tot_ret
				DISPLAY rm_det[i].tit_valor_ret
					TO rm_det[j].tit_valor_ret
				UPDATE tmp_detalle_ret
					SET tit_valor_ret =
							rm_det[i].tit_valor_ret 
					WHERE p20_tipo_doc =
							rm_det[i].p20_tipo_doc 
					  AND p20_num_doc  =
							rm_det[i].p20_num_doc 
				LET int_flag = 0
			ON KEY(F6)
				CALL cuantas_retenciones(i) RETURNING l
				IF l > 0 THEN
					CALL fgl_winmessage(vg_producto,'Comprobante ya tiene retención.','exclamation')
					CONTINUE DISPLAY
				END IF
				SELECT SUM(tit_valor_ret) INTO valor_ret 
					FROM tmp_detalle_ret
				SELECT COUNT(*) INTO ind_ret
					FROM tmp_retenciones
					WHERE tipo_doc = rm_det[i].p20_tipo_doc
					  AND num_doc  = rm_det[i].p20_num_doc
				IF valor_ret = 0 OR ind_ret = 0 THEN
					CALL fgl_winmessage(vg_producto,'No ha hecho retenciones en nigún comprobante.','exclamation')
					CONTINUE DISPLAY
				END IF
				BEGIN WORK
					LET done = graba_retenciones(i)
					IF done THEN
						CALL graba_ajuste_retencion(i)
					ELSE
						ROLLBACK WORK
						CONTINUE DISPLAY
					END IF
					DELETE FROM tmp_retenciones
				COMMIT WORK
				CALL fl_lee_retencion_cxp(vg_codcia, vg_codloc,
					vm_num_ret) RETURNING r_p27.*
				CALL imprime_retenciones(r_p27.*)
				CALL fl_mensaje_registro_ingresado()
				LET int_flag = 0
			ON KEY(F7)
				CALL ver_estado_cuenta(i)
				LET int_flag = 0
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
		END DISPLAY
		IF int_flag = 1 THEN
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
END WHILE

END FUNCTION



FUNCTION lee_parametros()
DEFINE r_mon		RECORD LIKE gent013.*
DEFINE r_mon_par	RECORD LIKE gent014.*
DEFINE r_pro		RECORD LIKE cxpt001.*
DEFINE mone_aux         LIKE gent013.g13_moneda
DEFINE nomm_aux         LIKE gent013.g13_nombre
DEFINE deci_aux         LIKE gent013.g13_decimales
DEFINE codprov		LIKE cxpt027.p27_codprov
DEFINE nomprov		LIKE cxpt001.p01_nomprov

INITIALIZE mone_aux, codprov TO NULL
LET int_flag = 0
INPUT BY NAME rm_cxp.p27_codprov, rm_cxp.p27_moneda
	WITHOUT DEFAULTS
	ON KEY(INTERRUPT)
		LET int_flag = 1
		RETURN
	ON KEY(F2)
		IF INFIELD(p27_codprov) THEN
                     	CALL fl_ayuda_proveedores()
				RETURNING codprov, nomprov
                       	IF codprov IS NOT NULL THEN
                             	LET rm_cxp.p27_codprov = codprov
                               	DISPLAY BY NAME rm_cxp.p27_codprov
                               	DISPLAY nomprov TO tit_nombre_pro
                        END IF
                END IF
		IF INFIELD(p27_moneda) THEN
               		CALL fl_ayuda_monedas()
                       		RETURNING mone_aux, nomm_aux, deci_aux
       		      	LET int_flag = 0
                      	IF mone_aux IS NOT NULL THEN
                              	LET rm_cxp.p27_moneda = mone_aux
                               	DISPLAY BY NAME rm_cxp.p27_moneda
                               	DISPLAY nomm_aux TO tit_moneda
                       	END IF
                END IF
	AFTER FIELD p27_moneda
               	IF rm_cxp.p27_moneda IS NOT NULL THEN
                       	CALL fl_lee_moneda(rm_cxp.p27_moneda)
                               	RETURNING r_mon.*
                       	IF r_mon.g13_moneda IS NULL THEN
                               	CALL fgl_winmessage(vg_producto,'Moneda no existe.','exclamation')
                               	NEXT FIELD p27_moneda
                       	END IF
			IF r_mon.g13_estado = 'B' THEN
                                CALL fl_mensaje_estado_bloqueado()
				NEXT FIELD p20_moneda
			END IF
			IF rm_cxp.p27_moneda = rg_gen.g00_moneda_base THEN
				LET r_mon_par.g14_tasa = 1
			ELSE
				CALL fl_lee_factor_moneda(rm_cxp.p27_moneda,
							rg_gen.g00_moneda_base)
					RETURNING r_mon_par.*
				IF r_mon_par.g14_serial IS NULL THEN
					CALL fgl_winmessage(vg_producto,'La paridad para está moneda no existe.','exclamation')
					NEXT FIELD p27_moneda
				END IF
			END IF
			LET rm_cxp.p27_paridad = r_mon_par.g14_tasa
			DISPLAY BY NAME rm_cxp.p27_paridad
               	ELSE
                       	LET rm_cxp.p27_moneda = rg_gen.g00_moneda_base
                       	CALL fl_lee_moneda(rm_cxp.p27_moneda)
				RETURNING r_mon.*
                       	DISPLAY BY NAME rm_cxp.p27_moneda
               	END IF
               	DISPLAY r_mon.g13_nombre TO tit_moneda
	AFTER FIELD p27_codprov
               	IF rm_cxp.p27_codprov IS NOT NULL THEN
                       	CALL fl_lee_proveedor(rm_cxp.p27_codprov)
                     		RETURNING r_pro.*
                        IF r_pro.p01_codprov IS NULL THEN
                               	CALL fgl_winmessage(vg_producto,'Proveedor no existe.','exclamation')
                               	NEXT FIELD p27_codprov
                        END IF
			IF fl_validar_cedruc_dig_ver(r_pro.p01_tipo_doc, r_pro.p01_num_doc) = 0 THEN
				NEXT FIELD p27_codprov
			END IF
			DISPLAY r_pro.p01_nomprov TO tit_nombre_pro
		ELSE
			CLEAR tit_nombre_pro
                END IF
END INPUT

END FUNCTION



FUNCTION retenciones(r_cxp)
DEFINE r_cxp		RECORD LIKE cxpt020.*
DEFINE r_p01		RECORD LIKE cxpt001.*
DEFINE r_c02		RECORD LIKE ordt002.*
DEFINE r_p05		RECORD LIKE cxpt005.*
DEFINE r_c13		RECORD LIKE ordt013.*
DEFINE i		SMALLINT

CALL fl_lee_proveedor(rm_cxp.p27_codprov) RETURNING r_p01.*
LET val_servi  = 0
LET val_bienes = r_cxp.p20_valor_fact - r_cxp.p20_valor_impto
LET val_impto  = r_cxp.p20_valor_impto
LET val_neto   = r_cxp.p20_valor_fact
LET ind_ret    = 0
LET tot_ret    = 0

DECLARE q_ret CURSOR FOR SELECT * FROM ordt002, OUTER cxpt005
		WHERE c02_compania   = vg_codcia
          AND c02_estado     = 'A' 
	  	  AND p05_compania   = c02_compania
	  	  AND p05_codprov    = r_p01.p01_codprov
		  AND p05_codigo_sri = c02_codigo_sri
	  	  AND p05_tipo_ret   = c02_tipo_ret
	  	  AND p05_porcentaje = c02_porcentaje 
LET i = 1
FOREACH q_ret INTO r_c02.*, r_p05.*
	IF r_c02.c02_tipo_ret = 'F' AND r_p01.p01_ret_fuente = 'N' THEN
		CONTINUE FOREACH
	END IF
	IF r_c02.c02_tipo_ret = 'I' AND r_p01.p01_ret_impto = 'N' THEN
		CONTINUE FOREACH
	END IF
	LET r_ret[i].n_retencion = r_c02.c02_nombre
	LET r_ret[i].codigo_sri  = r_c02.c02_codigo_sri
	LET r_ret[i].tipo_ret    = r_c02.c02_tipo_ret
	LET r_ret[i].porc        = r_c02.c02_porcentaje
	LET r_ret[i].val_base    = 0
	LET r_ret[i].subtotal    = 0
	LET r_ret[i].check       = 'N'
	IF r_p05.p05_tipo_ret IS NOT NULL THEN
		LET r_ret[i].check = 'S'
		IF r_p05.p05_tipo_ret = 'I' THEN
			LET r_ret[i].val_base = val_impto
		ELSE
			LET r_ret[i].val_base = val_bienes
		END IF
		LET r_ret[i].subtotal = (r_ret[i].val_base * 
					(r_p05.p05_porcentaje / 100))
		LET tot_ret = tot_ret + r_ret[i].subtotal
	END IF
	LET r_ret_aux[i].* = r_ret[i].*
	LET i = i + 1
	IF i > ind_max_ret THEN
		EXIT FOREACH
	END IF
END FOREACH
LET i = i - 1
LET ind_ret = i

END FUNCTION



FUNCTION muestra_retenciones(l)
DEFINE resp		CHAR(6)
DEFINE c		CHAR(1)
DEFINE salir,i,j,l,k	SMALLINT
DEFINE iva		SMALLINT
DEFINE r_p01		RECORD LIKE cxpt001.*
DEFINE r_c02		RECORD LIKE ordt002.*

OPEN WINDOW w_for AT 04, 05
        WITH FORM '../forms/cxpf207_2'
        ATTRIBUTE(FORM LINE FIRST, COMMENT LINE LAST, MESSAGE LINE LAST,
                   MENU LINE 0, BORDER)
CALL mostrar_detalle_forma()
CALL fl_lee_proveedor(rm_cxp.p27_codprov) RETURNING r_p01.*
DISPLAY rm_det[l].p20_tipo_doc TO tit_tipo
DISPLAY rm_det[l].p20_num_doc TO tit_num
DISPLAY r_p01.p01_nomprov TO n_proveedor
DISPLAY BY NAME val_servi, val_bienes, val_impto, val_neto, tot_ret
OPTIONS INSERT KEY F40,
	DELETE KEY F41
INPUT BY NAME val_bienes, val_servi, val_impto, val_neto 
	WITHOUT DEFAULTS
	ON KEY(INTERRUPT)
		IF NOT FIELD_TOUCHED(val_bienes, val_servi) THEN
			EXIT INPUT
		END IF
		LET int_flag = 0
		CALL fl_mensaje_abandonar_proceso() RETURNING resp
		IF resp = 'Yes' THEN
			LET int_flag = 1
			EXIT INPUT
		END IF
	AFTER FIELD val_bienes
		IF val_bienes IS NULL THEN
			LET val_bienes = 0
		END IF
		IF val_bienes > val_neto THEN
			CALL fgl_winmessage(vg_producto,
				'Debe ingresar un valor menor ' ||
				'valor neto.',
				'exclamation')
			NEXT FIELD val_bienes
		END IF
		LET val_servi = val_neto - val_impto - val_bienes
		DISPLAY BY NAME val_bienes, val_servi
	AFTER FIELD val_servi
		IF val_servi IS NULL THEN
			LET val_servi = 0
		END IF
		IF val_servi > val_neto THEN
			CALL fgl_winmessage(vg_producto,
				'Debe ingresar un valor menor ' ||
				'valor neto.',
				'exclamation')
			NEXT FIELD val_servi
		END IF			
		LET val_bienes = val_neto - val_impto - val_servi
		DISPLAY BY NAME val_bienes, val_servi
	AFTER INPUT
		IF (val_bienes + val_servi) <> (val_neto - val_impto) THEN
			CALL fgl_winmessage(vg_producto,
				'Total neto menos iva debe ser ' ||
				'igual al valor bienes mas valor ' ||
				'servicios.',
				'exclamation')
			CONTINUE INPUT
		END IF
--		LET iva_bien  = val_bienes * (r_p20.p20_porc_impto / 100)
--		LET iva_servi = val_servi  * (r_p20.p20_porc_impto / 100)
END INPUT
IF int_flag THEN
	CLOSE WINDOW w_for
	RETURN
END IF

LET tot_ret = 0
FOR i = 1 TO ind_ret
	IF r_ret[i].check = 'S' THEN
		CALL fl_lee_tipo_retencion(vg_codcia, r_ret[i].codigo_sri,
			 r_ret[i].tipo_ret,
			r_ret[i].porc
		) RETURNING r_c02.*
		IF r_ret[i].tipo_ret = 'I' THEN
			CASE r_c02.c02_tipo_fuente
				WHEN 'B'
					LET r_ret[i].val_base = iva_bien
				WHEN 'S'
					LET r_ret[i].val_base = iva_servi
				WHEN 'T'
					LET r_ret[i].val_base = val_impto
			END CASE
		ELSE
			CASE r_c02.c02_tipo_fuente
				WHEN 'B'
					LET r_ret[i].val_base = val_bienes
				WHEN 'S'
					LET r_ret[i].val_base = val_servi
				WHEN 'T'
					LET r_ret[i].val_base = 
						val_servi + val_bienes
			END CASE
		END IF
		LET r_ret[i].subtotal = (r_ret[i].val_base * 
					(r_ret[i].porc / 100))	
		LET tot_ret = tot_ret + r_ret[i].subtotal
	END IF
END FOR

LET salir = 0
WHILE NOT salir
	IF ind_ret > 0 THEN
		CALL set_count(ind_ret)
	ELSE
		CALL fgl_winmessage(vg_producto,'No hay datos a mostrar.','exclamation')
		RETURN
	END IF
	INPUT ARRAY r_ret WITHOUT DEFAULTS FROM ra_ret.*
		ON KEY(INTERRUPT)
			FOR k = 1 TO ind_ret
				LET r_ret[k].* = r_ret_aux[k].*
			END FOR
			LET int_flag = 1
			EXIT INPUT
		BEFORE INPUT
			CALL dialog.keysetlabel('INSERT', '')
			CALL dialog.keysetlabel('DELETE', '')
		BEFORE ROW
			LET i = arr_curr()
			LET j = scr_line()
		BEFORE INSERT
			EXIT INPUT
		BEFORE DELETE
			EXIT INPUT
		BEFORE FIELD check
			LET c = r_ret[i].check
		AFTER FIELD check, val_base
			IF r_ret[i].check = 'S' THEN
				IF r_ret[i].val_base IS NULL OR 
				   r_ret[i].val_base = 0 THEN
					CALL fgl_winmessage(vg_producto,
				'Digite valor base.', 'exclamation')
					NEXT FIELD val_base
				END IF
				CALL fl_lee_tipo_retencion(vg_codcia, 
					r_ret[i].codigo_sri,
					r_ret[i].tipo_ret,
					r_ret[i].porc
				) RETURNING r_c02.*
	 	{
				IF r_ret[i].tipo_ret = 'I' THEN
					CASE r_c02.c02_tipo_fuente
					WHEN 'B'
						LET r_ret[i].val_base =
							iva_bien
					WHEN 'S'
						LET r_ret[i].val_base = 
							iva_servi
					WHEN 'T'
						LET r_ret[i].val_base = 
							val_impto
					END CASE
				ELSE
					CASE r_c02.c02_tipo_fuente
					WHEN 'B'
						LET r_ret[i].val_base = 
							val_bienes
					WHEN 'S'
						LET r_ret[i].val_base = 
							val_servi
					WHEN 'T'
						LET r_ret[i].val_base = 
						val_servi + val_bienes
					END CASE
				END IF
		}
				LET r_ret[i].subtotal = 
					(r_ret[i].val_base * 
					(r_ret[i].porc / 100))	
				LET tot_ret = tot_ret
						+ r_ret[i].subtotal
			END IF
			IF r_ret[i].check = 'N' THEN
				LET r_ret[i].val_base = 0
				LET r_ret[i].subtotal = 0
			END IF
			DISPLAY r_ret[i].* TO ra_ret[j].*
			LET tot_ret = 0
			FOR k = 1 TO ind_ret
				LET tot_ret = tot_ret + r_ret[k].subtotal
			END FOR
			DISPLAY BY NAME tot_ret
		AFTER INPUT 
			IF tot_ret > val_neto THEN
				CALL fgl_winmessage(vg_producto,'El valor de las retenciones no debe ser mayor al valor neto.','exclamation')
				CONTINUE INPUT
			END IF
			LET iva = 0
			FOR i = 1 TO ind_ret 
				IF r_ret[i].check = 'S'
				AND r_ret[i].tipo_ret = 'I' THEN
					LET iva = iva + r_ret[i].porc
				END IF
			END FOR
			IF iva > 100 THEN
				CALL fgl_winmessage(vg_producto,'Las retenciones sobre el iva no pueden exceder al 100% del iva.','exclamation')
				CONTINUE INPUT
			END IF
			LET salir = 1
			LET ind_ret = arr_count()
	END INPUT
	IF int_flag THEN
		SELECT SUM(subtotal) INTO tot_ret
			FROM tmp_retenciones
			WHERE tipo_doc = rm_det[l].p20_tipo_doc
	  		  AND num_doc  = rm_det[l].p20_num_doc
		IF tot_ret IS NULL THEN
			LET tot_ret = 0  
		END IF
		CLOSE WINDOW w_for
		RETURN
	END IF
	CALL elimina_retenciones(l)
	FOR j = 1 TO ind_ret
		IF r_ret[j].check = 'S' THEN
			INSERT INTO tmp_retenciones 
				VALUES(rm_det[l].p20_tipo_doc,
					rm_det[l].p20_num_doc,   
						r_ret[j].codigo_sri,
	  	       			r_ret[j].tipo_ret,    
			       	       	r_ret[j].porc,
			       	       	r_ret[j].val_base,    
			       	       	r_ret[j].subtotal)
		END IF
	END FOR
	IF int_flag THEN
		CLOSE WINDOW w_for
		RETURN
	END IF

END WHILE
CLOSE WINDOW w_for

END FUNCTION



FUNCTION graba_ajuste_retencion(j)
DEFINE r_cxp,r_cxp2	RECORD LIKE cxpt020.*
DEFINE r_p28		RECORD LIKE cxpt028.*
DEFINE r_p22		RECORD LIKE cxpt022.*
DEFINE r_p23		RECORD LIKE cxpt023.*
DEFINE i,j,orden	SMALLINT
DEFINE retencion	DECIMAL(12,2)
DEFINE dividendo	LIKE cxpt020.p20_dividendo

INITIALIZE r_p22.*, r_p23.* TO NULL
-- Graba Cabecera Ajuste Documento
LET r_p22.p22_compania  = vg_codcia
LET r_p22.p22_localidad = vg_codloc
LET r_p22.p22_codprov   = rm_cxp.p27_codprov
LET r_p22.p22_tipo_trn  = 'AJ'
LET r_p22.p22_num_trn   = nextValInSequence('TE', r_p22.p22_tipo_trn)
IF r_p22.p22_num_trn = -1 THEN
	LET int_flag = 1
	ROLLBACK WORK
	CALL fgl_winmessage(vg_producto,'No puede generar la retención en este momento.','stop')
	EXIT PROGRAM
END IF
LET r_p22.p22_referencia = 'RETENCION # ' || vm_num_ret
LET r_p22.p22_fecha_emi  = TODAY
LET r_p22.p22_moneda     = rm_cxp.p27_moneda
LET r_p22.p22_paridad    = rm_cxp.p27_paridad
LET r_p22.p22_tasa_mora  = 0
SELECT SUM(subtotal) * (-1) INTO r_p22.p22_total_cap FROM tmp_retenciones
LET r_p22.p22_total_int  = 0
LET r_p22.p22_total_mora = 0
LET r_p22.p22_origen     = 'M'
LET r_p22.p22_usuario    = vg_usuario
LET r_p22.p22_fecing     = CURRENT 
INSERT INTO cxpt022 VALUES(r_p22.*)
--------------------------------------------------------------------------

LET r_p23.p23_compania   = r_p22.p22_compania
LET r_p23.p23_localidad  = r_p22.p22_localidad
LET r_p23.p23_codprov    = r_p22.p22_codprov
LET r_p23.p23_tipo_trn   = r_p22.p22_tipo_trn
LET r_p23.p23_num_trn    = r_p22.p22_num_trn
LET r_p23.p23_valor_int  = 0
LET r_p23.p23_valor_mora = 0
LET r_p23.p23_saldo_int  = 0
LET orden = 1

DECLARE q_ret3 CURSOR FOR 
	SELECT * FROM cxpt028
		WHERE p28_compania  = vg_codcia
		  AND p28_localidad = vg_codloc
		  AND p28_num_ret   = vm_num_ret
		ORDER BY p28_secuencia
FOREACH q_ret3 INTO r_p28.*
	LET r_p23.p23_tipo_doc = r_p28.p28_tipo_doc
	LET r_p23.p23_num_doc  = r_p28.p28_num_doc
	WHENEVER ERROR CONTINUE
	SET LOCK MODE TO WAIT 3
	DECLARE q_saldo2 CURSOR FOR
		SELECT p20_saldo_cap FROM cxpt020
			WHERE p20_compania  = vg_codcia
			  AND p20_localidad = vg_codloc
			  AND p20_codprov   = r_p23.p23_codprov
			  AND p20_tipo_doc  = r_p23.p23_tipo_doc
			  AND p20_num_doc   = r_p23.p23_num_doc
			  AND p20_dividendo = r_p28.p28_dividendo
		FOR UPDATE OF p20_saldo_cap
	SET LOCK MODE TO NOT WAIT
	WHENEVER ERROR STOP
	OPEN q_saldo2
	FETCH q_saldo2 INTO r_p23.p23_saldo_cap	
	IF STATUS < 0 THEN
		ROLLBACK WORK
		EXIT PROGRAM
	END IF
	LET r_p23.p23_orden     = orden
	LET orden = orden + 1
	LET r_p23.p23_div_doc   = r_p28.p28_dividendo
	LET r_p23.p23_valor_cap = r_p28.p28_valor_ret * (-1)
	INSERT INTO cxpt023 VALUES(r_p23.*)
	UPDATE cxpt020 
		SET p20_saldo_cap = p20_saldo_cap - r_p28.p28_valor_ret
		WHERE CURRENT OF q_saldo2
	CLOSE q_saldo2
	FREE  q_saldo2
END FOREACH
CALL fl_genera_saldos_proveedor(vg_codcia, vg_codloc, rm_cxp.p27_codprov)

END FUNCTION



FUNCTION graba_retenciones(j)
DEFINE r_p27		RECORD LIKE cxpt027.*
DEFINE r_p28		RECORD LIKE cxpt028.*
DEFINE i,j,orden,done	SMALLINT
DEFINE cont		INTEGER
DEFINE r_reten		RECORD
				tipo_doc	CHAR(2),
				num_doc		CHAR(15),
				codigo_sri	CHAR(3),
				tipo_ret	CHAR(1), 
				porc		DECIMAL(5,2),
				val_base	DECIMAL(12,2),
				subtotal 	DECIMAL(12,2)
			END RECORD
DEFINE dividendo	LIKE cxpt020.p20_dividendo
DEFINE saldo		DECIMAL(12,2)
DEFINE mensaje		VARCHAR(100)

SELECT COUNT(*) INTO cont FROM tmp_retenciones
IF cont = 0 THEN
	RETURN 0
END IF

INITIALIZE r_p27.*, r_p28.* TO NULL
LET r_p27.p27_compania  = vg_codcia
LET r_p27.p27_localidad = vg_codloc
LET r_p27.p27_estado    = 'A'
LET r_p27.p27_codprov   = rm_cxp.p27_codprov
LET r_p27.p27_moneda    = rm_cxp.p27_moneda
LET r_p27.p27_paridad   = rm_cxp.p27_paridad
SELECT SUM(subtotal) INTO r_p27.p27_total_ret FROM tmp_retenciones
LET r_p27.p27_origen    = 'M'
LET r_p27.p27_usuario   = vg_usuario
LET r_p27.p27_fecing    = CURRENT
LET r_p27.p27_num_ret   = nextValInSequence('TE', vm_retencion)
IF r_p27.p27_num_ret = -1 THEN
	LET int_flag = 1
	ROLLBACK WORK
	CALL fgl_winmessage(vg_producto,'No se puede generar la retención en este momento.','stop')
	EXIT PROGRAM
END IF
LET vm_num_ret = r_p27.p27_num_ret
INSERT INTO cxpt027 VALUES(r_p27.*) 

-- Graba Detalle Retencion
LET r_p28.p28_compania   = vg_codcia        
LET r_p28.p28_localidad  = vg_codloc
LET r_p28.p28_num_ret    = r_p27.p27_num_ret
LET r_p28.p28_codprov    = r_p27.p27_codprov

DECLARE q_tmpret2 CURSOR FOR
	SELECT DISTINCT tipo_doc, num_doc FROM tmp_retenciones
		ORDER BY 1, 2
LET i = 1
LET orden = 1
FOREACH q_tmpret2 INTO r_reten.tipo_doc, r_reten.num_doc
	LET r_p28.p28_tipo_doc = r_reten.tipo_doc
	LET r_p28.p28_num_doc  = r_reten.num_doc
	SELECT p20_valor_fact INTO r_p28.p28_valor_fact FROM tmp_detalle_ret
		WHERE p20_tipo_doc = r_reten.tipo_doc
		  AND p20_num_doc  = r_reten.num_doc
	DECLARE q_saldo3 CURSOR FOR
		SELECT p20_dividendo, p20_saldo_cap
			FROM cxpt020
			WHERE p20_compania  = vg_codcia
			  AND p20_localidad = vg_codloc
			  AND p20_codprov   = r_p28.p28_codprov
			  AND p20_tipo_doc  = r_p28.p28_tipo_doc
			  AND p20_num_doc   = r_p28.p28_num_doc
			  AND p20_saldo_cap > 0
			ORDER BY p20_dividendo ASC
	DECLARE q_saldo4 CURSOR FOR SELECT * FROM tmp_retenciones
		WHERE tipo_doc = r_reten.tipo_doc
		  AND num_doc  = r_reten.num_doc
		  AND subtotal > 0
	OPEN  q_saldo4
	FETCH q_saldo4 INTO r_reten.*
	FOREACH q_saldo3 INTO dividendo, saldo
		LET done  = 0	
		IF saldo < r_reten.subtotal THEN
			CONTINUE FOREACH
		END IF
		WHILE saldo >= r_reten.subtotal
			LET r_p28.p28_secuencia  = orden
			LET orden = orden + 1
			LET r_p28.p28_dividendo  = dividendo
			LET r_p28.p28_codigo_sri = r_reten.codigo_sri
			LET r_p28.p28_tipo_ret   = r_reten.tipo_ret
			LET r_p28.p28_porcentaje = r_reten.porc
			LET r_p28.p28_valor_base = r_reten.val_base
			LET r_p28.p28_valor_ret  = r_reten.subtotal
			INSERT INTO cxpt028 VALUES(r_p28.*)
			LET done = 1
			LET saldo = saldo - r_reten.subtotal
			FETCH q_saldo4 INTO r_reten.*
			IF STATUS = NOTFOUND THEN
				EXIT FOREACH
			END IF
		END WHILE
	END FOREACH
	FREE q_saldo3
	CLOSE q_saldo4
	FREE  q_saldo4
	IF NOT done THEN
		LET mensaje = 'No pudo hacerse la retención'
		CASE r_ret[i].tipo_ret
			WHEN 'I'
				LET mensaje = mensaje || ' sobre el IVA (' ||
					      r_ret[i].porc || '%).'
			WHEN 'F'
				LET mensaje = mensaje || ' en la fuente (' ||
					      r_ret[i].porc || '%).'
			OTHERWISE
				LET mensaje = mensaje || ' ' || 
					      r_ret[i].tipo_ret || ' (' ||
					      r_ret[i].porc || '%).'
		END CASE
		CALL fgl_winmessage(vg_producto, mensaje, 'stop')
		ROLLBACK WORK
		EXIT PROGRAM
	END IF
END FOREACH
RETURN done

END FUNCTION



FUNCTION sacar_total()
DEFINE i		SMALLINT

LET vm_total = 0
FOR i = 1 TO vm_num_det
	LET vm_total = vm_total + rm_det[i].tit_valor_ret
END FOR
DISPLAY vm_total TO tit_total_ret

END FUNCTION



FUNCTION borrar_cabecera()

CLEAR p27_estado, tit_estado_pro, p27_moneda, tit_moneda, p27_codprov,
	tit_nombre_pro, p20_referencia, p27_usuario, p27_fecing
INITIALIZE rm_cxp.* TO NULL

END FUNCTION



FUNCTION borrar_detalle()
DEFINE i  		SMALLINT

CALL muestra_contadores_det(0)
LET vm_scr_lin = fgl_scr_size('rm_det')
FOR i = 1 TO vm_scr_lin
        INITIALIZE rm_det[i].*, rm_refer[i] TO NULL
        CLEAR rm_det[i].*
END FOR
CLEAR tit_total_ret

END FUNCTION



FUNCTION muestra_contadores_det(cor)
DEFINE cor	           SMALLINT

DISPLAY "" AT 4, 62
DISPLAY cor, " de ", vm_num_det AT 4, 66

END FUNCTION


 
FUNCTION muestra_estado()

DISPLAY BY NAME rm_cxp.p27_estado
IF rm_cxp.p27_estado = 'A' THEN
	DISPLAY 'ACTIVO' TO tit_estado_pro
END IF
IF rm_cxp.p27_estado = 'E' THEN
	DISPLAY 'ELIMINADO' TO tit_estado_pro
END IF

END FUNCTION



FUNCTION mostrar_cabecera_forma()

DISPLAY 'TD'              TO tit_col1
DISPLAY 'Documento'       TO tit_col2
DISPLAY 'Fec. Emi.'       TO tit_col3
DISPLAY 'Valor Factura'   TO tit_col4
DISPLAY 'Valor Retención' TO tit_col5

END FUNCTION



FUNCTION mostrar_detalle_forma()

DISPLAY 'Descripción' TO tit_col6
DISPLAY 'Cod'		  TO tit_col7
DISPLAY 'Tipo'        TO tit_col8
DISPLAY 'Valor Base'  TO tit_col9
DISPLAY '%'           TO tit_col10
DISPLAY 'Subtotal'    TO tit_col11

END FUNCTION



FUNCTION nextValInSequence(modulo, tipo_tran)

DEFINE modulo		LIKE gent050.g50_modulo
DEFINE tipo_tran 	LIKE rept019.r19_cod_tran

DEFINE resp		CHAR(6)
DEFINE retVal 		SMALLINT

LET retVal = -1
WHILE retVal = -1

LET retVal = fl_actualiza_control_secuencias(vg_codcia, vg_codloc, modulo,
		'AA', tipo_tran)
IF retVal = 0 THEN
	EXIT PROGRAM
END IF
IF retVal <> -1 THEN
	 EXIT WHILE
END IF

CALL fgl_winquestion(vg_producto, 
	'La tabla de secuencias de transacciones ' ||
        'está siendo accesada por otro usuario, espere unos  ' ||
        'segundos y vuelva a intentar', 
	'No', 'Yes|No|Cancel', 'question', 1) RETURNING resp 
IF resp <> 'Yes' THEN
	EXIT WHILE	
END IF

END WHILE

RETURN retVal

END FUNCTION



FUNCTION elimina_retenciones(i)
DEFINE i		SMALLINT

DELETE FROM tmp_retenciones
	WHERE tipo_doc  = rm_det[i].p20_tipo_doc
	  AND num_doc   = rm_det[i].p20_num_doc
		  
END FUNCTION



FUNCTION carga_retenciones(i)
DEFINE i,j		SMALLINT
DEFINE r_c02		RECORD LIKE ordt002.*
DEFINE r_p01		RECORD LIKE cxpt001.*
DEFINE r_reten		RECORD
				tipo_doc	CHAR(2),
				num_doc		CHAR(15),
				codigo_sri  CHAR(3),
				tipo_ret	CHAR(1), 
				porc		DECIMAL(5,2),
				val_base	DECIMAL(12,2),
				subtotal 	DECIMAL(12,2)
			END RECORD

SELECT COUNT(*) INTO j FROM tmp_retenciones
	WHERE tipo_doc = rm_det[i].p20_tipo_doc
    	  AND num_doc  = rm_det[i].p20_num_doc
IF j = 0 THEN
	RETURN
END IF

LET tot_ret = 0
CALL fl_lee_proveedor(rm_cxp.p27_codprov) RETURNING r_p01.*
DECLARE q_ret2 CURSOR FOR
	SELECT * FROM ordt002, OUTER tmp_retenciones
		WHERE c02_compania = vg_codcia
                  AND c02_estado   = 'A' 
    	  	  AND tipo_doc     = rm_det[i].p20_tipo_doc
    		  AND num_doc      = rm_det[i].p20_num_doc
			  AND codigo_sri   = c02_codigo_sri
    		  AND tipo_ret     = c02_tipo_ret
    		  AND porc         = c02_porcentaje
LET filas_pant = fgl_scr_size('ra_ret')
FOR j = 1 TO filas_pant
	CLEAR ra_ret[j].*
END FOR
LET j = 1
FOREACH q_ret2 INTO r_c02.*, r_reten.*
	IF r_c02.c02_tipo_ret = 'F' AND r_p01.p01_ret_fuente = 'N' THEN
		CONTINUE FOREACH
	END IF
	IF r_c02.c02_tipo_ret = 'I' AND r_p01.p01_ret_impto = 'N' THEN
		CONTINUE FOREACH
	END IF
	LET r_ret[j].check    = 'N'
	LET r_ret[j].n_retencion = r_c02.c02_nombre
	LET r_ret[j].codigo_sri  = r_c02.c02_codigo_sri
	LET r_ret[j].tipo_ret =    r_c02.c02_tipo_ret
	LET r_ret[j].porc     =    r_c02.c02_porcentaje
	IF r_reten.subtotal IS NOT NULL THEN
		LET r_ret[j].check    = 'S'
		LET r_ret[j].val_base = r_reten.val_base
		LET r_ret[j].subtotal = r_reten.subtotal
		LET tot_ret           = tot_ret + r_reten.subtotal
	END IF
	IF j <= filas_pant THEN
		DISPLAY r_ret[j].* TO ra_ret[j].*
	END IF
	LET r_ret_aux[j].* = r_ret[j].*
	LET j = j + 1
	IF j > ind_max_ret THEN
		EXIT FOREACH
	END IF
END FOREACH
LET ind_ret = j - 1

END FUNCTION



FUNCTION cuantas_retenciones(i)
DEFINE i,l		SMALLINT

-- Verifica si se han hecho retenciones sobre este documento,
-- y si se han hecho si no se han eliminado
SELECT COUNT(p28_secuencia) INTO l FROM cxpt028, cxpt027
	WHERE p28_compania  = vg_codcia
	  AND p28_localidad = vg_codloc
	  AND p28_codprov   = rm_cxp.p27_codprov
	  AND p28_tipo_doc  = rm_det[i].p20_tipo_doc
 	  AND p28_num_doc   = rm_det[i].p20_num_doc
  	  AND p27_compania  = p28_compania
  	  AND p27_localidad = p28_localidad
 	  AND p27_num_ret   = p28_num_ret
  	  AND p27_estado    = 'A'
RETURN l

END FUNCTION



FUNCTION ver_estado_cuenta(i)
DEFINE i		SMALLINT
DEFINE nuevoprog     VARCHAR(400)

LET nuevoprog = 'cd ..', vg_separador, '..', vg_separador, 'TESORERIA',
	vg_separador, 'fuentes', vg_separador, '; fglrun cxpp300 ', vg_base,
	' ', vg_modulo, ' ', vg_codcia, ' ', vg_codloc, ' ',
	rm_cxp.p27_codprov, ' ', rm_cxp.p27_moneda
RUN nuevoprog

END FUNCTION



FUNCTION imprime_retenciones(r_p27)

DEFINE r_p27			RECORD LIKE cxpt027.*
DEFINE resp			VARCHAR(10)
DEFINE retenciones		SMALLINT
DEFINE comando			VARCHAR(250)

SELECT COUNT(*) INTO retenciones FROM cxpt028
WHERE p28_compania  = r_p27.p27_compania
  AND p28_localidad = r_p27.p27_localidad
  AND p28_num_ret   = r_p27.p27_num_ret

IF retenciones = 0 THEN
	RETURN
END IF

CALL fgl_winquestion(vg_producto, 'Desea imprimir comprobante de retencion?', 
	'No', 'Yes|No', 'question', 1) RETURNING resp
IF resp = 'Yes' THEN
	LET comando = 'cd ..', vg_separador, '..', vg_separador,
		      'TESORERIA', vg_separador, 'fuentes', 
		      vg_separador, '; fglrun cxpp405 ', vg_base, ' ',
		      'TE', vg_codcia, ' ', vg_codloc,
		      ' ', r_p27.p27_num_ret    

	RUN comando
END IF

END FUNCTION



FUNCTION validar_parametros()

CALL fl_lee_modulo(vg_modulo) RETURNING rg_mod.*
IF rg_mod.g50_modulo IS NULL THEN
	CALL fgl_winmessage(vg_producto, 'No existe módulo: ' || vg_modulo, 'stop')
	EXIT PROGRAM
END IF
CALL fl_lee_compania(vg_codcia) RETURNING rg_cia.*
IF rg_cia.g01_compania IS NULL THEn
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
